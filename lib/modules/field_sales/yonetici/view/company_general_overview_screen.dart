// Dosya Adı: company_general_overview_screen.dart
// Açıklama: MBT Firma Genel Görünüm dens — Liste + Grafik sekmeleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../model/company_general_overview.dart';

/// {@template company_general_overview_screen}
/// Firma Genel Analiz dens ekranı (MBT Yönetici → FİRMA GENEL ANALİZ).
/// Route: `/field-sales/company-general`
///
/// Sekmeler: Liste (MBT tablo) · Grafik (aynı veri).
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, CompanyGeneralOverviewScreen.routeName);
/// ```
/// {@endtemplate}
class CompanyGeneralOverviewScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/company-general';

  /// Opsiyonel özet (null → sample demo)
  final CompanyGeneralOverview? overview;

  /// {@macro company_general_overview_screen}
  const CompanyGeneralOverviewScreen({Key? key, this.overview})
      : super(key: key);

  @override
  State<CompanyGeneralOverviewScreen> createState() =>
      _CompanyGeneralOverviewScreenState();
}

class _CompanyGeneralOverviewScreenState
    extends State<CompanyGeneralOverviewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<String> _monthKeys = [
    'months.january',
    'months.february',
    'months.march',
    'months.april',
    'months.may',
    'months.june',
    'months.july',
    'months.august',
    'months.september',
    'months.october',
    'months.november',
    'months.december',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  CompanyGeneralOverview get _overview =>
      widget.overview ?? CompanyGeneralOverview.sample;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const Color primary = FieldSalesDensAppBar.primaryColor;
    final o = _overview;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('manager_dashboard.card_company_general'),
        backgroundColor: primary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 2,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            tabs: [
              Tab(
                height: 32,
                text: l10n.translate(
                  'field_sales.company_overview_tab_list',
                ),
              ),
              Tab(
                height: 32,
                text: l10n.translate(
                  'field_sales.company_overview_tab_chart',
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: FloatingActionButton(
              heroTag: 'company_overview_mail',
              backgroundColor: primary,
              elevation: 2,
              onPressed: () {},
              child: const Icon(Icons.alternate_email, size: 18),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 40,
            height: 40,
            child: FloatingActionButton(
              heroTag: 'company_overview_share',
              backgroundColor: primary,
              elevation: 2,
              onPressed: () {},
              child: const Icon(Icons.share, size: 18),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListTab(context, l10n, o),
          _buildChartTab(context, l10n, o),
        ],
      ),
    );
  }

  Widget _buildListTab(
    BuildContext context,
    AppLocalization l10n,
    CompanyGeneralOverview o,
  ) {
    final fmt = CompanyGeneralOverview.formatAmount;
    final pctAmt = CompanyGeneralOverview.formatProfitLine;

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 72),
      children: [
        if (o.isSample) ...[
          Text(
            l10n.translate('field_sales.company_overview_sample_badge'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
        ],
        _sectionTitle(
          l10n.translate('field_sales.stubs.company_general_overview'),
        ),
        _cardShell(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _groupTitle(
                      l10n.translate(
                        'field_sales.company_overview_ar_ap',
                      ),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_customer_debt',
                      ),
                      fmt(o.customerDebt),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_own_debt',
                      ),
                      fmt(o.ownDebt),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_general_debt',
                      ),
                      fmt(o.generalDebt),
                    ),
                    const SizedBox(height: 6),
                    _groupTitle(
                      l10n.translate(
                        'field_sales.company_overview_cash_bank',
                      ),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_cash',
                      ),
                      fmt(o.cashBalance),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_bank',
                      ),
                      fmt(o.bankBalance),
                    ),
                    const SizedBox(height: 6),
                    _groupTitle(
                      l10n.translate(
                        'field_sales.company_overview_sales_ex_vat',
                      ),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_sales',
                      ),
                      fmt(o.salesExVat),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_sales_returns',
                      ),
                      fmt(o.salesReturns),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_sales_cost',
                      ),
                      fmt(o.salesCost),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_sales_profit_pct',
                      ),
                      pctAmt(o.salesProfitPct, o.salesProfitAmount),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: Colors.grey.shade200,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _groupTitle(
                      l10n.translate(
                        'field_sales.company_overview_inventory',
                      ),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_inventory_plus_minus',
                      ),
                      fmt(o.inventoryPlusMinus),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_inventory_general',
                      ),
                      fmt(o.inventoryGeneral),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_inventory_fixed',
                      ),
                      fmt(o.inventoryFixedAssets),
                    ),
                    const SizedBox(height: 6),
                    _groupTitle(
                      l10n.translate(
                        'field_sales.company_overview_check_risk_firm_customer',
                      ),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_company_check_risk',
                      ),
                      fmt(o.companyCheckRisk),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_customer_check_risk',
                      ),
                      fmt(o.customerCheckRisk),
                    ),
                    const SizedBox(height: 6),
                    _groupTitle(
                      l10n.translate(
                        'field_sales.company_overview_purchases_amount',
                      ),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_purchases_amount',
                      ),
                      fmt(o.purchases),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_purchase_returns',
                      ),
                      fmt(o.purchaseReturns),
                    ),
                    _rowMetric(
                      l10n.translate(
                        'field_sales.company_overview_expenses',
                      ),
                      fmt(o.expenses),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _sectionTitle(
          l10n.translate('field_sales.company_overview_monthly'),
        ),
        if (o.monthlyPairs.isEmpty)
          _cardShell(
            child: Text(
              l10n.translate('field_sales.company_overview_stub_hint'),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          )
        else
          // Yatay kaydırma ay sütununa göre: yıl N + yıl N−1 alt alta,
          // sola/sağa kayınca ikisi birlikte kayar.
          SizedBox(
            height: 248,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: o.monthlyPairs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final pair = o.monthlyPairs[index];
                return _monthPairCard(l10n, pair);
              },
            ),
          ),
        const SizedBox(height: 12),
        Text(
          '${l10n.translate('field_sales.design_file')} : '
          '${o.designFileName}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _monthPairCard(
    AppLocalization l10n,
    CompanyMonthlyPair pair,
  ) {
    final monthName = l10n.translate(
      _monthKeys[(pair.current.month - 1).clamp(0, 11)],
    );
    return SizedBox(
      key: ValueKey<String>(
        'month_col_${pair.current.month}_${pair.current.year}',
      ),
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _monthCard(
            l10n,
            title: '$monthName ${pair.current.year}',
            snap: pair.current,
          ),
          const SizedBox(height: 4),
          _monthCard(
            l10n,
            title: '$monthName ${pair.previous.year}',
            snap: pair.previous,
          ),
        ],
      ),
    );
  }

  Widget _monthCard(
    AppLocalization l10n, {
    required String title,
    required CompanyMonthlySnapshot snap,
  }) {
    final fmt = CompanyGeneralOverview.formatAmount;
    final profit = CompanyGeneralOverview.formatProfitLine(
      snap.profitPct,
      snap.profitAmount,
    );
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 3),
          _miniRow(
            l10n.translate(
              'field_sales.company_overview_purchases_amount',
            ),
            fmt(snap.purchases),
          ),
          _miniRow(
            l10n.translate('field_sales.company_overview_sales'),
            fmt(snap.sales),
          ),
          _miniRow(
            l10n.translate(
              'field_sales.company_overview_month_sales_return',
            ),
            fmt(snap.salesReturns),
          ),
          _miniRow(
            l10n.translate(
              'field_sales.company_overview_sales_cost',
            ),
            fmt(snap.cost),
          ),
          _miniRow(
            l10n.translate(
              'field_sales.company_overview_sales_profit_pct',
            ),
            profit,
          ),
          _miniRow(
            l10n.translate('field_sales.company_overview_expenses'),
            fmt(snap.expenses),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab(
    BuildContext context,
    AppLocalization l10n,
    CompanyGeneralOverview o,
  ) {
    const Color primary = FieldSalesDensAppBar.primaryColor;
    const Color accent = FieldSalesDensAppBar.accentColor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 72),
      children: [
        if (o.isSample) ...[
          Text(
            l10n.translate('field_sales.company_overview_sample_badge'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
        ],
        _sectionTitle(
          l10n.translate(
            'field_sales.company_overview_chart_sales_cost',
          ),
        ),
        _chartCard(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _barMax([o.salesExVat, o.salesCost, o.purchases]),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (v, _) {
                      final labels = [
                        l10n.translate(
                          'field_sales.company_overview_sales',
                        ),
                        l10n.translate(
                          'field_sales.company_overview_sales_cost',
                        ),
                        l10n.translate(
                          'field_sales.company_overview_purchases_amount',
                        ),
                      ];
                      final i = v.toInt();
                      if (i < 0 || i >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        labels[i],
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                _barGroup(0, o.salesExVat, primary),
                _barGroup(1, o.salesCost, accent),
                _barGroup(2, o.purchases, const Color(0xFF6C757D)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _sectionTitle(
          l10n.translate('field_sales.company_overview_chart_debt'),
        ),
        _chartCard(
          height: 150,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 28,
                    sections: [
                      PieChartSectionData(
                        value: o.customerDebt.abs().clamp(1, double.infinity),
                        color: primary,
                        title: '',
                        radius: 36,
                      ),
                      PieChartSectionData(
                        value: o.ownDebt.abs().clamp(1, double.infinity),
                        color: accent,
                        title: '',
                        radius: 36,
                      ),
                      PieChartSectionData(
                        value: o.generalDebt.abs().clamp(1, double.infinity),
                        color: const Color(0xFF28A745),
                        title: '',
                        radius: 36,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legend(
                      primary,
                      l10n.translate(
                        'field_sales.company_overview_customer_debt',
                      ),
                    ),
                    _legend(
                      accent,
                      l10n.translate(
                        'field_sales.company_overview_own_debt',
                      ),
                    ),
                    _legend(
                      const Color(0xFF28A745),
                      l10n.translate(
                        'field_sales.company_overview_general_debt',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _sectionTitle(
          l10n.translate(
            'field_sales.company_overview_chart_cash_bank',
          ),
        ),
        _chartCard(
          height: 140,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 26,
                    sections: [
                      PieChartSectionData(
                        value: o.cashBalance.abs().clamp(1, double.infinity),
                        color: primary,
                        title: '',
                        radius: 34,
                      ),
                      PieChartSectionData(
                        value: o.bankBalance.abs().clamp(1, double.infinity),
                        color: accent,
                        title: '',
                        radius: 34,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legend(
                      primary,
                      l10n.translate(
                        'field_sales.company_overview_cash',
                      ),
                    ),
                    _legend(
                      accent,
                      l10n.translate(
                        'field_sales.company_overview_bank',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _sectionTitle(
          l10n.translate(
            'field_sales.company_overview_chart_monthly_profit',
          ),
        ),
        _chartCard(
          height: 180,
          child: o.monthlyPairs.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate(
                      'field_sales.company_overview_stub_hint',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
              : LineChart(
                  LineChartData(
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 18,
                          interval: 1,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= o.monthlyPairs.length) {
                              return const SizedBox.shrink();
                            }
                            if (i % 2 != 0) {
                              return const SizedBox.shrink();
                            }
                            final key = _monthKeys[
                                (o.monthlyPairs[i].current.month - 1)
                                    .clamp(0, 11)];
                            return Text(
                              l10n.translate(key).substring(0, 3),
                              style: const TextStyle(fontSize: 9),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < o.monthlyPairs.length; i++)
                            FlSpot(
                              i.toDouble(),
                              o.monthlyPairs[i].current.profitAmount,
                            ),
                        ],
                        isCurved: true,
                        color: primary,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: primary.withOpacity(0.08),
                        ),
                      ),
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < o.monthlyPairs.length; i++)
                            FlSpot(
                              i.toDouble(),
                              o.monthlyPairs[i].previous.profitAmount,
                            ),
                        ],
                        isCurved: true,
                        color: accent,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _legend(
              primary,
              '${DateTime.now().year}',
            ),
            const SizedBox(width: 12),
            _legend(
              accent,
              '${DateTime.now().year - 1}',
            ),
          ],
        ),
      ],
    );
  }

  double _barMax(List<double> values) {
    final m = values.fold<double>(0, (a, b) => a > b ? a : b);
    return m <= 0 ? 1 : m * 1.15;
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y <= 0 ? 0.01 : y,
          color: color,
          width: 18,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _chartCard({required double height, required Widget child}) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _legend(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF2C3E50)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  Widget _groupTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: Color(0xFF375A7F),
        ),
      ),
    );
  }

  Widget _rowMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: Color(0xFF2C3E50),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}
