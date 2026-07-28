// Dosya Adı: login_tenant_code_chip_test.dart
// Açıklama: LoginTenantChipData görünürlük + birleşik dens chip widget
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/view/widgets/login_tenant_code_chip.dart';

import '../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  group('LoginTenantChipData', () {
    test('kayıtlı değilken header butonu gizli', () {
      const data = LoginTenantChipData(
        loadDone: true,
        gatePassed: false,
        tenantCode: '',
      );
      expect(data.visible, isFalse);
    });

    test('kayıtlı/bağlı iken header butonu görünür', () {
      const data = LoginTenantChipData(
        loadDone: true,
        gatePassed: true,
        tenantCode: 'lovan',
      );
      expect(data.visible, isTrue);
      expect(data.shortCode, 'lovan');
    });

    test('yükleme bitmeden görünmez', () {
      const data = LoginTenantChipData(
        loadDone: false,
        gatePassed: true,
        tenantCode: 'lovan',
      );
      expect(data.visible, isFalse);
    });

    test('uzun kod max 8 (7 + …)', () {
      const data = LoginTenantChipData(
        loadDone: true,
        gatePassed: true,
        tenantCode: 'verylongtenant',
      );
      expect(data.shortCode, 'verylon…');
      expect(data.shortCode.length, 8);
    });

    test('copyWith gatePassed günceller', () {
      const base = LoginTenantChipData(loadDone: true);
      final next = base.copyWith(gatePassed: true, tenantCode: 'aqua');
      expect(next.visible, isTrue);
      expect(next.tenantCode, 'aqua');
      expect(next.shortCode, 'aqua');
    });
  });

  group('LoginTenantCodeChip widget', () {
    testWidgets('ikon + metin tek InkWell hit target', (tester) async {
      var taps = 0;
      await pumpStubWithL10n(
        tester,
        Scaffold(
          body: LoginTenantCodeChip(
            tenantCode: 'lovan',
            onPressed: () => taps++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(LoginTenantCodeChip.tapKey), findsOneWidget);
      expect(find.byIcon(Icons.apartment), findsOneWidget);
      expect(find.text('T: lovan'), findsOneWidget);

      final ink = tester.widget<InkWell>(
        find.byKey(LoginTenantCodeChip.tapKey),
      );
      expect(ink.onTap, isNotNull);

      // İkon veya metne ayrı tıklansa da aynı callback (tek kontrol)
      await tester.tap(find.byIcon(Icons.apartment));
      await tester.pump();
      expect(taps, 1);

      await tester.tap(find.text('T: lovan'));
      await tester.pump();
      expect(taps, 2);
    });

    testWidgets('tonal Container dekorasyonu birleşik chip', (tester) async {
      await pumpStubWithL10n(
        tester,
        const Scaffold(
          body: LoginTenantCodeChip(tenantCode: 'lovan'),
        ),
      );
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(LoginTenantCodeChip.tapKey),
              matching: find.byType(Container),
            )
            .first,
      );
      final deco = container.decoration! as BoxDecoration;
      expect(deco.borderRadius, isNotNull);
      expect(deco.color, isNotNull);
      expect(deco.border, isNotNull);
    });
  });
}
