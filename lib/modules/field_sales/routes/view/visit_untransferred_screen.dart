// Dosya Adı: visit_untransferred_screen.dart
// Açıklama: Transfer edilmeyen ziyaretler — dens visit Logo sync kuyruğu
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/job_queue_service.dart';
import '../../sync/view/logo_sync_queue_list.dart';
import '../viewmodel/visit_queue_filter.dart';

/// {@template visit_untransferred_screen}
/// Plasiyer henüz merkezi sisteme aktarılmamış ziyaret kuyruğunu görür.
///
/// Rota: `/field-sales/visit-untransferred`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, VisitUntransferredScreen.routeName);
/// ```
/// {@endtemplate}
class VisitUntransferredScreen extends StatefulWidget {
  /// [routeName]: GoRouter / named route yolu
  static const String routeName = '/field-sales/visit-untransferred';

  /// [pendingJobsLoader]: Test / enjeksiyon için bekleyen iş yükleyici
  final Future<List<Map<String, dynamic>>> Function()? pendingJobsLoader;

  /// [onRetryQueue]: Test / enjeksiyon için kuyruk yeniden işleme
  final Future<void> Function()? onRetryQueue;

  const VisitUntransferredScreen({
    Key? key,
    this.pendingJobsLoader,
    this.onRetryQueue,
  }) : super(key: key);

  @override
  State<VisitUntransferredScreen> createState() =>
      _VisitUntransferredScreenState();
}

class _VisitUntransferredScreenState extends State<VisitUntransferredScreen> {
  /// [_jobs]: Filtrelenmiş visit kuyruk satırları
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

  /// {@template visit_untransferred_load}
  /// Bekleyen işleri yükler ve visit tipine filtreler.
  /// {@endtemplate}
  Future<void> _load() async {
    setState(() => _loading = true);
    List<Map<String, dynamic>> jobs = const [];
    try {
      final loader = widget.pendingJobsLoader ??
          () => JobQueueService().getPendingJobs();
      jobs = filterVisitQueueJobs(await loader());
    } catch (_) {
      jobs = const [];
    }
    if (!mounted) return;
    setState(() {
      _jobs = jobs;
      _loading = false;
    });
  }

  /// {@template visit_untransferred_retry}
  /// Visit kuyruğunu yeniden işler.
  /// {@endtemplate}
  Future<void> _retry() async {
    setState(() => _processing = true);
    try {
      final retry = widget.onRetryQueue ??
          () => JobQueueService().processQueue();
      await retry();
    } catch (_) {}
    await _load();
    if (mounted) setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          l10n.translate('field_sales.stubs.visit_untransferred'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
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
