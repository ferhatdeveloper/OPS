// Dosya Adı: vehicle_camera_frame_test.dart
// Açıklama: Araç kamera kare modeli + son kare birleştirme testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/gps/model/vehicle_camera_frame.dart';
import 'package:exfin_ops/modules/field_sales/gps/model/vehicle_camera_lens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehicleCameraFrame', () {
    test('fromMap / toMap yuvarlak trip', () {
      final now = DateTime(2026, 7, 27, 15, 0);
      final frame = VehicleCameraFrame(
        id: 'f1',
        userId: 'u1',
        salespersonCode: 'PLS01',
        lens: VehicleCameraLens.rear,
        capturedAt: now,
        imageBase64: 'abc',
        isSynced: false,
      );
      final again = VehicleCameraFrame.fromMap(frame.toMap());
      expect(again.id, 'f1');
      expect(again.userId, 'u1');
      expect(again.lens, VehicleCameraLens.rear);
      expect(again.imageBase64, 'abc');
      expect(again.isSynced, isFalse);
    });

    test('latestByUserAndLens her çift için en yeniyi tutar', () {
      final a1 = VehicleCameraFrame(
        id: '1',
        userId: 'u1',
        salespersonCode: 'PLS01',
        lens: VehicleCameraLens.front,
        capturedAt: DateTime(2026, 7, 27, 10, 0),
        imageBase64: 'old',
      );
      final a2 = VehicleCameraFrame(
        id: '2',
        userId: 'u1',
        salespersonCode: 'PLS01',
        lens: VehicleCameraLens.front,
        capturedAt: DateTime(2026, 7, 27, 11, 0),
        imageBase64: 'new',
      );
      final b = VehicleCameraFrame(
        id: '3',
        userId: 'u1',
        salespersonCode: 'PLS01',
        lens: VehicleCameraLens.rear,
        capturedAt: DateTime(2026, 7, 27, 10, 30),
        imageBase64: 'rear',
      );
      final latest = VehicleCameraFrame.latestByUserAndLens([a1, b, a2]);
      expect(latest.length, 2);
      final front = latest.firstWhere(
        (f) => f.lens == VehicleCameraLens.front,
      );
      expect(front.imageBase64, 'new');
    });
  });
}
