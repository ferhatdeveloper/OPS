// Dosya Adı: vehicle_camera_transport.dart
// Açıklama: Araç kamera canlı taşıma tercihi ve fallback seçimi
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template vehicle_camera_active_transport}
/// Aktif canlı taşıma yolu.
/// {@endtemplate}
enum VehicleCameraActiveTransport {
  /// JPEG snapshot polling (mevcut yol)
  jpegPoll,

  /// WebRTC P2P video
  webrtc,
}

/// {@template vehicle_camera_transport_selector}
/// WebRTC tercih / platform / hata durumuna göre taşıma seçer.
///
/// Kullanım örneği:
/// ```dart
/// final t = VehicleCameraTransportSelector.resolve(
///   webrtcEnabled: true,
///   platformSupportsWebrtc: true,
///   webrtcFailed: false,
/// );
/// ```
/// {@endtemplate}
class VehicleCameraTransportSelector {
  /// {@macro vehicle_camera_transport_selector}
  const VehicleCameraTransportSelector._();

  /// Tercih + yetenek + hata → aktif taşıma.
  ///
  /// Parametreler:
  /// - [webrtcEnabled]: Ayarlarda "WebRTC canlı" açık mı
  /// - [platformSupportsWebrtc]: Platformda WebRTC denenebilir mi
  /// - [webrtcFailed]: Oturum kurulumu / bağlanma başarısız mı
  ///
  /// Dönüş değeri:
  /// - [VehicleCameraActiveTransport]: jpegPoll veya webrtc
  static VehicleCameraActiveTransport resolve({
    required bool webrtcEnabled,
    required bool platformSupportsWebrtc,
    required bool webrtcFailed,
  }) {
    if (!webrtcEnabled || !platformSupportsWebrtc || webrtcFailed) {
      return VehicleCameraActiveTransport.jpegPoll;
    }
    return VehicleCameraActiveTransport.webrtc;
  }

  /// Yayıncı (plasiyer) WebRTC destekler mi?
  /// Web'de yayın yok (kamera plugin + arka plan kısıtı).
  static bool supportsBroadcastWebrtc({required bool isWeb}) {
    return !isWeb;
  }

  /// İzleyici (yönetici) WebRTC destekler mi?
  /// Web dahil denenebilir; NAT/TURN yoksa JPEG'e düşer.
  static bool supportsMonitorWebrtc({required bool isWeb}) {
    // ignore: unused_local_variable — web de denenebilir
    final _ = isWeb;
    return true;
  }
}
