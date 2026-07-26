// Dosya Adı: admin_kpi_provider.dart
// Açıklama: Yönetici KPI özeti Riverpod FutureProvider
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../service/database_service.dart';
import '../model/admin_kpi_summary.dart';
import 'admin_kpi_repository.dart';

/// {@template admin_kpi_repository_provider}
/// [AdminKpiRepository] örneği.
/// {@endtemplate}
final adminKpiRepositoryProvider = Provider<AdminKpiRepository>((ref) {
  return const AdminKpiRepository();
});

/// {@template admin_kpi_summary_provider}
/// Bugünkü yönetici KPI özetini SQLite aggregate ile yükler.
///
/// Kullanım örneği:
/// ```dart
/// final async = ref.watch(adminKpiSummaryProvider);
/// ```
/// {@endtemplate}
final adminKpiSummaryProvider =
    FutureProvider.autoDispose<AdminKpiSummary>((ref) async {
  final repo = ref.watch(adminKpiRepositoryProvider);
  final dbService = await DatabaseService.getInstance();
  final db = await dbService.getDatabase();
  return repo.fetchToday(db);
});
