// Dosya Adı: logo_pull_state_store_test.dart
// Açıklama: Kaynak bazlı Logo indirme durumu deposu birim testleri
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exfin_ops/modules/field_sales/sync/model/logo_pull_source.dart';
import 'package:exfin_ops/modules/field_sales/sync/service/logo_pull_state_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  LogoPullStateStore buildStore({DateTime? now}) {
    return LogoPullStateStore(
      prefsFactory: SharedPreferences.getInstance,
      now: now == null ? null : () => now,
    );
  }

  test('kayıt yoksa boş harita döner', () async {
    final store = buildStore();
    expect(await store.loadAll(), isEmpty);
  });

  test('başarılı kayıt zaman ve adet ile saklanır', () async {
    final store = buildStore(now: DateTime.utc(2026, 7, 29, 10, 30));
    await store.record(
      LogoPullSource.customers,
      ok: true,
      recordCount: 128,
    );

    final all = await store.loadAll();
    final state = all[LogoPullSource.customers];
    expect(state, isNotNull);
    expect(state!.lastOk, isTrue);
    expect(state.recordCount, 128);
    expect(state.lastSuccessAt, DateTime.utc(2026, 7, 29, 10, 30));
    expect(state.lastError, isNull);
  });

  test('hata kaydı önceki başarılı zaman ve adedi korur', () async {
    final store = buildStore(now: DateTime.utc(2026, 7, 29, 10));
    await store.record(LogoPullSource.products, ok: true, recordCount: 42);

    final later = buildStore(now: DateTime.utc(2026, 7, 29, 11));
    await later.record(
      LogoPullSource.products,
      ok: false,
      error: 'HTTP 401',
    );

    final state = (await later.loadAll())[LogoPullSource.products];
    expect(state!.lastOk, isFalse);
    expect(state.lastError, 'HTTP 401');
    expect(state.recordCount, 42);
    expect(state.lastSuccessAt, DateTime.utc(2026, 7, 29, 10));
  });

  test('farklı kaynaklar birbirini ezmez', () async {
    final store = buildStore(now: DateTime.utc(2026, 7, 29, 9));
    await store.record(LogoPullSource.customers, ok: true, recordCount: 5);
    await store.record(LogoPullSource.orders, ok: true, recordCount: 7);

    final all = await store.loadAll();
    expect(all[LogoPullSource.customers]!.recordCount, 5);
    expect(all[LogoPullSource.orders]!.recordCount, 7);
  });

  test('bozuk JSON boş harita döner ve çökmez', () async {
    SharedPreferences.setMockInitialValues({
      LogoPullStateStore.prefsKey: '{bozuk',
    });
    expect(await buildStore().loadAll(), isEmpty);
  });

  test('bilinmeyen kaynak anahtarı yok sayılır', () async {
    SharedPreferences.setMockInitialValues({
      LogoPullStateStore.prefsKey:
          '{"prices":{"at":"2026-07-29T10:00:00Z","count":3,"ok":true}}',
    });
    expect(await buildStore().loadAll(), isEmpty);
  });

  test('clear tüm kayıtları siler', () async {
    final store = buildStore(now: DateTime.utc(2026, 7, 29, 9));
    await store.record(LogoPullSource.stock, ok: true, recordCount: 1);
    await store.clear();
    expect(await store.loadAll(), isEmpty);
  });
}
