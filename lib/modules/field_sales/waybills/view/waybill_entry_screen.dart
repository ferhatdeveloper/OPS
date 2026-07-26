// Dosya Adı: waybill_entry_screen.dart
// Açıklama: İrsaliye toptan/satın alma — cari → Stok/Hizmet dens form
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../delivery/viewmodel/delivery_hold_entry.dart';
import '../../shared/view/catalog_barcode_actions.dart';
import '../../shared/view/mbt_catalog_toolbar.dart';
import '../../shared/view/unsaved_voucher_scope.dart';
import '../../shared/view/voucher_defaults_fields.dart';
import '../model/waybill_model.dart';
import '../model/waybill_type.dart';
import '../viewmodel/waybill_repository.dart';
import 'waybill_customer_selection_screen.dart';

export '../model/waybill_type.dart';

/// {@template _WaybillLine}
/// Yerel dens kalem satırı (stub sepet).
/// {@endtemplate}
class _WaybillLine {
  /// [productId]: Ürün kimliği
  final String productId;

  /// [name]: Ürün adı
  final String name;

  /// [code]: Ürün kodu
  final String code;

  /// [qty]: Miktar
  double qty;

  _WaybillLine({
    required this.productId,
    required this.name,
    required this.code,
  }) : qty = 1;
}

/// {@template WaybillEntryScreen}
/// İrsaliye giriş ekranı — cari zorunlu, Stok/Hizmet dens katalog.
///
/// UI stili [OrderEntryScreen] dens kalıbı; muhasebe: irsaliye ≠ fatura.
/// Rota: [routeWholesale] / [routePurchase]
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   WaybillEntryScreen.routeWholesale,
///   arguments: cariId,
/// );
/// ```
/// {@endtemplate}
class WaybillEntryScreen extends StatefulWidget {
  /// Rota: `/field-sales/waybill-wholesale`
  static const String routeWholesale = '/field-sales/waybill-wholesale';

  /// Rota: `/field-sales/waybill-purchase`
  static const String routePurchase = '/field-sales/waybill-purchase';

  /// [cariId]: İrsaliyenin bağlanacağı cari kart kimliği (zorunlu)
  final String cariId;

  /// [waybillType]: Toptan satış veya satın alma
  final WaybillType waybillType;

  /// [title]: AppBar başlığı override (null → tip l10n)
  final String? title;

  const WaybillEntryScreen({
    Key? key,
    required this.cariId,
    this.waybillType = WaybillType.wholesale,
    this.title,
  }) : super(key: key);

  /// {@template isValidCustomerId}
  /// Cari kimliğinin irsaliye için geçerli olup olmadığını kontrol eder.
  /// {@endtemplate}
  static bool isValidCustomerId(String? customerId) =>
      WaybillCustomerSelectionScreen.isValidCustomerId(customerId);

  /// {@template titleKeyForType}
  /// Tip → l10n anahtarı (stub başlık).
  /// {@endtemplate}
  static String titleKeyForType(WaybillType type) {
    switch (type) {
      case WaybillType.purchase:
        return 'field_sales.stubs.waybill_purchase';
      case WaybillType.wholesale:
        return 'field_sales.stubs.waybill_wholesale';
    }
  }

  /// {@template buildDispatchQueuePayload}
  /// Logo `dispatches/sync` kuyruk gövdesi (fatura TYPE 8 flatten yok).
  /// {@endtemplate}
  static Map<String, dynamic> buildDispatchQueuePayload({
    required String customerCode,
    required WaybillType waybillType,
    List<Map<String, dynamic>> items = const [],
    Map<String, dynamic>? header,
  }) =>
      WaybillType.buildDispatchQueuePayload(
        customerCode: customerCode,
        waybillType: waybillType,
        items: items,
        header: header,
      );

  @override
  State<WaybillEntryScreen> createState() => _WaybillEntryScreenState();
}

class _WaybillEntryScreenState extends State<WaybillEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  final List<_WaybillLine> _lines = [];
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    Future.microtask(() {
      if (!WaybillEntryScreen.isValidCustomerId(widget.cariId)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context).translate(
                'field_sales.waybill_requires_customer',
              ),
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => WaybillCustomerSelectionScreen(
              title: widget.title,
              waybillType: widget.waybillType,
            ),
          ),
        );
        return;
      }
      _fetchProducts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// {@template _fetchProducts}
  /// Yerel SQLite ürün kataloğunu yükler (cari → stok akışı).
  /// {@endtemplate}
  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      final results = await sqliteDb.query('products');
      if (!mounted) return;
      setState(() {
        _products = results;
        _isLoadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingProducts = false);
    }
  }

  /// {@template _open_barcode_lookup}
  /// Barkod dens lookup açar; seçilen ürünü irsaliye satırına ekler.
  /// {@endtemplate}
  Future<void> _openBarcodeLookup() async {
    final product = await openFieldSalesBarcodeScan(context);
    if (product == null || !mounted) return;
    _addLine(product);
  }

  /// {@template _addLine}
  /// Katalog ürününü dens sepete ekler / miktar artırır.
  /// {@endtemplate}
  void _addLine(Map<String, dynamic> p) {
    final id = p['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final existing = _lines.where((l) => l.productId == id).toList();
    setState(() {
      if (existing.isNotEmpty) {
        existing.first.qty += 1;
      } else {
        _lines.add(
          _WaybillLine(
            productId: id,
            name: p['name']?.toString() ?? '',
            code: p['code']?.toString() ?? '',
          ),
        );
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = widget.title ??
        l10n.translate(WaybillEntryScreen.titleKeyForType(widget.waybillType));

    return UnsavedVoucherScope(
      hasUnsaved: _lines.isNotEmpty,
      onDiscard: () => setState(() => _lines.clear()),
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
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: l10n.translate('field_sales.delivery_hold.add_hold'),
            icon: const Icon(Icons.pause_circle_outline),
            onPressed: _lines.isEmpty ? null : () => _putOnHold(l10n),
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
              child: _lines.isNotEmpty
                  ? Badge(
                      label: Text(
                        '${_lines.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      backgroundColor: Colors.red,
                      alignment: const AlignmentDirectional(16, -4),
                      child: Text(
                        l10n.translate('field_sales.products_in_waybill'),
                      ),
                    )
                  : Text(l10n.translate('field_sales.products_in_waybill')),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCatalog(l10n),
          _buildCart(l10n),
        ],
      ),
      bottomNavigationBar:
          _tabController.index == 1 ? _buildBottomBar(l10n) : null,
      ),
    );
  }

  /// {@template _buildCatalog}
  /// Stok/Hizmet dens katalog: MBT toolbar + arama + ürün listesi.
  /// {@endtemplate}
  Widget _buildCatalog(AppLocalization l10n) {
    final query = _searchController.text.toLowerCase();
    final filtered = _products.where((p) {
      final name = p['name']?.toString().toLowerCase() ?? '';
      final code = p['code']?.toString().toLowerCase() ?? '';
      final barcode = p['barcode']?.toString().toLowerCase() ?? '';
      return name.contains(query) ||
          code.contains(query) ||
          barcode.contains(query);
    }).toList();

    return Column(
      children: [
        MbtCatalogToolbar(
          onAction: (action) {
            switch (action) {
              case MbtCatalogToolbarAction.barcode:
              case MbtCatalogToolbarAction.camera:
                _openBarcodeLookup();
                break;
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
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.translate('field_sales.search_products_hint'),
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF00A8E8),
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.red,
                          size: 18,
                        ),
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
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? _buildEmptyState(
                      l10n.translate('field_sales.no_products_found'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        final name = p['name']?.toString() ?? '';
                        final code = p['code']?.toString() ?? '';
                        final unit = p['unit']?.toString() ?? 'Adet';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              _addLine(p);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.translate(
                                      'field_sales.product_added',
                                      args: {'name': name},
                                    ),
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
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
                                          '$code · $unit',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.grey.shade400,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  /// {@template _buildCart}
  /// İrsaliye kalemleri + MBT dens fiş ön değer alanları.
  /// {@endtemplate}
  Widget _buildCart(AppLocalization l10n) {
    if (_lines.isEmpty) {
      return _buildEmptyState(
        l10n.translate('field_sales.waybill_cart_empty'),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        ..._lines.map((line) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              title: Text(
                line.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                line.code,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () {
                      setState(() {
                        if (line.qty <= 1) {
                          _lines.remove(line);
                        } else {
                          line.qty -= 1;
                        }
                      });
                    },
                  ),
                  Text(
                    '${line.qty.toInt()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () => setState(() => line.qty += 1),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        const VoucherDefaultsFields(),
      ],
    );
  }

  /// {@template _resolveCustomerLabel}
  /// Hold kaydı için cari kod / ünvan (yoksa cariId).
  /// {@endtemplate}
  Future<({String code, String name})> _resolveCustomerLabel() async {
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      final rows = await sqliteDb.query(
        'customers',
        columns: ['code', 'name'],
        where: 'id = ?',
        whereArgs: [widget.cariId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return (code: widget.cariId, name: widget.cariId);
      }
      final code = rows.first['code']?.toString().trim() ?? '';
      final name = rows.first['name']?.toString().trim() ?? '';
      return (
        code: code.isNotEmpty ? code : widget.cariId,
        name: name.isNotEmpty ? name : widget.cariId,
      );
    } catch (_) {
      return (code: widget.cariId, name: widget.cariId);
    }
  }

  /// {@template _putOnHold}
  /// Dens sepeti [DeliveryHoldStore.add] ile beklemeye alır; sepeti temizler.
  /// {@endtemplate}
  Future<void> _putOnHold(AppLocalization l10n) async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.waybill_min_products')),
        ),
      );
      return;
    }
    if (!WaybillEntryScreen.isValidCustomerId(widget.cariId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.waybill_save_requires_customer'),
          ),
        ),
      );
      return;
    }

    final label = await _resolveCustomerLabel();
    if (!mounted) return;

    await const DeliveryHoldEntry().addFromWaybill(
      holdId: const Uuid().v4(),
      waybillType: widget.waybillType,
      customerCode: label.code,
      customerName: label.name,
      note: l10n.translate('field_sales.delivery_hold.sample_note'),
    );

    if (!mounted) return;
    setState(() => _lines.clear());
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

  /// {@template _saveWaybill}
  /// SQLite kaydı + sync_queue dispatch enqueue (TYPE koru).
  /// {@endtemplate}
  Future<void> _saveWaybill(AppLocalization l10n) async {
    if (!WaybillEntryScreen.isValidCustomerId(widget.cariId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.waybill_save_requires_customer'),
          ),
        ),
      );
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.waybill_min_products')),
        ),
      );
      return;
    }

    try {
      final dbService = await DatabaseService.getInstance();
      final sqliteDb = await dbService.getDatabase();
      await sqliteDb.execute(SqlQuerys.createWaybillsTable);
      await sqliteDb.execute(SqlQuerys.createWaybillItemsTable);
      await sqliteDb.execute(SqlQuerys.createSyncQueueTable);

      final inputs = _lines
          .map(
            (l) => WaybillLineInput(
              productId: l.productId,
              productCode: l.code,
              quantity: l.qty,
            ),
          )
          .toList();

      final result = await const WaybillRepository().saveAndEnqueue(
        sqliteDb,
        customerId: widget.cariId,
        waybillType: widget.waybillType,
        lines: inputs,
      );

      if (!mounted) return;
      if (!result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.translate(
                result.errorKey ?? 'field_sales.waybill_save_failed',
              ),
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.waybill_saved')),
        ),
      );
      Navigator.of(context).maybePop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.waybill_save_failed')),
        ),
      );
    }
  }

  /// {@template _buildBottomBar}
  /// Kaydet çubuğu — SQLite + job_queue dispatch TYPE.
  /// {@endtemplate}
  Widget _buildBottomBar(AppLocalization l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF375A7F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _lines.isEmpty ? null : () => _saveWaybill(l10n),
            child: Text(
              l10n.translate('field_sales.waybill_save'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
