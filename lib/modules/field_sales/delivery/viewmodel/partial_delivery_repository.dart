// Dosya Adı: partial_delivery_repository.dart
// Açıklama: Kısmi teslimat SQLite insert + sync_queue iskelet katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../model/partial_delivery_model.dart';

/// {@template partial_delivery_repository}
/// partial_deliveries tablosu + sync_queue yazımı.
///
/// Kullanım örneği:
/// ```dart
/// final repo = PartialDeliveryRepository();
/// await repo.ensureSchema(db);
/// await repo.insert(db, record);
/// ```
/// {@endtemplate}
class PartialDeliveryRepository {
  /// [entityType]: Job kuyruğu entity tipi
  static const String entityType = 'partial_delivery';

  /// {@macro partial_delivery_repository}
  const PartialDeliveryRepository();

  /// {@template partial_delivery_repository_ensure_schema}
  /// Tablo yoksa oluşturur (iskelet bootstrap).
  ///
  /// Parametreler:
  /// - [db]: SQLite veritabanı
  /// {@endtemplate}
  Future<void> ensureSchema(Database db) async {
    await db.execute(SqlQuerys.createPartialDeliveriesTable);
    await db.execute(SqlQuerys.createSyncQueueTable);
  }

  /// {@template partial_delivery_repository_insert}
  /// Kaydı partial_deliveries tablosuna yazar.
  ///
  /// Parametreler:
  /// - [db]: SQLite
  /// - [record]: Kaydedilecek fiş
  /// {@endtemplate}
  Future<void> insert(Database db, PartialDeliveryRecord record) async {
    await db.insert(
      'partial_deliveries',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// {@template partial_delivery_repository_enqueue}
  /// sync_queue'ya partial_delivery işi ekler (Logo aktarım sonraki faz).
  ///
  /// Parametreler:
  /// - [db]: SQLite
  /// - [entityId]: Kayıt kimliği
  /// - [payload]: JSON payload
  /// {@endtemplate}
  Future<void> enqueueSyncQueue(
    Database db, {
    required String entityId,
    required Map<String, dynamic> payload,
    int priority = 0,
  }) async {
    await db.insert('sync_queue', {
      'id': const Uuid().v4(),
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': jsonEncode(payload),
      'priority': priority,
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
