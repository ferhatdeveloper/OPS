import 'package:flutter/material.dart';
import '../engine/extra_ops_service.dart';
import '../model/extra_ops_model.dart';
import '../../../../service/database_service.dart';
import 'package:uuid/uuid.dart';

class StockOpsScreen extends StatefulWidget {
  const StockOpsScreen({Key? key}) : super(key: key);

  @override
  State<StockOpsScreen> createState() => _StockOpsScreenState();
}

class _StockOpsScreenState extends State<StockOpsScreen> {
  final _service = ExtraOpsService();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final db = await DatabaseService.getInstance();
    final sqliteDb = await db.getDatabase();
    final results = await sqliteDb.query('products');
    setState(() {
      _products = results;
      _isLoading = false;
    });
  }

  void _showLogDialog(Map<String, dynamic> product, String type) {
    final qtyController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'Wastage' ? 'Fire Kaydı' : 'Numune Kaydı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(product['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: 'Miktar'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Neden / Not'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(qtyController.text) ?? 0;
              if (qty <= 0) return;

              final log = WastageLogModel(
                id: const Uuid().v4(),
                productId: product['id'] as String,
                quantity: qty,
                type: type,
                reason: reasonController.text,
                createdAt: DateTime.now(),
              );
              await _service.saveWastageLog(log);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\$type kaydı oluşturuldu ve stok güncellendi.')));
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sarfiyat ve Numune')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final p = _products[index];
                return ListTile(
                  title: Text(p['name'] as String),
                  subtitle: Text(p['code'] as String),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        onPressed: () => _showLogDialog(p, 'Wastage'),
                        tooltip: 'Fire',
                      ),
                      IconButton(
                        icon: const Icon(Icons.card_giftcard, color: Colors.green),
                        onPressed: () => _showLogDialog(p, 'Sample'),
                        tooltip: 'Numune',
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
