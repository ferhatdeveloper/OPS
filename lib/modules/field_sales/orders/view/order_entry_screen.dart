import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/order_provider.dart';
import '../../../../service/database_service.dart';
import '../../../../core/localization/app_localization.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../../stock/engine/unit_conversion_service.dart';
import '../engine/recommendation_engine.dart';
import '../model/ai_suggestion_model.dart';
import '../../shared/view/digital_signature_screen.dart';
import '../../../../service/pod_service.dart';

class OrderEntryScreen extends ConsumerStatefulWidget {
  final String customerId;
  const OrderEntryScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  ConsumerState<OrderEntryScreen> createState() => _OrderEntryScreenState();
}

class _OrderEntryScreenState extends ConsumerState<OrderEntryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() async {
      ref.read(orderProvider.notifier).startNewOrder(widget.customerId);
      await _fetchProducts();
      // Seed mock suggestions for the demo
      await RecommendationEngine().seedMockSuggestions(widget.customerId, _products.map((p) => p['id'] as String).toList());
    });
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      final results = await sqliteDb.query('products');
      setState(() {
        _products = results;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => _isLoadingProducts = false);
    }
  }

  void _scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        _handleBarcodeScanned(result.rawContent);
      }
    } catch (e) {
      debugPrint('Barcode scan error: $e');
    }
  }

  void _handleBarcodeScanned(String code) {
    _searchController.text = code;
    setState(() {});
    
    // Auto-add product if exact match found
    final exactMatch = _products.where((p) => p['code'] == code || p['barcode'] == code).toList();
    if (exactMatch.isNotEmpty) {
      final p = exactMatch.first;
      _showUnitSelection(p);
      _searchController.clear();
      setState(() {});
    }
  }

  void _showUnitSelection(Map<String, dynamic> p) async {
    final unitSetId = p['unit_set_id'] as String?;
    final units = await UnitConversionService.getUnitsForProduct(unitSetId);
    
    if (units.isEmpty) {
      ref.read(orderProvider.notifier).addItem(p['id'] as String, p['name'] as String, 1);
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            const Text('Birim Seçiniz:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            ...units.map((u) => ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: Text(u.unitName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ref.read(orderProvider.notifier).addItem(p['id'] as String, p['name'] as String, 1, unitName: u.unitName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${p['name']} (${u.unitName}) eklendi")));
              },
            )).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final l10n = AppLocalization.of(context);

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
        title: Text(
          l10n.translate('field_sales.order_entry'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: [
            const Tab(text: 'Katalog'),
            Tab(
              child: state.items.isNotEmpty
                  ? Badge(
                      label: Text('\${state.items.length}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                      backgroundColor: Colors.red,
                      alignment: const AlignmentDirectional(16, -4),
                      child: Text(l10n.translate('field_sales.order_label')),
                    )
                  : Text(l10n.translate('field_sales.order_label')),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductCatalog(context, state, l10n),
          _buildCartSummary(context, state, l10n),
        ],
      ),
      bottomNavigationBar: _tabController.index == 1 ? _buildBottomBar(context, state, l10n) : null,
    );
  }

  Widget _buildProductCatalog(BuildContext context, OrderState state, AppLocalization l10n) {
    final filteredProducts = _products.where((p) {
      final query = _searchController.text.toLowerCase();
      final name = p['name']?.toString().toLowerCase() ?? '';
      final code = p['code']?.toString().toLowerCase() ?? '';
      final barcode = p['barcode']?.toString().toLowerCase() ?? '';
      return name.contains(query) || code.contains(query) || barcode.contains(query);
    }).toList();

    return Column(
      children: [
        Container(
          color: const Color(0xFF375A7F),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.translate('field_sales.search_products_hint'),
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00A8E8)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: Colors.red), onPressed: () => setState(() => _searchController.clear()))
                    : IconButton(icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF375A7F)), onPressed: _scanBarcode),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (v) => setState(() {}),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingProducts 
            ? const Center(child: CircularProgressIndicator())
            : filteredProducts.isEmpty 
                ? _buildEmptyState(l10n.translate('field_sales.no_products_found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = filteredProducts[index];
                      final name = p['name'] as String;
                      final code = p['code'] as String;
                      // final price = (p['price'] as num).toDouble();
                      // final unit = p['unit'] as String? ?? 'Adet';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(color: const Color(0xFFF8F9FD), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF00A8E8), size: 32),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('${l10n.translate('auth.username')}: $code', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                    const SizedBox(height: 8),
                                    FutureBuilder<AISuggestionModel?>(
                                      future: RecommendationEngine().getSuggestion(widget.customerId, p['id'] as String),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData && snapshot.data != null) {
                                          final suggestion = snapshot.data!;
                                          return InkWell(
                                            onTap: () {
                                              _showSuggestionDetails(suggestion, p);
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(top: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.auto_awesome, color: Colors.purple, size: 14),
                                                  const SizedBox(width: 4),
                                                  Text('Öneri: ${suggestion.suggestedQty.toInt()}', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _showUnitSelection(p),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00A8E8).withOpacity(0.1),
                                      foregroundColor: const Color(0xFF00A8E8),
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(12),
                                      elevation: 0,
                                    ),
                                    child: const Icon(Icons.add, size: 24),
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
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, OrderState state, AppLocalization l10n) {
    if (state.items.isEmpty) {
      return _buildEmptyState(l10n.translate('field_sales.order_cart_empty'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...state.items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(item.productName ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => ref.read(orderProvider.notifier).updateQuantity(item.productId, 0),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFF8F9FD), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => ref.read(orderProvider.notifier).updateQuantity(item.productId, item.quantity - 1),
                        ),
                        Container(
                          width: 40,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          alignment: Alignment.center,
                          child: Text('\${item.quantity.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => ref.read(orderProvider.notifier).updateQuantity(item.productId, item.quantity + 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Birim: ${item.price} ₺ (${item.unitName ?? "Adet"})', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('${item.totalAmount.toStringAsFixed(2)} ₺', style: const TextStyle(color: Color(0xFF00A8E8), fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        )).toList(),
        
        if (state.freeItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(l10n.translate('field_sales.gift_promotion_products'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
          ),
          ...state.freeItems.map((f) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
            child: ListTile(
              leading: const Icon(Icons.card_giftcard, color: Colors.green),
              title: Text(f.productName ?? 'Ürün ID: \${f.productId}', style: TextStyle(color: Colors.green.shade900)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                child: Text('Adet: \${f.quantity.toInt()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )).toList(),
        ],
        
        const SizedBox(height: 24),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.translate('field_sales.order_note_hint'),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, OrderState state, AppLocalization l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTotalRow('Ara Toplam', '\${state.subtotal.toStringAsFixed(2)} '),
            const SizedBox(height: 4),
            _buildTotalRow('KDV Toplam', '\${state.vatTotal.toStringAsFixed(2)} '),
            if (state.discountTotal > 0) ...[
              const SizedBox(height: 4),
              _buildTotalRow('Kampanya İndirimi', '-\${state.discountTotal.toStringAsFixed(2)} ', isDiscount: true),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            _buildTotalRow('GENEL TOPLAM', '\${state.grandTotal.toStringAsFixed(2)} ', isGrand: true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A8E8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: state.items.isEmpty ? null : () => _saveOrder(l10n),
                child: state.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(l10n.translate('field_sales.confirm_order'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isDiscount = false, bool isGrand = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontWeight: isGrand ? FontWeight.bold : FontWeight.w500,
          color: isDiscount ? Colors.green : (isGrand ? const Color(0xFF2C3E50) : Colors.grey.shade600),
          fontSize: isGrand ? 16 : 14,
        )),
        Text(value, style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDiscount ? Colors.green : (isGrand ? const Color(0xFF00A8E8) : const Color(0xFF2C3E50)),
          fontSize: isGrand ? 20 : 15,
        )),
      ],
    );
  }

  void _saveOrder(AppLocalization l10n) async {
    final state = ref.read(orderProvider);
    final orderId = state.draftOrder?.id;

    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hata: Sipariş ID bulunamadı.')));
      return;
    }

    final success = await ref.read(orderProvider.notifier).saveOrder(_notesController.text);
    if (success) {
      if (!mounted) return;

      // Navigate to signature screen before fully exiting
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DigitalSignatureScreen(
            transactionId: orderId,
            type: SignatureType.order,
            onComplete: (signatureData) async {
              await PODService().saveOrderSignature(
                orderId: orderId,
                signatureData: signatureData,
              );
              if (mounted) {
                Navigator.pop(context); // Close signature screen
                Navigator.pop(context); // Close order entry screen
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.translate('pod.signature_saved')),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
          ),
        ),
      );
    }
  }

  void _showSuggestionDetails(AISuggestionModel suggestion, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.auto_awesome, color: Colors.purple),
            SizedBox(width: 8),
            Text('AI Sipariş Önerisi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ürün: ${product['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Önerilen Miktar: ${suggestion.suggestedQty.toInt()} Adet'),
            const SizedBox(height: 8),
            Text('Güven Oranı: %${(suggestion.confidence * 100).toInt()}'),
            const SizedBox(height: 12),
            const Text('Neden:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(suggestion.reason ?? 'Geçmiş veriler temelinde hesaplandı.', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
          ElevatedButton(
            onPressed: () {
              ref.read(orderProvider.notifier).addItem(product['id'] as String, product['name'] as String, suggestion.suggestedQty, unitName: product['unit'] as String?);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI önerisi (${suggestion.suggestedQty.toInt()} adet) eklendi.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text('Öneriyi Uygula'),
          ),
        ],
      ),
    );
  }
}

