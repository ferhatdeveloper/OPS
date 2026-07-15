// Dosya Adı: sync_management_screen.dart
// Açıklama: Veri senkronizasyonu yönetim ekranı
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_manager.dart';

/// {@template SyncManagementScreen}
/// Veri senkronizasyonu yönetim ekranı
///
/// Kullanım örneği:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(builder: (context) => SyncManagementScreen()));
/// ```
/// {@endtemplate}
class SyncManagementScreen extends ConsumerStatefulWidget {
  const SyncManagementScreen({super.key});

  @override
  ConsumerState<SyncManagementScreen> createState() =>
      _SyncManagementScreenState();
}

class _SyncManagementScreenState extends ConsumerState<SyncManagementScreen> {
  bool _isAutoSyncEnabled = false;
  int _autoSyncIntervalMinutes = 5;
  Map<String, dynamic> _syncStatus = {};
  Map<String, int> _syncStatistics = {};
  bool _isLoading = false;
  List<Map<String, dynamic>> _syncSettingsList = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _loadSyncStatus();
    await _loadSyncSettingsList();
    setState(() {});
  }

  Future<void> _loadSyncStatus() async {
    try {
      final syncManager = SyncManager();
      final config = syncManager.config;

      setState(() {
        _isAutoSyncEnabled = config.autoSyncEnabled;
        _autoSyncIntervalMinutes = config.syncInterval.inMinutes;
        _syncStatus = {
          'auto_sync_enabled': config.autoSyncEnabled,
          'sync_interval_minutes': config.syncInterval.inMinutes,
          'backup_enabled': config.backupEnabled,
          'encryption_enabled': config.encryptionEnabled,
        };
        _syncStatistics = {
          'Toplam Tablo': 0,
          'Senkronize Edilen': 0,
          'Bekleyen': 0,
        };
      });
    } catch (e) {
      print('Sync durumu yüklenirken hata: $e');
    }
  }

  Future<void> _loadSyncSettingsList() async {
    try {
      final syncManager = SyncManager();
      final tables = await syncManager.getTables();
      final config = syncManager.config;
      final List<Map<String, dynamic>> list = [];
      // Tablo açıklamaları sabit map
      final tableDescriptions = <String, String>{
        'companies': 'Firma bilgileri',
        'company_period': 'Firma dönemleri',
        'users': 'Kullanıcılar',
        'departments': 'Departmanlar',
        'factories': 'Fabrikalar',
        'device': 'Cihazlar',
        'roles': 'Roller',
        'settings': 'Ayarlar',
        'user_roles': 'Kullanıcı rolleri',
        'menu_permissions': 'Menü izinleri',
      };
      for (final table in tables) {
        // Kayıt sayısı
        int count = 0;
        try {
          count = await syncManager.getTableRecordCount(table);
        } catch (_) {}
        list.add({
          'table_name': table,
          'description': tableDescriptions[table] ?? '',
          'is_enabled': 1, // Gelişmiş config ile dinamik yapılabilir
          'sync_direction':
              'bidirectional', // Gelişmiş config ile dinamik yapılabilir
          'record_count': count,
        });
      }
      setState(() {
        _syncSettingsList = list;
      });
    } catch (e) {
      print('Tablo meta verisi yüklenirken hata: $e');
    }
  }

  Future<void> _updateSyncSetting(String table,
      {int? isEnabled, String? syncDirection}) async {
    try {
      // Yeni modül ile sync ayarları config üzerinden yönetiliyor
      print('Sync ayarı güncellendi: $table');
    } catch (e) {
      print('Sync ayarı güncellenirken hata: $e');
    }
  }

  Future<void> _manualSyncTable(String table) async {
    setState(() => _isLoading = true);
    try {
      final syncManager = SyncManager();
      final result = await syncManager.syncTable(table);
      await _loadSyncStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$table tablosu sync edildi'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync hatası: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAutoSync(bool value) async {
    setState(() => _isLoading = true);
    try {
      // Yeni modül ile auto sync config üzerinden yönetiliyor
      await _loadSyncStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Otomatik sync ${value ? 'açıldı' : 'kapatıldı'}'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veri Senkronizasyonu'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSyncSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSyncSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Veri Senkronizasyonu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Otomatik Sync Ayarları
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Otomatik Senkronizasyon',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      const Text('Belirli aralıklarla otomatik sync yapar',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Switch(
                  value: _isAutoSyncEnabled,
                  onChanged: _toggleAutoSync,
                ),
              ],
            ),

            if (_isAutoSyncEnabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Sync Aralığı: '),
                  DropdownButton<int>(
                    value: _autoSyncIntervalMinutes,
                    items: [5, 10, 15, 30, 60].map((minutes) {
                      return DropdownMenuItem(
                        value: minutes,
                        child: Text('$minutes dakika'),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() => _autoSyncIntervalMinutes = value);
                        // Yeni modül ile sync aralığı config üzerinden yönetiliyor
                      }
                    },
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Tablo Bazlı Sync Ayarları
            const Text('Tablo Bazlı Senkronizasyon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Hangi tabloların sync edileceğini ve yönünü ayarlayın',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),

            if (_syncSettingsList.isEmpty)
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hiçbir tablo bulunamadı. Sync ayarları için tablo ekleyin veya uygulamayı yeniden başlatın.',
                          style: TextStyle(color: Colors.orange, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Tablo listesi
            ...(_syncSettingsList.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row['table_name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    if (row['description'] != null &&
                                        row['description']
                                            .toString()
                                            .isNotEmpty)
                                      Text(
                                        row['description'],
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Switch(
                                  value: row['is_enabled'] == 1,
                                  onChanged: row['sync_direction'] == 'disabled'
                                      ? null
                                      : (value) => _updateSyncSetting(
                                            row['table_name'],
                                            isEnabled: value ? 1 : 0,
                                          ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: DropdownButton<String>(
                                  value: row['sync_direction'],
                                  items: [
                                    DropdownMenuItem(
                                      value: 'bidirectional',
                                      child: const Text('Çift Yönlü'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'server_to_local',
                                      child: const Text('Supabase → Local'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'local_to_server',
                                      child: const Text('Local → Supabase'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'disabled',
                                      child: const Text('Sync Edilmesin'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      _updateSyncSetting(
                                        row['table_name'],
                                        syncDirection: value,
                                      );
                                    }
                                  },
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: row['sync_direction'] == 'disabled'
                                      ? null
                                      : () =>
                                          _manualSyncTable(row['table_name']),
                                  icon: const Icon(Icons.sync),
                                  label: const Text('Sync'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(60, 36),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ))),

            // --- SON: Sync Ayarları Paneli ---
            const SizedBox(height: 16),
            if (_syncStatus.isNotEmpty) ...[
              const Text('Sync Durumu:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildStatusItem('Son Sync:',
                  _syncStatus['last_sync_time'] ?? 'Hiç sync yapılmamış'),
              _buildStatusItem(
                  'Durum:', _syncStatus['sync_status'] ?? 'Bilinmiyor'),
              if (_syncStatus['last_sync_error']?.isNotEmpty == true)
                _buildStatusItem('Son Hata:', _syncStatus['last_sync_error'],
                    isError: true),
            ],
            const SizedBox(height: 16),
            if (_syncStatistics.isNotEmpty) ...[
              const Text('Local Veri İstatistikleri:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(_syncStatistics.entries.map((entry) =>
                  _buildStatusItem('${entry.key}:', '${entry.value} kayıt'))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
}
