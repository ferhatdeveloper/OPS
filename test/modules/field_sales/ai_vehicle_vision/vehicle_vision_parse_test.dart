// Dosya Adı: vehicle_vision_parse_test.dart
// Açıklama: Araç vision JSON → VehicleVisionResult unit test
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/modules/field_sales/ai_vehicle_vision/engine/vehicle_vision_analyzer.dart';
import 'package:exfin_ops/modules/field_sales/ai_vehicle_vision/model/vehicle_vision_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('JSON obje → plaka/marka/tür/renk', () {
    const raw = '''
    {
      "plate": "34 ABC 123",
      "brand": "Toyota",
      "model": "Corolla",
      "type": "otomobil",
      "color": "beyaz",
      "year": "2020",
      "notes": "ön tampon çizik",
      "confidence": 0.91
    }
    ''';
    final v = VehicleVisionAnalyzer.parseVehicleJson(raw);
    expect(v, isNotNull);
    expect(v!.plate, '34 ABC 123');
    expect(v.brand, 'Toyota');
    expect(v.model, 'Corolla');
    expect(v.type, 'otomobil');
    expect(v.color, 'beyaz');
    expect(v.year, '2020');
    expect(v.notes, contains('çizik'));
    expect(v.confidence, closeTo(0.91, 0.001));
    expect(v.hasContent, isTrue);
    expect(v.isUncertain, isFalse);
    expect(v.displayName, contains('Toyota'));
  });

  test('fence + TR alias + düşük confidence → isUncertain', () {
    const raw = '''
```json
{"plaka":"06 XYZ 01","marka":"Ford","tur":"kamyonet","renk":"mavi","confidence":0.2}
```
''';
    final v = VehicleVisionAnalyzer.parseVehicleJson(raw);
    expect(v, isNotNull);
    expect(v!.plate, '06 XYZ 01');
    expect(v.brand, 'Ford');
    expect(v.type, 'kamyonet');
    expect(v.color, 'mavi');
    expect(v.isUncertain, isTrue);
  });

  test('year num + confidence yüzde', () {
    final v = VehicleVisionResult.fromJson({
      'plate': '01 A 01',
      'brand': 'X',
      'year': 2018,
      'confidence': 85,
    });
    expect(v.year, '2018');
    expect(v.confidence, closeTo(0.85, 0.001));
  });

  test('boş / geçersiz → null', () {
    expect(VehicleVisionAnalyzer.parseVehicleJson(''), isNull);
    expect(VehicleVisionAnalyzer.parseVehicleJson('not json'), isNull);
    expect(
      VehicleVisionAnalyzer.parseVehicleJson('{"plate":""}'),
      isA<VehicleVisionResult>(),
    );
    expect(
      VehicleVisionAnalyzer.parseVehicleJson('{"plate":""}')!.hasContent,
      isFalse,
    );
  });
}
