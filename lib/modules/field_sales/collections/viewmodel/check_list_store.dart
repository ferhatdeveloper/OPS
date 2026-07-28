// Dosya Adı: check_list_store.dart
// Açıklama: check_portfolio SQLite dens CRUD (create·update·soft delete)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/check_list_row.dart';
import '../model/check_list_seed.dart';
import '../model/check_list_status.dart';
import '../model/finance_movement_type.dart';
import 'collections_logo_sync_mapper.dart';

/// {@template check_list_store}
/// Çek portföyü offline SQLite — seed + dens CRUD.
/// {@endtemplate}
class CheckListStore {
  /// [openDb]: Test DB
  final Future<Database> Function()? openDb;

  /// {@macro check_list_store}
  const CheckListStore({this.openDb});

  static const String tableName = 'check_portfolio';

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createCheckPortfolioTable);
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
    for (final row in CheckListSeed.defaultRows) {
      batch.insert(
        tableName,
        {
          'id': row.id,
          'customer_id': row.customerId,
          'customer_name': row.customerName,
          'amount': row.amount,
          'check_number': row.checkNumber,
          'bank_name': row.bankName,
          'branch_name': row.branchName,
          'due_date': row.dueDate?.toIso8601String(),
          'document_no': row.documentNo,
          'check_status': row.status.code,
          'collection_date': row.collectionDate.toIso8601String(),
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

  Future<List<CheckListRow>> listActive() async {
    final db = await _db();
    await ensureReady();
    final maps = await db.query(
      tableName,
      where: 'COALESCE(is_deleted, 0) = 0',
      orderBy: 'due_date ASC',
    );
    return maps.map(_fromPortfolioMap).toList(growable: false);
  }

  CheckListRow _fromPortfolioMap(Map<String, Object?> map) {
    return CheckListRow.fromMap({
      ...map,
      'payment_type': FinanceMovementType.checkCollection.apiCode,
    })!;
  }

  Future<CheckListRow> create({
    required String customerId,
    String? customerName,
    required double amount,
    required String checkNumber,
    String? bankName,
    String? documentNo,
    DateTime? dueDate,
    CheckListStatus status = CheckListStatus.collection,
  }) async {
    await ensureReady();
    final db = await _db();
    final now = DateTime.now();
    final row = CheckListRow(
      id: const Uuid().v4(),
      customerId: customerId.trim(),
      customerName: customerName,
      amount: amount,
      paymentType: FinanceMovementType.checkCollection.apiCode,
      collectionDate: now,
      checkNumber: checkNumber.trim(),
      bankName: bankName,
      dueDate: dueDate,
      documentNo: documentNo,
      status: status,
    );
    await db.insert(tableName, {
      'id': row.id,
      'customer_id': row.customerId,
      'customer_name': row.customerName,
      'amount': row.amount,
      'check_number': row.checkNumber,
      'bank_name': row.bankName,
      'branch_name': row.branchName,
      'due_date': row.dueDate?.toIso8601String(),
      'document_no': row.documentNo,
      'check_status': row.status.code,
      'collection_date': row.collectionDate.toIso8601String(),
      'is_synced': 0,
      'is_deleted': 0,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    await CollectionsLogoSyncMapper.enqueueCheck(
      db: db,
      row: row,
      operation: 'upsert',
    );
    return row;
  }

  Future<void> update(CheckListRow row) async {
    await ensureReady();
    final db = await _db();
    await db.update(
      tableName,
      {
        'customer_id': row.customerId,
        'customer_name': row.customerName,
        'amount': row.amount,
        'check_number': row.checkNumber,
        'bank_name': row.bankName,
        'branch_name': row.branchName,
        'due_date': row.dueDate?.toIso8601String(),
        'document_no': row.documentNo,
        'check_status': row.status.code,
        'collection_date': row.collectionDate.toIso8601String(),
        'is_synced': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [row.id],
    );
    await CollectionsLogoSyncMapper.enqueueCheck(
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
      final row = _fromPortfolioMap(maps.first);
      await CollectionsLogoSyncMapper.enqueueCheck(
        db: db,
        row: row,
        operation: 'delete',
      );
    }
  }
}