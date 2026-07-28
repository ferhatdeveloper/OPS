// Dosya Adı: report_pdf_fonts.dart
// Açıklama: Rapor PDF Unicode fontları (TR Latin + Arapça / Soranice)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/localization/app_localization.dart';

/// {@template report_pdf_fonts}
/// MBT rapor PDF’leri için gömülü Unicode font teması.
///
/// - [NotoSans]: Türkçe / Latin (Ş İ ğ ü ö ç ı …)
/// - [NotoSansArabic]: Arapça + Soranice (کوردی) + Farsça glifleri
///
/// Kullanım örneği:
/// ```dart
/// final theme = await ReportPdfFonts.loadTheme();
/// final dir = ReportPdfFonts.textDirectionFor('ku');
/// ```
/// {@endtemplate}
class ReportPdfFonts {
  /// [regularAsset]: Latin regular TTF
  static const String regularAsset =
      'assets/fonts/NotoSans-Regular.ttf';

  /// [boldAsset]: Latin bold TTF
  static const String boldAsset = 'assets/fonts/NotoSans-Bold.ttf';

  /// [arabicRegularAsset]: Arapça / Soranice regular
  static const String arabicRegularAsset =
      'assets/fonts/NotoSansArabic-Regular.ttf';

  /// [arabicBoldAsset]: Arapça / Soranice bold
  static const String arabicBoldAsset =
      'assets/fonts/NotoSansArabic-Bold.ttf';

  static pw.ThemeData? _cachedTheme;

  /// {@template report_pdf_fonts_load_theme}
  /// Noto Sans + Noto Sans Arabic fallback ile ThemeData üretir.
  ///
  /// Dönüş değeri:
  /// - [pw.ThemeData]: Tüm PDF metinleri için Unicode tema
  /// {@endtemplate}
  static Future<pw.ThemeData> loadTheme() async {
    final cached = _cachedTheme;
    if (cached != null) return cached;

    final base = pw.Font.ttf(
      await rootBundle.load(regularAsset),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load(boldAsset),
    );
    final arabic = pw.Font.ttf(
      await rootBundle.load(arabicRegularAsset),
    );
    final arabicBold = pw.Font.ttf(
      await rootBundle.load(arabicBoldAsset),
    );

    final theme = pw.ThemeData.withFont(
      base: base,
      bold: bold,
      fontFallback: [arabic, arabicBold],
    );
    _cachedTheme = theme;
    return theme;
  }

  /// {@template report_pdf_fonts_text_direction}
  /// Dil koduna göre PDF metin yönü (ar / ku / ckb / fa → RTL).
  ///
  /// Parametreler:
  /// - [languageCode]: Uygulama dil kodu (null → LTR)
  ///
  /// Dönüş değeri:
  /// - [pw.TextDirection]: ltr veya rtl
  /// {@endtemplate}
  static pw.TextDirection textDirectionFor(String? languageCode) {
    final code = (languageCode ?? '').toLowerCase().trim();
    if (code.isEmpty) return pw.TextDirection.ltr;
    final primary = code.contains('-') ? code.split('-').first : code;
    if (AppLocalization.isRtl(primary)) {
      return pw.TextDirection.rtl;
    }
    return pw.TextDirection.ltr;
  }

  /// {@template report_pdf_fonts_reset_cache}
  /// Test için tema önbelleğini temizler.
  /// {@endtemplate}
  static void resetCacheForTest() {
    _cachedTheme = null;
  }
}
