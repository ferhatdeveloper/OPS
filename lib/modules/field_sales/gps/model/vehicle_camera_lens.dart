// Dosya Adı: vehicle_camera_lens.dart
// Açıklama: Araç kamera lens seçimi (ön / arka)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template vehicle_camera_lens}
/// Araç kamera yönü — tek cihazda eşzamanlı çift stream genelde yok;
/// plasiyer ön veya arka seçer (veya yönetici ayrı kareleri izler).
///
/// Kullanım örneği:
/// ```dart
/// final lens = VehicleCameraLens.parse('rear');
/// ```
/// {@endtemplate}
enum VehicleCameraLens {
  /// Ön kamera
  front,

  /// Arka kamera
  rear;

  /// SQLite / prefs saklama anahtarı
  String get storageKey => this == VehicleCameraLens.rear ? 'rear' : 'front';

  /// Ham metinden parse (null / bilinmeyen → front)
  static VehicleCameraLens parse(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s == 'rear' || s == 'back' || s == 'arka') {
      return VehicleCameraLens.rear;
    }
    return VehicleCameraLens.front;
  }
}
