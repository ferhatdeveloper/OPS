// Dosya Adı: permission_groups_screen_test.dart
// Açıklama: Yetki grupları dens ekranı smoke widget testi
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/admin_panel/permission_groups_screen.dart';
import 'package:exfin_ops/modules/admin_panel/viewmodel/permission_group_store.dart';

import '../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('liste dens — grup adı görünür', (tester) async {
    await pumpStubWithL10n(
      tester,
      PermissionGroupsScreen(
        embedded: true,
        initialGroups: const [
          PermissionGroupRecord(
            id: 'g1',
            name: 'Plasiyer Test',
            description: 'demo',
          ),
        ],
      ),
    );

    expect(find.byType(PermissionGroupsScreen), findsOneWidget);
    expect(find.text('Plasiyer Test'), findsOneWidget);
  });
}
