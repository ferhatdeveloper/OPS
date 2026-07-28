// Dosya Adı: vehicle_camera_ice_profile.dart
// Açıklama: WebRTC ICE profili — otomatik STUN veya özel TURN
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template vehicle_camera_ice_profile}
/// Araç kamera ICE yapılandırma profili.
///
/// Kullanım örneği:
/// ```dart
/// final p = VehicleCameraIceProfile.parse('custom_turn');
/// ```
/// {@endtemplate}
enum VehicleCameraIceProfile {
  /// Genel STUN otomatik; TURN yok (varsayılan).
  autoStun,

  /// Kullanıcı TURN URL + kimlik bilgisi girer.
  customTurn,
}

/// {@template vehicle_camera_ice_profile_ext}
/// Profil serileştirme / parse yardımcıları.
/// {@endtemplate}
extension VehicleCameraIceProfileX on VehicleCameraIceProfile {
  /// SharedPreferences / JSON anahtarı.
  String get storageKey {
    switch (this) {
      case VehicleCameraIceProfile.autoStun:
        return 'auto_stun';
      case VehicleCameraIceProfile.customTurn:
        return 'custom_turn';
    }
  }

  /// l10n anahtarı.
  String get labelKey {
    switch (this) {
      case VehicleCameraIceProfile.autoStun:
        return 'field_sales.vehicle_camera_ice_profile_auto';
      case VehicleCameraIceProfile.customTurn:
        return 'field_sales.vehicle_camera_ice_profile_turn';
    }
  }

  /// Ham metinden profil; bilinmeyen → autoStun.
  static VehicleCameraIceProfile parse(String? raw) {
    final t = (raw ?? '').trim().toLowerCase();
    if (t == VehicleCameraIceProfile.customTurn.storageKey ||
        t == 'custom' ||
        t == 'turn') {
      return VehicleCameraIceProfile.customTurn;
    }
    return VehicleCameraIceProfile.autoStun;
  }
}
