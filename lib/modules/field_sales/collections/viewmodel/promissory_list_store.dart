// Dosya Adı: promissory_list_store.dart
// Açıklama: promissory_portfolio SQLite dens CRUD
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/promissory_list_row.dart';
import '../model/promissory_list_seed.dart';
import '../model/promissory_list_status.dart';
import 'collections_logo_sync_mapper.dart';

/// {@template promissory_list_store}
/// Senet portföyü offline SQLite — seed + dens CRUD.
/// {@endtemplate}
class PromissoryListStore {
  /// [openDb]: Test DB
  final Future<Database> Function()? openDb;

  /// {@macro promissory_list_store}
  const PromissoryListStore({this.openDb});

  static const String tableName = 'promissory_portfolio';

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createPromissoryPortfolioTable);
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
    final now = DateTime.now().toIso8601String();
    for (final row in PromissoryListSeed.defaultRows) {
      batch.insert(
        tableName,
        {
          ..._rowToMap(row),
          'is_synced': 0,
          'is_deleted': 0,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Map<String, dynamic> _rowToMap(PromissoryListRow row) {
    return {
      'id': row.id,
      'customer_id': row.customerId,
      'customer_name': row.customerName,
      'amount': row.amount,
      'note_number': row.noteNumber,
      'bank_name': row.bankName,
      'due_date': row.dueDate?.toIso8601String(),
      'document_no': row.documentNo,
      'note_status': row.status.code,
    };
  }

  Future<List<PromissoryListRow>> listActive() async {
    final db = await _db();
    await ensureReady();
    final maps = await db.query(
      tableName,
      where: 'COALESCE(is_deleted, 0) = 0',
      orderBy: 'due_date ASC',
    );
    return maps.map(_fromMap).toList(growable: false);
  }

  PromissoryListRow _fromMap(Map<String, Object?> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return PromissoryListRow(
      id: (map['id'] ?? '').toString(),
      customerId: (map['customer_id'] ?? '').toString(),
      customerName: map['customer_name']?.toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      noteNumber: (map['note_number'] ?? '').toString(),
      bankName: map['bank_name']?.toString(),
      dueDate: parseDate(map['due_date']),
      documentNo: map['document_no']?.toString(),
      status: PromissoryListStatus.fromCode(map['note_status']?.toString()),
    );
  }

  Future<PromissoryListRow> create({
    required String customerId,
    String? customerName,
    required double amount,
    required String noteNumber,
    String? bankName,
    String? documentNo,
    DateTime? dueDate,
    PromissoryListStatus status = PromissoryListStatus.collection,
  }) async {
    await ensureReady();
    final db = await _db();
    final now = DateTime.now();
    final row = PromissoryListRow(
      id: const Uuid().v4(),
      customerId: customerId.trim(),
      customerName: customerName,
      amount: amount,
      noteNumber: noteNumber.trim(),
      bankName: bankName,
      dueDate: dueDate,
      documentNo: documentNo,
      status: status,
    );
    await db.insert(tableName, {
      ..._rowToMap(row),
      'is_synced': 0,
      'is_deleted': 0,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    await CollectionsLogoSyncMapper.enqueuePromissory(
      db: db,
      row: row,
      operation: 'upsert',
    );
    return row;
  }

  Future<void> update(PromissoryListRow row) async {
    await ensureReady();
    final db = await _db();
    await db.update(
      tableName,
      {
        ..._rowToMap(row),
        'is_synced': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [row.id],
    );
    await CollectionsLogoSyncMapper.enqueuePromissory(
      db: db,
      row: row,
      operation: 'upsert',
    );
  }

  Future<void> softDelete(String id) async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    await db.update(
      tableName,
      {
        'is_deleted': 1,
        'is_synced': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final row = _fromMap(maps.first);
      await CollectionsLogoSyncMapper.enqueuePromissory(
        db: db,
        row: row,
        operation: 'delete',
      );
    }
  }
}