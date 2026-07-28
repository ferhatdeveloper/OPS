// Dosya Adı: whms_count_order_store.dart
// Açıklama: whms_count_orders SQLite CRUD (emir listesi / taslak / ONAY)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../../contract/whms_bridge_dto.dart';
import '../model/whms_count_order.dart';

/// {@template whms_count_order_store}
/// `whms_count_orders` tablo hazırlığı + list / draft insert / ONAY / soft-delete.
///
/// Kullanım örneği:
/// ```dart
/// final store = WhmsCountOrderStore();
/// await store.ensureReady();
/// final rows = await store.list();
/// ```
/// {@endtemplate}
class WhmsCountOrderStore {
  /// [openDb]: Test DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro whms_count_order_store}
  const WhmsCountOrderStore({this.openDb});

  /// [tableName]: SQLite tablo
  static const String tableName = 'whms_count_orders';

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template whms_count_order_store_ensure}
  /// Tabloyu `SqlQuerys.createWhmsCountOrdersTable` ile hazırlar.
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createWhmsCountOrdersTable);
  }

  /// {@template whms_count_order_store_list}
  /// Aktif (silinmemiş) sayım emirleri.
  ///
  /// Parametreler:
  /// - [warehouseCode]: null/boş → tüm ambarlar
  ///
  /// Dönüş değeri:
  /// - [List<WhmsCountOrder>]: order_date DESC
  /// {@endtemplate}
  Future<List<WhmsCountOrder>> list({String? warehouseCode}) async {
    await ensureReady();
    final db = await _db();
    final code = warehouseCode?.trim() ?? '';
    final maps = code.isEmpty
        ? await db.query(
            tableName,
            where: 'COALESCE(is_deleted, 0) = 0',
            orderBy: 'order_date DESC, updated_at DESC',
          )
        : await db.query(
            tableName,
            where: 'COALESCE(is_deleted, 0) = 0 '
                'AND warehouse_code = ?',
            whereArgs: <Object>[code],
            orderBy: 'order_date DESC, updated_at DESC',
          );
    return maps.map(WhmsCountOrder.fromMap).toList(growable: false);
  }

  /// {@template whms_count_order_store_get_by_id}
  /// Emir id ile tek satır (silinmiş hariç).
  ///
  /// Parametreler:
  /// - [id]: Emir id
  ///
  /// Dönüş değeri:
  /// - [WhmsCountOrder?] — yoksa null
  /// {@endtemplate}
  Future<WhmsCountOrder?> getById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: 'id = ? AND COALESCE(is_deleted, 0) = 0',
      whereArgs: <Object>[trimmed],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return WhmsCountOrder.fromMap(maps.first);
  }

  /// {@template whms_count_order_store_insert_draft}
  /// Taslak sayım emri ekler (ONAY=0, status=draft).
  ///
  /// Parametreler:
  /// - [warehouseCode]: Ambar kodu
  /// - [locationCode]: Opsiyonel lokasyon
  /// - [productCodes]: Ürün filtresi
  /// - [orderDate]: Emir tarihi (varsayılan bugün)
  ///
  /// Dönüş değeri:
  /// - [WhmsCountOrder]: Kaydedilen satır
  ///
  /// Fırlatılan hatalar:
  /// - [ArgumentError]: Ambar boş
  /// {@endtemplate}
  Future<WhmsCountOrder> insertDraft({
    required String warehouseCode,
    String? locationCode,
    List<String> productCodes = const [],
    DateTime? orderDate,
  }) async {
    final wh = warehouseCode.trim();
    if (wh.isEmpty) {
      throw ArgumentError('warehouse_code required');
    }

    await ensureReady();
    final db = await _db();
    final now = DateTime.now();
    final row = WhmsCountOrder(
      id: const Uuid().v4(),
      warehouseCode: wh,
      locationCode: locationCode?.trim().isEmpty == true
          ? null
          : locationCode?.trim(),
      status: WhmsCountOrderStatus.draft,
      productCodes: productCodes,
      orderDate: orderDate ?? now,
      approval: WhmsApprovalStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert(tableName, row.toMap());
    return row;
  }

  /// {@template whms_count_order_store_update_status}
  /// Emir status (+ opsiyonel ONAY) günceller.
  ///
  /// Parametreler:
  /// - [id]: Emir id
  /// - [status]: Yeni durum
  /// - [approval]: Opsiyonel ONAY
  /// {@endtemplate}
  Future<void> updateStatus({
    required String id,
    required WhmsCountOrderStatus status,
    WhmsApprovalStatus? approval,
  }) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;
    await ensureReady();
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    final map = <String, Object?>{
      'status': status.name,
      'is_synced': 0,
      'updated_at': now,
    };
    if (approval != null) {
      map['ONAY'] = _approvalToInt(approval);
    }
    await db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: <Object>[trimmed],
    );
  }

  /// {@template whms_count_order_store_set_approval}
  /// ONAY kolonunu günceller; is_synced sıfırlanır.
  ///
  /// Parametreler:
  /// - [id]: Emir id
  /// - [approval]: Yeni ONAY durumu
  /// {@endtemplate}
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
        'ONAY': _approvalToInt(approval),
        'is_synced': 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: <Object>[trimmed],
    );
  }

  /// {@template whms_count_order_store_soft_delete}
  /// Soft delete (is_deleted = 1).
  ///
  /// Parametreler:
  /// - [id]: Emir id
  /// {@endtemplate}
  Future<void> softDelete(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;
    await ensureReady();
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    await db.update(
      tableName,
      <String, Object?>{
        'is_deleted': 1,
        'is_synced': 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: <Object>[trimmed],
    );
  }

  static int _approvalToInt(WhmsApprovalStatus status) {
    switch (status) {
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
