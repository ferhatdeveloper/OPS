// Dosya Adı: whms_location_store.dart
// Açıklama: whms_locations SQLite ensure / dens CRUD (upsert · soft delete)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/whms_location.dart';

/// {@template whms_location_store}
/// `whms_locations` tablo hazırlığı + listActive / upsert / softDelete.
///
/// Kullanım örneği:
/// ```dart
/// final store = WhmsLocationStore();
/// await store.ensureReady();
/// final rows = await store.listActive(warehouseCode: 'MRK');
/// ```
/// {@endtemplate}
class WhmsLocationStore {
  /// [openDb]: Test DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro whms_location_store}
  const WhmsLocationStore({this.openDb});

  /// [tableName]: SQLite tablo
  static const String tableName = 'whms_locations';

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template whms_location_store_ensure}
  /// Tabloyu [SqlQuerys.createWhmsLocationsTable] ile hazırlar.
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createWhmsLocationsTable);
  }

  /// {@template whms_location_store_list}
  /// Aktif (silinmemiş) lokasyonlar; opsiyonel ambar filtresi.
  ///
  /// Parametreler:
  /// - [warehouseCode]: null/boş → tüm ambarlar
  ///
  /// Dönüş değeri:
  /// - [List<WhmsLocation>]: route_seq + kod sırası
  /// {@endtemplate}
  Future<List<WhmsLocation>> listActive({String? warehouseCode}) async {
    await ensureReady();
    final db = await _db();
    final code = warehouseCode?.trim() ?? '';
    final maps = code.isEmpty
        ? await db.query(
            tableName,
            where: 'COALESCE(is_deleted, 0) = 0 '
                'AND COALESCE(is_active, 1) = 1',
            orderBy: 'warehouse_code ASC, route_seq ASC, code ASC',
          )
        : await db.query(
            tableName,
            where: 'COALESCE(is_deleted, 0) = 0 '
                'AND COALESCE(is_active, 1) = 1 '
                'AND warehouse_code = ?',
            whereArgs: <Object>[code],
            orderBy: 'route_seq ASC, code ASC',
          );
    return maps.map(WhmsLocation.fromMap).toList(growable: false);
  }

  /// {@template whms_location_store_upsert}
  /// id doluysa günceller; boşsa yeni satır ekler.
  /// UNIQUE(warehouse_code, code) çakışmasında replace.
  ///
  /// Parametreler:
  /// - [location]: Zorunlu warehouseCode + code
  ///
  /// Dönüş değeri:
  /// - [WhmsLocation]: Kaydedilen satır
  ///
  /// Fırlatılan hatalar:
  /// - [ArgumentError]: warehouse/code boş
  /// {@endtemplate}
  Future<WhmsLocation> upsert(WhmsLocation location) async {
    final wh = location.warehouseCode.trim();
    final locCode = location.code.trim();
    if (wh.isEmpty || locCode.isEmpty) {
      throw ArgumentError('warehouse_code and code required');
    }

    await ensureReady();
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    final id = location.id.trim().isEmpty
        ? const Uuid().v4()
        : location.id.trim();

    final row = WhmsLocation(
      id: id,
      warehouseCode: wh,
      code: locCode,
      aisle: location.aisle.trim(),
      rack: location.rack.trim(),
      bin: location.bin.trim(),
      barcode: location.barcode.trim(),
      routeSeq: location.routeSeq,
      isActive: location.isActive,
      isSynced: false,
      isDeleted: false,
      createdAt: location.createdAt?.trim().isNotEmpty == true
          ? location.createdAt
          : now,
      updatedAt: now,
    );

    await db.insert(
      tableName,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return row;
  }

  /// {@template whms_location_store_soft_delete}
  /// Soft delete (`is_deleted=1`, `is_active=0`).
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
        'is_active': 0,
        'is_synced': 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: <Object>[trimmed],
    );
  }
}
