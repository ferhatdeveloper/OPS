// Dosya Adı: vehicle_camera_ice_config.dart
// Açıklama: WebRTC ICE sunucuları (STUN otomatik; TURN profili opsiyonel)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'vehicle_camera_ice_profile.dart';
import 'vehicle_camera_settings_record.dart';

/// {@template vehicle_camera_ice_config}
/// P2P bağlantı için ICE sunucu listesi.
/// Genel STUN çoğu ev/ofis NAT için yeterlidir; simetrik/kurumsal
/// NAT veya CGNAT için TURN ayarlardan girilir.
///
/// Kullanım örneği:
/// ```dart
/// final ice = VehicleCameraIceConfig.defaults();
/// final maps = ice.toRtcIceServers();
/// ```
/// {@endtemplate}
class VehicleCameraIceConfig {
  /// Genel Google STUN yedekleri (otomatik yapılandırma).
  static const List<String> defaultStunUrls = [
    'stun:stun.l.google.com:19302',
    'stun:stun1.l.google.com:19302',
    'stun:stun2.l.google.com:19302',
  ];

  /// [stunUrls]: STUN sunucuları
  final List<String> stunUrls;

  /// [turnUrl]: Opsiyonel TURN URL (örn. turn:turn.example.com:3478)
  final String? turnUrl;

  /// [turnUsername]: TURN kullanıcı
  final String? turnUsername;

  /// [turnCredential]: TURN parola
  final String? turnCredential;

  /// {@macro vehicle_camera_ice_config}
  const VehicleCameraIceConfig({
    this.stunUrls = defaultStunUrls,
    this.turnUrl,
    this.turnUsername,
    this.turnCredential,
  });

  /// Genel STUN ile varsayılan yapılandırma (TURN yalnızca doluysa).
  factory VehicleCameraIceConfig.defaults({
    String? turnUrl,
    String? turnUsername,
    String? turnCredential,
  }) {
    return VehicleCameraIceConfig(
      turnUrl: _emptyToNull(turnUrl),
      turnUsername: _emptyToNull(turnUsername),
      turnCredential: _emptyToNull(turnCredential),
    );
  }

  /// {@template vehicle_camera_ice_config_from_settings}
  /// Ayar kaydından ICE — `autoStun` profilinde TURN yok sayılır.
  /// {@endtemplate}
  factory VehicleCameraIceConfig.fromSettings(
    VehicleCameraSettingsRecord settings,
  ) {
    if (settings.iceProfile == VehicleCameraIceProfile.autoStun) {
      return VehicleCameraIceConfig.defaults();
    }
    return VehicleCameraIceConfig.defaults(
      turnUrl: settings.turnUrl,
      turnUsername: settings.turnUsername,
      turnCredential: settings.turnCredential,
    );
  }

  /// flutter_webrtc `iceServers` map listesi.
  List<Map<String, dynamic>> toRtcIceServers() {
    final list = <Map<String, dynamic>>[
      for (final u in stunUrls)
        if (u.trim().isNotEmpty) {'urls': u.trim()},
    ];
    final turn = turnUrl?.trim();
    if (turn != null && turn.isNotEmpty) {
      list.add({
        'urls': turn,
        if (turnUsername != null && turnUsername!.trim().isNotEmpty)
          'username': turnUsername!.trim(),
        if (turnCredential != null && turnCredential!.trim().isNotEmpty)
          'credential': turnCredential!.trim(),
      });
    }
    return list;
  }

  /// TURN tanımlı mı (simetrik NAT notu için).
  bool get hasTurn {
    final t = turnUrl?.trim();
    return t != null && t.isNotEmpty;
  }

  static String? _emptyToNull(String? v) {
    final t = v?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }
}
