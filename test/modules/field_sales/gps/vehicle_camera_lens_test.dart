// Dosya Adı: vehicle_camera_lens_test.dart
// Açıklama: Araç kamera lens enum / parse birim testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/gps/model/vehicle_camera_lens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehicleCameraLens', () {
    test('parse front / rear / bilinmeyen', () {
      expect(VehicleCameraLens.parse('front'), VehicleCameraLens.front);
      expect(VehicleCameraLens.parse('rear'), VehicleCameraLens.rear);
      expect(VehicleCameraLens.parse('BACK'), VehicleCameraLens.rear);
      expect(VehicleCameraLens.parse(null), VehicleCameraLens.front);
      expect(VehicleCameraLens.parse('x'), VehicleCameraLens.front);
    });

    test('storageKey sabit', () {
      expect(VehicleCameraLens.front.storageKey, 'front');
      expect(VehicleCameraLens.rear.storageKey, 'rear');
    });
  });
}
