import 'package:flutter/material.dart';

class DataTransferScreen extends StatefulWidget {
  const DataTransferScreen({Key? key}) : super(key: key);

  @override
  State<DataTransferScreen> createState() => _DataTransferScreenState();
}

class _DataTransferScreenState extends State<DataTransferScreen> {
  bool isSyncing = false;
  double overallProgress = 0.0;
  
  final List<Map<String, dynamic>> syncItems = [
    {'title': 'Müşteri Kartları', 'icon': Icons.people, 'progress': 1.0, 'status': 'Tamamlandı'},
    {'title': 'Ürün Kartları', 'icon': Icons.shopping_bag, 'progress': 1.0, 'status': 'Tamamlandı'},
    {'title': 'Fiyat Listeleri', 'icon': Icons.sell, 'progress': 0.0, 'status': 'Bekliyor'},
    {'title': 'Stok Durumları', 'icon': Icons.inventory, 'progress': 0.0, 'status': 'Bekliyor'},
    {'title': 'Siparişler', 'icon': Icons.shopping_cart, 'progress': 0.0, 'status': 'Bekliyor'},
    {'title': 'Tahsilatlar', 'icon': Icons.payments, 'progress': 0.0, 'status': 'Bekliyor'},
  ];

  void _startSync() async {
    setState(() {
      isSyncing = true;
      overallProgress = 0.0;
      for (var item in syncItems) {
        if (item['status'] != 'Tamamlandı') item['progress'] = 0.0;
      }
    });

    for (int i = 0; i < syncItems.length; i++) {
      if (syncItems[i]['status'] == 'Tamamlandı') continue;
      
      setState(() {
        syncItems[i]['status'] = 'Aktarılıyor...';
      });

      for (int step = 1; step <= 10; step++) {
        await Future.delayed(const Duration(milliseconds: 150));
        setState(() {
          syncItems[i]['progress'] = step / 10;
          overallProgress = (i + (step / 10)) / syncItems.length;
        });
      }

      setState(() {
        syncItems[i]['status'] = 'Tamamlandı';
      });
    }

    setState(() {
      isSyncing = false;
      overallProgress = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Veri Transferi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF375A7F),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Genel İlerleme', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${(overallProgress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: overallProgress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSyncing ? null : _startSync,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF375A7F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(isSyncing ? 'Senkronize Ediliyor...' : 'Şimdi Güncelle', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: syncItems.length,
              itemBuilder: (context, index) {
                final item = syncItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(item['icon'] as IconData, color: const Color(0xFF375A7F)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Text(item['status'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                        if (item['progress'] > 0 && item['progress'] < 1) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: item['progress'] as double,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF375A7F)),
                            minHeight: 4,
                          ),
                        ],
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
