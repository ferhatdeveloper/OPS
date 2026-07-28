// Dosya Adı: personnel_live_location_test.dart
// Açıklama: Personel canlı konum modeli + tazelik birim testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/gps/model/personnel_live_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PersonnelLiveLocation', () {
    test('fromMap / toMap yuvarlak trip', () {
      final now = DateTime(2026, 7, 27, 12, 0);
      final row = PersonnelLiveLocation(
        userId: 'u-1',
        salespersonCode: 'PLS01',
        displayName: 'Ali',
        latitude: 41.0082,
        longitude: 28.9784,
        updatedAt: now,
        accuracy: 12.0,
        isSynced: true,
      );

      final again = PersonnelLiveLocation.fromMap(row.toMap());
      expect(again.userId, 'u-1');
      expect(again.salespersonCode, 'PLS01');
      expect(again.displayName, 'Ali');
      expect(again.latitude, closeTo(41.0082, 1e-6));
      expect(again.longitude, closeTo(28.9784, 1e-6));
      expect(again.updatedAt, now);
      expect(again.accuracy, 12.0);
      expect(again.isSynced, isTrue);
      expect(again.coordinateText, contains('41.00820'));
    });

    test('isFresh maxAge içinde true, dışında false', () {
      final updated = DateTime(2026, 7, 27, 12, 0);
      final row = PersonnelLiveLocation(
        userId: 'u-1',
        salespersonCode: 'PLS01',
        displayName: 'Ali',
        latitude: 41.0,
        longitude: 29.0,
        updatedAt: updated,
      );

      expect(
        row.isFresh(
          now: updated.add(const Duration(seconds: 45)),
          maxAge: const Duration(seconds: 90),
        ),
        isTrue,
      );
      expect(
        row.isFresh(
          now: updated.add(const Duration(minutes: 5)),
          maxAge: const Duration(seconds: 90),
        ),
        isFalse,
      );
    });

    test('mergeLatestByUserId aynı user için en yeniyi tutar', () {
      final older = PersonnelLiveLocation(
        userId: 'u-1',
        salespersonCode: 'PLS01',
        displayName: 'Ali',
        latitude: 41.0,
        longitude: 29.0,
        updatedAt: DateTime(2026, 7, 27, 10, 0),
      );
      final newer = PersonnelLiveLocation(
        userId: 'u-1',
        salespersonCode: 'PLS01',
        displayName: 'Ali',
        latitude: 41.1,
        longitude: 29.1,
        updatedAt: DateTime(2026, 7, 27, 11, 0),
      );
      final other = PersonnelLiveLocation(
        userId: 'u-2',
        salespersonCode: 'PLS02',
        displayName: 'Veli',
        latitude: 40.0,
        longitude: 28.0,
        updatedAt: DateTime(2026, 7, 27, 10, 30),
      );

      final merged = PersonnelLiveLocation.mergeLatestByUserId([
        older,
        other,
        newer,
      ]);
      expect(merged.length, 2);
      final u1 = merged.firstWhere((e) => e.userId == 'u-1');
      expect(u1.latitude, closeTo(41.1, 1e-6));
      expect(merged.any((e) => e.userId == 'u-2'), isTrue);
    });
  });
}
