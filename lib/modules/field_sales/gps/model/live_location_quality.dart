// Dosya Adı: live_location_quality.dart
// Açıklama: Canlı konum tazelik / doğruluk eşikleri ve filtre
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template live_location_accuracy_band}
/// UI doğruluk bandı (iyi / orta / zayıf).
/// {@endtemplate}
enum LiveLocationAccuracyBand {
  /// ≤ [LiveLocationQuality.accuracyGoodMaxMeters]
  good,

  /// ≤ [LiveLocationQuality.maxSyncAccuracyMeters]
  fair,

  /// Eşik üstü veya bilinmiyor
  poor,

  /// accuracy null / ≤ 0
  unknown,
}

/// {@template live_location_quality}
/// Canlı konum yayın ve UI için doğruluk / tazelik sabitleri.
/// PostgREST Realtime yok → yönetici HTTP poll (backoff).
/// Bkz. `docs/plans/2026-07-28-live-location-transport.md`.
///
/// Kullanım örneği:
/// ```dart
/// if (LiveLocationQuality.acceptsFix(
///   accuracyMeters: 12,
///   fixAge: Duration.zero,
/// )) { ... }
/// ```
/// {@endtemplate}
class LiveLocationQuality {
  LiveLocationQuality._();

  /// Yayın stream mesafe filtresi (metre).
  static const int distanceFilterMeters = 15;

  /// Android konum stream aralığı.
  static const Duration streamInterval = Duration(seconds: 3);

  /// Sabitken bile heartbeat senkron aralığı.
  static const Duration heartbeatInterval = Duration(seconds: 5);

  /// Yönetici liste poll aralığı (PostgREST Realtime yok).
  static const Duration managerPollInterval = Duration(seconds: 3);

  /// Değişmeyen snapshot’ta poll backoff adımları.
  static const List<Duration> managerPollBackoffSteps = [
    Duration(seconds: 3),
    Duration(seconds: 5),
    Duration(seconds: 8),
    Duration(seconds: 12),
    Duration(seconds: 15),
  ];

  /// UI “iyi” doğruluk tavanı (metre).
  static const double accuracyGoodMaxMeters = 20;

  /// Senkron için maksimum yatay doğruluk (metre).
  static const double maxSyncAccuracyMeters = 50;

  /// Proximity / geofence için daha gevşek doğruluk tavanı.
  static const double maxProximityAccuracyMeters = 100;

  /// Fix zaman damgası bu yaştan eskiyse reddet.
  static const Duration maxFixAge = Duration(seconds: 30);

  /// UI "Canlı" rozeti için varsayılan tazelik penceresi.
  static const Duration realtimeFreshMaxAge = Duration(seconds: 90);

  /// Liste / sunucu penceresi (eski snapshot hâlâ gösterilebilir).
  static const Duration listFreshMaxAge = Duration(minutes: 30);

  /// {@template live_location_quality_poll_interval}
  /// Backoff adımına göre poll aralığı.
  /// {@endtemplate}
  static Duration pollIntervalForStep(int step) {
    final i = step.clamp(0, managerPollBackoffSteps.length - 1);
    return managerPollBackoffSteps[i];
  }

  /// {@template live_location_quality_accuracy_band}
  /// Metre doğruluğunu UI bandına çevirir.
  /// {@endtemplate}
  static LiveLocationAccuracyBand accuracyBand(double? accuracyMeters) {
    if (accuracyMeters == null || accuracyMeters <= 0) {
      return LiveLocationAccuracyBand.unknown;
    }
    if (accuracyMeters <= accuracyGoodMaxMeters) {
      return LiveLocationAccuracyBand.good;
    }
    if (accuracyMeters <= maxSyncAccuracyMeters) {
      return LiveLocationAccuracyBand.fair;
    }
    return LiveLocationAccuracyBand.poor;
  }

  /// Band → l10n anahtarı.
  static String accuracyBandKey(LiveLocationAccuracyBand band) {
    switch (band) {
      case LiveLocationAccuracyBand.good:
        return 'field_sales.gps_accuracy_band_good';
      case LiveLocationAccuracyBand.fair:
        return 'field_sales.gps_accuracy_band_fair';
      case LiveLocationAccuracyBand.poor:
        return 'field_sales.gps_accuracy_band_poor';
      case LiveLocationAccuracyBand.unknown:
        return 'field_sales.gps_accuracy_unknown';
    }
  }

  /// {@template live_location_quality_accepts_fix}
  /// Düşük doğruluk veya bayat fix’i senkron / canlı yayın için reddeder.
  ///
  /// Parametreler:
  /// - [accuracyMeters]: Yatay doğruluk (m); null → kabul (eski kayıt)
  /// - [fixAge]: Fix’in yaşı; null → yaş kontrolü yok
  /// - [maxAccuracyMeters]: Doğruluk tavanı
  /// - [maxAge]: Bayatlık tavanı
  ///
  /// Dönüş değeri:
  /// - [bool]: Fix kabul edilsin mi
  /// {@endtemplate}
  static bool acceptsFix({
    double? accuracyMeters,
    Duration? fixAge,
    double maxAccuracyMeters = maxSyncAccuracyMeters,
    Duration maxAge = maxFixAge,
  }) {
    if (accuracyMeters != null &&
        accuracyMeters > 0 &&
        accuracyMeters > maxAccuracyMeters) {
      return false;
    }
    if (fixAge != null && fixAge > maxAge) {
      return false;
    }
    return true;
  }

  /// {@template live_location_quality_age}
  /// [updatedAt] ile [now] arasındaki yaş.
  /// {@endtemplate}
  static Duration ageOf(DateTime updatedAt, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final d = n.difference(updatedAt);
    return d.isNegative ? Duration.zero : d;
  }

  /// {@template live_location_quality_age_bucket}
  /// UI / l10n için yaş kovası: `seconds` | `minutes` | `hours`.
  /// {@endtemplate}
  static ({String unit, int value}) ageBucket(Duration age) {
    if (age.inSeconds < 60) {
      return (unit: 'seconds', value: age.inSeconds);
    }
    if (age.inMinutes < 60) {
      return (unit: 'minutes', value: age.inMinutes);
    }
    return (unit: 'hours', value: age.inHours);
  }
}
