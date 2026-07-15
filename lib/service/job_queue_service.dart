// Dosya Adı: job_queue_service.dart
// Açıklama: Offline sync kuyruğu — Logo REST aktarımı
// Oluşturulma Tarihi: 2026-02-22
// Geliştirici: EXFIN OPS Team
// Son Güncelleme: 2026-07-15

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/services/logo_api_service.dart';
import '../core/services/logo_payload_mapper.dart';
import 'database_service.dart';

class JobQueueService {
  static final JobQueueService _instance = JobQueueService._internal();
  factory JobQueueService() => _instance;
  JobQueueService._internal();

  bool _isProcessing = false;

  /// Kuyruğa iş ekler ve işlemeyi tetikler.
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    Map<String, dynamic>? payload,
    int priority = 0,
  }) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();

    final jobId = const Uuid().v4();
    await db.insert('sync_queue', {
      'id': jobId,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': payload != null ? jsonEncode(payload) : null,
      'priority': priority,
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    debugPrint('Job Enqueued: $entityType ($entityId)');
    processQueue();
  }

  Future<List<Map<String, dynamic>>> getPendingJobs() async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    final jobs = await db.query(
      'sync_queue',
      orderBy: 'priority DESC, created_at ASC',
    );
    return jobs.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<int> pendingCount() async {
    final jobs = await getPendingJobs();
    return jobs.length;
  }

  /// Bekleyen işleri Logo REST'e aktarır.
  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();

      final jobs = await db.query(
        'sync_queue',
        orderBy: 'priority DESC, created_at ASC',
        limit: 10,
      );

      for (final job in jobs) {
        final jobId = job['id'] as String;
        final type = (job['entity_type'] as String).toLowerCase();
        final entityId = job['entity_id'] as String;
        Map<String, dynamic>? payload;
        if (job['payload'] != null) {
          try {
            payload = Map<String, dynamic>.from(
              jsonDecode(job['payload'] as String) as Map,
            );
          } catch (_) {
            payload = null;
          }
        }

        debugPrint('Processing Job: $type ($entityId)');
        final result = await _syncToLogo(type, entityId, payload);

        if (result.success) {
          await db.delete('sync_queue', where: 'id = ?', whereArgs: [jobId]);
          await _markEntitySynced(type, entityId);
          debugPrint('Job Completed: $jobId');
        } else {
          final currentRetry = (job['retry_count'] as int? ?? 0) + 1;
          await db.update(
            'sync_queue',
            {
              'retry_count': currentRetry,
              'last_error': result.error ?? 'Bilinmeyen hata',
              if (currentRetry <= 5)
                'scheduled_at': DateTime.now()
                    .add(const Duration(minutes: 5))
                    .toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [jobId],
          );
          debugPrint('Job Failed: $jobId → ${result.error}');
        }
      }
    } catch (e) {
      debugPrint('Queue Processing Error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<LogoApiResult> _syncToLogo(
    String type,
    String entityId,
    Map<String, dynamic>? payload,
  ) async {
    final logo = LogoApiService();
    await logo.loadConfig();

    try {
      switch (type) {
        case 'order':
        case 'orders':
          return await _syncOrder(logo, entityId, payload);
        case 'invoice':
        case 'invoices':
          return await _syncInvoice(logo, entityId, payload);
        case 'collection':
        case 'collections':
          return await _syncCollection(logo, entityId, payload);
        case 'dispatch':
        case 'dispatches':
          if (payload == null) {
            return LogoApiResult.fail('İrsaliye payload boş');
          }
          final items = (payload['items'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              const [];
          return logo.createDispatch(payload, items);
        case 'campaign':
        case 'campaigns':
          return logo.createCampaign(payload ?? {'id': entityId});
        default:
          debugPrint('Bilinmeyen entity_type: $type — atlanıyor');
          return LogoApiResult.ok({'skipped': true});
      }
    } catch (e) {
      return LogoApiResult.fail(e.toString());
    }
  }

  Future<LogoApiResult> _syncOrder(
    LogoApiService logo,
    String entityId,
    Map<String, dynamic>? payload,
  ) async {
    if (payload != null &&
        (payload.containsKey('lines') || payload.containsKey('customer_code'))) {
      return logo.createOrder(payload);
    }

    final built = await _buildOrderPayload(entityId);
    if (built == null) {
      return LogoApiResult.fail('Sipariş bulunamadı: $entityId');
    }
    return logo.createOrder(built);
  }

  Future<LogoApiResult> _syncInvoice(
    LogoApiService logo,
    String entityId,
    Map<String, dynamic>? payload,
  ) async {
    // ExfinApi: query param local_invoice_id — PG'deki sipariş/fatura id
    final type = payload?['type']?.toString() ??
        payload?['invoice_type']?.toString() ??
        'wholesale';
    final mappedType = type.toLowerCase().contains('return')
        ? 'wholesale'
        : (type.toLowerCase().contains('retail') ? 'retail' : 'wholesale');

    if (payload != null && payload.containsKey('lines')) {
      final customerCode =
          (payload['customer_code'] ?? payload['arp_code'] ?? '').toString();
      if (customerCode.isNotEmpty) {
        // Satırlı fatura varsa sipariş endpoint'i üzerinden de denenebilir
        final asOrder = await logo.createOrder(payload);
        if (asOrder.success) return asOrder;
      }
    }

    return logo.createInvoice(localInvoiceId: entityId, type: mappedType);
  }

  Future<LogoApiResult> _syncCollection(
    LogoApiService logo,
    String entityId,
    Map<String, dynamic>? payload,
  ) async {
    if (payload != null) {
      final code =
          (payload['customer_code'] ?? payload['arp_code'] ?? '').toString();
      final amount = (payload['amount'] as num?)?.toDouble();
      if (code.isNotEmpty && amount != null) {
        final sync = await logo.createCollectionSync(payload);
        if (sync.success) return sync;
        return logo.createCollectionSimple(
          customerCode: code,
          amount: amount,
        );
      }
    }

    final built = await _buildCollectionPayload(entityId);
    if (built == null) {
      return LogoApiResult.fail('Tahsilat bulunamadı: $entityId');
    }
    final sync = await logo.createCollectionSync(built);
    if (sync.success) return sync;
    return logo.createCollectionSimple(
      customerCode: built['customer_code']?.toString() ?? '',
      amount: (built['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<Map<String, dynamic>?> _buildOrderPayload(String orderId) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();

    final orders = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );
    if (orders.isEmpty) return null;
    final order = orders.first;
    final customerId = order['customer_id']?.toString();
    final customerCode = await _resolveCustomerCode(customerId);

    final itemRows = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    final lines = <Map<String, dynamic>>[];
    for (final row in itemRows) {
      final productId = row['product_id']?.toString();
      String code = productId ?? '';
      if (productId != null) {
        final products = await db.query(
          'products',
          columns: ['code'],
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );
        if (products.isNotEmpty && products.first['code'] != null) {
          code = products.first['code'].toString();
        }
      }
      lines.add({
        'product_code': code,
        'quantity': row['quantity'],
        'price': row['price'],
      });
    }

    return LogoPayloadMapper.orderFromLocal(
      order: Map<String, dynamic>.from(order),
      items: lines,
      customerCode: customerCode,
    );
  }

  Future<Map<String, dynamic>?> _buildCollectionPayload(
    String collectionId,
  ) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    final rows = await db.query(
      'collections',
      where: 'id = ?',
      whereArgs: [collectionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final c = rows.first;
    final customerCode =
        await _resolveCustomerCode(c['customer_id']?.toString());
    return LogoPayloadMapper.collectionFromLocal(
      customerCode: customerCode,
      amount: (c['amount'] as num?)?.toDouble() ?? 0,
      paymentType: c['payment_type']?.toString() ?? 'Cash',
      description: c['notes']?.toString(),
    );
  }

  Future<String> _resolveCustomerCode(String? customerId) async {
    if (customerId == null || customerId.isEmpty) return 'UNKNOWN';
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    try {
      final rows = await db.query(
        'customers',
        where: 'id = ?',
        whereArgs: [customerId],
        limit: 1,
      );
      if (rows.isEmpty) return customerId;
      final row = rows.first;
      // code kolonu migration sonrası varsa kullan
      if (row.containsKey('code') &&
          row['code'] != null &&
          row['code'].toString().isNotEmpty) {
        return row['code'].toString();
      }
      if (row['tax_no'] != null && row['tax_no'].toString().isNotEmpty) {
        return row['tax_no'].toString();
      }
      return customerId;
    } catch (_) {
      return customerId;
    }
  }

  Future<void> _markEntitySynced(String type, String entityId) async {
    final table = switch (type) {
      'order' || 'orders' => 'orders',
      'invoice' || 'invoices' => 'invoices',
      'collection' || 'collections' => 'collections',
      _ => null,
    };
    if (table == null) return;
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      await db.update(
        table,
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [entityId],
      );
    } catch (e) {
      debugPrint('is_synced update failed ($table): $e');
    }
  }
}
