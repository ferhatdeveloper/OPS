import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Çeviri işlemlerinin tamamlanıp tamamlanmadığını izlemek için
final translationsLoadedProvider = StateProvider<bool>((ref) => false);

// Dil sağlayıcı
final appLocalizationProvider = Provider<AppLocalization>((ref) {
  final locale = ref.watch(localeProvider);
  final appLocalization = AppLocalization(locale);

  // Çevirileri proaktif olarak yükle
  Future.microtask(() async {
    final success = await appLocalization.load();
    ref.read(translationsLoadedProvider.notifier).state = success;
  });

  return appLocalization;
});

// Dil sağlayıcı notifier
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('tr', 'TR')); // Türkçe varsayılan

  void setLocale(Locale locale) {
    state = locale;
  }
}

// Loglama yardımcı fonksiyonu
void debugLog(String message) {
  // ignore: avoid_print
  print(message);
}

// Desteklenen diller ve dosya isimleri
// TR, EN, AR, KU (Sorani), FA
final Map<String, String> supportedLanguageFiles = {
  'tr': 'tr',    // Türkçe
  'en': 'en',    // İngilizce
  'ar': 'ar',    // Arapça
  'ku': 'ku',    // Kürtçe Sorani
  'ckb': 'ku',   // Central Kurdish (BCP 47 kodu) → ku.json dosyasına yönlendir
  'fa': 'fa',    // Farsça
  'de': 'de',    // Almanca
  'fr': 'fr',    // Fransızca
  'es': 'es',    // İspanyolca
  'ru': 'ru',    // Rusça
  'zh': 'zh',    // Çince
  'ar-iq': 'ar-iq', // Irak Arapçası
};

// Dosya varlığını kontrol eden yardımcı fonksiyon
Future<bool> doesLanguageFileExist(String fileName) async {
  try {
    await rootBundle.load('assets/translations/$fileName.json');
    return true;
  } catch (e) {
    return false;
  }
}

class AppLocalization {
  final Locale locale;
  Map<String, dynamic> _localizedValues = {};
  Map<String, dynamic> _turkishValues = {};
  bool _isLoaded = false;
  static const String _fallbackLanguage = 'tr';

  AppLocalization(this.locale);

  static AppLocalization of(BuildContext context) {
    try {
      final loc = Localizations.of<AppLocalization>(context, AppLocalization);
      if (loc == null) {
        debugLog("WARNING: AppLocalization.of() returned null, using fallback");
        return AppLocalization(const Locale('tr', 'TR'));
      }
      return loc;
    } catch (e) {
      debugLog("ERROR in AppLocalization.of(): $e");
      return AppLocalization(const Locale('tr', 'TR'));
    }
  }

  Future<bool> load() async {
    try {
      // 1. Her zaman Türkçe (varsayılan) dosyasını yükle
      String fallbackPath = 'assets/translations/$_fallbackLanguage.json';
      try {
        String trJsonString = await rootBundle.loadString(fallbackPath);
        _turkishValues = json.decode(trJsonString);
      } catch (e) {
        debugLog('Kritik hata: Türkçe dil dosyası yüklenemedi: $e');
      }

      String langCode = locale.languageCode;
      String langKey = langCode;

      debugLog('Dil dosyası yükleniyor: $langKey');

      // Desteklenen dil dosyasını bul
      String? fileName = supportedLanguageFiles[langKey];
      
      // Eğer seçilen dil Türkçe ise veya desteklenmiyorsa sadece Türkçe kullan
      if (fileName == null || fileName == _fallbackLanguage) {
        _localizedValues = _turkishValues;
        _isLoaded = true;
        return true;
      }

      String filePath = 'assets/translations/$fileName.json';
      debugLog('Dosya yükleme denemesi: $filePath');

      try {
        String jsonString = await rootBundle.loadString(filePath);
        debugLog('Başarılı: $filePath');
        _localizedValues = json.decode(jsonString);
        _isLoaded = true;
        return true;
      } catch (e) {
        debugLog('Hata: $filePath - $e. Sadece Türkçe kullanılıyor.');
        _localizedValues = _turkishValues;
        _isLoaded = true;
        return true;
      }
    } catch (e) {
      debugLog('Dil dosyası yükleme hatası: $e');
      _isLoaded = false;
      return false;
    }
  }

  String translate(String key, {Map<String, String>? args}) {
    try {
      if (!_isLoaded) {
        return key;
      }

      List<String> keys = key.split('.');
      
      // Önce seçili dilde ara
      dynamic value = _getValueFromMap(_localizedValues, keys);
      
      // Bulunamazsa Türkçe (varsayılan) dilde ara
      if (value == null) {
        value = _getValueFromMap(_turkishValues, keys);
      }

      // Yine bulunamazsa anahtarı döndür
      if (value == null) {
        return key;
      }

      String translatedText = value.toString();
      if (args != null) {
        args.forEach((argKey, argValue) {
          translatedText = translatedText.replaceAll('{$argKey}', argValue);
        });
      }

      return translatedText;
    } catch (e) {
      return key;
    }
  }

  dynamic _getValueFromMap(Map<String, dynamic> map, List<String> keys) {
    dynamic value = map;
    for (String k in keys) {
      if (value is Map && value.containsKey(k)) {
        value = value[k];
      } else {
        return null;
      }
    }
    return value;
  }

  // Desteklenen locale listesi
  static List<Locale> supportedLocales() {
    return const [
      Locale('tr', 'TR'), // Türkçe
      Locale('en', 'US'), // İngilizce
      Locale('ar', 'SA'), // Arapça
      Locale('ku', 'IQ'), // Kürtçe Sorani (Irak Kürdistanı)
      Locale('ckb', ''),  // Central Kurdish (Sorani) - BCP 47
      Locale('fa', 'IR'), // Farsça (İran)
      Locale('de', 'DE'), // Almanca
      Locale('fr', 'FR'), // Fransızca
      Locale('es', 'ES'), // İspanyolca
      Locale('ru', 'RU'), // Rusça
      Locale('zh', 'CN'), // Çince
    ];
  }

  // RTL dil mi?
  static bool isRtl(String languageCode) {
    return ['ar', 'ku', 'ckb', 'fa'].contains(languageCode);
  }
}

// Delegate sınıfı
class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    return supportedLanguageFiles.containsKey(locale.languageCode);
  }

  @override
  Future<AppLocalization> load(Locale locale) async {
    await Future.delayed(const Duration(milliseconds: 100));
    AppLocalization localization = AppLocalization(locale);
    await localization.load();
    return localization;
  }

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}
