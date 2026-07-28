// Dosya Adı: ai_gateway.dart
// Açıklama: Çoklu AI sağlayıcı facade — aktif provider + use-case model override
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:http/http.dart' as http;

import 'ai_chat_message.dart';
import 'ai_completion.dart';
import 'ai_image.dart';
import 'ai_prompt_sanitizer.dart';
import 'ai_provider.dart';
import 'ai_provider_client.dart';
import 'ai_provider_config.dart';
import 'ai_settings_store.dart';
import 'ai_use_case.dart';
import 'clients/anthropic_client.dart';
import 'clients/gemini_client.dart';
import 'clients/openai_compatible_client.dart';

/// {@template ai_gateway}
/// AI gateway: ayarlardan aktif sağlayıcıyı seçer, key yoksa no-op döner.
/// Use-case bazlı opsiyonel model override destekler.
///
/// Kullanım örneği:
/// ```dart
/// final r = await AiGateway().completeFor(
///   AiUseCase.voiceAssistant,
///   AiCompletionRequest(messages: [AiChatMessage.user('Merhaba')]),
/// );
/// ```
/// {@endtemplate}
class AiGateway {
  /// [_store]: Ayar deposu
  final AiSettingsStore _store;

  /// [_clients]: Sağlayıcı istemcileri
  final Map<AiProvider, AiProviderClient> _clients;

  /// {@macro ai_gateway}
  AiGateway({
    AiSettingsStore? store,
    Map<AiProvider, AiProviderClient>? clients,
    http.Client? httpClient,
  })  : _store = store ?? AiSettingsStore(),
        _clients = clients ??
            {
              AiProvider.openAi: OpenAiClient(httpClient: httpClient),
              AiProvider.openRouter: OpenRouterClient(httpClient: httpClient),
              AiProvider.gemini: GeminiClient(httpClient: httpClient),
              AiProvider.anthropic: AnthropicClient(httpClient: httpClient),
            };

  /// Ayar anlık görüntüsü
  Future<AiSettingsSnapshot> loadSettings() => _store.loadSnapshot();

  /// Store erişimi (ayar ekranı)
  AiSettingsStore get settingsStore => _store;

  /// {@template ai_gateway_complete}
  /// Aktif sağlayıcı ile tamamla; key yoksa [AiCompletionStatus.noKey].
  ///
  /// Parametreler:
  /// - [request]: Mesajlar
  /// - [providerOverride]: Geçici sağlayıcı
  /// - [modelOverride]: Geçici model (use-case override’dan önce gelir)
  ///
  /// Dönüş değeri:
  /// - [AiCompletionResult]
  /// {@endtemplate}
  Future<AiCompletionResult> complete(
    AiCompletionRequest request, {
    AiProvider? providerOverride,
    String? modelOverride,
  }) async {
    final snapshot = await _store.loadSnapshot();
    final provider = providerOverride ?? snapshot.activeProvider;
    final config =
        snapshot.configs[provider] ?? AiProviderConfig.defaults(provider);

    if (!config.enabled) {
      return AiCompletionResult.error(
        message: 'provider_disabled',
        provider: provider,
        l10nKey: 'ai.provider_disabled',
      );
    }

    final apiKey = await _store.readApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) {
      return AiCompletionResult.noKey(provider: provider);
    }

    final client = _clients[provider];
    if (client == null) {
      return AiCompletionResult.error(
        message: 'no_client',
        provider: provider,
      );
    }

    final effectiveModel = (modelOverride != null &&
            modelOverride.trim().isNotEmpty)
        ? modelOverride.trim()
        : null;
    final effectiveRequest = effectiveModel == null
        ? request
        : AiCompletionRequest(
            messages: request.messages,
            model: effectiveModel,
            temperature: request.temperature,
            maxTokens: request.maxTokens,
          );

    return client.complete(
      config: config,
      apiKey: apiKey,
      request: effectiveRequest,
    );
  }

  /// {@template ai_gateway_complete_for}
  /// Use-case için tamamla: ayarlardaki model override uygulanır.
  ///
  /// Parametreler:
  /// - [useCase]: Özellik kimliği
  /// - [request]: Mesajlar
  /// - [providerOverride]: Opsiyonel sağlayıcı
  ///
  /// Dönüş değeri:
  /// - [AiCompletionResult]
  /// {@endtemplate}
  Future<AiCompletionResult> completeFor(
    AiUseCase useCase,
    AiCompletionRequest request, {
    AiProvider? providerOverride,
  }) async {
    final snapshot = await _store.loadSnapshot();
    final overrideModel = snapshot.modelOverrideFor(useCase);
    return complete(
      request,
      providerOverride: providerOverride,
      modelOverride: overrideModel,
    );
  }

  /// {@template ai_gateway_ask}
  /// Tek tur system + user kısayolu.
  /// {@endtemplate}
  Future<AiCompletionResult> ask({
    required String userMessage,
    String? systemPrompt,
    AiUseCase? useCase,
    double? temperature,
    int? maxTokens,
    AiProvider? providerOverride,
  }) {
    final request = AiCompletionRequest(
      messages: [
        if (systemPrompt != null && systemPrompt.trim().isNotEmpty)
          AiChatMessage.system(systemPrompt),
        AiChatMessage.user(userMessage),
      ],
      temperature: temperature,
      maxTokens: maxTokens,
    );
    if (useCase != null) {
      return completeFor(
        useCase,
        request,
        providerOverride: providerOverride,
      );
    }
    return complete(request, providerOverride: providerOverride);
  }

  /// {@template ai_gateway_propose_report}
  /// Doğal dil → PostgREST query spec JSON (ham SQL YASAK).
  ///
  /// AI yalnızca allowlist tablo/kolon ile GET spec üretir; uygulama
  /// [PostgrestHttpClient] ile çalıştırır. `db.execute(sql)` yok.
  /// {@endtemplate}
  Future<AiCompletionResult> proposeReport({
    required String userPrompt,
    required String allowlistCatalog,
    AiProvider? providerOverride,
  }) {
    return completeFor(
      AiUseCase.proposeReport,
      AiCompletionRequest(
        messages: [
          AiChatMessage.system(
            'Sen saha satış rapor asistanısın. Kullanıcı isteğine göre '
            'YALNIZCA JSON üret (markdown fence opsiyonel). '
            'Ham SQL, SELECT/INSERT/UPDATE/DELETE YASAK. '
            'Yalnız PostgREST query spec: table, select[], filters[{column,op,value}], '
            'order (col.asc|col.desc), limit, columns[{id,labelKey,numeric}]. '
            'op: eq|neq|gt|gte|lt|lte|like|ilike|is|in. '
            'İzinli tablolar/kolonlar:\n$allowlistCatalog\n'
            'Schema: {"title":"...","titleKey":"...","query":{...},"columns":[...]}',
          ),
          AiChatMessage.user(userPrompt.trim()),
        ],
        temperature: 0.2,
        maxTokens: 900,
      ),
      providerOverride: providerOverride,
    );
  }

  /// {@template ai_gateway_vision_analyze}
  /// Raf / etiket fotoğrafı → ürün adı + fiyat JSON.
  /// Görüntü içeriği loglanmaz.
  /// {@endtemplate}
  Future<AiCompletionResult> visionAnalyze({
    required String imageBase64,
    String imageMimeType = 'image/jpeg',
    String? userHint,
    AiProvider? providerOverride,
  }) {
    final hint = AiPromptSanitizer.sanitize((userHint ?? '').trim());
    return completeFor(
      AiUseCase.visionAnalyze,
      AiCompletionRequest(
        messages: [
          AiChatMessage.system(
            'Raf / rakip fiyat etiketlerini oku. Yalnız JSON dizi üret: '
            '[{"name":"...","sku":"...","price":12.5,"currency":"TRY",'
            '"confidence":0.0-1.0}]. '
            'Belirsiz satırlarda confidence düşük tut. '
            'Kişi adı / telefon yazma. Açıklama metni yazma.',
          ),
          AiChatMessage.userWithImage(
            content: hint.isEmpty
                ? 'Bu görüntüdeki ürün adları, SKU ve fiyatları çıkar.'
                : hint,
            imageBase64: imageBase64,
            imageMimeType: imageMimeType,
          ),
        ],
        temperature: 0.1,
        maxTokens: 1200,
      ),
      providerOverride: providerOverride,
    );
  }

  /// {@template ai_gateway_invoice_ocr}
  /// Fatura / fiş fotoğrafı → başlık + satır JSON.
  /// Kötü el yazısı dahil; görüntü içeriği loglanmaz.
  /// {@endtemplate}
  Future<AiCompletionResult> invoiceOcr({
    required String imageBase64,
    String imageMimeType = 'image/jpeg',
    String? userHint,
    String? docTypeHint,
    AiProvider? providerOverride,
  }) {
    final hint = AiPromptSanitizer.sanitize((userHint ?? '').trim());
    final docHint = AiPromptSanitizer.sanitize((docTypeHint ?? '').trim());
    final typePart = docHint.isEmpty ? '' : ' Belge tipi ipucu: $docHint.';
    return completeFor(
      AiUseCase.invoiceOcr,
      AiCompletionRequest(
        messages: [
          AiChatMessage.system(
            'Fatura/fiş OCR. El yazısı kötü olsa da oku. Yalnız JSON obje: '
            '{"party_name":"...","party_code":"...","document_no":"...",'
            '"document_date":"YYYY-MM-DD","currency":"TRY","confidence":0-1,'
            '"lines":[{"name":"...","sku":"...","quantity":1,"unit":"ADET",'
            '"unit_price":0,"vat_rate":20,"line_total":0,"confidence":0-1}]}.'
            ' Belirsizde confidence düşük. Telefon/TC uydurma. Açıklama yazma.',
          ),
          AiChatMessage.userWithImage(
            content: hint.isEmpty
                ? 'Bu belgedeki cari, tarih, belge no ve ürün satırlarını çıkar.'
                    '$typePart'
                : '$hint$typePart',
            imageBase64: imageBase64,
            imageMimeType: imageMimeType,
          ),
        ],
        temperature: 0.1,
        maxTokens: 2500,
      ),
      providerOverride: providerOverride,
    );
  }

  /// {@template ai_gateway_vehicle_vision}
  /// Araç fotoğrafı → plaka / marka / tür / renk JSON.
  /// Görüntü içeriği loglanmaz.
  /// {@endtemplate}
  Future<AiCompletionResult> vehicleVision({
    required String imageBase64,
    String imageMimeType = 'image/jpeg',
    String? userHint,
    AiProvider? providerOverride,
  }) {
    final hint = AiPromptSanitizer.sanitize((userHint ?? '').trim());
    return completeFor(
      AiUseCase.vehicleVision,
      AiCompletionRequest(
        messages: [
          AiChatMessage.system(
            'Araç fotoğrafı analizi. Yalnız JSON obje üret: '
            '{"plate":"...","brand":"...","model":"...","type":"otomobil|'
            'kamyonet|kamyon|motosiklet|minibus|van|diger","color":"...",'
            '"year":"YYYY veya boş","notes":"görünen diğer özellikler",'
            '"confidence":0.0-1.0}. '
            'Plaka okunmuyorsa plate boş bırak. Marka/renk/tür görünürse doldur. '
            'Kişi adı / telefon uydurma. Açıklama metni yazma.',
          ),
          AiChatMessage.userWithImage(
            content: hint.isEmpty
                ? 'Bu araç fotoğrafından plaka, marka, model, tür, renk '
                    've yıl bilgisini çıkar.'
                : hint,
            imageBase64: imageBase64,
            imageMimeType: imageMimeType,
          ),
        ],
        temperature: 0.1,
        maxTokens: 800,
      ),
      providerOverride: providerOverride,
    );
  }

  /// {@template ai_gateway_visit_transcript_analyze}
  /// Transcript → özet + durum önerisi JSON (ses/PII loglanmaz).
  /// {@endtemplate}
  Future<AiCompletionResult> visitTranscriptAnalyze({
    required String transcriptText,
    AiProvider? providerOverride,
  }) {
    final text = AiPromptSanitizer.sanitize(transcriptText.trim());
    return completeFor(
      AiUseCase.visitTranscriptAnalyze,
      AiCompletionRequest(
        messages: [
          AiChatMessage.system(
            'Saha ziyaret konuşması özeti. Yalnız JSON: '
            '{"summary":"...","status_suggestion":"...","lang":"tr|ar|ku|en",'
            '"emotion":"happy|irritable|angry|neutral","draft":true}. '
            'Kişi adı/telefon uydurma. Ham ses yok.',
          ),
          AiChatMessage.user(text.isEmpty ? '(boş transcript)' : text),
        ],
        temperature: 0.2,
        maxTokens: 700,
      ),
      providerOverride: providerOverride,
    );
  }

  /// {@template ai_gateway_emotion_detect}
  /// Metin → duygu etiketi JSON.
  /// {@endtemplate}
  Future<AiCompletionResult> emotionDetect({
    required String text,
    AiProvider? providerOverride,
  }) {
    final body = AiPromptSanitizer.sanitize(text.trim());
    return completeFor(
      AiUseCase.emotionDetect,
      AiCompletionRequest(
        messages: [
          AiChatMessage.system(
            'Duygu sınıflandır. Yalnız JSON: '
            '{"emotion":"happy|irritable|angry|neutral","confidence":0.0-1.0}. '
            'PII yazma.',
          ),
          AiChatMessage.user(body.isEmpty ? '(boş)' : body),
        ],
        temperature: 0.1,
        maxTokens: 120,
      ),
      providerOverride: providerOverride,
    );
  }

  /// {@template ai_gateway_diarize_hint}
  /// Segment metinleri → Speaker 1/2 etiket ipucu JSON.
  /// {@endtemplate}
  Future<AiCompletionResult> diarizeHint({
    required String segmentsText,
    AiProvider? providerOverride,
  }) {
    final body = AiPromptSanitizer.sanitize(segmentsText.trim());
    return completeFor(
      AiUseCase.diarizeHint,
      AiCompletionRequest(
        messages: [
          AiChatMessage.system(
            'Konuşmacı ayrımı ipucu. Yalnız JSON dizi: '
            '[{"speaker_label":"Speaker 1","start_ms":0,"end_ms":1000,'
            '"text":"...","lang":"tr"}]. '
            'Kimlik kesin değil; Speakers 1/2 kullan. PII uydurma.',
          ),
          AiChatMessage.user(body.isEmpty ? '(boş)' : body),
        ],
        temperature: 0.2,
        maxTokens: 900,
      ),
      providerOverride: providerOverride,
    );
  }

  /// {@template ai_gateway_generate_image}
  /// Aktif sağlayıcı ile görsel üret; key yoksa noKey; destek yoksa unsupported.
  ///
  /// Parametreler:
  /// - [request]: Prompt + boyut
  /// - [providerOverride]: Geçici sağlayıcı
  /// - [modelOverride]: Use-case / geçici model
  ///
  /// Dönüş değeri:
  /// - [AiImageResult]
  /// {@endtemplate}
  Future<AiImageResult> generateImage(
    AiImageRequest request, {
    AiProvider? providerOverride,
    String? modelOverride,
  }) async {
    final snapshot = await _store.loadSnapshot();
    var provider = providerOverride ?? snapshot.activeProvider;
    var config =
        snapshot.configs[provider] ?? AiProviderConfig.defaults(provider);

    if (!config.enabled) {
      return AiImageResult.error(
        message: 'provider_disabled',
        provider: provider,
        l10nKey: 'ai.provider_disabled',
      );
    }

    // Claude image yok → OpenRouter / OpenAI key varsa otomatik fallback
    String? fallbackL10n;
    if (!provider.supportsImageGeneration) {
      final fallback = await _resolveImageFallback(snapshot);
      if (fallback == null) {
        return AiImageResult.unsupported(provider: provider);
      }
      provider = fallback;
      config =
          snapshot.configs[provider] ?? AiProviderConfig.defaults(provider);
      fallbackL10n = 'ai.image_fallback_from_claude';
    }

    final apiKey = await _store.readApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) {
      return AiImageResult.noKey(provider: provider);
    }

    final client = _clients[provider];
    if (client == null) {
      return AiImageResult.error(
        message: 'no_client',
        provider: provider,
      );
    }

    final effectiveModel = (modelOverride != null &&
            modelOverride.trim().isNotEmpty)
        ? modelOverride.trim()
        : request.model;
    final prompt = AiPromptSanitizer.sanitize(request.prompt);
    final url = request.productImageUrl?.trim();
    final effectivePrompt = (url != null && url.isNotEmpty)
        ? '$prompt\nReference product image URL: $url'
        : prompt;
    final effectiveRequest = AiImageRequest(
      prompt: effectivePrompt,
      width: request.width,
      height: request.height,
      model: effectiveModel,
      productImageUrl: request.productImageUrl,
      productImageBytes: request.productImageBytes,
    );

    final result = await client.generateImage(
      config: config,
      apiKey: apiKey,
      request: effectiveRequest,
    );
    if (result.isOk && fallbackL10n != null) {
      return AiImageResult(
        status: result.status,
        bytes: result.bytes,
        mimeType: result.mimeType,
        provider: result.provider,
        model: result.model,
        errorMessage: result.errorMessage,
        l10nKey: fallbackL10n,
      );
    }
    return result;
  }

  /// Claude aktifken image için OpenRouter → OpenAI key sırası.
  Future<AiProvider?> _resolveImageFallback(AiSettingsSnapshot snapshot) async {
    for (final p in [AiProvider.openRouter, AiProvider.openAi]) {
      final cfg = snapshot.configs[p];
      if (cfg == null || !cfg.enabled) continue;
      final key = await _store.readApiKey(p);
      if (key != null && key.isNotEmpty) return p;
    }
    return null;
  }

  /// {@template ai_gateway_generate_image_for}
  /// Use-case model override ile görsel üret.
  /// {@endtemplate}
  Future<AiImageResult> generateImageFor(
    AiUseCase useCase,
    AiImageRequest request, {
    AiProvider? providerOverride,
  }) async {
    final snapshot = await _store.loadSnapshot();
    final overrideModel = snapshot.modelOverrideFor(useCase);
    return generateImage(
      request,
      providerOverride: providerOverride,
      modelOverride: overrideModel,
    );
  }
}
