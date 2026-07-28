// Dosya Adı: materials_screen.dart
// Açıklama: Malzeme listesi dens kart + uzun basma işlemleri (MBT STOK)
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/init/navigation/routes.dart';
import '../../../core/localization/app_localization.dart';
import '../../field_sales/products/view/product_detail_screen.dart';
import '../model/material_model.dart';
import '../viewmodel/material_provider.dart';

/// {@template materials_screen}
/// Malzeme / ürün dens listesi — arama, kompakt kart, uzun basma işlemleri.
///
/// Kullanım örneği:
/// ```dart
/// const MaterialsScreen();
/// ```
/// {@endtemplate}
class MaterialsScreen extends ConsumerStatefulWidget {
  /// {@macro materials_screen}
  const MaterialsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  /// [_searchController]: Arama alanı
  final TextEditingController _searchController = TextEditingController();

  /// [_searchQuery]: Aktif arama metni
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// {@template materials_screen_filtered}
  /// Kod / açıklama filtresi.
  /// {@endtemplate}
  List<MaterialItem> _filtered(List<MaterialItem> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((m) {
      return m.code.toLowerCase().contains(q) ||
          m.description.toLowerCase().contains(q) ||
          (m.description2?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final materialState = ref.watch(materialProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered(materialState.items);
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF4F6FB),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6B4FCF), Color(0xFF8B7CC7)],
            ),
          ),
        ),
        title: Text(
          l10n.translate('inventory.materials'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: l10n.translate('common.reload'),
            onPressed: () =>
                ref.read(materialProvider.notifier).fetchMaterials(),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: l10n.translate('inventory.new_material'),
            onPressed: () => _showAddMaterialDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF8B7CC7),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                textCapitalization: TextCapitalization.none,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.translate('inventory.search_material'),
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF8B7CC7),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('inventory.products'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  '${filtered.length} ${l10n.translate('inventory.records')}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: materialState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : materialState.error != null
                    ? Center(
                        child: Text(
                          materialState.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : filtered.isEmpty
                        ? _buildEmpty(context)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, i) =>
                                _buildCard(context, filtered[i], isDark),
                          ),
          ),
        ],
      ),
    );
  }

  /// {@template materials_screen_build_card}
  /// Dens malzeme satırı — dokununca detay, uzun basınca işlemler.
  /// {@endtemplate}
  Widget _buildCard(BuildContext context, MaterialItem item, bool isDark) {
    final stockColor = item.availableStock > 0
        ? const Color(0xFF27AE60)
        : item.availableStock < 0
            ? Colors.red
            : Colors.orange;
    final l10n = AppLocalization.of(context);

    return Material(
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showDetailDialog(context, item),
        onLongPress: () => _showMaterialActions(context, item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B7CC7).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF8B7CC7),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.15,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF2C3E50),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${l10n.translate('inventory.code')}: ${item.code}'
                      '  •  ${item.unitOfMeasure}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: stockColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.availableStock}',
                  style: TextStyle(
                    color: stockColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// {@template materials_screen_actions}
  /// MBT parity: Detay · Fiyat Gör · Barkod Ekle.
  /// {@endtemplate}
  void _showMaterialActions(BuildContext context, MaterialItem item) {
    final l10n = AppLocalization.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF8F9FD),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('inventory.material_actions'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.code} · ${item.description}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                leading: const Icon(Icons.info_outline, size: 22),
                title: Text(
                  l10n.translate('inventory.action_detail'),
                  style: const TextStyle(fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _openDetail(item);
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.price_check, size: 22),
                title: Text(
                  l10n.translate('inventory.action_view_price'),
                  style: const TextStyle(fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  Navigator.pushNamed(context, AppRoutes.fieldSalesPrices);
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.qr_code_scanner, size: 22),
                title: Text(
                  l10n.translate('inventory.action_add_barcode'),
                  style: const TextStyle(fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.fieldSalesStockBarcode,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Detay ekranı (uzun bas → Detay).
  void _openDetail(MaterialItem item) {
    Navigator.pushNamed(
      context,
      ProductDetailScreen.routeName,
      arguments: {
        'id': item.code,
        'code': item.code,
        'name': item.description,
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? l10n.translate('inventory.no_search_result')
                : l10n.translate('inventory.no_material_found'),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddMaterialDialog(BuildContext context) {
    final l10n = AppLocalization.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('inventory.new_material')),
        content: Text(l10n.translate('inventory.feature_in_development')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.translate('common.close')),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, MaterialItem item) {
    final l10n = AppLocalization.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.description),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.translate('inventory.code')}: ${item.code}'),
            if (item.description2 != null && item.description2!.isNotEmpty)
              Text(
                '${l10n.translate('inventory.description_2')}: '
                '${item.description2}',
              ),
            Text('${l10n.translate('inventory.unit')}: ${item.unitOfMeasure}'),
            Text(
              '${l10n.translate('inventory.current_stock')}: '
              '${item.currentStock}',
            ),
            Text(
              '${l10n.translate('inventory.actual_stock')}: '
              '${item.actualStock}',
            ),
            Text(
              '${l10n.translate('inventory.available_stock')}: '
              '${item.availableStock}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.translate('common.close')),
          ),
        ],
      ),
    );
  }
}
