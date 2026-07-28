// Dosya Adı: bank_card_store.dart
// Açıklama: bank_cards SQLite seed / CRUD (create·update·soft delete)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/bank_card_master.dart';
import 'collections_logo_sync_mapper.dart';

/// {@template bank_card_record}
/// SQLite `bank_cards` satır modeli.
/// {@endtemplate}
class BankCardRecord {
  /// [id]: Birincil anahtar
  final String id;

  /// [code]: Banka hesap kodu
  final String code;

  /// [name]: Yerel ünvan
  final String name;

  /// [nameKey]: l10n anahtarı (boş olabilir)
  final String nameKey;

  /// [balanceTl]: TL bakiye
  final double balanceTl;

  /// [balanceUsd]: USD bakiye
  final double balanceUsd;

  /// [balanceIqd]: IQD bakiye
  final double balanceIqd;

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

  /// {@macro bank_card_record}
  const BankCardRecord({
    required this.id,
    required this.code,
    required this.name,
    required this.nameKey,
    this.balanceTl = 0,
    this.balanceUsd = 0,
    this.balanceIqd = 0,
    this.isActive = true,
    this.isSynced = false,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory BankCardRecord.fromMap(Map<String, dynamic> map) {
    return BankCardRecord(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      nameKey: map['name_key']?.toString() ?? '',
      balanceTl: (map['balance_tl'] as num?)?.toDouble() ?? 0,
      balanceUsd: (map['balance_usd'] as num?)?.toDouble() ?? 0,
      balanceIqd: (map['balance_iqd'] as num?)?.toDouble() ?? 0,
      isActive: (map['is_active'] as num?)?.toInt() != 0,
      isSynced: (map['is_synced'] as num?)?.toInt() == 1,
      isDeleted: (map['is_deleted'] as num?)?.toInt() == 1,
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'code': code,
      'name': name,
      'name_key': nameKey,
      'balance_tl': balanceTl,
      'balance_usd': balanceUsd,
      'balance_iqd': balanceIqd,
      'is_active': isActive ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Dens liste seçeneği.
  BankCardOption toOption() => BankCardOption(
        code: code,
        l10nKey: nameKey,
        displayName: nameKey.trim().isEmpty ? name : null,
        balanceTl: balanceTl,
        balanceUsd: balanceUsd,
        balanceIqd: balanceIqd,
      );
}

/// {@template bank_card_store}
/// `bank_cards` oluşturur, seed yazar, dens CRUD sağlar.
/// {@endtemplate}
class BankCardStore {
  /// [openDb]: Test DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro bank_card_store}
  const BankCardStore({this.openDb});

  static const String tableName = 'bank_cards';
  static const String seedCreatedAt = '2026-07-27T00:00:00.000';

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// Tabloyu hazırlar; boşsa master seed yazar.
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createBankCardsTable);
    await seedIfEmpty(db);
  }

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
    for (final o in BankCardMaster.options) {
      batch.insert(
        tableName,
        <String, dynamic>{
          'id': 'bc_${o.code.trim().replaceAll(' ', '_')}',
          'code': o.code,
          'name': o.code,
          'name_key': o.l10nKey,
          'balance_tl': o.balanceTl,
          'balance_usd': o.balanceUsd,
          'balance_iqd': o.balanceIqd,
          'is_active': 1,
          'is_synced': 0,
          'is_deleted': 0,
          'created_at': seedCreatedAt,
          'updated_at': seedCreatedAt,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Aktif (silinmemiş) banka kartları.
  Future<List<BankCardRecord>> listActive() async {
    final db = await _db();
    await db.execute(SqlQuerys.createBankCardsTable);
    final maps = await db.query(
      tableName,
      where: 'COALESCE(is_deleted, 0) = 0 AND COALESCE(is_active, 1) = 1',
      orderBy: 'code ASC',
    );
    return maps.map(BankCardRecord.fromMap).toList(growable: false);
  }

  /// Yeni kart oluşturur.
  Future<BankCardRecord> create({
    required String code,
    required String name,
    String nameKey = '',
  }) async {
    final db = await _db();
    await ensureReady();
    final now = DateTime.now().toIso8601String();
    final trimmed = code.trim();
    final record = BankCardRecord(
      id: const Uuid().v4(),
      code: trimmed,
      name: name.trim().isEmpty ? trimmed : name.trim(),
      nameKey: nameKey.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await db.insert(
      tableName,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await CollectionsLogoSyncMapper.enqueueBankCard(
      db: db,
      record: record,
      operation: 'upsert',
    );
    return record;
  }

  /// Kod + ünvan günceller.
  Future<void> update(BankCardRecord record) async {
    final db = await _db();
    await ensureReady();
    final now = DateTime.now().toIso8601String();
    final updated = BankCardRecord(
      id: record.id,
      code: record.code,
      name: record.name,
      nameKey: record.nameKey,
      balanceTl: record.balanceTl,
      balanceUsd: record.balanceUsd,
      balanceIqd: record.balanceIqd,
      isActive: record.isActive,
      isSynced: false,
      isDeleted: record.isDeleted,
      createdAt: record.createdAt,
      updatedAt: now,
    );
    await db.update(
      tableName,
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
    await CollectionsLogoSyncMapper.enqueueBankCard(
      db: db,
      record: updated,
      operation: 'upsert',
    );
  }

  /// Soft delete (`is_deleted=1`).
  Future<void> softDelete(String id) async {
    final db = await _db();
    await ensureReady();
    final now = DateTime.now().toIso8601String();
    final existing = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    await db.update(
      tableName,
      {
        'is_deleted': 1,
        'is_active': 0,
        'is_synced': 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (existing.isNotEmpty) {
      final record = BankCardRecord.fromMap({
        ...existing.first,
        'is_deleted': 1,
        'is_active': 0,
        'is_synced': 0,
        'updated_at': now,
      });
      await CollectionsLogoSyncMapper.enqueueBankCard(
        db: db,
        record: record,
        operation: 'delete',
      );
    }
  }

  /// Kod ile aktif kayıt.
  Future<BankCardRecord?> findByCode(String code) async {
    final db = await _db();
    await ensureReady();
    final maps = await db.query(
      tableName,
      where: 'code = ? AND COALESCE(is_deleted, 0) = 0',
      whereArgs: [code.trim()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BankCardRecord.fromMap(maps.first);
  }
}
