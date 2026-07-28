// Dosya Adı: field_sales_chat_agent.dart
// Açıklama: Plasiyer sohbet ajanı — SQLite-öncelikli veri + opsiyonel rapor PDF
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../ai_chat_message.dart';
import '../ai_completion.dart';
import '../ai_gateway.dart';
import '../ai_use_case.dart';
import 'ai_chat_data_tools.dart';
import 'ai_chat_report_pdf_builder.dart';
import 'ai_report_proposal_service.dart';
import 'postgrest_query_runner.dart';
import 'postgrest_query_spec.dart';

/// {@template field_sales_chat_agent}
/// Plasiyer asistanı: SQLite-öncelikli veri araçları + rapor PDF.
/// Key yoksa no-op; UI l10n mesaj gösterir.
/// {@endtemplate}
class FieldSalesChatAgent {
  final AiGateway _gateway;
  final AiChatDataToolkit _toolkit;
  final AiReportProposalService _proposals;
  final PostgrestQueryRunner _runner;
  final AiChatReportPdfBuilder _pdfBuilder;

  /// Konuşma geçmişi
  final List<AiChatMessage> history = [];

  /// Son veri paketi (UI dens chip)
  AiChatDataBundle? lastDataBundle;

  /// Asistan history index → PDF
  final Map<int, AiChatReportPdfPayload> pdfByHistoryIndex = {};

  /// {@macro field_sales_chat_agent}
  FieldSalesChatAgent({
    AiGateway? gateway,
    AiChatDataToolkit? toolkit,
    AiReportProposalService? proposals,
    PostgrestQueryRunner? runner,
    AiChatReportPdfBuilder? pdfBuilder,
  })  : _gateway = gateway ?? AiGateway(),
        _toolkit = toolkit ?? AiChatDataToolkit(),
        _proposals = proposals ?? AiReportProposalService(),
        _runner = runner ?? PostgrestQueryRunner(),
        _pdfBuilder = pdfBuilder ?? AiChatReportPdfBuilder();

  static const String _systemPrompt =
      'Sen EXFINOPS saha satış (plasiyer) asistanısın. '
      'Raporlar, menü akışları, sipariş/tahsilat/ziyaret hakkında kısa Türkçe '
      'yardım et. Uydurma ERP fiş numarası veya tutar üretme. '
      'Veri bloğu varsa yalnızca ona dayan. '
      'ASLA dahili/klon ID gösterme veya okuma (ord_*, cust_*, prod_*, uuid, '
      'customer_id, sipariş id). Müşteri adı, tarih, tutar ve durumu doğal '
      'cümleyle anlat (ör. "Anadolu Gıda için 120 TL sipariş beklemede"). '
      'Markdown ** kullanma; düz metin veya kısa madde yaz.';

  /// Geçmişi temizle
  void reset() {
    history.clear();
    pdfByHistoryIndex.clear();
    lastDataBundle = null;
  }

  /// Rapor / liste niyeti mi?
  static bool looksLikeReportRequest(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return false;
    const keys = [
      'rapor',
      'report',
      'listele',
      'pdf',
      'extre',
      'bakiye list',
    ];
    for (final k in keys) {
      if (t.contains(k)) return true;
    }
    return false;
  }

  /// {@template field_sales_chat_agent_reply}
  /// Kullanıcı mesajına yanıt.
  /// {@endtemplate}
  Future<AiCompletionResult> reply(String userText) async {
    final text = userText.trim();
    if (text.isEmpty) {
      return const AiCompletionResult(
        status: AiCompletionStatus.error,
        l10nKey: 'ai.empty_message',
      );
    }

    final settings = await _gateway.loadSettings();
    if (!settings.hasActiveKey) {
      return AiCompletionResult.noKey(provider: settings.activeProvider);
    }

    // Veri araçları (SQLite önce; merkez yoksa yerel)
    try {
      lastDataBundle = await _toolkit.gather(text);
    } catch (_) {
      lastDataBundle = const AiChatDataBundle(centerUnavailable: true);
    }

    // Açık rapor niyeti → PDF
    if (looksLikeReportRequest(text)) {
      final pdfResult = await _tryReportPdf(text);
      if (pdfResult != null) return pdfResult;
    }

    history.add(AiChatMessage.user(text));
    return _completeFromHistory();
  }

  /// {@template field_sales_chat_agent_reply_with_image}
  /// Kamera / galeri görüntüsü ile multimodal yanıt.
  /// {@endtemplate}
  Future<AiCompletionResult> replyWithImage({
    required String imageBase64,
    String imageMimeType = 'image/jpeg',
    String? hint,
  }) async {
    final b64 = imageBase64.trim();
    if (b64.isEmpty) {
      return const AiCompletionResult(
        status: AiCompletionStatus.error,
        l10nKey: 'ai.empty_message',
      );
    }

    final settings = await _gateway.loadSettings();
    if (!settings.hasActiveKey) {
      return AiCompletionResult.noKey(provider: settings.activeProvider);
    }

    final content = (hint ?? '').trim().isEmpty
        ? 'Bu görüntüyü incele ve saha satışı bağlamında yardımcı ol.'
        : hint!.trim();

    history.add(
      AiChatMessage.userWithImage(
        content: content,
        imageBase64: b64,
        imageMimeType: imageMimeType,
      ),
    );
    return _completeFromHistory(useVision: true);
  }

  Future<AiCompletionResult?> _tryReportPdf(String userText) async {
    try {
      // Önce local bundle satırlarından PDF dene
      final bundle = lastDataBundle;
      if (bundle != null) {
        for (final slice in bundle.slices) {
          if (slice.rows.isEmpty) continue;
          final cols = slice.rows.first.keys
              .map((k) => AiReportLayoutColumn(id: k, labelKey: k))
              .toList();
          final pdf = await _pdfBuilder.build(
            title: 'AI · ${slice.tool.name}',
            columns: cols,
            rows: slice.rows,
          );
          history.add(AiChatMessage.user(userText));
          final summary =
              '${slice.tool.name}: ${slice.rows.length} satır. PDF hazır.';
          history.add(AiChatMessage.assistant(summary));
          pdfByHistoryIndex[history.length - 1] = pdf;
          return AiCompletionResult(
            status: AiCompletionStatus.ok,
            text: summary,
          );
        }
      }

      final proposed = await _proposals.propose(userText);
      if (!proposed.isOk || proposed.proposal == null) return null;
      final proposal = proposed.proposal!;
      final run = await _runner.run(proposal.query);
      if (!run.ok) return null;

      var columns = proposal.columns;
      if (columns.isEmpty && run.rows.isNotEmpty) {
        columns = run.rows.first.keys
            .map((k) => AiReportLayoutColumn(id: k, labelKey: k))
            .toList();
      }
      final pdf = await _pdfBuilder.build(
        title: proposal.title,
        columns: columns,
        rows: run.rows,
      );
      history.add(AiChatMessage.user(userText));
      final summary =
          '${proposal.title}\n${run.rows.length} satır. PDF hazır.';
      history.add(AiChatMessage.assistant(summary));
      pdfByHistoryIndex[history.length - 1] = pdf;
      return AiCompletionResult(
        status: AiCompletionStatus.ok,
        text: summary,
      );
    } catch (_) {
      return null;
    }
  }

  Future<AiCompletionResult> _completeFromHistory({
    bool useVision = false,
  }) async {
    final dataBlock = lastDataBundle?.toPromptBlock();
    final system = dataBlock == null || dataBlock.isEmpty
        ? _systemPrompt
        : '$_systemPrompt\n\n$dataBlock';

    final messages = <AiChatMessage>[
      AiChatMessage.system(system),
      ...history,
    ];

    final result = await _gateway.completeFor(
      useVision ? AiUseCase.visionAnalyze : AiUseCase.voiceAssistant,
      AiCompletionRequest(
        messages: messages,
        maxTokens: useVision ? 1200 : 900,
        temperature: useVision ? 0.2 : 0.35,
      ),
    );

    if (result.isOk && result.text != null) {
      history.add(AiChatMessage.assistant(result.text!));
    } else {
      if (history.isNotEmpty && history.last.role == AiChatRole.user) {
        history.removeLast();
      }
    }
    return result;
  }

  /// History index PDF
  AiChatReportPdfPayload? pdfAt(int historyIndex) =>
      pdfByHistoryIndex[historyIndex];
}
