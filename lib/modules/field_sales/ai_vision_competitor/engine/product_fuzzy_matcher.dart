// Dosya Adı: product_fuzzy_matcher.dart
// Açıklama: Raf ürün adı ↔ yerel katalog fuzzy eşleme
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../../products/model/product_catalog_row.dart';

/// {@template product_fuzzy_match}
/// Tek eşleşme sonucu.
/// {@endtemplate}
class ProductFuzzyMatch {
  /// [product]: Yerel ürün
  final ProductCatalogRow product;

  /// [score]: 0–1 benzerlik
  final double score;

  /// {@macro product_fuzzy_match}
  const ProductFuzzyMatch({
    required this.product,
    required this.score,
  });
}

/// {@template product_fuzzy_matcher}
/// İsim / barkod fuzzy match (Levenshtein + token).
///
/// Kullanım örneği:
/// ```dart
/// final m = ProductFuzzyMatcher().bestMatch('Kola 330', catalog);
/// ```
/// {@endtemplate}
class ProductFuzzyMatcher {
  /// Minimum skor
  final double minScore;

  /// {@macro product_fuzzy_matcher}
  const ProductFuzzyMatcher({this.minScore = 0.45});

  /// Normalize
  static String normalize(String raw) {
    var s = raw.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[^a-zA-Z0-9\u00C0-\u024F\u0600-\u06FF\s]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Levenshtein mesafesi
  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      var diag = prev[0];
      prev[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final tmp = prev[j];
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        prev[j] = [
          prev[j] + 1,
          prev[j - 1] + 1,
          diag + cost,
        ].reduce((x, y) => x < y ? x : y);
        diag = tmp;
      }
    }
    return prev[b.length];
  }

  /// Benzerlik 0–1
  static double similarity(String a, String b) {
    final na = normalize(a);
    final nb = normalize(b);
    if (na.isEmpty || nb.isEmpty) return 0;
    if (na == nb) return 1;
    if (na.contains(nb) || nb.contains(na)) {
      final shorter = na.length < nb.length ? na.length : nb.length;
      final longer = na.length > nb.length ? na.length : nb.length;
      return 0.7 + 0.3 * (shorter / longer);
    }
    final dist = levenshtein(na, nb);
    final maxLen = na.length > nb.length ? na.length : nb.length;
    return 1.0 - (dist / maxLen);
  }

  /// En iyi eşleşme
  ProductFuzzyMatch? bestMatch(
    String queryName, {
    String? barcode,
    required List<ProductCatalogRow> catalog,
  }) {
    final qBar = (barcode ?? '').trim();
    if (qBar.isNotEmpty) {
      for (final p in catalog) {
        if (p.barcode.trim() == qBar) {
          return ProductFuzzyMatch(product: p, score: 1);
        }
      }
    }
    ProductFuzzyMatch? best;
    for (final p in catalog) {
      final scoreName = similarity(queryName, p.name);
      final scoreCode = similarity(queryName, p.code);
      final score = scoreName > scoreCode ? scoreName : scoreCode;
      if (score < minScore) continue;
      if (best == null || score > best.score) {
        best = ProductFuzzyMatch(product: p, score: score);
      }
    }
    return best;
  }
}
