// Dosya Adı: stock_count_service.dart
// Açıklama: Sayım fişi yerel SQLite kayıt + sync_queue enqueue
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../model/stock_count_record.dart';

/// {@template stock_count_service}
/// Sayım dens Kaydet: önce yerel `stock_counts`, sonra `sync_queue`.
///
/// Kullanım örneği:
/// ```dart
/// await StockCountService.saveLocalAndQueue(db: db, record: record);
/// ```
/// {@endtemplate}
class StockCountService {
  /// [entityType]: JobQueue / sync_queue entity_type
  static const String entityType = 'stock_count';

  /// {@template stock_count_service_save_local_and_queue}
  /// Yerel kaydı yazar ve sync kuyruğuna ekler (aynı transaction).
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite veritabanı
  /// - [record]: Kaydedilecek sayım fişi
  ///
  /// Dönüş değeri:
  /// - [String]: Kayıt id
  /// {@endtemplate}
  static Future<String> saveLocalAndQueue({
    required Database db,
    required StockCountRecord record,
  }) async {
    await db.execute(SqlQuerys.createStockCountsTable);
    await db.execute(SqlQuerys.createSyncQueueTable);

    final jobId = const Uuid().v4();
    await db.transaction((txn) async {
      await txn.insert('stock_counts', record.toMap());
      await txn.insert('sync_queue', {
        'id': jobId,
        'entity_type': StockCountService.entityType,
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
