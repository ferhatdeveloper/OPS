// Dosya Adı: live_location_transport.dart
// Açıklama: Canlı konum taşıma modu ve snapshot parmak izi
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'personnel_live_location.dart';

/// {@template live_location_transport_mode}
/// Yönetici listesine veri nasıl akıyor.
/// {@endtemplate}
enum LiveLocationTransportMode {
  /// WebSocket / Realtime push
  realtime,

  /// HTTP poll (PostgREST / PG / SQLite)
  httpPoll,

  /// Yalnızca yerel gps_logs
  localOnly,
}

/// {@template live_location_watch_event}
/// [PersonnelLiveLocationStore.watchLive] olayı.
/// {@endtemplate}
class LiveLocationWatchEvent {
  /// [rows]: Güncel liste
  final List<PersonnelLiveLocation> rows;

  /// [mode]: Aktif taşıma
  final LiveLocationTransportMode mode;

  /// [realtimeConnected]: WS/Realtime bağlı mı
  final bool realtimeConnected;

  /// {@macro live_location_watch_event}
  const LiveLocationWatchEvent({
    required this.rows,
    required this.mode,
    this.realtimeConnected = false,
  });
}

/// {@template live_location_snapshot_fingerprint}
/// Poll backoff için snapshot özeti.
/// {@endtemplate}
class LiveLocationSnapshotFingerprint {
  /// {@macro live_location_snapshot_fingerprint}
  const LiveLocationSnapshotFingerprint(this.value);

  /// Birleşik parmak izi
  final String value;

  /// {@template live_location_snapshot_fingerprint_from_rows}
  /// Satırlardan parmak izi üretir.
  /// {@endtemplate}
  factory LiveLocationSnapshotFingerprint.fromRows(
    List<PersonnelLiveLocation> rows,
  ) {
    final parts = <String>[];
    for (final r in rows) {
      parts.add(
        '${r.userId}|${r.updatedAt.toUtc().millisecondsSinceEpoch}|'
        '${r.latitude.toStringAsFixed(5)}|${r.longitude.toStringAsFixed(5)}',
      );
    }
    parts.sort();
    return LiveLocationSnapshotFingerprint(parts.join(';'));
  }
}
