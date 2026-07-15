import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:uuid/uuid.dart';
import '../../../../service/database_service.dart';

class WarehouseReceiptScreen extends StatefulWidget {
  const WarehouseReceiptScreen({Key? key}) : super(key: key);

  @override
  State<WarehouseReceiptScreen> createState() => _WarehouseReceiptScreenState();
}

class _WarehouseReceiptScreenState extends State<WarehouseReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _sourceWarehouse;
  String? _destinationWarehouse;
  final TextEditingController _notesController = TextEditingController();

  // Temporary list of products added to the transfer
  final List<Map<String, dynamic>> _transferItems = [];
  
  // Products from DB for lookup
  List<Map<String, dynamic>> _availableProducts = [];
  bool _isLoading = false;

  final List<String> _dummyWarehouses = [
    'Merkez Depo (01)',
    'Araç Depo - 34ABC123 (02)',
    'Hasarlı Bölüm (03)',
    'İade Deposu (04)'
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      final results = await sqliteDb.query('products');
      setState(() {
        _availableProducts = results;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddProductDialog([String? initialSearch]) {
    TextEditingController searchCtrl = TextEditingController(text: initialSearch);
    List<Map<String, dynamic>> filteredList = List.from(_availableProducts);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void filter(String query) {
              final q = query.toLowerCase();
              setModalState(() {
                filteredList = _availableProducts.where((p) {
                  final n = (p['name']?.toString() ?? '').toLowerCase();
                  final c = (p['code']?.toString() ?? '').toLowerCase();
                  final b = (p['barcode']?.toString() ?? '').toLowerCase();
                  return n.contains(q) || c.contains(q) || b.contains(q);
                }).toList();
              });
            }

            // If an initial search was passed (e.g. from barcode), run filter immediately on mount
            if (initialSearch != null && initialSearch.isNotEmpty && filteredList.length == _availableProducts.length) {
              filter(initialSearch);
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ürün Ara (Ad, Kod, Barkod)...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF00A8E8)),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FD),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: filter,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final p = filteredList[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.inventory_2, color: Color(0xFF00A8E8)),
                          ),
                          title: Text(p['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text("Kod: \${p['code'] ?? '-'}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                            onPressed: () {
                              _addProductToTransfer(p);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        _showAddProductDialog(result.rawContent);
      }
    } catch (e) {
      debugPrint('Barcode scan error: $e');
    }
  }

  void _addProductToTransfer(Map<String, dynamic> product) {
    setState(() {
      final existingIndex = _transferItems.indexWhere((item) => item['id'] == product['id']);
      if (existingIndex >= 0) {
        _transferItems[existingIndex]['quantity'] += 1;
      } else {
        _transferItems.add({
          ...product,
          'quantity': 1,
        });
      }
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQty = (_transferItems[index]['quantity'] as int) + delta;
      if (newQty <= 0) {
        _transferItems.removeAt(index);
      } else {
        _transferItems[index]['quantity'] = newQty;
      }
    });
  }

  Future<void> _saveReceipt() async {
    if (_formKey.currentState!.validate()) {
      if (_transferItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen en az bir ürün ekleyin.'), backgroundColor: Colors.red),
        );
        return;
      }

      if (_sourceWarehouse == _destinationWarehouse) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kaynak ve Hedef ambar aynı olamaz.'), backgroundColor: Colors.orange),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final db = await DatabaseService.getInstance();
        final sqliteDb = await db.getDatabase();
        const uuid = Uuid();
        final now = DateTime.now().toIso8601String();

        // Her ürün için ayrı bir transfer kaydı oluştur (offline queue)
        for (final item in _transferItems) {
          await sqliteDb.insert('warehouse_transfers', {
            'id': uuid.v4(),
            'from_warehouse': _sourceWarehouse,
            'to_warehouse': _destinationWarehouse,
            'product_id': item['id']?.toString() ?? '',
            'quantity': (item['quantity'] as int).toDouble(),
            'transfer_date': now,
            'status': 'Pending',
            'is_synced': 0,
            'created_at': now,
          });
        }

        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_transferItems.length} ürün için ambar fişi kaydedildi.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kayıt hatası: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildDropdown(String label, String? value, List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
      items: items.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Bu alan zorunludur' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: const Text('Ambar Fişi', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: _scanBarcode),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _buildDropdown('Kaynak Ambar (Çıkış)', _sourceWarehouse, _dummyWarehouses, (v) => setState(() => _sourceWarehouse = v)),
                  const SizedBox(height: 12),
                  const Icon(Icons.arrow_downward, color: Colors.grey),
                  const SizedBox(height: 12),
                  _buildDropdown('Hedef Ambar (Giriş)', _destinationWarehouse, _dummyWarehouses, (v) => setState(() => _destinationWarehouse = v)),
                ],
              ),
            ),

            // Item List Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transfer Edilecek Ürünler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade800)),
                  TextButton.icon(
                    onPressed: () => _showAddProductDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Ürün Ekle'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF00A8E8)),
                  ),
                ],
              ),
            ),

            // Transfer Items
            Expanded(
              child: _transferItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Henüz ürün eklenmedi.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _transferItems.length,
                      itemBuilder: (context, index) {
                        final item = _transferItems[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text("Kod: \${item['code'] ?? '-'}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(color: const Color(0xFFF8F9FD), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: () => _updateQuantity(index, -1),
                                    ),
                                    Container(
                                      width: 40,
                                      alignment: Alignment.center,
                                      child: Text("\${item['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: () => _updateQuantity(index, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Save
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5))],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Fiş Notu (İsteğe bağlı)',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FD),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveReceipt,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A8E8),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('FİŞİ KAYDET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
