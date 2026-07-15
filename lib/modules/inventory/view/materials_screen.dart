import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/material_provider.dart';
import '../model/material_model.dart';
import '../../../../core/localization/app_localization.dart';

class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          AppLocalization.of(context).translate('inventory.materials'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: AppLocalization.of(context).translate('common.reload'),
            onPressed: () =>
                ref.read(materialProvider.notifier).fetchMaterials(),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: AppLocalization.of(context).translate('inventory.new_material'),
            onPressed: () => _showAddMaterialDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: const Color(0xFF8B7CC7),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalization.of(context).translate('inventory.search_material'),
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF8B7CC7)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),

          // Count bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalization.of(context).translate('inventory.products'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  '${filtered.length} ${AppLocalization.of(context).translate('inventory.records')}',
                  style:
                      TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          ),

          // Grid
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
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) =>
                                _buildCard(context, filtered[i], isDark),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, MaterialItem item, bool isDark) {
    final stockColor = item.availableStock > 0
        ? const Color(0xFF27AE60)
        : item.availableStock < 0
            ? Colors.red
            : Colors.orange;

    return GestureDetector(
      onTap: () => _showDetailDialog(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B7CC7).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF8B7CC7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Name + code + unit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF2C3E50),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${AppLocalization.of(context).translate('inventory.code')}: ${item.code}  •  ${item.unitOfMeasure}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Stock badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: stockColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${item.availableStock}',
                  style: TextStyle(
                    color: stockColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? AppLocalization.of(context).translate('inventory.no_search_result')
                : AppLocalization.of(context).translate('inventory.no_material_found'),
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddMaterialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalization.of(context).translate('inventory.new_material')),
        content: Text(AppLocalization.of(context).translate('inventory.feature_in_development')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalization.of(context).translate('common.close')),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, MaterialItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.description),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppLocalization.of(context).translate('inventory.code')}: ${item.code}'),
            if (item.description2 != null && item.description2!.isNotEmpty)
              Text('${AppLocalization.of(context).translate('inventory.description_2')}: ${item.description2}'),
            Text('${AppLocalization.of(context).translate('inventory.unit')}: ${item.unitOfMeasure}'),
            Text('${AppLocalization.of(context).translate('inventory.current_stock')}: ${item.currentStock}'),
            Text('${AppLocalization.of(context).translate('inventory.actual_stock')}: ${item.actualStock}'),
            Text('${AppLocalization.of(context).translate('inventory.available_stock')}: ${item.availableStock}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalization.of(context).translate('common.close')),
          ),
        ],
      ),
    );
  }
}
