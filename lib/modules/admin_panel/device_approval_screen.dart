// Dosya Adı: device_approval_screen.dart
// Açıklama: Cihaz kayıt onaylama işlemlerinin yapıldığı admin panel ekranı
// Oluşturulma Tarihi: 2024-12-19
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-12-19

import 'package:flutter/material.dart';
// supabase removed

/// {@template DeviceApprovalScreen}
/// Cihaz kayıt onaylama işlemlerinin yapıldığı admin panel ekranı
///
/// Kullanım örneği:
/// ```dart
/// DeviceApprovalScreen()
/// ```
/// {@endtemplate}
class DeviceApprovalScreen extends StatefulWidget {
  const DeviceApprovalScreen({Key? key}) : super(key: key);

  @override
  State<DeviceApprovalScreen> createState() => _DeviceApprovalScreenState();
}

class _DeviceApprovalScreenState extends State<DeviceApprovalScreen> {
  List<Map<String, dynamic>> _pendingDevices = [];
  List<Map<String, dynamic>> _approvedDevices = [];
  List<Map<String, dynamic>> _rejectedDevices = [];
  List<Map<String, dynamic>> _blockedDevices = [];
  bool _isLoading = true;
  String _selectedFilter =
      'pending'; // 'pending', 'approved', 'rejected', 'blocked'

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  /// {@template loadDevices}
  /// Supabase'den cihaz kayıtlarını yükler
  ///
  /// Parametreler:
  /// - Yok
  ///
  /// Dönüş değeri:
  /// - [Future<void>]: Yükleme işlemi tamamlandığında döner
  ///
  /// Fırlatılan hatalar:
  /// - [Exception]: Veritabanı bağlantı hatası
  /// {@endtemplate}
  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);

    try {
      final client = MockSupabase.instance.client;

      // Bekleyen cihazlar (approval_status = 0)
      final pendingResult = await client
          .from('device')
          .select()
          .eq('approval_status', 0)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      // Onaylanmış cihazlar (approval_status = 1)
      final approvedResult = await client
          .from('device')
          .select()
          .eq('approval_status', 1)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      // Reddedilmiş cihazlar (approval_status = 3)
      final rejectedResult = await client
          .from('device')
          .select()
          .eq('approval_status', 3)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      // Bloklanmış cihazlar (approval_status = 5)
      final blockedResult = await client
          .from('device')
          .select()
          .eq('approval_status', 5)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      setState(() {
        _pendingDevices = List<Map<String, dynamic>>.from(pendingResult);
        _approvedDevices = List<Map<String, dynamic>>.from(approvedResult);
        _rejectedDevices = List<Map<String, dynamic>>.from(rejectedResult);
        _blockedDevices = List<Map<String, dynamic>>.from(blockedResult);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cihazlar yüklenirken hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// {@template approveDevice}
  /// Cihazı onaylar
  ///
  /// Parametreler:
  /// - [deviceId]: Onaylanacak cihazın ID'si
  ///
  /// Dönüş değeri:
  /// - [Future<void>]: Onaylama işlemi tamamlandığında döner
  ///
  /// Fırlatılan hatalar:
  /// - [Exception]: Veritabanı güncelleme hatası
  /// {@endtemplate}
  Future<void> _approveDevice(String deviceId) async {
    try {
      final client = MockSupabase.instance.client;

      await client.from('device').update({
        'approval_status': 1,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', deviceId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cihaz başarıyla onaylandı ve aktifleştirildi'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDevices(); // Listeyi yenile
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Onaylama hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// {@template rejectDevice}
  /// Cihazı reddeder
  ///
  /// Parametreler:
  /// - [deviceId]: Reddedilecek cihazın ID'si
  ///
  /// Dönüş değeri:
  /// - [Future<void>]: Reddetme işlemi tamamlandığında döner
  ///
  /// Fırlatılan hatalar:
  /// - [Exception]: Veritabanı güncelleme hatası
  /// {@endtemplate}
  Future<void> _rejectDevice(String deviceId) async {
    try {
      final client = MockSupabase.instance.client;

      await client.from('device').update({
        'approval_status': 3,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', deviceId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cihaz reddedildi'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadDevices(); // Listeyi yenile
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reddetme hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// {@template deleteDevice}
  /// Cihazı kalıcı olarak siler
  ///
  /// Parametreler:
  /// - [deviceId]: Silinecek cihazın ID'si
  ///
  /// Dönüş değeri:
  /// - [Future<void>]: Silme işlemi tamamlandığında döner
  ///
  /// Fırlatılan hatalar:
  /// - [Exception]: Veritabanı silme hatası
  /// {@endtemplate}
  Future<void> _deleteDevice(String deviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cihazı Sil'),
        content: const Text(
            'Bu cihazı kalıcı olarak silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final client = MockSupabase.instance.client;

      await client.from('device').delete().eq('id', deviceId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cihaz kalıcı olarak silindi'),
            backgroundColor: Colors.red,
          ),
        );
        _loadDevices(); // Listeyi yenile
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Cihazı bloklar
  Future<void> _blockDevice(String deviceId) async {
    try {
      final client = MockSupabase.instance.client;
      await client.from('device').update({
        'approval_status': 5,
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', deviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cihaz bloklandı ve devre dışı bırakıldı'),
            backgroundColor: Colors.purple,
          ),
        );
        _loadDevices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bloklama hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Cihazın blokunu kaldırır
  Future<void> _unblockDevice(String deviceId) async {
    try {
      final client = MockSupabase.instance.client;
      await client.from('device').update({
        'approval_status': 1,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', deviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cihaz aktifleştirildi'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDevices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aktifleştirme hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Onaylanmış ama devre dışı cihazı aktifleştirir
  Future<void> _activateDevice(String deviceId) async {
    try {
      final client = MockSupabase.instance.client;
      await client.from('device').update({
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', deviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cihaz aktifleştirildi'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDevices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aktifleştirme hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// {@template getStatusText}
  /// Cihaz durumunu metin olarak döndürür
  ///
  /// Parametreler:
  /// - [status]: Cihaz durumu (0, 1, 2, 3, 4)
  ///
  /// Dönüş değeri:
  /// - [String]: Durum metni
  /// {@endtemplate}
  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'Beklemede';
      case 1:
        return 'Onaylandı';
      case 2:
        return 'Senkronize Edildi';
      case 3:
        return 'Reddedildi';
      case 4:
        return 'Hata';
      case 5:
        return 'Bloklandı';
      default:
        return 'Bilinmiyor';
    }
  }

  /// {@template getStatusColor}
  /// Cihaz durumuna göre renk döndürür
  ///
  /// Parametreler:
  /// - [status]: Cihaz durumu (0, 1, 2, 3, 4)
  ///
  /// Dönüş değeri:
  /// - [Color]: Durum rengi
  /// {@endtemplate}
  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.red;
      case 4:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// {@template formatDate}
  /// Tarihi okunabilir formata çevirir
  ///
  /// Parametreler:
  /// - [dateString]: ISO 8601 tarih string'i
  ///
  /// Dönüş değeri:
  /// - [String]: Formatlanmış tarih
  /// {@endtemplate}
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Bilinmiyor';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Geçersiz tarih';
    }
  }

  /// {@template buildDeviceCard}
  /// Cihaz kartını oluşturur
  ///
  /// Parametreler:
  /// - [device]: Cihaz verisi
  ///
  /// Dönüş değeri:
  /// - [Widget]: Cihaz kartı widget'ı
  /// {@endtemplate}
  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final status = device['approval_status'] as int? ?? 0;
    final isPending = status == 0;
    final isApproved = status == 1;
    final isBlocked = status == 5;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device['user_full_name'] ?? 'İsimsiz',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cihaz: ${device['device_serial_number'] ?? 'Bilinmiyor'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      if (device['is_active'] == false)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(
                            'DEVRE DIŞI',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Marka: ${device['brand'] ?? 'Bilinmiyor'}'),
                      Text(
                          'İşletim Sistemi: ${device['operating_system'] ?? 'Bilinmiyor'}'),
                      Text(
                          'Kayıt Tarihi: ${_formatDate(device['created_at'])}'),
                    ],
                  ),
                ),
                if (device['updated_at'] != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Güncelleme: ${_formatDate(device['updated_at'])}'),
                      ],
                    ),
                  ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _rejectDevice(device['id'].toString()),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reddet',
                        style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approveDevice(device['id'].toString()),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Onayla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ] else if (isApproved) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (device['is_active'] == false) ...[
                    TextButton.icon(
                      onPressed: () => _activateDevice(device['id'].toString()),
                      icon: const Icon(Icons.power_settings_new,
                          color: Colors.green),
                      label: const Text('Aktifleştir',
                          style: TextStyle(color: Colors.green)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton.icon(
                    onPressed: () => _blockDevice(device['id'].toString()),
                    icon: const Icon(Icons.block, color: Colors.purple),
                    label: const Text('Blokla',
                        style: TextStyle(color: Colors.purple)),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteDevice(device['id'].toString()),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label:
                        const Text('Sil', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ] else if (isBlocked) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _unblockDevice(device['id'].toString()),
                    icon: const Icon(Icons.lock_open, color: Colors.green),
                    label: const Text('Aktifleştir',
                        style: TextStyle(color: Colors.green)),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteDevice(device['id'].toString()),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label:
                        const Text('Sil', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _deleteDevice(device['id'].toString()),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label:
                        const Text('Sil', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> currentDevices;
    String title;

    switch (_selectedFilter) {
      case 'pending':
        currentDevices = _pendingDevices;
        title = 'Bekleyen Cihazlar';
        break;
      case 'approved':
        currentDevices = _approvedDevices;
        title = 'Onaylanmış Cihazlar';
        break;
      case 'rejected':
        currentDevices = _rejectedDevices;
        title = 'Reddedilmiş Cihazlar';
        break;
      case 'blocked':
        currentDevices = _blockedDevices;
        title = 'Bloklanmış Cihazlar';
        break;
      default:
        currentDevices = _pendingDevices;
        title = 'Bekleyen Cihazlar';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Filtre butonları yatay kaydırılabilir
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterButton('Bekleyen', 'pending', _pendingDevices.length),
              const SizedBox(width: 8),
              _buildFilterButton(
                  'Onaylanmış', 'approved', _approvedDevices.length),
              const SizedBox(width: 8),
              _buildFilterButton(
                  'Reddedilmiş', 'rejected', _rejectedDevices.length),
              const SizedBox(width: 8),
              _buildFilterButton(
                  'Bloklanmış', 'blocked', _blockedDevices.length),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Yenile butonu
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _loadDevices,
              icon: const Icon(Icons.refresh),
              label: const Text('Yenile'),
            ),
            const SizedBox(width: 8),
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Cihaz listesi
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : currentDevices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.devices_other,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bu kategoride cihaz bulunamadı',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: currentDevices.length,
                      itemBuilder: (context, index) {
                        return _buildDeviceCard(currentDevices[index]);
                      },
                    ),
        ),
      ],
    );
  }

  /// {@template buildFilterButton}
  /// Filtre butonunu oluşturur
  ///
  /// Parametreler:
  /// - [label]: Buton etiketi
  /// - [filter]: Filtre değeri
  /// - [count]: Cihaz sayısı
  ///
  /// Dönüş değeri:
  /// - [Widget]: Filtre butonu widget'ı
  /// {@endtemplate}
  Widget _buildFilterButton(String label, String filter, int count) {
    final isSelected = _selectedFilter == filter;

    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedFilter = filter);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 2 : 0,
      ),
      child: Text('$label ($count)'),
    );
  }
}

class Supabase { static dynamic instance; }
class MockSupabase { static dynamic instance; }
