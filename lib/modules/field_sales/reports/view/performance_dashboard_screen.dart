import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/kpi_provider.dart';
import '../../../../service/ai_analytics_service.dart';

class PerformanceDashboardScreen extends ConsumerWidget {
  const PerformanceDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kpiProvider);
    final aiService = AIAnalyticsService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Performans Analitiği', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
      ),
      body: state.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () => ref.read(kpiProvider.notifier).refreshKPIs(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAISummaryStream(aiService),
                const SizedBox(height: 20),
                if (state.kpi != null) ...[
                  _buildKPIGrid(state.kpi!),
                  const SizedBox(height: 24),
                  _buildAchievementCard('Satış Hedefi', state.kpi!.salesAchievement, '${state.kpi!.currentSales.toInt()} / ${state.kpi!.salesTarget.toInt()} ₺', Colors.blue),
                  const SizedBox(height: 16),
                  _buildAchievementCard('Ziyaret Başarısı', state.kpi!.visitSuccessRate, '${state.kpi!.completedVisits} / ${state.kpi!.plannedVisits}', Colors.orange),
                  const SizedBox(height: 24),
                  _buildSalesHeatmap(),
                ],
              ],
            ),
          ),
    );
  }

  Widget _buildAISummaryStream(AIAnalyticsService aiService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.purple, Colors.purpleAccent]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('AI Canlı İçgörüler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<String>(
            stream: aiService.streamAIInsights('performance_context'),
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? 'Analiz yapılıyor...',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKPIGrid(dynamic kpi) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildKPICard('Toplam Sipariş', '${kpi.totalOrders}', Icons.shopping_bag, Colors.indigo),
        _buildKPICard('Ort. Sipariş', '${kpi.averageOrderValue.toInt()} ₺', Icons.analytics, Colors.teal),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(String title, double percentage, String detail, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('%${percentage.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: percentage / 100, backgroundColor: color.withOpacity(0.1), color: color, minHeight: 8),
          const SizedBox(height: 8),
          Text(detail, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSalesHeatmap() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.map_outlined, color: Colors.blue),
              SizedBox(width: 8),
              Text('Satış Yoğunluğu (Isı Haritası)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: NetworkImage('https://maps.googleapis.com/maps/api/staticmap?center=41.0082,28.9784&zoom=11&size=600x300&key=MOCK_KEY'), // Placeholder
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
            child: Center(
              child: Stack(
                children: [
                  _buildHeatPoint(40, 60, Colors.red, 40),
                  _buildHeatPoint(100, 150, Colors.orange, 30),
                  _buildHeatPoint(20, 100, Colors.redAccent, 50),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Kademeli yoğunluk: Kırmızı (Yüksek), Turuncu (Orta)', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHeatPoint(double top, double left, Color color, double size) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withOpacity(0.6), color.withOpacity(0)]),
        ),
      ),
    );
  }
}
