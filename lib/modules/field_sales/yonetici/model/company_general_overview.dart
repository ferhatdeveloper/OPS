// Dosya Adı: company_general_overview.dart
// Açıklama: MBT Firma Genel Görünüm dens özet + aylık satırlar (örnek/stub)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template company_monthly_snapshot}
/// Tek ay için alış / satış / maliyet / gider satırı.
///
/// Kullanım örneği:
/// ```dart
/// final m = CompanyMonthlySnapshot(month: 1, year: 2026, sales: 1000);
/// ```
/// {@endtemplate}
class CompanyMonthlySnapshot {
  /// [month]: Ay (1–12)
  final int month;

  /// [year]: Yıl
  final int year;

  /// [purchases]: Alışlar
  final double purchases;

  /// [sales]: Satışlar
  final double sales;

  /// [salesReturns]: Satış iade
  final double salesReturns;

  /// [cost]: Maliyet
  final double cost;

  /// [expenses]: Giderler
  final double expenses;

  /// {@macro company_monthly_snapshot}
  const CompanyMonthlySnapshot({
    required this.month,
    required this.year,
    this.purchases = 0,
    this.sales = 0,
    this.salesReturns = 0,
    this.cost = 0,
    this.expenses = 0,
  });

  /// Kar tutarı: Satışlar − Maliyet (görüntüleme).
  double get profitAmount => sales - cost;

  /// Kar %: (Satışlar − Maliyet) / Satışlar × 100.
  double get profitPct {
    if (sales == 0) return 0;
    return (profitAmount / sales) * 100;
  }
}

/// {@template company_monthly_pair}
/// Aynı ay için yıl / yıl−1 alt alta kart çifti (bir sütun).
///
/// Kullanım örneği:
/// ```dart
/// final p = CompanyMonthlyPair(
///   current: CompanyMonthlySnapshot(month: 1, year: 2026),
///   previous: CompanyMonthlySnapshot(month: 1, year: 2025),
/// );
/// ```
/// {@endtemplate}
class CompanyMonthlyPair {
  /// [current]: Bu yıl ayı
  final CompanyMonthlySnapshot current;

  /// [previous]: Geçen yıl aynı ay
  final CompanyMonthlySnapshot previous;

  /// {@macro company_monthly_pair}
  const CompanyMonthlyPair({
    required this.current,
    required this.previous,
  });
}

/// {@template company_general_overview}
/// Firma Genel Analiz dens özeti — MBT alan grupları.
///
/// Canlı veri yokken [sample] demo tutarları kullanır.
///
/// Kullanım örneği:
/// ```dart
/// final o = CompanyGeneralOverview.sample;
/// ```
/// {@endtemplate}
class CompanyGeneralOverview {
  /// [customerDebt]: Müşteri borcu
  final double customerDebt;

  /// [ownDebt]: Kendi (firma) borcu
  final double ownDebt;

  /// [generalDebt]: Genel borç / alacak
  final double generalDebt;

  /// [cashBalance]: Kasa bakiyesi
  final double cashBalance;

  /// [bankBalance]: Banka bakiyesi
  final double bankBalance;

  /// [salesExVat]: Satışlar (KDV hariç)
  final double salesExVat;

  /// [salesReturns]: Satış iadeleri
  final double salesReturns;

  /// [salesCost]: Satış maliyeti
  final double salesCost;

  /// [inventoryPlusMinus]: Envanter (+/-)
  final double inventoryPlusMinus;

  /// [inventoryGeneral]: Envanter genel
  final double inventoryGeneral;

  /// [inventoryFixedAssets]: Demirbaş
  final double inventoryFixedAssets;

  /// [companyCheckRisk]: Firma çek riski
  final double companyCheckRisk;

  /// [customerCheckRisk]: Müşteri çek riski
  final double customerCheckRisk;

  /// [purchases]: Alışlar
  final double purchases;

  /// [purchaseReturns]: Alış iadeleri
  final double purchaseReturns;

  /// [expenses]: Giderler
  final double expenses;

  /// [designFileName]: Dizayn dosya (MBT: GenelAnaliz.repx)
  final String designFileName;

  /// [isSample]: Örnek veri etiketi göster
  final bool isSample;

  /// [monthlyPairs]: Ocak… alt alta yıl / yıl−1 ay sütunları
  final List<CompanyMonthlyPair> monthlyPairs;

  /// {@macro company_general_overview}
  const CompanyGeneralOverview({
    this.customerDebt = 0,
    this.ownDebt = 0,
    this.generalDebt = 0,
    this.cashBalance = 0,
    this.bankBalance = 0,
    this.salesExVat = 0,
    this.salesReturns = 0,
    this.salesCost = 0,
    this.inventoryPlusMinus = 0,
    this.inventoryGeneral = 0,
    this.inventoryFixedAssets = 0,
    this.companyCheckRisk = 0,
    this.customerCheckRisk = 0,
    this.purchases = 0,
    this.purchaseReturns = 0,
    this.expenses = 0,
    this.designFileName = 'GenelAnaliz.repx',
    this.isSample = false,
    this.monthlyPairs = const [],
  });

  /// Kar tutarı: Satışlar − Maliyet.
  double get salesProfitAmount => salesExVat - salesCost;

  /// Kar %: (Satışlar − Maliyet) / Satışlar × 100.
  double get salesProfitPct {
    if (salesExVat == 0) return 0;
    return (salesProfitAmount / salesExVat) * 100;
  }

  /// Sıfır stub — boş aylık satırlar.
  static CompanyGeneralOverview get zero => const CompanyGeneralOverview();

  /// MBT ekran görüntüsü büyüklüğünde örnek (demo) veri.
  static CompanyGeneralOverview get sample {
    final year = DateTime.now().year;
    final prevYear = year - 1;
    final pairs = <CompanyMonthlyPair>[];
    // Ekran görüntüsü mertebesi: yüzbin–milyon TL
    const salesBase = <double>[
      1245800,
      980400,
      1512200,
      1088600,
      1320000,
      1450300,
      1100500,
      1275900,
      1390100,
      1180000,
      1560400,
      1720800,
    ];
    const costRatio = 0.72;
    for (var m = 1; m <= 12; m++) {
      final s = salesBase[m - 1];
      final sPrev = s * 0.88;
      pairs.add(
        CompanyMonthlyPair(
          current: CompanyMonthlySnapshot(
            month: m,
            year: year,
            purchases: s * 0.55,
            sales: s,
            salesReturns: s * 0.03,
            cost: s * costRatio,
            expenses: s * 0.08,
          ),
          previous: CompanyMonthlySnapshot(
            month: m,
            year: prevYear,
            purchases: sPrev * 0.55,
            sales: sPrev,
            salesReturns: sPrev * 0.025,
            cost: sPrev * costRatio,
            expenses: sPrev * 0.075,
          ),
        ),
      );
    }

    const sales = 14824900.0;
    const cost = sales * costRatio;
    return CompanyGeneralOverview(
      customerDebt: 71540786.36,
      ownDebt: 12340220.50,
      generalDebt: 59200565.86,
      cashBalance: 1845320.75,
      bankBalance: 8932110.40,
      salesExVat: sales,
      salesReturns: 445200.00,
      salesCost: cost,
      inventoryPlusMinus: 320450.00,
      inventoryGeneral: 22180600.00,
      inventoryFixedAssets: 3450000.00,
      companyCheckRisk: 2180000.00,
      customerCheckRisk: 5640800.00,
      purchases: 9120400.00,
      purchaseReturns: 210300.00,
      expenses: 1180600.00,
      designFileName: 'GenelAnaliz.repx',
      isSample: true,
      monthlyPairs: pairs,
    );
  }

  /// Dens tutar formatı.
  static String formatAmount(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$intPart,${parts[1]}';
  }

  /// Yüzde formatı.
  static String formatPct(double value) {
    return '%${value.toStringAsFixed(2)}';
  }

  /// Kar % | tutar (MBT: Kar %|amount).
  static String formatProfitLine(double pct, double amount) {
    return '${formatPct(pct)} | ${formatAmount(amount)}';
  }
}
