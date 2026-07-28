// Dosya Adı: personnel_live_location_store.dart
// Açıklama: Personel canlı konum — gps_logs + Postgres/PostgREST okuma
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/tenant/postgrest_http_client.dart';
import '../../../../service/postgres_service.dart';
import '../model/gps_last_location_record.dart';
import '../model/live_location_transport.dart';
import '../model/personnel_live_location.dart';
import 'gps_last_location_store.dart';
import 'live_location_realtime_client.dart';

/// {@template personnel_live_location_store}
/// Yönetici canlı konum listesi: önce uzak snapshot, yoksa SQLite
/// `gps_logs` son konumları.
///
/// Kullanım örneği:
/// ```dart
/// final rows = await PersonnelLiveLocationStore().loadLive();
/// ```
/// {@endtemplate}
class PersonnelLiveLocationStore {
  /// [local]: gps_logs store
  final GpsLastLocationStore local;

  /// [postgrest]: Opsiyonel REST
  final PostgrestHttpClient? postgrest;

  /// [postgres]: Direkt PG (fallback)
  final Future<PostgresService> Function()? postgresFactory;

  /// {@macro personnel_live_location_store}
  const PersonnelLiveLocationStore({
    this.local = const GpsLastLocationStore(),
    this.postgrest,
    this.postgresFactory,
  });

  /// Canlı konum akışı (Realtime/WS → HTTP poll yedek).
  ///
  /// Dinleyici dispose edilince istemciyi kapatın.
  LiveLocationRealtimeClient createWatchClient({int limit = 100}) {
    return LiveLocationRealtimeClient(store: this, limit: limit);
  }

  /// Olay akışı; dinlemeden önce [LiveLocationRealtimeClient.start] çağırın.
  Stream<LiveLocationWatchEvent> watchLive({int limit = 100}) {
    final client = createWatchClient(limit: limit);
    unawaited(client.start());
    return client.events;
  }

  /// Canlı / son konum satırlarını yükler.
  Future<List<PersonnelLiveLocation>> loadLive({int limit = 100}) async {
    final remote = await _tryRemote();
    if (remote.isNotEmpty) {
      return PersonnelLiveLocation.mergeLatestByUserId(remote)
          .take(limit)
          .toList(growable: false);
    }

    final localRows = await local.loadLastLocations(limit: limit);
    return localRows
        .map(_fromGpsLog)
        .toList(growable: false);
  }

  PersonnelLiveLocation _fromGpsLog(GpsLastLocationRecord r) {
    final code = r.salespersonCode.trim();
    return PersonnelLiveLocation(
      userId: code.isEmpty ? r.id : code,
      salespersonCode: code,
      displayName: r.label.trim().isEmpty ? code : r.label.trim(),
      latitude: r.latitude,
      longitude: r.longitude,
      updatedAt: r.recordedAt,
      accuracy: r.accuracy,
      isSynced: r.isSynced == 1,
    );
  }

  Future<List<PersonnelLiveLocation>> _tryRemote() async {
    try {
      final client = postgrest ?? PostgrestHttpClient();
      if (client.isConfigured) {
        final rows = await client.getRows(
          '/live_location_snapshots',
          query: {
            'order': 'last_update.desc',
            'limit': '100',
          },
        );
        return rows
            .map(PersonnelLiveLocation.fromMap)
            .toList(growable: false);
      }
    } catch (e) {
      debugPrint('PersonnelLiveLocationStore postgrest: $e');
    }

    try {
      final factory = postgresFactory ?? PostgresService.getInstance;
      final pg = await factory();
      final rows = await pg.getLiveLocations();
      return rows
          .map(PersonnelLiveLocation.fromMap)
          .toList(growable: false);
    } catch (e) {
      debugPrint('PersonnelLiveLocationStore postgres: $e');
      return const [];
    }
  }
}
