// Dosya Adı: admin_kpi_summary.dart
// Açıklama: Yönetici KPI günlük özet modeli (sipariş/fatura/tahsilat/ziyaret)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template admin_kpi_summary}
/// Bugünkü plasiyer KPI sayıları (SQLite COUNT aggregate).
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
  /// [orderCount]: Bugünkü sipariş adedi (iptaller hariç)
  final int orderCount;

  /// [invoiceCount]: Bugünkü fatura adedi (iptaller hariç)
  final int invoiceCount;

  /// [collectionCount]: Bugünkü tahsilat adedi (iptaller hariç)
  final int collectionCount;

  /// [visitCount]: Bugünkü ziyaret adedi
  final int visitCount;

  /// {@macro admin_kpi_summary}
  const AdminKpiSummary({
    required this.orderCount,
    required this.invoiceCount,
    required this.collectionCount,
    required this.visitCount,
  });

  /// [zero]: Boş / yüklenemeyen özet
  static const AdminKpiSummary zero = AdminKpiSummary(
    orderCount: 0,
    invoiceCount: 0,
    collectionCount: 0,
    visitCount: 0,
  );

  @override
  bool operator ==(Object other) {
    return other is AdminKpiSummary &&
        other.orderCount == orderCount &&
        other.invoiceCount == invoiceCount &&
        other.collectionCount == collectionCount &&
        other.visitCount == visitCount;
  }

  @override
  int get hashCode => Object.hash(
        orderCount,
        invoiceCount,
        collectionCount,
        visitCount,
      );
}
