import 'package:flutter/material.dart';

class CurrencyRatesScreen extends StatelessWidget {
  const CurrencyRatesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Döviz Kurları', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF375A7F),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Son Güncelleme: Bugun 17:15',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickRate('USD', '31.24', '+0.12%', Colors.greenAccent),
                    _buildQuickRate('EUR', '33.85', '-0.05%', Colors.redAccent),
                    _buildQuickRate('GBP', '39.42', '+0.08%', Colors.greenAccent),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCurrencyCard('Amerikan Doları', 'USD', '31.2450', '31.2580', Icons.attach_money, Colors.blue),
                _buildCurrencyCard('Euro', 'EUR', '33.8420', '33.8590', Icons.euro, Colors.orange),
                _buildCurrencyCard('İngiliz Sterlini', 'GBP', '39.4120', '39.4350', Icons.currency_pound, Colors.green),
                _buildCurrencyCard('İsviçre Frangı', 'CHF', '35.1240', '35.1520', Icons.currency_franc, Colors.purple),
                _buildCurrencyCard('Kuveyt Dinarı', 'KWD', '101.4250', '101.5580', Icons.monetization_on, Colors.teal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRate(String label, String value, String change, Color changeColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(change, style: TextStyle(color: changeColor, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCurrencyCard(String name, String code, String bid, String ask, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(code, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Alış: $bid', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text('Satış: $ask', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF375A7F))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
