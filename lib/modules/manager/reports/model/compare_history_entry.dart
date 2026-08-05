// Dosya Adı: compare_history_entry.dart
// Açıklama: Dönem karşılaştırma kayıtlı geçmiş satırı
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'compare_matrix_models.dart';

/// {@template compare_history_entry}
/// SQLite’ta saklanan karşılaştırma kaydı (sorgu + isteğe bağlı snapshot).
///
/// Kullanım örneği:
/// ```dart
/// final e = CompareHistoryEntry(
///   id: '1',
///   name: 'Ağustos firma',
///   template: CompareTemplate.companyPeriod,
///   query: ComparisonWizardState.fromTemplate(
///     CompareTemplate.companyPeriod,
///   ),
///   createdAt: DateTime.now().toIso8601String(),
///   updatedAt: DateTime.now().toIso8601String(),
/// );
/// ```
/// {@endtemplate}
class CompareHistoryEntry {
  /// [id]: Birincil anahtar
  final String id;

  /// [name]: Kullanıcı etiketi
  final String name;

  /// [template]: Şablon
  final CompareTemplate template;

  /// [query]: Sihirbaz state
  final ComparisonWizardState query;

  /// [result]: Kaydedilmiş matris (opsiyonel)
  final CompareMatrixResult? result;

  /// [createdAt]: ISO oluşturma
  final String createdAt;

  /// [updatedAt]: ISO güncelleme
  final String updatedAt;

  /// {@macro compare_history_entry}
  const CompareHistoryEntry({
    required this.id,
    required this.name,
    required this.template,
    required this.query,
    required this.createdAt,
    required this.updatedAt,
    this.result,
  });
}
