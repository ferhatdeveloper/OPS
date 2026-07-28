// Dosya Adı: customer_detail_screen.dart
// Açıklama: Cari detay hub — FATURA / İRSALİYE / SİPARİŞ / ZİYARET / FİNANS
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/init/navigation/routes.dart';
import '../../../../core/localization/app_localization.dart';
import '../../routes/view/visit_form_screen.dart';
import '../../routes/view/visit_history_screen.dart';
import '../../routes/viewmodel/weekly_route_plan_store.dart';
import '../../orders/model/order_model.dart';
import '../../orders/view/order_type_sheet.dart';
import '../model/customer_model.dart';
import '../viewmodel/customer_provider.dart';
import '../widgets/customer_visit_weekdays_tab.dart';
import 'customer_extract_screen.dart';
import 'customer_form_screen.dart';
import 'customer_reconciliation_screen.dart';

/// {@template customer_detail_hub_action}
/// MBT cari detay hub kısayolu: named route + l10n + ikon.
/// {@endtemplate}
class CustomerDetailHubAction {
  /// [routeName]: pushNamed hedefi
  final String routeName;

  /// [l10nKey]: `field_sales.customer_detail_hub_*`
  final String l10nKey;

  /// [icon]: Dense flat aksiyon ikonu
  final IconData icon;

  const CustomerDetailHubAction({
    required this.routeName,
    required this.l10nKey,
    required this.icon,
  });
}

/// {@template customer_detail_screen}
/// Cari kart detayı; hub’dan belge/ziyaret/finans named route’lara
/// `cariId` argument ile açılır (cari-önce guard ile uyumlu).
/// Sekmeler: Özet · Ziyaret günleri (haftalık rota planı).
/// {@endtemplate}
class CustomerDetailScreen extends ConsumerStatefulWidget {
  /// [customer]: Cari kart
  final CustomerModel customer;

  /// [routeStore]: Test enjeksiyonu (ziyaret günleri)
  final WeeklyRoutePlanStore? routeStore;

  /// {@macro customer_detail_screen}
  const CustomerDetailScreen({
    Key? key,
    required this.customer,
    this.routeStore,
  }) : super(key: key);

  /// MBT: FATURA · İRSALİYE · SİPARİŞ · ZİYARET · FİNANS
  static const List<CustomerDetailHubAction> hubActions =
      <CustomerDetailHubAction>[
    CustomerDetailHubAction(
      routeName: AppRoutes.fieldSalesInvoicesNew,
      l10nKey: 'field_sales.customer_detail_hub_invoice',
      icon: Icons.receipt_long_outlined,
    ),
    CustomerDetailHubAction(
      routeName: AppRoutes.fieldSalesWaybillWholesale,
      l10nKey: 'field_sales.customer_detail_hub_waybill',
      icon: Icons.local_shipping_outlined,
    ),
    CustomerDetailHubAction(
      routeName: AppRoutes.fieldSalesOrders,
      l10nKey: 'field_sales.customer_detail_hub_order',
      icon: Icons.add_shopping_cart_outlined,
    ),
    CustomerDetailHubAction(
      routeName: VisitFormScreen.routeName,
      l10nKey: 'field_sales.customer_detail_hub_visit',
      icon: Icons.place_outlined,
    ),
    CustomerDetailHubAction(
      routeName: AppRoutes.fieldSalesCollections,
      l10nKey: 'field_sales.customer_detail_hub_finance',
      icon: Icons.account_balance_wallet_outlined,
    ),
  ];

  /// {@template hubCariIdArg}
  /// Named route `arguments` için trim’li cariId; geçersizse null.
  /// {@endtemplate}
  static String? hubCariIdArg(String? customerId) {
    final id = customerId?.trim() ?? '';
    return id.isEmpty ? null : id;
  }

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState
    extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late CustomerModel _customer;
  bool _cashSaleEnabled = false;

  CustomerModel get customer => _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// {@template _openHubAction}
  /// Cari-önce named route’a `cariId` ile pushNamed.
  /// {@endtemplate}
  void _openHubAction(BuildContext context, CustomerDetailHubAction action) {
    final cariId = CustomerDetailScreen.hubCariIdArg(customer.id);
    if (cariId == null) {
      final l10n = AppLocalization.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.order_requires_customer')),
        ),
      );
      return;
    }
    if (action.routeName == AppRoutes.fieldSalesOrders) {
      showOrderTypeSheet(context).then((type) {
        if (type == null || !context.mounted) return;
        final route = type == OrderType.purchase
            ? AppRoutes.fieldSalesOrdersPurchase
            : AppRoutes.fieldSalesOrdersSales;
        Navigator.pushNamed(context, route, arguments: cariId);
      });
      return;
    }
    Navigator.pushNamed(context, action.routeName, arguments: cariId);
  }

  /// {@template _requireCariId}
  /// Trim’li cari id; yoksa snackbar ve null.
  /// {@endtemplate}
  String? _requireCariId(BuildContext context) {
    final cariId = CustomerDetailScreen.hubCariIdArg(customer.id);
    if (cariId == null) {
      final l10n = AppLocalization.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.order_requires_customer'),
          ),
        ),
      );
    }
    return cariId;
  }

  /// {@template _openCashSale}
  /// Peşin satış → fatura entry (van_sales), cari önseçili.
  /// {@endtemplate}
  void _openCashSale(BuildContext context) {
    final cariId = _requireCariId(context);
    if (cariId == null) return;
    Navigator.pushNamed(
      context,
      AppRoutes.fieldSalesInvoicesNew,
      arguments: cariId,
    );
  }

  /// {@template _openMovements}
  /// Hareketler → cari ekstre dens.
  /// {@endtemplate}
  void _openMovements(BuildContext context) {
    final cariId = _requireCariId(context);
    if (cariId == null) return;
    Navigator.pushNamed(
      context,
      CustomerExtractScreen.routeName,
      arguments: cariId,
    );
  }

  /// {@template _openReconciliation}
  /// Mutabakat → dens dönem özeti + onay/PDF.
  /// {@endtemplate}
  void _openReconciliation(BuildContext context) {
    final cariId = _requireCariId(context);
    if (cariId == null) return;
    Navigator.pushNamed(
      context,
      CustomerReconciliationScreen.routeName,
      arguments: <String, String>{
        'customerId': cariId,
        if ((customer.code ?? '').trim().isNotEmpty)
          'customerCode': customer.code!.trim(),
        'customerName': customer.name,
      },
    );
  }

  /// {@template _refreshCustomer}
  /// Cari listesini yeniler ve bu kartı günceller.
  /// {@endtemplate}
  Future<void> _refreshCustomer(BuildContext context) async {
    final l10n = AppLocalization.of(context);
    await ref.read(customerProvider.notifier).fetchCustomers();
    if (!mounted) return;
    final updated = ref
        .read(customerProvider)
        .customers
        .where((c) => c.id == customer.id)
        .toList(growable: false);
    if (updated.isNotEmpty) {
      setState(() => _customer = updated.first);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.translate('field_sales.customer_detail_refreshed'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2691E5);
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    tooltip: l10n.translate('customer.edit_title'),
                    onPressed: () async {
                      final result = await Navigator.push<Object?>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerFormScreen(
                            existingCustomer: customer,
                          ),
                        ),
                      );
                      if (result is CustomerModel && mounted) {
                        setState(() => _customer = result);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                    tooltip: l10n.translate('customer.deactivate'),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.translate('customer.deactivate')),
                          content: Text(
                            l10n.translate('customer.deactivate_confirm'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l10n.translate('common.cancel')),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(l10n.translate('common.delete')),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true || !mounted) return;
                      final ok = await ref
                          .read(customerProvider.notifier)
                          .deactivateCustomer(customer.id);
                      if (!mounted) return;
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.translate('customer.deactivate_success'),
                            ),
                          ),
                        );
                        Navigator.pop(context, true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.translate('customer.save_failed'),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Müşterilerinizin takibi cebinizde. Mobil cihazınızdan anlık olarak e-fatura, e-arşiv ve e-irsaliye düzenleyin!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: primaryBlue,
                      unselectedLabelColor: Colors.grey.shade500,
                      indicatorColor: primaryBlue,
                      indicatorWeight: 2,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      dividerColor: Colors.grey.shade200,
                      tabs: [
                        Tab(
                          height: 36,
                          text: l10n.translate(
                            'field_sales.customer_detail_tab_summary',
                          ),
                        ),
                        Tab(
                          height: 36,
                          text: l10n.translate(
                            'field_sales.customer_visit_days_tab',
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSummaryTab(context, l10n, primaryBlue),
                          CustomerVisitWeekdaysTab(
                            customerId: customer.id,
                            store: widget.routeStore,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// {@template _buildSummaryTab}
  /// Mevcut cari özet içeriği (hub + kart bilgileri).
  /// {@endtemplate}
  Widget _buildSummaryTab(
    BuildContext context,
    AppLocalization l10n,
    Color primaryBlue,
  ) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final formattedBalance = currencyFormatter.format(customer.balance);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            customer.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2C3E50),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "E-Fatura",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            customer.address?.toUpperCase() ?? "ADRES BELİRTİLMEMİŞ",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "---------------------------------",
            style: TextStyle(
              color: Colors.grey.shade300,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${customer.taxNo ?? '-'} • ${customer.taxOffice ?? '-'}",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${customer.phone ?? '-'} •",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          if (customer.email == null || customer.email!.isEmpty)
            InkWell(
              onTap: () async {
                final result = await Navigator.push<Object?>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerFormScreen(
                      existingCustomer: customer,
                    ),
                  ),
                );
                if (result is CustomerModel && mounted) {
                  setState(() => _customer = result);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: primaryBlue, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.translate(
                          'field_sales.customer_detail_email_missing',
                        ),
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('field_sales.customer_detail_cash_sale'),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                Switch(
                  value: _cashSaleEnabled,
                  onChanged: (val) {
                    setState(() => _cashSaleEnabled = val);
                    if (val) _openCashSale(context);
                  },
                  activeColor: primaryBlue,
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIconTextAction(
                  Icons.list_alt,
                  l10n.translate('field_sales.customer_detail_movements'),
                  onTap: () => _openMovements(context),
                ),
                _buildIconTextAction(
                  Icons.handshake_outlined,
                  l10n.translate(
                    'field_sales.customer_detail_reconciliation',
                  ),
                  onTap: () => _openReconciliation(context),
                ),
                _buildIconTextAction(
                  Icons.refresh,
                  l10n.translate('field_sales.customer_detail_refresh'),
                  onTap: () => _refreshCustomer(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  l10n.translate('field_sales.customer_detail_balance'),
                  formattedBalance,
                  formattedBalance,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoCard(
                  l10n.translate('field_sales.customer_detail_risk_limit'),
                  '~',
                  '₺0,00',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoCard(
                  l10n.translate('field_sales.customer_detail_aging_debt'),
                  '₺0,00',
                  '₺0,00',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 4,
            runSpacing: 8,
            children: [
              for (final action in CustomerDetailScreen.hubActions)
                _buildCircularAction(
                  action.icon,
                  l10n.translate(action.l10nKey),
                  onTap: () => _openHubAction(context, action),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.history, size: 18),
              label: Text(
                l10n.translate(
                  'field_sales.customer_detail_hub_visit_history',
                ),
                style: const TextStyle(fontSize: 13),
              ),
              onPressed: () {
                final cariId =
                    CustomerDetailScreen.hubCariIdArg(customer.id);
                if (cariId == null) return;
                Navigator.pushNamed(
                  context,
                  VisitHistoryScreen.routeName,
                  arguments: {'customerId': cariId},
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildIconTextAction(
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
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
  }

  Widget _buildInfoCard(String title, String value1, String value2) {
    const Color primaryBlue = Color(0xFF2691E5);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value1,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value2,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularAction(
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: Center(
                child: Icon(icon, color: Colors.grey.shade600, size: 22),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
