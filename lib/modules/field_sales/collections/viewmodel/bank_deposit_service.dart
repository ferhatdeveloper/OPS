// Dosya Adı: bank_deposit_service.dart
// Açıklama: Banka yatırma yerel SQLite kayıt + sync_queue enqueue
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../model/bank_deposit_record.dart';

/// {@template bank_deposit_service}
/// Banka yatırma dens Kaydet: önce yerel `bank_deposits`, sonra `sync_queue`.
///
/// Kullanım örneği:
/// ```dart
/// await BankDepositService.saveLocalAndQueue(db: db, record: record);
/// ```
/// {@endtemplate}
class BankDepositService {
  /// [entityType]: JobQueue / sync_queue entity_type
  static const String entityType = BankDepositRecord.entityType;

  /// {@template bank_deposit_service_save_local_and_queue}
  /// Yerel kaydı yazar ve sync kuyruğuna ekler (aynı transaction).
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite veritabanı
  /// - [record]: Kaydedilecek banka yatırma
  ///
  /// Dönüş değeri:
  /// - [String]: Kayıt id
  /// {@endtemplate}
  static Future<String> saveLocalAndQueue({
    required Database db,
    required BankDepositRecord record,
  }) async {
    await db.execute(SqlQuerys.createBankDepositsTable);
    await db.execute(SqlQuerys.createSyncQueueTable);

    final jobId = const Uuid().v4();
    await db.transaction((txn) async {
      await txn.insert('bank_deposits', record.toMap());
      await txn.insert('sync_queue', {
        'id': jobId,
        'entity_type': BankDepositService.entityType,
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
