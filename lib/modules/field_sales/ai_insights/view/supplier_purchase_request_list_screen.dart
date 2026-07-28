// Dosya Adı: supplier_purchase_request_list_screen.dart
// Açıklama: Depocu tedarik talep dens listesi + oluşturma
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../../shared/view/field_sales_dens_theme.dart';
import '../model/supplier_purchase_request.dart';
import '../viewmodel/supplier_purchase_request_store.dart';

/// {@template supplier_purchase_request_list_screen}
/// Tedarikçi ürün talep dens listesi.
/// Route: `/field-sales/supply-requests`
/// {@endtemplate}
class SupplierPurchaseRequestListScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/supply-requests';

  /// Store inject (test)
  final SupplierPurchaseRequestStore? store;

  /// {@macro supplier_purchase_request_list_screen}
  const SupplierPurchaseRequestListScreen({Key? key, this.store})
      : super(key: key);

  @override
  State<SupplierPurchaseRequestListScreen> createState() =>
      _SupplierPurchaseRequestListScreenState();
}

class _SupplierPurchaseRequestListScreenState
    extends State<SupplierPurchaseRequestListScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final SupplierPurchaseRequestStore _store =
      widget.store ?? const SupplierPurchaseRequestStore();

  List<SupplierPurchaseRequest> _rows = const [];
  bool _loading = true;
  bool _unsyncedOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _store.listActive(
        query: _searchController.text,
        unsyncedOnly: _unsyncedOnly,
      );
      if (!mounted) return;
      setState(() {
        _rows = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = const [];
        _loading = false;
      });
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.pushNamed(
      context,
      SupplierPurchaseRequestFormScreen.routeName,
    );
    if (created == true) await _load();
  }

  Future<void> _submit(SupplierPurchaseRequest row) async {
    await _store.submitForApproval(row.id);
    await _load();
  }

  Future<void> _approve(SupplierPurchaseRequest row) async {
    await _store.approve(row.id);
    await _load();
  }

  Future<void> _delete(SupplierPurchaseRequest row) async {
    await _store.softDelete(row.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.supply_request');
    final primary = FieldSalesDensAppBar.primaryColor;

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.add,
            tooltip: l10n.translate('field_sales.supply_request.create'),
            onPressed: _openCreate,
          ),
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.refresh,
            tooltip: l10n.translate('field_sales.ai_insights.refresh'),
            onPressed: _loading ? null : _load,
          ),
        ],
        bottom: FieldSalesDensFilterBar(
          children: [
            FieldSalesDensChipRow(
              items: [
                FieldSalesDensChipItem(
                  label: l10n.translate(
                    'field_sales.supply_request.filter_all',
                  ),
                  selected: !_unsyncedOnly,
                  onTap: () {
                    if (!_unsyncedOnly) return;
                    setState(() => _unsyncedOnly = false);
                    _load();
                  },
                ),
                FieldSalesDensChipItem(
                  label: l10n.translate(
                    'field_sales.supply_request.filter_untransferred',
                  ),
                  selected: _unsyncedOnly,
                  onTap: () {
                    if (_unsyncedOnly) return;
                    setState(() => _unsyncedOnly = true);
                    _load();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => _load(),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.translate('common.search'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search, size: 18),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _rows.isEmpty
                    ? Center(
                        child: Text(
                          l10n.translate(
                            _unsyncedOnly
                                ? 'field_sales.supply_request.empty_untransferred'
                                : 'field_sales.supply_request.empty',
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: FieldSalesDensTheme.muted(context),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final row = _rows[index];
                          return _RequestTile(
                            row: row,
                            l10n: l10n,
                            primary: primary,
                            onSubmit: () => _submit(row),
                            onApprove: () => _approve(row),
                            onDelete: () => _delete(row),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: SizedBox(
                height: 40,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _openCreate,
                  child: Text(
                    l10n.translate('field_sales.supply_request.create'),
                    style: const TextStyle(fontSize: 13),
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

class _RequestTile extends StatelessWidget {
  final SupplierPurchaseRequest row;
  final AppLocalization l10n;
  final Color primary;
  final VoidCallback onSubmit;
  final VoidCallback onApprove;
  final VoidCallback onDelete;

  const _RequestTile({
    required this.row,
    required this.l10n,
    required this.primary,
    required this.onSubmit,
    required this.onApprove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = l10n.translate(row.status.labelKey);
    final onBody = FieldSalesDensTheme.title(context);
    final onMuted = FieldSalesDensTheme.muted(context);
    final surface = FieldSalesDensTheme.surface(context);
    final border = FieldSalesDensTheme.border(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${row.productCode.isNotEmpty ? row.productCode : row.productId}'
                  ' · ${row.quantity.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onBody,
                  ),
                ),
              ),
              Text(
                statusLabel,
                style: TextStyle(fontSize: 11, color: primary),
              ),
            ],
          ),
          if (row.productName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              row.productName,
              style: TextStyle(fontSize: 12, color: onMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (row.supplierName.isNotEmpty ||
              row.supplierCode.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              row.supplierCode.isNotEmpty
                  ? '${row.supplierCode} ${row.supplierName}'
                  : row.supplierName,
              style: TextStyle(fontSize: 11, color: onMuted),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              if (row.status == SupplierPurchaseRequestStatus.draft)
                TextButton(
                  onPressed: onSubmit,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    l10n.translate('field_sales.supply_request.submit'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              if (row.status ==
                  SupplierPurchaseRequestStatus.pendingApproval)
                TextButton(
                  onPressed: onApprove,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    l10n.translate('field_sales.supply_request.approve'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// {@template supplier_purchase_request_form_screen}
/// Tedarik talep oluşturma dens formu.
/// Route: `/field-sales/supply-requests/new`
/// {@endtemplate}
class SupplierPurchaseRequestFormScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/supply-requests/new';

  /// Store inject
  final SupplierPurchaseRequestStore? store;

  /// {@macro supplier_purchase_request_form_screen}
  const SupplierPurchaseRequestFormScreen({Key? key, this.store})
      : super(key: key);

  @override
  State<SupplierPurchaseRequestFormScreen> createState() =>
      _SupplierPurchaseRequestFormScreenState();
}

class _SupplierPurchaseRequestFormScreenState
    extends State<SupplierPurchaseRequestFormScreen> {
  late final SupplierPurchaseRequestStore _store =
      widget.store ?? const SupplierPurchaseRequestStore();

  final _qtyCtrl = TextEditingController(text: '1');
  final _notesCtrl = TextEditingController();
  final _productCodeCtrl = TextEditingController();
  final _productNameCtrl = TextEditingController();
  final _productIdCtrl = TextEditingController();

  List<Map<String, dynamic>> _suppliers = const [];
  List<Map<String, dynamic>> _suggestions = const [];
  String? _supplierId;
  String _supplierCode = '';
  String _supplierName = '';
  String _warehouseCode = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    _productCodeCtrl.dispose();
    _productNameCtrl.dispose();
    _productIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _store.ensureReady();
    final suppliers = await _store.listSuppliers();
    final suggestions = await _store.suggestFromLowStock();
    if (!mounted) return;
    setState(() {
      _suppliers = suppliers;
      _suggestions = suggestions;
    });
  }

  void _applySuggestion(Map<String, dynamic> s) {
    setState(() {
      _productIdCtrl.text = (s['product_id'] ?? '').toString();
      _productCodeCtrl.text = (s['product_code'] ?? '').toString();
      _productNameCtrl.text = (s['product_name'] ?? '').toString();
      _warehouseCode = (s['warehouse_code'] ?? '').toString();
      final q = (s['quantity'] as num?)?.toDouble() ?? 0;
      final need = (10 - q).clamp(1, 9999);
      _qtyCtrl.text = need.toStringAsFixed(0);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalization.of(context);
    final productId = _productIdCtrl.text.trim().isNotEmpty
        ? _productIdCtrl.text.trim()
        : _productCodeCtrl.text.trim();
    final qty = double.tryParse(_qtyCtrl.text.trim().replaceAll(',', '.'));
    if (productId.isEmpty || qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.supply_request.validation'),
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _store.create(
        productId: productId,
        productCode: _productCodeCtrl.text.trim(),
        productName: _productNameCtrl.text.trim(),
        quantity: qty,
        supplierId: _supplierId,
        supplierCode: _supplierCode,
        supplierName: _supplierName,
        warehouseCode: _warehouseCode,
        notes: _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.supply_request.save_failed'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final primary = FieldSalesDensAppBar.primaryColor;

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.supply_request.create'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
        children: [
          if (_suggestions.isNotEmpty) ...[
            Text(
              l10n.translate('field_sales.supply_request.from_stock'),
              style: TextStyle(fontSize: 12, color: primary),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length.clamp(0, 12),
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final s = _suggestions[i];
                  final code = (s['product_code'] ?? '').toString();
                  final qty = (s['quantity'] as num?)?.toDouble() ?? 0;
                  return InkWell(
                    onTap: () => _applySuggestion(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: primary),
                        borderRadius: BorderRadius.circular(4),
                        color: FieldSalesDensTheme.surface(context),
                      ),
                      child: Text(
                        '${code.isEmpty ? s['product_id'] : code}'
                        ' (${qty.toStringAsFixed(0)})',
                        style: TextStyle(fontSize: 11, color: primary),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
          _denseField(
            controller: _productCodeCtrl,
            label: l10n.translate('field_sales.supply_request.product_code'),
          ),
          const SizedBox(height: 8),
          _denseField(
            controller: _productNameCtrl,
            label: l10n.translate('field_sales.supply_request.product_name'),
          ),
          const SizedBox(height: 8),
          _denseField(
            controller: _productIdCtrl,
            label: l10n.translate('field_sales.supply_request.product_id'),
          ),
          const SizedBox(height: 8),
          _denseField(
            controller: _qtyCtrl,
            label: l10n.translate('field_sales.supply_request.quantity'),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isDense: true,
            value: _supplierId,
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.translate(
                'field_sales.supply_request.supplier',
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(
                  l10n.translate('field_sales.supply_request.supplier_none'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              ..._suppliers.map((s) {
                final id = (s['id'] ?? '').toString();
                final code = (s['code'] ?? '').toString();
                final name = (s['name'] ?? '').toString();
                return DropdownMenuItem(
                  value: id,
                  child: Text(
                    '$code $name',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (id) {
              setState(() {
                _supplierId = id;
                Map<String, dynamic>? match;
                for (final s in _suppliers) {
                  if ((s['id']?.toString() ?? '') == id) {
                    match = s;
                    break;
                  }
                }
                _supplierCode = match?['code']?.toString() ?? '';
                _supplierName = match?['name']?.toString() ?? '';
              });
            },
          ),
          const SizedBox(height: 8),
          _denseField(
            controller: _notesCtrl,
            label: l10n.translate('field_sales.supply_request.notes'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.translate('common.save'),
                      style: const TextStyle(fontSize: 13),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _denseField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 13),
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
