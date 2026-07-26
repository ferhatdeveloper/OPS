// Dosya Adı: barcode_scan_screen.dart
// Açıklama: Barkod → ürün katalog dens lookup (ara · satır · Seç / pop)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../products/model/product_catalog_row.dart';
import '../../products/model/product_catalog_seed.dart';
import '../../products/viewmodel/product_catalog_store.dart';

/// {@template barcode_scan_screen}
/// Barkod / kod / ad ile ürün dens lookup ekranı.
/// Kaynak: [ProductCatalogStore] (boş/hata → seed).
///
/// [selectionMode] true iken Seç, seçili ürün haritası ile pop eder
/// (sipariş/fatura/irsaliye katalog barkod araç çubuğu).
///
/// Kullanım örneği:
/// ```dart
/// final map = await Navigator.pushNamed<Map<String, dynamic>>(
///   context,
///   '/field-sales/barcode-scan',
/// );
/// ```
/// {@endtemplate}
class BarcodeScanScreen extends StatefulWidget {
  /// [selectionMode]: true → Seç pop sonucu döner
  final bool selectionMode;

  /// [store]: Ürün kaynağı (test enjeksiyonu)
  final ProductCatalogStore? store;

  /// [products]: Sabit dens satırlar (test / smoke)
  final List<ProductCatalogRow>? products;

  /// [initialQuery]: Açılış arama metni (barkod)
  final String? initialQuery;

  /// {@macro barcode_scan_screen}
  const BarcodeScanScreen({
    Key? key,
    this.selectionMode = true,
    this.store,
    this.products,
    this.initialQuery,
  }) : super(key: key);

  /// {@template barcode_scan_screen_exact_barcode}
  /// Tam barkod eşleşen tek satır (yoksa null).
  /// {@endtemplate}
  static ProductCatalogRow? findExactBarcode(
    List<ProductCatalogRow> rows,
    String barcode,
  ) {
    final trimmed = barcode.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    final matches = rows
        .where((r) => r.barcode.trim().toLowerCase() == trimmed)
        .toList();
    if (matches.length == 1) return matches.first;
    return null;
  }

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  /// [_searchController]: Dens arama (kod / ad / barkod)
  final TextEditingController _searchController = TextEditingController();

  /// [_all]: Yüklenen ürünler
  List<ProductCatalogRow> _all = const [];

  /// [_filtered]: Süzülmüş dens satırlar
  List<ProductCatalogRow> _filtered = const [];

  /// [_selectedIndex]: Seçili dens satır
  int? _selectedIndex;

  /// [_loading]: İlk yükleme
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) {
      _searchController.text = initial;
    }
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// {@template barcode_scan_screen_load}
  /// Ürün dens listesini yükler ve süzgeç uygular.
  /// {@endtemplate}
  Future<void> _load() async {
    setState(() => _loading = true);
    List<ProductCatalogRow> rows;
    final injected = widget.products;
    if (injected != null) {
      rows = List<ProductCatalogRow>.from(injected);
    } else {
      try {
        final store = widget.store ?? const ProductCatalogStore();
        rows = await store.loadAll();
      } catch (_) {
        rows = List<ProductCatalogRow>.from(
          ProductCatalogSeed.defaultRows,
        );
      }
      if (rows.isEmpty) {
        rows = List<ProductCatalogRow>.from(
          ProductCatalogSeed.defaultRows,
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _all = rows;
      _loading = false;
      _applyFilter(_searchController.text, notify: false);
    });
  }

  /// {@template barcode_scan_screen_apply_filter}
  /// Ara kutusuna göre dens listeyi süzgeçler.
  /// {@endtemplate}
  void _applyFilter(String query, {bool notify = true}) {
    final previous = (_selectedIndex != null &&
            _selectedIndex! >= 0 &&
            _selectedIndex! < _filtered.length)
        ? _filtered[_selectedIndex!]
        : null;
    final q = query.trim();
    final filtered = q.isEmpty
        ? List<ProductCatalogRow>.from(_all)
        : _all.where((r) => r.matches(q)).toList();
    int? nextIndex;
    if (filtered.isEmpty) {
      nextIndex = null;
    } else if (previous != null) {
      final idx = filtered.indexWhere((r) => r.id == previous.id);
      nextIndex = idx >= 0 ? idx : 0;
    } else {
      nextIndex = 0;
    }
    void update() {
      _filtered = filtered;
      _selectedIndex = nextIndex;
    }

    if (notify) {
      setState(update);
    } else {
      update();
    }
  }

  /// {@template barcode_scan_screen_camera}
  /// Kamera ile barkod okur; dens süzgeç + tek eşleşmede auto-pop.
  /// {@endtemplate}
  Future<void> _scanCamera() async {
    final l10n = AppLocalization.of(context);
    try {
      final result = await BarcodeScanner.scan();
      if (result.type != ResultType.Barcode ||
          result.rawContent.trim().isEmpty) {
        return;
      }
      final raw = result.rawContent.trim();
      _searchController.text = raw;
      _applyFilter(raw);
      final exact = BarcodeScanScreen.findExactBarcode(_all, raw);
      if (exact != null && widget.selectionMode && mounted) {
        Navigator.of(context).pop<Map<String, dynamic>>(exact.toMap());
        return;
      }
      if (_filtered.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.translate('field_sales.barcode_product_not_found'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.barcode_camera_failed'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// {@template barcode_scan_screen_on_select}
  /// Seçili ürünü döndürür (selectionMode) veya ekranı kapatır.
  /// {@endtemplate}
  void _onSelect() {
    final l10n = AppLocalization.of(context);
    final idx = _selectedIndex;
    if (idx == null || idx < 0 || idx >= _filtered.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.barcode_product_select_required'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final selected = _filtered[idx];
    if (widget.selectionMode) {
      Navigator.of(context).pop<Map<String, dynamic>>(selected.toMap());
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.barcode_scan');
    const Color primary = Color(0xFF375A7F);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: l10n.translate('field_sales.barcode_scan'),
            onPressed: _scanCamera,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l10n.translate('field_sales.barcode_lookup_hint'),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.translate(
                  'field_sales.search_products_hint',
                ),
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter('');
                        },
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          size: 20,
                        ),
                        onPressed: _scanCamera,
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
              onChanged: _applyFilter,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.translate(
                            _searchController.text.trim().isEmpty
                                ? 'field_sales.no_products_found'
                                : 'field_sales.barcode_product_not_found',
                          ),
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final row = _filtered[index];
                          final selected = _selectedIndex == index;
                          return _ProductLookupDensTile(
                            row: row,
                            selected: selected,
                            onTap: () =>
                                setState(() => _selectedIndex = index),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    l10n.translate('common.select'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// {@template product_lookup_dens_tile}
/// Tek ürün dens satırı (kod + ad + barkod).
/// {@endtemplate}
class _ProductLookupDensTile extends StatelessWidget {
  /// [row]: Katalog dens satırı
  final ProductCatalogRow row;

  /// [selected]: Seçili vurgusu
  final bool selected;

  /// [onTap]: Satır seçimi
  final VoidCallback onTap;

  /// {@macro product_lookup_dens_tile}
  const _ProductLookupDensTile({
    required this.row,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final barcode = row.barcode.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFF375A7F)
                  : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (barcode.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        barcode,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF375A7F),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
