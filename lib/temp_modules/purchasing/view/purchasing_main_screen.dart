import 'package:flutter/material.dart';

class PurchasingMainScreen extends StatelessWidget {
  const PurchasingMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Satınalma Yönetimi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickStats(context),
            const SizedBox(height: 24),
            const Text(
              'İşlemler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActionGrid(context),
            const SizedBox(height: 24),
            const Text(
              'Son Satınalma Hareketleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Açık Siparişler',
            '12',
            Icons.shopping_basket,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Bekleyen Kabuller',
            '5',
            Icons.local_shipping,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(context, 'Yeni Sipariş', Icons.add_shopping_cart, Colors.green),
        _buildActionCard(context, 'Alış Faturası', Icons.receipt, Colors.teal),
        _buildActionCard(context, 'Tedarikçiler', Icons.business, Colors.indigo),
        _buildActionCard(context, 'Talep Yönetimi', Icons.request_quote, Colors.purple),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final activities = [
      {'title': 'ABC Lojistik', 'amount': '₺45.000', 'date': 'Bugün', 'status': 'Onaylandı'},
      {'title': 'Tekno Market', 'amount': '₺12.500', 'date': 'Dün', 'status': 'Bekliyor'},
      {'title': 'Global Gıda', 'amount': '₺8.900', 'date': '21.02', 'status': 'Onaylandı'},
    ];

    return Column(
      children: activities.map((activity) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF375A7F),
              child: Icon(Icons.business, color: Colors.white, size: 20),
            ),
            title: Text(activity['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(activity['date']!),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(activity['amount']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Text(activity['status']!, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
