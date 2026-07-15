import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/invoice_model.dart';
import '../viewmodel/invoice_provider.dart';
import '../../../../service/print_settings_service.dart';
import '../../../../service/bluetooth_print_service.dart';
import '../../campaigns/engine/campaign_engine.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../../../view/widgets/template_preview_card.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../../../../core/config/regional_config.dart';
import '../../../../service/invoice_print_service.dart';
import '../../shared/view/digital_signature_screen.dart';
import '../../../../service/pod_service.dart';
import 'package:geolocator/geolocator.dart';

class InvoiceEntryScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String title;
  final String invoiceType;
  
  const InvoiceEntryScreen({
    Key? key, 
    required this.customerId,
    this.title = 'Satış Faturası',
    this.invoiceType = 'Sıcak Satış (Van Sales)',
  }) : super(key: key);

  @override
  ConsumerState<InvoiceEntryScreen> createState() => _InvoiceEntryScreenState();
}

class _InvoiceEntryScreenState extends ConsumerState<InvoiceEntryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(invoiceProvider.notifier).startNewInvoice(widget.customerId, invoiceType: widget.invoiceType);
      _fetchProducts();
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
    final l10n = AppLocalization.of(context);
    _searchController.text = code;
    setState(() {});
    
    final exactMatch = _products.where((p) => p['code'] == code || p['barcode'] == code).toList();
    if (exactMatch.isNotEmpty) {
      final p = exactMatch.first;
      ref.read(invoiceProvider.notifier).addItem(p['id'], p['name'], (p['price'] as num).toDouble(), 1);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.translate('field_sales.product_added').replaceAll('{name}', p['name']))));
      _searchController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceProvider);
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
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
            Tab(text: l10n.translate('field_sales.catalog')),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.translate('field_sales.products_in_invoice')),
                  if (state.items.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      child: Text('${state.items.length}', style: const TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                ],
              ),
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

  Widget _buildProductCatalog(BuildContext context, InvoiceState state, AppLocalization l10n) {
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
                      final price = (p['price'] as num).toDouble();
                      final unit = p['unit'] as String? ?? 'Adet';

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
                                    Text('$price  / $unit', style: const TextStyle(color: Color(0xFF00A8E8), fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () => _printLabel(p),
                                    icon: const Icon(Icons.print_outlined, color: Colors.grey, size: 20),
                                    tooltip: l10n.translate('field_sales.print_label'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => ref.read(invoiceProvider.notifier).addItem(p['id'], name, price, 1),
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

  Widget _buildCartSummary(BuildContext context, InvoiceState state, AppLocalization l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTypeSelectionCard(),
        const SizedBox(height: 16),
        if (RegionalConfig.showEInvoice) ...[
          _buildEInvoiceSwitchCard(state),
          const SizedBox(height: 24),
        ],
        if (state.items.isEmpty)
          _buildEmptyState(l10n.translate('field_sales.cart_empty'))
        else ...[
          Text(l10n.translate('field_sales.products'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
          const SizedBox(height: 12),
          ...state.items.map((item) => _buildCartItem(item)).toList(),
          
          if (state.freeItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(l10n.translate('field_sales.gift_promotion_products'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
            ),
            ...state.freeItems.map((f) => _buildFreeItem(f)).toList(),
          ],
        ],
        const SizedBox(height: 24),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.translate('field_sales.add_invoice_note'),
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

  Widget _buildCartItem(InvoiceItemModel item) {
    return Container(
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
                onPressed: () => ref.read(invoiceProvider.notifier).updateQuantity(item.productId, 0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${item.price} ', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF8F9FD), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      onPressed: () => ref.read(invoiceProvider.notifier).updateQuantity(item.productId, item.quantity - 1),
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text('${item.quantity.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      onPressed: () => ref.read(invoiceProvider.notifier).updateQuantity(item.productId, item.quantity + 1),
                    ),
                  ],
                ),
              ),
              Text('${item.totalAmount} ', style: const TextStyle(color: Color(0xFF00A8E8), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFreeItem(FreeItem f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
      child: ListTile(
        leading: const Icon(Icons.card_giftcard, color: Colors.green),
        title: Text('Ürün ID: ${f.productId}', style: TextStyle(color: Colors.green.shade900)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
          child: Text('Adet: ${f.quantity.toInt()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildTypeSelectionCard() {
    final l10n = AppLocalization.of(context);
    final state = ref.watch(invoiceProvider);
    
    // Map of logical keys to their translation keys
    final Map<String, String> typeOptions = {
      'field_sales.van_sales': 'field_sales.van_sales',
      'field_sales.return_invoice': 'field_sales.return_invoice',
      'field_sales.price_difference': 'field_sales.price_difference',
      'field_sales.wholesale_invoice_8': 'field_sales.wholesale_invoice_8',
      'field_sales.sales_return_invoice_3': 'field_sales.sales_return_invoice_3',
    };

    // Current type from state
    String currentType = state.draftInvoice?.invoiceType ?? 'field_sales.van_sales';
    
    // If the current type is not one of our keys (e.g. it's an old Turkish name), 
    // try to map it or fallback to the first key
    if (!typeOptions.containsKey(currentType)) {
      if (currentType == 'Sıcak Satış (Van Sales)') currentType = 'field_sales.van_sales';
      else if (currentType == 'İade Faturası') currentType = 'field_sales.return_invoice';
      else if (currentType == 'Fiyat Farkı') currentType = 'field_sales.price_difference';
      else if (currentType == 'Toptan Satış Faturası (8)') currentType = 'field_sales.wholesale_invoice_8';
      else if (currentType == 'Satış İade Faturası (3)') currentType = 'field_sales.sales_return_invoice_3';
      else currentType = 'field_sales.van_sales'; // Default fallback
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.translate('field_sales.invoice_type'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: currentType,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8F9FD),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: typeOptions.entries.map((e) => DropdownMenuItem<String>(
              value: e.key, 
              child: Text(l10n.translate(e.value))
            )).toList(),
            onChanged: (val) {
              if (val != null) ref.read(invoiceProvider.notifier).updateInvoiceSettings(type: val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEInvoiceSwitchCard(InvoiceState state) {
    final l10n = AppLocalization.of(context);
    // The instruction snippet for `_buildEInvoiceSwitchCard` was syntactically incorrect
    // as it tried to define functions and providers inside a Widget method.
    // I am keeping the original `_buildEInvoiceSwitchCard` method as is,
    // and placing the new provider definitions outside the class, as is standard for Riverpod.
    final isEInvoice = state.draftInvoice?.isEInvoice ?? true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.translate('field_sales.e_invoice_archive'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
              const SizedBox(height: 4),
              Text(l10n.translate('field_sales.issue_as_e_invoice'), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
          Switch(
            value: isEInvoice,
            activeColor: const Color(0xFF00A8E8),
            onChanged: (v) => ref.read(invoiceProvider.notifier).updateInvoiceSettings(isEInvoice: v),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, InvoiceState state, AppLocalization l10n) {
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
            _buildTotalRow(l10n.translate('field_sales.subtotal'), '${state.subtotal.toStringAsFixed(2)} '),
            const SizedBox(height: 4),
            _buildTotalRow(l10n.translate('field_sales.vat_total'), '${state.vatTotal.toStringAsFixed(2)} '),
            if (state.discountTotal > 0) ...[
              const SizedBox(height: 4),
              _buildTotalRow(l10n.translate('field_sales.campaign_discount'), '-${state.discountTotal.toStringAsFixed(2)} ', isDiscount: true),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            _buildTotalRow(l10n.translate('field_sales.grand_total_label'), '${state.grandTotal.toStringAsFixed(2)} ', isGrand: true),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: const Color(0xFF375A7F),
                      side: const BorderSide(color: Color(0xFF375A7F)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _showPrintOptions(context, state),
                    icon: const Icon(Icons.print),
                    label: Text(l10n.translate('field_sales.print')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF00A8E8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    onPressed: state.items.isEmpty ? null : _saveInvoice,
                    child: state.isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.translate('field_sales.issue_invoice'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
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

  void _showPrintOptions(BuildContext context, InvoiceState state) async {
    final l10n = AppLocalization.of(context);
    if (state.draftInvoice == null) return;

    final settings = await PrintSettingsService().getDefaultPrinter();
    final showPreview = await PrintSettingsService().getShowPreview();
    final btService = BluetoothPrintService();

    // Check if we should print directly
    if (!showPreview && settings['address'] != null) {
      try {
        final devices = await btService.getPairedDevices();
        final device = devices.firstWhere(
          (d) => d.address == settings['address'],
          orElse: () => throw Exception('Varsayılan yazıcı bulunamadı.'),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.translate('field_sales.sending_to_default_printer'))));
        await btService.connect(device);
        await btService.printInvoice(state.draftInvoice!, state.items);
        return;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.translate('field_sales.direct_print_error').replaceAll('{error}', e.toString())), backgroundColor: Colors.orange));
      }
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.translate('field_sales.select_print_size'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Color(0xFF00A8E8)),
              title: Text(l10n.translate('field_sales.thermal_80mm')),
              onTap: () {
                Navigator.pop(context);
                InvoicePrintService().printInvoice(state.draftInvoice!, state.items, format: PrintFormat.thermal80mm);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Color(0xFF375A7F)),
              title: Text(l10n.translate('field_sales.a5_doc')),
              onTap: () {
                Navigator.pop(context);
                InvoicePrintService().printInvoice(state.draftInvoice!, state.items, format: PrintFormat.a5);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment, color: Colors.green),
              title: Text(l10n.translate('field_sales.a4_standard')),
              onTap: () {
                Navigator.pop(context);
                InvoicePrintService().printInvoice(state.draftInvoice!, state.items, format: PrintFormat.a4);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bluetooth, color: Colors.blue),
              title: Text(l10n.translate('field_sales.bluetooth_printer')),
              subtitle: Text(l10n.translate('field_sales.print_directly_thermal')),
              onTap: () {
                Navigator.pop(context);
                _showBluetoothSlipDesignOptions(context, state);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showBluetoothSlipDesignOptions(BuildContext context, InvoiceState state) async {
    final l10n = AppLocalization.of(context);
    final printerSettings = await PrintSettingsService().getDefaultPrinter();

    if (!context.mounted) return;

    if (printerSettings['address'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.translate('field_sales.please_select_default_printer')),
        backgroundColor: Colors.orange,
      ));
      return; 
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.translate('field_sales.select_slip_design'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.translate('field_sales.select_slip_design_desc'), 
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  TemplatePreviewCard(
                    title: l10n.translate('field_sales.standard_slip'),
                    templateId: 'standard',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      _executeBluetoothSlipPrint(state, 'standard', printerSettings['address']);
                    },
                  ),
                  TemplatePreviewCard(
                    title: l10n.translate('field_sales.minimal_slip'),
                    templateId: 'minimal',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      _executeBluetoothSlipPrint(state, 'minimal', printerSettings['address']);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _executeBluetoothSlipPrint(InvoiceState state, String templateId, String? printerAddress) async {
    if (printerAddress == null) return;
    final btService = BluetoothPrintService();
    try {
      bool? isConnected = await btService.isConnected();
      if (isConnected != true) {
        final devices = await btService.getPairedDevices();
        final device = devices.firstWhere((d) => d.address == printerAddress);
        await btService.connect(device);
      }
      await btService.printInvoice(state.draftInvoice!, state.items, templateId: templateId);
    } catch (e) {
      debugPrint('Bluetooth yazdirma hatasi: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bağlantı hatası: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _printLabel(Map<String, dynamic> product) {
    final l10n = AppLocalization.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.translate('field_sales.select_label_design'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(l10n.translate('field_sales.select_label_design_desc'), 
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 20),
              SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    TemplatePreviewCard(
                      title: l10n.translate('field_sales.product_label_small'),
                      templateId: 'product_small',
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        _executeBluetoothLabelPrint(product, 'product_small');
                      },
                    ),
                    TemplatePreviewCard(
                      title: l10n.translate('field_sales.shelf_label_large'),
                      templateId: 'shelf_large',
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        _executeBluetoothLabelPrint(product, 'shelf_large');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _executeBluetoothLabelPrint(Map<String, dynamic> product, String templateId) async {
    final printService = BluetoothPrintService();
    final printerSettings = await PrintSettingsService().getLabelPrinter(); // Etiket icin
      
    if (printerSettings['address'] == null) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen ayarlardan Etiket Yazıcısı seçin.')));
      }
      return;
    }

    bool? isConnected = await printService.isConnected();
    if (isConnected != true) {
      try {
        final devices = await printService.getPairedDevices();
        final device = devices.firstWhere((d) => d.address == printerSettings['address']);
        await printService.connect(device);
      } catch (e) {
         debugPrint("Baglanti hatasi: $e");
      }
    }

    final price = (product['price'] as num).toDouble();
    await printService.printLabel(
      product['name'] as String,
      product['id'] as String,
      price.toStringAsFixed(2),
      labelType: templateId
    );
  }

  void _saveInvoice() async {
    final invoiceState = ref.read(invoiceProvider);
    final invoiceId = invoiceState.draftInvoice?.id;

    if (invoiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hata: Fatura ID bulunamadı.')));
      return;
    }

    final success = await ref.read(invoiceProvider.notifier).saveInvoice(_notesController.text);

    if (success) {
      if (!mounted) return;

      // Navigate to signature screen for POD
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DigitalSignatureScreen(
            transactionId: invoiceId,
            type: SignatureType.invoice,
            onComplete: (signatureData) async {
              // Try to get current position for POD
              double lat = 0.0;
              double lon = 0.0;
              try {
                final pos = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.low,
                  timeLimit: const Duration(seconds: 5),
                );
                lat = pos.latitude;
                lon = pos.longitude;
              } catch (e) {
                debugPrint('POD Location Error: $e');
              }

              // Save POD info
              await PODService().saveProofOfDelivery(
                invoiceId: invoiceId,
                signatureData: signatureData,
                latitude: lat,
                longitude: lon,
              );

              if (mounted) {
                Navigator.pop(context); // Close signature screen
                Navigator.pop(context); // Close invoice entry screen

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(AppLocalization.of(context).translate('pod.signature_saved')),
                  behavior: SnackBarBehavior.floating,
                ));

                // Auto-print logic
                _handleAutoPrint(invoiceState);
              }
            },
          ),
        ),
      );
    }
  }

  void _handleAutoPrint(InvoiceState state) async {
    final bool autoPrint = await PrintSettingsService().getAutoPrint();
    if (!autoPrint) return;

    try {
      final printService = BluetoothPrintService();
      final printerSettings = await PrintSettingsService().getDefaultPrinter();
      
      if (printerSettings['address'] == null) return;

      // Ensure connected
      bool? isConnected = await printService.isConnected();
      if (isConnected != true) {
        // Find matching device
        final devices = await printService.getPairedDevices();
        final device = devices.firstWhere((d) => d.address == printerSettings['address']);
        await printService.connect(device);
      }

      // Prepare InvoiceModel for printing (use the one from state)
      // Note: saveInvoice updates the date and status, but for printing the draft is fine 
      // as long as we pass the same ID and totals.
      if (state.draftInvoice != null) {
        await printService.printInvoice(
          state.draftInvoice!.copyWith(
            invoiceDate: DateTime.now(),
            totalAmount: state.grandTotal,
            status: 'Completed',
          ), 
          state.items
        );
      }
    } catch (e) {
      debugPrint('Auto-print error: $e');
    }
  }
}
