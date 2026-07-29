// Dosya Adı: logo_tiger_pull_sync_test.dart
// Açıklama: Logo Tiger pull sync kasa/banka/döviz/birim set upsert testleri
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/core/logo/logo_tiger_config.dart';
import 'package:exfin_ops/core/logo/logo_tiger_pull_sync.dart';
import 'package:exfin_ops/core/logo/logo_tiger_rest_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test için sabit satır dönen Tiger istemcisi.
class _FakeTigerClient extends LogoTigerRestClient {
  _FakeTigerClient({
    this.cashRows = const [],
    this.bankRows = const [],
    this.currencyRows = const [],
    this.unitSetRows = const [],
  }) : super(config: const LogoTigerConfig(baseUrl: 'http://logo.test'));

  final List<Map<String, dynamic>> cashRows;
  final List<Map<String, dynamic>> bankRows;
  final List<Map<String, dynamic>> currencyRows;
  final List<Map<String, dynamic>> unitSetRows;

  @override
  Future<LogoTigerResult> ensureSession() async =>
      LogoTigerResult.ok({'session': true});

  @override
  Future<List<Map<String, dynamic>>> fetchCash({int maxPages = 50}) async =>
      cashRows;

  @override
  Future<List<Map<String, dynamic>>> fetchBanks({int maxPages = 50}) async =>
      bankRows;

  @override
  Future<List<Map<String, dynamic>>> fetchCurrencies({
    int maxPages = 50,
  }) async =>
      currencyRows;

  @override
  Future<List<Map<String, dynamic>>> fetchUnitSets({
    int maxPages = 50,
  }) async =>
      unitSetRows;

  @override
  Future<List<Map<String, dynamic>>> fetchItems({int maxPages = 200}) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> fetchArps({int maxPages = 200}) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> fetchLocationCodes({
    int maxPages = 50,
  }) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> fetchSalesOrders({
    int maxPages = 100,
  }) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> fetchSalesmen({
    int maxPages = 100,
  }) async =>
      const [];
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LogoTigerPullSync cash/banks/currencies/unitSets', () {
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.execute(SqlQuerys.createCashCardsTable);
      await db.execute(SqlQuerys.createBankCardsTable);
      await db.execute(SqlQuerys.createUnitSetsTable);
      await db.execute(SqlQuerys.createUnitSetLinesTable);
    });

    tearDown(() async {
      await db.close();
    });

    test('cash=true → cash_cards upsert sayısı', () async {
      final sync = LogoTigerPullSync(
        client: _FakeTigerClient(
          cashRows: [
            {'CODE': 'K01', 'NAME': 'Merkez Kasa'},
            {'CODE': 'K02', 'DEFINITION_': 'Şube Kasa'},
          ],
        ),
        dbFactory: () async => db,
      );

      final r = await sync.pullAll(
        products: false,
        customers: false,
        warehouses: false,
        orders: false,
        salesmen: false,
        cash: true,
      );

      expect(r.ok, isTrue);
      expect(r.cash.fetched, 2);
      expect(r.cash.upserted, 2);
      expect(r.cash.errors, 0);

      final rows = await db.query('cash_cards', orderBy: 'code');
      expect(rows, hasLength(2));
      expect(rows.first['code'], 'K01');
      expect(rows.first['name'], 'Merkez Kasa');
      expect(rows.first['name_key'], isNotEmpty);
      expect(rows.first['is_synced'], 1);
    });

    test('banks=true → bank_cards upsert sayısı', () async {
      final sync = LogoTigerPullSync(
        client: _FakeTigerClient(
          bankRows: [
            {
              'CODE': 'B01',
              'NAME': 'Ziraat TL',
              'BALANCE': 100.5,
            },
          ],
        ),
        dbFactory: () async => db,
      );

      final r = await sync.pullAll(
        products: false,
        customers: false,
        warehouses: false,
        orders: false,
        salesmen: false,
        banks: true,
      );

      expect(r.banks.fetched, 1);
      expect(r.banks.upserted, 1);
      final rows = await db.query('bank_cards');
      expect(rows.single['code'], 'B01');
      expect(rows.single['name'], 'Ziraat TL');
      expect(rows.single['balance_tl'], 100.5);
    });

    test('currencies=true → no local table mesajı, hata yok', () async {
      final sync = LogoTigerPullSync(
        client: _FakeTigerClient(
          currencyRows: [
            {'CODE': 'USD', 'NAME': 'US Dollar'},
          ],
        ),
        dbFactory: () async => db,
      );

      final r = await sync.pullAll(
        products: false,
        customers: false,
        warehouses: false,
        orders: false,
        salesmen: false,
        currencies: true,
      );

      expect(r.ok, isTrue);
      expect(r.currencies.fetched, 0);
      expect(r.currencies.upserted, 0);
      expect(r.currencies.errors, 0);
      expect(r.currencies.message, 'no local table');
    });

    test('unitSets=true → unit_sets + unit_set_lines upsert', () async {
      final sync = LogoTigerPullSync(
        client: _FakeTigerClient(
          unitSetRows: [
            {
              'CODE': '05',
              'DESCRIPTION': 'ADET SET',
              'UNITS': {
                'items': [
                  {
                    'UNIT_CODE': 'AD',
                    'CONV_FACT': 1,
                    'MAIN_UNIT': 1,
                  },
                  {
                    'UNIT_CODE': 'KL',
                    'CONV_FACT': 12,
                    'MAIN_UNIT': 0,
                  },
                ],
              },
            },
          ],
        ),
        dbFactory: () async => db,
      );

      final r = await sync.pullAll(
        products: false,
        customers: false,
        warehouses: false,
        orders: false,
        salesmen: false,
        unitSets: true,
      );

      expect(r.unitSets.fetched, 1);
      expect(r.unitSets.upserted, 1);
      final sets = await db.query('unit_sets');
      expect(sets.single['id'], '05');
      expect(sets.single['name'], 'ADET SET');
      final lines = await db.query('unit_set_lines', orderBy: 'unit_name');
      expect(lines, hasLength(2));
      expect(lines.first['unit_name'], 'AD');
      expect(lines.first['conversion_factor'], 1);
      expect(lines.first['is_main_unit'], 1);
    });

    test('boş cash adayları → 0 kayıt, pull düşmez', () async {
      final sync = LogoTigerPullSync(
        client: _FakeTigerClient(),
        dbFactory: () async => db,
      );

      final r = await sync.pullAll(
        products: false,
        customers: false,
        warehouses: false,
        orders: false,
        salesmen: false,
        cash: true,
        banks: true,
      );

      expect(r.ok, isTrue);
      expect(r.cash.fetched, 0);
      expect(r.cash.errors, 0);
      expect(r.banks.fetched, 0);
      expect(r.banks.errors, 0);
    });
  });
}
