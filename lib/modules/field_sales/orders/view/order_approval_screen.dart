// Dosya Adı: order_approval_screen.dart
// Açıklama: Sipariş onaylama dens formu (Öneri / Sevk → SQLite)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/order_dens_row.dart';
import '../model/order_model.dart';
import '../viewmodel/order_approval_store.dart';

/// {@template order_approval_screen}
/// MBT Sipariş Onaylama: ALIŞ/SATIŞ · Öneri · Sevk · dönem filtre.
/// Kaynak: SQLite `orders` + `customers` JOIN.
/// Route: `/field-sales/orders-approval`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, OrderApprovalScreen.routeName);
/// ```
/// {@endtemplate}
class OrderApprovalScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/orders-approval`
  static const String routeName = '/field-sales/orders-approval';

  /// [store]: Opsiyonel store (test enjeksiyonu)
  final OrderApprovalStore? store;

  /// [initialRows]: Opsiyonel önceden yüklenmiş satırlar (widget test)
  final List<OrderDensRow>? initialRows;

  const OrderApprovalScreen({
    Key? key,
    this.store,
    this.initialRows,
  }) : super(key: key);

  @override
  State<OrderApprovalScreen> createState() => _OrderApprovalScreenState();
}

class _OrderApprovalScreenState extends State<OrderApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// [_store]: SQLite dens kaynağı
  late final OrderApprovalStore _store =
      widget.store ?? const OrderApprovalStore();

  /// [ _typeFilter ]: null = hepsi, sales / purchase
  OrderType? _typeFilter;

  /// [ _sevkMode ]: Sevk sekmesinde Edilebilir / Edilemez
  bool _sevkShippable = true;

  DateTime _periodFrom =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _periodTo = DateTime.now();

  /// [_rows]: SQLite dens satırları (sekme filtresi uygulanmış)
  List<OrderDensRow> _rows = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadOrders();
      }
    });
    if (widget.initialRows != null) {
      _rows = widget.initialRows!;
      _loading = false;
    } else {
      _loadOrders();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// {@template _currentTab}
  /// Aktif dens sekmesi.
  /// {@endtemplate}
  OrderApprovalDensTab get _currentTab => _tabController.index == 0
      ? OrderApprovalDensTab.proposal
      : OrderApprovalDensTab.dispatch;

  /// {@template _loadOrders}
  /// Yerel siparişleri dönem + tip + Öneri/Sevk filtresine göre yükler.
  /// {@endtemplate}
  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final list = await _store.query(
        tab: _currentTab,
        sevkShippable: _sevkShippable,
        orderType: _typeFilter,
        periodFrom: _periodFrom,
        periodTo: _periodTo,
      );
      if (!mounted) return;
      setState(() {
        _rows = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = [];
        _loading = false;
      });
    }
  }

  /// {@template _approveToShippable}
  /// Öneri satırını Sevk edilebilir yapar (SQLite status = Shippable).
  /// Tip (sales/purchase) korunur.
  /// {@endtemplate}
  Future<void> _approveToShippable(
    OrderDensRow row,
    AppLocalization l10n,
  ) async {
    if (_currentTab != OrderApprovalDensTab.proposal) return;
    final updated = await _store.updateStatus(
      id: row.id,
      status: 'Shippable',
    );
    if (!mounted) return;
    if (updated > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.order_approval_marked_shippable'),
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _loadOrders();
    }
  }

  InputDecoration _denseDecoration(String label) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _periodFrom : _periodTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _periodFrom = picked;
      } else {
        _periodTo = picked;
      }
    });
    await _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.order_approval');
    final filtered = _rows;
    final dateFmt = DateFormat('dd.MM.yyyy');

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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: l10n.translate('field_sales.order_approval_tab_proposal')),
            Tab(text: l10n.translate('field_sales.order_approval_tab_dispatch')),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<OrderType?>(
                  value: _typeFilter,
                  isDense: true,
                  decoration: _denseDecoration(
                    l10n.translate('field_sales.order_approval_type_filter'),
                  ),
                  items: [
                    DropdownMenuItem<OrderType?>(
                      value: null,
                      child: Text(
                        l10n.translate('field_sales.order_approval_type_all'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    DropdownMenuItem<OrderType?>(
                      value: OrderType.sales,
                      child: Text(
                        l10n.translate('field_sales.order_type_sales'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    DropdownMenuItem<OrderType?>(
                      value: OrderType.purchase,
                      child: Text(
                        l10n.translate('field_sales.order_type_purchase'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _typeFilter = v);
                    _loadOrders();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isFrom: true),
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: _denseDecoration(
                            l10n.translate(
                              'field_sales.order_approval_period_from',
                            ),
                          ),
                          child: Text(
                            dateFmt.format(_periodFrom),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isFrom: false),
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: _denseDecoration(
                            l10n.translate(
                              'field_sales.order_approval_period_to',
                            ),
                          ),
                          child: Text(
                            dateFmt.format(_periodTo),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_tabController.index == 1) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _sevkChip(
                          selected: _sevkShippable,
                          label: l10n.translate(
                            'field_sales.order_approval_shippable',
                          ),
                          onTap: () {
                            setState(() => _sevkShippable = true);
                            _loadOrders();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _sevkChip(
                          selected: !_sevkShippable,
                          label: l10n.translate(
                            'field_sales.order_approval_not_shippable',
                          ),
                          onTap: () {
                            setState(() => _sevkShippable = false);
                            _loadOrders();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  l10n.translate(
                    'field_sales.order_approval_count',
                    args: {'count': '${filtered.length}'},
                  ),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.translate('field_sales.order_approval_empty'),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final o = filtered[index];
                          final statusLabel = l10n.translate(
                            OrderApprovalStore.statusL10nKey(o.status),
                          );
                          return InkWell(
                            onTap: _currentTab ==
                                    OrderApprovalDensTab.proposal
                                ? () => _approveToShippable(o, l10n)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 8, 10, 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          o.displayTitle,
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
                                          '${l10n.translate(o.orderType.titleL10nKey)} · ${dateFmt.format(o.orderDate)} · ${o.totalAmount.toStringAsFixed(2)} ₺',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
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

  Widget _sevkChip({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00A8E8) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF00A8E8) : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
