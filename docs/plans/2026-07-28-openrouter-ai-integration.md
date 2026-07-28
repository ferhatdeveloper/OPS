// Dosya Adı: 2026-07-28-openrouter-ai-integration.md
// Plan: Çoklu AI sağlayıcı (OpenAI / Gemini / Claude / OpenRouter) + use-case
# Çoklu AI Entegrasyonu (OpenRouter + OpenAI + Gemini + Claude)

**Tarih:** 2026-07-28  
**Durum:** P0 gateway / settings / chat iskeleti / rapor insight hazır  
**Commit:** henüz yok (bilinçli)

## Hedef

Saha satış için ortak AI katmanı:

| Sağlayıcı | Base URL | Not |
|-----------|----------|-----|
| OpenAI | `https://api.openai.com/v1` | Chat Completions |
| Gemini | `https://generativelanguage.googleapis.com/v1beta` | generateContent |
| Anthropic | `https://api.anthropic.com` | Messages API |
| OpenRouter | `https://openrouter.ai/api/v1` | Tek key, çok model yedek |

## Mimari

```
AiSettingsStore (obfuscated SharedPreferences)
        │
   AiGateway.complete / completeFor(AiUseCase)
        │
   ┌────┴────┬──────────┬────────────┐
OpenAI   OpenRouter  Gemini     Anthropic
```

### Dosyalar

- `lib/core/ai/ai_provider.dart` — enum
- `lib/core/ai/ai_use_case.dart` — reportInsight, demandForecastInsight, replenishmentAdvice, voiceAssistant, …
- `lib/core/ai/ai_gateway.dart` — facade
- `lib/core/ai/ai_settings_store.dart` — key/model/use-case override
- `lib/core/ai/clients/*` — HTTP istemciler
- `lib/core/ai/openrouter_client.dart` — export
- `lib/core/ai/features/*` — rapor insight / öneri / sipariş köprü / chat agent
- `lib/modules/field_sales/ai/view/ai_settings_screen.dart`
- `lib/modules/field_sales/ai/view/ai_voice_chat_screen.dart`
- `lib/modules/field_sales/ai/widgets/report_ai_insight_banner.dart`

## Kısa API

### AiGateway

```dart
final gateway = AiGateway();

// Aktif sağlayıcı; key yoksa AiCompletionStatus.noKey
await gateway.complete(AiCompletionRequest(
  messages: [AiChatMessage.user('Merhaba')],
));

// Use-case model override ile
await gateway.completeFor(
  AiUseCase.demandForecastInsight,
  request,
);

await gateway.ask(
  useCase: AiUseCase.voiceAssistant,
  systemPrompt: '...',
  userMessage: '...',
);
```

### AiUseCase

| Use-case | Amaç | UI sahibi |
|----------|------|-----------|
| `reportInsight` | Rapor sonuç insight (P0) | Bu iş |
| `reportSuggestion` | Yeni rapor önerisi | Bu iş (servis) |
| `orderRecommendation` | Sipariş reason enrich | Bridge |
| `demandForecastInsight` | Sipariş tahmin | Başka ajan |
| `replenishmentAdvice` | Ürün bitiş / depo tedarik | Başka ajan |
| `voiceAssistant` | Plasiyer sohbet | Chat iskeleti |

### Ayarlar

1. **Ayarlar → AI sağlayıcılar** (`/field-sales/ai-settings`)
2. Sağlayıcı chip seç → API key yapıştır → model → Kaydet
3. Aktif sağlayıcı = kaydedilen chip
4. Use-case model override opsiyonel (boş = provider model)
5. Rapor AI insight switch (opt-in)
6. Key obfuscate saklanır; log’a yazılmaz; commit edilmez

### Rapor insight

- Sonuç ekranı üstünde dens banner
- Opt-in + key gerekir; aksi halde l10n no-op

### Güvenlik

- Key hardcoded yok
- `RememberMeCrypto` + SharedPreferences (OS keychain yoksa obfuscation)
- HTTP Authorization header’da key; debugPrint key yazmaz

## Test

`test/core/ai/openrouter_client_test.dart`

- Request builder (OpenRouter headers)
- Key yok → noKey
- Use-case model override wire
- Report insight opt-in

## Sonraki (başka ajan)

- Talep tahmin / replenishment dens UI
- RecommendationEngine → bridge otomatik enrich (sipariş ekranı)
- İsteğe bağlı `flutter_secure_storage` yükseltmesi
