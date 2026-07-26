// Dosya Adı: product_catalog_screen.dart
// Açıklama: Ürün katalogu dens listesi (MBT STOK — products SQLite)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/product_catalog_row.dart';
import '../model/product_catalog_seed.dart';
import '../viewmodel/product_catalog_store.dart';
import 'product_detail_screen.dart';

/// {@template product_catalog_screen}
/// Ürün katalog dens listesi — kod/ad/barkod arama.
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

  /// [_allRows]: SQLite / enjekte tüm satırlar
  List<ProductCatalogRow> _allRows = const [];

  /// [_query]: Aktif arama metni
  String _query = '';

  /// [_loading]: İlk yükleme durumu
  bool _loading = true;

  /// [_primary]: OPS dens primary
  static const Color _primary = Color(0xFF375A7F);

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  /// {@template product_catalog_screen_visible}
  /// Arama filtresi uygulanmış dens satırlar.
  /// {@endtemplate}
  List<ProductCatalogRow> get _visibleRows {
    if (_query.trim().isEmpty) return _allRows;
    return _allRows.where((r) => r.matches(_query)).toList(growable: false);
  }

  /// {@template product_catalog_screen_open_detail}
  /// Seçilen ürünü detay stub ekranına taşır.
  ///
  /// Parametreler:
  /// - [row]: Dens katalog satırı
  /// {@endtemplate}
  void _openDetail(ProductCatalogRow row) {
    Navigator.pushNamed(
      context,
      ProductDetailScreen.routeName,
      arguments: {
        'id': row.id,
        'code': row.code,
        'name': row.name,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.product_catalog');
    final rows = _visibleRows;
    final emptyKey = _query.trim().isEmpty
        ? 'field_sales.product_catalog_empty'
        : 'field_sales.product_catalog_not_found';

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                  child: Text(
                    l10n.translate('field_sales.product_catalog_list_hint'),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13),
                    textInputAction: TextInputAction.search,
                    textCapitalization: TextCapitalization.none,
                    keyboardType: TextInputType.text,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.translate(
                        'field_sales.search_products_hint',
                      ),
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: Text(
                    l10n
                        .translate('field_sales.product_catalog_count_label')
                        .replaceAll('{count}', '${rows.length}'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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
                          padding: const EdgeInsets.fromLTRB(10, 6, 10, 16),
                          itemCount: rows.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            final subtitle = l10n
                                .translate(
                                  'field_sales.product_catalog_row_subtitle',
                                )
                                .replaceAll('{code}', row.code)
                                .replaceAll('{unit}', row.unit)
                                .replaceAll('{stock}', row.stockText)
                                .replaceAll('{price}', row.priceText);

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2,
                                ),
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: _primary.withOpacity(0.12),
                                  child: Text(
                                    row.name.isNotEmpty
                                        ? row.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: _primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  row.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                ),
                                onTap: () => _openDetail(row),
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
