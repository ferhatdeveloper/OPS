// Dosya Adı: sync_log_screen.dart
// Açıklama: Senkronizasyon logları ve durumu takip ekranı
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_manager.dart';
import 'dart:async';

/// {@template SyncLogScreen}
/// Senkronizasyon logları ve durumu takip ekranı
///
/// Kullanım örneği:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(builder: (context) => SyncLogScreen()));
/// ```
/// {@endtemplate}
class SyncLogScreen extends ConsumerStatefulWidget {
  const SyncLogScreen({super.key});

  @override
  ConsumerState<SyncLogScreen> createState() => _SyncLogScreenState();
}

class _SyncLogScreenState extends ConsumerState<SyncLogScreen> {
  List<LogEntry> _logs = [];
  Map<String, dynamic> _syncStatus = {};
  Map<String, int> _syncStatistics = {};
  bool _isAutoSyncEnabled = false;
  Timer? _refreshTimer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await _loadData();
    setState(() {});
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final syncManager = SyncManager();
      final config = syncManager.config;

      setState(() {
        _syncStatus = {
          'auto_sync_enabled': config.autoSyncEnabled,
          'last_sync_time': DateTime.now().toString(),
          'sync_status': 'Aktif',
        };
        _syncStatistics = {
          'Toplam Tablo': 0,
          'Senkronize Edilen': 0,
          'Bekleyen': 0,
        };
        _isAutoSyncEnabled = config.autoSyncEnabled;
      });
    } catch (e) {
      _addLog('❌ Veri yükleme hatası: $e', LogType.error);
    }
  }

  void _addLog(String message, LogType type) {
    setState(() {
      _logs.insert(
          0,
          LogEntry(
            message: message,
            type: type,
            timestamp: DateTime.now(),
          ));

      // Maksimum 100 log tut
      if (_logs.length > 100) {
        _logs = _logs.take(100).toList();
      }
    });
  }

  Future<void> _triggerManualSync() async {
    _addLog('🔄 Manuel sync başlatılıyor...', LogType.info);

    try {
      final syncManager = SyncManager();
      final result = await syncManager.syncAll();

      if (result.isSuccess) {
        _addLog('✅ Manuel sync başarıyla tamamlandı', LogType.success);
      } else {
        _addLog('❌ Manuel sync hatası: ${result.errorMessage}', LogType.error);
      }
      await _loadData();
    } catch (e) {
      _addLog('❌ Manuel sync hatası: $e', LogType.error);
    }
  }

  Future<void> _toggleAutoSync(bool value) async {
    try {
      final syncManager = SyncManager();
      // Auto sync ayarı config üzerinden yapılacak
      _addLog(value ? '🔄 Otomatik sync aktif' : '⏹️ Otomatik sync pasif',
          LogType.info);
      await _loadData();
    } catch (e) {
      _addLog('❌ Otomatik sync değiştirme hatası: $e', LogType.error);
    }
  }

  Future<void> _clearLogs() async {
    setState(() {
      _logs.clear();
    });
    _addLog('🧹 Loglar temizlendi', LogType.info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Logları'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearLogs,
            tooltip: 'Logları Temizle',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusCard(),
          _buildStatisticsCard(),
          _buildControlsCard(),
          Expanded(child: _buildLogsList()),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isAutoSyncEnabled ? Icons.sync : Icons.sync_disabled,
                  color: _isAutoSyncEnabled ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sync Durumu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
                'Otomatik Sync:', _isAutoSyncEnabled ? 'Aktif' : 'Pasif'),
            _buildStatusRow(
                'Son Sync:', _formatDateTime(_syncStatus['last_sync_time'])),
            _buildStatusRow(
                'Durum:', _syncStatus['sync_status'] ?? 'Bilinmiyor'),
            if (_syncStatus['last_sync_error']?.isNotEmpty == true)
              _buildStatusRow('Son Hata:', _syncStatus['last_sync_error'],
                  isError: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Local Veri İstatistikleri',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _syncStatistics.entries
                  .map(
                    (entry) => Chip(
                      label: Text('${entry.key}: ${entry.value}'),
                      backgroundColor: Colors.blue.shade50,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.control_camera, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Kontroller',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Otomatik Sync'),
                    value: _isAutoSyncEnabled,
                    onChanged: _toggleAutoSync,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _triggerManualSync,
                  icon: const Icon(Icons.sync),
                  label: const Text('Manuel Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsList() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.list_alt, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Sync Logları',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_logs.length} log',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz log yok',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return _buildLogItem(log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(LogEntry log) {
    Color backgroundColor;
    IconData icon;

    switch (log.type) {
      case LogType.success:
        backgroundColor = Colors.green.shade50;
        icon = Icons.check_circle;
        break;
      case LogType.error:
        backgroundColor = Colors.red.shade50;
        icon = Icons.error;
        break;
      case LogType.warning:
        backgroundColor = Colors.orange.shade50;
        icon = Icons.warning;
        break;
      case LogType.info:
      default:
        backgroundColor = Colors.blue.shade50;
        icon = Icons.info;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: backgroundColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.message,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(log.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isError ? Colors.red : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : null,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'Hiç sync yapılmamış';

    try {
      if (dateTime is String) {
        final dt = DateTime.parse(dateTime);
        return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return dateTime.toString();
    } catch (e) {
      return dateTime.toString();
    }
  }
}

enum LogType { success, error, warning, info }

class LogEntry {
  final String message;
  final LogType type;
  final DateTime timestamp;

  LogEntry({
    required this.message,
    required this.type,
    required this.timestamp,
  });
}
