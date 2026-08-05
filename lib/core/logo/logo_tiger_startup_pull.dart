// Dosya Adı: logo_tiger_startup_pull.dart
// Açıklama: İlk açılışta Logo Tiger master verisini (gerekirse) otomatik çeker
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'package:flutter/foundation.dart';

import '../../modules/field_sales/sync/model/logo_pull_source.dart';
import '../../modules/field_sales/sync/service/logo_pull_source_runner.dart';
import '../../modules/field_sales/sync/service/logo_pull_state_store.dart';
import 'logo_tiger_config.dart';
import 'logo_tiger_pull_sync.dart';
import 'logo_tiger_settings_store.dart';

/// {@template logo_tiger_startup_pull_result}
/// Açılış pull özeti — UI kırılmaz; hata yalnızca log/özet.
///
/// Kullanım örneği:
/// ```dart
/// final r = await LogoTigerStartupPull().runIfNeeded();
/// debugPrint(r.skipReason ?? r.error);
/// ```
/// {@endtemplate}
class LogoTigerStartupPullResult {
  /// [attempted]: Network pull denendi mi
  final bool attempted;

  /// [skipped]: Bilinçli atlandı mı (spam / yapılandırma)
  final bool skipped;

  /// [skipReason]: Atlanma nedeni sabiti
  final String? skipReason;

  /// [ok]: Pull başarılı mı (atlandıysa true kabul edilmez; attempted=false)
  final bool ok;

  /// [error]: Ham hata metni
  final String? error;

  /// [messages]: Entity özet satırları
  final List<String> messages;

  /// {@macro logo_tiger_startup_pull_result}
  const LogoTigerStartupPullResult({
    required this.attempted,
    this.skipped = false,
    this.skipReason,
    this.ok = false,
    this.error,
    this.messages = const [],
  });
}

/// {@template logo_tiger_startup_pull}
/// Sistem açılışında Logo'dan gerekli master veriyi çeker.
///
/// Gerekli kapsam (MBT alınacak çekirdek): ürün, cari, ambar, plasiyer,
/// kasa, banka, birim set. Sipariş / döviz açılışta yok (ağır / tablo yok).
///
/// Spam önleme: ürün+cari için [LogoPullStateStore] başarı kaydı varsa atlar.
/// Tiger kapalı / kimlik yok / eşzamanlı koşu → sessiz skip. Exception fırlatmaz.
///
/// Kullanım örneği:
/// ```dart
/// unawaited(LogoTigerStartupPull().runIfNeeded());
/// ```
/// {@endtemplate}
class LogoTigerStartupPull {
  /// Atlanma: Tiger REST kapalı
  static const String skipDisabled = 'disabled';

  /// Atlanma: base URL / OAuth eksik
  static const String skipNotConfigured = 'not_configured';

  /// Atlanma: ürün+cari zaten başarılı çekilmiş
  static const String skipAlreadySynced = 'already_synced';

  /// Atlanma: başka bir runIfNeeded devam ediyor
  static const String skipInProgress = 'in_progress';

  /// [_gateSources]: Skip kararı için minimum başarı kaynakları
  static const List<LogoPullSource> _gateSources = [
    LogoPullSource.products,
    LogoPullSource.customers,
  ];

  /// [_inFlight]: Process-level eşzamanlılık kilidi
  static bool _inFlight = false;

  /// [settingsStore]: Tiger ayarları (varsayılan store)
  final LogoTigerSettingsStore? settingsStore;

  /// [stateStore]: Kaynak bazlı pull geçmişi
  final LogoPullStateStore stateStore;

  /// [pullAll]: Test edilebilir pull fonksiyonu
  final LogoTigerPullAllFn pullAll;

  /// [isEnabled]: Test inject — Tiger açık mı
  final Future<bool> Function()? isEnabled;

  /// [loadConfig]: Test inject — yapılandırma
  final Future<LogoTigerConfig> Function()? loadConfig;

  /// [ensureDefaults]: Test inject — boş prefs → default seed
  final Future<void> Function()? ensureDefaults;

  /// {@macro logo_tiger_startup_pull}
  LogoTigerStartupPull({
    this.settingsStore,
    LogoPullStateStore? stateStore,
    LogoTigerPullAllFn? pullAll,
    LogoTigerPullSync? pullSync,
    this.isEnabled,
    this.loadConfig,
    this.ensureDefaults,
  })  : stateStore = stateStore ?? const LogoPullStateStore(),
        pullAll = pullAll ?? (pullSync ?? LogoTigerPullSync()).pullAll;

  /// Test kilidini sıfırlar.
  @visibleForTesting
  static void resetInFlightForTest() {
    _inFlight = false;
  }

  LogoTigerSettingsStore get _store =>
      settingsStore ?? LogoTigerSettingsStore();

  /// {@template logo_tiger_startup_pull_run}
  /// Gerekirse Logo master pull; gerekmezse no-op.
  ///
  /// Dönüş değeri:
  /// - [LogoTigerStartupPullResult]: Deneme / skip / hata özeti
  /// {@endtemplate}
  Future<LogoTigerStartupPullResult> runIfNeeded() async {
    if (_inFlight) {
      return const LogoTigerStartupPullResult(
        attempted: false,
        skipped: true,
        skipReason: skipInProgress,
      );
    }
    _inFlight = true;
    try {
      return await _runBody();
    } catch (e, st) {
      debugPrint('LogoTigerStartupPull: $e\n$st');
      return LogoTigerStartupPullResult(
        attempted: true,
        ok: false,
        error: e.toString(),
      );
    } finally {
      _inFlight = false;
    }
  }

  Future<LogoTigerStartupPullResult> _runBody() async {
    final ensure = ensureDefaults;
    if (ensure != null) {
      await ensure();
    } else {
      await _store.ensureDefaultsPersisted();
    }

    final enabled =
        isEnabled != null ? await isEnabled!() : await _store.isEnabled();
    if (!enabled) {
      return const LogoTigerStartupPullResult(
        attempted: false,
        skipped: true,
        skipReason: skipDisabled,
      );
    }

    final cfg =
        loadConfig != null ? await loadConfig!() : await _store.load();
    if (!cfg.canPush) {
      return const LogoTigerStartupPullResult(
        attempted: false,
        skipped: true,
        skipReason: skipNotConfigured,
      );
    }

    final states = await stateStore.loadAll();
    if (_isAlreadySynced(states)) {
      return const LogoTigerStartupPullResult(
        attempted: false,
        skipped: true,
        skipReason: skipAlreadySynced,
      );
    }

    final result = await pullAll(
      products: true,
      customers: true,
      warehouses: true,
      orders: false,
      salesmen: true,
      cash: true,
      banks: true,
      currencies: false,
      unitSets: true,
    );

    await _recordResults(result);

    if (!result.ok) {
      debugPrint(
        'LogoTigerStartupPull fail: ${result.error ?? 'unknown'}'
        ' · ${result.messages.join(' | ')}',
      );
      return LogoTigerStartupPullResult(
        attempted: true,
        ok: false,
        error: result.error,
        messages: result.messages,
      );
    }

    debugPrint(
      'LogoTigerStartupPull ok: ${result.messages.join(' | ')}',
    );
    return LogoTigerStartupPullResult(
      attempted: true,
      ok: true,
      messages: result.messages,
    );
  }

  /// [_isAlreadySynced]: Ürün + cari başarı kaydı var mı?
  static bool _isAlreadySynced(
    Map<LogoPullSource, LogoPullSourceState> states,
  ) {
    for (final source in _gateSources) {
      final state = states[source];
      if (state == null || state.lastSuccessAt == null) return false;
    }
    return true;
  }

  /// [_recordResults]: Gate + MBT çekirdek kaynak durumlarını yazar.
  Future<void> _recordResults(LogoTigerSyncResult result) async {
    Future<void> rec(
      LogoPullSource source,
      LogoTigerEntitySyncResult entity,
    ) async {
      final ok = result.ok && entity.errors == 0;
      await stateStore.record(
        source,
        ok: ok,
        recordCount: ok ? entity.upserted : null,
        error: ok ? null : (result.error ?? entity.message),
      );
    }

    await rec(LogoPullSource.products, result.products);
    await rec(LogoPullSource.customers, result.customers);
    await rec(LogoPullSource.cash, result.cash);
    await rec(LogoPullSource.banks, result.banks);
    await rec(
      LogoPullSource.general,
      LogoTigerEntitySyncResult(
        fetched: result.warehouses.fetched +
            result.salesmen.fetched +
            result.unitSets.fetched,
        upserted: result.warehouses.upserted +
            result.salesmen.upserted +
            result.unitSets.upserted,
        errors: result.warehouses.errors +
            result.salesmen.errors +
            result.unitSets.errors,
      ),
    );
  }
}
