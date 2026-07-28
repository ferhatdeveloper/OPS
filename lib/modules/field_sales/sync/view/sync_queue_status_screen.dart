// Dosya Adı: sync_queue_status_screen.dart
// Açıklama: Offline sync kuyruk durumu — dens Logo durum chip listesi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/job_queue_service.dart';
import 'logo_sync_queue_list.dart';

/// {@template sync_queue_status_screen}
/// Offline sync kuyruk durumu ekranı (Logo durum chip’leri).
/// Route: `/field-sales/sync-queue`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, SyncQueueStatusScreen.routeName);
/// ```
/// {@endtemplate}
class SyncQueueStatusScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/sync-queue`
  static const String routeName = '/field-sales/sync-queue';

  const SyncQueueStatusScreen({Key? key}) : super(key: key);

  @override
  State<SyncQueueStatusScreen> createState() => _SyncQueueStatusScreenState();
}

class _SyncQueueStatusScreenState extends State<SyncQueueStatusScreen> {
  /// [_jobs]: Bekleyen kuyruk satırları
  List<Map<String, dynamic>> _jobs = [];

  /// [_loading]: İlk yükleme
  bool _loading = true;

  /// [_processing]: Yeniden gönderim sürüyor
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// {@template sync_queue_load}
  /// Bekleyen işleri yükler.
  /// {@endtemplate}
  Future<void> _load() async {
    setState(() => _loading = true);
    List<Map<String, dynamic>> jobs = const [];
    try {
      jobs = await JobQueueService().getPendingJobs();
    } catch (_) {
      jobs = const [];
    }
    if (!mounted) return;
    setState(() {
      _jobs = jobs;
      _loading = false;
    });
  }

  /// {@template sync_queue_retry}
  /// Kuyruğu yeniden işler.
  /// {@endtemplate}
  Future<void> _retry() async {
    setState(() => _processing = true);
    await JobQueueService().processQueue();
    await _load();
    if (mounted) setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.sync_queue_status');

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _processing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync),
            onPressed: _processing ? null : _retry,
            tooltip: l10n.translate('field_sales.resend_to_logo_tooltip'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: l10n.translate('common.reload'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LogoSyncQueueList(
              jobs: _jobs,
              processing: _processing,
              onRetryOne: _retry,
            ),
    );
  }
}
