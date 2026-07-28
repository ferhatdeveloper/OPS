// Dosya Adı: invoice_ocr_analyzer.dart
// Açıklama: AiGateway.invoiceOcr → InvoiceOcrDraft + katalog/cari eşleme
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import '../../../../core/ai/ai_completion.dart';
import '../../../../core/ai/ai_gateway.dart';
import '../../ai_vision_competitor/engine/product_fuzzy_matcher.dart';
import '../../products/model/product_catalog_row.dart';
import '../model/invoice_ocr_line.dart';
import '../model/invoice_ocr_result.dart';
import '../model/invoice_scan_doc_type.dart';

/// {@template invoice_ocr_analyze_result}
/// Vision fatura OCR sonucu.
/// {@endtemplate}
class InvoiceOcrAnalyzeResult {
  /// [status]
  final AiCompletionStatus status;

  /// [draft]
  final InvoiceOcrDraft? draft;

  /// [l10nKey]
  final String? l10nKey;

  /// {@macro invoice_ocr_analyze_result}
  const InvoiceOcrAnalyzeResult({
    required this.status,
    this.draft,
    this.l10nKey,
  });

  bool get isOk =>
      status == AiCompletionStatus.ok &&
      draft != null &&
      draft!.hasContent;
}

/// {@template invoice_ocr_analyzer}
/// Fotoğraf → fatura taslağı; görüntü loglanmaz.
/// {@endtemplate}
class InvoiceOcrAnalyzer {
  final AiGateway _gateway;
  final ProductFuzzyMatcher _productMatcher;

  /// {@macro invoice_ocr_analyzer}
  InvoiceOcrAnalyzer({
    AiGateway? gateway,
    ProductFuzzyMatcher productMatcher = const ProductFuzzyMatcher(),
  })  : _gateway = gateway ?? AiGateway(),
        _productMatcher = productMatcher;

  /// Vision OCR çağrısı
  Future<InvoiceOcrAnalyzeResult> analyzeImage({
    required String imageBase64,
    String imageMimeType = 'image/jpeg',
    InvoiceScanDocType docType = InvoiceScanDocType.other,
    String? hint,
  }) async {
    final settings = await _gateway.loadSettings();
    if (!settings.hasActiveKey) {
      return const InvoiceOcrAnalyzeResult(
        status: AiCompletionStatus.noKey,
        l10nKey: 'ai.no_api_key',
      );
    }
    final r = await _gateway.invoiceOcr(
      imageBase64: imageBase64,
      imageMimeType: imageMimeType,
      userHint: hint,
      docTypeHint: docType.promptHint,
    );
    if (!r.isOk) {
      return InvoiceOcrAnalyzeResult(
        status: r.status,
        l10nKey: r.l10nKey ?? 'ai.request_failed',
      );
    }
    final draft = parseDraftJson(r.text!);
    if (draft == null || !draft.hasContent) {
      return const InvoiceOcrAnalyzeResult(
        status: AiCompletionStatus.error,
        l10nKey: 'field_sales.ai_invoice_scan.err_parse',
      );
    }
    return InvoiceOcrAnalyzeResult(
      status: AiCompletionStatus.ok,
      draft: draft,
    );
  }

  /// JSON → taslak (unit test)
  static InvoiceOcrDraft? parseDraftJson(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    String body = trimmed;
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
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
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      return InvoiceOcrDraft.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  /// Satır → ürün katalog fuzzy
  List<InvoiceOcrLineMatch> matchProducts({
    required List<InvoiceOcrLine> lines,
    required List<ProductCatalogRow> catalog,
  }) {
    return lines.map((line) {
      final match = _productMatcher.bestMatch(
        line.name,
        barcode: line.sku.isEmpty ? null : line.sku,
        catalog: catalog,
      );
      if (match == null) {
        return InvoiceOcrLineMatch(line: line);
      }
      return InvoiceOcrLineMatch(
        line: line,
        matchedProductId: match.product.id,
        matchedProductCode: match.product.code,
        matchedProductName: match.product.name,
        matchScore: match.score,
      );
    }).toList(growable: false);
  }

  /// Cari fuzzy (ad / kod)
  InvoiceOcrCustomerMatch matchCustomer({
    required String partyName,
    required String partyCode,
    required List<Map<String, dynamic>> customers,
  }) {
    final codeQ = partyCode.trim();
    if (codeQ.isNotEmpty) {
      for (final c in customers) {
        final code = (c['code'] ?? '').toString().trim();
        if (code.isNotEmpty &&
            code.toLowerCase() == codeQ.toLowerCase()) {
          return InvoiceOcrCustomerMatch(
            customerId: (c['id'] ?? '').toString(),
            customerCode: code,
            customerName: (c['name'] ?? '').toString(),
            score: 1,
          );
        }
      }
    }
    final nameQ = partyName.trim();
    if (nameQ.isEmpty) {
      return const InvoiceOcrCustomerMatch();
    }
    InvoiceOcrCustomerMatch? best;
    for (final c in customers) {
      final name = (c['name'] ?? '').toString();
      final code = (c['code'] ?? '').toString();
      final scoreName = ProductFuzzyMatcher.similarity(nameQ, name);
      final scoreCode = code.isEmpty
          ? 0.0
          : ProductFuzzyMatcher.similarity(nameQ, code);
      final score = scoreName > scoreCode ? scoreName : scoreCode;
      if (score < 0.45) continue;
      if (best == null || score > best.score) {
        best = InvoiceOcrCustomerMatch(
          customerId: (c['id'] ?? '').toString(),
          customerCode: code,
          customerName: name,
          score: score,
        );
      }
    }
    return best ?? const InvoiceOcrCustomerMatch();
  }
}
