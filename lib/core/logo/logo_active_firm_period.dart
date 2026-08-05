// Dosya Adı: logo_active_firm_period.dart
// Açıklama: ActiveCompany etkin firma/dönem → Tiger CompanyLogin köprüsü
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

/// {@template logo_active_firm_period}
/// Kullanıcının seçtiği firma/dönemi Logo Tiger oturumuna taşır.
/// Registry bootstrap `firmNr`/`periodNr` yalnızca yedek varsayılandır.
///
/// Kullanım örneği:
/// ```dart
/// LogoActiveFirmPeriod.applyFromCodes(
///   companyNo: '012',
///   periodNo: '05',
/// );
/// print(LogoActiveFirmPeriod.firmNr); // 12
/// ```
/// {@endtemplate}
class LogoActiveFirmPeriod {
  /// [firmNr]: Etkin Logo firma no (yoksa null)
  static int? _firmNr;

  /// [periodNr]: Etkin Logo dönem no (yoksa null)
  static int? _periodNr;

  /// [firmNr]: Son uygulanan firma no
  static int? get firmNr => _firmNr;

  /// [periodNr]: Son uygulanan dönem no
  static int? get periodNr => _periodNr;

  /// [hasOverride]: Etkin firma+dönem override var mı?
  static bool get hasOverride => _firmNr != null && _periodNr != null;

  /// {@macro logo_active_firm_period}
  LogoActiveFirmPeriod._();

  /// {@template logo_active_firm_period_set}
  /// Bellekteki etkin firma/dönemi ayarlar.
  ///
  /// Parametreler:
  /// - [firmNr]: Logo firma numarası (>0)
  /// - [periodNr]: Logo dönem numarası (>0)
  /// {@endtemplate}
  static void set({required int firmNr, required int periodNr}) {
    if (firmNr <= 0 || periodNr <= 0) return;
    _firmNr = firmNr;
    _periodNr = periodNr;
  }

  /// {@template logo_active_firm_period_apply_from_codes}
  /// `"001"` / `"01"` gibi kodlardan int override üretir.
  ///
  /// Parametreler:
  /// - [companyNo]: Firma kodu (ör. `012`)
  /// - [periodNo]: Dönem kodu (ör. `05`)
  ///
  /// Dönüş değeri:
  /// - [bool]: Geçerli parse + set yapıldıysa `true`
  /// {@endtemplate}
  static bool applyFromCodes({
    required String companyNo,
    required String periodNo,
  }) {
    final firm = int.tryParse(companyNo.trim());
    final period = int.tryParse(periodNo.trim());
    if (firm == null || firm <= 0 || period == null || period <= 0) {
      return false;
    }
    set(firmNr: firm, periodNr: period);
    return true;
  }

  /// {@template logo_active_firm_period_clear}
  /// Bellekteki override’ı temizler (config varsayılanına düşülür).
  /// {@endtemplate}
  static void clear() {
    _firmNr = null;
    _periodNr = null;
  }
}
