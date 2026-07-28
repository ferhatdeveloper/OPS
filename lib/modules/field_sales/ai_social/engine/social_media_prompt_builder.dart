// Dosya Adı: social_media_prompt_builder.dart
// Açıklama: Ürün → sosyal medya reklam metni / görsel prompt üretici
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../model/social_image_size_preset.dart';

/// {@template social_media_prompt_input}
/// Prompt builder girdi alanları.
/// {@endtemplate}
class SocialMediaPromptInput {
  /// [productName]: Ürün adı
  final String productName;

  /// [priceText]: Biçimli fiyat
  final String priceText;

  /// [unit]: Birim
  final String unit;

  /// [adCopy]: Kullanıcı onaylı reklam metni
  final String adCopy;

  /// [preset]: Boyut preset
  final SocialImageSizePreset preset;

  /// [currency]: Para birimi etiketi
  final String currency;

  /// [category]: Opsiyonel kategori
  final String category;

  /// [productImageUrl]: Ürün görseli URL (provider destekliyorsa referans)
  final String productImageUrl;

  /// {@macro social_media_prompt_input}
  const SocialMediaPromptInput({
    required this.productName,
    required this.priceText,
    required this.unit,
    required this.adCopy,
    required this.preset,
    this.currency = 'TRY',
    this.category = '',
    this.productImageUrl = '',
  });
}

/// {@template social_media_prompt_builder}
/// Offline-safe prompt / seed metin üretici (AI key gerekmez).
///
/// Kullanım örneği:
/// ```dart
/// final p = SocialMediaPromptBuilder.buildImagePrompt(input);
/// ```
/// {@endtemplate}
class SocialMediaPromptBuilder {
  SocialMediaPromptBuilder._();

  /// {@template social_media_prompt_builder_seed_copy}
  /// Kullanıcı düzenleyebileceği başlangıç reklam metni.
  ///
  /// Parametreler:
  /// - [productName]: Ürün
  /// - [priceText]: Fiyat
  /// - [unit]: Birim
  ///
  /// Dönüş değeri:
  /// - [String]: Seed reklam metni
  /// {@endtemplate}
  static String seedAdCopy({
    required String productName,
    required String priceText,
    required String unit,
    String currency = 'TRY',
  }) {
    final name = productName.trim().isEmpty ? 'Ürün' : productName.trim();
    final price = priceText.trim().isEmpty ? '—' : priceText.trim();
    final u = unit.trim().isEmpty ? 'ADET' : unit.trim();
    return '$name — $price $currency / $u. Hemen sipariş verin!';
  }

  /// {@template social_media_prompt_builder_copy_system}
  /// AI reklam metni system prompt.
  /// {@endtemplate}
  static String copySystemPrompt() {
    return 'Sen saha satış sosyal medya asistanısın. '
        'Kısa, ikna edici Türkçe reklam metni yaz (max 2 cümle). '
        'Emoji az kullan. Fiyatı ve birimi koru. Yalnız metin döndür.';
  }

  /// {@template social_media_prompt_builder_copy_user}
  /// AI reklam metni user prompt.
  /// {@endtemplate}
  static String buildCopyUserPrompt(SocialMediaPromptInput input) {
    final cat = input.category.trim();
    final buf = StringBuffer()
      ..writeln('Ürün: ${input.productName.trim()}')
      ..writeln('Fiyat: ${input.priceText.trim()} ${input.currency}')
      ..writeln('Birim: ${input.unit.trim()}');
    if (cat.isNotEmpty) {
      buf.writeln('Kategori: $cat');
    }
    buf.writeln('Format: ${input.preset.promptFormatHint}');
    return buf.toString().trim();
  }

  /// {@template social_media_prompt_builder_image}
  /// Görsel üretim promptu (ürün + onaylı metin + format).
  ///
  /// Parametreler:
  /// - [input]: Ürün + metin + preset
  ///
  /// Dönüş değeri:
  /// - [String]: Image gen prompt (EN görsel dil + TR ürün bilgisi)
  /// {@endtemplate}
  static String buildImagePrompt(SocialMediaPromptInput input) {
    final name = input.productName.trim().isEmpty
        ? 'product'
        : input.productName.trim();
    final copy = input.adCopy.trim().isEmpty
        ? seedAdCopy(
            productName: name,
            priceText: input.priceText,
            unit: input.unit,
            currency: input.currency,
          )
        : input.adCopy.trim();
    final buf = StringBuffer()
      ..writeln(
        'Professional product social media advertisement, clean commercial photo,',
      )
      ..writeln(input.preset.promptFormatHint)
      ..writeln('Product name: $name')
      ..writeln(
        'Price label: ${input.priceText.trim()} ${input.currency} / '
        '${input.unit.trim()}',
      )
      ..writeln('Headline / caption to include visually: $copy')
      ..writeln(
        'High quality, readable typography overlay, brand-safe colors, '
        'no watermark, no logo invent.',
      );
    final cat = input.category.trim();
    if (cat.isNotEmpty) {
      buf.writeln('Category context: $cat');
    }
    final img = input.productImageUrl.trim();
    if (img.isNotEmpty) {
      buf.writeln('Use this product photo as visual reference: $img');
    }
    return buf.toString().trim();
  }
}
