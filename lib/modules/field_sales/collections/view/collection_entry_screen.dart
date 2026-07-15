import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/collection_provider.dart';

class CollectionEntryScreen extends ConsumerStatefulWidget {
  final String customerId;
  const CollectionEntryScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  ConsumerState<CollectionEntryScreen> createState() => _CollectionEntryScreenState();
}

class _CollectionEntryScreenState extends ConsumerState<CollectionEntryScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _bankController = TextEditingController();
  final _branchController = TextEditingController();
  final _checkNoController = TextEditingController();
  DateTime? _dueDate;
  String _selectedPaymentType = 'Cash';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(collectionProvider);

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
        title: const Text('Tahsilat Girişi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAmountCard(),
            const SizedBox(height: 16),
            _buildPaymentTypeCard(),
            const SizedBox(height: 16),
            _buildNotesCard(),
            if (_selectedPaymentType == 'Check') ...[
              const SizedBox(height: 16),
              _buildCheckDetailsCard(),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A8E8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                ),
                onPressed: state.isLoading ? null : _handleSave,
                child: state.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Tahsilatı Onayla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF375A7F).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Tahsil Edilecek Tutar', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0.00',
              suffixText: '',
              suffixStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00A8E8)),
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF375A7F).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ödeme Türü', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
          const SizedBox(height: 16),
          _buildPaymentTypeSelector(),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSelector() {
    final types = [
      {'val': 'Cash', 'label': 'Nakit', 'icon': Icons.money},
      {'val': 'CreditCard', 'label': 'Kredi', 'icon': Icons.credit_card},
      {'val': 'Check', 'label': 'Çek', 'icon': Icons.description},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: types.map((t) {
        final isSelected = _selectedPaymentType == t['val'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () => setState(() => _selectedPaymentType = t['val'] as String),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00A8E8) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? const Color(0xFF00A8E8) : Colors.transparent),
                  boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF00A8E8).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                ),
                child: Column(
                  children: [
                    Icon(t['icon'] as IconData, color: isSelected ? Colors.white : Colors.grey.shade500, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      t['label'] as String,
                      style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF375A7F).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notlar (Opsiyonel)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8F9FD),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              hintText: 'Ödeme detaylarını buraya yazabilirsiniz...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCheckDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF375A7F).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Çek Detayları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
          const SizedBox(height: 16),
          _buildTextField(_bankController, 'Banka Adı', Icons.account_balance),
          const SizedBox(height: 12),
          _buildTextField(_branchController, 'Şube Adı', Icons.location_on),
          const SizedBox(height: 12),
          _buildTextField(_checkNoController, 'Çek Numarası', Icons.confirmation_number),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectDueDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: Color(0xFF00A8E8)),
                  const SizedBox(width: 12),
                  Text(
                    _dueDate == null ? 'Vade Tarihi Seçin' : 'Vade: ${_dueDate!.day}.${_dueDate!.month}.${_dueDate!.year}',
                    style: TextStyle(color: _dueDate == null ? Colors.grey.shade600 : Colors.black, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF375A7F)),
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8F9FD),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _handleSave() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen geçerli bir tutar girin.')));
      return;
    }

    final success = await ref.read(collectionProvider.notifier).saveCollection(
      customerId: widget.customerId,
      amount: amount,
      paymentType: _selectedPaymentType,
      notes: _notesController.text,
      bankName: _selectedPaymentType == 'Check' ? _bankController.text : null,
      branchName: _selectedPaymentType == 'Check' ? _branchController.text : null,
      checkNumber: _selectedPaymentType == 'Check' ? _checkNoController.text : null,
      dueDate: _selectedPaymentType == 'Check' ? _dueDate : null,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tahsilat başarıyla kaydedildi.')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: \${ref.read(collectionProvider).error}')));
    }
  }
}
