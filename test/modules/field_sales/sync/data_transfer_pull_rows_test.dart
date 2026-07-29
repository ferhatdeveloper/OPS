// Dosya Adı: data_transfer_pull_rows_test.dart
// Açıklama: Güncelleme ekranı kaynak bazlı indirme satırları widget testleri
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exfin_ops/core/logo/logo_connection_health.dart';
import 'package:exfin_ops/core/logo/logo_tiger_pull_sync.dart';
import 'package:exfin_ops/modules/field_sales/sync/service/logo_pull_source_runner.dart';
import 'package:exfin_ops/modules/field_sales/sync/service/logo_pull_state_store.dart';
import 'package:exfin_ops/modules/field_sales/sync/view/data_transfer_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> pulled;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    pulled = <String>[];
  });

  LogoPullStateStore buildStateStore() {
    return LogoPullStateStore(
      prefsFactory: SharedPreferences.getInstance,
      now: () => DateTime.utc(2026, 7, 29, 10),
    );
  }

  LogoConnectionHealthChecker buildChecker() {
    return LogoConnectionHealthChecker(
      probe: () async => LogoHealthProbeResult.online(detail: 'HTTP 200'),
    );
  }

  /// [buildRunner]: Hangi kaynağın istendiğini kaydeden sahte koşucu.
  LogoPullSourceRunner buildRunner(
    LogoPullStateStore stateStore, {
    LogoTigerSyncResult? result,
  }) {
    return LogoPullSourceRunner(
      stateStore: stateStore,
      pullAll: ({
        bool products = true,
        bool customers = true,
        bool warehouses = true,
        bool orders = true,
        bool salesmen = true,
        bool cash = false,
        bool banks = false,
        bool currencies = false,
        bool unitSets = false,
      }) async {
        if (products) pulled.add('products');
        if (customers) pulled.add('customers');
        if (cash) pulled.add('cash');
        if (banks) pulled.add('banks');
        if (currencies) pulled.add('currencies');
        if (warehouses) pulled.add('warehouses');
        if (salesmen) pulled.add('salesmen');
        if (unitSets) pulled.add('unitSets');
        if (orders) pulled.add('orders');
        return result ??
            const LogoTigerSyncResult(
              ok: true,
              products: LogoTigerEntitySyncResult(fetched: 3, upserted: 3),
              customers: LogoTigerEntitySyncResult(fetched: 5, upserted: 5),
              cash: LogoTigerEntitySyncResult(fetched: 2, upserted: 2),
              banks: LogoTigerEntitySyncResult(fetched: 1, upserted: 1),
              // Yerel kur tablosu yok — gerçek pull davranışı
              currencies: LogoTigerEntitySyncResult(message: 'no local table'),
              warehouses: LogoTigerEntitySyncResult(fetched: 2, upserted: 2),
              salesmen: LogoTigerEntitySyncResult(fetched: 4, upserted: 4),
              unitSets: LogoTigerEntitySyncResult(fetched: 3, upserted: 3),
              orders: LogoTigerEntitySyncResult(fetched: 1, upserted: 1),
            );
      },
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required bool tigerEnabled,
    LogoTigerSyncResult? result,
  }) async {
    // Tüm satırlar tek ekranda görünsün (ListView lazy build sınırı)
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final stateStore = buildStateStore();
    await tester.pumpWidget(
      MaterialApp(
        home: DataTransferScreen(
          tigerEnabledOverride: tigerEnabled,
          pullStateStore: stateStore,
          pullRunner: buildRunner(stateStore, result: result),
          healthChecker: buildChecker(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// [rowIconOf]: Belirli satır başlığına ait indirme ikonu bulucusu.
  Finder rowIconOf(String titleKey) {
    return find.descendant(
      of: find.ancestor(
        of: find.text(titleKey),
        matching: find.byType(ListTile),
      ),
      matching: find.byIcon(Icons.cloud_download_outlined),
    );
  }

  testWidgets('Tiger modunda MBT dokuz alınacak satırı listelenir',
      (tester) async {
    await pumpScreen(tester, tigerEnabled: true);

    for (final key in const [
      'field_sales.logo_pull_mbt_stock',
      'field_sales.logo_pull_mbt_customers',
      'field_sales.logo_pull_mbt_cash',
      'field_sales.logo_pull_mbt_banks',
      'field_sales.logo_pull_mbt_currency',
      'field_sales.logo_pull_mbt_general',
      'field_sales.logo_pull_mbt_variants',
      'field_sales.logo_pull_mbt_routes',
      'field_sales.logo_pull_mbt_announcements',
    ]) {
      expect(find.text(key), findsOneWidget, reason: '$key satırı yok');
    }
    expect(find.text('field_sales.logo_pull_never'), findsNWidgets(9));
    expect(find.text('field_sales.logo_pull_orders'), findsNothing);
  });

  testWidgets('kaynağı bağlanmamış satırlar Bekliyor yerine bilgi gösterir',
      (tester) async {
    await pumpScreen(tester, tigerEnabled: true);

    // Varyant → yakında, rota + duyurular → merkez kaynaklı
    expect(find.text('field_sales.logo_pull_coming_soon'), findsOneWidget);
    expect(find.text('field_sales.logo_pull_center_source'), findsNWidgets(2));
    // Çekilebilir satırlar Bekliyor durumunda kalır
    expect(
      find.textContaining('field_sales.status_pending'),
      findsNWidgets(6),
    );
  });

  testWidgets('ExfinApi modunda middleware kaynakları eski başlıkla listelenir',
      (tester) async {
    await pumpScreen(tester, tigerEnabled: false);

    expect(find.text('field_sales.customer_list'), findsOneWidget);
    expect(find.text('field_sales.product_list'), findsOneWidget);
    expect(find.text('field_sales.stock'), findsOneWidget);
    expect(find.text('field_sales.balance'), findsOneWidget);
    expect(find.text('field_sales.logo_pull_mbt_cash'), findsNothing);
    expect(find.text('field_sales.logo_pull_mbt_general'), findsNothing);
  });

  testWidgets('her satır kendi indir düğmesine sahiptir', (tester) async {
    await pumpScreen(tester, tigerEnabled: true);

    expect(find.byIcon(Icons.cloud_download_outlined), findsNWidgets(9));
  });

  testWidgets('tek satır indirme yalnızca o kaynağı çeker', (tester) async {
    await pumpScreen(tester, tigerEnabled: true);

    await tester.tap(rowIconOf('field_sales.logo_pull_mbt_stock'));
    await tester.pumpAndSettle();

    expect(pulled, ['products']);
    expect(find.textContaining('field_sales.status_completed'), findsOneWidget);
    expect(find.textContaining('field_sales.logo_pull_last_update'),
        findsOneWidget);
  });

  testWidgets('genel satırı ambar + plasiyer + birim seti birlikte çeker',
      (tester) async {
    await pumpScreen(tester, tigerEnabled: true);

    await tester.tap(rowIconOf('field_sales.logo_pull_mbt_general'));
    await tester.pumpAndSettle();

    expect(pulled, ['warehouses', 'salesmen', 'unitSets']);
    // 2 + 4 + 3 = 9 kayıt tek satırda toplanır
    expect(
      find.textContaining('field_sales.logo_pull_record_count'),
      findsOneWidget,
    );
  });

  testWidgets('döviz satırı yerel tablo yoksa yakında olarak işaretlenir',
      (tester) async {
    await pumpScreen(tester, tigerEnabled: true);

    await tester.tap(rowIconOf('field_sales.logo_pull_mbt_currency'));
    await tester.pumpAndSettle();

    expect(pulled, ['currencies']);
    // Varyant satırı + döviz satırı
    expect(find.text('field_sales.logo_pull_coming_soon'), findsNWidgets(2));
    expect(find.textContaining('field_sales.status_completed'), findsNothing);
  });

  testWidgets('yakında satırına dokunmak indirme yapmaz, bilgi mesajı verir',
      (tester) async {
    await pumpScreen(tester, tigerEnabled: true);

    await tester.tap(rowIconOf('field_sales.logo_pull_mbt_routes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(pulled, isEmpty);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('field_sales.logo_pull_center_source'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('toplu Al desteklenen kaynakları çeker ve ilerlemeyi tamamlar',
      (tester) async {
    await pumpScreen(tester, tigerEnabled: true);

    await tester.tap(find.text('field_sales.receive_from_server'));
    await tester.pumpAndSettle();

    expect(pulled, [
      'products',
      'customers',
      'cash',
      'banks',
      'currencies',
      'warehouses',
      'salesmen',
      'unitSets',
    ]);
    // Stok, cari, kasa, banka, genel tamamlanır
    expect(
      find.textContaining('field_sales.status_completed'),
      findsNWidgets(5),
    );
    // Döviz + varyant yakında, rota + duyurular merkez kaynaklı
    expect(find.text('field_sales.logo_pull_coming_soon'), findsNWidgets(2));
    expect(find.text('field_sales.logo_pull_center_source'), findsNWidgets(2));
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('bağlantı göstergesi yeşil bulut ikonu ile gösterilir',
      (tester) async {
    await pumpScreen(tester, tigerEnabled: true);

    expect(find.byIcon(Icons.cloud_done), findsOneWidget);
  });

  testWidgets('pull hatası genel alanda ve ilgili satırda gösterilir',
      (tester) async {
    await pumpScreen(
      tester,
      tigerEnabled: true,
      result: const LogoTigerSyncResult(
        ok: false,
        error: 'username, password ve client_id gerekli',
      ),
    );

    await tester.tap(rowIconOf('field_sales.logo_pull_mbt_stock'));
    await tester.pumpAndSettle();

    expect(
      find.text('username, password ve client_id gerekli'),
      findsNWidgets(2),
    );
  });
}
