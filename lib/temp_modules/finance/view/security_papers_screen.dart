import 'package:flutter/material.dart';

class SecurityPapersScreen extends StatelessWidget {
  const SecurityPapersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        appBar: AppBar(
          title: const Text('Çek ve Senetler', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: const Color(0xFF375A7F),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Portföy (Müşteri)'),
              Tab(text: 'Kendi Çeklerimiz'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildPapersList(context, true),
            _buildPapersList(context, false),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color(0xFF375A7F),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPapersList(BuildContext context, bool isCustomer) {
    final papers = isCustomer 
      ? [
          {'title': 'Ahmet Yılmaz', 'type': 'Çek', 'amount': '₺25.400', 'status': 'Portföyde', 'date': '15.03.2024'},
          {'title': 'Mehmet Kaya', 'type': 'Senet', 'amount': '₺12.000', 'status': 'Tahsil Edildi', 'date': '20.03.2024'},
          {'title': 'Ayşe Demir', 'type': 'Çek', 'amount': '₺45.000', 'status': 'Karşılıksız', 'date': '05.03.2024'},
        ]
      : [
          {'title': 'Global Tedarik Ltd.', 'type': 'Çek', 'amount': '₺120.000', 'status': 'Ödendi', 'date': '10.03.2024'},
          {'title': 'İstanbul Enerji', 'type': 'Çek', 'amount': '₺35.000', 'status': 'Vadeli', 'date': '25.03.2024'},
        ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: papers.length,
      itemBuilder: (context, index) {
        final paper = papers[index];
        final bool isWarning = paper['status'] == 'Karşılıksız';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: _buildIcon(paper['type']!),
            title: Text(paper['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Vade: ${paper['date']}', style: const TextStyle(fontSize: 12)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(paper['amount']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                _buildStatusBadge(paper['status']!, isWarning),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(Icons.info_outline, 'Detay'),
                    _buildActionButton(Icons.history, 'Geçmiş'),
                    _buildActionButton(Icons.edit, 'Düzelt'),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildIcon(String type) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: type == 'Çek' ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        type == 'Çek' ? Icons.description : Icons.sticky_note_2,
        color: type == 'Çek' ? Colors.blue : Colors.orange,
        size: 20,
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isWarning) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isWarning ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isWarning ? Colors.red : Colors.green,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF375A7F), size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
