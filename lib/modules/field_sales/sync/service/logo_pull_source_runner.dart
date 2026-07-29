// Dosya Adı: logo_pull_source_runner.dart
// Açıklama: Tek Logo veri türünü Tiger pull sync ile indiren koşucu
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import '../../../../core/logo/logo_tiger_pull_sync.dart';
import '../model/logo_pull_source.dart';
import 'logo_pull_state_store.dart';

/// {@template logo_tiger_pull_all_fn}
/// [LogoTigerPullSync.pullAll] imzasının test edilebilir alt kümesi.
/// {@endtemplate}
typedef LogoTigerPullAllFn = Future<LogoTigerSyncResult> Function({
  bool products,
  bool customers,
  bool warehouses,
  bool orders,
  bool salesmen,
});

/// {@template logo_pull_outcome}
/// Tek kaynak indirme sonucu.
///
/// Kullanım örneği:
/// ```dart
/// final outcome = await runner.run(LogoPullSource.customers);
/// ```
/// {@endtemplate}
class LogoPullOutcome {
  /// [ok]: İndirme başarılı mı
  final bool ok;

  /// [fetched]: Logo'dan okunan kayıt sayısı
  final int fetched;

  /// [upserted]: SQLite'a yazılan kayıt sayısı
  final int upserted;

  /// [error]: Ham hata metni (çeviri yok)
  final String? error;

  /// [errorKey]: Çevrilebilir hata anahtarı
  final String? errorKey;

  /// [message]: Kaynak bazlı bilgilendirme metni (ham)
  final String? message;

  /// {@macro logo_pull_outcome}
  const LogoPullOutcome({
    required this.ok,
    this.fetched = 0,
    this.upserted = 0,
    this.error,
    this.errorKey,
    this.message,
  });

  /// Seçili bağlantı türünde desteklenmeyen kaynak sonucu.
  factory LogoPullOutcome.unsupported() => const LogoPullOutcome(
        ok: false,
        errorKey: LogoPullSourceCatalog.unsupportedKey,
      );
}

/// {@template logo_pull_source_runner}
/// Bir veri türünü tek başına indirir; toplu indirme bu koşucunun sırayla
/// çağrılmasıdır (satır bazlı durum + doğru genel ilerleme).
///
/// Mevcut `LogoTigerPullSync.pullAll` bayrakları yeniden kullanılır; yeni
/// senkron mimarisi yazılmaz.
///
/// Kullanım örneği:
/// ```dart
/// final runner = LogoPullSourceRunner();
/// final outcome = await runner.run(LogoPullSource.products);
/// ```
/// {@endtemplate}
class LogoPullSourceRunner {
  /// [pullAll]: Tiger pull fonksiyonu (varsayılan [LogoTigerPullSync])
  final LogoTigerPullAllFn pullAll;

  /// [stateStore]: Satır durumlarının kalıcılığı
  final LogoPullStateStore stateStore;

  /// {@macro logo_pull_source_runner}
  LogoPullSourceRunner({
    LogoTigerPullAllFn? pullAll,
    LogoPullStateStore? stateStore,
    LogoTigerPullSync? pullSync,
  })  : pullAll = pullAll ?? (pullSync ?? LogoTigerPullSync()).pullAll,
        stateStore = stateStore ?? const LogoPullStateStore();

  /// {@template logo_pull_source_runner_run}
  /// Tek kaynağı indirir ve durumunu kaydeder.
  ///
  /// Parametreler:
  /// - [source]: İndirilecek veri türü
  ///
  /// Dönüş değeri:
  /// - [LogoPullOutcome]: Sayaçlar + hata bilgisi (exception fırlatmaz)
  /// {@endtemplate}
  Future<LogoPullOutcome> run(LogoPullSource source) async {
    if (!LogoPullSourceCatalog.supportsTiger(source)) {
      return LogoPullOutcome.unsupported();
    }

    final result = await pullAll(
      products: source == LogoPullSource.products,
      customers: source == LogoPullSource.customers,
      warehouses: source == LogoPullSource.warehouses,
      orders: source == LogoPullSource.orders,
      salesmen: source == LogoPullSource.salesmen,
    );

    final entity = _entityOf(result, source);
    final ok = result.ok && entity.errors == 0;
    final outcome = LogoPullOutcome(
      ok: ok,
      fetched: entity.fetched,
      upserted: entity.upserted,
      error: ok ? null : result.error,
      message: entity.message,
    );

    await stateStore.record(
      source,
      ok: ok,
      recordCount: entity.upserted,
      error: outcome.error,
    );
    return outcome;
  }

  /// [_entityOf]: Toplu sonuçtan ilgili kaynağın özetini seçer.
  static LogoTigerEntitySyncResult _entityOf(
    LogoTigerSyncResult result,
    LogoPullSource source,
  ) {
    switch (source) {
      case LogoPullSource.products:
        return result.products;
      case LogoPullSource.customers:
        return result.customers;
      case LogoPullSource.warehouses:
        return result.warehouses;
      case LogoPullSource.orders:
        return result.orders;
      case LogoPullSource.salesmen:
        return result.salesmen;
      case LogoPullSource.stock:
      case LogoPullSource.balances:
        return const LogoTigerEntitySyncResult();
    }
  }
}
