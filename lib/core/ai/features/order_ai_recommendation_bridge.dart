// Dosya Adı: order_ai_recommendation_bridge.dart
// Açıklama: Yerel RecommendationEngine + AiGateway yedek/enrich yolu
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../ai_chat_message.dart';
import '../ai_completion.dart';
import '../ai_gateway.dart';
import '../ai_use_case.dart';

/// {@template order_ai_recommendation_bridge}
/// Sipariş AI önerisi: önce yerel SQLite suggestion; key varsa
/// gateway ile reason zenginleştirme (opsiyonel, offline-safe).
///
/// Tahmin UI başka ajan yazacak — bu köprü yalnızca gateway çağrısı.
/// {@endtemplate}
class OrderAiRecommendationBridge {
  final AiGateway _gateway;

  /// {@macro order_ai_recommendation_bridge}
  OrderAiRecommendationBridge({AiGateway? gateway})
      : _gateway = gateway ?? AiGateway();

  /// Yerel reason’ı AI ile kısaca zenginleştir (key yoksa orijinal döner)
  Future<String?> enrichReason({
    required String customerLabel,
    required String productLabel,
    required double suggestedQty,
    String? localReason,
  }) async {
    final settings = await _gateway.loadSettings();
    if (!settings.hasActiveKey) return localReason;

    final result = await _gateway.completeFor(
      AiUseCase.orderRecommendation,
      AiCompletionRequest(
        messages: [
          AiChatMessage.system(
            'Plasiyer sipariş asistanısın. Tek cümle Türkçe öneri gerekçesi yaz. '
            'Sayı uydurma; verilen miktarı kullan.',
          ),
          AiChatMessage.user(
            'Müşteri: $customerLabel\n'
            'Ürün: $productLabel\n'
            'Önerilen miktar: $suggestedQty\n'
            'Yerel gerekçe: ${localReason ?? '-'}',
          ),
        ],
        maxTokens: 120,
        temperature: 0.2,
      ),
    );
    if (result.isOk) return result.text;
    return localReason;
  }

  /// Talep tahmin insight iskeleti (UI başka ajan)
  Future<AiCompletionResult> demandForecastInsight({
    required String contextSummary,
  }) {
    return _gateway.ask(
      useCase: AiUseCase.demandForecastInsight,
      systemPrompt:
          'Saha satış talep tahmin asistanısın. Kısa Türkçe insight ver.',
      userMessage: contextSummary,
      maxTokens: 400,
      temperature: 0.3,
    );
  }

  /// Replenishment / tedarik tavsiyesi iskeleti
  Future<AiCompletionResult> replenishmentAdvice({
    required String contextSummary,
  }) {
    return _gateway.ask(
      useCase: AiUseCase.replenishmentAdvice,
      systemPrompt:
          'Depo tedarik / ürün bitiş asistanısın. Kısa Türkçe aksiyon öner.',
      userMessage: contextSummary,
      maxTokens: 400,
      temperature: 0.3,
    );
  }
}
