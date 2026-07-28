// Dosya Adı: admin_kpi_summary.dart
// Açıklama: Yönetici KPI dönem özet modeli (adet/tutar/hedef/pivot/trend)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template admin_kpi_period}
/// Yönetici KPI dens dönem seçimi (Bugün / Hafta / Ay).
///
/// Kullanım örneği:
/// ```dart
/// final p = AdminKpiPeriod.today;
/// ```
/// {@endtemplate}
enum AdminKpiPeriod {
  /// Bugün
  today,

  /// Bu hafta (Pazartesi → bugün)
  week,

  /// Bu ay (ayın 1’i → bugün)
  month,
}

/// {@template admin_kpi_pivot_row}
/// Plasiyer × metrik dens pivot satırı.
///
/// Kullanım örneği:
/// ```dart
/// const row = AdminKpiPivotRow(
///   salespersonKey: 'u1',
///   salespersonName: 'Ali',
///   visitCount: 3,
/// );
/// ```
/// {@endtemplate}
class AdminKpiPivotRow {
  /// [salespersonKey]: user_id veya salesperson_code
  final String salespersonKey;

  /// [salespersonName]: Görünen ad (yoksa key)
  final String salespersonName;

  /// [visitCount]: Dönem ziyaret adedi
  final int visitCount;

  /// [collectionCount]: Dönem tahsilat adedi
  final int collectionCount;

  /// [collectionAmount]: Dönem tahsilat tutarı
  final double collectionAmount;

  /// [targetAmount]: Dönem hedef tutarı
  final double targetAmount;

  /// [targetAchieved]: Dönem gerçekleşen tutar
  final double targetAchieved;

  /// {@macro admin_kpi_pivot_row}
  const AdminKpiPivotRow({
    required this.salespersonKey,
    required this.salespersonName,
    this.visitCount = 0,
    this.collectionCount = 0,
    this.collectionAmount = 0,
    this.targetAmount = 0,
    this.targetAchieved = 0,
  });

  /// [targetPct]: Hedef gerçekleşme oranı (0–100+; hedef 0 ise 0)
  double get targetPct {
    if (targetAmount <= 0) return 0;
    return (targetAchieved / targetAmount) * 100;
  }

  /// Pivot satırını AI / rapor map’ine çevirir.
  Map<String, String> toInsightMap() {
    return {
      'salesperson': salespersonName,
      'visits': '$visitCount',
      'collections': '$collectionCount',
      'collection_amount': collectionAmount.toStringAsFixed(2),
      'target': targetAmount.toStringAsFixed(2),
      'achieved': targetAchieved.toStringAsFixed(2),
    };
  }

  @override
  bool operator ==(Object other) {
    if (other is! AdminKpiPivotRow) return false;
    return other.salespersonKey == salespersonKey &&
        other.salespersonName == salespersonName &&
        other.visitCount == visitCount &&
        other.collectionCount == collectionCount &&
        other.collectionAmount == collectionAmount &&
        other.targetAmount == targetAmount &&
        other.targetAchieved == targetAchieved;
  }

  @override
  int get hashCode => Object.hash(
        salespersonKey,
        salespersonName,
        visitCount,
        collectionCount,
        collectionAmount,
        targetAmount,
        targetAchieved,
      );
}

/// {@template admin_kpi_summary}
/// Plasiyer KPI özeti — SQLite COUNT / SUM aggregate + snapshot + pivot.
///
/// Tutarlar yerel tablolardan display-only; muhasebe formülü uydurulmaz.
///
/// Kullanım örneği:
/// ```dart
/// const summary = AdminKpiSummary(
///   orderCount: 3,
///   invoiceCount: 2,
///   collectionCount: 1,
///   visitCount: 5,
/// );
/// ```
/// {@endtemplate}
class AdminKpiSummary {
  /// [orderCount]: Dönem sipariş adedi (iptaller hariç)
  final int orderCount;

  /// [invoiceCount]: Dönem fatura adedi (iptaller hariç)
  final int invoiceCount;

  /// [collectionCount]: Dönem tahsilat adedi (iptaller hariç)
  final int collectionCount;

  /// [visitCount]: Dönem ziyaret adedi
  final int visitCount;

  /// [waybillCount]: Dönem irsaliye adedi (iptaller hariç)
  final int waybillCount;

  /// [salesAmount]: Dönem fatura tutarı toplamı (iptal hariç)
  final double salesAmount;

  /// [orderAmount]: Dönem sipariş tutarı toplamı
  final double orderAmount;

  /// [collectionAmount]: Dönem tahsilat tutarı toplamı
  final double collectionAmount;

  /// [cashCollected]: Dönem nakit (`payment_type = Cash`) tahsilat
  final double cashCollected;

  /// [checkCollected]: Dönem çek tahsilat tutarı
  final double checkCollected;

  /// [bankSnapshot]: Dönem kart tahsilat + banka yatırma toplamı
  final double bankSnapshot;

  /// [openReceivables]: Pozitif cari bakiye toplamı (display)
  final double openReceivables;

  /// [debtorCount]: Bakiyesi > 0 cari adedi (risk ipucu)
  final int debtorCount;

  /// [pendingOrderCount]: Sync bekleyen sipariş (`is_synced = 0`)
  final int pendingOrderCount;

  /// [pendingInvoiceCount]: Sync bekleyen fatura
  final int pendingInvoiceCount;

  /// [pendingWaybillCount]: Sync bekleyen irsaliye
  final int pendingWaybillCount;

  /// [targetAmount]: Dönem satış hedefi toplamı
  final double targetAmount;

  /// [targetAchieved]: Dönem hedef gerçekleşen toplamı
  final double targetAchieved;

  /// [activeSalespersonCount]: Dönemde aktif plasiyer (ziyaret+tahsilat)
  final int activeSalespersonCount;

  /// [sparklineSales]: Son 7 gün günlük satış tutarları (eski → yeni)
  final List<double> sparklineSales;

  /// [sparklineCollections]: Son 7 gün günlük tahsilat tutarları
  final List<double> sparklineCollections;

  /// [pivotRows]: Plasiyer × metrik dens pivot
  final List<AdminKpiPivotRow> pivotRows;

  /// {@macro admin_kpi_summary}
  const AdminKpiSummary({
    required this.orderCount,
    required this.invoiceCount,
    required this.collectionCount,
    required this.visitCount,
    this.waybillCount = 0,
    this.salesAmount = 0,
    this.orderAmount = 0,
    this.collectionAmount = 0,
    this.cashCollected = 0,
    this.checkCollected = 0,
    this.bankSnapshot = 0,
    this.openReceivables = 0,
    this.debtorCount = 0,
    this.pendingOrderCount = 0,
    this.pendingInvoiceCount = 0,
    this.pendingWaybillCount = 0,
    this.targetAmount = 0,
    this.targetAchieved = 0,
    this.activeSalespersonCount = 0,
    this.sparklineSales = const <double>[],
    this.sparklineCollections = const <double>[],
    this.pivotRows = const <AdminKpiPivotRow>[],
  });

  /// [zero]: Boş / yüklenemeyen özet
  static const AdminKpiSummary zero = AdminKpiSummary(
    orderCount: 0,
    invoiceCount: 0,
    collectionCount: 0,
    visitCount: 0,
  );

  /// [pendingTransferTotal]: Sync bekleyen belge toplamı
  int get pendingTransferTotal =>
      pendingOrderCount + pendingInvoiceCount + pendingWaybillCount;

  /// [targetPct]: Firma geneli hedef gerçekleşme (0–100+)
  double get targetPct {
    if (targetAmount <= 0) return 0;
    return (targetAchieved / targetAmount) * 100;
  }

  /// AI insight için kompakt satır map’leri.
  List<Map<String, String>> toInsightRows() {
    final rows = <Map<String, String>>[
      {
        'metric': 'visits',
        'value': '$visitCount',
      },
      {
        'metric': 'orders',
        'value': '$orderCount',
        'amount': orderAmount.toStringAsFixed(2),
      },
      {
        'metric': 'invoices',
        'value': '$invoiceCount',
        'amount': salesAmount.toStringAsFixed(2),
      },
      {
        'metric': 'collections',
        'value': '$collectionCount',
        'amount': collectionAmount.toStringAsFixed(2),
      },
      {
        'metric': 'waybills',
        'value': '$waybillCount',
      },
      {
        'metric': 'cash',
        'amount': cashCollected.toStringAsFixed(2),
      },
      {
        'metric': 'check',
        'amount': checkCollected.toStringAsFixed(2),
      },
      {
        'metric': 'bank',
        'amount': bankSnapshot.toStringAsFixed(2),
      },
      {
        'metric': 'receivables',
        'amount': openReceivables.toStringAsFixed(2),
        'debtors': '$debtorCount',
      },
      {
        'metric': 'target',
        'amount': targetAmount.toStringAsFixed(2),
        'achieved': targetAchieved.toStringAsFixed(2),
        'pct': targetPct.toStringAsFixed(1),
      },
      {
        'metric': 'pending_transfer',
        'value': '$pendingTransferTotal',
      },
      {
        'metric': 'active_salespersons',
        'value': '$activeSalespersonCount',
      },
    ];
    for (final p in pivotRows.take(12)) {
      rows.add(p.toInsightMap());
    }
    return rows;
  }

  @override
  bool operator ==(Object other) {
    if (other is! AdminKpiSummary) return false;
    if (other.orderCount != orderCount ||
        other.invoiceCount != invoiceCount ||
        other.collectionCount != collectionCount ||
        other.visitCount != visitCount ||
        other.waybillCount != waybillCount ||
        other.salesAmount != salesAmount ||
        other.orderAmount != orderAmount ||
        other.collectionAmount != collectionAmount ||
        other.cashCollected != cashCollected ||
        other.checkCollected != checkCollected ||
        other.bankSnapshot != bankSnapshot ||
        other.openReceivables != openReceivables ||
        other.debtorCount != debtorCount ||
        other.pendingOrderCount != pendingOrderCount ||
        other.pendingInvoiceCount != pendingInvoiceCount ||
        other.pendingWaybillCount != pendingWaybillCount ||
        other.targetAmount != targetAmount ||
        other.targetAchieved != targetAchieved ||
        other.activeSalespersonCount != activeSalespersonCount) {
      return false;
    }
    if (other.sparklineSales.length != sparklineSales.length) return false;
    for (var i = 0; i < sparklineSales.length; i++) {
      if (other.sparklineSales[i] != sparklineSales[i]) return false;
    }
    if (other.sparklineCollections.length != sparklineCollections.length) {
      return false;
    }
    for (var i = 0; i < sparklineCollections.length; i++) {
      if (other.sparklineCollections[i] != sparklineCollections[i]) {
        return false;
      }
    }
    if (other.pivotRows.length != pivotRows.length) return false;
    for (var i = 0; i < pivotRows.length; i++) {
      if (other.pivotRows[i] != pivotRows[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
        orderCount,
        invoiceCount,
        collectionCount,
        visitCount,
        waybillCount,
        salesAmount,
        orderAmount,
        collectionAmount,
        cashCollected,
        checkCollected,
        bankSnapshot,
        openReceivables,
        debtorCount,
        pendingOrderCount,
        pendingInvoiceCount,
        pendingWaybillCount,
        targetAmount,
        targetAchieved,
        activeSalespersonCount,
        Object.hashAll(sparklineSales),
        Object.hashAll(sparklineCollections),
        Object.hashAll(pivotRows),
      ]);
}
