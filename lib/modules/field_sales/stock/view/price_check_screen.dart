import 'package:flutter/material.dart';
import '../../../../service/database_service.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class PriceCheckScreen extends StatefulWidget {
  const PriceCheckScreen({Key? key}) : super(key: key);

  @override
  State<PriceCheckScreen> createState() => _PriceCheckScreenState();
}

class _PriceCheckScreenState extends State<PriceCheckScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = false;

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
        _allProducts = results;
        _filteredProducts = results;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürünler yüklenemedi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _allProducts;
      });
      return;
    }
    
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final name = (p['name']?.toString() ?? '').toLowerCase();
        final code = (p['code']?.toString() ?? '').toLowerCase();
        final barcode = (p['barcode']?.toString() ?? '').toLowerCase();
        return name.contains(lowerQuery) || code.contains(lowerQuery) || barcode.contains(lowerQuery);
      }).toList();
    });
  }

  void _scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        _searchController.text = result.rawContent;
        _filterProducts(result.rawContent);
      }
    } catch (e) {
      debugPrint('Barcode scan error: $e');
    }
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
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)], // Flat UI Primary Blues
            ),
          ),
        ),
        title: const Text('Fiyat Gör', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            color: const Color(0xFF375A7F),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Ürün adı, kodu veya barkodu...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF00A8E8)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _filterProducts('');
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF375A7F)),
                          onPressed: _scanBarcode,
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: _filterProducts,
              ),
            ),
          ),
          
          // Results Header Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Arama Sonuçları',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade800),
                ),
                Text(
                  '\${_filteredProducts.length} Ürün',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          ),

          // Product Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final p = _filteredProducts[index];
                          final name = p['name']?.toString() ?? 'İsimsiz Ürün';
                          final code = p['code']?.toString() ?? '-';
                          final barcode = p['barcode']?.toString() ?? '-';
                          final price = (p['price'] as num?)?.toDouble() ?? 0.0;
                          final unit = p['unit']?.toString() ?? 'Adet';

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F4FB),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      color: Color(0xFF00A8E8),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Product Name
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF2C3E50),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  // Code
                                  Text(
                                    'Kod: $code',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (barcode.isNotEmpty && barcode != '-')
                                    Text(
                                      'Barkod: $barcode',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const Spacer(),
                                  // Divider
                                  Divider(color: Colors.grey.shade100, height: 16),
                                  // Price row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '/ $unit',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        '${price.toStringAsFixed(2)} ₺',
                                        style: const TextStyle(
                                          color: Color(0xFF00A8E8),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
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


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'Aradığınız kriterlere uygun ürün bulunamadı.'
                : 'Lütfen aramak istediğiniz ürünü yazın.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
