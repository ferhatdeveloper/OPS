// Dosya Adı: warehouse_list_screen_test.dart
// Açıklama: Ambar listesi route ve dens chip tıklama smoke testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/companies/view/company_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/active_warehouse_session.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/warehouse_list_row.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/warehouse_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/stock/viewmodel/active_warehouse_store.dart';
import 'package:exfin_ops/modules/field_sales/stock/widgets/active_warehouse_dens_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ActiveWarehouseStore.resetMemory();
  });

  group('WarehouseListScreen', () {
    test('routeName dens path', () {
      expect(WarehouseListScreen.routeName, '/field-sales/warehouses');
    });

    test('WarehouseListRow label kod · ad', () {
      const row = WarehouseListRow(
        code: 'ARC',
        name: 'Araç Depo',
        type: 'vehicle',
      );
      expect(row.label, 'ARC · Araç Depo');
    });

    testWidgets('route wrapper Depo sekmeli CompanyListScreen açar',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: WarehouseListScreen()),
      );
      await tester.pump();
      expect(find.byType(CompanyListScreen), findsOneWidget);
      final screen = tester.widget<CompanyListScreen>(
        find.byType(CompanyListScreen),
      );
      expect(screen.initialTab, CompanyContextTab.warehouses);
    });
  });

  group('ActiveWarehouseDensChip.resolveLabel', () {
    test('boş oturum null', () {
      expect(ActiveWarehouseDensChip.resolveLabel(null), isNull);
      expect(
        ActiveWarehouseDensChip.resolveLabel(ActiveWarehouseSession.empty),
        isNull,
      );
    });

    test('dolu oturum label', () {
      expect(
        ActiveWarehouseDensChip.resolveLabel(
          const ActiveWarehouseSession(
            code: 'ARC',
            name: 'Araç Depo',
          ),
        ),
        'ARC · Araç Depo',
      );
    });
  });

  group('ActiveWarehouseDensChip widget', () {
    testWidgets('tıklanınca birleşik bağlam Depo sekmesine gider',
        (tester) async {
      await const ActiveWarehouseStore().save(
        const ActiveWarehouseSession(
          code: 'ST_01',
          name: 'Merkez Depo',
          type: 'center',
        ),
      );

      await pumpStubWithL10n(tester, const ActiveWarehouseDensChip());
      await tester.pumpAndSettle();

      expect(find.textContaining('ST_01 · Merkez Depo'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      await tester.tap(find.byKey(ActiveWarehouseDensChip.tapKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CompanyListScreen), findsOneWidget);
      final screen = tester.widget<CompanyListScreen>(
        find.byType(CompanyListScreen),
      );
      expect(screen.initialTab, CompanyContextTab.warehouses);
    });
  });
}
