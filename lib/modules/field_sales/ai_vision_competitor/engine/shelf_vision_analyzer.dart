// Dosya Adı: shelf_vision_analyzer.dart
// Açıklama: AiGateway.visionAnalyze → ShelfPriceLine listesi + katalog karşılaştırma
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import '../../../../core/ai/ai_completion.dart';
import '../../../../core/ai/ai_gateway.dart';
import '../../products/model/product_catalog_row.dart';
import '../model/shelf_price_line.dart';
import 'price_text_parser.dart';
import 'product_fuzzy_matcher.dart';

/// {@template shelf_vision_analyze_result}
/// Vision analiz sonucu.
/// {@endtemplate}
class ShelfVisionAnalyzeResult {
  /// [status]
  final AiCompletionStatus status;

  /// [lines]
  final List<ShelfPriceLine> lines;

  /// [l10nKey]
  final String? l10nKey;

  /// {@macro shelf_vision_analyze_result}
  const ShelfVisionAnalyzeResult({
    required this.status,
    this.lines = const [],
    this.l10nKey,
  });

  bool get isOk => status == AiCompletionStatus.ok && lines.isNotEmpty;
}

/// {@template shelf_vision_analyzer}
/// Fotoğraf → satırlar; görüntü loglanmaz.
/// {@endtemplate}
class ShelfVisionAnalyzer {
  final AiGateway _gateway;
  final ProductFuzzyMatcher _matcher;

  /// {@macro shelf_vision_analyzer}
  ShelfVisionAnalyzer({
    AiGateway? gateway,
    ProductFuzzyMatcher matcher = const ProductFuzzyMatcher(),
  })  : _gateway = gateway ?? AiGateway(),
        _matcher = matcher;

  /// Vision çağrısı
  Future<ShelfVisionAnalyzeResult> analyzeImage({
    required String imageBase64,
    String imageMimeType = 'image/jpeg',
    String? hint,
  }) async {
    final settings = await _gateway.loadSettings();
    if (!settings.hasActiveKey) {
      return const ShelfVisionAnalyzeResult(
        status: AiCompletionStatus.noKey,
        l10nKey: 'ai.no_api_key',
      );
    }
    final r = await _gateway.visionAnalyze(
      imageBase64: imageBase64,
      imageMimeType: imageMimeType,
      userHint: hint,
    );
    if (!r.isOk) {
      return ShelfVisionAnalyzeResult(
        status: r.status,
        l10nKey: r.l10nKey ?? 'ai.request_failed',
      );
    }
    final lines = parseLinesJson(r.text!);
    if (lines.isEmpty) {
      return const ShelfVisionAnalyzeResult(
        status: AiCompletionStatus.error,
        l10nKey: 'field_sales.ai_vision.err_parse',
      );
    }
    return ShelfVisionAnalyzeResult(
      status: AiCompletionStatus.ok,
      lines: lines,
    );
  }

  /// JSON → satırlar (test)
  static List<ShelfPriceLine> parseLinesJson(String text) {
    final trimmed = text.trim();
    String body = trimmed;
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final m = fence.firstMatch(trimmed);
    if (m != null) {
      body = m.group(1)!.trim();
    } else {
      final start = trimmed.indexOf('[');
      final end = trimmed.lastIndexOf(']');
      if (start >= 0 && end > start) {
        body = trimmed.substring(start, end + 1);
      }
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is! List) return const [];
      final out = <ShelfPriceLine>[];
      for (final e in decoded) {
        if (e is! Map) continue;
        final map = Map<String, dynamic>.from(e);
        var line = ShelfPriceLine.fromJson(map);
        if (line.price == null && map['price'] is String) {
          line = line.copyWith(
            price: PriceTextParser.parse(map['price'] as String),
          );
        }
        if (line.name.isEmpty) continue;
        out.add(line);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Katalog karşılaştırma
  List<ShelfPriceComparison> compareToCatalog({
    required List<ShelfPriceLine> lines,
    required List<ProductCatalogRow> catalog,
  }) {
    return lines.map((line) {
      final match = _matcher.bestMatch(line.name, catalog: catalog);
      if (match == null) {
        return ShelfPriceComparison(line: line);
      }
      return ShelfPriceComparison(
        line: line,
        matchedProductId: match.product.id,
        matchedProductCode: match.product.code,
        matchedProductName: match.product.name,
        ourPrice: match.product.price,
        matchScore: match.score,
      );
    }).toList(growable: false);
  }
}
