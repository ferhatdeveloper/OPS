// Dosya Adı: voucher_defaults_store.dart
// Açıklama: Fiş ön değerleri SharedPreferences load/save katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:shared_preferences/shared_preferences.dart';

import '../model/voucher_defaults_record.dart';

/// {@template voucher_defaults_store}
/// Fiş ön değerlerini SharedPreferences ile okur / yazar.
/// Sipariş, fatura ve irsaliye girişinde [VoucherDefaultsFields]
/// bu store üzerinden varsayılanları yükler.
///
/// Kullanım örneği:
/// ```dart
/// const store = VoucherDefaultsStore();
/// final record = await store.load();
/// await store.save(record);
/// ```
/// {@endtemplate}
class VoucherDefaultsStore {
  /// [prefsDescription]: Açıklama 1 anahtarı
  static const String prefsDescription = 'voucher_defaults_description';

  /// [prefsDescription2]: Açıklama 2 anahtarı
  static const String prefsDescription2 = 'voucher_defaults_description_2';

  /// [prefsPlateNo]: Plaka no anahtarı
  static const String prefsPlateNo = 'voucher_defaults_plate_no';

  /// [prefsSpecialCode1]: Özelkod 1 anahtarı
  static const String prefsSpecialCode1 = 'voucher_defaults_special_code_1';

  /// {@macro voucher_defaults_store}
  const VoucherDefaultsStore();

  /// {@template voucher_defaults_store_load}
  /// Yerel kayıtlı fiş ön değerlerini yükler.
  ///
  /// Dönüş değeri:
  /// - [VoucherDefaultsRecord]: Yüklenen değerler (yoksa boş)
  /// {@endtemplate}
  Future<VoucherDefaultsRecord> load() async {
    final prefs = await SharedPreferences.getInstance();
    return VoucherDefaultsRecord(
      description: prefs.getString(prefsDescription) ?? '',
      description2: prefs.getString(prefsDescription2) ?? '',
      plateNo: prefs.getString(prefsPlateNo) ?? '',
      specialCode1: prefs.getString(prefsSpecialCode1) ?? '',
    );
  }

  /// {@template voucher_defaults_store_save}
  /// Fiş ön değerlerini SharedPreferences'a yazar.
  ///
  /// Parametreler:
  /// - [record]: Kaydedilecek değerler
  /// {@endtemplate}
  Future<void> save(VoucherDefaultsRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsDescription, record.description.trim());
    await prefs.setString(prefsDescription2, record.description2.trim());
    await prefs.setString(prefsPlateNo, record.plateNo.trim());
    await prefs.setString(prefsSpecialCode1, record.specialCode1.trim());
  }
}
