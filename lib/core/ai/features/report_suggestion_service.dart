// Dosya Adı: report_suggestion_service.dart
// Açıklama: MBT rapor bağlamında AI rapor önerisi / metin özeti
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../ai_chat_message.dart';
import '../ai_completion.dart';
import '../ai_gateway.dart';
import '../ai_use_case.dart';

/// {@template report_suggestion_service}
/// Katalog / kategori bağlamından yeni rapor önerisi veya kısa özet üretir.
/// Key yoksa no-op.
/// {@endtemplate}
class ReportSuggestionService {
  final AiGateway _gateway;

  /// {@macro report_suggestion_service}
  ReportSuggestionService({AiGateway? gateway})
      : _gateway = gateway ?? AiGateway();

  /// Rapor önerileri (metin listesi tek blok)
  Future<AiCompletionResult> suggestReports({
    required String categoryLabel,
    required List<String> existingReportNames,
    String? userHint,
  }) async {
    final settings = await _gateway.loadSettings();
    if (!settings.hasActiveKey) {
      return AiCompletionResult.noKey(provider: settings.activeProvider);
    }
    final names = existingReportNames.take(30).join(', ');
    final hint = (userHint ?? '').trim();
    return _gateway.completeFor(
      AiUseCase.reportSuggestion,
      AiCompletionRequest(
        messages: [
          AiChatMessage.system(
            'Saha satış MBT rapor kataloğu için yardımcı ol. '
            'Kısa Türkçe öneriler ver (en fazla 5). Mevcut raporları tekrarlama.',
          ),
          AiChatMessage.user(
            'Kategori: $categoryLabel\n'
            'Mevcut: $names\n'
            '${hint.isEmpty ? '' : 'İstek: $hint'}',
          ),
        ],
        maxTokens: 600,
        temperature: 0.4,
      ),
    );
  }
}
