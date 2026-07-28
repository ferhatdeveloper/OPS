// Dosya Adı: whms_count_result_store.dart
// Açıklama: whms_count_results SQLite — yerel sayım fark kaydı
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../../contract/whms_bridge_dto.dart';
import '../model/whms_count_order.dart';
import '../model/whms_count_result_line.dart';

/// {@template whms_count_result_row}
/// Yerel sayım fark satırı (persist).
/// {@endtemplate}
class WhmsCountResultRow {
  /// [id]: PK
  final String id;

  /// [orderId]: Bağlı emir
  final String? orderId;

  /// [warehouseCode]: Ambar
  final String warehouseCode;

  /// [locationCode]: Lokasyon
  final String? locationCode;

  /// [countDate]: Sayım tarihi ISO
  final String countDate;

  /// [varianceQty]: Toplam fark miktarı (fiili − sistem)
  final double varianceQty;

  /// [approval]: ONAY
  final WhmsApprovalStatus approval;

  /// [linesJson]: Satır JSON
  final String linesJson;

  /// {@macro whms_count_result_row}
  const WhmsCountResultRow({
    required this.id,
    required this.warehouseCode,
    required this.countDate,
    this.orderId,
    this.locationCode,
    this.varianceQty = 0,
    this.approval = WhmsApprovalStatus.pending,
    this.linesJson = '[]',
  });

  factory WhmsCountResultRow.fromMap(Map<String, dynamic> map) {
    return WhmsCountResultRow(
      id: map['id']?.toString() ?? '',
      orderId: map['order_id']?.toString(),
      warehouseCode: map['warehouse_code']?.toString() ?? '',
      locationCode: map['location_code']?.toString(),
      countDate: map['count_date']?.toString() ?? '',
      varianceQty: (map['variance_qty'] as num?)?.toDouble() ?? 0,
      approval: _approvalFromInt((map['ONAY'] as num?)?.toInt() ?? 0),
      linesJson: map['lines_json']?.toString() ?? '[]',
    );
  }

  Map<String, dynamic> toMap({
    required String createdAt,
    required String updatedAt,
  }) {
    return <String, dynamic>{
      'id': id,
      'order_id': orderId,
      'warehouse_code': warehouseCode,
      'location_code': locationCode,
      'count_date': countDate,
      'lines_json': linesJson,
      'variance_qty': varianceQty,
      'ONAY': _approvalToInt(approval),
      'is_synced': 0,
      'is_deleted': 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static WhmsApprovalStatus _approvalFromInt(int v) {
    switch (v) {
      case 1:
        return WhmsApprovalStatus.approved;
      case 2:
        return WhmsApprovalStatus.synced;
      case 3:
        return WhmsApprovalStatus.rejected;
      case 4:
        return WhmsApprovalStatus.error;
      default:
        return WhmsApprovalStatus.pending;
    }
  }

  static int _approvalToInt(WhmsApprovalStatus s) {
    switch (s) {
      case WhmsApprovalStatus.pending:
        return 0;
      case WhmsApprovalStatus.approved:
        return 1;
      case WhmsApprovalStatus.synced:
        return 2;
      case WhmsApprovalStatus.rejected:
        return 3;
      case WhmsApprovalStatus.error:
        return 4;
    }
  }
}

/// {@template whms_count_result_store}
/// Sayım fark sonuçlarını SQLite’a yazar (offline-first).
///
/// Kullanım örneği:
/// ```dart
/// await WhmsCountResultStore().recordVariance(
///   warehouseCode: 'MRK',
///   orderId: 'o1',
///   lines: [{'product_code': 'SKU', 'system_qty': 10, 'actual_qty': 9}],
/// );
/// ```
/// {@endtemplate}
class WhmsCountResultStore {
  /// [openDb]: Test DB
  final Future<Database> Function()? openDb;

  /// {@macro whms_count_result_store}
  const WhmsCountResultStore({this.openDb});

  static const String tableName = 'whms_count_results';

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// Tablo hazırlığı.
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createWhmsCountResultsTable);
  }

  /// Aktif fark kayıtları.
  Future<List<WhmsCountResultRow>> list({String? warehouseCode}) async {
    await ensureReady();
    final db = await _db();
    final code = warehouseCode?.trim() ?? '';
    final maps = code.isEmpty
        ? await db.query(
            tableName,
            where: 'COALESCE(is_deleted, 0) = 0',
            orderBy: 'count_date DESC, updated_at DESC',
          )
        : await db.query(
            tableName,
            where: 'COALESCE(is_deleted, 0) = 0 '
                'AND warehouse_code = ?',
            whereArgs: <Object>[code],
            orderBy: 'count_date DESC, updated_at DESC',
          );
    return maps.map(WhmsCountResultRow.fromMap).toList(growable: false);
  }

  /// Emir id ile son aktif sonuç (taslak veya tamamlanmış).
  Future<WhmsCountResultRow?> findByOrderId(String orderId) async {
    final oid = orderId.trim();
    if (oid.isEmpty) return null;
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: 'order_id = ? AND COALESCE(is_deleted, 0) = 0',
      whereArgs: <Object>[oid],
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return WhmsCountResultRow.fromMap(maps.first);
  }

  /// lines_json → satır listesi.
  static List<WhmsCountResultLine> parseLines(String linesJson) {
    try {
      final decoded = jsonDecode(linesJson);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (e) => WhmsCountResultLine.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// {@template whms_count_result_store_upsert_draft}
  /// Sayım devam ederken satırları SQLite’a yazar (ONAY=0).
  ///
  /// Parametreler:
  /// - [order]: Bağlı emir
  /// - [lines]: Fiili / sistem satırları
  /// - [existingId]: Varsa güncelle
  ///
  /// Dönüş değeri:
  /// - [WhmsCountResultRow]
  /// {@endtemplate}
  Future<WhmsCountResultRow> upsertDraft({
    required WhmsCountOrder order,
    required List<WhmsCountResultLine> lines,
    String? existingId,
  }) async {
    await ensureReady();
    final db = await _db();
    final now = DateTime.now();
    final iso = now.toIso8601String();
    var variance = 0.0;
    for (final line in lines) {
      variance += line.variance;
    }
    final lineMaps = lines.map((l) => l.toMap()).toList(growable: false);
    final id = (existingId?.trim().isNotEmpty == true)
        ? existingId!.trim()
        : const Uuid().v4();
    final row = WhmsCountResultRow(
      id: id,
      orderId: order.id,
      warehouseCode: order.warehouseCode,
      locationCode: order.locationCode,
      countDate: iso,
      varianceQty: variance,
      approval: WhmsApprovalStatus.pending,
      linesJson: jsonEncode(lineMaps),
    );
    final map = row.toMap(createdAt: iso, updatedAt: iso);
    final existing = await db.query(
      tableName,
      columns: ['id'],
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert(tableName, map);
    } else {
      map.remove('created_at');
      await db.update(
        tableName,
        map,
        where: 'id = ?',
        whereArgs: <Object>[id],
      );
    }
    return row;
  }

  /// Sonuç ONAY güncelle.
  Future<void> setApproval({
    required String id,
    required WhmsApprovalStatus approval,
  }) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;
    await ensureReady();
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    await db.update(
      tableName,
      <String, Object?>{
        'ONAY': WhmsCountResultRow._approvalToInt(approval),
        'is_synced': 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: <Object>[trimmed],
    );
  }

  /// {@template whms_count_result_store_record}
  /// Yerel fark kaydı — ERP beklenmez; ONAY=0.
  ///
  /// Parametreler:
  /// - [warehouseCode]: Ambar
  /// - [orderId]: Emir id
  /// - [locationCode]: Lokasyon
  /// - [lines]: system_qty / actual_qty map listesi
  ///
  /// Dönüş değeri:
  /// - [WhmsCountResultRow]
  /// {@endtemplate}
  Future<WhmsCountResultRow> recordVariance({
    required String warehouseCode,
    String? orderId,
    String? locationCode,
    List<Map<String, dynamic>> lines = const [],
    DateTime? date,
  }) async {
    final wh = warehouseCode.trim();
    if (wh.isEmpty) throw ArgumentError('warehouse_code required');

    await ensureReady();
    final db = await _db();
    final now = DateTime.now();
    final when = date ?? now;
    var variance = 0.0;
    for (final line in lines) {
      final sys = (line['system_qty'] as num?)?.toDouble() ?? 0;
      final act = (line['actual_qty'] as num?)?.toDouble() ??
          (line['counted_qty'] as num?)?.toDouble() ??
          0;
      variance += act - sys;
    }
    final row = WhmsCountResultRow(
      id: const Uuid().v4(),
      orderId: orderId?.trim().isEmpty == true ? null : orderId?.trim(),
      warehouseCode: wh,
      locationCode: locationCode?.trim().isEmpty == true
          ? null
          : locationCode?.trim(),
      countDate: when.toIso8601String(),
      varianceQty: variance,
      linesJson: jsonEncode(lines),
    );
    final iso = now.toIso8601String();
    await db.insert(tableName, row.toMap(createdAt: iso, updatedAt: iso));
    return row;
  }
}
