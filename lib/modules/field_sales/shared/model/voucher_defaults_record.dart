// Dosya Adı: voucher_defaults_record.dart
// Açıklama: Fiş ön değerleri (açıklama, plaka, özelkod) veri modeli
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template voucher_defaults_record}
/// SharedPreferences'taki fiş ön değerleri.
///
/// Kullanım örneği:
/// ```dart
/// const record = VoucherDefaultsRecord(
///   description: 'Saha satış',
///   description2: '',
///   plateNo: '34ABC123',
///   specialCode1: 'OPS',
/// );
/// ```
/// {@endtemplate}
class VoucherDefaultsRecord {
  /// [description]: Açıklama 1
  final String description;

  /// [description2]: Açıklama 2 (ayarlar ekranı)
  final String description2;

  /// [plateNo]: Plaka no
  final String plateNo;

  /// [specialCode1]: Özelkod 1
  final String specialCode1;

  /// {@macro voucher_defaults_record}
  const VoucherDefaultsRecord({
    this.description = '',
    this.description2 = '',
    this.plateNo = '',
    this.specialCode1 = '',
  });
}
