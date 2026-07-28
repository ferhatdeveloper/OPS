// Dosya Adı: collections_logo_sync_mapper.dart
// Açıklama: Banka / çek / senet dens → Logo sync_queue payload stub + enqueue
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../core/services/logo_payload_mapper.dart';
import '../model/check_list_row.dart';
import '../model/promissory_list_row.dart';
import 'bank_card_store.dart';

/// {@template collections_logo_sync_mapper}
/// Banka kartı / çek / senet için Logo sync_queue iskeleti.
/// Yerel CRUD sonrası enqueue; merkez Objects aktarım sonraki faz.
///
/// Kullanım örneği:
/// ```dart
/// await CollectionsLogoSyncMapper.enqueueBankCard(
///   db: db,
///   record: record,
///   operation: 'upsert',
/// );
/// ```
/// {@endtemplate}
class CollectionsLogoSyncMapper {
  /// {@macro collections_logo_sync_mapper}
  const CollectionsLogoSyncMapper._();

  /// Banka kartı entity_type
  static const String bankCardEntityType = 'bank_card';

  /// Çek portföy entity_type
  static const String checkEntityType = 'check';

  /// Senet portföy entity_type
  static const String promissoryEntityType = 'promissory';

  /// {@template collections_logo_sync_mapper_bank_card_payload}
  /// Banka kartı → Logo banka/kasa stub payload.
  /// {@endtemplate}
  static Map<String, dynamic> bankCardPayload({
    required BankCardRecord record,
    required String operation,
  }) {
    return {
      'entity': bankCardEntityType,
      'type': bankCardEntityType,
      'operation': operation,
      'id': record.id,
      'code': record.code,
      'CODE': record.code,
      'name': record.name,
      'TITLE': record.name,
      'name_key': record.nameKey,
      'balance_tl': record.balanceTl,
      'balance_usd': record.balanceUsd,
      'balance_iqd': record.balanceIqd,
      'is_active': record.isActive,
      'is_deleted': record.isDeleted,
      // Logo CL/BANK stub — gerçek Objects alanı sonraki faz
      'stub': true,
    };
  }

  /// {@template collections_logo_sync_mapper_check_payload}
  /// Çek satırı → Logo CSCARD (DOC=1) stub.
  /// {@endtemplate}
  static Map<String, dynamic> checkPayload({
    required CheckListRow row,
    required String operation,
  }) {
    final base = LogoPayloadMapper.collectionFromLocal(
      customerCode: row.customerId,
      amount: row.amount,
      paymentType: 'check',
      customerName: row.customerName,
      documentNo: row.documentNo,
      bankName: row.bankName,
      branchName: row.branchName,
      checkNumber: row.checkNumber,
      dueDate: row.dueDate,
    );
    return {
      ...base,
      'entity': checkEntityType,
      'type': checkEntityType,
      'operation': operation,
      'id': row.id,
      'check_status': row.status.code,
      'stub': true,
    };
  }

  /// {@template collections_logo_sync_mapper_promissory_payload}
  /// Senet satırı → Logo CSCARD (DOC=2) stub.
  /// {@endtemplate}
  static Map<String, dynamic> promissoryPayload({
    required PromissoryListRow row,
    required String operation,
  }) {
    final base = LogoPayloadMapper.collectionFromLocal(
      customerCode: row.customerId,
      amount: row.amount,
      paymentType: 'note',
      customerName: row.customerName,
      documentNo: row.documentNo,
      bankName: row.bankName,
      checkNumber: row.noteNumber,
      dueDate: row.dueDate,
    );
    return {
      ...base,
      'entity': promissoryEntityType,
      'type': promissoryEntityType,
      'operation': operation,
      'id': row.id,
      'note_status': row.status.code,
      'stub': true,
    };
  }

  /// {@template collections_logo_sync_mapper_enqueue}
  /// sync_queue satırı yazar (aynı txn veya ayrı).
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite (veya Transaction)
  /// - [entityType]: entity_type
  /// - [entityId]: entity_id
  /// - [payload]: JSON map
  ///
  /// Dönüş değeri:
  /// - [String]: Job id
  /// {@endtemplate}
  static Future<String> enqueue({
    required DatabaseExecutor db,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    if (db is Database) {
      await db.execute(SqlQuerys.createSyncQueueTable);
    }
    final jobId = const Uuid().v4();
    await db.insert('sync_queue', {
      'id': jobId,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': jsonEncode(payload),
      'priority': 0,
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    return jobId;
  }

  /// Banka kartı upsert/delete enqueue.
  static Future<String> enqueueBankCard({
    required DatabaseExecutor db,
    required BankCardRecord record,
    required String operation,
  }) {
    return enqueue(
      db: db,
      entityType: bankCardEntityType,
      entityId: record.id,
      payload: bankCardPayload(record: record, operation: operation),
    );
  }

  /// Çek upsert/delete enqueue.
  static Future<String> enqueueCheck({
    required DatabaseExecutor db,
    required CheckListRow row,
    required String operation,
  }) {
    return enqueue(
      db: db,
      entityType: checkEntityType,
      entityId: row.id,
      payload: checkPayload(row: row, operation: operation),
    );
  }

  /// Senet upsert/delete enqueue.
  static Future<String> enqueuePromissory({
    required DatabaseExecutor db,
    required PromissoryListRow row,
    required String operation,
  }) {
    return enqueue(
      db: db,
      entityType: promissoryEntityType,
      entityId: row.id,
      payload: promissoryPayload(row: row, operation: operation),
    );
  }
}
