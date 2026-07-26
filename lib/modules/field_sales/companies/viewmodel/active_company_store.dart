// Dosya Adı: active_company_store.dart
// Açıklama: Aktif firma/dönem SharedPreferences + bellek oturumu
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/logo_rest_settings_service.dart';
import '../../../../service/postgres_service.dart';
import '../model/active_company_session.dart';

/// {@template active_company_store}
/// Seçili firma/dönemi prefs'e yazar, bellek oturumunu günceller
/// ve Logo REST + Postgres aktif bağlamı senkronlar.
///
/// Kullanım örneği:
/// ```dart
/// const store = ActiveCompanyStore();
/// await store.save(ActiveCompanySession(
///   companyId: 'mbt_001',
///   companyName: 'MBT',
///   companyNo: '001',
///   periodNo: '01',
/// ));
/// print(ActiveCompanyStore.current?.appBarLabel);
/// ```
/// {@endtemplate}
class ActiveCompanyStore {
  /// [prefsCompanyId]: companies.id anahtarı
  static const String prefsCompanyId = 'fs_active_company_id';

  /// [prefsCompanyName]: Firma adı anahtarı
  static const String prefsCompanyName = 'fs_active_company_name';

  /// [prefsCompanyNo]: Firma No anahtarı
  static const String prefsCompanyNo = 'fs_active_company_no';

  /// [prefsPeriodNo]: Dönem No anahtarı
  static const String prefsPeriodNo = 'fs_active_period_no';

  /// [prefsStartDate]: Dönem başlangıç
  static const String prefsStartDate = 'fs_active_period_start';

  /// [prefsEndDate]: Dönem bitiş
  static const String prefsEndDate = 'fs_active_period_end';

  /// Bellekteki aktif oturum (senkron okuma)
  static ActiveCompanySession? _current;

  /// [current]: Son kaydedilen / yüklenen oturum
  static ActiveCompanySession? get current => _current;

  /// Logo REST prefs senkronu (testte kapatılabilir)
  final bool syncLogoPrefs;

  /// Postgres bellek bağlamı senkronu
  final bool syncPostgresContext;

  /// {@macro active_company_store}
  const ActiveCompanyStore({
    this.syncLogoPrefs = true,
    this.syncPostgresContext = true,
  });

  /// {@template active_company_store_load}
  /// Prefs'ten aktif firma/dönemi yükler; belleği günceller.
  ///
  /// Dönüş değeri:
  /// - [ActiveCompanySession]: Kayıt (yoksa empty)
  /// {@endtemplate}
  Future<ActiveCompanySession> load() async {
    final prefs = await SharedPreferences.getInstance();
    final session = ActiveCompanySession(
      companyId: prefs.getString(prefsCompanyId) ?? '',
      companyName: prefs.getString(prefsCompanyName) ?? '',
      companyNo: prefs.getString(prefsCompanyNo) ?? '',
      periodNo: prefs.getString(prefsPeriodNo) ?? '',
      startDate: prefs.getString(prefsStartDate) ?? '',
      endDate: prefs.getString(prefsEndDate) ?? '',
    );
    _current = session.isEmpty ? null : session;
    return session;
  }

  /// {@template active_company_store_save}
  /// Aktif firma/dönemi prefs + bellek (+ Logo/Postgres) kaydeder.
  ///
  /// Parametreler:
  /// - [session]: Kaydedilecek oturum
  /// {@endtemplate}
  Future<void> save(ActiveCompanySession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsCompanyId, session.companyId.trim());
    await prefs.setString(prefsCompanyName, session.companyName.trim());
    await prefs.setString(prefsCompanyNo, session.companyNo.trim());
    await prefs.setString(prefsPeriodNo, session.periodNo.trim());
    await prefs.setString(prefsStartDate, session.startDate.trim());
    await prefs.setString(prefsEndDate, session.endDate.trim());

    _current = session.isEmpty ? null : session;

    if (syncLogoPrefs && session.isNotEmpty) {
      await LogoRestSettingsService().setFirmaPeriod(
        firma: session.companyNo.trim(),
        period: session.periodNo.trim(),
      );
    }

    if (syncPostgresContext && session.isNotEmpty) {
      PostgresService.instance.setActiveContext(
        firmNr: session.companyNo.trim(),
        periodNr: session.periodNo.trim(),
      );
    }
  }

  /// {@template active_company_store_clear}
  /// Aktif firma/dönem kaydını temizler.
  /// {@endtemplate}
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsCompanyId);
    await prefs.remove(prefsCompanyName);
    await prefs.remove(prefsCompanyNo);
    await prefs.remove(prefsPeriodNo);
    await prefs.remove(prefsStartDate);
    await prefs.remove(prefsEndDate);
    _current = null;
  }

  /// Test / sıcak reload için bellek oturumunu sıfırlar.
  static void resetMemory() {
    _current = null;
  }
}
