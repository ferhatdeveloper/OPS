import 'package:flutter/material.dart';
import '../../../../core/localization/app_localization.dart';
import '../engine/stock_transfer_service.dart';
import '../model/stock_transfer_model.dart';
import 'package:uuid/uuid.dart';

class StockTransferScreen extends StatefulWidget {
  const StockTransferScreen({Key? key}) : super(key: key);

  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen> {
  List<StockTransferModel> _transfers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransfers();
  }

  Future<void> _fetchTransfers() async {
    setState(() => _isLoading = true);
    final results = await StockTransferService.getTransfers();
    setState(() {
      _transfers = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

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
        title: const Text('Stok Transferleri', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transfers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transfers.length,
                  itemBuilder: (context, index) {
                    final t = _transfers[index];
                    return _buildTransferCard(t);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00A8E8),
        onPressed: () => _showCreateTransferDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTransferCard(StockTransferModel t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.swap_horiz, color: Color(0xFF00A8E8)),
        ),
        title: Text(t.productName ?? 'Bilinmeyen Ürün', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${t.fromWarehouse} ➔ ${t.toWarehouse}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 2),
            Text('Miktar: ${t.quantity} ${t.unitName ?? ""}', style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(t.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(t.status, style: TextStyle(color: _getStatusColor(t.status), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            Text(t.transferDate.toString().substring(0, 10), style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed': return Colors.green;
      case 'Approved': return Colors.blue;
      case 'Pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swap_horiz, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Henüz stok transferi bulunmuyor.', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  void _showCreateTransferDialog() {
    // In a real app, this would be a full screen or complex dialog with product/warehouse pickers
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transfer detayları için ERP entegrasyonu gereklidir.")));
  }
}
