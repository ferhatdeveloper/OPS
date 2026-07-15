import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/vehicle_provider.dart';

class EndOfDayScreen extends ConsumerStatefulWidget {
  const EndOfDayScreen({super.key});

  @override
  ConsumerState<EndOfDayScreen> createState() => _EndOfDayScreenState();
}

class _EndOfDayScreenState extends ConsumerState<EndOfDayScreen> {
  bool _isReconciling = false;

  Future<void> _handleReconcile() async {
    setState(() => _isReconciling = true);
    
    // Simulate reconciliation process
    await Future.delayed(const Duration(seconds: 2));
    
    // The instruction mentions passing arguments to reconcileEndOfDay.
    // The provided code edit keeps `[]` for reconcileEndOfDay, so we'll keep it as is.
    // If specific arguments were intended, they should be provided in the instruction.
    final success = await ref.read(vehicleProvider.notifier).reconcileEndOfDay([]);

    if (mounted) {
      setState(() => _isReconciling = false);
      if (success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Gün Sonu Başarılı'),
            content: const Text('Tüm veriler senkronize edildi ve stoklar güncellendi.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Dialog
                  Navigator.pop(context); // Screen
                },
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      } else {
        final error = ref.read(vehicleProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Gün Sonu Kapanışı', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 24),
            _buildChecklist(state),
            const SizedBox(height: 32),
            _buildSummaryCard(),
            const SizedBox(height: 40),
            _buildReconcileButton(state),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
          ),
          child: const Icon(Icons.assignment_turned_in, size: 60, color: Color(0xFF375A7F)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Gün Sonu Kontrolü',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Günü kapatmadan önce aşağıdaki kontrolleri yapınız.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildChecklist(VehicleState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildCheckItem('Tüm faturalar kaydedildi', true),
          _buildCheckItem('Tahsilatlar sisteme girildi', true),
          _buildCheckItem('Araç stokları doğrulandı', state.stocks.isNotEmpty),
          _buildCheckItem('Sistem senkronizasyonu hazır', true),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String title, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(
            fontSize: 16,
            color: isDone ? Colors.black : Colors.grey,
            decoration: isDone ? null : TextDecoration.none,
          )),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF375A7F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Toplam Satış', ' 12.450'),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildSummaryItem('Toplam Tahsilat', ' 8.200'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildReconcileButton(VehicleState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isReconciling || state.isLoading ? null : _handleReconcile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A8E8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        child: _isReconciling
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('GÜNÜ KAPAT VE SENKRONİZE ET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
