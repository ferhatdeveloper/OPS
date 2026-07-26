// Dosya Adı: day_status_store_test.dart
// Açıklama: MBT gün başla/bitir SharedPreferences kalıcılık testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exfin_ops/modules/field_sales/other/model/day_status_record.dart';
import 'package:exfin_ops/modules/field_sales/other/viewmodel/day_status_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DayStatusStore', () {
    test('boş prefs yüklenince varsayılan kayıt döner', () async {
      final store = DayStatusStore();
      final record = await store.load();

      expect(record.plate, isEmpty);
      expect(record.startKm, isNull);
      expect(record.endKm, isNull);
      expect(record.completed, isFalse);
      expect(record.isDayStarted, isFalse);
      expect(record.startTime, isNull);
      expect(record.endTime, isNull);
    });

    test('kaydet ve yükle plaka / km / tamamlandı alanlarını korur', () async {
      final store = DayStatusStore();
      final start = DateTime(2026, 7, 26, 8, 30);
      final end = DateTime(2026, 7, 26, 17, 45);

      await store.save(
        DayStatusRecord(
          plate: '34 ABC 123',
          startKm: 12000,
          endKm: 12150,
          completed: true,
          isDayStarted: false,
          startTime: start,
          endTime: end,
        ),
      );

      final loaded = await store.load();
      expect(loaded.plate, '34 ABC 123');
      expect(loaded.startKm, 12000);
      expect(loaded.endKm, 12150);
      expect(loaded.completed, isTrue);
      expect(loaded.isDayStarted, isFalse);
      expect(loaded.startTime, start);
      expect(loaded.endTime, end);
    });

    test('validateEndKm bitiş < başlangıç ise hata anahtarı döner', () {
      expect(
        DayStatusRecord.validateEndKm(100, 90),
        'field_sales.day_end_km_invalid',
      );
      expect(DayStatusRecord.validateEndKm(100, 100), isNull);
      expect(DayStatusRecord.validateEndKm(100, 110), isNull);
      expect(DayStatusRecord.validateEndKm(null, 50), isNull);
    });

    test('applySave tamamlandı true ise günü bitirir', () {
      final now = DateTime(2026, 7, 26, 18, 0);
      final open = DayStatusRecord(
        plate: '06 XYZ 01',
        startKm: 500,
        endKm: null,
        completed: false,
        isDayStarted: true,
        startTime: DateTime(2026, 7, 26, 8, 0),
      );

      final closed = DayStatusRecord.applySave(
        current: open,
        plate: '06 XYZ 01',
        startKm: 500,
        endKm: 620,
        completed: true,
        now: now,
      );

      expect(closed.completed, isTrue);
      expect(closed.isDayStarted, isFalse);
      expect(closed.endKm, 620);
      expect(closed.endTime, now);
    });

    test('applySave tamamlandı false ve başlangıç km ile günü açar', () {
      final now = DateTime(2026, 7, 26, 8, 15);
      final closed = const DayStatusRecord();

      final opened = DayStatusRecord.applySave(
        current: closed,
        plate: '35 DEF 99',
        startKm: 1000,
        endKm: null,
        completed: false,
        now: now,
      );

      expect(opened.plate, '35 DEF 99');
      expect(opened.startKm, 1000);
      expect(opened.completed, isFalse);
      expect(opened.isDayStarted, isTrue);
      expect(opened.startTime, now);
      expect(opened.endTime, isNull);
    });
  });
}
