// Dosya Adı: data_transfer_screen.dart
// Açıklama: Logo REST ile master data indirme ve bekleyen belge yükleme
// Oluşturulma Tarihi: 2026-02-22
// Geliştirici: EXFIN OPS Team
// Son Güncelleme: 2026-07-15

import 'package:flutter/material.dart';

import '../../../../core/services/logo_api_service.dart';
import '../../../../service/database_service.dart';
import '../../../../service/job_queue_service.dart';
import 'logo_rest_settings_screen.dart';

class DataTransferScreen extends StatefulWidget {
  const DataTransferScreen({Key? key}) : super(key: key);

  @override
  State<DataTransferScreen> createState() => _DataTransferScreenState();
}

class _DataTransferScreenState extends State<DataTransferScreen> {
  bool isSyncing = false;
  double overallProgress = 0.0;
  String? lastError;

  final List<Map<String, dynamic>> syncItems = [
    {
      'key': 'customers',
      'title': 'Müşteri Kartları',
      'icon': Icons.people,
      'progress': 0.0,
      'status': 'Bekliyor',
    },
    {
      'key': 'products',
      'title': 'Ürün Kartları',
      'icon': Icons.shopping_bag,
      'progress': 0.0,
      'status': 'Bekliyor',
    },
    {
      'key': 'stock',
      'title': 'Stok Durumları',
      'icon': Icons.inventory,
      'progress': 0.0,
      'status': 'Bekliyor',
    },
    {
      'key': 'balances',
      'title': 'Cari Bakiyeler',
      'icon': Icons.account_balance_wallet,
      'progress': 0.0,
      'status': 'Bekliyor',
    },
    {
      'key': 'upload',
      'title': 'Bekleyen Belgeler (Logo)',
      'icon': Icons.cloud_upload,
      'progress': 0.0,
      'status': 'Bekliyor',
    },
  ];

  Future<void> _startSync() async {
    if (isSyncing) return;
    setState(() {
      isSyncing = true;
      overallProgress = 0.0;
      lastError = null;
      for (final item in syncItems) {
        item['progress'] = 0.0;
        item['status'] = 'Bekliyor';
      }
    });

    final logo = LogoApiService();
    await logo.ensureReady();

    for (int i = 0; i < syncItems.length; i++) {
      final item = syncItems[i];
      setState(() {
        item['status'] = 'Aktarılıyor...';
        item['progress'] = 0.1;
      });

      try {
        switch (item['key']) {
          case 'customers':
            await _syncCustomers(logo, i);
            break;
          case 'products':
            await _syncProducts(logo, i);
            break;
          case 'stock':
            await _syncStock(logo, i);
            break;
          case 'balances':
            await _syncBalances(logo, i);
            break;
          case 'upload':
            await _uploadPending(i);
            break;
        }
        setState(() {
          item['status'] = 'Tamamlandı';
          item['progress'] = 1.0;
          overallProgress = (i + 1) / syncItems.length;
        });
      } catch (e) {
        setState(() {
          item['status'] = 'Hata';
          lastError = e.toString();
          overallProgress = (i + 1) / syncItems.length;
        });
      }
    }

    setState(() => isSyncing = false);
  }

  Future<void> _syncCustomers(LogoApiService logo, int index) async {
    final result = await logo.getCustomers();
    if (!result.success) {
      throw Exception(result.error ?? 'Müşteri indirilemedi');
    }
    final list = result.asMapList();
    final db = await (await DatabaseService.getInstance()).getDatabase();
    final now = DateTime.now().toIso8601String();
    var done = 0;
    for (final row in list) {
      final code = (row['CODE'] ?? row['code'] ?? row['LOGICALREF'] ?? '')
          .toString();
      if (code.isEmpty) continue;
      final name =
          (row['DEFINITION_'] ?? row['name'] ?? row['TITLE'] ?? code).toString();
      final existing = await db.query(
        'customers',
        where: 'id = ? OR code = ?',
        whereArgs: [code, code],
        limit: 1,
      );
      final data = {
        'id': existing.isNotEmpty ? existing.first['id'] : code,
        'code': code,
        'name': name,
        'tax_no': row['TAXNR'] ?? row['tax_number'] ?? row['tax_no'],
        'tax_office': row['TAXOFFICE'] ?? row['tax_office'],
        'address': row['ADDR1'] ?? row['address'],
        'il': row['CITY'] ?? row['city'] ?? row['il'],
        'phone': row['TELNRS1'] ?? row['phone'],
        'email': row['EMAILADDR'] ?? row['email'],
        'balance': (row['BALANCE'] ?? row['balance'] ?? 0) is num
            ? (row['BALANCE'] ?? row['balance'] as num).toDouble()
            : 0.0,
        'is_active': 1,
        'updated_at': now,
        'created_at': existing.isNotEmpty
            ? existing.first['created_at']
            : now,
      };
      try {
        await db.insert('customers', data);
      } catch (_) {
        await db.update(
          'customers',
          data,
          where: 'id = ?',
          whereArgs: [data['id']],
        );
      }
      done++;
      if (done % 20 == 0) {
        setState(() {
          syncItems[index]['progress'] =
              (done / (list.isEmpty ? 1 : list.length)).clamp(0.1, 0.99);
        });
      }
    }
  }

  Future<void> _syncProducts(LogoApiService logo, int index) async {
    final result = await logo.getItems();
    if (!result.success) {
      throw Exception(result.error ?? 'Ürün indirilemedi');
    }
    final list = result.asMapList();
    final db = await (await DatabaseService.getInstance()).getDatabase();
    final now = DateTime.now().toIso8601String();
    var done = 0;
    for (final row in list) {
      final code = (row['CODE'] ?? row['code'] ?? '').toString();
      if (code.isEmpty) continue;
      final name = (row['NAME'] ?? row['name'] ?? code).toString();
      final id = code;
      final data = {
        'id': id,
        'code': code,
        'name': name,
        'unit': row['UNIT'] ?? row['unit'] ?? 'AD',
        'price': (row['PRICE'] ?? row['price'] ?? 0) is num
            ? (row['PRICE'] ?? row['price'] as num).toDouble()
            : 0.0,
        'stock_quantity': (row['ONHAND'] ?? row['stock'] ?? row['STOCK_QTY'] ?? 0)
                is num
            ? ((row['ONHAND'] ?? row['stock'] ?? row['STOCK_QTY']) as num)
                .toDouble()
            : 0.0,
        'vat_rate': 20,
        'updated_at': now,
        'created_at': now,
      };
      try {
        await db.insert('products', data);
      } catch (_) {
        await db.update('products', data, where: 'id = ?', whereArgs: [id]);
      }
      done++;
      if (done % 20 == 0) {
        setState(() {
          syncItems[index]['progress'] =
              (done / (list.isEmpty ? 1 : list.length)).clamp(0.1, 0.99);
        });
      }
    }
  }

  Future<void> _syncStock(LogoApiService logo, int index) async {
    final result = await logo.getInventoryReport();
    if (!result.success) {
      // Stok raporu yoksa ürün listesinden devam
      setState(() => syncItems[index]['status'] = 'Atlandı');
      return;
    }
    final list = result.asMapList();
    final db = await (await DatabaseService.getInstance()).getDatabase();
    for (final row in list) {
      final code = (row['CODE'] ?? row['code'] ?? row['item_code'] ?? '')
          .toString();
      if (code.isEmpty) continue;
      final qty = (row['ONHAND'] ?? row['stock'] ?? row['STOCK_QTY'] ?? 0);
      await db.update(
        'products',
        {
          'stock_quantity': qty is num ? qty.toDouble() : 0.0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'code = ? OR id = ?',
        whereArgs: [code, code],
      );
    }
  }

  Future<void> _syncBalances(LogoApiService logo, int index) async {
    final result = await logo.getBalances();
    if (!result.success) {
      setState(() => syncItems[index]['status'] = 'Atlandı');
      return;
    }
    final list = result.asMapList();
    final db = await (await DatabaseService.getInstance()).getDatabase();
    for (final row in list) {
      final code = (row['CODE'] ?? row['code'] ?? row['ARP_CODE'] ?? '')
          .toString();
      if (code.isEmpty) continue;
      final bal = row['BALANCE'] ?? row['balance'] ?? row['DEBIT'] ?? 0;
      await db.update(
        'customers',
        {
          'balance': bal is num ? bal.toDouble() : 0.0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'code = ? OR id = ?',
        whereArgs: [code, code],
      );
    }
  }

  Future<void> _uploadPending(int index) async {
    final pending = await JobQueueService().pendingCount();
    setState(() {
      syncItems[index]['status'] = '$pending belge gönderiliyor...';
      syncItems[index]['progress'] = 0.3;
    });
    await JobQueueService().processQueue();
    final left = await JobQueueService().pendingCount();
    if (left > 0) {
      throw Exception('$left belge Logo\'ya gönderilemedi (kuyrukta kaldı)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'Veri Transferi (Logo)',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Logo REST Ayarları',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LogoRestSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF375A7F),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Genel İlerleme',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${(overallProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: overallProgress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                    minHeight: 10,
                  ),
                ),
                if (lastError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    lastError!,
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSyncing ? null : _startSync,
                    icon: Icon(isSyncing ? Icons.hourglass_top : Icons.sync),
                    label: Text(isSyncing ? 'Senkronize ediliyor...' : 'Logo ile Senkronize Et'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF375A7F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              cacheExtent: 500,
              itemCount: syncItems.length,
              itemBuilder: (context, index) {
                final item = syncItems[index];
                final done = item['status'] == 'Tamamlandı';
                final err = item['status'] == 'Hata';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: done
                          ? Colors.green.shade100
                          : err
                              ? Colors.red.shade100
                              : const Color(0xFF375A7F).withOpacity(0.15),
                      child: Icon(
                        item['icon'] as IconData,
                        color: done
                            ? Colors.green
                            : err
                                ? Colors.red
                                : const Color(0xFF375A7F),
                      ),
                    ),
                    title: Text(item['title'] as String),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['status'] as String),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: (item['progress'] as num).toDouble(),
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
