// Dosya Adı: vehicle_camera_frame_store.dart
// Açıklama: Araç kamera kareleri SQLite + opsiyonel PostgREST sync
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../core/tenant/postgrest_http_client.dart';
import '../../../../service/database_service.dart';
import '../model/vehicle_camera_frame.dart';
import '../model/vehicle_camera_lens.dart';

/// {@template vehicle_camera_frame_store}
/// Snapshot karelerini offline-first kaydeder; online ise PostgREST
/// `vehicle_camera_frames` tablosuna dener (yoksa sessizce lokal kalır).
///
/// Kullanım örneği:
/// ```dart
/// await store.insertFrame(frame);
/// final latest = await store.loadLatest();
/// ```
/// {@endtemplate}
class VehicleCameraFrameStore {
  /// [openDb]: Test DB enjeksiyonu
  final Future<Database> Function()? openDb;

  /// [postgrest]: Opsiyonel remote istemci
  final PostgrestHttpClient? postgrest;

  /// [tableName]: Yerel tablo
  static const String tableName = 'vehicle_camera_frames';

  /// {@macro vehicle_camera_frame_store}
  const VehicleCameraFrameStore({
    this.openDb,
    this.postgrest,
  });

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// Tabloyu oluşturur.
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createVehicleCameraFramesTable);
  }

  /// Yeni kare kaydeder (lokal) ve sync dener.
  Future<void> insertFrame(VehicleCameraFrame frame) async {
    await ensureReady();
    final db = await _db();
    await db.insert(
      tableName,
      frame.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _tryRemoteUpsert(frame);
  }

  /// Kullanıcı+lens başına son kareler.
  Future<List<VehicleCameraFrame>> loadLatest({int limit = 40}) async {
    await ensureReady();
    final db = await _db();
    final rows = await db.query(
      tableName,
      where: 'COALESCE(is_deleted, 0) = 0',
      orderBy: 'captured_at DESC',
      limit: limit * 3,
    );
    final all = rows.map(VehicleCameraFrame.fromMap).toList();
    final merged = VehicleCameraFrame.latestByUserAndLens(all);
    if (merged.length <= limit) return merged;
    return merged.take(limit).toList(growable: false);
  }

  /// Belirli kullanıcı + lens son kare.
  Future<VehicleCameraFrame?> loadLatestFor({
    required String userId,
    required VehicleCameraLens lens,
  }) async {
    await ensureReady();
    final db = await _db();
    final rows = await db.query(
      tableName,
      where: 'user_id = ? AND lens = ? AND COALESCE(is_deleted, 0) = 0',
      whereArgs: [userId, lens.storageKey],
      orderBy: 'captured_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return VehicleCameraFrame.fromMap(rows.first);
  }

  Future<void> _tryRemoteUpsert(VehicleCameraFrame frame) async {
    try {
      final client = postgrest ?? PostgrestHttpClient();
      if (!client.isConfigured) return;
      await client.postRow(
        '/vehicle_camera_frames',
        {
          'id': frame.id,
          'user_id': frame.userId,
          'salesperson_code': frame.salespersonCode,
          'lens': frame.lens.storageKey,
          'captured_at': frame.capturedAt.toIso8601String(),
          'image_base64': frame.imageBase64,
        },
        extraHeaders: {
          'Prefer': 'resolution=merge-duplicates,return=minimal',
        },
        returnRepresentation: false,
      );
      final db = await _db();
      await db.update(
        tableName,
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [frame.id],
      );
    } catch (e) {
      debugPrint('VehicleCameraFrameStore remote: $e');
    }
  }
}
