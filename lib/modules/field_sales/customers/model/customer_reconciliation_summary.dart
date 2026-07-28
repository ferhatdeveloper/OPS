// Dosya Adı: customer_reconciliation_summary.dart
// Açıklama: Cari mutabakat dönem özeti (açılış / borç / alacak / kapanış)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template customer_reconciliation_summary}
/// Cari mutabakat dens özeti — dönem öncesi bakiye + dönem hareketleri.
///
/// Kullanım örneği:
/// ```dart
/// const s = CustomerReconciliationSummary(
///   openingBalance: 100,
///   periodDebit: 50,
///   periodCredit: 20,
///   movementCount: 3,
/// );
/// s.closingBalance; // 130
/// ```
/// {@endtemplate}
class CustomerReconciliationSummary {
  /// [openingBalance]: Dönem başı bakiye (borç − alacak)
  final double openingBalance;

  /// [periodDebit]: Dönem toplam borç
  final double periodDebit;

  /// [periodCredit]: Dönem toplam alacak
  final double periodCredit;

  /// [movementCount]: Dönem hareket adedi
  final int movementCount;

  /// {@macro customer_reconciliation_summary}
  const CustomerReconciliationSummary({
    this.openingBalance = 0,
    this.periodDebit = 0,
    this.periodCredit = 0,
    this.movementCount = 0,
  });

  /// {@template customer_reconciliation_closing}
  /// Kapanış bakiyesi = açılış + borç − alacak.
  /// {@endtemplate}
  double get closingBalance =>
      openingBalance + periodDebit - periodCredit;

  /// {@template customer_reconciliation_net}
  /// Dönem net (borç − alacak).
  /// {@endtemplate}
  double get periodNet => periodDebit - periodCredit;

  /// {@template customer_reconciliation_empty}
  /// Boş özet sabitı.
  /// {@endtemplate}
  static const CustomerReconciliationSummary empty =
      CustomerReconciliationSummary();
}
