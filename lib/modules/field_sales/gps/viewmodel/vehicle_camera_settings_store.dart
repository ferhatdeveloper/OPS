// Dosya Adı: vehicle_camera_settings_store.dart
// Açıklama: Araç kamera ayarları SharedPreferences katmanı
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:shared_preferences/shared_preferences.dart';

import '../model/vehicle_camera_ice_profile.dart';
import '../model/vehicle_camera_lens.dart';
import '../model/vehicle_camera_settings_record.dart';

/// {@template vehicle_camera_settings_store}
/// Araç kamera canlı izleme parametrelerini okur / yazar.
/// Varsayılan: kapalı (yalnızca açıkken yayın/izleme).
/// Kamera açık + WebRTC hiç kaydedilmemişse WebRTC otomatik açık.
///
/// Kullanım örneği:
/// ```dart
/// final s = await const VehicleCameraSettingsStore().load();
/// ```
/// {@endtemplate}
class VehicleCameraSettingsStore {
  /// [prefsEnabled]: Canlı kamera açık mı
  static const String prefsEnabled = 'vehicle_camera_enabled';

  /// [prefsDefaultLens]: Varsayılan lens
  static const String prefsDefaultLens = 'vehicle_camera_default_lens';

  /// [prefsInterval]: Snapshot aralığı (sn)
  static const String prefsInterval = 'vehicle_camera_interval_s';

  /// [prefsWebrtc]: WebRTC canlı dene
  static const String prefsWebrtc = 'vehicle_camera_webrtc_enabled';

  /// [prefsAudio]: WebRTC ses (mikrofon)
  static const String prefsAudio = 'vehicle_camera_audio_enabled';

  /// [prefsBothLenses]: Yayıncı çift lens (eşzamanlı/sırayla)
  static const String prefsBothLenses = 'vehicle_camera_broadcast_both';

  /// [prefsTurnUrl]: Opsiyonel TURN URL
  static const String prefsTurnUrl = 'vehicle_camera_turn_url';

  /// [prefsTurnUsername]: TURN kullanıcı
  static const String prefsTurnUsername = 'vehicle_camera_turn_username';

  /// [prefsTurnCredential]: TURN parola
  static const String prefsTurnCredential = 'vehicle_camera_turn_credential';

  /// [prefsIceProfile]: ICE profili (auto_stun | custom_turn)
  static const String prefsIceProfile = 'vehicle_camera_ice_profile';

  /// {@macro vehicle_camera_settings_store}
  const VehicleCameraSettingsStore();

  /// Yerel ayarları yükler.
  Future<VehicleCameraSettingsRecord> load() async {
    final prefs = await SharedPreferences.getInstance();
    final interval = prefs.getInt(prefsInterval);
    final enabled = prefs.getBool(prefsEnabled) ?? false;
    final webrtcExplicit = prefs.containsKey(prefsWebrtc)
        ? prefs.getBool(prefsWebrtc)
        : null;
    final profile = VehicleCameraIceProfileX.parse(
      prefs.getString(prefsIceProfile),
    );
    // Eski kayıt: profil yok ama TURN dolu → customTurn varsay
    final turnUrl = prefs.getString(prefsTurnUrl) ?? '';
    final resolvedProfile = !prefs.containsKey(prefsIceProfile) &&
            turnUrl.trim().isNotEmpty
        ? VehicleCameraIceProfile.customTurn
        : profile;
    return VehicleCameraSettingsRecord(
      enabled: enabled,
      defaultLens: VehicleCameraLens.parse(
        prefs.getString(prefsDefaultLens),
      ),
      intervalSeconds: (interval ??
              VehicleCameraSettingsRecord.defaultIntervalSeconds)
          .clamp(
        VehicleCameraSettingsRecord.minIntervalSeconds,
        VehicleCameraSettingsRecord.maxIntervalSeconds,
      ),
      webrtcEnabled: VehicleCameraSettingsRecord.autoWebrtcWhenEnabled(
        enabled: enabled,
        webrtcExplicit: webrtcExplicit,
      ),
      audioEnabled: prefs.getBool(prefsAudio) ?? false,
      broadcastBothLenses: prefs.getBool(prefsBothLenses) ?? true,
      iceProfile: resolvedProfile,
      turnUrl: turnUrl,
      turnUsername: prefs.getString(prefsTurnUsername) ?? '',
      turnCredential: prefs.getString(prefsTurnCredential) ?? '',
    );
  }

  /// Ayarları kaydeder.
  Future<void> save(VehicleCameraSettingsRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final interval = record.intervalSeconds.clamp(
      VehicleCameraSettingsRecord.minIntervalSeconds,
      VehicleCameraSettingsRecord.maxIntervalSeconds,
    );
    await prefs.setBool(prefsEnabled, record.enabled);
    await prefs.setString(
      prefsDefaultLens,
      record.defaultLens.storageKey,
    );
    await prefs.setInt(prefsInterval, interval);
    await prefs.setBool(prefsWebrtc, record.webrtcEnabled);
    await prefs.setBool(prefsAudio, record.audioEnabled);
    await prefs.setBool(prefsBothLenses, record.broadcastBothLenses);
    await prefs.setString(prefsIceProfile, record.iceProfile.storageKey);
    await prefs.setString(prefsTurnUrl, record.turnUrl.trim());
    await prefs.setString(prefsTurnUsername, record.turnUsername.trim());
    await prefs.setString(prefsTurnCredential, record.turnCredential.trim());
  }
}
