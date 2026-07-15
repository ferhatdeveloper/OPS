import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodel/report_provider.dart';
import '../../../../service/nfc_service.dart';
import '../../../../service/notification_service.dart';
import '../../../../service/offline_maps_service.dart';
import '../../invoices/view/invoice_entry_screen.dart';
import '../../other/view/stock_ops_screen.dart';
import 'performance_dashboard_screen.dart';
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _startNfcScan();
  }

  @override
  void dispose() {
    NfcService().stopScanning();
    super.dispose();
  }

  void _startNfcScan() {
    NfcService().startScanning(
      onCustomerFound: (customerId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Müşteri NFC kartı tanımlandı. Geçiş yapılıyor...'))
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceEntryScreen(customerId: customerId),
            ),
          );
        }
      },
      onError: (error) {
        debugPrint('NFC Scan Error: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(dailySalesReportProvider);

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
        title: const Text('Gün Sonu Raporu', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const StockOpsScreen())),
            icon: const Icon(Icons.inventory),
            tooltip: 'Sarfiyat/Numune',
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const PerformanceDashboardScreen())),
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Detaylı Analiz',
          ),
          IconButton(
            onPressed: () => ref.read(dailySalesReportProvider.notifier).fetchDailySales(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: reportState.when(
        data: (data) => _buildContent(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReportData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Özet Performans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50))),
          const SizedBox(height: 16),
          _buildTargetProgressCard(data),
          const SizedBox(height: 16),
          _buildSummaryCards(data),
          if (data.nearestCustomer != null) ...[
             const SizedBox(height: 24),
             const Text('Önerilen Sonraki Durak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50))),
             const SizedBox(height: 16),
             _buildNearestCustomerCard(context, data.nearestCustomer!),
          ],
          const SizedBox(height: 24),
          const Text('Satış Trendi (Son 7 Gün)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50))),
          const SizedBox(height: 16),
          _buildChartCard(data),
          const SizedBox(height: 24),
          const Text('Araç Stok Durumu (Van Sales)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50))),
          const SizedBox(height: 16),
          _buildVanStockCard(data),
          const SizedBox(height: 24),
          _buildMerkezSimulatorCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ReportData data) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryItem(
            'Toplam Satış',
            '${data.totalSales.toStringAsFixed(0)} ',
            Icons.shopping_bag,
            const Color(0xFF375A7F),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryItem(
            'Tahsilatlar',
            '${data.totalCollections.toStringAsFixed(0)} ',
            Icons.payments,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildChartCard(ReportData data) {
    if (data.dailySales.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.dailySales.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList(),
              isCurved: true,
              color: const Color(0xFF00A8E8),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF00A8E8).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetProgressCard(ReportData data) {
    final progress = (data.targetReached / data.dailyTarget).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Günlük Satış Hedefi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Text('%$percentage', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A8E8))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00A8E8)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${data.targetReached.toStringAsFixed(0)} ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Hedef: ${data.dailyTarget.toStringAsFixed(0)} ', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNearestCustomerCard(BuildContext context, Map<String, dynamic> customer) {
    final distance = (customer['distance'] as double? ?? 0) / 1000; // to km
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF375A7F), Color(0xFF2C3E50)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.near_me, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${distance.toStringAsFixed(1)} KM uzaklıkta', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _launchNavigation(customer['latitude'], customer['longitude']),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A8E8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Git'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchNavigation(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final url = 'google.navigation:q=$lat,$lng';
    
    // Note: In real app, use url_launcher
    debugPrint('Launching Navigation: $url');
  }

  Widget _buildVanStockCard(ReportData data) {
    if (data.vehicleStocks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: const Center(child: Text('Araçta stok bulunamadı.')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.vehicleStocks.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final item = data.vehicleStocks[index];
          final qty = (item['quantity'] as num).toDouble();
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF8F9FD), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.inventory_2, color: Color(0xFF375A7F), size: 20),
            ),
            title: Text(item['product_name'] ?? item['product_id'], style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: Text(
              '$qty Adet',
              style: TextStyle(fontWeight: FontWeight.bold, color: qty < 10 ? Colors.red : Colors.green),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMerkezSimulatorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.hub_outlined, color: Colors.orange.shade800),
              const SizedBox(width: 12),
              const Text('Merkez İletişim (Simülasyon)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Yönetici komutlarını simüle ederek veri çekme ve kilitleme işlemlerini test edin.', style: TextStyle(fontSize: 12, color: Colors.orange)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => NotificationService().simulatePushNotification(
                    'VERI_CEKME', 
                    'Merkez cihazınızdaki tüm satış verilerini şimdi senkronize ediyor.'
                  ),
                  icon: const Icon(Icons.cloud_download, size: 18),
                  label: const Text('Veri Çek', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => NotificationService().simulatePushNotification(
                    'CIHAZ_KILITLE', 
                    'Bu cihaz geçici olarak kurumsal güvenli moduna alındı.'
                  ),
                  icon: const Icon(Icons.lock_person, size: 18),
                  label: const Text('Kilitle', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => OfflineMapsService().downloadRegion('İstanbul Avrupa Yakası'),
              icon: const Icon(Icons.download_for_offline_rounded),
              label: const Text('Çevrimdışı Harita İndir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
