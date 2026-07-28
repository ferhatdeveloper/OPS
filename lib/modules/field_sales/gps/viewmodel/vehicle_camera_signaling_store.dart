// Dosya Adı: vehicle_camera_signaling_store.dart
// Açıklama: WebRTC sinyal mesajları PostgREST poll + lokal SQLite
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../core/tenant/postgrest_http_client.dart';
import '../../../../service/database_service.dart';
import '../model/vehicle_camera_signaling_message.dart';

/// {@template vehicle_camera_signaling_store}
/// SDP/ICE mesajlarını offline-first yazar; online ise PostgREST
/// `vehicle_camera_signaling` tablosuna dener (yoksa lokal kalır).
/// Realtime yoksa HTTP poll ile `pollSince` kullanılır.
///
/// Kullanım örneği:
/// ```dart
/// await store.publish(msg);
/// final inbox = await store.pollSince(sessionId: sid, since: t);
/// ```
/// {@endtemplate}
class VehicleCameraSignalingStore {
  /// [openDb]: Test DB enjeksiyonu
  final Future<Database> Function()? openDb;

  /// [postgrest]: Opsiyonel remote istemci
  final PostgrestHttpClient? postgrest;

  /// [tableName]: Yerel tablo
  static const String tableName = 'vehicle_camera_signaling';

  /// {@macro vehicle_camera_signaling_store}
  const VehicleCameraSignalingStore({
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
    await db.execute(SqlQuerys.createVehicleCameraSignalingTable);
  }

  /// Sinyal mesajı yayınlar.
  Future<void> publish(VehicleCameraSignalingMessage message) async {
    await ensureReady();
    final db = await _db();
    await db.insert(
      tableName,
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _tryRemoteInsert(message);
  }

  /// Son [within] içinde görülen oturum anahtarları (WebRTC keşif).
  Future<List<String>> loadRecentSessionIds({
    Duration within = const Duration(minutes: 5),
  }) async {
    await ensureReady();
    final since =
        DateTime.now().toUtc().subtract(within).toIso8601String();
    try {
      final client = postgrest ?? PostgrestHttpClient();
      if (client.isConfigured) {
        final rows = await client.getRows(
          '/vehicle_camera_signaling',
          query: {
            'created_at': 'gt.$since',
            'select': 'session_id',
            'order': 'created_at.desc',
            'limit': '100',
          },
        );
        final ids = <String>{};
        for (final r in rows) {
          final s = r['session_id']?.toString() ?? '';
          if (s.isNotEmpty) ids.add(s);
        }
        if (ids.isNotEmpty) return ids.toList(growable: false);
      }
    } catch (e) {
      debugPrint('VehicleCameraSignalingStore sessions remote: $e');
    }
    final db = await _db();
    final rows = await db.query(
      tableName,
      columns: ['session_id'],
      where: 'created_at > ? AND COALESCE(is_deleted, 0) = 0',
      whereArgs: [since],
      orderBy: 'created_at DESC',
      limit: 100,
    );
    final ids = <String>{};
    for (final r in rows) {
      final s = r['session_id']?.toString() ?? '';
      if (s.isNotEmpty) ids.add(s);
    }
    return ids.toList(growable: false);
  }

  /// Oturum için [since] sonrası mesajları getirir (yerel + remote birleşik).
  Future<List<VehicleCameraSignalingMessage>> pollSince({
    required String sessionId,
    required DateTime since,
    String? excludePeerId,
  }) async {
    await ensureReady();
    final remote = await _tryRemotePoll(sessionId: sessionId, since: since);
    for (final m in remote) {
      final db = await _db();
      await db.insert(
        tableName,
        {
          ...m.toMap(),
          'is_synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final db = await _db();
    final rows = await db.query(
      tableName,
      where: 'session_id = ? AND created_at > ? '
          'AND COALESCE(is_deleted, 0) = 0',
      whereArgs: [sessionId, since.toIso8601String()],
      orderBy: 'created_at ASC',
      limit: 200,
    );
    var list = rows.map(VehicleCameraSignalingMessage.fromMap).toList();
    final exclude = excludePeerId?.trim();
    if (exclude != null && exclude.isNotEmpty) {
      list = list.where((m) => m.fromPeerId != exclude).toList();
    }
    return list;
  }

  Future<void> _tryRemoteInsert(VehicleCameraSignalingMessage message) async {
    try {
      final client = postgrest ?? PostgrestHttpClient();
      if (!client.isConfigured) return;
      await client.postRow(
        '/vehicle_camera_signaling',
        message.toRemoteMap(),
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
        whereArgs: [message.id],
      );
    } catch (e) {
      debugPrint('VehicleCameraSignalingStore remote insert: $e');
    }
  }

  Future<List<VehicleCameraSignalingMessage>> _tryRemotePoll({
    required String sessionId,
    required DateTime since,
  }) async {
    try {
      final client = postgrest ?? PostgrestHttpClient();
      if (!client.isConfigured) return const [];
      final rows = await client.getRows(
        '/vehicle_camera_signaling',
        query: {
          'session_id': 'eq.$sessionId',
          'created_at': 'gt.${since.toIso8601String()}',
          'order': 'created_at.asc',
          'limit': '200',
        },
      );
      return rows.map(VehicleCameraSignalingMessage.fromMap).toList();
    } catch (e) {
      debugPrint('VehicleCameraSignalingStore remote poll: $e');
      return const [];
    }
  }
}
