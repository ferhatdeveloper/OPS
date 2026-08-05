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
import '../../../../core/config/regional_config.dart';
import '../../../../service/invoice_print_service.dart';
import '../../shared/view/catalog_barcode_actions.dart';
import '../../shared/view/digital_signature_screen.dart';
import '../../shared/view/mbt_catalog_toolbar.dart';
import '../../shared/view/product_line_qty_unit_sheet.dart';
import '../../shared/view/unsaved_voucher_dialog.dart';
import '../../shared/view/unsaved_voucher_scope.dart';
import '../../shared/view/voucher_defaults_fields.dart';
import '../../../../service/pod_service.dart';
import 'package:geolocator/geolocator.dart';
import 'invoice_customer_selection_screen.dart';
import '../../shared/view/field_sales_dens_theme.dart';
import '../../eod/viewmodel/pending_transfer_gate.dart';

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
    Future.microtask(() async {
      if (!InvoiceNotifier.isValidCustomerId(widget.customerId)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context).translate(
                'field_sales.invoice_requires_customer',
              ),
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => InvoiceCustomerSelectionScreen(
              title: widget.title,
              invoiceType: widget.invoiceType,
            ),
          ),
        );
        return;
      }
      await _beginInvoiceDraftOrPrompt();
      if (!mounted) return;
      _fetchProducts();
    });
  }

  /// {@template _beginInvoiceDraftOrPrompt}
  /// Mevcut kaydedilmemiş fatura varsa ortak taslak uyarısı gösterir.
  /// {@endtemplate}
  Future<void> _beginInvoiceDraftOrPrompt() async {
    final invoiceState = ref.read(invoiceProvider);
    final hasDraft = invoiceState.items.isNotEmpty;
    final decision = await promptExistingDraftVoucher(
      context: context,
      hasExistingDraft: hasDraft,
      customerLabel: invoiceState.draftInvoice?.customerId,
    );
    if (!mounted) return;
    switch (decision) {
      case ExistingDraftDecision.keepExisting:
        return;
      case ExistingDraftDecision.discardAndRestart:
        ref.read(invoiceProvider.notifier).discardDraft();
        break;
      case ExistingDraftDecision.startFresh:
        break;
    }
    ref.read(invoiceProvider.notifier).startNewInvoice(
          widget.customerId,
          invoiceType: widget.invoiceType,
        );
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceProvider);
    final l10n = AppLocalization.of(context);

    return UnsavedVoucherScope(
      hasUnsaved: state.items.isNotEmpty,
      onDiscard: () => ref.read(invoiceProvider.notifier).discardDraft(),
      child: Scaffold(
        backgroundColor: FieldSalesDensTheme.bodyBackground(context),
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
              ),
            ),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => _openBarcodeLookup(l10n),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: [
              Tab(text: l10n.translate('field_sales.catalog')),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.translate('field_sales.products_in_invoice')),
                    if (state.items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${state.items.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
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
        bottomNavigationBar: _tabController.index == 1
            ? _buildBottomBar(context, state, l10n)
            : null,
      ),
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
        MbtCatalogToolbar(
          onAction: (action) => _onMbtToolbarAction(context, l10n, action),
        ),
        Container(
          color: const Color(0xFF375A7F),
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Container(
            decoration: BoxDecoration(
              color: FieldSalesDensTheme.surface(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.translate('field_sales.search_products_hint'),
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF00A8E8),
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red, size: 18),
                        onPressed: () =>
                            setState(() => _searchController.clear()),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Color(0xFF375A7F),
                          size: 20,
                        ),
                        onPressed: () => _openBarcodeLookup(l10n),
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = filteredProducts[index];
                      final name = p['name'] as String;
                      final code = p['code'] as String;
                      final price = (p['price'] as num).toDouble();
                      final unit = p['unit'] as String? ??
                          l10n.translate('field_sales.unit_piece');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: FieldSalesDensTheme.surface(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: FieldSalesDensTheme.bodyBackground(context),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: Color(0xFF00A8E8),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Color(0xFF2C3E50),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$code · $price / $unit',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _printLabel(p),
                                icon: const Icon(
                                  Icons.print_outlined,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                tooltip: l10n.translate(
                                  'field_sales.print_label',
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _addProductWithQtyUnit(p),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF00A8E8).withOpacity(0.1),
                                  foregroundColor: const Color(0xFF00A8E8),
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: const Size(36, 36),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  elevation: 0,
                                ),
                                child: const Icon(Icons.add, size: 20),
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

  /// {@template _add_product_with_qty_unit}
  /// Dens birim+miktar sheet ile fatura satırına ürün ekler.
  /// {@endtemplate}
  Future<void> _addProductWithQtyUnit(Map<String, dynamic> product) async {
    final result = await showProductLineQtyUnitSheet(
      context: context,
      product: product,
    );
    if (result == null || !mounted) return;

    final id = product['id'];
    if (id == null) return;
    final name = product['name']?.toString() ?? '';
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final vatRate = (product['vat_rate'] as num?)?.toDouble() ?? 20.0;

    await ref.read(invoiceProvider.notifier).addItem(
          id.toString(),
          name,
          price,
          result.quantity,
          vatRate: vatRate,
          unitName: result.unitName,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalization.of(context).translate(
            'field_sales.item_added_with_unit',
            args: {
              'name': name,
              'unit': '${result.quantity} ${result.unitName}',
            },
          ),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// {@template _open_barcode_lookup}
  /// Barkod dens lookup açar; seçilen ürünü faturaya ekler.
  /// {@endtemplate}
  Future<void> _openBarcodeLookup(AppLocalization l10n) async {
    final product = await openFieldSalesBarcodeScan(context);
    if (product == null || !mounted) return;
    await _addProductWithQtyUnit(product);
  }

  /// {@template _onMbtToolbarAction}
  /// Katalog araç çubuğu: Barkod/Kamera → [BarcodeScanScreen]; diğerleri stub.
  /// {@endtemplate}
  void _onMbtToolbarAction(
    BuildContext context,
    AppLocalization l10n,
    MbtCatalogToolbarAction action,
  ) {
    switch (action) {
      case MbtCatalogToolbarAction.barcode:
      case MbtCatalogToolbarAction.camera:
        _openBarcodeLookup(l10n);
        return;
      case MbtCatalogToolbarAction.search:
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.translate('field_sales.search_products_hint'),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
        return;
      default:
        final label = l10n.translate(
          'field_sales.mbt_toolbar.${_invoiceToolbarKey(action)}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.translate(
                'field_sales.mbt_toolbar.stub_action',
                args: {'action': label},
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  /// {@template _invoiceToolbarKey}
  /// [MbtCatalogToolbarAction] → l10n alt anahtar adı.
  /// {@endtemplate}
  String _invoiceToolbarKey(MbtCatalogToolbarAction action) {
    switch (action) {
      case MbtCatalogToolbarAction.stockCard:
        return 'stock_card';
      case MbtCatalogToolbarAction.serviceCard:
        return 'service_card';
      case MbtCatalogToolbarAction.codeName:
        return 'code_name';
      case MbtCatalogToolbarAction.barcode:
        return 'barcode';
      case MbtCatalogToolbarAction.camera:
        return 'camera';
      case MbtCatalogToolbarAction.group:
        return 'group';
      case MbtCatalogToolbarAction.image:
        return 'image';
      case MbtCatalogToolbarAction.search:
        return 'search';
    }
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
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      children: [
        _buildTypeSelectionCard(),
        const SizedBox(height: 8),
        if (RegionalConfig.showEInvoice) ...[
          _buildEInvoiceSwitchCard(state),
          const SizedBox(height: 10),
        ],
        if (state.items.isEmpty)
          _buildEmptyState(l10n.translate('field_sales.cart_empty'))
        else ...[
          Text(
            l10n.translate('field_sales.products'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 6),
          ...state.items.map((item) => _buildCartItem(item)).toList(),
          if (state.freeItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                l10n.translate('field_sales.gift_promotion_products'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                  fontSize: 13,
                ),
              ),
            ),
            ...state.freeItems.map((f) => _buildFreeItem(f)).toList(),
          ],
        ],
        const SizedBox(height: 10),
        const VoucherDefaultsFields(),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 2,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: l10n.translate('field_sales.add_invoice_note'),
            labelStyle: const TextStyle(fontSize: 13),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: FieldSalesDensTheme.surface(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCartItem(InvoiceItemModel item) {
    final unitLabel = (item.unitName ?? '').trim().isEmpty
        ? AppLocalization.of(context).translate('field_sales.unit_piece')
        : item.unitName!;
    final qtyText = item.quantity == item.quantity.roundToDouble()
        ? '${item.quantity.toInt()}'
        : item.quantity.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: FieldSalesDensTheme.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productName ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF2C3E50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => ref
                    .read(invoiceProvider.notifier)
                    .updateQuantity(item.id, 0),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${item.price} / $unitLabel',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const Spacer(),
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: FieldSalesDensTheme.bodyBackground(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      padding: const EdgeInsets.all(4),
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: () => ref
                          .read(invoiceProvider.notifier)
                          .updateQuantity(
                            item.id,
                            item.quantity - 1,
                          ),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        qtyText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      padding: const EdgeInsets.all(4),
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: () => ref
                          .read(invoiceProvider.notifier)
                          .updateQuantity(
                            item.id,
                            item.quantity + 1,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.totalAmount} ',
                style: const TextStyle(
                  color: Color(0xFF00A8E8),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFreeItem(FreeItem f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: const Icon(Icons.card_giftcard, color: Colors.green, size: 20),
        title: Text(
          'Ürün ID: ${f.productId}',
          style: TextStyle(color: Colors.green.shade900, fontSize: 13),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Adet: ${f.quantity.toInt()}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelectionCard() {
    final l10n = AppLocalization.of(context);
    final state = ref.watch(invoiceProvider);

    final Map<String, String> typeOptions = {
      'field_sales.van_sales': 'field_sales.van_sales',
      'field_sales.return_invoice': 'field_sales.return_invoice',
      'field_sales.price_difference': 'field_sales.price_difference',
      'field_sales.wholesale_invoice_8': 'field_sales.wholesale_invoice_8',
      'field_sales.sales_return_invoice_3':
          'field_sales.sales_return_invoice_3',
      'field_sales.purchase_invoice': 'field_sales.purchase_invoice',
    };

    String currentType =
        state.draftInvoice?.invoiceType ?? 'field_sales.van_sales';

    if (!typeOptions.containsKey(currentType)) {
      if (currentType == 'Sıcak Satış (Van Sales)') {
        currentType = 'field_sales.van_sales';
      } else if (currentType == 'İade Faturası') {
        currentType = 'field_sales.return_invoice';
      } else if (currentType == 'Fiyat Farkı') {
        currentType = 'field_sales.price_difference';
      } else if (currentType == 'Toptan Satış Faturası (8)') {
        currentType = 'field_sales.wholesale_invoice_8';
      } else if (currentType == 'Satış İade Faturası (3)') {
        currentType = 'field_sales.sales_return_invoice_3';
      } else if (currentType == 'Satın Alma' ||
          currentType == 'Alış Faturası' ||
          currentType.toLowerCase().contains('purchase')) {
        currentType = 'field_sales.purchase_invoice';
      } else {
        currentType = 'field_sales.van_sales';
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: FieldSalesDensTheme.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('field_sales.invoice_type'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: currentType,
            isDense: true,
            style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50)),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              filled: true,
              fillColor: FieldSalesDensTheme.surface(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            items: typeOptions.entries
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(
                      l10n.translate(e.value),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                ref
                    .read(invoiceProvider.notifier)
                    .updateInvoiceSettings(type: val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEInvoiceSwitchCard(InvoiceState state) {
    final l10n = AppLocalization.of(context);
    final isEInvoice = state.draftInvoice?.isEInvoice ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: FieldSalesDensTheme.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('field_sales.e_invoice_archive'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  l10n.translate('field_sales.issue_as_e_invoice'),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: isEInvoice,
            activeColor: const Color(0xFF00A8E8),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (v) => ref
                .read(invoiceProvider.notifier)
                .updateInvoiceSettings(isEInvoice: v),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, InvoiceState state, AppLocalization l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: FieldSalesDensTheme.surface(context),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTotalRow(
              l10n.translate('field_sales.subtotal'),
              '${state.subtotal.toStringAsFixed(2)} ',
            ),
            const SizedBox(height: 2),
            _buildTotalRow(
              l10n.translate('field_sales.vat_total'),
              '${state.vatTotal.toStringAsFixed(2)} ',
            ),
            if (state.discountTotal > 0) ...[
              const SizedBox(height: 2),
              _buildTotalRow(
                l10n.translate('field_sales.campaign_discount'),
                '-${state.discountTotal.toStringAsFixed(2)} ',
                isDiscount: true,
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1),
            ),
            _buildTotalRow(
              l10n.translate('field_sales.grand_total_label'),
              '${state.grandTotal.toStringAsFixed(2)} ',
              isGrand: true,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      foregroundColor: const Color(0xFF375A7F),
                      side: const BorderSide(color: Color(0xFF375A7F)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _showPrintOptions(context, state),
                    icon: const Icon(Icons.print, size: 18),
                    label: Text(l10n.translate('field_sales.print')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: const Color(0xFF00A8E8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: state.items.isEmpty ? null : _saveInvoice,
                    child: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            l10n.translate('field_sales.issue_invoice'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isGrand = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isGrand ? FontWeight.w700 : FontWeight.w500,
            color: isDiscount
                ? Colors.green
                : (isGrand ? const Color(0xFF2C3E50) : Colors.grey.shade600),
            fontSize: isGrand ? 14 : 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDiscount
                ? Colors.green
                : (isGrand
                    ? const Color(0xFF00A8E8)
                    : const Color(0xFF2C3E50)),
            fontSize: isGrand ? 16 : 13,
          ),
        ),
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
    final l10n = AppLocalization.of(context);
    if (!InvoiceNotifier.isValidCustomerId(widget.customerId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.invoice_save_requires_customer'),
          ),
        ),
      );
      return;
    }

    final invoiceState = ref.read(invoiceProvider);
    final invoiceId = invoiceState.draftInvoice?.id;

    if (invoiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hata: Fatura ID bulunamadı.')));
      return;
    }

    final success = await ref.read(invoiceProvider.notifier).saveInvoice(_notesController.text);

    if (!success) {
      final err = ref.read(invoiceProvider).error;
      if (mounted && err != null) {
        final msg = err.startsWith('field_sales.')
            ? l10n.translate(err)
            : err;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      return;
    }

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
                content: Text(
                  AppLocalization.of(context).translate(
                    PendingTransferGate.savedQueuedKey,
                  ),
                ),
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
