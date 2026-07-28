// Dosya Adı: default_currency_resolver.dart
// Açıklama: Merkez/firma varsayılan para birimini SQLite/settings'ten çözer
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../service/database_service.dart';
import '../../companies/viewmodel/active_company_store.dart';
import '../engine/collection_currency_exchange.dart';

/// {@template default_currency_resolver}
/// Tahsilat varsayılan dövizi: aktif firma → settings → prefs → TRY.
///
/// Kullanım örneği:
/// ```dart
/// final code = await const DefaultCurrencyResolver().resolve();
/// ```
/// {@endtemplate}
class DefaultCurrencyResolver {
  /// Settings / prefs anahtarı
  static const String settingKey = 'default_currency';

  /// RetailEX uyumlu alternatif anahtar
  static const String settingKeyAlt = 'ana_para_birimi';

  /// Prefs yedek anahtarı
  static const String prefsKey = 'fs_default_currency';

  /// [activeCompanyStore]: Aktif firma oturumu
  final ActiveCompanyStore activeCompanyStore;

  /// [getSetting]: Settings okuyucu (test enjeksiyonu)
  final Future<String?> Function(String key)? getSetting;

  /// [queryCompanyCurrency]: Firma satırından döviz (test enjeksiyonu)
  final Future<String?> Function(String companyId, String companyNo)?
      queryCompanyCurrency;

  /// {@macro default_currency_resolver}
  const DefaultCurrencyResolver({
    this.activeCompanyStore = const ActiveCompanyStore(
      syncLogoPrefs: false,
      syncPostgresContext: false,
    ),
    this.getSetting,
    this.queryCompanyCurrency,
  });

  /// {@template default_currency_resolver_resolve}
  /// Merkez varsayılan para birimi kodunu döner.
  ///
  /// Dönüş değeri:
  /// - [String]: Normalize kod (boş olmaz; yedek TRY)
  /// {@endtemplate}
  Future<String> resolve() async {
    final session = ActiveCompanyStore.current ??
        await activeCompanyStore.load();

    final fromCompany = await _fromCompany(
      companyId: session.companyId,
      companyNo: session.companyNo,
    );
    if (fromCompany != null) return fromCompany;

    final fromSettings = await _fromSettings();
    if (fromSettings != null) return fromSettings;

    final prefs = await SharedPreferences.getInstance();
    final fromPrefs = CollectionCurrencyExchange.normalize(
      prefs.getString(prefsKey),
    );
    if (fromPrefs.isNotEmpty) return fromPrefs;

    return CollectionCurrencyExchange.fallbackDefaultCode;
  }

  /// {@template default_currency_resolver_save_prefs}
  /// Varsayılan dövizi prefs'e yazar (test / lokal override).
  /// {@endtemplate}
  Future<void> savePrefs(String code) async {
    final n = CollectionCurrencyExchange.normalize(code);
    if (n.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, n);
  }

  Future<String?> _fromCompany({
    required String companyId,
    required String companyNo,
  }) async {
    if (queryCompanyCurrency != null) {
      final raw = await queryCompanyCurrency!(companyId, companyNo);
      final n = CollectionCurrencyExchange.normalize(raw);
      return n.isEmpty ? null : n;
    }
    try {
      final db = await DatabaseService.getInstance();
      await db.ensureCompaniesTableSchema();
      final sqlite = await db.getDatabase();
      final columns = await sqlite.rawQuery(
        'PRAGMA table_info(companies)',
      );
      final hasCol = columns.any(
        (c) => c['name']?.toString() == 'default_currency',
      );
      if (!hasCol) return null;

      if (companyId.trim().isNotEmpty) {
        final rows = await sqlite.query(
          'companies',
          columns: ['default_currency'],
          where: 'id = ?',
          whereArgs: [companyId.trim()],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          final n = CollectionCurrencyExchange.normalize(
            rows.first['default_currency']?.toString(),
          );
          if (n.isNotEmpty) return n;
        }
      }
      if (companyNo.trim().isNotEmpty) {
        final rows = await sqlite.query(
          'companies',
          columns: ['default_currency'],
          where: 'company_no = ?',
          whereArgs: [companyNo.trim()],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          final n = CollectionCurrencyExchange.normalize(
            rows.first['default_currency']?.toString(),
          );
          if (n.isNotEmpty) return n;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<String?> _fromSettings() async {
    try {
      final getter = getSetting ??
          (String key) async {
            final db = await DatabaseService.getInstance();
            return db.getSetting(key);
          };
      for (final key in [settingKey, settingKeyAlt]) {
        final raw = await getter(key);
        final n = CollectionCurrencyExchange.normalize(raw);
        if (n.isNotEmpty) return n;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
