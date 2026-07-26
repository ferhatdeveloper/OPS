// Dosya Adı: currency_rate_store.dart
// Açıklama: Döviz kuru SharedPreferences load/save katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/currency_rate_record.dart';
import '../model/currency_rate_seed.dart';

/// {@template currency_rate_store}
/// Döviz kurlarını SharedPreferences ile okur / yazar.
///
/// Kullanım örneği:
/// ```dart
/// const store = CurrencyRateStore();
/// final record = await store.load();
/// await store.save(record);
/// ```
/// {@endtemplate}
class CurrencyRateStore {
  /// [prefsDate]: Kur tarihi anahtarı (`yyyy-MM-dd`)
  static const String prefsDate = 'currency_rates_date';

  /// [prefsRates]: Kod→kur JSON haritası anahtarı
  static const String prefsRates = 'currency_rates_map';

  /// {@macro currency_rate_store}
  const CurrencyRateStore();

  /// {@template currency_rate_store_load}
  /// Yerel kayıtlı kurları yükler; yoksa seed varsayılanları döner.
  /// Eksik kodlar seed ile tamamlanır.
  ///
  /// Dönüş değeri:
  /// - [CurrencyRateRecord]: Yüklenen veya varsayılan kayıt
  /// {@endtemplate}
  Future<CurrencyRateRecord> load() async {
    final prefs = await SharedPreferences.getInstance();
    final dateRaw = prefs.getString(prefsDate);
    final ratesRaw = prefs.getString(prefsRates);

    if (dateRaw == null && ratesRaw == null) {
      return CurrencyRateRecord.defaults();
    }

    final defaults = CurrencyRateRecord.defaults(
      rateDate: _parseDate(dateRaw) ?? DateTime.now(),
    );
    final saved = _parseRates(ratesRaw);
    final merged = <String, String>{
      ...defaults.rates,
      ...saved,
    };
    return CurrencyRateRecord(
      rateDate: defaults.rateDate,
      rates: merged,
    );
  }

  /// {@template currency_rate_store_save}
  /// Kur tarihini ve satırları SharedPreferences'a yazar.
  ///
  /// Parametreler:
  /// - [record]: Kaydedilecek kur kaydı
  /// {@endtemplate}
  Future<void> save(CurrencyRateRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = <String, String>{};
    for (final code in CurrencyRateSeed.codes) {
      final value = (record.rates[code] ?? '').trim();
      trimmed[code] = value;
    }
    await prefs.setString(prefsDate, _formatDate(record.rateDate));
    await prefs.setString(prefsRates, jsonEncode(trimmed));
  }

  /// {@template currency_rate_store_format_date}
  /// Tarihi `yyyy-MM-dd` olarak biçimlendirir.
  /// {@endtemplate}
  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// {@template currency_rate_store_parse_date}
  /// `yyyy-MM-dd` veya ISO-8601 dizesini DateTime'a çevirir.
  /// {@endtemplate}
  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final iso = DateTime.tryParse(raw);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }
    return null;
  }

  /// {@template currency_rate_store_parse_rates}
  /// JSON haritasını kod→kur map'ine çevirir.
  /// {@endtemplate}
  Map<String, String> _parseRates(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final out = <String, String>{};
      decoded.forEach((key, value) {
        if (key is String) {
          out[key] = value?.toString() ?? '';
        }
      });
      return out;
    } catch (_) {
      return const {};
    }
  }
}
