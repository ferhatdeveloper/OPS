import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/vehicle_provider.dart';
import '../model/vehicle_model.dart';
import '../../../../service/database_service.dart';

class VehicleLoadingScreen extends ConsumerStatefulWidget {
  const VehicleLoadingScreen({super.key});

  @override
  ConsumerState<VehicleLoadingScreen> createState() => _VehicleLoadingScreenState();
}

class _VehicleLoadingScreenState extends ConsumerState<VehicleLoadingScreen> {
  final List<Map<String, dynamic>> _itemsToLoad = [];
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoadingProducts = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      final results = await sqliteDb.query('products', where: 'is_active = 1');
      setState(() {
        _allProducts = results;
        _filteredProducts = results;
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ürünler yüklenirken hata: $e')));
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final name = (p['name'] as String).toLowerCase();
        final sku = (p['sku'] as String? ?? '').toLowerCase();
        return name.contains(query.toLowerCase()) || sku.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _addItem(Map<String, dynamic> product, double qty) {
    setState(() {
      final existingIndex = _itemsToLoad.indexWhere((i) => i['productId'] == product['id']);
      if (existingIndex != -1) {
        _itemsToLoad[existingIndex]['quantity'] += qty;
      } else {
        _itemsToLoad.add({
          'productId': product['id'],
          'name': product['name'],
          'quantity': qty,
          'unit': product['unit'] ?? 'Adet',
        });
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _itemsToLoad.removeAt(index);
    });
  }

  Future<void> _handleSave() async {
    if (_itemsToLoad.isEmpty) return;

    final success = await ref.read(vehicleProvider.notifier).loadStockIntoVehicle(items: _itemsToLoad);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yükleme başarıyla tamamlandı.')));
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        final error = ref.read(vehicleProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Araca Ürün Yükle', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildVehicleSelector(state),
          _buildSearchBox(),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildProductList()),
                const VerticalDivider(width: 1),
                Expanded(flex: 1, child: _buildLoadingSummary()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(state),
    );
  }

  Widget _buildVehicleSelector(VehicleState state) {
    if (state.vehicles.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.delivery_dining, color: Color(0xFF375A7F)),
          const SizedBox(width: 12),
          const Text('Araç:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<VehicleModel>(
              value: state.selectedVehicle,
              isExpanded: true,
              underline: const SizedBox(),
              items: state.vehicles.map((v) => DropdownMenuItem(
                value: v,
                child: Text('${v.plate} - ${v.name ?? ''}'),
              )).toList(),
              onChanged: (v) {
                if (v != null) ref.read(vehicleProvider.notifier).selectVehicle(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _filterProducts,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Color(0xFF375A7F)),
          hintText: 'Ürün ara...',
          filled: true,
          fillColor: const Color(0xFFF8F9FD),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    if (_isLoadingProducts) return const Center(child: CircularProgressIndicator());
    if (_filteredProducts.isEmpty) return const Center(child: Text('Ürün bulunamadı.'));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(product['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('SKU: ${product['sku'] ?? '-'} | Fiyat: ${product['price'] ?? 0} TL'),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFF00A8E8)),
              onPressed: () => _showQuantityDialog(product),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingSummary() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Yüklenecekler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(height: 1),
          Expanded(
            child: _itemsToLoad.isEmpty
                ? const Center(child: Text('Henüz ürün seçilmedi.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _itemsToLoad.length,
                    itemBuilder: (context, index) {
                      final item = _itemsToLoad[index];
                      return ListTile(
                        title: Text(item['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text('${item['quantity']} ${item['unit']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => _removeItem(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(VehicleState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: ElevatedButton(
        onPressed: _itemsToLoad.isEmpty || state.isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A8E8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: state.isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Yüklemeyi Onayla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showQuantityDialog(Map<String, dynamic> product) {
    final controller = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${product['name']} Yükle'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Miktar'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(controller.text) ?? 1.0;
              _addItem(product, qty);
              Navigator.pop(context);
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
}
