import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class PendingTransfersScreen extends StatefulWidget {
  final int initialTabIndex;
  const PendingTransfersScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<PendingTransfersScreen> createState() => _PendingTransfersScreenState();
}

class _PendingTransfersScreenState extends State<PendingTransfersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'K1';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
        title: const Text('Bekleyen Transferler', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Tümünü Senkronize Et',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tüm bekleyen kayıtlar gönderiliyor...')));
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96.0),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: isDarkMode ? Colors.white : Colors.black,
                indicatorWeight: 3,
                isScrollable: true,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                tabs: const [
                  Tab(text: 'Faturalar'),
                  Tab(text: 'Tahsilatlar'),
                  Tab(text: 'Siparişler'),
                  Tab(text: 'Ambar / İrsaliye'),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: CupertinoSegmentedControl<String>(
                  children: const {
                    'K1': Text('K1'),
                    'K2': Text('K2'),
                    'K3': Text('K3'),
                  },
                  groupValue: _selectedPeriod,
                  onValueChanged: (value) {
                    setState(() => _selectedPeriod = value);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDummyList('Fatura', Icons.receipt, Colors.blue, _selectedPeriod),
          _buildDummyList('Tahsilat', Icons.monetization_on, Colors.green, _selectedPeriod),
          _buildDummyList('Sipariş', Icons.shopping_cart, Colors.orange, _selectedPeriod),
          _buildDummyList('Fiş', Icons.description, Colors.purple, _selectedPeriod),
        ],
      ),
    );
  }

  Widget _buildDummyList(String type, IconData icon, Color color, String period) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          shadowColor: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            title: Text('$type - $period - No: #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Tutar: \${(index + 1) * 1500} ₺\\nDurum: Bekliyor (Offline)'),
            trailing: IconButton(
              icon: const Icon(Icons.sync_problem, color: Colors.orange),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sadece bu \$type gönderiliyor...')));
              },
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
