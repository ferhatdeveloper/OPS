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
  bool? cash;
  bool? banks;
  bool? currencies;
  bool? unitSets;
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
    expect(capture.cash, isFalse);
    expect(capture.banks, isFalse);
    expect(capture.currencies, isFalse);
    expect(capture.unitSets, isFalse);
  });

  test('kasa satırı yalnızca cash bayrağını açar', () async {
    final runner = buildRunner(
      const LogoTigerSyncResult(
        ok: true,
        cash: LogoTigerEntitySyncResult(fetched: 3, upserted: 3),
      ),
    );

    final outcome = await runner.run(LogoPullSource.cash);

    expect(capture.cash, isTrue);
    expect(capture.banks, isFalse);
    expect(capture.products, isFalse);
    expect(outcome.ok, isTrue);
    expect(outcome.upserted, 3);
  });

  test('banka satırı yalnızca banks bayrağını açar', () async {
    final runner = buildRunner(
      const LogoTigerSyncResult(
        ok: true,
        banks: LogoTigerEntitySyncResult(fetched: 2, upserted: 2),
      ),
    );

    final outcome = await runner.run(LogoPullSource.banks);

    expect(capture.banks, isTrue);
    expect(capture.cash, isFalse);
    expect(outcome.upserted, 2);
  });

  test('döviz satırı currencies bayrağını açar', () async {
    final runner = buildRunner(
      const LogoTigerSyncResult(
        ok: true,
        currencies: LogoTigerEntitySyncResult(fetched: 5, upserted: 5),
      ),
    );

    final outcome = await runner.run(LogoPullSource.currency);

    expect(capture.currencies, isTrue);
    expect(outcome.ok, isTrue);
    expect(outcome.upserted, 5);
  });

  test('döviz yerel tablo yoksa yakında olarak döner ve durum yazılmaz',
      () async {
    final stateStore = LogoPullStateStore(
      prefsFactory: SharedPreferences.getInstance,
      now: () => DateTime.utc(2026, 7, 29, 12),
    );
    final runner = buildRunner(
      const LogoTigerSyncResult(
        ok: true,
        currencies: LogoTigerEntitySyncResult(message: 'no local table'),
      ),
      stateStore: stateStore,
    );

    final outcome = await runner.run(LogoPullSource.currency);

    expect(capture.currencies, isTrue);
    expect(outcome.comingSoon, isTrue);
    expect(outcome.ok, isFalse);
    expect(outcome.errorKey, 'field_sales.logo_pull_coming_soon');
    expect(outcome.message, 'no local table');
    expect(await stateStore.loadAll(), isEmpty);
  });

  test('genel satırı ambar + plasiyer + birim seti tek çağrıda çeker',
      () async {
    final runner = buildRunner(
      const LogoTigerSyncResult(
        ok: true,
        warehouses: LogoTigerEntitySyncResult(fetched: 2, upserted: 2),
        salesmen: LogoTigerEntitySyncResult(fetched: 4, upserted: 4),
        unitSets: LogoTigerEntitySyncResult(fetched: 3, upserted: 3),
      ),
    );

    final outcome = await runner.run(LogoPullSource.general);

    expect(capture.calls, 1);
    expect(capture.warehouses, isTrue);
    expect(capture.salesmen, isTrue);
    expect(capture.unitSets, isTrue);
    expect(capture.products, isFalse);
    expect(capture.orders, isFalse);
    expect(outcome.ok, isTrue);
    expect(outcome.fetched, 9);
    expect(outcome.upserted, 9);
  });

  test('genel satırında alt kaynak mesajları birleştirilir', () async {
    final runner = buildRunner(
      const LogoTigerSyncResult(
        ok: true,
        warehouses: LogoTigerEntitySyncResult(
          message: 'locationCodes boş veya yetkisiz — ambar atlandı',
        ),
        salesmen: LogoTigerEntitySyncResult(fetched: 4, upserted: 4),
        unitSets: LogoTigerEntitySyncResult(message: 'unitSets kaynak yok'),
      ),
    );

    final outcome = await runner.run(LogoPullSource.general);

    expect(outcome.ok, isTrue);
    expect(outcome.upserted, 4);
    expect(outcome.message, contains('ambar atlandı'));
    expect(outcome.message, contains('unitSets kaynak yok'));
  });

  test('genel satırının tüm alt kaynakları boşsa yakında döner', () async {
    final runner = buildRunner(
      const LogoTigerSyncResult(
        ok: true,
        warehouses: LogoTigerEntitySyncResult(message: 'locationCodes boş'),
        salesmen: LogoTigerEntitySyncResult(message: 'salesmen kaynak yok'),
        unitSets: LogoTigerEntitySyncResult(message: 'unitSets kaynak yok'),
      ),
    );

    final outcome = await runner.run(LogoPullSource.general);

    expect(outcome.comingSoon, isTrue);
    expect(outcome.errorKey, 'field_sales.logo_pull_coming_soon');
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

  test('varyant satırı ağ çağrısı yapmadan yakında döner', () async {
    final runner = buildRunner(const LogoTigerSyncResult(ok: true));

    final outcome = await runner.run(LogoPullSource.variants);

    expect(capture.calls, 0);
    expect(outcome.comingSoon, isTrue);
    expect(outcome.errorKey, 'field_sales.logo_pull_coming_soon');
  });

  test('rota ve duyuru satırları merkez kaynak anahtarı döner', () async {
    final runner = buildRunner(const LogoTigerSyncResult(ok: true));

    for (final source in const [
      LogoPullSource.routes,
      LogoPullSource.announcements,
    ]) {
      final outcome = await runner.run(source);
      expect(outcome.comingSoon, isTrue);
      expect(outcome.errorKey, 'field_sales.logo_pull_center_source');
    }
    expect(capture.calls, 0);
  });

  test('desteklenmeyen kaynak ağ çağrısı yapmadan hata anahtarı döner',
      () async {
    final runner = buildRunner(const LogoTigerSyncResult(ok: true));

    final outcome = await runner.run(LogoPullSource.stock);

    expect(capture.calls, 0);
    expect(outcome.ok, isFalse);
    expect(outcome.comingSoon, isFalse);
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
