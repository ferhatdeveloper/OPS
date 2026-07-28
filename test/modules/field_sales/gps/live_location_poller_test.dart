// Dosya Adı: live_location_poller_test.dart
// Açıklama: Canlı konum fingerprint / doğruluk bandı testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/modules/field_sales/gps/model/live_location_quality.dart';
import 'package:exfin_ops/modules/field_sales/gps/model/live_location_transport.dart';
import 'package:exfin_ops/modules/field_sales/gps/model/personnel_live_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveLocationSnapshotFingerprint', () {
    test('aynı satırlar aynı fingerprint', () {
      final t = DateTime(2026, 7, 28, 10);
      final a = [
        PersonnelLiveLocation(
          userId: 'u1',
          salespersonCode: 'P1',
          displayName: 'A',
          latitude: 41.0,
          longitude: 29.0,
          updatedAt: t,
          accuracy: 12,
        ),
      ];
      final b = [
        PersonnelLiveLocation(
          userId: 'u1',
          salespersonCode: 'P1',
          displayName: 'A',
          latitude: 41.0,
          longitude: 29.0,
          updatedAt: t,
          accuracy: 12,
        ),
      ];
      expect(
        LiveLocationSnapshotFingerprint.fromRows(a).value,
        LiveLocationSnapshotFingerprint.fromRows(b).value,
      );
    });

    test('konum değişince fingerprint değişir', () {
      final t = DateTime(2026, 7, 28, 10);
      final a = LiveLocationSnapshotFingerprint.fromRows([
        PersonnelLiveLocation(
          userId: 'u1',
          salespersonCode: 'P1',
          displayName: 'A',
          latitude: 41.0,
          longitude: 29.0,
          updatedAt: t,
        ),
      ]);
      final b = LiveLocationSnapshotFingerprint.fromRows([
        PersonnelLiveLocation(
          userId: 'u1',
          salespersonCode: 'P1',
          displayName: 'A',
          latitude: 41.001,
          longitude: 29.0,
          updatedAt: t,
        ),
      ]);
      expect(a.value, isNot(b.value));
    });
  });

  group('LiveLocationQuality.accuracyBand', () {
    test('iyi / orta / zayıf / bilinmiyor', () {
      expect(
        LiveLocationQuality.accuracyBand(10),
        LiveLocationAccuracyBand.good,
      );
      expect(
        LiveLocationQuality.accuracyBand(40),
        LiveLocationAccuracyBand.fair,
      );
      expect(
        LiveLocationQuality.accuracyBand(80),
        LiveLocationAccuracyBand.poor,
      );
      expect(
        LiveLocationQuality.accuracyBand(null),
        LiveLocationAccuracyBand.unknown,
      );
    });
  });

  group('LiveLocationQuality.pollIntervalForStep', () {
    test('backoff adımları artar', () {
      expect(
        LiveLocationQuality.pollIntervalForStep(0),
        LiveLocationQuality.managerPollInterval,
      );
      expect(
        LiveLocationQuality.pollIntervalForStep(4).inSeconds,
        greaterThan(
          LiveLocationQuality.pollIntervalForStep(0).inSeconds,
        ),
      );
    });
  });
}
