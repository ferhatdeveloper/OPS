import 'package:flutter/material.dart';

class InvoiceListScreen extends StatefulWidget {
  final String customerId;
  const InvoiceListScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final List<Map<String, dynamic>> _invoices = [
    {'id': 'INV-2023-001', 'date': '12 Eki 2023', 'amount': 12500.50, 'status': 'Ödendi'},
    {'id': 'INV-2023-002', 'date': '15 Eki 2023', 'amount': 8400.00, 'status': 'Bekliyor'},
    {'id': 'INV-2023-003', 'date': '18 Eki 2023', 'amount': 4200.75, 'status': 'Kısmi Ödeme'},
  ];

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Faturalar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/field-sales/invoices/new', arguments: widget.customerId),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _invoices.length,
        itemBuilder: (context, index) {
          final invoice = _invoices[index];
          final status = invoice['status'] as String;
          Color statusColor;
          
          if (status == 'Ödendi') statusColor = Colors.green;
          else if (status == 'Bekliyor') statusColor = Colors.orange;
          else statusColor = Colors.blue;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8F9FD), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.receipt_long, color: Color(0xFF375A7F)),
              ),
              title: Text(invoice['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(invoice['date'], style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${invoice["amount"]} ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              onTap: () {},
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/field-sales/invoices/new', arguments: widget.customerId),
        backgroundColor: const Color(0xFF00A8E8),
        icon: const Icon(Icons.receipt, color: Colors.white),
        label: const Text('Yeni Fatura', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
