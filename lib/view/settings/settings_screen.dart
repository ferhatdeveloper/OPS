// Dosya Adı: settings_screen.dart
// Açıklama: Uygulama ayarları ekranı
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:flutter/material.dart';
import '../../service/database_service.dart';
import '../../service/theme_service.dart';
import '../../service/language_service.dart';
import 'sync_log_screen.dart';

/// {@template SettingsScreen}
/// Uygulama ayarları ekranı
///
/// Kullanım örneği:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
/// ```
/// {@endtemplate}
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late DatabaseService _databaseService;
  late ThemeService _themeService;
  late LanguageService _languageService;

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
    _loadSyncSettingsList();
  }

  Future<void> _initializeServices() async {
    _databaseService = await DatabaseService.getInstance();
    _themeService = ThemeService();
    _languageService = LanguageService();

    await _loadSyncStatus();
    await _loadSyncStatistics();

    setState(() {});
  }

  Future<void> _loadSyncStatus() async {
    try {
      _syncStatus = await _databaseService.getSyncStatus();
      _isAutoSyncEnabled = _syncStatus['auto_sync_enabled'] ?? false;
      _autoSyncIntervalMinutes = _syncStatus['auto_sync_interval_minutes'] ?? 5;
    } catch (e) {
      print('Sync durumu yüklenirken hata: $e');
    }
  }

  Future<void> _loadSyncStatistics() async {
    try {
      _syncStatistics = await _databaseService.getSyncStatistics();
    } catch (e) {
      print('Sync istatistikleri yüklenirken hata: $e');
    }
  }

  Future<void> _loadSyncSettingsList() async {
    try {
      final result = await _databaseService
          .getDatabase()
          .then((db) => db.query('sync_settings'));
      setState(() {
        _syncSettingsList = result;
      });
    } catch (e) {
      print('Sync ayarları yüklenirken hata: $e');
    }
  }

  Future<void> _updateSyncSetting(String table,
      {int? isEnabled, String? syncDirection}) async {
    try {
      final current =
          _syncSettingsList.firstWhere((row) => row['table_name'] == table);
      final db = await _databaseService.getDatabase();
      await db.update(
        'sync_settings',
        {
          'is_enabled': isEnabled ?? current['is_enabled'],
          'sync_direction': syncDirection ?? current['sync_direction'],
        },
        where: 'table_name = ?',
        whereArgs: [table],
      );
      await _loadSyncSettingsList();
    } catch (e) {
      print('Sync ayarı güncellenirken hata: $e');
    }
  }

  Future<void> _manualSyncTable(String table) async {
    setState(() => _isLoading = true);
    try {
      await _databaseService.manualSyncTableFromSupabase(table);
      await _loadSyncStatus();
      await _loadSyncStatistics();
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
      if (value) {
        await _databaseService.startAutoSync(
            interval: Duration(minutes: _autoSyncIntervalMinutes));
      } else {
        await _databaseService.stopAutoSync();
      }

      await _loadSyncStatus();
      setState(() => _isAutoSyncEnabled = value);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              value ? 'Otomatik sync başlatıldı' : 'Otomatik sync durduruldu'),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerManualSync() async {
    setState(() => _isLoading = true);

    try {
      await _databaseService.triggerManualSync();
      await _loadSyncStatus();
      await _loadSyncStatistics();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manuel sync başarıyla tamamlandı'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
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
                  const SizedBox(height: 24),
                  _buildDatabaseSecuritySection(),
                  const SizedBox(height: 24),
                  _buildThemeSection(),
                  const SizedBox(height: 24),
                  _buildLanguageSection(),
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
            // Otomatik Sync Switch
            SwitchListTile(
              title: const Text('Otomatik Senkronizasyon'),
              subtitle: Text(
                  'Her $_autoSyncIntervalMinutes dakikada bir otomatik sync'),
              value: _isAutoSyncEnabled,
              onChanged: _toggleAutoSync,
            ),
            // Manuel Sync Butonu
            ElevatedButton.icon(
              onPressed: _triggerManualSync,
              icon: const Icon(Icons.sync),
              label: const Text('Manuel Sync Başlat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SyncLogScreen()),
                );
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('Sync Loglarını Görüntüle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // --- YENİ: Sync Ayarları Paneli ---
            if (_syncSettingsList.isNotEmpty) ...[
              const Text('Tablo Bazlı Sync Yönetimi:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._syncSettingsList.map((row) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 2,
                              child: Text(row['table_name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500))),
                          Expanded(
                            flex: 2,
                            child: DropdownButton<String>(
                              value: row['sync_direction'],
                              items: const [
                                DropdownMenuItem(
                                    value: 'bidirectional',
                                    child: Text('Çift Yönlü')),
                                DropdownMenuItem(
                                    value: 'supabase_to_local',
                                    child: Text('Supabase → Local')),
                                DropdownMenuItem(
                                    value: 'local_to_supabase',
                                    child: Text('Local → Supabase')),
                                DropdownMenuItem(
                                    value: 'none',
                                    child: Text('Sync Edilmesin')),
                              ],
                              onChanged: (val) => _updateSyncSetting(
                                  row['table_name'],
                                  syncDirection: val),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Switch(
                              value: row['is_enabled'] == 1,
                              onChanged: (val) => _updateSyncSetting(
                                  row['table_name'],
                                  isEnabled: val ? 1 : 0),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () =>
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
                    ),
                  )),
            ],
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

  Widget _buildThemeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Tema Ayarları',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tema ayarları buraya eklenecek
            const Text('Tema ayarları yakında eklenecek...'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Dil Ayarları',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Dil ayarları buraya eklenecek
            const Text('Dil ayarları yakında eklenecek...'),
          ],
        ),
      ),
    );
  }

  Widget _buildDatabaseSecuritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Veritabanı Güvenliği',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Güvenlik Durumu
            FutureBuilder<Map<String, dynamic>>(
              future: _databaseService.getDatabaseSecurityStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text('Hata: ${snapshot.error}');
                }

                final securityStatus = snapshot.data ?? {};
                final isEncrypted = securityStatus['is_encrypted'] ?? false;
                final securityLevel = securityStatus['security_level'] ?? 'low';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusItem(
                        'Şifreleme:', isEncrypted ? 'Aktif' : 'Pasif'),
                    _buildStatusItem('Güvenlik Seviyesi:',
                        securityLevel == 'high' ? 'Yüksek' : 'Düşük'),
                    const SizedBox(height: 16),

                    // Güvenlik Ayarları Butonları
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await _databaseService
                                    .configureDatabaseSecurity(
                                  enableEncryption: true,
                                  enableBackup: true,
                                  enableAuditLog: true,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Güvenlik ayarları yapılandırıldı'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                setState(() {});
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Hata: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.security),
                            label: const Text('Güvenliği Etkinleştir'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
