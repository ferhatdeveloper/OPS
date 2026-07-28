// Dosya Adı: logo_job_status_screen.dart
// Açıklama: Logo REST iş kuyruğu — dens durum chip listesi (gerçek sync_queue)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/job_queue_service.dart';
import '../model/logo_job_record.dart';
import '../viewmodel/logo_job_store.dart';
import 'logo_sync_queue_list.dart';

/// {@template logo_job_status_screen}
/// Logo REST iş kuyruğu durumu ekranı (durum chip’leri).
/// Kaynak: SQLite `sync_queue` (JobQueueService / [LogoJobStore]).
/// Route: `/field-sales/logo-jobs`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, LogoJobStatusScreen.routeName);
/// ```
/// {@endtemplate}
class LogoJobStatusScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/logo-jobs`
  static const String routeName = '/field-sales/logo-jobs';

  /// [jobs]: Opsiyonel dens satırlar (null → SQLite sync_queue)
  final List<LogoJobRecord>? jobs;

  /// [store]: Opsiyonel store (null → varsayılan [LogoJobStore])
  final LogoJobStore? store;

  const LogoJobStatusScreen({
    Key? key,
    this.jobs,
    this.store,
  }) : super(key: key);

  @override
  State<LogoJobStatusScreen> createState() => _LogoJobStatusScreenState();
}

class _LogoJobStatusScreenState extends State<LogoJobStatusScreen> {
  /// [_jobs]: Logo kuyruk dens satırları
  List<LogoJobRecord> _jobs = const [];

  /// [_loading]: İlk yükleme
  bool _loading = true;

  /// [_processing]: Yeniden gönderim sürüyor
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// {@template logo_jobs_load}
  /// Gerçek job_queue (`sync_queue`) satırlarını yükler.
  /// {@endtemplate}
  Future<void> _load() async {
    final injected = widget.jobs;
    if (injected != null) {
      if (!mounted) return;
      setState(() {
        _jobs = injected;
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    List<LogoJobRecord> jobs = const [];
    try {
      final store = widget.store ?? const LogoJobStore();
      jobs = await store.loadAll();
    } catch (_) {
      jobs = const [];
    }
    if (!mounted) return;
    setState(() {
      _jobs = jobs;
      _loading = false;
    });
  }

  /// {@template logo_jobs_retry}
  /// Kuyruğu yeniden işler, ardından gerçek satırları yeniler.
  /// {@endtemplate}
  Future<void> _retry() async {
    setState(() => _processing = true);
    try {
      await JobQueueService().processQueue();
    } catch (_) {
      // Yeniden yükleme yine de yapılır
    }
    await _load();
    if (mounted) setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.logo_job_status');

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
              jobs: _jobs.map((e) => e.toMap()).toList(growable: false),
              processing: _processing,
              onRetryOne: _retry,
            ),
    );
  }
}
