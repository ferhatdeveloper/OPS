// Dosya Adı: mbt_report_param_field.dart
// Açıklama: MBT rapor Parametreler alan türleri (tarih / kod / toggle / dizayn)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template mbt_report_param_kind}
/// Parametre satır türü — dens form alanları.
/// {@endtemplate}
enum MbtReportParamKind {
  /// Başlangıç + bitiş + Bugün/Hafta/Ay/Yıl preset
  dateRange,

  /// Tek bitiş tarihi
  dateEnd,

  /// KOD / AD çifti
  codeName,

  /// KOD 2 / AD 2 çifti
  codeName2,

  /// CARİKODU / AD — dens cari seçici
  cariCodeName,

  /// CARİKODU 2 / AD 2 — aralık bitiş (tahsilat)
  cariCodeName2,

  /// Döviz kodu metin
  currencyCode,

  /// Döviz değerleme switch
  currencyValuation,

  /// Raporlama dövizi switch
  reportingCurrency,

  /// SEÇİM (Satış / Alış)
  selectionSalePurchase,

  /// İŞYERİ / FABRİKA / AMBAR
  workplaceFactoryWarehouse,

  /// Özel kod 1..5
  specialCodes,

  /// 0'dan büyük / küçük / bakiye 0
  balanceFilters,

  /// Dizayn dosya (.repx) salt okunur
  designFile,

  /// STK.KOD / STK.AD (bekleyen sipariş)
  stockCodeName,

  /// STK.KOD 2 / STK.AD 2
  stockCodeName2,
}

/// {@template mbt_report_param_field}
/// Tek parametre alanı tanımı.
///
/// Kullanım örneği:
/// ```dart
/// const MbtReportParamField(MbtReportParamKind.dateRange);
/// ```
/// {@endtemplate}
class MbtReportParamField {
  /// [kind]: Alan türü
  final MbtReportParamKind kind;

  const MbtReportParamField(this.kind);
}

/// {@template mbt_report_param_profiles}
/// MBT ekranlarından türetilmiş hazır alan profilleri.
/// {@endtemplate}
class MbtReportParamProfiles {
  /// Cari Extre tarzı (tarih + cari seçici + döviz + dizayn)
  static const List<MbtReportParamField> cariExtre = [
    MbtReportParamField(MbtReportParamKind.dateRange),
    MbtReportParamField(MbtReportParamKind.cariCodeName),
    MbtReportParamField(MbtReportParamKind.currencyValuation),
    MbtReportParamField(MbtReportParamKind.currencyCode),
    MbtReportParamField(MbtReportParamKind.reportingCurrency),
    MbtReportParamField(MbtReportParamKind.designFile),
  ];

  /// Tahsilat Listesi (bitiş + cari aralığı + özelkod)
  static const List<MbtReportParamField> tahsilat = [
    MbtReportParamField(MbtReportParamKind.dateEnd),
    MbtReportParamField(MbtReportParamKind.cariCodeName),
    MbtReportParamField(MbtReportParamKind.cariCodeName2),
    MbtReportParamField(MbtReportParamKind.specialCodes),
    MbtReportParamField(MbtReportParamKind.designFile),
  ];

  /// Stok Bakiye (stok kod metin + cari seçici + bakiye filtre)
  static const List<MbtReportParamField> stokBakiye = [
    MbtReportParamField(MbtReportParamKind.codeName),
    MbtReportParamField(MbtReportParamKind.codeName2),
    MbtReportParamField(MbtReportParamKind.cariCodeName),
    MbtReportParamField(MbtReportParamKind.balanceFilters),
    MbtReportParamField(MbtReportParamKind.specialCodes),
    MbtReportParamField(MbtReportParamKind.designFile),
  ];

  /// Belge listesi (sipariş/fatura/irsaliye dens)
  static const List<MbtReportParamField> belgeListesi = [
    MbtReportParamField(MbtReportParamKind.dateRange),
    MbtReportParamField(MbtReportParamKind.selectionSalePurchase),
    MbtReportParamField(MbtReportParamKind.workplaceFactoryWarehouse),
    MbtReportParamField(MbtReportParamKind.codeName),
    MbtReportParamField(MbtReportParamKind.codeName2),
    MbtReportParamField(MbtReportParamKind.cariCodeName),
    MbtReportParamField(MbtReportParamKind.specialCodes),
    MbtReportParamField(MbtReportParamKind.designFile),
  ];

  /// Bekleyen sipariş — stok kod + belge listesi varyantı
  static const List<MbtReportParamField> belgeStokKod = [
    MbtReportParamField(MbtReportParamKind.dateRange),
    MbtReportParamField(MbtReportParamKind.stockCodeName),
    MbtReportParamField(MbtReportParamKind.stockCodeName2),
    MbtReportParamField(MbtReportParamKind.codeName),
    MbtReportParamField(MbtReportParamKind.codeName2),
    MbtReportParamField(MbtReportParamKind.workplaceFactoryWarehouse),
    MbtReportParamField(MbtReportParamKind.designFile),
  ];

  /// Basit tarih aralığı + serbest KOD/AD (stok / yönetici / OPS)
  static const List<MbtReportParamField> simpleDate = [
    MbtReportParamField(MbtReportParamKind.dateRange),
    MbtReportParamField(MbtReportParamKind.codeName),
    MbtReportParamField(MbtReportParamKind.designFile),
  ];

  /// CARİ basit tarih + cari seçici (serbest KOD yok)
  static const List<MbtReportParamField> cariSimpleDate = [
    MbtReportParamField(MbtReportParamKind.dateRange),
    MbtReportParamField(MbtReportParamKind.cariCodeName),
    MbtReportParamField(MbtReportParamKind.designFile),
  ];

  /// GPS / konum (dizayn + opsiyonel serbest kod)
  static const List<MbtReportParamField> gps = [
    MbtReportParamField(MbtReportParamKind.codeName),
    MbtReportParamField(MbtReportParamKind.designFile),
  ];

  /// CARİ GPS — cari seçici
  static const List<MbtReportParamField> cariGps = [
    MbtReportParamField(MbtReportParamKind.cariCodeName),
    MbtReportParamField(MbtReportParamKind.designFile),
  ];
}
