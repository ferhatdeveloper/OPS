// Dosya Adı: tenant_dens_chip_test.dart
// Açıklama: Dashboard aktif kiracı dens chip l10n ve store testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exfin_ops/core/tenant/tenant_context.dart';
import 'package:exfin_ops/core/tenant/tenant_store.dart';
import 'package:exfin_ops/core/tenant/widgets/tenant_dens_chip.dart';

import '../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TenantStore.resetMemory();
  });

  group('TenantContext.chipLabel', () {
    test('displayName varsa onu kullanır', () {
      const ctx = TenantContext(
        tenantCode: 'lovan',
        remoteRestUrl: 'https://api.retailex.app/lovan',
        displayName: 'Lovan',
      );
      expect(ctx.chipLabel, 'Lovan');
    });

    test('displayName yoksa tenantCode kullanır', () {
      const ctx = TenantContext(
        tenantCode: 'aqua',
        remoteRestUrl: 'https://api.retailex.app/aqua',
      );
      expect(ctx.chipLabel, 'aqua');
    });
  });

  group('TenantDensChip.resolveLabel', () {
    test('boş bağlam null döner', () {
      expect(TenantDensChip.resolveLabel(null), isNull);
      expect(TenantDensChip.resolveLabel(TenantContext.empty), isNull);
    });

    test('dolu bağlam chipLabel döner', () {
      const ctx = TenantContext(
        tenantCode: 'lovan',
        remoteRestUrl: 'https://api.retailex.app/lovan',
        displayName: 'Lovan',
      );
      expect(TenantDensChip.resolveLabel(ctx), 'Lovan');
    });
  });

  group('TenantDensChip widget', () {
    testWidgets('kayıt yokken chip gizlenir', (tester) async {
      await pumpStubWithL10n(tester, const TenantDensChip());
      await tester.pumpAndSettle();

      expect(find.textContaining('Kiracı:'), findsNothing);
    });

    testWidgets('aktif kiracı metnini gösterir', (tester) async {
      await const TenantStore().save(
        const TenantContext(
          tenantCode: 'lovan',
          remoteRestUrl: 'https://api.retailex.app/lovan',
          displayName: 'Lovan',
        ),
      );

      await pumpStubWithL10n(tester, const TenantDensChip());
      await tester.pumpAndSettle();

      expect(find.text('Kiracı: Lovan'), findsOneWidget);
    });
  });
}
