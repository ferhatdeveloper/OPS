import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/vehicle_provider.dart';

class VehicleStockSummaryScreen extends ConsumerWidget {
  const VehicleStockSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehicleProvider);
    final selectedVehicle = state.selectedVehicle;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Araç Stok Özeti', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildInfoCard(selectedVehicle),
          Expanded(
            child: state.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _buildStockList(state),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (selectedVehicle != null) {
            ref.read(vehicleProvider.notifier).loadVehicleStocks(selectedVehicle.id);
          }
        },
        backgroundColor: const Color(0xFF00A8E8),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildInfoCard(selectedVehicle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF375A7F), Color(0xFF4B79A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktif Araç',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            selectedVehicle?.plate ?? 'Araç Seçilmedi',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (selectedVehicle?.name != null) ...[
            const SizedBox(height: 4),
            Text(
              selectedVehicle!.name!,
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStockList(VehicleState state) {
    if (state.stocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Stokta ürün bulunamadı.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.stocks.length,
      itemBuilder: (context, index) {
        final stock = state.stocks[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF375A7F)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.productId, // Product name will be fetched in a real app
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ürün Kodu: ${stock.productId}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      stock.quantity.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A8E8),
                      ),
                    ),
                    const Text(
                      'Adet',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
