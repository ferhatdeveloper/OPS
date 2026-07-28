// Dosya Adı: promissory_list_row.dart
// Açıklama: Senet Listesi dens satırı (payment_type=note)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'promissory_list_status.dart';

/// {@template promissory_list_row}
/// Senet dens satırı — MBT Senet Listesi.
///
/// Kullanım örneği:
/// ```dart
/// final rows = PromissoryListRow.filter(source, status: s, query: q);
/// ```
/// {@endtemplate}
class PromissoryListRow {
  /// [id]: Yerel kimlik
  final String id;

  /// [customerId]: Cari kimliği
  final String customerId;

  /// [customerName]: Opsiyonel cari ünvan
  final String? customerName;

  /// [amount]: Tutar
  final double amount;

  /// [noteNumber]: Senet numarası
  final String noteNumber;

  /// [bankName]: Banka
  final String? bankName;

  /// [dueDate]: Vade
  final DateTime? dueDate;

  /// [documentNo]: Evrak no
  final String? documentNo;

  /// [status]: Dens durum sekmesi
  final PromissoryListStatus status;

  /// {@macro promissory_list_row}
  const PromissoryListRow({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.noteNumber,
    this.customerName,
    this.bankName,
    this.dueDate,
    this.documentNo,
    this.status = PromissoryListStatus.collection,
  });

  /// Durum + arama süzgeci.
  static List<PromissoryListRow> filter(
    List<PromissoryListRow> source, {
    required PromissoryListStatus status,
    String query = '',
  }) {
    final q = query.trim().toLowerCase();
    return source.where((r) {
      if (r.status != status) return false;
      if (q.isEmpty) return true;
      return r.noteNumber.toLowerCase().contains(q) ||
          (r.customerName ?? r.customerId).toLowerCase().contains(q) ||
          (r.bankName ?? '').toLowerCase().contains(q) ||
          (r.documentNo ?? '').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  /// Toplam tutar.
  static double totalAmount(List<PromissoryListRow> rows) {
    var sum = 0.0;
    for (final r in rows) {
      sum += r.amount;
    }
    return sum;
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
}
