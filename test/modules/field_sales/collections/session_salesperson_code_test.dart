// Dosya Adı: session_salesperson_code_test.dart
// Açıklama: Oturumdan plasiyer kodu çözümleyici birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/session_salesperson_code.dart';

void main() {
  group('resolveSalespersonCodeFromSession', () {
    test('null / boş oturumda null döner', () {
      expect(resolveSalespersonCodeFromSession(null), isNull);
      expect(resolveSalespersonCodeFromSession({}), isNull);
    });

    test('logo_salesman_code username\'den önce gelir', () {
      expect(
        resolveSalespersonCodeFromSession({
          'logo_salesman_code': 'PLS01',
          'username': 'ferhat',
        }),
        'PLS01',
      );
    });

    test('kullanıcı kodu (username) ile ön-doldurur', () {
      expect(
        resolveSalespersonCodeFromSession({
          'id': 'u-1',
          'username': 'demo',
          'full_name': 'Demo User',
        }),
        'demo',
      );
    });

    test('boşluklu değerler atlanır', () {
      expect(
        resolveSalespersonCodeFromSession({
          'logo_salesman_code': '  ',
          'username': '  PLS02  ',
        }),
        'PLS02',
      );
    });

    test('hiçbir aday yoksa null', () {
      expect(
        resolveSalespersonCodeFromSession({
          'id': 'u-1',
          'full_name': 'Demo User',
          'role': 'salesman',
        }),
        isNull,
      );
    });
  });
}
