// Dosya Adı: logo_pull_source_runner_test.dart
// Açıklama: Tek kaynak Logo indirme koşucusu birim testleri
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exfin_ops/core/logo/logo_tiger_pull_sync.dart';
import 'package:exfin_ops/modules/field_sales/sync/model/logo_pull_source.dart';
import 'package:exfin_ops/modules/field_sales/sync/service/logo_pull_source_runner.dart';
import 'package:exfin_ops/modules/field_sales/sync/service/logo_pull_state_store.dart';

/// [_Capture]: Son çağrının bayraklarını tutar.
class _Capture {
  int calls = 0;
  bool? products;
  bool? customers;
  bool? warehouses;
  bool? orders;
  bool? salesmen;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Capture capture;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    capture = _Capture();
  });

  LogoPullSourceRunner buildRunner(
    LogoTigerSyncResult result, {
    LogoPullStateStore? stateStore,
  }) {
    return LogoPullSourceRunner(
      pullAll: ({
        bool products = true,
        bool customers = true,
        bool warehouses = true,
        bool orders = true,
        bool salesmen = true,
      }) async {
        capture.calls++;
        capture.products = products;
        capture.customers = customers;
        capture.warehouses = warehouses;
        capture.orders = orders;
        capture.salesmen = salesmen;
        return result;
      },
      stateStore: stateStore ??
          LogoPullStateStore(
            prefsFactory: SharedPreferences.getInstance,
            now: () => DateTime.utc(2026, 7, 29, 12),
          ),
    );
  }

  test('yalnızca istenen kaynağın bayrağı açılır', () async {
    final runner = buildRunner(
      const LogoTigerSyncResult(
        ok: true,
        products: LogoTigerEntitySyncResult(fetched: 9, upserted: 9),
      ),
    );

    await runner.run(LogoPullSource.products);

    expect(capture.calls, 1);
    expect(capture.products, isTrue);
    expect(capture.customers, isFalse);
    expect(capture.warehouses, isFalse);
    expect(capture.orders, isFalse);
    expect(capture.salesmen, isFalse);
  });

  test('kaynak sayaçları outcome üzerine taşınır', () async {
    final runner = buildRunner(
      const LogoTigerSyncResult(
        ok: true,
        customers: LogoTigerEntitySyncResult(fetched: 120, upserted: 118),
      ),
    );

    final outcome = await runner.run(LogoPullSource.customers);

    expect(outcome.ok, isTrue);
    expect(outcome.fetched, 120);
    expect(outcome.upserted, 118);
    expect(outcome.error, isNull);
    expect(outcome.errorKey, isNull);
  });

  test('desteklenmeyen kaynak ağ çağrısı yapmadan hata anahtarı döner',
      () async {
    final runner = buildRunner(const LogoTigerSyncResult(ok: true));

    final outcome = await runner.run(LogoPullSource.stock);

    expect(capture.calls, 0);
    expect(outcome.ok, isFalse);
    expect(outcome.errorKey, 'field_sales.logo_pull_unsupported');
  });

  test('başarılı çekim durum deposuna yazılır', () async {
    final stateStore = LogoPullStateStore(
      prefsFactory: SharedPreferences.getInstance,
      now: () => DateTime.utc(2026, 7, 29, 12),
    );
    final runner = buildRunner(
      const LogoTigerSyncResult(
        ok: true,
        salesmen: LogoTigerEntitySyncResult(fetched: 4, upserted: 4),
      ),
      stateStore: stateStore,
    );

    await runner.run(LogoPullSource.salesmen);

    final state = (await stateStore.loadAll())[LogoPullSource.salesmen];
    expect(state, isNotNull);
    expect(state!.lastOk, isTrue);
    expect(state.recordCount, 4);
    expect(state.lastSuccessAt, DateTime.utc(2026, 7, 29, 12));
  });

  test('pull hatası outcome ve durum deposuna hata olarak yansır', () async {
    final stateStore = LogoPullStateStore(
      prefsFactory: SharedPreferences.getInstance,
      now: () => DateTime.utc(2026, 7, 29, 12),
    );
    final runner = buildRunner(
      const LogoTigerSyncResult(ok: false, error: 'Oturum açılamadı'),
      stateStore: stateStore,
    );

    final outcome = await runner.run(LogoPullSource.orders);

    expect(outcome.ok, isFalse);
    expect(outcome.error, 'Oturum açılamadı');
    final state = (await stateStore.loadAll())[LogoPullSource.orders];
    expect(state!.lastOk, isFalse);
    expect(state.lastError, 'Oturum açılamadı');
  });

  test('kaynak hata sayacı varsa outcome başarısız sayılır', () async {
    final runner = buildRunner(
      const LogoTigerSyncResult(
        ok: false,
        warehouses: LogoTigerEntitySyncResult(
          fetched: 3,
          upserted: 2,
          errors: 1,
          message: 'locationCodes kısmi',
        ),
        error: 'Bazı kayıtlar atlandı/hatalı',
      ),
    );

    final outcome = await runner.run(LogoPullSource.warehouses);

    expect(outcome.ok, isFalse);
    expect(outcome.upserted, 2);
    expect(outcome.message, 'locationCodes kısmi');
  });
}
