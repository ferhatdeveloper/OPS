// Dosya Adı: report_insight_service.dart
// Açıklama: MBT rapor sonucu için opt-in AI insight (key yoksa no-op)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../ai_chat_message.dart';
import '../ai_completion.dart';
import '../ai_gateway.dart';
import '../ai_use_case.dart';

/// {@template report_insight_service}
/// Rapor satır özetinden kısa AI insight üretir.
/// Opt-in kapalı veya key yoksa [AiCompletionStatus.noKey] / sessiz no-op.
///
/// Kullanım örneği:
/// ```dart
/// final r = await ReportInsightService().analyze(
///   reportTitle: 'Cari Extre',
///   rowSummaries: ['A: 100', 'B: 50'],
/// );
/// ```
/// {@endtemplate}
class ReportInsightService {
  /// [_gateway]: AI facade
  final AiGateway _gateway;

  /// [maxRows]: Prompt’a giden satır üst sınırı
  final int maxRows;

  /// {@macro report_insight_service}
  ReportInsightService({
    AiGateway? gateway,
    this.maxRows = 40,
  }) : _gateway = gateway ?? AiGateway();

  /// {@template report_insight_analyze}
  /// Opt-in + key kontrolü sonrası kısa insight.
  ///
  /// Parametreler:
  /// - [reportTitle]: Rapor başlığı
  /// - [rowSummaries]: Satır özet metinleri
  /// - [force]: Opt-in yok say (test)
  ///
  /// Dönüş değeri:
  /// - [AiCompletionResult]
  /// {@endtemplate}
  Future<AiCompletionResult> analyze({
    required String reportTitle,
    required List<String> rowSummaries,
    bool force = false,
  }) async {
    final settings = await _gateway.loadSettings();
    if (!force && !settings.insightsOptIn) {
      return const AiCompletionResult(
        status: AiCompletionStatus.noKey,
        l10nKey: 'ai.insights_opt_in_required',
      );
    }
    if (!settings.hasActiveKey) {
      return AiCompletionResult.noKey(provider: settings.activeProvider);
    }

    final clipped = rowSummaries.take(maxRows).toList();
    final buf = StringBuffer()
      ..writeln('Rapor: $reportTitle')
      ..writeln('Satır sayısı: ${rowSummaries.length}')
      ..writeln('Özet örnekleri:')
      ..writeln(clipped.join('\n'));

    return _gateway.completeFor(
      AiUseCase.reportInsight,
      AiCompletionRequest(
        messages: [
          AiChatMessage.system(
            'Sen bir saha satış / muhasebe raporu asistanısın. '
            'Türkçe, kısa (en fazla 5 madde), aksiyon odaklı insight ver. '
            'Uydurma sayı üretme; yalnızca verilen özetlere dayan.',
          ),
          AiChatMessage.user(buf.toString()),
        ],
        maxTokens: 512,
        temperature: 0.3,
      ),
    );
  }

  /// Rapor satır map’lerinden kompakt özet satırları
  static List<String> summarizeRows(
    List<Map<String, String>> rows, {
    int maxRows = 40,
    int maxCols = 6,
  }) {
    final out = <String>[];
    for (final row in rows.take(maxRows)) {
      final entries = row.entries.take(maxCols).map((e) {
        final v = e.value.trim();
        if (v.isEmpty) return null;
        return '${e.key}=$v';
      }).whereType<String>();
      final line = entries.join(' | ');
      if (line.isNotEmpty) out.add(line);
    }
    return out;
  }
}
