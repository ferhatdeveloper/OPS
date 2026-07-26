// Dosya Adı: check_list_row.dart
// Açıklama: Çek Listesi dens satırı — collections check tipi eşlemesi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'check_list_status.dart';
import 'collection_model.dart';
import 'finance_movement_type.dart';

/// {@template check_list_row}
/// Çek dens satırı — yalnızca `payment_type=check` collections.
///
/// Kullanım örneği:
/// ```dart
/// final row = CheckListRow.fromCollection(collection);
/// ```
/// {@endtemplate}
class CheckListRow {
  /// [id]: collections.id
  final String id;

  /// [customerId]: Cari kimliği
  final String customerId;

  /// [customerName]: Opsiyonel cari ünvan
  final String? customerName;

  /// [amount]: Tutar
  final double amount;

  /// [paymentType]: API/storage tipi (check)
  final String paymentType;

  /// [collectionDate]: Tahsilat / fiş tarihi
  final DateTime collectionDate;

  /// [checkNumber]: Çek numarası
  final String checkNumber;

  /// [bankName]: Banka
  final String? bankName;

  /// [branchName]: Şube
  final String? branchName;

  /// [dueDate]: Vade
  final DateTime? dueDate;

  /// [documentNo]: Evrak no
  final String? documentNo;

  /// [originalDebtor]: Asıl borçlu
  final String? originalDebtor;

  /// [endorsement]: Ciro
  final String? endorsement;

  /// [status]: MBT dens durum sekmesi
  final CheckListStatus status;

  /// {@macro check_list_row}
  const CheckListRow({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.paymentType,
    required this.collectionDate,
    required this.checkNumber,
    this.customerName,
    this.bankName,
    this.branchName,
    this.dueDate,
    this.documentNo,
    this.originalDebtor,
    this.endorsement,
    this.status = CheckListStatus.collection,
  });

  /// {@template check_list_row_is_check_payment_type}
  /// Ödeme tipi çek mi (FinanceMovementType.checkCollection).
  /// {@endtemplate}
  static bool isCheckPaymentType(String? raw) {
    return FinanceMovementType.fromStorage(raw).isCheck;
  }

  /// {@template check_list_row_from_collection}
  /// CollectionModel → dens satır; check değilse null.
  /// {@endtemplate}
  static CheckListRow? fromCollection(CollectionModel model) {
    if (!isCheckPaymentType(model.paymentType)) return null;
    return CheckListRow(
      id: model.id,
      customerId: model.customerId,
      amount: model.amount,
      paymentType: FinanceMovementType.checkCollection.apiCode,
      collectionDate: model.collectionDate,
      checkNumber: (model.checkNumber ?? '').trim(),
      bankName: model.bankName,
      branchName: model.branchName,
      dueDate: model.dueDate,
      documentNo: model.documentNo,
      originalDebtor: model.originalDebtor,
      endorsement: model.endorsement,
      status: CheckListStatus.fromCode(model.checkStatus),
    );
  }

  /// {@template check_list_row_from_collections}
  /// Liste içinden yalnızca check tipi dens satırları.
  /// {@endtemplate}
  static List<CheckListRow> fromCollections(List<CollectionModel> models) {
    final out = <CheckListRow>[];
    for (final m in models) {
      final row = fromCollection(m);
      if (row != null) out.add(row);
    }
    return out;
  }

  /// {@template check_list_row_from_map}
  /// SQLite / seed map → dens satır; check değilse null.
  /// {@endtemplate}
  static CheckListRow? fromMap(Map<String, dynamic> map) {
    final paymentType = (map['payment_type'] ?? '').toString();
    if (!isCheckPaymentType(paymentType)) return null;

    DateTime parseDate(dynamic v, {DateTime? fallback}) {
      if (v is DateTime) return v;
      final s = (v ?? '').toString().trim();
      if (s.isEmpty) {
        return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
      return DateTime.tryParse(s) ??
          fallback ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return CheckListRow(
      id: (map['id'] ?? '').toString(),
      customerId: (map['customer_id'] ?? '').toString(),
      customerName: map['customer_name']?.toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paymentType: FinanceMovementType.checkCollection.apiCode,
      collectionDate: parseDate(map['collection_date']),
      checkNumber: (map['check_number'] ?? '').toString().trim(),
      bankName: map['bank_name']?.toString(),
      branchName: map['branch_name']?.toString(),
      dueDate: map['due_date'] == null ||
              (map['due_date']?.toString().trim().isEmpty ?? true)
          ? null
          : parseDate(map['due_date']),
      documentNo: map['document_no']?.toString(),
      originalDebtor: map['original_debtor']?.toString(),
      endorsement: map['endorsement']?.toString(),
      status: CheckListStatus.fromCode(map['check_status']?.toString()),
    );
  }

  /// {@template check_list_row_to_map}
  /// SQLite insert map (payment_type=check + check_status).
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'amount': amount,
      'payment_type': FinanceMovementType.checkCollection.apiCode,
      'collection_date': collectionDate.toIso8601String(),
      'check_number': checkNumber,
      'bank_name': bankName,
      'branch_name': branchName,
      'due_date': dueDate?.toIso8601String(),
      'document_no': documentNo,
      'original_debtor': originalDebtor,
      'endorsement': endorsement,
      'check_status': status.code,
    };
  }

  /// {@template check_list_row_matches_search}
  /// Ara kutusu eşleşmesi (çek no · banka · cari · evrak).
  /// {@endtemplate}
  bool matchesSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final blob = [
      checkNumber,
      bankName,
      branchName,
      customerId,
      customerName,
      documentNo,
      originalDebtor,
      endorsement,
    ].whereType<String>().join(' ').toLowerCase();
    return blob.contains(q);
  }

  /// {@template check_list_row_filter}
  /// Durum sekmesi + arama süzgeci.
  /// {@endtemplate}
  static List<CheckListRow> filter(
    List<CheckListRow> rows, {
    required CheckListStatus status,
    String query = '',
  }) {
    return rows
        .where((r) => r.status == status && r.matchesSearch(query))
        .toList(growable: false);
  }

  /// {@template check_list_row_total_amount}
  /// Filtrelenmiş satırların toplam tutarı.
  /// {@endtemplate}
  static double totalAmount(List<CheckListRow> rows) {
    var sum = 0.0;
    for (final r in rows) {
      sum += r.amount;
    }
    return sum;
  }

  /// {@template check_list_row_format_amount}
  /// TR dens tutar metni (1.250,50).
  /// {@endtemplate}
  static String formatAmount(double amount) {
    final negative = amount < 0;
    final abs = amount.abs();
    final whole = abs.floor();
    final frac = ((abs - whole) * 100).round().clamp(0, 99);
    final wholeStr = _groupThousands(whole);
    final fracStr = frac.toString().padLeft(2, '0');
    final formatted = '$wholeStr,$fracStr';
    return negative ? '-$formatted' : formatted;
  }

  /// {@template check_list_row_group_thousands}
  /// Binlik ayırıcı (nokta).
  /// {@endtemplate}
  static String _groupThousands(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buf.write('.');
      }
    }
    return buf.toString();
  }
}
