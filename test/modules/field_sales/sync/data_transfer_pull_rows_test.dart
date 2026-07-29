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
  LogoPullSourceRunner buildRunner(LogoPullStateStore stateStore) {
    return LogoPullSourceRunner(
      stateStore: stateStore,
      pullAll: ({
        bool products = true,
        bool customers = true,
        bool warehouses = true,
        bool orders = true,
        bool salesmen = true,
      }) async {
        if (products) pulled.add('products');
        if (customers) pulled.add('customers');
        if (warehouses) pulled.add('warehouses');
        if (orders) pulled.add('orders');
        if (salesmen) pulled.add('salesmen');
        return const LogoTigerSyncResult(
          ok: true,
          products: LogoTigerEntitySyncResult(fetched: 3, upserted: 3),
          customers: LogoTigerEntitySyncResult(fetched: 5, upserted: 5),
          warehouses: LogoTigerEntitySyncResult(fetched: 2, upserted: 2),
          orders: LogoTigerEntitySyncResult(fetched: 1, upserted: 1),
          salesmen: LogoTigerEntitySyncResult(fetched: 4, upserted: 4),
        );
      },
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required bool tigerEnabled,
  }) async {
    // Tüm satırlar tek ekranda görünsün (ListView lazy build sınırı)
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final stateStore = buildStateStore();
    await tester.pumpWidget(
      MaterialApp(
        home: DataTransferScreen(
          tigerEnabledOverride: tigerEnabled,
          pullStateStore: stateStore,
          pullRunner: buildRunner(stateStore),
          healthChecker: buildChecker(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Tiger modunda her Logo veri türü ayrı satır olur',
      (tester) async {
    await pumpScreen(tester, tigerEnabled: true);

    expect(find.text('field_sales.customer_list'), findsOneWidget);
    expect(find.text('field_sales.product_list'), findsOneWidget);
    expect(find.text('field_sales.logo_pull_warehouses'), findsOneWidget);
    expect(find.text('field_sales.logo_pull_salesmen'), findsOneWidget);
    expect(find.text('field_sales.logo_pull_orders'), findsOneWidget);
    expect(find.text('field_sales.logo_pull_never'), findsNWidgets(5));
  });

  testWidgets('ExfinApi modunda middleware kaynakları listelenir',
      (tester) async {
    await pumpScreen(tester, tigerEnabled: false);

    expect(find.text('field_sales.customer_list'), findsOneWidget);
    expect(find.text('field_sales.product_list'), findsOneWidget);
    expect(find.text('field_sales.stock'), findsOneWidget);
    expect(find.text('field_sales.balance'), findsOneWidget);
    expect(find.text('field_sales.logo_pull_salesmen'), findsNothing);
  });

  testWidgets('her satır kendi indir düğmesine sahiptir', (tester) async {
    await pumpScreen(tester, tigerEnabled: true);

    expect(find.byIcon(Icons.cloud_download_outlined), findsNWidgets(5));
  });

  testWidgets('tek satır indirme yalnızca o kaynağı çeker', (tester) async {
    await pumpScreen(tester, tigerEnabled: true);

    await tester.tap(find.byIcon(Icons.cloud_download_outlined).first);
    await tester.pumpAndSettle();

    expect(pulled, ['customers']);
    expect(find.textContaining('field_sales.status_completed'), findsOneWidget);
    expect(find.textContaining('field_sales.logo_pull_last_update'),
        findsOneWidget);
  });

  testWidgets('toplu Al tüm kaynakları çeker ve ilerlemeyi tamamlar',
      (tester) async {
    await pumpScreen(tester, tigerEnabled: true);

    await tester.tap(find.text('field_sales.receive_from_server'));
    await tester.pumpAndSettle();

    expect(pulled, ['customers', 'products', 'warehouses', 'salesmen', 'orders']);
    expect(
      find.textContaining('field_sales.status_completed'),
      findsNWidgets(5),
    );
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('bağlantı göstergesi yeşil bulut ikonu ile gösterilir',
      (tester) async {
    await pumpScreen(tester, tigerEnabled: true);

    expect(find.byIcon(Icons.cloud_done), findsOneWidget);
  });
}
