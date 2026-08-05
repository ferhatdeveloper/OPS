// Dosya Adı: logo_tiger_startup_pull_test.dart
// Açıklama: İlk açılış Logo Tiger otomatik pull birim testleri
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'package:exfin_ops/core/logo/logo_tiger_config.dart';
import 'package:exfin_ops/core/logo/logo_tiger_pull_sync.dart';
import 'package:exfin_ops/core/logo/logo_tiger_settings_store.dart';
import 'package:exfin_ops/core/logo/logo_tiger_startup_pull.dart';
import 'package:exfin_ops/modules/field_sales/sync/model/logo_pull_source.dart';
import 'package:exfin_ops/modules/field_sales/sync/service/logo_pull_source_runner.dart';
import 'package:exfin_ops/modules/field_sales/sync/service/logo_pull_state_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [_Capture]: pullAll çağrı bayrakları.
class _Capture {
  int calls = 0;
  bool? products;
  bool? customers;
  bool? warehouses;
  bool? orders;
  bool? salesmen;
  bool? cash;
  bool? banks;
  bool? currencies;
  bool? unitSets;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Capture capture;
  late LogoPullStateStore stateStore;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LogoTigerStartupPull.resetInFlightForTest();
    capture = _Capture();
    stateStore = LogoPullStateStore(
      prefsFactory: SharedPreferences.getInstance,
      now: () => DateTime.utc(2026, 8, 5, 12),
    );
  });

  LogoTigerPullAllFn capturePull(LogoTigerSyncResult result) {
    return ({
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
      capture.calls++;
      capture.products = products;
      capture.customers = customers;
      capture.warehouses = warehouses;
      capture.orders = orders;
      capture.salesmen = salesmen;
      capture.cash = cash;
      capture.banks = banks;
      capture.currencies = currencies;
      capture.unitSets = unitSets;
      return result;
    };
  }

  LogoTigerStartupPull build({
    required bool enabled,
    required LogoTigerConfig config,
    required LogoTigerSyncResult result,
    LogoPullStateStore? store,
  }) {
    return LogoTigerStartupPull(
      isEnabled: () async => enabled,
      loadConfig: () async => config,
      ensureDefaults: () async {},
      pullAll: capturePull(result),
      stateStore: store ?? stateStore,
    );
  }

  const readyConfig = LogoTigerConfig(
    baseUrl: 'http://logo.test/api/v1',
    apiKey: 'k',
    username: 'u',
    password: 'p',
    clientId: 'c',
    clientSecret: 's',
  );

  test('Tiger kapalıysa pull çağrılmaz', () async {
    final pull = build(
      enabled: false,
      config: readyConfig,
      result: const LogoTigerSyncResult(ok: true),
    );
    final r = await pull.runIfNeeded();
    expect(r.attempted, isFalse);
    expect(r.skipped, isTrue);
    expect(r.skipReason, LogoTigerStartupPull.skipDisabled);
    expect(capture.calls, 0);
  });

  test('kimlik eksikse pull çağrılmaz', () async {
    final pull = build(
      enabled: true,
      config: const LogoTigerConfig(baseUrl: 'http://x'),
      result: const LogoTigerSyncResult(ok: true),
    );
    final r = await pull.runIfNeeded();
    expect(r.attempted, isFalse);
    expect(r.skipReason, LogoTigerStartupPull.skipNotConfigured);
    expect(capture.calls, 0);
  });

  test('ürün+cari zaten çekildiyse tekrar full pull yok', () async {
    await stateStore.record(
      LogoPullSource.products,
      ok: true,
      recordCount: 10,
    );
    await stateStore.record(
      LogoPullSource.customers,
      ok: true,
      recordCount: 5,
    );
    final pull = build(
      enabled: true,
      config: readyConfig,
      result: const LogoTigerSyncResult(ok: true),
    );
    final r = await pull.runIfNeeded();
    expect(r.attempted, isFalse);
    expect(r.skipReason, LogoTigerStartupPull.skipAlreadySynced);
    expect(capture.calls, 0);
  });

  test('ilk açılışta gerekli master bayraklarıyla pullAll çalışır', () async {
    final pull = build(
      enabled: true,
      config: readyConfig,
      result: const LogoTigerSyncResult(
        ok: true,
        products: LogoTigerEntitySyncResult(fetched: 2, upserted: 2),
        customers: LogoTigerEntitySyncResult(fetched: 3, upserted: 3),
        warehouses: LogoTigerEntitySyncResult(fetched: 1, upserted: 1),
        salesmen: LogoTigerEntitySyncResult(fetched: 1, upserted: 1),
        cash: LogoTigerEntitySyncResult(fetched: 1, upserted: 1),
        banks: LogoTigerEntitySyncResult(fetched: 1, upserted: 1),
        unitSets: LogoTigerEntitySyncResult(fetched: 1, upserted: 1),
      ),
    );
    final r = await pull.runIfNeeded();
    expect(r.attempted, isTrue);
    expect(r.ok, isTrue);
    expect(capture.calls, 1);
    expect(capture.products, isTrue);
    expect(capture.customers, isTrue);
    expect(capture.warehouses, isTrue);
    expect(capture.salesmen, isTrue);
    expect(capture.cash, isTrue);
    expect(capture.banks, isTrue);
    expect(capture.unitSets, isTrue);
    expect(capture.orders, isFalse);
    expect(capture.currencies, isFalse);

    final states = await stateStore.loadAll();
    expect(states[LogoPullSource.products]?.lastSuccessAt, isNotNull);
    expect(states[LogoPullSource.customers]?.lastSuccessAt, isNotNull);
    expect(states[LogoPullSource.general]?.lastSuccessAt, isNotNull);
  });

  test('ağ/oturum hatası UI kırmadan ok=false döner', () async {
    final pull = build(
      enabled: true,
      config: readyConfig,
      result: const LogoTigerSyncResult(
        ok: false,
        error: 'Oturum açılamadı',
      ),
    );
    final r = await pull.runIfNeeded();
    expect(r.attempted, isTrue);
    expect(r.ok, isFalse);
    expect(r.error, contains('Oturum'));
  });

  test('eşzamanlı ikinci çağrı in_progress ile atlanır', () async {
    var release = false;
    final pull = LogoTigerStartupPull(
      isEnabled: () async => true,
      loadConfig: () async => readyConfig,
      ensureDefaults: () async {},
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
        capture.calls++;
        while (!release) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        return const LogoTigerSyncResult(ok: true);
      },
    );

    final first = pull.runIfNeeded();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final second = await pull.runIfNeeded();
    expect(second.skipReason, LogoTigerStartupPull.skipInProgress);
    release = true;
    final firstResult = await first;
    expect(firstResult.attempted, isTrue);
    expect(capture.calls, 1);
  });

  test('settings store kapalıysa gerçek store ile skip', () async {
    final store = LogoTigerSettingsStore(
      prefsFactory: SharedPreferences.getInstance,
    );
    await store.setEnabled(false);
    final pull = LogoTigerStartupPull(
      settingsStore: store,
      stateStore: stateStore,
      pullAll: capturePull(const LogoTigerSyncResult(ok: true)),
      ensureDefaults: () async {},
    );
    final r = await pull.runIfNeeded();
    expect(r.skipReason, LogoTigerStartupPull.skipDisabled);
    expect(capture.calls, 0);
  });
}
