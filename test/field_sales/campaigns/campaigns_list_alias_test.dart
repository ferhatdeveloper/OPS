// Dosya Adı: campaigns_list_alias_test.dart
// Açıklama: CampaignsListScreen → AnnouncementsScreen tek kaynak alias
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/announcements/view/announcements_screen.dart';
import 'package:exfin_ops/modules/field_sales/campaigns/view/campaigns_list_screen.dart';

import '../stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('CampaignsListScreen builds AnnouncementsScreen', (tester) async {
    await pumpStubWithL10n(tester, const CampaignsListScreen());

    expect(find.byType(AnnouncementsScreen), findsOneWidget);
    expectStubL10nSmoke(tester, 'field_sales.stubs.announcements');
    expect(CampaignsListScreen.routeName, '/field-sales/campaigns-list');
    expect(AnnouncementsScreen.routeName, '/field-sales/announcements');
  });
}
