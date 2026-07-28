// Dosya Adı: social_image_size_preset.dart
// Açıklama: Sosyal medya görsel boyut presetleri (IG / Story / FB)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template social_image_size_preset}
/// Platform boyut presetleri — dens chip seçimi.
///
/// Kullanım örneği:
/// ```dart
/// final p = SocialImageSizePreset.instagramSquare;
/// print('${p.width}x${p.height}'); // 1080x1080
/// ```
/// {@endtemplate}
enum SocialImageSizePreset {
  /// Instagram kare feed
  instagramSquare,

  /// Instagram / WhatsApp Story dikey
  storyVertical,

  /// Facebook / LinkedIn yatay
  facebook,
}

/// {@template social_image_size_preset_x}
/// Preset boyut ve l10n yardımcıları.
/// {@endtemplate}
extension SocialImageSizePresetX on SocialImageSizePreset {
  /// Hedef genişlik (px)
  int get width {
    switch (this) {
      case SocialImageSizePreset.instagramSquare:
        return 1080;
      case SocialImageSizePreset.storyVertical:
        return 1080;
      case SocialImageSizePreset.facebook:
        return 1200;
    }
  }

  /// Hedef yükseklik (px)
  int get height {
    switch (this) {
      case SocialImageSizePreset.instagramSquare:
        return 1080;
      case SocialImageSizePreset.storyVertical:
        return 1920;
      case SocialImageSizePreset.facebook:
        return 630;
    }
  }

  /// API’ye gönderilecek eşlenmiş boyut etiketi (DALL-E)
  String get apiSizeLabel {
    switch (this) {
      case SocialImageSizePreset.instagramSquare:
        return '1024x1024';
      case SocialImageSizePreset.storyVertical:
        return '1024x1792';
      case SocialImageSizePreset.facebook:
        return '1792x1024';
    }
  }

  /// Storage / test kimliği
  String get storageKey {
    switch (this) {
      case SocialImageSizePreset.instagramSquare:
        return 'instagram_square';
      case SocialImageSizePreset.storyVertical:
        return 'story_vertical';
      case SocialImageSizePreset.facebook:
        return 'facebook';
    }
  }

  /// l10n: `field_sales.ai_social.preset_<storageKey>`
  String get labelKey => 'field_sales.ai_social.preset_$storageKey';

  /// Prompt’a eklenecek format ipucu
  String get promptFormatHint {
    switch (this) {
      case SocialImageSizePreset.instagramSquare:
        return 'square Instagram feed post, 1:1 composition';
      case SocialImageSizePreset.storyVertical:
        return 'vertical Story format, 9:16, mobile-first';
      case SocialImageSizePreset.facebook:
        return 'horizontal Facebook cover/ad, ~1.91:1';
    }
  }

  /// [storageKey] → enum
  static SocialImageSizePreset? tryParse(String? raw) {
    final k = (raw ?? '').trim().toLowerCase();
    if (k.isEmpty) return null;
    for (final p in SocialImageSizePreset.values) {
      if (p.storageKey == k) return p;
    }
    return null;
  }
}
