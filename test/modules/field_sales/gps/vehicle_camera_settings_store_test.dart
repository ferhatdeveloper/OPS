// Dosya Adı: vehicle_camera_settings_store_test.dart
// Açıklama: Araç kamera ayarları SharedPreferences testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/gps/model/vehicle_camera_ice_profile.dart';
import 'package:exfin_ops/modules/field_sales/gps/model/vehicle_camera_lens.dart';
import 'package:exfin_ops/modules/field_sales/gps/model/vehicle_camera_settings_record.dart';
import 'package:exfin_ops/modules/field_sales/gps/viewmodel/vehicle_camera_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VehicleCameraSettingsStore', () {
    test('varsayılan kapalı', () async {
      const store = VehicleCameraSettingsStore();
      final r = await store.load();
      expect(r.enabled, isFalse);
      expect(r.defaultLens, VehicleCameraLens.front);
      expect(r.audioEnabled, isFalse);
    });

    test('kaydet / yükle', () async {
      const store = VehicleCameraSettingsStore();
      await store.save(
        const VehicleCameraSettingsRecord(
          enabled: true,
          defaultLens: VehicleCameraLens.rear,
          intervalSeconds: 12,
          webrtcEnabled: true,
          audioEnabled: true,
          broadcastBothLenses: true,
          iceProfile: VehicleCameraIceProfile.customTurn,
          turnUrl: 'turn:example.com:3478',
          turnUsername: 'tu',
          turnCredential: 'tp',
        ),
      );
      final r = await store.load();
      expect(r.enabled, isTrue);
      expect(r.defaultLens, VehicleCameraLens.rear);
      expect(r.intervalSeconds, 12);
      expect(r.webrtcEnabled, isTrue);
      expect(r.audioEnabled, isTrue);
      expect(r.broadcastBothLenses, isTrue);
      expect(r.iceProfile, VehicleCameraIceProfile.customTurn);
      expect(r.turnUrl, 'turn:example.com:3478');
      expect(r.turnUsername, 'tu');
      expect(r.turnCredential, 'tp');
    });

    test('TURN dolu + profil yok → customTurn migrate', () async {
      SharedPreferences.setMockInitialValues({
        VehicleCameraSettingsStore.prefsEnabled: true,
        VehicleCameraSettingsStore.prefsTurnUrl: 'turn:x:3478',
      });
      const store = VehicleCameraSettingsStore();
      final r = await store.load();
      expect(r.iceProfile, VehicleCameraIceProfile.customTurn);
    });

    test('kamera açık + webrtc kaydı yok → webrtc otomatik', () async {
      SharedPreferences.setMockInitialValues({
        VehicleCameraSettingsStore.prefsEnabled: true,
      });
      const store = VehicleCameraSettingsStore();
      final r = await store.load();
      expect(r.enabled, isTrue);
      expect(r.webrtcEnabled, isTrue);
    });

    test('webrtc açıkça kapalı kalır', () async {
      const store = VehicleCameraSettingsStore();
      await store.save(
        const VehicleCameraSettingsRecord(
          enabled: true,
          webrtcEnabled: false,
        ),
      );
      final r = await store.load();
      expect(r.webrtcEnabled, isFalse);
    });
  });

  group('VehicleCameraSettingsRecord.autoWebrtcWhenEnabled', () {
    test('explicit null + enabled → true', () {
      expect(
        VehicleCameraSettingsRecord.autoWebrtcWhenEnabled(
          enabled: true,
          webrtcExplicit: null,
        ),
        isTrue,
      );
    });

    test('explicit false korunur', () {
      expect(
        VehicleCameraSettingsRecord.autoWebrtcWhenEnabled(
          enabled: true,
          webrtcExplicit: false,
        ),
        isFalse,
      );
    });
  });
}
