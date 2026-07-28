// Dosya Adı: menu_title_l10n_resolve_test.dart
// Açıklama: SQLite menü title (field_sales.menu.* / fs_*) → UI metin çözümü
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/localization/app_localization.dart';
import 'package:exfin_ops/modules/field_sales/shared/model/field_sales_menu_l10n.dart';
import 'package:exfin_ops/service/menu_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalization l10n;

  setUpAll(() async {
    l10n = await AppLocalization.resolve();
  });

  group('FieldSalesMenuL10n seed keys', () {
    test('fs_invoice → field_sales.menu.fs_invoice', () {
      expect(
        FieldSalesMenuL10n.titleForSeed('fs_invoice', 'Fatura'),
        'field_sales.menu.fs_invoice',
      );
    });

    test('fs_other override → dashboard.diger', () {
      expect(
        FieldSalesMenuL10n.titleForSeed('fs_other', 'Diğer'),
        'dashboard.diger',
      );
    });

    test('bare fs_* current title migrates to dotted key', () {
      expect(
        FieldSalesMenuL10n.storedTitleForUuid(
          uuid: 'fs_admin',
          currentTitle: 'fs_admin',
        ),
        'field_sales.menu.fs_admin',
      );
    });
  });

  group('MenuService.resolveStoredMenuTitle', () {
    test('dotted field_sales.menu key resolves (not last segment)', () {
      final resolved = MenuService.resolveStoredMenuTitle(
        'field_sales.menu.fs_invoice',
        l10n: l10n,
      );
      expect(resolved, 'Fatura');
      expect(resolved, isNot('fs_invoice'));
    });

    test('bare fs_* uuid title resolves via field_sales.menu', () {
      expect(
        MenuService.resolveStoredMenuTitle('fs_customers', l10n: l10n),
        'Cari',
      );
      expect(
        MenuService.resolveStoredMenuTitle('fs_admin', l10n: l10n),
        'Yönetici',
      );
    });

    test('override dashboard.diger resolves to Diğer', () {
      expect(
        MenuService.resolveStoredMenuTitle('dashboard.diger', l10n: l10n),
        'Diğer',
      );
    });

    test('without l10n still resolves via AppLocalization.instance', () {
      // instance set by setUpAll resolve()
      final resolved = MenuService.resolveStoredMenuTitle(
        'field_sales.menu.fs_order',
      );
      expect(resolved, 'Sipariş');
    });

    test('legacy Turkish human title unchanged', () {
      expect(
        MenuService.resolveStoredMenuTitle('Sipariş', l10n: l10n),
        'Sipariş',
      );
    });
  });
}
