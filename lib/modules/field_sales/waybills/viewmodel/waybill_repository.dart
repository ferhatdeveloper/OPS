// Dosya Adı: waybill_repository.dart
// Açıklama: İrsaliye SQLite kaydı + sync_queue enqueue (dispatch TYPE)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../model/waybill_model.dart';
import '../model/waybill_type.dart';

/// {@template WaybillUnsyncedRow}
/// Transfer edilmeyen / bekleyen irsaliye dens satırı (`is_synced=0`).
///
/// Kullanım örneği:
/// ```dart
/// final rows = await const WaybillRepository().listUnsynced(db);
/// ```
/// {@endtemplate}
class WaybillUnsyncedRow {
  /// [id]: İrsaliye kimliği
  final String id;

  /// [customerId]: Cari kimliği
  final String customerId;

  /// [customerCode]: Cari kodu (Logo ARP)
  final String? customerCode;

  /// [customerName]: Cari ünvan
  final String? customerName;

  /// [waybillDate]: Belge tarihi
  final DateTime waybillDate;

  /// [waybillType]: `waybill_wholesale` | `waybill_purchase`
  final String waybillType;

  /// [totalAmount]: Bilgilendirme tutarı
  final double totalAmount;

  /// [status]: Durum metni
  final String status;

  /// [notes]: Not
  final String? notes;

  /// [isSynced]: Her zaman 0 (filtre sonucu)
  final int isSynced;

  /// {@macro WaybillUnsyncedRow}
  const WaybillUnsyncedRow({
    required this.id,
    required this.customerId,
    required this.waybillDate,
    required this.waybillType,
    this.customerCode,
    this.customerName,
    this.totalAmount = 0,
    this.status = 'Completed',
    this.notes,
    this.isSynced = 0,
  });

  /// {@template WaybillUnsyncedRow.fromMap}
  /// JOIN satırından dens model.
  /// {@endtemplate}
  factory WaybillUnsyncedRow.fromMap(Map<String, dynamic> map) {
    return WaybillUnsyncedRow(
      id: map['id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      customerCode: map['customer_code']?.toString(),
      customerName: map['customer_name']?.toString(),
      waybillDate:
          DateTime.tryParse(map['waybill_date']?.toString() ?? '') ??
              DateTime.now(),
      waybillType:
          map['waybill_type']?.toString() ?? 'waybill_wholesale',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? 'Completed',
      notes: map['notes']?.toString(),
      isSynced: (map['is_synced'] as num?)?.toInt() ?? 0,
    );
  }
}

/// {@template WaybillValidationResult}
/// Kaydet öncesi doğrulama sonucu.
/// {@endtemplate}
class WaybillValidationResult {
  /// [isValid]: Geçerli mi
  final bool isValid;

  /// [errorKey]: l10n hata anahtarı
  final String? errorKey;

  const WaybillValidationResult({
    required this.isValid,
    this.errorKey,
  });
}

/// {@template WaybillSaveResult}
/// Kaydet + enqueue sonucu.
/// {@endtemplate}
class WaybillSaveResult {
  /// [ok]: Başarılı mı
  final bool ok;

  /// [waybillId]: Oluşan irsaliye id
  final String? waybillId;

  /// [errorKey]: l10n hata anahtarı
  final String? errorKey;

  const WaybillSaveResult({
    required this.ok,
    this.waybillId,
    this.errorKey,
  });
}

/// {@template WaybillRepository}
/// İrsaliye yerel kalıcılık ve Logo dispatch kuyruğu.
///
/// Kullanım örneği:
/// ```dart
/// final result = await const WaybillRepository().saveAndEnqueue(
///   db,
///   customerId: cariId,
///   waybillType: WaybillType.wholesale,
///   lines: inputs,
/// );
/// ```
/// {@endtemplate}
class WaybillRepository {
  const WaybillRepository();

  /// {@template WaybillRepository.listUnsynced}
  /// SQLite `waybills` — `is_synced = 0` dens listesi (cari JOIN).
  ///
  /// Parametreler:
  /// - [db]: SQLite bağlantısı
  ///
  /// Dönüş değeri:
  /// - [List<WaybillUnsyncedRow>]: Transfer edilmeyen / bekleyen satırlar
  /// {@endtemplate}
  Future<List<WaybillUnsyncedRow>> listUnsynced(Database db) async {
    final maps = await db.rawQuery('''
      SELECT
        w.id,
        w.customer_id,
        w.waybill_date,
        w.waybill_type,
        w.total_amount,
        w.status,
        w.notes,
        w.is_synced,
        c.code AS customer_code,
        c.name AS customer_name
      FROM waybills w
      LEFT JOIN customers c ON c.id = w.customer_id
      WHERE w.is_synced = 0
      ORDER BY w.waybill_date DESC
    ''');
    return maps.map(WaybillUnsyncedRow.fromMap).toList();
  }

  /// {@template WaybillRepository.validate}
  /// Cari + kalem guard.
  ///
  /// Parametreler:
  /// - [customerId]: Cari kimliği
  /// - [lines]: Dens kalemleri
  ///
  /// Dönüş değeri:
  /// - [WaybillValidationResult]: Geçerlilik + l10n anahtarı
  /// {@endtemplate}
  static WaybillValidationResult validate({
    required String? customerId,
    required List<WaybillLineInput> lines,
  }) {
    if (customerId == null || customerId.trim().isEmpty) {
      return const WaybillValidationResult(
        isValid: false,
        errorKey: 'field_sales.waybill_save_requires_customer',
      );
    }
    if (lines.isEmpty) {
      return const WaybillValidationResult(
        isValid: false,
        errorKey: 'field_sales.waybill_min_products',
      );
    }
    return const WaybillValidationResult(isValid: true);
  }

  /// {@template WaybillRepository.list}
  /// SQLite `waybills` dens listesi (tarih azalan).
  ///
  /// Parametreler:
  /// - [db]: SQLite bağlantısı
  /// - [customerId]: Opsiyonel cari filtresi
  ///
  /// Dönüş değeri:
  /// - [List<WaybillModel>]: İrsaliye başlıkları
  /// {@endtemplate}
  Future<List<WaybillModel>> list(
    Database db, {
    String? customerId,
  }) async {
    final trimmed = customerId?.trim();
    final hasCustomer = trimmed != null && trimmed.isNotEmpty;
    final rows = await db.query(
      'waybills',
      where: hasCustomer ? 'customer_id = ?' : null,
      whereArgs: hasCustomer ? [trimmed] : null,
      orderBy: 'waybill_date DESC',
    );
    return rows.map(WaybillModel.fromMap).toList(growable: false);
  }

  /// {@template WaybillRepository.saveAndEnqueue}
  /// SQLite `waybills`/`waybill_items` + `sync_queue` (entity=dispatch).
  /// Dispatch TYPE korunur; fatura TYPE 8 flatten yok.
  ///
  /// Parametreler:
  /// - [db]: SQLite bağlantısı
  /// - [customerId]: Cari kimliği
  /// - [waybillType]: Toptan / satın alma
  /// - [lines]: Kalemler
  /// - [notes]: Opsiyonel not
  ///
  /// Dönüş değeri:
  /// - [WaybillSaveResult]: Başarı / hata
  /// {@endtemplate}
  Future<WaybillSaveResult> saveAndEnqueue(
    Database db, {
    required String customerId,
    required WaybillType waybillType,
    required List<WaybillLineInput> lines,
    String? notes,
  }) async {
    final check = validate(customerId: customerId, lines: lines);
    if (!check.isValid) {
      return WaybillSaveResult(ok: false, errorKey: check.errorKey);
    }

    final waybillId = const Uuid().v4();
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    var total = 0.0;
    for (final line in lines) {
      total += line.quantity * line.unitPrice;
    }

    final header = WaybillModel(
      id: waybillId,
      customerId: customerId.trim(),
      waybillDate: now,
      waybillType: waybillType.localKey,
      totalAmount: total,
      status: 'Completed',
      notes: notes,
      isSynced: 0,
    );

    final itemModels = <WaybillItemModel>[];
    for (final line in lines) {
      itemModels.add(
        WaybillItemModel(
          id: const Uuid().v4(),
          waybillId: waybillId,
          productId: line.productId,
          productCode: line.productCode.isNotEmpty
              ? line.productCode
              : line.productId,
          quantity: line.quantity,
          price: line.unitPrice,
          totalAmount: line.quantity * line.unitPrice,
        ),
      );
    }

    await db.transaction((txn) async {
      final map = header.toMap();
      map['approval_status'] = 1;
      map['created_at'] = nowIso;
      map['updated_at'] = nowIso;
      await txn.insert('waybills', map);

      for (final item in itemModels) {
        final itemMap = item.toMap();
        itemMap['updated_at'] = nowIso;
        await txn.insert('waybill_items', itemMap);
      }
    });

    final customerCode = await _resolveCustomerCode(db, customerId.trim());
    final payloadItems = itemModels
        .map(
          (i) => {
            'product_code': i.productCode,
            'quantity': i.quantity,
            'price': i.price,
          },
        )
        .toList();

    final payload = WaybillType.buildDispatchQueuePayload(
      customerCode: customerCode,
      waybillType: waybillType,
      items: payloadItems,
      header: {
        'id': waybillId,
        'notes': notes,
        'date': nowIso,
      },
    );

    await db.insert('sync_queue', {
      'id': const Uuid().v4(),
      'entity_type': 'dispatch',
      'entity_id': waybillId,
      'payload': jsonEncode(payload),
      'priority': 2,
      'retry_count': 0,
      'created_at': nowIso,
    });

    return WaybillSaveResult(ok: true, waybillId: waybillId);
  }

  /// {@template _resolveCustomerCode}
  /// Cari `code` / `tax_no` / id → Logo ARP_CODE.
  /// {@endtemplate}
  Future<String> _resolveCustomerCode(Database db, String customerId) async {
    try {
      final rows = await db.query(
        'customers',
        where: 'id = ?',
        whereArgs: [customerId],
        limit: 1,
      );
      if (rows.isEmpty) return customerId;
      final row = rows.first;
      final code = row['code']?.toString();
      if (code != null && code.isNotEmpty) return code;
      final tax = row['tax_no']?.toString();
      if (tax != null && tax.isNotEmpty) return tax;
      return customerId;
    } catch (_) {
      return customerId;
    }
  }
}
