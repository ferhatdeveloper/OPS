// Dosya Adı: visit_queue_filter.dart
// Açıklama: sync_queue satırlarını ziyaret (visit) entity tipine filtreler
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../../core/services/logo_payload_mapper.dart';

/// {@template filter_visit_queue_jobs}
/// Bekleyen sync_queue satırlarından yalnızca ziyaret işlerini döner.
///
/// Parametreler:
/// - [jobs]: Tüm bekleyen kuyruk satırları
///
/// Dönüş değeri:
/// - [List]: `entity_type` visit / visits olan satırlar
///
/// Kullanım örneği:
/// ```dart
/// final visits = filterVisitQueueJobs(allJobs);
/// ```
/// {@endtemplate}
List<Map<String, dynamic>> filterVisitQueueJobs(
  List<Map<String, dynamic>> jobs,
) {
  final visitType = LogoPayloadMapper.visitEntityType.toLowerCase();
  return jobs.where((job) {
    final type = (job['entity_type'] as String? ?? '').toLowerCase();
    return type == visitType || type == 'visits';
  }).toList();
}
