// Dosya Adı: vehicle_camera_settings_record.dart
// Açıklama: Araç kamera canlı izleme opsiyonel parametreleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'vehicle_camera_ice_profile.dart';
import 'vehicle_camera_lens.dart';

/// {@template vehicle_camera_settings_record}
/// Araç ön/arka kamera yayını — varsayılan kapalı (gizlilik).
/// Kamera açılınca WebRTC otomatik tercih edilir (STUN varsayılan).
///
/// Kullanım örneği:
/// ```dart
/// const s = VehicleCameraSettingsRecord(enabled: true, webrtcEnabled: true);
/// ```
/// {@endtemplate}
class VehicleCameraSettingsRecord {
  /// [defaultIntervalSeconds]: Snapshot aralığı varsayılanı
  static const int defaultIntervalSeconds = 8;

  /// [minIntervalSeconds]: Minimum aralık
  static const int minIntervalSeconds = 3;

  /// [maxIntervalSeconds]: Maksimum aralık
  static const int maxIntervalSeconds = 60;

  /// [defaultAlternateSeconds]: Çift lens time-slice süresi
  static const int defaultAlternateSeconds = 6;

  /// [enabled]: Parametre açık mı (yayın + yönetici izleme)
  final bool enabled;

  /// [defaultLens]: Plasiyer varsayılan lens
  final VehicleCameraLens defaultLens;

  /// [intervalSeconds]: Snapshot polling aralığı
  final int intervalSeconds;

  /// [webrtcEnabled]: WebRTC canlı dene; başarısızsa JPEG fallback
  final bool webrtcEnabled;

  /// [audioEnabled]: WebRTC mikrofona izin ver (izleyici duyabilir)
  final bool audioEnabled;

  /// [broadcastBothLenses]: Yayıncı ön+arka (eşzamanlı veya sırayla)
  final bool broadcastBothLenses;

  /// [iceProfile]: Otomatik STUN veya özel TURN
  final VehicleCameraIceProfile iceProfile;

  /// [turnUrl]: Opsiyonel TURN sunucusu
  final String turnUrl;

  /// [turnUsername]: TURN kullanıcı adı
  final String turnUsername;

  /// [turnCredential]: TURN parola
  final String turnCredential;

  /// {@macro vehicle_camera_settings_record}
  const VehicleCameraSettingsRecord({
    this.enabled = false,
    this.defaultLens = VehicleCameraLens.front,
    this.intervalSeconds = defaultIntervalSeconds,
    this.webrtcEnabled = false,
    this.audioEnabled = false,
    this.broadcastBothLenses = true,
    this.iceProfile = VehicleCameraIceProfile.autoStun,
    this.turnUrl = '',
    this.turnUsername = '',
    this.turnCredential = '',
  });

  /// Kamera açıkken WebRTC tercihinin otomatik varsayılanı.
  static bool autoWebrtcWhenEnabled({
    required bool enabled,
    bool? webrtcExplicit,
  }) {
    if (webrtcExplicit != null) return webrtcExplicit;
    return enabled;
  }

  VehicleCameraSettingsRecord copyWith({
    bool? enabled,
    VehicleCameraLens? defaultLens,
    int? intervalSeconds,
    bool? webrtcEnabled,
    bool? audioEnabled,
    bool? broadcastBothLenses,
    VehicleCameraIceProfile? iceProfile,
    String? turnUrl,
    String? turnUsername,
    String? turnCredential,
  }) {
    return VehicleCameraSettingsRecord(
      enabled: enabled ?? this.enabled,
      defaultLens: defaultLens ?? this.defaultLens,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      webrtcEnabled: webrtcEnabled ?? this.webrtcEnabled,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      broadcastBothLenses: broadcastBothLenses ?? this.broadcastBothLenses,
      iceProfile: iceProfile ?? this.iceProfile,
      turnUrl: turnUrl ?? this.turnUrl,
      turnUsername: turnUsername ?? this.turnUsername,
      turnCredential: turnCredential ?? this.turnCredential,
    );
  }
}
