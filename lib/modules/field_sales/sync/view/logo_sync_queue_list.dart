// Dosya Adı: logo_sync_queue_list.dart
// Açıklama: Sync queue dens liste gövdesi + Logo durum chip’leri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import 'logo_queue_status_chip.dart';
import 'offline_queue_detail_screen.dart';

/// {@template logo_sync_queue_list}
/// Bekleyen Logo sync_queue satırlarını dens flat listeler.
///
/// Kullanım örneği:
/// ```dart
/// LogoSyncQueueList(
///   jobs: jobs,
///   processing: false,
///   onRetryOne: () async {},
/// )
/// ```
/// {@endtemplate}
class LogoSyncQueueList extends StatelessWidget {
  /// [jobs]: sync_queue satırları
  final List<Map<String, dynamic>> jobs;

  /// [processing]: Yeniden gönderim sürüyor
  final bool processing;

  /// [onRetryOne]: Tek satır / kuyruk yeniden dene
  final Future<void> Function()? onRetryOne;

  /// {@macro logo_sync_queue_list}
  const LogoSyncQueueList({
    Key? key,
    required this.jobs,
    this.processing = false,
    this.onRetryOne,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.green.shade300,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.translate('field_sales.no_documents_to_transfer'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.translate('field_sales.queue_empty_hint'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      cacheExtent: 500,
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        final type = job['entity_type']?.toString() ?? '-';
        final entityId = job['entity_id']?.toString() ?? '-';
        final retry = job['retry_count'] ?? 0;
        final error = job['last_error']?.toString();
        final status = LogoQueueStatus.fromJob(job);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                OfflineQueueDetailScreen.routeName,
                arguments: job,
              );
            },
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: status.color.withOpacity(0.12),
              child: Icon(
                status == LogoQueueStatus.pending
                    ? Icons.cloud_queue
                    : Icons.sync_problem,
                size: 18,
                color: status.color,
              ),
            ),
            title: Text(
              '$type · $entityId',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              error != null && error.isNotEmpty
                  ? '${l10n.translate('common.error')} ($retry): $error'
                  : '${job['created_at'] ?? '-'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            trailing: onRetryOne == null
                ? LogoQueueStatusChip(status: status)
                : SizedBox(
                    width: 118,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(child: LogoQueueStatusChip(status: status)),
                        IconButton(
                          icon: const Icon(Icons.send, size: 18),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: processing
                              ? null
                              : () async {
                                  await onRetryOne!();
                                },
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
