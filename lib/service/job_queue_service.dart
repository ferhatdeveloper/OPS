// Dosya Adı: job_queue_service.dart
// Açıklama: Offline sync kuyruğu — Logo REST aktarımı
// Oluşturulma Tarihi: 2026-02-22
// Geliştirici: EXFIN OPS Team
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/database/migrations/SqlQuerys.dart';
import '../core/services/logo_api_service.dart';
import '../core/services/logo_payload_mapper.dart';
import '../modules/field_sales/ai_insights/viewmodel/supply_request_logo_sync_mapper.dart';
import 'database_service.dart';
import 'job_queue_entity_map.dart';

export 'job_queue_entity_map.dart';

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
    // Tablo yoksa oluştur (LogoJobStore / dens ekranlarla uyumlu)
    await db.execute(SqlQuerys.createSyncQueueTable);
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
          await _markEntitySynced(type, entityId, payload);
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
        case 'waybill':
        case 'waybills':
          if (payload == null) {
            return LogoApiResult.fail('İrsaliye payload boş');
          }
          final items = (payload['items'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              (payload['lines'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              const [];
          final customerCode = (payload['customer_code'] ??
                  payload['arp_code'] ??
                  payload['ARP_CODE'] ??
                  '')
              .toString();
          if (customerCode.isEmpty) {
            return LogoApiResult.fail('İrsaliye ARP_CODE / customer_code boş');
          }
          // Dispatch TYPE — invoice entity / TYPE 8 flatten yasak
          final header = LogoPayloadMapper.dispatchHeaderFromLocal(
            customerCode: customerCode,
            header: Map<String, dynamic>.from(payload)
              ..remove('items')
              ..remove('lines'),
            dispatchType: (payload['dispatch_type'] ??
                    payload['waybill_type'] ??
                    payload['type'])
                ?.toString(),
          );
          final mappedItems =
              LogoPayloadMapper.dispatchItemsFromLocal(items);
          return logo.createDispatch(header, mappedItems);
        case 'campaign':
        case 'campaigns':
          return logo.createCampaign(payload ?? {'id': entityId});
        case 'day_close':
        case 'audit':
          // Gün sonu plaka/km + denetim: yerel audit_log; Logo endpoint yok
          return LogoApiResult.ok({
            'skipped': true,
            'entity_type': type,
            'entity_id': entityId,
          });
        case 'production_receipt':
        case 'production_receipts':
        case 'stock_production':
          // Üretimden giriş — Logo material slip API henüz yok; kuyrukta tut
          if (payload == null || payload.isEmpty) {
            return LogoApiResult.fail('Üretimden giriş payload boş');
          }
          return LogoApiResult.fail(
            'Üretimden giriş Logo aktarımı henüz bağlanmadı',
          );
        case 'stock_transfer':
        case 'warehouse_transfer':
        case 'warehouse_transfers':
          if (payload == null || payload.isEmpty) {
            return LogoApiResult.fail('Ambar transfer payload boş');
          }
          return logo.createStockTransfer(payload);
        case 'visit':
        case 'visits':
          if (!isVisitQueuePayloadReady(payload)) {
            return LogoApiResult.fail('Ziyaret payload boş');
          }
          return LogoApiResult.ok(visitQueueSkippedData(payload!));
        case 'bank_card':
        case 'bank_cards':
          return _syncFinanceMasterStub(
            type,
            entityId,
            payload,
            normalize: LogoPayloadMapper.bankCardFromLocal,
          );
        case 'check_portfolio':
        case 'check_portfolios':
          return _syncFinanceMasterStub(
            type,
            entityId,
            payload,
            normalize: LogoPayloadMapper.checkPortfolioFromLocal,
          );
        case 'promissory_portfolio':
        case 'promissory_portfolios':
        case 'promissory_note':
          return _syncFinanceMasterStub(
            type,
            entityId,
            payload,
            normalize: LogoPayloadMapper.promissoryPortfolioFromLocal,
          );
        case 'supplier_purchase_request':
        case 'supplier_purchase_requests':
        case 'supply_request':
          return _syncSupplierPurchaseRequest(logo, entityId, payload);
        default:
          debugPrint('Bilinmeyen entity_type: $type — atlanıyor');
          return LogoApiResult.ok({'skipped': true});
      }
    } catch (e) {
      return LogoApiResult.fail(e.toString());
    }
  }

  /// Banka / çek / senet master — Logo endpoint stub (normalize + skipped ok).
  LogoApiResult _syncFinanceMasterStub(
    String type,
    String entityId,
    Map<String, dynamic>? payload, {
    required Map<String, dynamic> Function(Map<String, dynamic> row) normalize,
  }) {
    if (payload == null || payload.isEmpty) {
      return LogoApiResult.fail('$type payload boş');
    }
    final body = normalize(Map<String, dynamic>.from(payload));
    return LogoApiResult.ok({
      'skipped': true,
      'sync_stub': true,
      'entity_type': type,
      'entity_id': entityId,
      'payload': body,
    });
  }

  /// Tedarik talebi → Logo satın alma siparişi (`POST /orders`, purchase).
  ///
  /// [SupplyRequestLogoSyncMapper.useRealLogoPurchasePath] false veya
  /// payload `stub: true` → yerel is_synced işaretleme (stub ok).
  Future<LogoApiResult> _syncSupplierPurchaseRequest(
    LogoApiService logo,
    String entityId,
    Map<String, dynamic>? payload,
  ) async {
    if (payload == null || payload.isEmpty) {
      return LogoApiResult.fail('supplier_purchase_request payload boş');
    }
    final stub = payload['stub'] == true ||
        !SupplyRequestLogoSyncMapper.useRealLogoPurchasePath;
    if (stub) {
      return LogoApiResult.ok({
        'skipped': true,
        'sync_stub': true,
        'entity_type': SupplyRequestLogoSyncMapper.entityType,
        'entity_id': entityId,
        'payload': payload,
      });
    }
    final body = _ensureOrderTypeFields(Map<String, dynamic>.from(payload));
    body['type'] = 'purchase';
    body['order_type'] = 'purchase';
    body['order_channel'] = LogoPayloadMapper.orderChannelKey('purchase');
    return logo.createOrder(body);
  }

  Future<LogoApiResult> _syncOrder(
    LogoApiService logo,
    String entityId,
    Map<String, dynamic>? payload,
  ) async {
    if (payload != null &&
        (payload.containsKey('lines') || payload.containsKey('customer_code'))) {
      return logo.createOrder(_ensureOrderTypeFields(payload));
    }

    final built = await _buildOrderPayload(entityId);
    if (built == null) {
      return LogoApiResult.fail('Sipariş bulunamadı: $entityId');
    }
    return logo.createOrder(built);
  }

  /// Sipariş payload'ında sales/purchase kanalını garanti eder.
  /// Fatura `wholesale` / TYPE 8 alanlarına flatten etmez.
  Map<String, dynamic> _ensureOrderTypeFields(Map<String, dynamic> payload) {
    final body = Map<String, dynamic>.from(payload);
    final apiType = LogoPayloadMapper.resolveOrderApiType(
      body['type']?.toString() ??
          body['order_type']?.toString() ??
          body['order_channel']?.toString(),
    );
    body['type'] = apiType;
    body['order_type'] = apiType;
    body['order_channel'] = LogoPayloadMapper.orderChannelKey(apiType);
    return body;
  }

  Future<LogoApiResult> _syncInvoice(
    LogoApiService logo,
    String entityId,
    Map<String, dynamic>? payload,
  ) async {
    // ExfinApi: local_invoice_id + type (wholesale|return|purchase|retail)
    // logo_type/TRCODE: 8 toptan, 3 iade, 1 alış — return→wholesale flatten yok
    // Sipariş endpoint'ine düşürme: order sales/purchase kanalı fatura TYPE ezmez
    final rawType = payload?['type']?.toString() ??
        payload?['invoice_type']?.toString() ??
        LogoPayloadMapper.invoiceQueueWholesale;
    final mappedType = LogoPayloadMapper.resolveInvoiceQueueType(rawType);

    return logo.createInvoice(
      localInvoiceId: entityId,
      type: mappedType,
    );
  }

  Future<LogoApiResult> _syncCollection(
    LogoApiService logo,
    String entityId,
    Map<String, dynamic>? payload,
  ) async {
    if (payload != null) {
      final paymentType =
          (payload['payment_type'] ?? '').toString().toLowerCase();
      final isVirman = paymentType == 'virman';
      final code =
          (payload['customer_code'] ?? payload['arp_code'] ?? '').toString();
      final amount = (payload['amount'] as num?)?.toDouble();
      // Virman: ARP zorunlu değil; payment_type=virman korunur (cash flatten yok)
      if (isVirman && amount != null && amount > 0) {
        return logo.createCollectionSync(payload);
      }
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
    final builtType =
        (built['payment_type'] ?? '').toString().toLowerCase();
    if (builtType == 'virman') {
      return logo.createCollectionSync(built);
    }
    final sync = await logo.createCollectionSync(built);
    if (sync.success) return sync;
    return logo.createCollectionSimple(
      customerCode: (built['customer_code'] ?? '').toString(),
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
        'discount_percent': row['discount_percent'] ?? 0,
      });
    }

    final orderMap = Map<String, dynamic>.from(order);
    // DB order_type → queue type (sales|purchase); satışa flatten yok
    if (!orderMap.containsKey('type') && orderMap['order_type'] != null) {
      orderMap['type'] = orderMap['order_type'];
    }
    return LogoPayloadMapper.orderFromLocal(
      order: orderMap,
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
    final paymentType = c['payment_type']?.toString() ?? 'Cash';
    final amount = (c['amount'] as num?)?.toDouble() ?? 0;
    if (paymentType.toLowerCase() == 'virman') {
      return LogoPayloadMapper.virmanFromLocal(
        amount: amount,
        fromSafeCode: c['cash_code']?.toString() ?? '',
        toSafeCode: c['target_cash_code']?.toString() ?? '',
        description: c['notes']?.toString(),
      );
    }
    final customerCode =
        await _resolveCustomerCode(c['customer_id']?.toString());
    DateTime? due;
    final dueRaw = c['due_date']?.toString();
    if (dueRaw != null && dueRaw.isNotEmpty) {
      due = DateTime.tryParse(dueRaw);
    }
    return LogoPayloadMapper.collectionFromLocal(
      customerCode: customerCode,
      amount: amount,
      paymentType: paymentType,
      safeCode: c['cash_code']?.toString(),
      description: c['notes']?.toString(),
      documentNo: c['document_no']?.toString(),
      currencyCode: c['currency_code']?.toString(),
      exchangeRate: (c['exchange_rate'] as num?)?.toDouble(),
      baseAmount: (c['base_amount'] as num?)?.toDouble(),
      baseCurrencyCode: c['base_currency_code']?.toString(),
      salesmanCode: c['salesperson_code']?.toString(),
      specialCode1: c['special_code_1']?.toString(),
      bankName: c['bank_name']?.toString(),
      branchName: c['branch_name']?.toString(),
      checkNumber: c['check_number']?.toString(),
      dueDate: due,
      endorsement: c['endorsement']?.toString(),
      originalDebtor: c['original_debtor']?.toString(),
      workplace: c['workplace']?.toString(),
      accountNumber: c['account_number']?.toString(),
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

  Future<void> _markEntitySynced(
    String type,
    String entityId, [
    Map<String, dynamic>? payload,
  ]) async {
    final table = jobQueueEntityTable(type);
    if (table == 'warehouse_transfers') {
      await _markWarehouseTransfersSynced(entityId, payload);
      return;
    }
    if (table == null) return;
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      final values = <String, Object?>{'is_synced': 1};
      if (table == 'supplier_purchase_requests') {
        values['status'] = 'synced';
        values['ONAY'] = 2;
        values['updated_at'] = DateTime.now().toIso8601String();
      }
      await db.update(
        table,
        values,
        where: 'id = ?',
        whereArgs: [entityId],
      );
    } catch (e) {
      debugPrint('is_synced update failed ($table): $e');
    }
  }

  /// Ambar transfer satırlarını `transfer_ids` veya entityId ile işaretler.
  Future<void> _markWarehouseTransfersSynced(
    String entityId,
    Map<String, dynamic>? payload,
  ) async {
    final ids = <String>[];
    final raw = payload?['transfer_ids'];
    if (raw is List) {
      for (final e in raw) {
        final s = e?.toString() ?? '';
        if (s.isNotEmpty) ids.add(s);
      }
    }
    if (ids.isEmpty) ids.add(entityId);

    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      for (final id in ids) {
        await db.update(
          'warehouse_transfers',
          {'is_synced': 1, 'status': 'Completed'},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      debugPrint('warehouse_transfers is_synced update failed: $e');
    }
  }
}
