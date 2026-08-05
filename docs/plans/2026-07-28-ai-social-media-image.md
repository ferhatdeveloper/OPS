# AI Sosyal Medya Görsel Üretimi

**Tarih:** 2026-07-28  
**Durum:** Uygulandı (commit yok)

## Özet

Ürün detay / katalogdan dens aksiyon ile Instagram kare / Story dikey / Facebook
preset seçilerek AI reklam metni + görsel üretilir; paylaş / yerel kaydet.

## Mimari

| Parça | Yol |
|-------|-----|
| Use-case | `AiUseCase.socialMediaImage` |
| Image API | `AiGateway.generateImage` / `generateImageFor` |
| Modül | `lib/modules/field_sales/ai_social/` |
| Route | `/field-sales/social-media-image` |
| Giriş | `ProductDetailScreen` dens CTA + AppBar ikon |

## Provider image desteği

| Provider | Destek | Endpoint / model |
|----------|--------|------------------|
| OpenAI | Evet | `/v1/images/generations` · `dall-e-3` |
| Gemini | Evet | Imagen `:predict` · `imagen-4.0-generate-001` |
| OpenRouter | Evet | `/v1/images` · `google/gemini-2.5-flash-image` |
| Anthropic | Hayır | `AiImageStatus.unsupported` + l10n (OpenRouter/OpenAI fallback) |

Key / ağ yoksa: `noKey` / error — UI kırılmaz (seed metin + SnackBar/l10n).

## Test

- `test/modules/field_sales/ai_social/social_media_prompt_builder_test.dart`
- `test/core/ai/ai_image_generation_test.dart`
