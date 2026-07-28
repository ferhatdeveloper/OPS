// Dosya Adı: product_catalog_picker.dart
// Açıklama: Dens satır için SQLite ürün katalog seçici (modal)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../stock/model/product_model.dart';
import '../../stock/view/stock_slip_dens_form.dart';

/// {@template stock_slip_line_from_product}
/// Katalog ürününü dens satır yer tutucusuna çevirir.
///
/// Parametreler:
/// - [product]: Seçilen ürün
/// - [qty]: Miktar metni (varsayılan `1`)
///
/// Dönüş değeri:
/// - [StockSlipLinePlaceholder]: productId = ürün id, code = ürün kodu
/// {@endtemplate}
StockSlipLinePlaceholder stockSlipLineFromProduct(
  ProductModel product, {
  String qty = '1',
}) {
  return StockSlipLinePlaceholder(
    code: product.code.isNotEmpty ? product.code : product.id,
    name: product.name,
    qty: qty,
    productId: product.id,
    unit: product.mainUnit ?? product.unit,
  );
}

/// {@template load_products_for_catalog_picker}
/// Aktif ürünleri SQLite `products` tablosundan okur.
///
/// Dönüş değeri:
/// - [List<ProductModel>]: Katalog listesi (boş olabilir)
/// {@endtemplate}
Future<List<ProductModel>> loadProductsForCatalogPicker() async {
  final db = await DatabaseService.getInstance();
  final sqliteDb = await db.getDatabase();
  final results = await sqliteDb.query(
    'products',
    orderBy: 'name COLLATE NOCASE',
  );
  return results
      .map((raw) {
        final map = Map<String, dynamic>.from(raw);
        final id = map['id']?.toString() ?? '';
        map['id'] = id;
        map['code'] = map['code']?.toString() ?? id;
        map['name'] = map['name']?.toString() ?? '';
        return ProductModel.fromMap(map);
      })
      .where((p) => p.id.isNotEmpty)
      .toList();
}

/// {@template show_product_catalog_picker}
/// Ürün katalog seçicisini modal olarak açar.
///
/// Parametreler:
/// - [context]: BuildContext
/// - [loadProducts]: Test enjeksiyonu (opsiyonel)
///
/// Dönüş değeri:
/// - [ProductModel?]: Seçilen ürün veya iptal
/// {@endtemplate}
Future<ProductModel?> showProductCatalogPicker(
  BuildContext context, {
  Future<List<ProductModel>> Function()? loadProducts,
}) {
  return showModalBottomSheet<ProductModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: FieldSalesDensTheme.bodyBackground(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      return FractionallySizedBox(
        heightFactor: 0.92,
        child: ProductCatalogPickerSheet(
          loadProducts: loadProducts ?? loadProductsForCatalogPicker,
        ),
      );
    },
  );
}

/// {@template product_catalog_picker_sheet}
/// Arama + ürün listesi; dokununca seçili ürünü pop eder.
/// {@endtemplate}
class ProductCatalogPickerSheet extends StatefulWidget {
  /// {@template product_catalog_picker_sheet_constructor}
  /// Katalog seçici sheet oluşturur.
  /// {@endtemplate}
  const ProductCatalogPickerSheet({
    Key? key,
    required this.loadProducts,
  }) : super(key: key);

  /// [loadProducts]: Ürün listesi yükleyici
  final Future<List<ProductModel>> Function() loadProducts;

  @override
  State<ProductCatalogPickerSheet> createState() =>
      _ProductCatalogPickerSheetState();
}

class _ProductCatalogPickerSheetState extends State<ProductCatalogPickerSheet> {
  /// [_searchController]: Arama metni
  final TextEditingController _searchController = TextEditingController();

  /// [_all]: Tüm ürünler
  List<ProductModel> _all = const [];

  /// [_filtered]: Filtrelenmiş ürünler
  List<ProductModel> _filtered = const [];

  /// [_loading]: Yükleniyor
  bool _loading = true;

  /// [_error]: Hata metni
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await widget.loadProducts();
      if (!mounted) return;
      setState(() {
        _all = products;
        _filtered = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = _all;
        return;
      }
      _filtered = _all.where((p) {
        final name = p.name.toLowerCase();
        final code = p.code.toLowerCase();
        final barcode = (p.barcode ?? '').toLowerCase();
        return name.contains(query) ||
            code.contains(query) ||
            barcode.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.product_catalog');

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            color: Color(0xFF375A7F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.translate('field_sales.search_products_hint'),
              prefixIcon: const Icon(Icons.search, size: 20),
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
        ),
        Expanded(child: _buildBody(l10n)),
      ],
    );
  }

  Widget _buildBody(AppLocalization l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          l10n.translate('field_sales.no_products_found'),
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final product = _filtered[index];
        return Material(
          color: FieldSalesDensTheme.surface(context),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.of(context).pop(product),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${l10n.translate('field_sales.stock_slip.code')}: '
                          '${product.code.isNotEmpty ? product.code : product.id}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF00A8E8),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
