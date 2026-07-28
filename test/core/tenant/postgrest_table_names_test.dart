// Dosya Adı: postgrest_table_names_test.dart
// Açıklama: rex_FF / rex_FF_DD tablo adı birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/tenant/postgrest_table_names.dart';

void main() {
  group('PostgrestTableNames', () {
    test('padFirm 3 hane', () {
      expect(PostgrestTableNames.padFirm('1'), '001');
      expect(PostgrestTableNames.padFirm('001'), '001');
      expect(PostgrestTableNames.padFirm('02'), '002');
    });

    test('padPeriod 2 hane', () {
      expect(PostgrestTableNames.padPeriod('1'), '01');
      expect(PostgrestTableNames.padPeriod('01'), '01');
    });

    test('firmTable rex_001_customers', () {
      expect(
        PostgrestTableNames.firmTable('001', 'customers'),
        'rex_001_customers',
      );
    });

    test('periodTable rex_001_01_sales', () {
      expect(
        PostgrestTableNames.periodTable('1', '1', 'sales'),
        'rex_001_01_sales',
      );
    });
  });
}
