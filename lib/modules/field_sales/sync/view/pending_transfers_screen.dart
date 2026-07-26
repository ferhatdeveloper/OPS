// Dosya Adı: pending_transfers_screen.dart
// Açıklama: Logo REST'e bekleyen sync_queue belgelerini listeler / yeniden dener
// Oluşturulma Tarihi: 2026-02-22
// Geliştirici: EXFIN OPS Team
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/job_queue_service.dart';
import 'logo_sync_queue_list.dart';

/// {@template pending_transfers_screen}
/// Bekleyen Logo aktarımlarını sekmeli listeler.
///
/// Kullanım örneği:
/// ```dart
/// const PendingTransfersScreen();
/// ```
/// {@endtemplate}
class PendingTransfersScreen extends StatefulWidget {
  /// [initialTabIndex]: Başlangıç sekmesi (0–3)
  final int initialTabIndex;

  /// {@macro pending_transfers_screen}
  const PendingTransfersScreen({Key? key, this.initialTabIndex = 0})
      : super(key: key);

  @override
  State<PendingTransfersScreen> createState() => _PendingTransfersScreenState();
}

class _PendingTransfersScreenState extends State<PendingTransfersScreen>
    with SingleTickerProviderStateMixin {
  /// [_tabController]: Tip sekmeleri
  late TabController _tabController;

  /// [_jobs]: Bekleyen kuyruk satırları
  List<Map<String, dynamic>> _jobs = [];

  /// [_loading]: İlk yükleme
  bool _loading = true;

  /// [_processing]: Yeniden gönderim sürüyor
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// {@template _load}
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

  /// {@template _retry_all}
  /// Tüm kuyruğu yeniden işler.
  /// {@endtemplate}
  Future<void> _retryAll() async {
    setState(() => _processing = true);
    await JobQueueService().processQueue();
    await _load();
    if (mounted) setState(() => _processing = false);
  }

  /// {@template _filter}
  /// Tip filtresi uygular.
  /// {@endtemplate}
  List<Map<String, dynamic>> _filter(String type) {
    if (type == 'all') return _jobs;
    return _jobs
        .where((j) =>
            (j['entity_type'] as String? ?? '')
                .toLowerCase()
                .contains(type))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          l10n.translate('field_sales.stubs.sync_queue_status'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF375A7F),
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
            onPressed: _processing ? null : _retryAll,
            tooltip: l10n.translate('field_sales.resend_to_logo_tooltip'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: l10n.translate('common.reload'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: l10n.translate('common.all')),
            Tab(text: l10n.translate('field_sales.order')),
            Tab(text: l10n.translate('field_sales.invoice')),
            Tab(text: l10n.translate('field_sales.collection')),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_filter('all')),
                _buildList(_filter('order')),
                _buildList(_filter('invoice')),
                _buildList(_filter('collection')),
              ],
            ),
    );
  }

  /// {@template _build_list}
  /// Filtrelenmiş iş listesini dens Logo durum chip’leriyle çizer.
  /// {@endtemplate}
  Widget _buildList(List<Map<String, dynamic>> jobs) {
    return LogoSyncQueueList(
      jobs: jobs,
      processing: _processing,
      onRetryOne: () async {
        setState(() => _processing = true);
        await JobQueueService().processQueue();
        await _load();
        if (mounted) setState(() => _processing = false);
      },
    );
  }
}
