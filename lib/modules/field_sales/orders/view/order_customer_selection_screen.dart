// Dosya Adı: order_customer_selection_screen.dart
// Açıklama: Sipariş girişi öncesi zorunlu cari (müşteri) seçim ekranı
// Oluşturulma Tarihi: 2026-07-25
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';
import '../../customers/viewmodel/customer_provider.dart';
import '../../customers/model/customer_model.dart';
import '../model/order_model.dart';
import '../viewmodel/order_provider.dart';
import 'order_entry_screen.dart';
import '../../shared/view/field_sales_dens_theme.dart';

/// {@template order_customer_selection_screen}
/// Plasiyer sipariş/fatura girmeden önce cari kart seçer.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => const OrderCustomerSelectionScreen(
///     orderType: OrderType.sales,
///   ),
/// ));
/// ```
/// {@endtemplate}
class OrderCustomerSelectionScreen extends ConsumerStatefulWidget {
  /// [selectHintKey]: Üst bilgi satırı çeviri anahtarı
  final String selectHintKey;

  /// [orderType]: Satış / Alış — entry'ye aktarılır
  final OrderType orderType;

  /// [onCustomerSelected]: Verilirse sipariş yerine bu callback çalışır
  /// (örn. fatura girişi). Null ise [OrderEntryScreen] açılır.
  final void Function(BuildContext context, CustomerModel customer)?
      onCustomerSelected;

  const OrderCustomerSelectionScreen({
    Key? key,
    this.selectHintKey = 'field_sales.select_customer_first',
    this.orderType = OrderType.sales,
    this.onCustomerSelected,
  }) : super(key: key);

  /// {@template hintKeyFor}
  /// Sipariş tipine göre varsayılan üst bilgi çeviri anahtarı.
  /// {@endtemplate}
  static String hintKeyFor(OrderType orderType) {
    return orderType == OrderType.purchase
        ? 'field_sales.select_supplier_first'
        : 'field_sales.select_customer_first';
  }

  /// {@template emptyMessage}
  /// Boş DB / arama sonucu için çeviri anahtarı.
  /// UI: `AppLocalization.of(context).translate(emptyMessage(query))`
  /// {@endtemplate}
  static String emptyMessage(
    String query, {
    OrderType orderType = OrderType.sales,
  }) {
    final empty = query.trim().isEmpty;
    if (orderType == OrderType.purchase) {
      return empty
          ? 'field_sales.no_supplier_cards'
          : 'field_sales.supplier_not_found';
    }
    return empty
        ? 'field_sales.no_customer_cards'
        : 'field_sales.customer_not_found';
  }

  @override
  ConsumerState<OrderCustomerSelectionScreen> createState() =>
      _OrderCustomerSelectionScreenState();
}

class _OrderCustomerSelectionScreenState
    extends ConsumerState<OrderCustomerSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // CustomerListScreen pattern: açılışta tüm carileri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerProvider.notifier).fetchCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// {@template _openOrderEntry}
  /// Seçilen cari ile varsayılan sipariş girişi veya özel callback çalıştırır.
  ///
  /// Parametreler:
  /// - [customer]: Seçilen cari kart
  /// {@endtemplate}
  void _openOrderEntry(CustomerModel customer) {
    if (customer.id.trim().isEmpty) return;
    final onSelected = widget.onCustomerSelected;
    if (onSelected != null) {
      onSelected(context, customer);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderEntryScreen(
          customerId: customer.id,
          customerName: customer.name,
          customerCode: customer.code ?? customer.taxNo,
          orderType: widget.orderType,
          cardRole: customer.cardRole,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);
    final l10n = AppLocalization.of(context);
    const Color primary = Color(0xFF375A7F);
    final hintKey = widget.selectHintKey == 'field_sales.select_customer_first'
        ? OrderCustomerSelectionScreen.hintKeyFor(widget.orderType)
        : widget.selectHintKey;
    final visibleCustomers = OrderNotifier.filterForOrderType(
      state.customers,
      widget.orderType,
    );
    final hasSelectable = visibleCustomers.any((c) => c.id.trim().isNotEmpty);
    final titleKey = widget.orderType == OrderType.purchase
        ? 'field_sales.supplier_selection'
        : 'field_sales.customer_selection';

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          l10n.translate(titleKey),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(customerProvider.notifier).fetchCustomers(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Text(
              l10n.translate(hintKey),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() => _query = value);
                ref.read(customerProvider.notifier).searchCustomers(value);
              },
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.translate(
                  'field_sales.search_customer_code_hint',
                ),
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                          ref
                              .read(customerProvider.notifier)
                              .fetchCustomers();
                        },
                      )
                    : null,
                filled: true,
                fillColor: FieldSalesDensTheme.surface(context),
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
          const SizedBox(height: 6),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : !hasSelectable
                    ? Center(
                        child: Text(
                          l10n.translate(
                            OrderCustomerSelectionScreen.emptyMessage(
                              _query,
                              orderType: widget.orderType,
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 6, 10, 16),
                        itemCount: visibleCustomers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final customer = visibleCustomers[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: FieldSalesDensTheme.surface(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
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
                                backgroundColor: primary.withOpacity(0.12),
                                child: Text(
                                  customer.name.isNotEmpty
                                      ? customer.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              title: Text(
                                customer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                customer.displayCodeOrTax,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 18,
                              ),
                              onTap: () => _openOrderEntry(customer),
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
