// Dosya Adı: period_comparison_provider.dart
// Açıklama: Dönem karşılaştırma Riverpod state + FutureProvider
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../service/database_service.dart';
import '../model/period_comparison_models.dart';
import 'period_comparison_repository.dart';

/// {@template period_compare_selection}
/// Preset + isteğe bağlı özel A/B aralıkları.
///
/// Kullanım örneği:
/// ```dart
/// const s = PeriodCompareSelection(
///   preset: PeriodComparePreset.thisMonthVsLast,
/// );
/// ```
/// {@endtemplate}
class PeriodCompareSelection {
  /// [preset]: Dens ön ayar
  final PeriodComparePreset preset;

  /// [customA]: custom preset dönem A
  final PeriodDateRange? customA;

  /// [customB]: custom preset dönem B
  final PeriodDateRange? customB;

  /// {@macro period_compare_selection}
  const PeriodCompareSelection({
    required this.preset,
    this.customA,
    this.customB,
  });

  /// Varsayılan: bu ay × geçen ay.
  static const PeriodCompareSelection initial = PeriodCompareSelection(
    preset: PeriodComparePreset.thisMonthVsLast,
  );

  /// Kopya.
  PeriodCompareSelection copyWith({
    PeriodComparePreset? preset,
    PeriodDateRange? customA,
    PeriodDateRange? customB,
    bool clearCustom = false,
  }) {
    return PeriodCompareSelection(
      preset: preset ?? this.preset,
      customA: clearCustom ? null : (customA ?? this.customA),
      customB: clearCustom ? null : (customB ?? this.customB),
    );
  }
}

/// {@template period_comparison_repository_provider}
/// Repository örneği.
/// {@endtemplate}
final periodComparisonRepositoryProvider =
    Provider<PeriodComparisonRepository>((ref) {
  return const PeriodComparisonRepository();
});

/// {@template period_compare_selection_provider}
/// Dens preset / özel aralık seçimi.
/// {@endtemplate}
final periodCompareSelectionProvider =
    StateProvider.autoDispose<PeriodCompareSelection>((ref) {
  return PeriodCompareSelection.initial;
});

/// {@template period_comparison_result_provider}
/// Seçime göre SQLite A/B metrik karşılaştırması.
/// {@endtemplate}
final periodComparisonResultProvider =
    FutureProvider.autoDispose<PeriodComparisonResult>((ref) async {
  final selection = ref.watch(periodCompareSelectionProvider);
  final repo = ref.watch(periodComparisonRepositoryProvider);
  final dbService = await DatabaseService.getInstance();
  final db = await dbService.getDatabase();
  return repo.fetch(
    db,
    preset: selection.preset,
    customA: selection.customA,
    customB: selection.customB,
  );
});
