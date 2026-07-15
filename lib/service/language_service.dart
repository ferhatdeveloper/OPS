import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/localization/app_localization.dart'
    hide localeProvider; // Çakışmayı önlemek için gizle
import 'database_service.dart';
import 'package:translator/translator.dart';

class LanguageModel {
  final String code;
  final String name;
  final String localName;
  final bool isRtl;

  const LanguageModel({
    required this.code,
    required this.name,
    required this.localName,
    this.isRtl = false,
  });
}

class LanguageService {
  static const String _languageKey = 'selected_language';

  // Desteklenen dil listesi: TR, EN, AR, KU (Sorani), FA
  static final List<LanguageModel> supportedLanguages = [
    const LanguageModel(code: 'tr', name: 'Turkish', localName: 'Türkçe'),
    const LanguageModel(code: 'en', name: 'English', localName: 'English'),
    const LanguageModel(code: 'de', name: 'German', localName: 'Deutsch'),
    const LanguageModel(code: 'fr', name: 'French', localName: 'Français'),
    const LanguageModel(code: 'es', name: 'Spanish', localName: 'Español'),
    const LanguageModel(code: 'ru', name: 'Russian', localName: 'Русский'),
    const LanguageModel(code: 'zh', name: 'Chinese', localName: '中文'),
    const LanguageModel(
      code: 'ar',
      name: 'Arabic',
      localName: 'العربية',
      isRtl: true,
    ),
    const LanguageModel(
      code: 'ku',
      name: 'Kurdish (Sorani)',
      localName: 'کوردیی ناوەندی',
      isRtl: true,
    ),
    const LanguageModel(
      code: 'fa',
      name: 'Persian',
      localName: 'فارسی',
      isRtl: true,
    ),
  ];

  // Dil tablosu başlatma
  static Future<void> initializeLanguageTables() async {
    try {
      final String? currentLanguage = await getLanguagePreference();
      if (currentLanguage == null) {
        await saveLanguagePreference('tr'); // Varsayılan dil: Türkçe
      }
    } catch (e) {
      print('Language tables initialization error: $e');
    }
  }

  // Dil tercihini kaydet
  static Future<bool> setLanguagePreference(String languageCode) async {
    return await saveLanguagePreference(languageCode);
  }

  // Dil tercihini al
  static Future<String> getLanguagePreference() async {
    final db = await DatabaseService.getInstance();
    final language = await db.getPreference(_languageKey);
    return language ?? 'tr'; // Varsayılan dil Türkçe
  }

  // Dil tercihi kaydet
  static Future<bool> saveLanguagePreference(String languageCode) async {
    try {
      // Dil kodu desteklenen diller listesinde mi kontrol et
      bool isSupported = supportedLanguageFiles.containsKey(languageCode);

      if (!isSupported) {
        print(
          'Seçilen dil ($languageCode) desteklenmiyor, varsayılan dile dönülüyor',
        );
        languageCode = 'tr'; // Desteklenmeyen dil seçilmiş, Türkçe'ye dön
      }

      // Dil dosyasının varlığını kontrol et
      bool fileExists = await doesLanguageFileExist(
        supportedLanguageFiles[languageCode] ?? 'tr',
      );

      if (!fileExists) {
        print(
          'Dil dosyası bulunamadı: $languageCode, varsayılan dile dönülüyor',
        );
        languageCode = 'tr'; // Dil dosyası bulunamadı, Türkçe'ye dön
      }

      // Dil ayarını kaydet
      final dbService = await DatabaseService.getInstance();
      await dbService.setSetting('selected_language', languageCode);
      print('SQLite setting saved: selected_language = $languageCode');
      return true;
    } catch (e) {
      print('Error saving language preference: $e');
      return false;
    }
  }

  // Dil kodu ile dil modelini bul
  static LanguageModel getLanguageByCode(String code) {
    try {
      return supportedLanguages.firstWhere(
        (lang) => lang.code == code,
        orElse: () => supportedLanguages.first, // Bulunamazsa ilk dil (Türkçe)
      );
    } catch (e) {
      print('Error finding language by code: $e');
      return supportedLanguages.first; // Hata durumunda ilk dil (Türkçe)
    }
  }

  // Get all translations for a specific key and target language
  static Future<Map<String, String>> getTranslationsForKey(
    String originalText,
    String sourceLanguage,
    List<String> targetLanguages,
  ) async {
    final dbService = await DatabaseService.getInstance();
    final translations = <String, String>{};

    // Check if translation already exists in the database
    final existingTranslations = await dbService.getTranslationsForText(
      originalText,
      targetLanguages,
    );

    // Find which languages need translation
    final languagesToTranslate =
        targetLanguages
            .where((lang) => !existingTranslations.containsKey(lang))
            .toList();

    // Add existing translations
    translations.addAll(existingTranslations);

    // If we have all translations, return them
    if (languagesToTranslate.isEmpty) {
      return translations;
    }

    // Otherwise, fetch missing translations
    final newTranslations = await _translateTexts(
      originalText,
      sourceLanguage,
      languagesToTranslate,
    );

    // Save new translations to database
    for (final entry in newTranslations.entries) {
      await dbService.saveTranslation(
        originalText: originalText,
        sourceLanguage: sourceLanguage,
        targetLanguage: entry.key,
        translatedText: entry.value,
      );
    }

    // Merge all translations
    translations.addAll(newTranslations);
    return translations;
  }

  // Translate a single text to multiple languages
  static Future<Map<String, String>> _translateTexts(
    String text,
    String sourceLanguage,
    List<String> targetLanguages,
  ) async {
    final result = <String, String>{};

    for (final targetLang in targetLanguages) {
      try {
        // Use GoogleTranslator for real-time translation
        final translation = await _callTranslationAPI(
          text,
          sourceLanguage,
          targetLang,
        );
        result[targetLang] = translation;
      } catch (e) {
        print('Translation error for $targetLang: $e');
        result[targetLang] = text;
      }
    }

    return result;
  }

  // Call translation API (Google Translator)
  static Future<String> _callTranslationAPI(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    try {
      // GoogleTranslator only supports generic 'ku' for Kurdish
      String googleTarget = targetLanguage;
      if (targetLanguage.startsWith('ku-')) {
        googleTarget = 'ku';
      }
      final translator = GoogleTranslator();
      final translation = await translator.translate(
        text,
        from: sourceLanguage,
        to: googleTarget,
      );
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return text; // Fallback to original text on error
    }
  }

  /// List all stored translations for an original text
  static Future<List<Map<String, dynamic>>> getStoredTranslations(
    String originalText,
  ) async {
    final dbService = await DatabaseService.getInstance();
    return await dbService.getAllTranslations(originalText);
  }

  /// Synchronous translation stub: returns original text until cache/API implemented
  static String translateSync(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) {
    // TODO: look up translation in SQLite cache
    return text;
  }
}

// Widget to make translations easy to use in the UI
class TranslatedText extends ConsumerWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TranslatedText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Doğrudan AppLocalization'ı kullanarak JSON dosyasından çeviriyi alır
    final translated = AppLocalization.of(context).translate(text);

    return Text(
      translated,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
