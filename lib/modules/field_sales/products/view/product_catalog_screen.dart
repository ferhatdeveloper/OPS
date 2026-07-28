// Dosya Adı: product_catalog_screen.dart
// Açıklama: Ürün katalogu dens listesi (MBT STOK — products SQLite)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

import '../../../../core/init/navigation/routes.dart';
import '../../../../core/localization/app_localization.dart';
import '../../shared/view/catalog_barcode_actions.dart';
import '../../shared/view/mbt_catalog_toolbar.dart';
import '../model/product_catalog_row.dart';
import '../model/product_catalog_seed.dart';
import '../viewmodel/product_catalog_store.dart';
import 'product_detail_screen.dart';

/// {@template _product_catalog_card_filter}
/// MBT Stok / Hizmet kartı süzgeci.
/// {@endtemplate}
enum _ProductCatalogCardFilter {
  /// Tüm kartlar
  all,

  /// Stok kartları
  stock,

  /// Hizmet kartları
  service,
}

/// {@template product_catalog_screen}
/// Ürün katalog dens listesi — MBT toolbar + kod/ad/barkod arama.
/// Kaynak: SQLite `products` (boşsa seed).
/// Route: `/field-sales/product-catalog`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, ProductCatalogScreen.routeName);
/// ```
/// {@endtemplate}
class ProductCatalogScreen extends StatefulWidget {
  /// [routeName]: Named route — menü seed ile aynı
  static const String routeName = ProductCatalogSeed.route;

  /// [products]: Opsiyonel kayıtlar (null → SQLite `products`)
  final List<ProductCatalogRow>? products;

  /// [store]: Opsiyonel store (null → varsayılan [ProductCatalogStore])
  final ProductCatalogStore? store;

  const ProductCatalogScreen({
    Key? key,
    this.products,
    this.store,
  }) : super(key: key);

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  /// [_searchController]: Arama alanı
  final TextEditingController _searchController = TextEditingController();

  /// [_searchFocusNode]: Ara toolbar → odak
  final FocusNode _searchFocusNode = FocusNode();

  /// [_allRows]: SQLite / enjekte tüm satırlar
  List<ProductCatalogRow> _allRows = const [];

  /// [_query]: Aktif arama metni
  String _query = '';

  /// [_cardFilter]: Stok / hizmet süzgeci
  _ProductCatalogCardFilter _cardFilter = _ProductCatalogCardFilter.all;

  /// [_codeNameOnly]: Kod/Ad modu (barkod/kategori hariç arama)
  bool _codeNameOnly = false;

  /// [_categoryFilter]: Grup süzgeci (null = tüm gruplar)
  String? _categoryFilter;

  /// [_loading]: İlk yükleme durumu
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// {@template product_catalog_screen_load_rows}
  /// Enjekte kayıt varsa kullanır; yoksa SQLite `products` okur.
  /// {@endtemplate}
  Future<void> _loadRows() async {
    final injected = widget.products;
    if (injected != null) {
      setState(() {
        _allRows = injected;
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final store = widget.store ?? const ProductCatalogStore();
      final rows = await store.loadAll();
      if (!mounted) return;
      setState(() {
        _allRows = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allRows = const [];
        _loading = false;
      });
    }
  }

  /// {@template product_catalog_screen_row_matches}
  /// Aktif arama moduna göre satır eşleşmesi.
  /// {@endtemplate}
  bool _rowMatchesQuery(ProductCatalogRow row) {
    final q = _query.trim();
    if (q.isEmpty) return true;
    if (_codeNameOnly) {
      final lower = q.toLowerCase();
      return row.name.toLowerCase().contains(lower) ||
          row.code.toLowerCase().contains(lower);
    }
    return row.matches(q);
  }

  /// {@template product_catalog_screen_visible}
  /// Toolbar + arama filtresi uygulanmış dens satırlar.
  /// {@endtemplate}
  List<ProductCatalogRow> get _visibleRows {
    return _allRows.where((row) {
      if (_categoryFilter != null &&
          row.category.trim().toUpperCase() !=
              _categoryFilter!.trim().toUpperCase()) {
        return false;
      }
      switch (_cardFilter) {
        case _ProductCatalogCardFilter.stock:
          if (row.isServiceCard) return false;
          break;
        case _ProductCatalogCardFilter.service:
          if (!row.isServiceCard) return false;
          break;
        case _ProductCatalogCardFilter.all:
          break;
      }
      return _rowMatchesQuery(row);
    }).toList(growable: false);
  }

  /// {@template product_catalog_screen_open_detail}
  /// Seçilen ürünü detay ekranına taşır.
  ///
  /// Parametreler:
  /// - [row]: Dens katalog satırı
  /// {@endtemplate}
  void _openDetail(ProductCatalogRow row) async {
    final result = await Navigator.pushNamed(
      context,
      ProductDetailScreen.routeName,
      arguments: row,
    );
    if (!mounted) return;
    if (result != null) await _loadRows();
  }

  /// {@template product_catalog_open_new}
  /// Yeni ürün dens formu.
  /// {@endtemplate}
  Future<void> _openNew() async {
    final result = await Navigator.pushNamed(
      context,
      ProductDetailScreen.routeName,
    );
    if (!mounted) return;
    if (result != null) await _loadRows();
  }

  /// {@template product_catalog_screen_open_barcode}
  /// Barkod/Kamera lookup; dönüşte aramayı günceller veya detay açar.
  /// {@endtemplate}
  Future<void> _openBarcodeLookup() async {
    final product = await openFieldSalesBarcodeScan(context);
    if (product == null || !mounted) return;
    final barcode = product['barcode']?.toString().trim() ?? '';
    final code = product['code']?.toString().trim() ?? '';
    final id = product['id']?.toString() ?? '';
    final query = barcode.isNotEmpty ? barcode : code;
    if (query.isNotEmpty) {
      _searchController.text = query;
      setState(() => _query = query);
    }
    if (id.isEmpty) return;
    ProductCatalogRow? row;
    for (final candidate in _allRows) {
      if (candidate.id == id) {
        row = candidate;
        break;
      }
    }
    if (row != null && mounted) {
      _openDetail(row);
    }
  }

  /// {@template product_catalog_screen_pick_group}
  /// Grup süzgeci için kategori listesi (bottom sheet).
  /// {@endtemplate}
  Future<void> _pickCategoryGroup(AppLocalization l10n) async {
    final categories = <String>{
      for (final row in _allRows)
        if (row.category.trim().isNotEmpty) row.category.trim(),
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                dense: true,
                title: Text(
                  l10n.translate('field_sales.mbt_toolbar.group'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ListTile(
                dense: true,
                title: Text(l10n.translate('common.all')),
                onTap: () {
                  setState(() => _categoryFilter = null);
                  Navigator.pop(context);
                },
              ),
              ...categories.map(
                (cat) => ListTile(
                  dense: true,
                  title: Text(cat),
                  trailing: _categoryFilter == cat
                      ? const Icon(Icons.check, size: 18)
                      : null,
                  onTap: () {
                    setState(() => _categoryFilter = cat);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// {@template product_catalog_screen_on_toolbar}
  /// MBT katalog araç çubuğu → filtre / rota / arama odak.
  /// {@endtemplate}
  void _onToolbarAction(MbtCatalogToolbarAction action) {
    switch (action) {
      case MbtCatalogToolbarAction.stockCard:
        setState(
          () => _cardFilter = _ProductCatalogCardFilter.stock,
        );
        return;
      case MbtCatalogToolbarAction.serviceCard:
        setState(
          () => _cardFilter = _ProductCatalogCardFilter.service,
        );
        return;
      case MbtCatalogToolbarAction.codeName:
        setState(() => _codeNameOnly = !_codeNameOnly);
        return;
      case MbtCatalogToolbarAction.barcode:
      case MbtCatalogToolbarAction.camera:
        _openBarcodeLookup();
        return;
      case MbtCatalogToolbarAction.group:
        _pickCategoryGroup(AppLocalization.of(context));
        return;
      case MbtCatalogToolbarAction.image:
        Navigator.pushNamed(context, AppRoutes.fieldSalesImageSettings);
        return;
      case MbtCatalogToolbarAction.search:
        FocusScope.of(context).requestFocus(_searchFocusNode);
        return;
    }
  }

  /// {@template product_catalog_screen_build_search}
  /// MBT dens arama şeridi (belge katalog parity).
  /// {@endtemplate}
  Widget _buildSearchBar(AppLocalization l10n) {
    return Container(
      color: const Color(0xFF375A7F),
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: const TextStyle(fontSize: 13),
          textInputAction: TextInputAction.search,
          textCapitalization: TextCapitalization.none,
          keyboardType: TextInputType.text,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            isDense: true,
            hintText: l10n.translate('field_sales.search_products_hint'),
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFF00A8E8),
              size: 18,
            ),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.qr_code_scanner,
                      color: Color(0xFF375A7F),
                      size: 18,
                    ),
                    onPressed: _openBarcodeLookup,
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.product_catalog');
    final rows = _visibleRows;
    final hasFilter = _query.trim().isNotEmpty ||
        _cardFilter != _ProductCatalogCardFilter.all ||
        _categoryFilter != null;
    final emptyKey = hasFilter
        ? 'field_sales.product_catalog_not_found'
        : 'field_sales.product_catalog_empty';

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
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadRows,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        mini: true,
        onPressed: _loading ? null : _openNew,
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MbtCatalogToolbar(onAction: _onToolbarAction),
                _buildSearchBar(l10n),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                  child: Text(
                    l10n
                        .translate('field_sales.product_catalog_count_label')
                        .replaceAll('{count}', '${rows.length}'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                Expanded(
                  child: rows.isEmpty
                      ? Center(
                          child: Text(
                            l10n.translate(emptyKey),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(8, 2, 8, 12),
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            final meta = l10n
                                .translate(
                                  'field_sales.product_catalog_row_subtitle',
                                )
                                .replaceAll('{code}', row.code)
                                .replaceAll('{unit}', row.unit)
                                .replaceAll('{stock}', row.stockText)
                                .replaceAll('{price}', row.priceText);

                            return InkWell(
                              onTap: () => _openDetail(row),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            row.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                              height: 1.15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            meta,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 10,
                                              height: 1.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: Colors.grey.shade400,
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
}
