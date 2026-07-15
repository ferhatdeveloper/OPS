import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/localization/app_localization.dart';
import '../viewmodel/report_provider.dart';

class LogoReportsScreen extends ConsumerStatefulWidget {
  const LogoReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LogoReportsScreen> createState() => _LogoReportsScreenState();
}

class _LogoReportsScreenState extends ConsumerState<LogoReportsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dailySalesReportProvider.notifier).fetchDailySales());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailySalesReportProvider);
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(l10n.translate('field_sales.reports')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dailySalesReportProvider.notifier).fetchDailySales(),
          ),
        ],
      ),
      body: state.when(
        data: (data) => _buildReportContent(data.toMap()),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
      ),
    );
  }

  Widget _buildReportContent(Map<String, dynamic>? data) {
    if (data == null) return const Center(child: Text('No data available'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          'Günlük Ciro',
          '${data['total_turnover'] ?? 0} ',
          'Geçen Yıl: ${data['last_year_turnover'] ?? 0} ',
          data['growth_rate'] ?? '0%',
        ),
        const SizedBox(height: 24),
        _buildChartSection('Satış Trendi'),
        const SizedBox(height: 24),
        _buildComparisonList(data['stores'] as List? ?? []),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subValue, String growth) {
    bool isPositive = growth.contains('+') || !growth.contains('-');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  growth,
                  style: TextStyle(
                    color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(subValue, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildChartSection(String title) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3),
                      const FlSpot(1, 1),
                      const FlSpot(2, 4),
                      const FlSpot(3, 2),
                      const FlSpot(4, 5),
                    ],
                    isCurved: true,
                    color: const Color(0xFF375A7F),
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF375A7F).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonList(List stores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mağaza Bazlı Karşılaştırma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...stores.map((store) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(store['name'] ?? 'Mağaza'),
                trailing: Text('${store['sales'] ?? 0} ', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )),
      ],
    );
  }
}
