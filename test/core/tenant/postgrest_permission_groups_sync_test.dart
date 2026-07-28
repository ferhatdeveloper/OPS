// Dosya Adı: postgrest_permission_groups_sync_test.dart
// Açıklama: Yetki PostgREST tablo adı + no-config no-op
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/tenant/postgrest_table_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('permission tablo adları firma düzeyi', () {
    expect(
      PostgrestTableNames.firmTable('1', 'permission_groups'),
      'rex_001_permission_groups',
    );
    expect(
      PostgrestTableNames.firmTable('001', 'permission_group_menus'),
      'rex_001_permission_group_menus',
    );
    expect(
      PostgrestTableNames.firmTable('001', 'permission_group_members'),
      'rex_001_permission_group_members',
    );
  });
}
