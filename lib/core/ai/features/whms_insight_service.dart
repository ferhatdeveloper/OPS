// Dosya Adı: whms_insight_service.dart
// Açıklama: WHMS depo ekranları için opt-in AI insight (key yoksa no-op)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../ai_chat_message.dart';
import '../ai_completion.dart';
import '../ai_gateway.dart';
import '../ai_use_case.dart';

/// {@template whms_insight_service}
/// Depo / WHMS satır özetinden kısa AI insight üretir.
/// Opt-in kapalı veya key yoksa [AiCompletionStatus.noKey].
///
/// Kullanım örneği:
/// ```dart
/// final r = await WhmsInsightService().analyze(
///   contextTitle: 'Emirler',
///   rowSummaries: ['draft=3', 'transfer=1'],
/// );
/// ```
/// {@endtemplate}
class WhmsInsightService {
  /// [_gateway]: AI facade
  final AiGateway _gateway;

  /// [maxRows]: Prompt satır üst sınırı
  final int maxRows;

  /// {@macro whms_insight_service}
  WhmsInsightService({
    AiGateway? gateway,
    this.maxRows = 40,
  }) : _gateway = gateway ?? AiGateway();

  /// {@template whms_insight_analyze}
  /// Opt-in + key kontrolü sonrası kısa depo insight.
  ///
  /// Parametreler:
  /// - [contextTitle]: Ekran / bölüm başlığı
  /// - [rowSummaries]: Satır özet metinleri
  /// - [force]: Opt-in yok say (test)
  ///
  /// Dönüş değeri:
  /// - [AiCompletionResult]
  /// {@endtemplate}
  Future<AiCompletionResult> analyze({
    required String contextTitle,
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
      ..writeln('Bağlam: $contextTitle')
      ..writeln('Satır sayısı: ${rowSummaries.length}')
      ..writeln('Özet örnekleri:')
      ..writeln(clipped.join('\n'));

    return _gateway.completeFor(
      AiUseCase.whmsInsight,
      AiCompletionRequest(
        messages: [
          AiChatMessage.system(
            'Sen bir depo / WMS asistanısın. '
            'Türkçe, kısa (en fazla 5 madde), aksiyon odaklı insight ver. '
            'Düşük stok, SKT, sayım farkı, transfer riski vurgula. '
            'Uydurma sayı üretme; yalnızca verilen özetlere dayan.',
          ),
          AiChatMessage.user(buf.toString()),
        ],
        maxTokens: 512,
        temperature: 0.3,
      ),
    );
  }

  /// Map satırlarından kompakt özet.
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
