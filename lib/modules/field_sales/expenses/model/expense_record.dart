// Dosya Adı: expense_record.dart
// Açıklama: Plasiyer günlük masraf kaydı (tip · tutar · not)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template expense_type}
/// Masraf tipi kodları (ExpenseService / SQLite `type`).
///
/// Kullanım örneği:
/// ```dart
/// final t = ExpenseType.fuel;
/// print(t.storageCode); // FUEL
/// ```
/// {@endtemplate}
enum ExpenseType {
  /// Yakıt
  fuel,

  /// Yemek
  food,

  /// Park
  parking,

  /// Diğer
  other,
}

/// {@template expense_type_x}
/// [ExpenseType] depolama / l10n yardımcıları.
/// {@endtemplate}
extension ExpenseTypeX on ExpenseType {
  /// [storageCode]: SQLite `type` değeri
  String get storageCode {
    switch (this) {
      case ExpenseType.fuel:
        return 'FUEL';
      case ExpenseType.food:
        return 'FOOD';
      case ExpenseType.parking:
        return 'PARKING';
      case ExpenseType.other:
        return 'OTHER';
    }
  }

  /// [labelKey]: Çeviri anahtarı
  String get labelKey {
    switch (this) {
      case ExpenseType.fuel:
        return 'field_sales.expense.type_fuel';
      case ExpenseType.food:
        return 'field_sales.expense.type_food';
      case ExpenseType.parking:
        return 'field_sales.expense.type_parking';
      case ExpenseType.other:
        return 'field_sales.expense.type_other';
    }
  }

  /// {@template expense_type_from_storage}
  /// Depolama kodundan tip üretir; bilinmeyen → [ExpenseType.other].
  /// {@endtemplate}
  static ExpenseType fromStorage(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'FUEL':
        return ExpenseType.fuel;
      case 'FOOD':
        return ExpenseType.food;
      case 'PARKING':
        return ExpenseType.parking;
      default:
        return ExpenseType.other;
    }
  }
}

/// {@template expense_record}
/// Offline-first masraf satırı.
///
/// Kullanım örneği:
/// ```dart
/// final r = ExpenseRecord(
///   id: 'e1',
///   type: ExpenseType.fuel,
///   amount: 100,
///   createdAt: DateTime.now(),
/// );
/// ```
/// {@endtemplate}
class ExpenseRecord {
  /// [id]: Yerel kimlik
  final String id;

  /// [type]: Masraf tipi
  final ExpenseType type;

  /// [amount]: Tutar
  final double amount;

  /// [photoPath]: Opsiyonel fiş foto yolu
  final String? photoPath;

  /// [note]: Açıklama
  final String? note;

  /// [createdAt]: Oluşturma zamanı
  final DateTime createdAt;

  /// [isSynced]: Merkeze aktarıldı mı
  final bool isSynced;

  /// {@macro expense_record}
  const ExpenseRecord({
    required this.id,
    required this.type,
    required this.amount,
    this.photoPath,
    this.note,
    required this.createdAt,
    this.isSynced = false,
  });

  /// {@template expense_record_parse_amount}
  /// TR / EN tutar metnini [double?] yapar.
  ///
  /// Parametreler:
  /// - [raw]: Kullanıcı girişi
  ///
  /// Dönüş değeri:
  /// - [double?]: Geçerli tutar veya null
  /// {@endtemplate}
  static double? parseAmount(String raw) {
    var t = raw.trim();
    if (t.isEmpty) return null;
    if (t.contains(',') && t.contains('.')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else if (t.contains(',')) {
      t = t.replaceAll(',', '.');
    }
    return double.tryParse(t);
  }

  /// {@template expense_record_from_map}
  /// SQLite satırından üretir.
  /// {@endtemplate}
  factory ExpenseRecord.fromMap(Map<String, dynamic> map) {
    return ExpenseRecord(
      id: map['id']?.toString() ?? '',
      type: ExpenseTypeX.fromStorage(map['type']?.toString()),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      photoPath: map['photo_path']?.toString(),
      note: map['note']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }

  /// {@template expense_record_to_map}
  /// SQLite insert map'i.
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.storageCode,
      'amount': amount,
      'photo_path': photoPath,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }
}
