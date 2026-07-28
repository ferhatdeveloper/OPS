// Dosya Adı: live_location_session.dart
// Açıklama: Mesai açıkken personel canlı GPS oturumu başlat/durdur
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import '../../../../core/services/gps_service.dart';
import '../../other/viewmodel/day_status_store.dart';

/// {@template live_location_session}
/// Gün açıkken GpsService konum akışını bağlar; gün kapanınca keser.
/// Yayın: SQLite + PostgREST `live_location_snapshots` upsert ([GpsService]).
/// Yönetici liste: [PersonnelLiveLocationStore.createWatchClient] (Realtime/WS
/// veya HTTP poll yedek).
///
/// Kullanım örneği:
/// ```dart
/// await LiveLocationSession.start(
///   userId: 'u1',
///   salespersonCode: 'PLS01',
/// );
/// ```
/// {@endtemplate}
class LiveLocationSession {
  /// [dayStatusStore]: Mesai kapısı
  final DayStatusStore dayStatusStore;

  /// [gps]: Konum servisi
  final GpsService gps;

  /// {@macro live_location_session}
  LiveLocationSession({
    this.dayStatusStore = const DayStatusStore(),
    GpsService? gps,
  }) : gps = gps ?? GpsService();

  /// Mesai açıksa takibi başlatır.
  Future<bool> start({
    required String userId,
    String salespersonCode = '',
  }) async {
    final open = await dayStatusStore.isDayOpen();
    if (!open) return false;
    await gps.startTracking(
      userId: userId,
      salespersonCode: salespersonCode,
    );
    return true;
  }

  /// Mesai açıksa ve daha önce başlamadıysa yeniden dener.
  Future<void> resumeIfDayOpen({
    required String userId,
    String salespersonCode = '',
  }) async {
    await start(userId: userId, salespersonCode: salespersonCode);
  }

  /// Takibi durdurur (gün sonu).
  void stop() {
    gps.stopTracking();
  }
}
