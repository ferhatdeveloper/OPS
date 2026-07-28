import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/order_provider.dart';
import '../model/order_model.dart';
import '../../customers/model/customer_model.dart';
import '../../../../service/database_service.dart';
import '../../../../core/localization/app_localization.dart';
import '../engine/recommendation_engine.dart';
import '../model/ai_suggestion_model.dart';
import '../../delivery/viewmodel/delivery_hold_entry.dart';
import '../../shared/view/catalog_barcode_actions.dart';
import '../../shared/view/digital_signature_screen.dart';
import '../../shared/view/product_line_qty_unit_sheet.dart';
import '../../shared/view/voucher_defaults_fields.dart';
import '../../shared/view/mbt_catalog_toolbar.dart';
import '../../shared/view/unsaved_voucher_dialog.dart';
import '../../shared/view/unsaved_voucher_scope.dart';
import '../../../../service/pod_service.dart';
import 'order_customer_selection_screen.dart';
import 'order_type_sheet.dart';

class OrderEntryScreen extends ConsumerStatefulWidget {
  /// [customerId]: Siparişin bağlanacağı cari kart kimliği (zorunlu, boş olamaz)
  final String customerId;
  /// [customerName]: Header'da gösterilecek cari adı (opsiyonel)
  final String? customerName;
  /// [customerCode]: Header'da gösterilecek cari kod/VKN (opsiyonel)
  final String? customerCode;
  /// [orderType]: Satış / Alış (MBT tip)
  final OrderType orderType;
  /// [cardRole]: Cari rolü (alışta tedarikçi zorunlu)
  final CariCardRole? cardRole;

  /// [initialProductToAdd]: Ziyaret/barkod sonrası sepete eklenecek ürün haritası
  final Map<String, dynamic>? initialProductToAdd;

  /// [existingOrderId]: Düzenleme — yüklü sipariş id (null → yeni)
  final String? existingOrderId;

  const OrderEntryScreen({
    Key? key,
    required this.customerId,
    this.customerName,
    this.customerCode,
    this.orderType = OrderType.sales,
    this.cardRole,
    this.initialProductToAdd,
    this.existingOrderId,
  }) : super(key: key);

  @override
  ConsumerState<OrderEntryScreen> createState() => _OrderEntryScreenState();
}

class _OrderEntryScreenState extends ConsumerState<OrderEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingProducts = false;
  String? _resolvedCustomerName;
  String? _resolvedCustomerCode;
  bool _missingCustomer = false;
  late OrderType _orderType;
  CariCardRole? _cardRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _orderType = widget.orderType;
    _cardRole = widget.cardRole;
    _resolvedCustomerName = widget.customerName;
    _resolvedCustomerCode = widget.customerCode;

    Future.microtask(() async {
      if (!OrderNotifier.isValidCustomerId(widget.customerId)) {
        if (!mounted) return;
        setState(() => _missingCustomer = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context).translate(
                _orderType == OrderType.purchase
                    ? 'field_sales.order_requires_supplier'
                    : 'field_sales.order_requires_customer',
              ),
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderCustomerSelectionScreen(
              orderType: _orderType,
            ),
          ),
        );
        return;
      }

      await _resolveCustomerLabel();
      if (!mounted) return;

      if (!OrderNotifier.isValidPartyForOrder(
        customerId: widget.customerId,
        orderType: _orderType,
        cardRole: _cardRole,
      )) {
        setState(() => _missingCustomer = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context).translate(
                _orderType == OrderType.purchase
                    ? 'field_sales.order_requires_supplier'
                    : 'field_sales.order_requires_customer',
              ),
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderCustomerSelectionScreen(
              orderType: _orderType,
            ),
          ),
        );
        return;
      }

      await _beginOrderDraftOrPrompt();
      if (!mounted) return;
      await _fetchProducts();
      await RecommendationEngine().seedMockSuggestions(
        widget.customerId,
        _products.map((p) => p['id'] as String).toList(),
      );
      final seedProduct = widget.initialProductToAdd;
      if (seedProduct != null && mounted) {
        await _showUnitSelection(seedProduct);
      }
    });
  }

  /// {@template _beginOrderDraftOrPrompt}
  /// Mevcut kaydedilmemiş sipariş varsa ortak taslak uyarısı gösterir.
  /// Düzenleme modunda [existingOrderId] taslağı korunur.
  /// {@endtemplate}
  Future<void> _beginOrderDraftOrPrompt() async {
    final editId = widget.existingOrderId?.trim();
    if (editId != null && editId.isNotEmpty) {
      final orderState = ref.read(orderProvider);
      if (orderState.draftOrder?.id == editId &&
          orderState.items.isNotEmpty) {
        if ((orderState.draftOrder?.notes ?? '').isNotEmpty) {
          _notesController.text = orderState.draftOrder!.notes!;
        }
        return;
      }
      final ok = await ref
          .read(orderProvider.notifier)
          .loadDraftFromOrderId(editId);
      if (!mounted) return;
      if (!ok) {
        final err = ref.read(orderProvider).error;
        final l10n = AppLocalization.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              err != null && err.startsWith('field_sales.')
                  ? l10n.translate(err)
                  : l10n.translate('field_sales.order_edit_not_found'),
            ),
          ),
        );
        return;
      }
      final notes = ref.read(orderProvider).draftOrder?.notes;
      if (notes != null && notes.isNotEmpty) {
        _notesController.text = notes;
      }
      return;
    }

    final orderState = ref.read(orderProvider);
    final hasDraft = orderState.items.isNotEmpty;
    final label = _resolvedCustomerName?.trim().isNotEmpty == true
        ? _resolvedCustomerName
        : orderState.draftOrder?.customerId;
    final decision = await promptExistingDraftVoucher(
      context: context,
      hasExistingDraft: hasDraft,
      customerLabel: label,
    );
    if (!mounted) return;
    switch (decision) {
      case ExistingDraftDecision.keepExisting:
        return;
      case ExistingDraftDecision.discardAndRestart:
        ref.read(orderProvider.notifier).discardDraft();
        break;
      case ExistingDraftDecision.startFresh:
        break;
    }
    ref.read(orderProvider.notifier).startNewOrder(
          widget.customerId,
          orderType: _orderType,
          cardRole: _cardRole,
        );
  }

  /// {@template _resolveCustomerLabel}
  /// Header için cari ad/kod bilgisini DB'den tamamlar; rol yoksa okur.
  /// {@endtemplate}
  Future<void> _resolveCustomerLabel() async {
    final needName = _resolvedCustomerName == null ||
        _resolvedCustomerName!.trim().isEmpty;
    final needRole = _cardRole == null;
    if (!needName && !needRole) return;
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      final rows = await sqliteDb.query(
        'customers',
        where: 'id = ?',
        whereArgs: [widget.customerId],
        limit: 1,
      );
      if (rows.isEmpty || !mounted) return;
      final row = rows.first;
      setState(() {
        if (needName) {
          _resolvedCustomerName = row['name']?.toString();
          _resolvedCustomerCode =
              (row['code'] ?? row['tax_no'] ?? widget.customerId).toString();
        }
        if (needRole) {
          _cardRole = CariCardRole.fromStorage(row['card_role']?.toString());
        }
      });
    } catch (_) {
      // Header opsiyonel; sessizce geç
    }
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

  /// {@template _open_barcode_lookup}
  /// Barkod dens lookup açar; seçilen ürünü sepete ekler.
  /// {@endtemplate}
  Future<void> _openBarcodeLookup() async {
    final product = await openFieldSalesBarcodeScan(context);
    if (product == null || !mounted) return;
    await _showUnitSelection(product);
  }

  Future<void> _showUnitSelection(Map<String, dynamic> p) async {
    final result = await showProductLineQtyUnitSheet(
      context: context,
      product: p,
    );
    if (result == null || !mounted) return;

    ref.read(orderProvider.notifier).addItem(
          p['id'] as String,
          p['name'] as String,
          result.quantity,
          unitName: result.unitName,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalization.of(context).translate(
            'field_sales.item_added_with_unit',
            args: {
              'name': '${p['name']}',
              'unit': '${result.quantity} ${result.unitName}',
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final l10n = AppLocalization.of(context);

    if (_missingCustomer) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final customerTitle = _resolvedCustomerName?.trim().isNotEmpty == true
        ? _resolvedCustomerName!
        : widget.customerId;
    final customerSubtitle = _resolvedCustomerCode?.trim().isNotEmpty == true
        ? _resolvedCustomerCode
        : null;

    return UnsavedVoucherScope(
      hasUnsaved: state.items.isNotEmpty,
      onDiscard: () => ref.read(orderProvider.notifier).discardDraft(),
      child: Scaffold(
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate(_orderType.titleL10nKey),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              customerSubtitle != null
                  ? '$customerTitle ($customerSubtitle)'
                  : customerTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: l10n.translate('field_sales.delivery_hold.add_hold'),
            icon: const Icon(Icons.pause_circle_outline),
            onPressed: state.items.isEmpty ? null : () => _putOnHold(l10n),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _openBarcodeLookup,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          tabs: [
            Tab(text: l10n.translate('field_sales.catalog')),
            Tab(
              child: state.items.isNotEmpty
                  ? Badge(
                      label: Text(
                        '${state.items.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
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
    ),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          child: OrderTypeDensSelector(
            value: _orderType,
            enabled: state.items.isEmpty,
            onChanged: (type) {
              setState(() => _orderType = type);
              final draft = ref.read(orderProvider).draftOrder;
              if (draft != null) {
                ref.read(orderProvider.notifier).startNewOrder(
                      draft.customerId,
                      orderType: type,
                    );
              }
            },
          ),
        ),
        MbtCatalogToolbar(
          onAction: (action) {
            switch (action) {
              case MbtCatalogToolbarAction.barcode:
              case MbtCatalogToolbarAction.camera:
                _openBarcodeLookup();
                break;
              case MbtCatalogToolbarAction.search:
                // Mevcut arama alanına odaklanmak için setState yeter
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.translate('field_sales.search_products_hint'),
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
                break;
              default:
                final label = l10n.translate(
                  'field_sales.mbt_toolbar.${_toolbarKey(action)}',
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
          },
        ),
        Container(
          color: const Color(0xFF375A7F),
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
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
                        onPressed: _openBarcodeLookup,
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
                  ? _buildEmptyState(
                      l10n.translate('field_sales.no_products_found'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final p = filteredProducts[index];
                        final name = p['name'] as String;
                        final code = p['code'] as String;
                        final price = (p['price'] as num?)?.toDouble();
                        final unit = p['unit'] as String? ?? 'Adet';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                                    color: const Color(0xFFF8F9FD),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        price != null
                                            ? '$code · $price / $unit'
                                            : code,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                        ),
                                      ),
                                      FutureBuilder<AISuggestionModel?>(
                                        future: RecommendationEngine()
                                            .getSuggestionEnriched(
                                          customerId: widget.customerId,
                                          productId: p['id'] as String,
                                          customerLabel:
                                              widget.customerCode ??
                                                  widget.customerName ??
                                                  widget.customerId,
                                          productLabel: code.isNotEmpty
                                              ? code
                                              : (p['id'] as String),
                                        ),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData &&
                                              snapshot.data != null) {
                                            final suggestion = snapshot.data!;
                                            return InkWell(
                                              onTap: () {
                                                _showSuggestionDetails(
                                                  suggestion,
                                                  p,
                                                );
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.purple
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.auto_awesome,
                                                      color: Colors.purple,
                                                      size: 12,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      l10n.translate(
                                                        'field_sales.suggestion_qty_short',
                                                        args: {
                                                          'qty':
                                                              '${suggestion.suggestedQty.toInt()}',
                                                        },
                                                      ),
                                                      style: const TextStyle(
                                                        color: Colors.purple,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 10,
                                                      ),
                                                    ),
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
                                ElevatedButton(
                                  onPressed: () => _showUnitSelection(p),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00A8E8)
                                        .withOpacity(0.1),
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

  /// {@template _toolbarKey}
  /// [MbtCatalogToolbarAction] → l10n alt anahtar adı.
  /// {@endtemplate}
  String _toolbarKey(MbtCatalogToolbarAction action) {
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
          Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, OrderState state, AppLocalization l10n) {
    if (state.items.isEmpty) {
      return _buildEmptyState(l10n.translate('field_sales.order_cart_empty'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      children: [
        ...state.items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          decoration: BoxDecoration(
            color: Colors.white,
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
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: () => ref
                        .read(orderProvider.notifier)
                        .updateQuantity(item.productId, 0),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${item.price} ₺ (${item.unitName ?? "Adet"})',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 72,
                    child: TextFormField(
                      initialValue: item.discountPercent > 0
                          ? item.discountPercent.toStringAsFixed(0)
                          : '',
                      style: const TextStyle(fontSize: 12),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: l10n.translate(
                          'field_sales.order_line_discount_pct',
                        ),
                        labelStyle: const TextStyle(fontSize: 10),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      onFieldSubmitted: (v) {
                        final pct = double.tryParse(
                              v.replaceAll(',', '.'),
                            ) ??
                            0;
                        ref
                            .read(orderProvider.notifier)
                            .updateDiscount(item.productId, pct);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FD),
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
                              .read(orderProvider.notifier)
                              .updateQuantity(
                                item.productId,
                                item.quantity - 1,
                              ),
                        ),
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${item.quantity.toInt()}',
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
                              .read(orderProvider.notifier)
                              .updateQuantity(
                                item.productId,
                                item.quantity + 1,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.totalAmount.toStringAsFixed(2)} ₺',
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
        )).toList(),

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
          ...state.freeItems.map((f) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              leading: const Icon(
                Icons.card_giftcard,
                color: Colors.green,
                size: 20,
              ),
              title: Text(
                f.productName ??
                    l10n.translate(
                      'field_sales.product_id_label',
                      args: {'id': '${f.productId}'},
                    ),
                style: TextStyle(
                  color: Colors.green.shade900,
                  fontSize: 13,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.translate(
                    'field_sales.qty_pieces',
                    args: {'qty': '${f.quantity.toInt()}'},
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          )).toList(),
        ],

        const SizedBox(height: 12),
        const VoucherDefaultsFields(),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 2,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            labelText: l10n.translate('field_sales.order_note_hint'),
            labelStyle: const TextStyle(fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, OrderState state, AppLocalization l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
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
            SizedBox(
              width: double.infinity,
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
                onPressed: state.items.isEmpty ? null : () => _saveOrder(l10n),
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
                        l10n.translate('field_sales.confirm_order'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                : (isGrand ? const Color(0xFF00A8E8) : const Color(0xFF2C3E50)),
            fontSize: isGrand ? 16 : 13,
          ),
        ),
      ],
    );
  }

  /// {@template _putOnHold}
  /// Taslağı [DeliveryHoldStore.add] ile beklemeye alır; sepeti temizler.
  /// {@endtemplate}
  Future<void> _putOnHold(AppLocalization l10n) async {
    final state = ref.read(orderProvider);
    if (state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.order_min_products')),
        ),
      );
      return;
    }
    final orderId = state.draftOrder?.id;
    if (orderId == null || orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.order_id_not_found')),
        ),
      );
      return;
    }

    final code = (_resolvedCustomerCode ?? widget.customerCode ?? '').trim();
    final name = (_resolvedCustomerName ?? widget.customerName ?? '').trim();
    final note = _notesController.text.trim();

    await const DeliveryHoldEntry().addFromOrder(
      orderId: orderId,
      orderType: _orderType,
      customerCode: code.isNotEmpty ? code : widget.customerId,
      customerName: name.isNotEmpty ? name : widget.customerId,
      note: note.isNotEmpty
          ? note
          : l10n.translate('field_sales.delivery_hold.sample_note'),
    );

    if (!mounted) return;
    ref.read(orderProvider.notifier).discardDraft();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.translate('field_sales.delivery_hold.held_saved'),
        ),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).maybePop();
  }

  void _saveOrder(AppLocalization l10n) async {
    if (!OrderNotifier.isValidCustomerId(widget.customerId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.order_save_requires_customer')),
        ),
      );
      return;
    }

    final state = ref.read(orderProvider);
    final orderId = state.draftOrder?.id;

    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.order_id_not_found')),
        ),
      );
      return;
    }

    final success = (widget.existingOrderId?.trim().isNotEmpty == true)
        ? await ref
            .read(orderProvider.notifier)
            .updateLocalOrder(_notesController.text)
        : await ref
            .read(orderProvider.notifier)
            .saveOrder(_notesController.text);
    if (!success) {
      final err = ref.read(orderProvider).error;
      if (mounted && err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate(err))),
        );
      }
      return;
    }
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

  void _showSuggestionDetails(AISuggestionModel suggestion, Map<String, dynamic> product) {
    final l10n = AppLocalization.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.purple),
            const SizedBox(width: 8),
            Text(l10n.translate('field_sales.ai_order_suggestion')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate(
                'field_sales.ai_suggestion_product',
                args: {'name': '${product['name']}'},
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.translate(
                'field_sales.ai_suggested_qty',
                args: {'qty': '${suggestion.suggestedQty.toInt()}'},
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate(
                'field_sales.ai_confidence',
                args: {
                  'percent': '${(suggestion.confidence * 100).toInt()}',
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.translate('field_sales.ai_reason_label'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              suggestion.reason ??
                  l10n.translate('field_sales.ai_suggestion_default_reason'),
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('common.close')),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(orderProvider.notifier).addItem(
                    product['id'] as String,
                    product['name'] as String,
                    suggestion.suggestedQty,
                    unitName: product['unit'] as String?,
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.translate(
                      'field_sales.ai_suggestion_applied',
                      args: {'qty': '${suggestion.suggestedQty.toInt()}'},
                    ),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.translate('field_sales.apply_suggestion')),
          ),
        ],
      ),
    );
  }
}

