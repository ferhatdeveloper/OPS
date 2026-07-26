// Dosya Adı: translation_json_parse_test.dart
// Açıklama: tr.json ve en.json dosyalarının geçerli JSON olduğunu doğrular
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Translation JSON parse', () {
    test('tr.json geçerli JSON ve Map olarak parse edilir', () {
      final file = File('assets/translations/tr.json');
      expect(file.existsSync(), isTrue, reason: 'tr.json bulunamadı');

      final decoded = jsonDecode(file.readAsStringSync());
      expect(decoded, isA<Map<String, dynamic>>());
      expect((decoded as Map).isNotEmpty, isTrue);
    });

    test('en.json geçerli JSON ve Map olarak parse edilir', () {
      final file = File('assets/translations/en.json');
      expect(file.existsSync(), isTrue, reason: 'en.json bulunamadı');

      final decoded = jsonDecode(file.readAsStringSync());
      expect(decoded, isA<Map<String, dynamic>>());
      expect((decoded as Map).isNotEmpty, isTrue);
    });
  });
}
