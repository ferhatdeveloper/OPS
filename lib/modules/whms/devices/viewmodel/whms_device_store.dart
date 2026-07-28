// Dosya Adı: whms_device_store.dart
// Açıklama: whms_devices SQLite CRUD (etiket / terminal) + MAC gate destek
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/whms_device.dart';

/// {@template whms_device_store}
/// Cihaz master CRUD — offline-first; MAC normalize + unique.
///
/// Kullanım örneği:
/// ```dart
/// final s = WhmsDeviceStore();
/// await s.ensureReady();
/// await s.insert(name: 'RF-1', mac: 'AA:BB:CC:DD:EE:FF');
/// ```
/// {@endtemplate}
class WhmsDeviceStore {
  /// [openDb]: Test DB
  final Future<Database> Function()? openDb;

  /// {@macro whms_device_store}
  const WhmsDeviceStore({this.openDb});

  static const String tableName = 'whms_devices';

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template whms_device_store_normalize_mac}
  /// MAC’i AA:BB:CC:DD:EE:FF biçimine getirir; geçersizse null.
  ///
  /// Parametreler:
  /// - [raw]: Ham MAC
  ///
  /// Dönüş değeri:
  /// - [String?]: Normalize MAC veya null
  /// {@endtemplate}
  static String? normalizeMac(String? raw) {
    if (raw == null) return null;
    final hex = raw.trim().toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');
    if (hex.length != 12) return null;
    final parts = <String>[];
    for (var i = 0; i < 12; i += 2) {
      parts.add(hex.substring(i, i + 2));
    }
    return parts.join(':');
  }

  /// {@template whms_device_store_ensure}
  /// Tablo + eksik kolonları hazırlar.
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createWhmsDevicesTable);
    await _ensureColumns(db);
  }

  /// {@template whms_device_store_list}
  /// Silinmemiş tüm cihazlar (aktif + pasif).
  /// {@endtemplate}
  Future<List<WhmsDevice>> list() async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: 'COALESCE(is_deleted, 0) = 0',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return maps.map(WhmsDevice.fromMap).toList(growable: false);
  }

  /// {@template whms_device_store_list_active}
  /// Silinmemiş ve aktif cihazlar.
  /// {@endtemplate}
  Future<List<WhmsDevice>> listActive() async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: 'COALESCE(is_deleted, 0) = 0 '
          'AND COALESCE(is_active, 1) = 1',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return maps.map(WhmsDevice.fromMap).toList(growable: false);
  }

  /// {@template whms_device_store_get_by_id}
  /// Tek cihaz; silinmişse null.
  /// {@endtemplate}
  Future<WhmsDevice?> getById(String id) async {
    final key = id.trim();
    if (key.isEmpty) return null;
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: 'id = ? AND COALESCE(is_deleted, 0) = 0',
      whereArgs: <Object>[key],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return WhmsDevice.fromMap(maps.first);
  }

  /// {@template whms_device_store_find_by_mac}
  /// Normalize MAC ile aktif/pasif (silinmemiş) cihaz.
  /// {@endtemplate}
  Future<WhmsDevice?> findByMac(String? mac) async {
    final norm = normalizeMac(mac);
    if (norm == null) return null;
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: 'mac = ? AND COALESCE(is_deleted, 0) = 0',
      whereArgs: <Object>[norm],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return WhmsDevice.fromMap(maps.first);
  }

  /// {@template whms_device_store_insert}
  /// Yeni cihaz; MAC unique (silinmemişler arasında).
  ///
  /// Fırlatılan hatalar:
  /// - [ArgumentError]: name boş
  /// - [StateError]: `whms.terminal.mac_duplicate`
  /// {@endtemplate}
  Future<WhmsDevice> insert({
    required String name,
    String? mac,
    String? model,
    String? osName,
    List<String> roles = const [],
    String? defaultWarehouseCode,
    bool isActive = true,
  }) async {
    final n = name.trim();
    if (n.isEmpty) throw ArgumentError('name required');
    final normMac = normalizeMac(mac);
    await ensureReady();
    if (normMac != null) {
      final existing = await findByMac(normMac);
      if (existing != null) {
        throw StateError('whms.terminal.mac_duplicate');
      }
    }
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    final row = WhmsDevice(
      id: const Uuid().v4(),
      name: n,
      mac: normMac,
      model: _emptyToNull(model),
      osName: _emptyToNull(osName),
      roles: roles,
      defaultWarehouseCode: _emptyToNull(defaultWarehouseCode),
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert(tableName, row.toMap());
    return row;
  }

  /// {@template whms_device_store_upsert}
  /// id boşsa insert; doluysa update. MAC unique kontrolü.
  ///
  /// Fırlatılan hatalar:
  /// - [ArgumentError]: name boş
  /// - [StateError]: `whms.terminal.mac_duplicate`
  /// {@endtemplate}
  Future<WhmsDevice> upsert(WhmsDevice device) async {
    final n = device.name.trim();
    if (n.isEmpty) throw ArgumentError('name required');
    final normMac = normalizeMac(device.mac);
    await ensureReady();
    if (normMac != null) {
      final clash = await findByMac(normMac);
      if (clash != null && clash.id != device.id) {
        throw StateError('whms.terminal.mac_duplicate');
      }
    }
    final now = DateTime.now().toIso8601String();
    final id = device.id.trim().isEmpty
        ? const Uuid().v4()
        : device.id.trim();
    final row = WhmsDevice(
      id: id,
      name: n,
      mac: normMac,
      model: _emptyToNull(device.model),
      osName: _emptyToNull(device.osName),
      roles: device.roles,
      defaultWarehouseCode: _emptyToNull(device.defaultWarehouseCode),
      isActive: device.isActive,
      createdAt: device.createdAt?.trim().isNotEmpty == true
          ? device.createdAt
          : now,
      updatedAt: now,
    );
    final db = await _db();
    await db.insert(
      tableName,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return row;
  }

  /// {@template whms_device_store_update}
  /// Mevcut cihazı günceller ([upsert] delegasyonu).
  /// {@endtemplate}
  Future<void> update(WhmsDevice device) async {
    await upsert(device);
  }

  /// {@template whms_device_store_set_active}
  /// Aktif / pasif bayrağı.
  /// {@endtemplate}
  Future<void> setActive(String id, bool active) async {
    final key = id.trim();
    if (key.isEmpty) return;
    await ensureReady();
    final db = await _db();
    await db.update(
      tableName,
      <String, Object?>{
        'is_active': active ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND COALESCE(is_deleted, 0) = 0',
      whereArgs: <Object>[key],
    );
  }

  /// {@template whms_device_store_soft_delete}
  /// Soft delete + pasif.
  /// {@endtemplate}
  Future<void> softDelete(String id) async {
    final key = id.trim();
    if (key.isEmpty) return;
    await ensureReady();
    final db = await _db();
    await db.update(
      tableName,
      <String, Object?>{
        'is_deleted': 1,
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object>[key],
    );
  }

  String? _emptyToNull(String? v) {
    final t = v?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  Future<void> _ensureColumns(Database db) async {
    final cols = await _columnNames(db);
    if (cols.isEmpty) return;
    await _addColIfMissing(db, cols, 'roles', 'TEXT');
    await _addColIfMissing(db, cols, 'default_warehouse_code', 'TEXT');
  }

  Future<Set<String>> _columnNames(Database db) async {
    try {
      final rows = await db.rawQuery('PRAGMA table_info($tableName)');
      return rows
          .map((r) => r['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _addColIfMissing(
    Database db,
    Set<String> cols,
    String name,
    String typeSql,
  ) async {
    if (cols.contains(name)) return;
    try {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $name $typeSql',
      );
      cols.add(name);
    } catch (_) {
      // Kolon yarış / mevcut
    }
  }
}
