// Dosya Adı: order_geofence_gate.dart
// Açıklama: Sipariş kaydı için müşteri GPS yarıçap kapısı (saf değerlendirme)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import '../../../../core/geo/haversine.dart';

/// {@template order_geofence_decision}
/// Sipariş geofence değerlendirme sonucu.
///
/// Kullanım örneği:
/// ```dart
/// if (!decision.allowed) show dens error(decision.errorKey);
/// ```
/// {@endtemplate}
class OrderGeofenceDecision {
  /// [allowed]: Sipariş kaydına izin var mı
  final bool allowed;

  /// [errorKey]: l10n hata anahtarı (engel varsa)
  final String? errorKey;

  /// [distanceMeters]: Cihaz–müşteri mesafesi (varsa)
  final double? distanceMeters;

  /// {@macro order_geofence_decision}
  const OrderGeofenceDecision({
    required this.allowed,
    this.errorKey,
    this.distanceMeters,
  });
}

/// {@template order_geofence_gate}
/// Parametre açıkken sipariş yalnızca müşteri lat/long yarıçapında.
/// Check-in geofence’ten bağımsız; [orderRequireGeofence] ayrı bayrak.
///
/// Kullanım örneği:
/// ```dart
/// final d = OrderGeofenceGate.evaluate(
///   orderRequireGeofence: true,
///   radiusMeters: 100,
///   failClosed: true,
///   customerLat: 41.0,
///   customerLng: 29.0,
///   deviceLat: 41.0001,
///   deviceLng: 29.0,
/// );
/// ```
/// {@endtemplate}
class OrderGeofenceGate {
  OrderGeofenceGate._();

  /// {@template order_geofence_gate_evaluate}
  /// Saf geofence kararı (GPS IO yok).
  ///
  /// Parametreler:
  /// - [orderRequireGeofence]: Sipariş GPS zorunluluğu
  /// - [radiusMeters]: İzin verilen yarıçap
  /// - [failClosed]: GPS / müşteri koordinatı yoksa engelle
  /// - [customerLat] / [customerLng]: Müşteri konumu
  /// - [deviceLat] / [deviceLng]: Cihaz konumu
  ///
  /// Dönüş değeri:
  /// - [OrderGeofenceDecision]: İzin + opsiyonel hata anahtarı
  /// {@endtemplate}
  static OrderGeofenceDecision evaluate({
    required bool orderRequireGeofence,
    required int radiusMeters,
    required bool failClosed,
    required double? customerLat,
    required double? customerLng,
    required double? deviceLat,
    required double? deviceLng,
  }) {
    if (!orderRequireGeofence) {
      return const OrderGeofenceDecision(allowed: true);
    }

    final hasCustomer =
        customerLat != null && customerLng != null;
    if (!hasCustomer) {
      if (failClosed) {
        return const OrderGeofenceDecision(
          allowed: false,
          errorKey: 'field_sales.order_geofence_no_customer_coords',
        );
      }
      return const OrderGeofenceDecision(allowed: true);
    }

    final hasDevice = deviceLat != null && deviceLng != null;
    if (!hasDevice) {
      if (failClosed) {
        return const OrderGeofenceDecision(
          allowed: false,
          errorKey: 'field_sales.order_geofence_gps_unavailable',
        );
      }
      return const OrderGeofenceDecision(allowed: true);
    }

    final distance = haversineMeters(
      deviceLat,
      deviceLng,
      customerLat,
      customerLng,
    );
    if (distance > radiusMeters) {
      return OrderGeofenceDecision(
        allowed: false,
        errorKey: 'field_sales.order_geofence_outside',
        distanceMeters: distance,
      );
    }
    return OrderGeofenceDecision(
      allowed: true,
      distanceMeters: distance,
    );
  }
}
