// Dosya Adı: vehicle_card_store_test.dart
// Açıklama: Araç arama filtresi birim testi
// Oluşturulma Tarihi: 2026-08-04
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-04

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/vehicles/model/vehicle_model.dart';
import 'package:exfin_ops/modules/field_sales/vehicles/viewmodel/vehicle_card_store.dart';

void main() {
  group('filterVehiclesByQuery', () {
    final vehicles = [
      VehicleModel(id: '1', plate: '34 ABC 123', name: 'Ford Transit'),
      VehicleModel(id: '2', plate: '06 XYZ 99', name: 'Renault Kangoo'),
      VehicleModel(id: '3', plate: '35 DEF 01', name: null),
    ];

    test('boş sorgu tüm listeyi döner', () {
      final result = filterVehiclesByQuery(vehicles, '');
      expect(result, hasLength(3));
    });

    test('plaka ile filtreler', () {
      final result = filterVehiclesByQuery(vehicles, '34 abc');
      expect(result, hasLength(1));
      expect(result.first.plate, '34 ABC 123');
    });

    test('ad ile filtreler', () {
      final result = filterVehiclesByQuery(vehicles, 'kangoo');
      expect(result, hasLength(1));
      expect(result.first.id, '2');
    });

    test('eşleşmeyen sorgu boş döner', () {
      final result = filterVehiclesByQuery(vehicles, 'zzz');
      expect(result, isEmpty);
    });
  });
}
