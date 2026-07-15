import 'package:flutter/material.dart';
import '../../../../core/localization/app_localization.dart';

class PeriodComparisonReportScreen extends StatefulWidget {
  const PeriodComparisonReportScreen({Key? key}) : super(key: key);

  @override
  State<PeriodComparisonReportScreen> createState() => _PeriodComparisonReportScreenState();
}

class _PeriodComparisonReportScreenState extends State<PeriodComparisonReportScreen> {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  final List<int> years = List.generate(5, (index) => DateTime.now().year - index);
  List<String> getMonths(BuildContext context) {
    return [
      AppLocalization.of(context).translate('months.january'),
      AppLocalization.of(context).translate('months.february'),
      AppLocalization.of(context).translate('months.march'),
      AppLocalization.of(context).translate('months.april'),
      AppLocalization.of(context).translate('months.may'),
      AppLocalization.of(context).translate('months.june'),
      AppLocalization.of(context).translate('months.july'),
      AppLocalization.of(context).translate('months.august'),
      AppLocalization.of(context).translate('months.september'),
      AppLocalization.of(context).translate('months.october'),
      AppLocalization.of(context).translate('months.november'),
      AppLocalization.of(context).translate('months.december')
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(AppLocalization.of(context).translate('advanced.period_comparison'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF375A7F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSelectors(context),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            _buildComparisonCard('${AppLocalization.of(context).translate('advanced.monthly_sales')} (${getMonths(context)[selectedMonth - 1]} $selectedYear)', 1250000, 1500000, context),
            const SizedBox(height: 16),
            _buildComparisonCard(AppLocalization.of(context).translate('advanced.q3_vs_q4_collections'), 3200000, 2800000, context),
            const SizedBox(height: 16),
            _buildComparisonCard('${AppLocalization.of(context).translate('advanced.annual_growth')} ($selectedYear vs ${selectedYear - 1})', 15000000, 22000000, context),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectors(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedMonth,
                  items: List.generate(12, (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text(getMonths(context)[index]),
                  )),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedMonth = val);
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedYear,
                  items: years.map((year) => DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedYear = val);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(String title, double prev, double curr, BuildContext context) {
    final diff = curr - prev;
    final perc = prev == 0 ? 100.0 : (diff / prev) * 100;
    final isPositive = diff >= 0;

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalization.of(context).translate('advanced.previous_period'), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('${prev.toStringAsFixed(0)} ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ],
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade300),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(AppLocalization.of(context).translate('advanced.current_period'), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('${curr.toStringAsFixed(0)} ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isPositive ? Colors.green : Colors.red)),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalization.of(context).translate('advanced.difference_growth'), style: const TextStyle(fontWeight: FontWeight.w500)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isPositive ? Icons.trending_up : Icons.trending_down, size: 18, color: isPositive ? Colors.green : Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        '${isPositive ? '+' : ''}${perc.toStringAsFixed(1)}%',
                        style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? Colors.green : Colors.red),
                      ),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
