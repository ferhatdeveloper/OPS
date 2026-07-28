// Dosya Adı: customer_proximity_engine_test.dart
// Açıklama: En yakın müşteri proximity + debounce birim testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/gps/model/proximity_customer_pin.dart';
import 'package:exfin_ops/modules/field_sales/gps/viewmodel/customer_proximity_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CustomerProximityEngine engine;

  setUp(() {
    engine = CustomerProximityEngine(
      cooldown: const Duration(minutes: 30),
    );
  });

  const near = ProximityCustomerPin(
    id: 'near',
    name: 'Yakın Market',
    latitude: 41.0005,
    longitude: 29.0,
  );

  const far = ProximityCustomerPin(
    id: 'far',
    name: 'Uzak Market',
    latitude: 41.05,
    longitude: 29.0,
  );

  const closer = ProximityCustomerPin(
    id: 'closer',
    name: 'Daha Yakın',
    latitude: 41.0002,
    longitude: 29.0,
  );

  group('CustomerProximityEngine.evaluate', () {
    test('yarıçap dışındaysa null döner', () {
      final hit = engine.evaluate(
        userLat: 41.0,
        userLng: 29.0,
        radiusMeters: 100,
        customers: [far],
        now: DateTime(2026, 7, 27, 10),
      );
      expect(hit, isNull);
    });

    test('yarıçap içinde en yakını seçer', () {
      final hit = engine.evaluate(
        userLat: 41.0,
        userLng: 29.0,
        radiusMeters: 200,
        customers: [far, near, closer],
        now: DateTime(2026, 7, 27, 10),
      );
      expect(hit, isNotNull);
      expect(hit!.customerId, 'closer');
      expect(hit.customerName, 'Daha Yakın');
      expect(hit.distanceMeters, lessThan(50));
    });

    test('aynı müşteri içerideyken tekrar spam etmez', () {
      final t0 = DateTime(2026, 7, 27, 10);
      final first = engine.evaluate(
        userLat: 41.0,
        userLng: 29.0,
        radiusMeters: 200,
        customers: [near],
        now: t0,
      );
      expect(first, isNotNull);

      final second = engine.evaluate(
        userLat: 41.0,
        userLng: 29.0,
        radiusMeters: 200,
        customers: [near],
        now: t0.add(const Duration(minutes: 1)),
      );
      expect(second, isNull);
      expect(engine.isInside('near'), isTrue);
    });

    test('çıkış + cooldown dolunca yeniden uyarır', () {
      final t0 = DateTime(2026, 7, 27, 10);
      expect(
        engine.evaluate(
          userLat: 41.0,
          userLng: 29.0,
          radiusMeters: 200,
          customers: [near],
          now: t0,
        ),
        isNotNull,
      );

      // Yarıçap dışına çık (aynı pin listesi, kullanıcı uzak)
      expect(
        engine.evaluate(
          userLat: 42.0,
          userLng: 29.0,
          radiusMeters: 200,
          customers: [near, far],
          now: t0.add(const Duration(minutes: 5)),
        ),
        isNull,
      );
      expect(engine.isInside('near'), isFalse);

      // Cooldown henüz dolmadı
      expect(
        engine.evaluate(
          userLat: 41.0,
          userLng: 29.0,
          radiusMeters: 200,
          customers: [near],
          now: t0.add(const Duration(minutes: 10)),
        ),
        isNull,
      );
      expect(engine.isInside('near'), isFalse);

      // Cooldown sonrası yeniden
      final again = engine.evaluate(
        userLat: 41.0,
        userLng: 29.0,
        radiusMeters: 200,
        customers: [near],
        now: t0.add(const Duration(minutes: 31)),
      );
      expect(again, isNotNull);
      expect(again!.customerId, 'near');
    });

    test('clear debounce durumunu sıfırlar', () {
      final t0 = DateTime(2026, 7, 27, 10);
      engine.evaluate(
        userLat: 41.0,
        userLng: 29.0,
        radiusMeters: 200,
        customers: [near],
        now: t0,
      );
      engine.clear();
      final hit = engine.evaluate(
        userLat: 41.0,
        userLng: 29.0,
        radiusMeters: 200,
        customers: [near],
        now: t0.add(const Duration(seconds: 1)),
      );
      expect(hit, isNotNull);
    });
  });
}
