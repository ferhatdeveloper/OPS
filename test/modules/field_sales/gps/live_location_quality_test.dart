// Dosya Adı: live_location_quality_test.dart
// Açıklama: Canlı konum doğruluk / tazelik filtre birim testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/gps/model/live_location_quality.dart';
import 'package:exfin_ops/modules/field_sales/gps/model/personnel_live_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveLocationQuality.acceptsFix', () {
    test('iyi doğruluk ve taze fix kabul', () {
      expect(
        LiveLocationQuality.acceptsFix(
          accuracyMeters: 12,
          fixAge: const Duration(seconds: 2),
        ),
        isTrue,
      );
    });

    test('doğruluk eşiği üstü reddedilir', () {
      expect(
        LiveLocationQuality.acceptsFix(
          accuracyMeters: LiveLocationQuality.maxSyncAccuracyMeters + 1,
          fixAge: Duration.zero,
        ),
        isFalse,
      );
      expect(
        LiveLocationQuality.acceptsFix(
          accuracyMeters: LiveLocationQuality.maxSyncAccuracyMeters,
          fixAge: Duration.zero,
        ),
        isTrue,
      );
    });

    test('bayat fix reddedilir', () {
      expect(
        LiveLocationQuality.acceptsFix(
          accuracyMeters: 10,
          fixAge: LiveLocationQuality.maxFixAge +
              const Duration(seconds: 1),
        ),
        isFalse,
      );
    });

    test('proximity için daha gevşek tavan', () {
      expect(
        LiveLocationQuality.acceptsFix(
          accuracyMeters: 75,
          fixAge: Duration.zero,
          maxAccuracyMeters:
              LiveLocationQuality.maxProximityAccuracyMeters,
        ),
        isTrue,
      );
      expect(
        LiveLocationQuality.acceptsFix(
          accuracyMeters: 75,
          fixAge: Duration.zero,
          maxAccuracyMeters:
              LiveLocationQuality.maxSyncAccuracyMeters,
        ),
        isFalse,
      );
    });

    test('null accuracy kabul (eski kayıt)', () {
      expect(
        LiveLocationQuality.acceptsFix(
          accuracyMeters: null,
          fixAge: Duration.zero,
        ),
        isTrue,
      );
    });
  });

  group('LiveLocationQuality.ageBucket', () {
    test('saniye / dakika / saat', () {
      expect(
        LiveLocationQuality.ageBucket(const Duration(seconds: 12)).unit,
        'seconds',
      );
      expect(
        LiveLocationQuality.ageBucket(const Duration(minutes: 3)).value,
        3,
      );
      expect(
        LiveLocationQuality.ageBucket(const Duration(hours: 2)).unit,
        'hours',
      );
    });
  });

  group('PersonnelLiveLocation freshness + accuracy', () {
    test('varsayılan isFresh ~90 sn penceresi', () {
      final updated = DateTime(2026, 7, 27, 12, 0);
      final row = PersonnelLiveLocation(
        userId: 'u-1',
        salespersonCode: 'PLS01',
        displayName: 'Ali',
        latitude: 41.0,
        longitude: 29.0,
        updatedAt: updated,
        accuracy: 15,
      );

      expect(
        row.isFresh(now: updated.add(const Duration(seconds: 60))),
        isTrue,
      );
      expect(
        row.isFresh(now: updated.add(const Duration(seconds: 120))),
        isFalse,
      );
    });

    test('hasAcceptableAccuracy eşiği', () {
      final good = PersonnelLiveLocation(
        userId: 'u-1',
        salespersonCode: 'PLS01',
        displayName: 'Ali',
        latitude: 41.0,
        longitude: 29.0,
        updatedAt: DateTime(2026, 7, 27),
        accuracy: 20,
      );
      final bad = PersonnelLiveLocation(
        userId: 'u-1',
        salespersonCode: 'PLS01',
        displayName: 'Ali',
        latitude: 41.0,
        longitude: 29.0,
        updatedAt: DateTime(2026, 7, 27),
        accuracy: 80,
      );
      expect(good.hasAcceptableAccuracy(), isTrue);
      expect(bad.hasAcceptableAccuracy(), isFalse);
    });
  });
}
