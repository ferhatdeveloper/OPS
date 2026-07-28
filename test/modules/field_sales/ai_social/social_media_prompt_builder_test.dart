// Dosya Adı: social_media_prompt_builder_test.dart
// Açıklama: Sosyal medya prompt builder + size preset unit testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/ai/clients/gemini_client.dart';
import 'package:exfin_ops/core/ai/clients/openai_compatible_client.dart';
import 'package:exfin_ops/core/ai/ai_provider.dart';
import 'package:exfin_ops/modules/field_sales/ai_social/engine/social_media_prompt_builder.dart';
import 'package:exfin_ops/modules/field_sales/ai_social/model/social_image_size_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SocialImageSizePreset', () {
    test('instagram kare 1080x1080 + api 1024x1024', () {
      const p = SocialImageSizePreset.instagramSquare;
      expect(p.width, 1080);
      expect(p.height, 1080);
      expect(p.apiSizeLabel, '1024x1024');
      expect(p.storageKey, 'instagram_square');
      expect(
        OpenAiCompatibleClient.mapApiSize(p.width, p.height),
        '1024x1024',
      );
    });

    test('story dikey 1080x1920 + api 1024x1792', () {
      const p = SocialImageSizePreset.storyVertical;
      expect(p.width, 1080);
      expect(p.height, 1920);
      expect(p.apiSizeLabel, '1024x1792');
      expect(
        OpenAiCompatibleClient.mapApiSize(p.width, p.height),
        '1024x1792',
      );
      expect(GeminiClient.mapAspectRatio(p.width, p.height), '9:16');
    });

    test('facebook 1200x630 + api 1792x1024', () {
      const p = SocialImageSizePreset.facebook;
      expect(p.width, 1200);
      expect(p.height, 630);
      expect(p.apiSizeLabel, '1792x1024');
      expect(
        OpenAiCompatibleClient.mapApiSize(p.width, p.height),
        '1792x1024',
      );
      expect(GeminiClient.mapAspectRatio(p.width, p.height), '16:9');
    });

    test('tryParse storageKey', () {
      expect(
        SocialImageSizePresetX.tryParse('story_vertical'),
        SocialImageSizePreset.storyVertical,
      );
      expect(SocialImageSizePresetX.tryParse('x'), isNull);
    });
  });

  group('SocialMediaPromptBuilder', () {
    test('seedAdCopy ürün + fiyat + birim', () {
      final seed = SocialMediaPromptBuilder.seedAdCopy(
        productName: 'Süt 1L',
        priceText: '45,00',
        unit: 'ADET',
      );
      expect(seed, contains('Süt 1L'));
      expect(seed, contains('45,00'));
      expect(seed, contains('ADET'));
    });

    test('buildImagePrompt preset + reklam metni içerir', () {
      const input = SocialMediaPromptInput(
        productName: 'Süt 1L',
        priceText: '45,00',
        unit: 'ADET',
        adCopy: 'Taze süt kampanyası!',
        preset: SocialImageSizePreset.instagramSquare,
        category: 'Gıda',
      );
      final prompt = SocialMediaPromptBuilder.buildImagePrompt(input);
      expect(prompt, contains('Süt 1L'));
      expect(prompt, contains('Taze süt kampanyası!'));
      expect(prompt, contains('1:1'));
      expect(prompt, contains('Gıda'));
      expect(prompt.toLowerCase(), contains('instagram'));
    });

    test('buildCopyUserPrompt alanları', () {
      const input = SocialMediaPromptInput(
        productName: 'X',
        priceText: '10',
        unit: 'KG',
        adCopy: '',
        preset: SocialImageSizePreset.facebook,
      );
      final u = SocialMediaPromptBuilder.buildCopyUserPrompt(input);
      expect(u, contains('Ürün: X'));
      expect(u, contains('Birim: KG'));
      expect(u.toLowerCase(), contains('facebook'));
    });
  });

  group('AiProvider image support', () {
    test('OpenAI Gemini OpenRouter destekler; Anthropic yok', () {
      expect(AiProvider.openAi.supportsImageGeneration, isTrue);
      expect(AiProvider.gemini.supportsImageGeneration, isTrue);
      expect(AiProvider.openRouter.supportsImageGeneration, isTrue);
      expect(AiProvider.anthropic.supportsImageGeneration, isFalse);
      expect(AiProvider.openAi.defaultImageModel, 'dall-e-3');
      expect(AiProvider.gemini.defaultImageModel, contains('imagen'));
    });
  });
}
