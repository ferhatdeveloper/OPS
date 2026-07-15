import 'package:flutter/material.dart';

class CompanyListScreen extends StatelessWidget {
  const CompanyListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Mobil Şirket Listesi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCompanyCard(
            context,
            'EXFIN TEKNOLOJİ A.Ş.',
            'Merkez Şube',
            '001',
            true,
            Colors.blue,
          ),
          _buildCompanyCard(
            context,
            'EXFIN TEKNOLOJİ A.Ş.',
            'İstanbul Bölge',
            '002',
            false,
            Colors.orange,
          ),
          _buildCompanyCard(
            context,
            'EXFIN TEKNOLOJİ A.Ş.',
            'Ankara Bölge',
            '003',
            false,
            Colors.green,
          ),
          _buildCompanyCard(
            context,
            'LOJİSTİK DIŞ TİCARET',
            'Ana Depo',
            '010',
            false,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(
    BuildContext context,
    String name,
    String branch,
    String code,
    bool isSelected,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isSelected ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      elevation: isSelected ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.business, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    branch,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Şirket Kodu: $code',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.green, size: 24)
            else
              const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 24),
          ],
        ),
      ),
    );
  }
}
