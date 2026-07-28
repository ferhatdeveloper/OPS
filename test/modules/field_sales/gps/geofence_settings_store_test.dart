// Dosya Adı: geofence_settings_store_test.dart
// Açıklama: Geofence ayarları SharedPreferences kalıcılık testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/gps/model/geofence_settings_record.dart';
import 'package:exfin_ops/modules/field_sales/gps/viewmodel/geofence_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GeofenceSettingsStore', () {
    test('boş prefs yüklenince varsayılan kayıt döner', () async {
      const store = GeofenceSettingsStore();
      final record = await store.load();

      expect(record.enabled, isTrue);
      expect(
        record.radiusMeters,
        GeofenceSettingsRecord.defaultRadiusMeters,
      );
      expect(record.failClosed, isTrue);
    });

    test('kaydet ve yükle tüm alanları korur', () async {
      const store = GeofenceSettingsStore();
      await store.save(
        const GeofenceSettingsRecord(
          enabled: false,
          radiusMeters: 250,
          failClosed: false,
          orderRequireGeofence: true,
          proximityAlertsEnabled: false,
          proximityRadiusMeters: 180,
        ),
      );

      final loaded = await store.load();
      expect(loaded.enabled, isFalse);
      expect(loaded.radiusMeters, 250);
      expect(loaded.failClosed, isFalse);
      expect(loaded.orderRequireGeofence, isTrue);
      expect(loaded.proximityAlertsEnabled, isFalse);
      expect(loaded.proximityRadiusMeters, 180);
      expect(loaded.effectiveProximityRadiusMeters, 180);
    });

    test('proximityRadius 0 → effective check-in yarıçapı', () {
      const r = GeofenceSettingsRecord(
        radiusMeters: 120,
        proximityRadiusMeters: 0,
      );
      expect(r.effectiveProximityRadiusMeters, 120);
    });

    test('orderRequireGeofence varsayılan false', () async {
      const store = GeofenceSettingsStore();
      final record = await store.load();
      expect(record.orderRequireGeofence, isFalse);
      expect(record.proximityAlertsEnabled, isTrue);
    });

    test('save yarıçapı min/max aralığına sıkıştırır', () async {
      const store = GeofenceSettingsStore();
      await store.save(
        const GeofenceSettingsRecord(radiusMeters: 1),
      );
      expect(
        (await store.load()).radiusMeters,
        GeofenceSettingsRecord.minRadiusMeters,
      );

      await store.save(
        const GeofenceSettingsRecord(radiusMeters: 99999),
      );
      expect(
        (await store.load()).radiusMeters,
        GeofenceSettingsRecord.maxRadiusMeters,
      );
    });
  });

  group('GeofenceSettingsRecord.validateRadius', () {
    test('null / aralık dışı hata anahtarı döner', () {
      expect(
        GeofenceSettingsRecord.validateRadius(null),
        'field_sales.geofence_radius_required',
      );
      expect(
        GeofenceSettingsRecord.validateRadius(5),
        'field_sales.geofence_radius_invalid',
      );
      expect(
        GeofenceSettingsRecord.validateRadius(6000),
        'field_sales.geofence_radius_invalid',
      );
      expect(GeofenceSettingsRecord.validateRadius(100), isNull);
    });
  });
}
