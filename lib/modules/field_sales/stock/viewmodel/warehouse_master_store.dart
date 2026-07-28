// Dosya Adı: warehouse_master_store.dart
// Açıklama: Ambar master dens CRUD — SQLite + sync_queue stub
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../../../../service/job_queue_service.dart';
import '../model/warehouse_dens_row.dart';
import '../model/warehouse_master_seed.dart';

/// {@template warehouse_master_record}
/// SQLite `warehouses` satır modeli (CRUD).
///
/// Kullanım örneği:
/// ```dart
/// final r = WarehouseMasterRecord(
///   id: 'wh_x',
///   code: 'MRK',
///   name: 'Merkez',
///   type: WarehouseMasterSeed.typeCenter,
/// );
/// ```
/// {@endtemplate}
class WarehouseMasterRecord {
  /// [id]: Birincil anahtar
  final String id;

  /// [code]: Ambar kodu
  final String code;

  /// [name]: Görünen ad
  final String name;

  /// [type]: center / vehicle / return
  final String type;

  /// [isActive]: Aktif
  final bool isActive;

  /// [isSynced]: Sync
  final bool isSynced;

  /// [isDeleted]: Soft delete
  final bool isDeleted;

  /// [createdAt]: Oluşturma
  final String? createdAt;

  /// [updatedAt]: Güncelleme
  final String? updatedAt;

  /// {@macro warehouse_master_record}
  const WarehouseMasterRecord({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.isActive = true,
    this.isSynced = false,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  /// SQLite map → kayıt.
  factory WarehouseMasterRecord.fromMap(Map<String, dynamic> map) {
    return WarehouseMasterRecord(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? WarehouseMasterSeed.typeCenter,
      isActive: (map['is_active'] as num?)?.toInt() != 0,
      isSynced: (map['is_synced'] as num?)?.toInt() == 1,
      isDeleted: (map['is_deleted'] as num?)?.toInt() == 1,
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  /// Kayıt → SQLite map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'code': code,
      'name': name,
      'type': type,
      'is_active': isActive ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Dens liste satırı.
  WarehouseDensRow toDensRow() {
    return WarehouseDensRow(
      id: id,
      code: code,
      name: name,
      type: type,
      typeNameKey: WarehouseDensRow.typeNameKeyFor(type),
    );
  }
}

/// {@template warehouse_master_store}
/// `warehouses` create / update / soft-delete + sync_queue stub.
///
/// Kullanım örneği:
/// ```dart
/// final store = WarehouseMasterStore();
/// final rows = await store.listActive();
/// ```
/// {@endtemplate}
class WarehouseMasterStore {
  /// [openDb]: Test DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro warehouse_master_store}
  const WarehouseMasterStore({this.openDb});

  /// [tableName]: SQLite tablo
  static const String tableName = WarehouseMasterSeed.tableName;

  /// [entityType]: sync_queue entity_type
  static const String entityType = 'warehouse';

  /// {@template warehouse_master_store_db}
  /// Veritabanı bağlantısı.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template warehouse_master_store_ensure}
  /// Tablo + is_deleted kolonu; boşsa seed.
  /// {@endtemplate}
  Future<void> ensureReady({bool seed = true}) async {
    final db = await _db();
    await db.execute(SqlQuerys.createWarehousesTable);
    await db.execute(SqlQuerys.createSyncQueueTable);
    await _ensureIsDeletedColumn(db);
    if (!seed) return;
    await seedIfEmpty(db);
  }

  /// Mevcut DB’ye `is_deleted` ekler (yoksa).
  Future<void> _ensureIsDeletedColumn(Database db) async {
    try {
      final cols = await db.rawQuery('PRAGMA table_info($tableName)');
      if (cols.isEmpty) return;
      final has = cols.any((c) => c['name'] == 'is_deleted');
      if (has) return;
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN is_deleted '
        'INTEGER NOT NULL DEFAULT 0',
      );
    } catch (_) {}
  }

  /// {@template warehouse_master_store_seed}
  /// Tablo boşsa MRK/ARC/IAD yazar.
  /// {@endtemplate}
  Future<void> seedIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $tableName '
            'WHERE COALESCE(is_deleted, 0) = 0',
          ),
        ) ??
        0;
    if (count > 0) return;

    final batch = db.batch();
    for (final map in WarehouseMasterSeed.defaultMaps) {
      batch.insert(
        tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  /// {@template warehouse_master_store_list}
  /// Aktif (silinmemiş) ambarlar.
  /// {@endtemplate}
  Future<List<WarehouseMasterRecord>> listActive() async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: 'COALESCE(is_deleted, 0) = 0 AND COALESCE(is_active, 1) = 1',
      orderBy: 'code ASC',
    );
    return maps.map(WarehouseMasterRecord.fromMap).toList(growable: false);
  }

  /// {@template warehouse_master_store_create}
  /// Yeni ambar oluşturur + sync_queue upsert.
  ///
  /// Parametreler:
  /// - [code]: Ambar kodu
  /// - [name]: Ad
  /// - [type]: Tip (varsayılan center)
  ///
  /// Dönüş değeri:
  /// - [WarehouseMasterRecord]: Kayıt
  ///
  /// Fırlatılan hatalar:
  /// - [ArgumentError]: Kod/ad boş
  /// {@endtemplate}
  Future<WarehouseMasterRecord> create({
    required String code,
    required String name,
    String type = WarehouseMasterSeed.typeCenter,
  }) async {
    final trimmedCode = code.trim();
    final trimmedName = name.trim();
    if (trimmedCode.isEmpty || trimmedName.isEmpty) {
      throw ArgumentError('warehouse code/name required');
    }

    await ensureReady(seed: false);
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    final record = WarehouseMasterRecord(
      id: const Uuid().v4(),
      code: trimmedCode,
      name: trimmedName,
      type: type.trim().isEmpty ? WarehouseMasterSeed.typeCenter : type.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await _upsertWithQueue(db, record, op: 'upsert');
    return record;
  }

  /// {@template warehouse_master_store_update}
  /// Kod (değişmez) + ad/tip günceller + sync_queue.
  /// {@endtemplate}
  Future<WarehouseMasterRecord> update(WarehouseMasterRecord record) async {
    final name = record.name.trim();
    if (record.id.trim().isEmpty || name.isEmpty) {
      throw ArgumentError('warehouse id/name required');
    }
    await ensureReady(seed: false);
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    final saved = WarehouseMasterRecord(
      id: record.id,
      code: record.code.trim(),
      name: name,
      type: record.type.trim().isEmpty
          ? WarehouseMasterSeed.typeCenter
          : record.type.trim(),
      isActive: record.isActive,
      isSynced: false,
      isDeleted: false,
      createdAt: record.createdAt,
      updatedAt: now,
    );
    await _upsertWithQueue(db, saved, op: 'upsert');
    return saved;
  }

  /// {@template warehouse_master_store_soft_delete}
  /// Soft delete (`is_deleted=1`) + sync_queue delete stub.
  /// {@endtemplate}
  Future<bool> softDelete(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return false;

    await ensureReady(seed: false);
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    var updated = 0;

    await db.transaction((txn) async {
      updated = await txn.update(
        tableName,
        {
          'is_deleted': 1,
          'is_active': 0,
          'is_synced': 0,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [trimmed],
      );
      if (updated > 0) {
        await txn.insert('sync_queue', {
          'id': const Uuid().v4(),
          'entity_type': entityType,
          'entity_id': trimmed,
          'payload': jsonEncode({
            'id': trimmed,
            'op': 'delete',
            'updated_at': now,
          }),
          'priority': 0,
          'retry_count': 0,
          'created_at': now,
        });
      }
    });

    if (updated > 0 && openDb == null) {
      JobQueueService().processQueue();
    }
    return updated > 0;
  }

  /// Kod ile aktif kayıt.
  Future<WarehouseMasterRecord?> findByCode(String code) async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: 'code = ? AND COALESCE(is_deleted, 0) = 0',
      whereArgs: [code.trim()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return WarehouseMasterRecord.fromMap(maps.first);
  }

  Future<void> _upsertWithQueue(
    Database db,
    WarehouseMasterRecord record, {
    required String op,
  }) async {
    final map = record.toMap();
    final jobId = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.insert(
        tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert('sync_queue', {
        'id': jobId,
        'entity_type': entityType,
        'entity_id': record.id,
        'payload': jsonEncode({...map, 'op': op}),
        'priority': 0,
        'retry_count': 0,
        'created_at': now,
      });
    });

    if (openDb == null) {
      JobQueueService().processQueue();
    }
  }
}
