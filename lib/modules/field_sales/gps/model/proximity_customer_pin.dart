// Dosya Adı: proximity_customer_pin.dart
// Açıklama: Proximity motoru için cari konum pini (id/ad/lat/lng)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template proximity_customer_pin}
/// SQLite müşteri satırından gelen hafif konum pini.
///
/// Kullanım örneği:
/// ```dart
/// const pin = ProximityCustomerPin(
///   id: 'c1',
///   name: 'ABC Market',
///   latitude: 41.0,
///   longitude: 29.0,
/// );
/// ```
/// {@endtemplate}
class ProximityCustomerPin {
  /// [id]: Cari kimliği
  final String id;

  /// [name]: Cari ünvanı
  final String name;

  /// [latitude]: Enlem
  final double latitude;

  /// [longitude]: Boylam
  final double longitude;

  /// {@macro proximity_customer_pin}
  const ProximityCustomerPin({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

/// {@template proximity_hit}
/// Yarıçap içindeki en yakın müşteri sonucu.
/// {@endtemplate}
class ProximityHit {
  /// [customerId]: Cari kimliği
  final String customerId;

  /// [customerName]: Cari ünvanı
  final String customerName;

  /// [distanceMeters]: Kullanıcıdan mesafe (m)
  final double distanceMeters;

  /// {@macro proximity_hit}
  const ProximityHit({
    required this.customerId,
    required this.customerName,
    required this.distanceMeters,
  });
}
