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
  bool cash,
  bool banks,
  bool currencies,
  bool unitSets,
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

  /// [errorKey]: Çevrilebilir hata / bilgilendirme anahtarı
  final String? errorKey;

  /// [message]: Kaynak bazlı bilgilendirme metni (ham)
  final String? message;

  /// [comingSoon]: Kaynak henüz bağlanmadı — hata değil, bekleyen satır
  final bool comingSoon;

  /// {@macro logo_pull_outcome}
  const LogoPullOutcome({
    required this.ok,
    this.fetched = 0,
    this.upserted = 0,
    this.error,
    this.errorKey,
    this.message,
    this.comingSoon = false,
  });

  /// Seçili bağlantı türünde desteklenmeyen kaynak sonucu.
  factory LogoPullOutcome.unsupported() => const LogoPullOutcome(
        ok: false,
        errorKey: LogoPullSourceCatalog.unsupportedKey,
      );

  /// {@template logo_pull_outcome_coming_soon}
  /// Kaynağı henüz bağlanmamış (veya yerel tablosu olmayan) satır sonucu.
  ///
  /// Parametreler:
  /// - [messageKey]: Gösterilecek l10n anahtarı
  /// - [message]: Varsa pull katmanının ham açıklaması
  /// {@endtemplate}
  factory LogoPullOutcome.comingSoon({
    String messageKey = LogoPullSourceCatalog.comingSoonKey,
    String? message,
  }) =>
      LogoPullOutcome(
        ok: false,
        comingSoon: true,
        errorKey: messageKey,
        message: message,
      );
}

/// {@template logo_pull_source_runner}
/// Bir veri türünü tek başına indirir; toplu indirme bu koşucunun sırayla
/// çağrılmasıdır (satır bazlı durum + doğru genel ilerleme).
///
/// Mevcut `LogoTigerPullSync.pullAll` bayrakları yeniden kullanılır; yeni
/// senkron mimarisi yazılmaz. MBT "GENEL BİLGİLER" satırı ambar + plasiyer +
/// birim seti tek çağrıda çeker ve sayaçları toplar.
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
  /// - [LogoPullOutcome]: Sayaçlar + hata / bekleme bilgisi (exception yok)
  /// {@endtemplate}
  Future<LogoPullOutcome> run(LogoPullSource source) async {
    if (LogoPullSourceCatalog.isComingSoon(source)) {
      return LogoPullOutcome.comingSoon(
        messageKey: LogoPullSourceCatalog.pendingMessageKey(source),
      );
    }
    if (!LogoPullSourceCatalog.supportsTiger(source)) {
      return LogoPullOutcome.unsupported();
    }

    final isGeneral = source == LogoPullSource.general;
    final result = await pullAll(
      products: source == LogoPullSource.products,
      customers: source == LogoPullSource.customers,
      warehouses: isGeneral || source == LogoPullSource.warehouses,
      orders: source == LogoPullSource.orders,
      salesmen: isGeneral || source == LogoPullSource.salesmen,
      cash: source == LogoPullSource.cash,
      banks: source == LogoPullSource.banks,
      currencies: source == LogoPullSource.currency,
      unitSets: isGeneral,
    );

    final entity = _entityOf(result, source);
    if (_isEmptySource(result, entity)) {
      // Yerel tablo / uç nokta yok: hata değil, bekleyen satır.
      return LogoPullOutcome.comingSoon(message: entity.message);
    }

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

  /// [_isEmptySource]: Pull başarılı ama kaynak/yerel tablo yok mu?
  static bool _isEmptySource(
    LogoTigerSyncResult result,
    LogoTigerEntitySyncResult entity,
  ) {
    return result.ok &&
        entity.fetched == 0 &&
        entity.upserted == 0 &&
        entity.errors == 0 &&
        (entity.message?.trim().isNotEmpty ?? false);
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
      case LogoPullSource.cash:
        return result.cash;
      case LogoPullSource.banks:
        return result.banks;
      case LogoPullSource.currency:
        return result.currencies;
      case LogoPullSource.general:
        return _merge([
          result.warehouses,
          result.salesmen,
          result.unitSets,
        ]);
      case LogoPullSource.warehouses:
        return result.warehouses;
      case LogoPullSource.orders:
        return result.orders;
      case LogoPullSource.salesmen:
        return result.salesmen;
      case LogoPullSource.stock:
      case LogoPullSource.balances:
      case LogoPullSource.variants:
      case LogoPullSource.routes:
      case LogoPullSource.announcements:
        return const LogoTigerEntitySyncResult();
    }
  }

  /// [_merge]: Composite satır (GENEL) için sayaç ve mesaj toplama.
  static LogoTigerEntitySyncResult _merge(
    List<LogoTigerEntitySyncResult> parts,
  ) {
    var fetched = 0;
    var upserted = 0;
    var errors = 0;
    var usersCreated = 0;
    final messages = <String>[];
    for (final part in parts) {
      fetched += part.fetched;
      upserted += part.upserted;
      errors += part.errors;
      usersCreated += part.usersCreated;
      final message = part.message?.trim();
      if (message != null && message.isNotEmpty) messages.add(message);
    }
    return LogoTigerEntitySyncResult(
      fetched: fetched,
      upserted: upserted,
      errors: errors,
      usersCreated: usersCreated,
      message: messages.isEmpty ? null : messages.join(' · '),
    );
  }
}
