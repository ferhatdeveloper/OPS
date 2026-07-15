// Dosya Adı: sync_operations.dart
// Açıklama: Admin paneli için senkronizasyon işlemleri ekranı (Supabase <-> local db)
// Oluşturulma Tarihi: 2024-03-22
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-22

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_manager.dart';

/// {@template SyncOperations}
/// Senkronizasyon işlemleri ekranı: Supabase ile local db arasında veri senkronizasyonunu başlat, durumu göster, logları listele
///
/// Kullanım örneği:
/// ```dart
/// SyncOperations()
/// ```
/// {@endtemplate}
class SyncOperations extends ConsumerStatefulWidget {
  const SyncOperations({Key? key}) : super(key: key);

  @override
  ConsumerState<SyncOperations> createState() => _SyncOperationsState();
}

class _SyncOperationsState extends ConsumerState<SyncOperations> {
  bool _isSyncing = false;
  String _status = 'Hazır';
  List<String> _logs = [];

  Future<void> _startSync() async {
    setState(() {
      _isSyncing = true;
      _status = 'Senkronizasyon başlatıldı...';
      _logs.insert(0, '[${DateTime.now()}] Senkronizasyon başlatıldı');
    });

    try {
      final syncManager = SyncManager();
      final result = await syncManager.syncAll();

      setState(() {
        _isSyncing = false;
        if (result.isSuccess) {
          _status = 'Senkronizasyon başarılı';
          _logs.insert(0,
              '[${DateTime.now()}] Senkronizasyon başarılı: ${result.syncedRecords} kayıt senkronize edildi');
        } else {
          _status = 'Senkronizasyon hatası';
          _logs.insert(0,
              '[${DateTime.now()}] Senkronizasyon hatası: ${result.errorMessage}');
        }
      });
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _status = 'Senkronizasyon hatası';
        _logs.insert(0, '[${DateTime.now()}] Senkronizasyon hatası: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Senkronizasyon İşlemleri')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSyncing ? null : _startSync,
                  icon: const Icon(Icons.sync),
                  label: const Text('Senkronizasyonu Başlat'),
                ),
                const SizedBox(width: 16),
                Text('Durum: $_status'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Senkronizasyon Logları:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) => Text(_logs[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
