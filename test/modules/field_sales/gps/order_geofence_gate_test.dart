// Dosya Adı: order_geofence_gate_test.dart
// Açıklama: Sipariş geofence kapısı (parametre + yarıçap) birim testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/gps/engine/order_geofence_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderGeofenceGate.evaluate', () {
    test('param kapalıysa her zaman izin verir', () {
      final d = OrderGeofenceGate.evaluate(
        orderRequireGeofence: false,
        radiusMeters: 100,
        failClosed: true,
        customerLat: 41.0,
        customerLng: 29.0,
        deviceLat: 40.0,
        deviceLng: 28.0,
      );
      expect(d.allowed, isTrue);
      expect(d.errorKey, isNull);
    });

    test('müşteri koordinatı yok + failClosed → engel', () {
      final d = OrderGeofenceGate.evaluate(
        orderRequireGeofence: true,
        radiusMeters: 100,
        failClosed: true,
        customerLat: null,
        customerLng: null,
        deviceLat: 41.0,
        deviceLng: 29.0,
      );
      expect(d.allowed, isFalse);
      expect(
        d.errorKey,
        'field_sales.order_geofence_no_customer_coords',
      );
    });

    test('müşteri koordinatı yok + failClosed kapalı → izin', () {
      final d = OrderGeofenceGate.evaluate(
        orderRequireGeofence: true,
        radiusMeters: 100,
        failClosed: false,
        customerLat: null,
        customerLng: 29.0,
        deviceLat: 41.0,
        deviceLng: 29.0,
      );
      expect(d.allowed, isTrue);
    });

    test('cihaz GPS yok + failClosed → engel', () {
      final d = OrderGeofenceGate.evaluate(
        orderRequireGeofence: true,
        radiusMeters: 100,
        failClosed: true,
        customerLat: 41.0,
        customerLng: 29.0,
        deviceLat: null,
        deviceLng: null,
      );
      expect(d.allowed, isFalse);
      expect(d.errorKey, 'field_sales.order_geofence_gps_unavailable');
    });

    test('yarıçap içinde izin verir', () {
      final d = OrderGeofenceGate.evaluate(
        orderRequireGeofence: true,
        radiusMeters: 200,
        failClosed: true,
        customerLat: 41.0,
        customerLng: 29.0,
        deviceLat: 41.0005,
        deviceLng: 29.0,
      );
      expect(d.allowed, isTrue);
      expect(d.distanceMeters, isNotNull);
      expect(d.distanceMeters!, lessThan(200));
    });

    test('yarıçap dışında engeller', () {
      final d = OrderGeofenceGate.evaluate(
        orderRequireGeofence: true,
        radiusMeters: 50,
        failClosed: true,
        customerLat: 41.0,
        customerLng: 29.0,
        deviceLat: 41.01,
        deviceLng: 29.0,
      );
      expect(d.allowed, isFalse);
      expect(d.errorKey, 'field_sales.order_geofence_outside');
      expect(d.distanceMeters, greaterThan(50));
    });
  });
}
