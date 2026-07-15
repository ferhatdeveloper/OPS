// Dosya Adı: pending_transfers_screen.dart
// Açıklama: Logo REST'e bekleyen sync_queue belgelerini listeler / yeniden dener
// Oluşturulma Tarihi: 2026-02-22
// Geliştirici: EXFIN OPS Team
// Son Güncelleme: 2026-07-15

import 'package:flutter/material.dart';

import '../../../../service/job_queue_service.dart';

class PendingTransfersScreen extends StatefulWidget {
  final int initialTabIndex;
  const PendingTransfersScreen({Key? key, this.initialTabIndex = 0})
      : super(key: key);

  @override
  State<PendingTransfersScreen> createState() => _PendingTransfersScreenState();
}

class _PendingTransfersScreenState extends State<PendingTransfersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;
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

  Future<void> _load() async {
    setState(() => _loading = true);
    final jobs = await JobQueueService().getPendingJobs();
    if (!mounted) return;
    setState(() {
      _jobs = jobs;
      _loading = false;
    });
  }

  Future<void> _retryAll() async {
    setState(() => _processing = true);
    await JobQueueService().processQueue();
    await _load();
    if (mounted) setState(() => _processing = false);
  }

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'Bekleyen Aktarımlar',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
            tooltip: 'Logo\'ya yeniden gönder',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Sipariş'),
            Tab(text: 'Fatura'),
            Tab(text: 'Tahsilat'),
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

  Widget _buildList(List<Map<String, dynamic>> jobs) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green.shade300),
            const SizedBox(height: 12),
            const Text(
              'Bekleyen Logo aktarımı yok',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
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
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: error != null
                  ? Colors.orange.shade100
                  : const Color(0xFF375A7F).withOpacity(0.15),
              child: Icon(
                error != null ? Icons.sync_problem : Icons.cloud_queue,
                color: error != null ? Colors.orange : const Color(0xFF375A7F),
              ),
            ),
            title: Text('$type · $entityId'),
            subtitle: Text(
              error != null
                  ? 'Hata ($retry deneme): $error'
                  : 'Oluşturulma: ${job['created_at'] ?? '-'}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.send),
              onPressed: _processing
                  ? null
                  : () async {
                      setState(() => _processing = true);
                      await JobQueueService().processQueue();
                      await _load();
                      if (mounted) setState(() => _processing = false);
                    },
            ),
          ),
        );
      },
    );
  }
}
