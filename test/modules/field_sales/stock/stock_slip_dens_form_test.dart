// Dosya Adı: stock_slip_dens_form_test.dart
// Açıklama: Stok dens form iskeletinde Ambar/Tarih/Satırlar görünürlüğü
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/consignment_screen.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/production_receipt_screen.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/stock_count_screen.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/stock_transfer_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/warehouse_transfer_screen.dart';
import 'package:exfin_ops/modules/field_sales/vehicle/view/vehicle_load_screen.dart';
import 'package:exfin_ops/modules/field_sales/vehicle/view/vehicle_unload_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  group('MBT stok dens form iskeleti', () {
    testWidgets('Ambar transfer: Kaynak→Hedef dens + Kaydet', (tester) async {
      await pumpStubWithL10n(tester, const WarehouseTransferScreen());
      expect(find.text('Ambar Transferi'), findsOneWidget);
      expect(find.text('Kaynak'), findsOneWidget);
      expect(find.text('Hedef'), findsOneWidget);
      expect(find.text('Ambar'), findsWidgets);
      expect(find.text('Tarih'), findsWidgets);
      expect(find.text('Satırlar'), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget);
      expect(find.text('Henüz satır eklenmedi.'), findsOneWidget);
    });

    testWidgets('Sayım fişi: Ambar, Tarih, Satırlar, Kaydet görünür',
        (tester) async {
      await pumpStubWithL10n(tester, const StockCountScreen());
      expect(find.text('Sayım Fişi'), findsOneWidget);
      expect(find.text('Ambar'), findsWidgets);
      expect(find.text('Tarih'), findsWidgets);
      expect(find.text('Satırlar'), findsOneWidget);
      expect(find.text('Henüz satır eklenmedi.'), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget);
    });

    testWidgets('Üretimden giriş: Ambar, Tarih, Satırlar, Kaydet görünür',
        (tester) async {
      await pumpStubWithL10n(tester, const ProductionReceiptScreen());
      expect(find.text('Üretimden Giriş Fişi'), findsOneWidget);
      expect(find.text('Ambar'), findsWidgets);
      expect(find.text('Tarih'), findsWidgets);
      expect(find.text('Satırlar'), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget);
    });

    testWidgets('Konsinye: Ambar, Tarih, Satırlar, Kaydet görünür',
        (tester) async {
      await pumpStubWithL10n(tester, const ConsignmentScreen());
      expect(find.text('Konsinye'), findsOneWidget);
      expect(find.text('Ambar'), findsWidgets);
      expect(find.text('Tarih'), findsWidgets);
      expect(find.text('Satırlar'), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget);
    });

    testWidgets(
        'Araç boşaltma: Kaynak→Hedef dens (Ambar, Tarih, Satırlar)',
        (tester) async {
      await pumpStubWithL10n(
        tester,
        const ProviderScope(child: VehicleUnloadScreen()),
      );
      expect(find.text('Araç Boşaltma'), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget);
      expect(find.text('Kaynak'), findsOneWidget);
      expect(find.text('Hedef'), findsOneWidget);
      expect(find.text('Ambar'), findsWidgets);
      expect(find.text('Tarih'), findsWidgets);
      expect(find.text('Satırlar'), findsOneWidget);
      expect(find.text('Henüz satır eklenmedi.'), findsOneWidget);
    });

    testWidgets('Transfer listesi: Depo/Tarih/Satırlar sütunları',
        (tester) async {
      await pumpStubWithL10n(
        tester,
        const StockTransferListScreen(
          mode: StockTransferListMode.transferred,
        ),
      );
      expect(find.text('Transfer Edilenler'), findsOneWidget);
      expect(find.text('Depo'), findsOneWidget);
      expect(find.text('Tarih'), findsOneWidget);
      expect(find.text('Satırlar'), findsOneWidget);
      expect(find.textContaining('STK-T-'), findsWidgets);
    });

    testWidgets('Araç yükleme: Kaynak→Hedef dens alanlar görünür',
        (tester) async {
      await pumpStubWithL10n(
        tester,
        const ProviderScope(child: VehicleLoadScreen()),
      );
      expect(find.text('Araç Yükleme'), findsOneWidget);
      expect(find.text('Kaynak'), findsOneWidget);
      expect(find.text('Hedef'), findsOneWidget);
      expect(find.text('Ambar'), findsWidgets);
      expect(find.text('Tarih'), findsWidgets);
      expect(find.text('Satırlar'), findsOneWidget);
      expect(find.text('Henüz satır eklenmedi.'), findsOneWidget);
    });
  });
}
