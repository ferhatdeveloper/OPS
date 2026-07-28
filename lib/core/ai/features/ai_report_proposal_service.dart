// Dosya Adı: ai_report_proposal_service.dart
// Açıklama: Doğal dil → PostgREST query spec önerisi (SQL EXECUTE yok)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import '../ai_completion.dart';
import '../ai_gateway.dart';
import 'postgrest_query_allowlist.dart';
import 'postgrest_query_sanitizer.dart';
import 'postgrest_query_spec.dart';

/// {@template ai_report_proposal_result}
/// Öneri sonucu (onay öncesi).
/// {@endtemplate}
class AiReportProposalResult {
  /// [status]: Gateway durumu
  final AiCompletionStatus status;

  /// [proposal]: Sanitize edilmiş öneri
  final AiReportProposal? proposal;

  /// [l10nKey]
  final String? l10nKey;

  /// [rawText]: Ham AI metni (debug; UI göstermeyebilir)
  final String? rawText;

  /// {@macro ai_report_proposal_result}
  const AiReportProposalResult({
    required this.status,
    this.proposal,
    this.l10nKey,
    this.rawText,
  });

  bool get isOk =>
      status == AiCompletionStatus.ok && proposal != null;
}

/// {@template ai_report_proposal_service}
/// Kullanıcı doğal dil ister → AI **PostgREST query JSON** üretir.
/// Ham SQL kabul edilmez; sanitize zorunlu.
/// {@endtemplate}
class AiReportProposalService {
  final AiGateway _gateway;
  final PostgrestQueryAllowlist _allowlist;
  final PostgrestQuerySanitizer _sanitizer;

  /// {@macro ai_report_proposal_service}
  AiReportProposalService({
    AiGateway? gateway,
    PostgrestQueryAllowlist? allowlist,
    PostgrestQuerySanitizer? sanitizer,
  })  : _gateway = gateway ?? AiGateway(),
        _allowlist = allowlist ?? PostgrestQueryAllowlist(),
        _sanitizer = sanitizer ??
            PostgrestQuerySanitizer(
              allowlist: allowlist ?? PostgrestQueryAllowlist(),
            );

  /// Gateway kısayolu (test)
  Future<AiCompletionResult> proposeReportRaw(String userPrompt) {
    return _gateway.proposeReport(
      userPrompt: userPrompt,
      allowlistCatalog: _allowlist.promptCatalog(),
    );
  }

  /// {@template ai_report_proposal_service_propose}
  /// Doğal dil → sanitize edilmiş [AiReportProposal].
  /// {@endtemplate}
  Future<AiReportProposalResult> propose(String userPrompt) async {
    final settings = await _gateway.loadSettings();
    if (!settings.hasActiveKey) {
      return AiReportProposalResult(
        status: AiCompletionStatus.noKey,
        l10nKey: 'ai.no_api_key',
      );
    }
    final completion = await _gateway.proposeReport(
      userPrompt: userPrompt,
      allowlistCatalog: _allowlist.promptCatalog(),
    );
    if (!completion.isOk) {
      return AiReportProposalResult(
        status: completion.status,
        l10nKey: completion.l10nKey ?? 'ai.request_failed',
        rawText: completion.text,
      );
    }
    final parsed = tryParseProposalJson(completion.text!);
    if (parsed == null) {
      return AiReportProposalResult(
        status: AiCompletionStatus.error,
        l10nKey: 'field_sales.ai_reports.err_parse',
        rawText: completion.text,
      );
    }
    final sanitized = _sanitizer.sanitize(parsed.query);
    if (!sanitized.ok || sanitized.spec == null) {
      return AiReportProposalResult(
        status: AiCompletionStatus.error,
        l10nKey: sanitized.errorKey ?? 'field_sales.ai_reports.err_sanitize',
        rawText: completion.text,
      );
    }
    final cols = parsed.columns.isNotEmpty
        ? parsed.columns
            .where((c) => sanitized.spec!.select.contains(c.id))
            .toList()
        : sanitized.spec!.select
            .map((id) => AiReportLayoutColumn(id: id, labelKey: id))
            .toList();
    return AiReportProposalResult(
      status: AiCompletionStatus.ok,
      proposal: AiReportProposal(
        title: parsed.title.isEmpty ? 'AI Report' : parsed.title,
        titleKey: parsed.titleKey,
        query: sanitized.spec!,
        columns: cols,
      ),
      rawText: completion.text,
    );
  }

  /// JSON blok çıkar + parse (test)
  static AiReportProposal? tryParseProposalJson(String text) {
    final trimmed = text.trim();
    String body = trimmed;
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
    final m = fence.firstMatch(trimmed);
    if (m != null) {
      body = m.group(1)!.trim();
    } else {
      final start = trimmed.indexOf('{');
      final end = trimmed.lastIndexOf('}');
      if (start >= 0 && end > start) {
        body = trimmed.substring(start, end + 1);
      }
    }
    // Ham SQL reddi
    if (RegExp(
      r'\b(select|insert|update|delete|drop|execute)\b.*\bfrom\b',
      caseSensitive: false,
    ).hasMatch(body) &&
        !body.contains('"table"')) {
      return null;
    }
    try {
      final map = jsonDecode(body);
      if (map is! Map) return null;
      return AiReportProposal.fromJson(Map<String, dynamic>.from(map));
    } catch (_) {
      return null;
    }
  }
}
