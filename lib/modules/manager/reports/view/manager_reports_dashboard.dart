// Dosya Adı: manager_reports_dashboard.dart
// Açıklama: MBT Yönetici Raporları hub — dönem sekmeleri + KASA/BANKA/ÇEK/SENET…
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/collections/view/bank_card_list_screen.dart';
import '../../../field_sales/collections/view/cash_card_detail_screen.dart';
import '../../../field_sales/collections/view/cash_card_list_screen.dart';
import '../../../field_sales/collections/view/check_list_screen.dart';
import '../../../field_sales/collections/view/promissory_note_list_screen.dart';
import '../../../field_sales/invoices/view/invoice_list_mbt_screen.dart';
import '../../../field_sales/orders/view/order_list_screen.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../../field_sales/yonetici/view/company_general_overview_screen.dart';

/// {@template manager_reports_dashboard}
/// Yönetici Raporları dens hub — MBT parity kartları + navigasyon.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, '/field-sales/manager-dashboard');
/// ```
/// {@endtemplate}
class ManagerReportsDashboard extends StatefulWidget {
  /// {@macro manager_reports_dashboard}
  const ManagerReportsDashboard({Key? key}) : super(key: key);

  @override
  State<ManagerReportsDashboard> createState() =>
      _ManagerReportsDashboardState();
}

class _ManagerReportsDashboardState extends State<ManagerReportsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _periodTab;

  /// Stub tutar gösterimi (canlı aggregate yok).
  static const String _zero = '0,00';

  @override
  void initState() {
    super.initState();
    _periodTab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _periodTab.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.year}';
  }

  /// Hub kartlarından dens detay — named route yerine doğrudan push
  /// (embedded dashboard içinde rota kaçırma riskini önler).
  void _pushPage(Widget page, {String? routeName}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: routeName == null ? null : RouteSettings(name: routeName),
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).colorScheme.surface
        : const Color(0xFFF8F9FD);
    final now = DateTime.now();
    final dateText = _fmtDate(now);

    return Scaffold(
      backgroundColor: bg,
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('submodules.yonetici_raporlari'),
        backgroundColor: isDark
            ? Theme.of(context).appBarTheme.backgroundColor
            : FieldSalesDensAppBar.primaryColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Column(
            children: [
              TabBar(
                controller: _periodTab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: FieldSalesDensAppBar.primaryColor,
                unselectedLabelColor: Colors.white70,
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 11,
                ),
                tabs: [
                  Tab(
                    height: 28,
                    text: l10n.translate('field_sales.period_today'),
                  ),
                  Tab(
                    height: 28,
                    text: l10n.translate('field_sales.period_this_week'),
                  ),
                  Tab(
                    height: 28,
                    text: l10n.translate('field_sales.period_this_month'),
                  ),
                  Tab(
                    height: 28,
                    text: l10n.translate('field_sales.period_this_year'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${l10n.translate('field_sales.date_start_label')} '
                        '$dateText',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      '${l10n.translate('field_sales.date_end_label')} '
                      '$dateText',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
        children: [
          _ReportCard(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFF1976D2),
            title: l10n.translate('manager_dashboard.card_cash'),
            lines: [
              _line(
                l10n,
                'manager_dashboard.inflows_total',
                _zero,
              ),
              _line(
                l10n,
                'manager_dashboard.outflows_total',
                _zero,
              ),
              _line(l10n, 'manager_dashboard.difference', _zero),
            ],
            onTap: () => _pushPage(
              const CashCardListScreen(),
              routeName: CashCardListScreen.routeName,
            ),
            onLongPress: () => _pushPage(
              const CashCardDetailScreen(cashCode: '100 01 01'),
              routeName: CashCardDetailScreen.routeName,
            ),
          ),
          const SizedBox(height: 6),
          _ReportCard(
            icon: Icons.credit_card,
            iconColor: const Color(0xFF388E3C),
            title: l10n.translate('manager_dashboard.card_bank'),
            lines: [
              _line(
                l10n,
                'manager_dashboard.inflows_total',
                _zero,
              ),
              _line(
                l10n,
                'manager_dashboard.outflows_total',
                _zero,
              ),
              _line(l10n, 'manager_dashboard.difference', _zero),
            ],
            onTap: () => _pushPage(
              const BankCardListScreen(),
              routeName: BankCardListScreen.routeName,
            ),
          ),
          const SizedBox(height: 6),
          _ReportCard(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFFF57C00),
            title: l10n.translate('manager_dashboard.card_check'),
            lines: [
              _line(
                l10n,
                'manager_dashboard.portfolio_checks',
                _zero,
              ),
              _line(
                l10n,
                'manager_dashboard.company_checks',
                _zero,
              ),
            ],
            onTap: () => _pushPage(
              const CheckListScreen(),
              routeName: CheckListScreen.routeName,
            ),
          ),
          const SizedBox(height: 6),
          _ReportCard(
            icon: Icons.receipt_long,
            iconColor: const Color(0xFF7B1FA2),
            title: l10n.translate('manager_dashboard.card_promissory'),
            lines: [
              _line(
                l10n,
                'manager_dashboard.portfolio_notes',
                _zero,
              ),
              _line(
                l10n,
                'manager_dashboard.company_notes',
                _zero,
              ),
            ],
            onTap: () => _pushPage(
              const PromissoryNoteListScreen(),
              routeName: PromissoryNoteListScreen.routeName,
            ),
          ),
          const SizedBox(height: 6),
          _ReportCard(
            icon: Icons.insights,
            iconColor: const Color(0xFF00897B),
            title: l10n.translate('manager_dashboard.card_company_general'),
            lines: const [],
            onTap: () => _pushPage(
              const CompanyGeneralOverviewScreen(),
              routeName: CompanyGeneralOverviewScreen.routeName,
            ),
          ),
          const SizedBox(height: 6),
          _ReportCard(
            icon: Icons.receipt,
            iconColor: const Color(0xFF1565C0),
            title: l10n.translate('manager_dashboard.card_invoice'),
            lines: [
              _line(
                l10n,
                'manager_dashboard.sales_invoices',
                _zero,
              ),
              _line(
                l10n,
                'manager_dashboard.purchase_invoices',
                _zero,
              ),
            ],
            onTap: () => _pushPage(
              const InvoiceListMbtScreen(),
              routeName: InvoiceListMbtScreen.routeName,
            ),
          ),
          const SizedBox(height: 6),
          _ReportCard(
            icon: Icons.shopping_bag_outlined,
            iconColor: const Color(0xFF5D4037),
            title: l10n.translate('manager_dashboard.card_order'),
            lines: [
              _line(
                l10n,
                'manager_dashboard.sales_orders',
                _zero,
              ),
              _line(
                l10n,
                'manager_dashboard.purchase_orders',
                _zero,
              ),
            ],
            onTap: () => _pushPage(
              const OrderListScreen(),
              routeName: OrderListScreen.routeName,
            ),
          ),
        ],
      ),
    );
  }

  String _line(AppLocalization l10n, String key, String amount) {
    return '${l10n.translate(key)} : $amount';
  }
}

/// {@template manager_report_card}
/// Yönetici hub dens kart satırı.
/// {@endtemplate}
class _ReportCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> lines;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ReportCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.lines,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final subColor = isDark ? Colors.grey[400] : Colors.grey.shade700;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                    for (final line in lines) ...[
                      const SizedBox(height: 2),
                      Text(
                        line,
                        style: TextStyle(fontSize: 11, color: subColor),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: isDark ? Colors.grey[600] : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
