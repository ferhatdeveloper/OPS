// Dosya Adı: comparison_wizard_provider.dart
// Açıklama: Esnek karşılaştırma sihirbazı Riverpod state + matris FutureProvider
// Oluşturulma Tarihi: 2026-08-04
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../modules/field_sales/companies/viewmodel/active_company_store.dart';
import '../../../../modules/field_sales/companies/viewmodel/company_context_loader.dart';
import '../../../../service/database_service.dart';
import '../model/compare_history_entry.dart';
import '../model/compare_matrix_models.dart';
import '../model/period_comparison_models.dart';
import 'compare_history_store.dart';
import 'compare_matrix_repository.dart';

/// {@template compare_context_catalog_provider}
/// Sistem firmaları + dönemler (PostgREST → SQLite yedek).
/// {@endtemplate}
final compareContextCatalogProvider =
    FutureProvider.autoDispose<CompanyContextData>((ref) async {
  return const CompanyContextLoader().loadFirmsAndPeriods();
});

/// {@template compare_history_store_provider}
/// Geçmiş store.
/// {@endtemplate}
final compareHistoryStoreProvider = Provider<CompareHistoryStore>((ref) {
  return const CompareHistoryStore();
});

/// {@template compare_history_list_provider}
/// Kayıtlı karşılaştırmalar listesi.
/// {@endtemplate}
final compareHistoryListProvider =
    FutureProvider.autoDispose<List<CompareHistoryEntry>>((ref) async {
  final store = ref.watch(compareHistoryStoreProvider);
  return store.list();
});

/// {@template compare_matrix_snapshot_provider}
/// Geçmişten yüklenen snapshot (null → canlı sorgu).
/// {@endtemplate}
final compareMatrixSnapshotProvider =
    StateProvider.autoDispose<CompareMatrixResult?>((ref) => null);

/// {@template comparison_wizard_notifier}
/// 4 adımlı matris sihirbaz state yönetimi.
///
/// Kullanım örneği:
/// ```dart
/// ref.read(comparisonWizardProvider.notifier).applyTemplate(
///   CompareTemplate.productPeriod,
/// );
/// ```
/// {@endtemplate}
class ComparisonWizardNotifier extends StateNotifier<ComparisonWizardState> {
  /// Snapshot temizleyici (provider üzerinden bağlanır).
  final void Function()? onClearSnapshot;

  /// {@macro comparison_wizard_notifier}
  ComparisonWizardNotifier({this.onClearSnapshot})
      : super(
          ComparisonWizardState.fromTemplate(CompareTemplate.periodOverview),
        );

  /// Şablon uygula (step 0); Firma×Dönem’de ActiveCompany ön seç.
  void applyTemplate(CompareTemplate template) {
    onClearSnapshot?.call();
    var next = ComparisonWizardState.fromTemplate(template).copyWith(step: 0);
    if (template == CompareTemplate.companyPeriod) {
      next = _withActiveCompany(next);
    }
    state = next;
  }

  /// Kayıtlı geçmişi yükle (sonuç adımı).
  void loadHistory(CompareHistoryEntry entry) {
    state = entry.query.copyWith(step: 3);
  }

  /// Adım ileri (validasyon).
  bool nextStep() {
    final s = state;
    if (s.step == 0) {
      onClearSnapshot?.call();
      var next = s.copyWith(step: 1);
      if (s.template == CompareTemplate.companyPeriod &&
          s.companyIds.isEmpty) {
        next = _withActiveCompany(next);
      }
      state = next;
      return true;
    }
    if (s.step == 1) {
      if (!s.isAxesValid) return false;
      onClearSnapshot?.call();
      var next = s.copyWith(step: 2);
      if (s.rowAxis == CompareAxis.company && s.companyIds.isEmpty) {
        next = _withActiveCompany(next);
      }
      state = next;
      return true;
    }
    if (s.step == 2) {
      if (!s.canProceedFromFilters) return false;
      onClearSnapshot?.call();
      state = s.copyWith(step: 3);
      return true;
    }
    return false;
  }

  /// Adım geri.
  void prevStep() {
    if (state.step <= 0) return;
    onClearSnapshot?.call();
    state = state.copyWith(step: state.step - 1);
  }

  /// Sonuç adımına atla (şablon + varsayılan filtreler).
  void jumpToResult() {
    final s = state;
    if (!s.isAxesValid || !s.canProceedFromFilters) return;
    state = s.copyWith(step: 3);
  }

  /// Eksen güncelle.
  void setAxes({CompareAxis? rowAxis, CompareAxis? columnAxis}) {
    state = state.copyWith(
      rowAxis: rowAxis,
      columnAxis: columnAxis,
      template: CompareTemplate.custom,
    );
  }

  /// Dönem dilimleri (max 6 clamp modelde).
  void setPeriods(List<ComparePeriodSlot> periods) {
    state = state.copyWith(periods: periods);
  }

  /// Dönem ekle.
  void addPeriod(ComparePeriodSlot slot) {
    if (state.periods.length >= ComparisonWizardState.maxPeriods) return;
    state = state.copyWith(periods: [...state.periods, slot]);
  }

  /// Dönem sil.
  void removePeriod(String id) {
    if (state.periods.length <= 2) return;
    state = state.copyWith(
      periods: state.periods.where((p) => p.id != id).toList(),
    );
  }

  /// Firma seçimi.
  void setCompanyIds(List<String> ids) {
    state = state.copyWith(companyIds: ids);
  }

  /// Filtre listeleri.
  void setEntityIds(CompareAxis axis, List<String> ids) {
    switch (axis) {
      case CompareAxis.company:
        state = state.copyWith(companyIds: ids);
        break;
      case CompareAxis.product:
        state = state.copyWith(productIds: ids);
        break;
      case CompareAxis.customer:
        state = state.copyWith(customerIds: ids);
        break;
      case CompareAxis.supplier:
        state = state.copyWith(supplierIds: ids);
        break;
      case CompareAxis.salesman:
        state = state.copyWith(salesmanIds: ids);
        break;
      case CompareAxis.region:
        state = state.copyWith(regionIds: ids);
        break;
      case CompareAxis.productGroup:
        state = state.copyWith(productGroupIds: ids);
        break;
      case CompareAxis.brand:
        state = state.copyWith(brandIds: ids);
        break;
      case CompareAxis.period:
      case CompareAxis.none:
        break;
    }
  }

  /// TOP-N.
  void setTopN(int n) {
    final v = n.clamp(5, 50);
    state = state.copyWith(topN: v);
  }

  /// Primary metrik.
  void setPrimaryMetric(PeriodMetricKind kind) {
    state = state.copyWith(primaryMetric: kind);
  }

  ComparisonWizardState _withActiveCompany(ComparisonWizardState s) {
    if (s.companyIds.isNotEmpty) return s;
    final session = ActiveCompanyStore.current;
    if (session == null || session.companyId.isEmpty) return s;
    final key = session.companyNo.isNotEmpty
        ? session.companyNo
        : session.companyId;
    return s.copyWith(companyIds: [key]);
  }
}

/// {@template comparison_wizard_provider}
/// Sihirbaz state.
/// {@endtemplate}
final comparisonWizardProvider = StateNotifierProvider.autoDispose<
    ComparisonWizardNotifier, ComparisonWizardState>((ref) {
  return ComparisonWizardNotifier(
    onClearSnapshot: () {
      ref.read(compareMatrixSnapshotProvider.notifier).state = null;
    },
  );
});

/// {@template compare_matrix_repository_provider}
/// Matris repository.
/// {@endtemplate}
final compareMatrixRepositoryProvider =
    Provider<CompareMatrixRepository>((ref) {
  return const CompareMatrixRepository();
});

/// {@template compare_matrix_result_provider}
/// step==3 iken matris sorgusu (veya geçmiş snapshot).
/// {@endtemplate}
final compareMatrixResultProvider =
    FutureProvider.autoDispose<CompareMatrixResult>((ref) async {
  final wizard = ref.watch(comparisonWizardProvider);
  if (wizard.step < 3) {
    return CompareMatrixResult.empty(wizard);
  }
  final snap = ref.watch(compareMatrixSnapshotProvider);
  if (snap != null) return snap;

  final repo = ref.watch(compareMatrixRepositoryProvider);
  final dbService = await DatabaseService.getInstance();
  final db = await dbService.getDatabase();
  return repo.fetchMatrix(db, wizard);
});
