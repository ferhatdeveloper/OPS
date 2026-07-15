import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/target_provider.dart';
import '../../../../core/localization/app_localization.dart';

class TargetRankingScreen extends ConsumerWidget {
  const TargetRankingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetState = ref.watch(targetProvider);

    // Sort targets by achievement percentage descending
    final list = [...targetState.targets];
    list.sort((a, b) {
      final aPerc = a.targetAmount > 0 ? (a.achievedAmount / a.targetAmount) : 0;
      final bPerc = b.targetAmount > 0 ? (b.achievedAmount / b.targetAmount) : 0;
      return bPerc.compareTo(aPerc);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(AppLocalization.of(context).translate('target.target_ranking'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF375A7F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: targetState.isLoading && list.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? Center(child: Text(AppLocalization.of(context).translate('target.no_target_to_display')))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final t = list[index];
                    final percentage = t.targetAmount > 0 ? (t.achievedAmount / t.targetAmount) * 100 : 0.0;
                    
                    // Top 3 gets special colors
                    Color rankColor = Colors.grey.shade400;
                    if (index == 0) rankColor = Colors.amber;
                    if (index == 1) rankColor = Colors.blueGrey.shade300;
                    if (index == 2) rankColor = Colors.brown.shade300;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: index < 3 ? 4 : 1,
                      shadowColor: index < 3 ? rankColor.withOpacity(0.4) : Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index < 3 ? rankColor.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                                border: index < 3 ? Border.all(color: rankColor, width: 2) : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: index < 3 ? rankColor.withOpacity(0.9) : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.userId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
                                  const SizedBox(height: 4),
                                  Text('${t.type} | ${t.period}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: percentage / 100,
                                      minHeight: 10,
                                      backgroundColor: Colors.grey.shade200,
                                      color: percentage >= 100 ? Colors.green : (percentage > 50 ? const Color(0xFF00A8E8) : Colors.orange),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${t.achievedAmount.toStringAsFixed(0)} / ${t.targetAmount.toStringAsFixed(0)} ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF2C3E50))),
                                      Text('%${percentage.toStringAsFixed(1)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: percentage >= 100 ? Colors.green : const Color(0xFF00A8E8))),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
