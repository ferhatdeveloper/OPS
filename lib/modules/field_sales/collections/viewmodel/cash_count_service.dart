// Dosya Adı: cash_count_service.dart
// Açıklama: Kasa sayımı yerel SQLite kayıt + sync_queue enqueue
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../model/cash_count_record.dart';

/// {@template cash_count_service}
/// Kasa sayımı dens Kaydet: önce yerel `cash_counts`, sonra `sync_queue`.
///
/// Kullanım örneği:
/// ```dart
/// await CashCountService.saveLocalAndQueue(db: db, record: record);
/// ```
/// {@endtemplate}
class CashCountService {
  /// [entityType]: JobQueue / sync_queue entity_type
  static const String entityType = CashCountRecord.entityType;

  /// {@template cash_count_service_save_local_and_queue}
  /// Yerel kaydı yazar ve sync kuyruğuna ekler (aynı transaction).
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite veritabanı
  /// - [record]: Kaydedilecek kasa sayımı
  ///
  /// Dönüş değeri:
  /// - [String]: Kayıt id
  /// {@endtemplate}
  static Future<String> saveLocalAndQueue({
    required Database db,
    required CashCountRecord record,
  }) async {
    await db.execute(SqlQuerys.createCashCountsTable);
    await db.execute(SqlQuerys.createSyncQueueTable);

    final jobId = const Uuid().v4();
    await db.transaction((txn) async {
      await txn.insert('cash_counts', record.toMap());
      await txn.insert('sync_queue', {
        'id': jobId,
        'entity_type': CashCountService.entityType,
        'entity_id': record.id,
        'payload': jsonEncode(record.toQueuePayload()),
        'priority': 0,
        'retry_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
    });

    return record.id;
  }
}
