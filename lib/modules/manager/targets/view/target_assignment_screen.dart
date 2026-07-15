import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/target_model.dart';
import '../viewmodel/target_provider.dart';
import '../../../../core/localization/app_localization.dart';

class TargetAssignmentScreen extends ConsumerStatefulWidget {
  const TargetAssignmentScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TargetAssignmentScreen> createState() => _TargetAssignmentScreenState();
}

class _TargetAssignmentScreenState extends ConsumerState<TargetAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedUser = 'Ahmet Yılmaz'; // Default demo user
  String _selectedPeriod = 'Aralık';
  String _selectedType = 'Sales';
  final _amountController = TextEditingController();

  final List<String> _users = ['Ahmet Yılmaz', 'Mehmet Kaya', 'Ayşe Demir', 'Ali Can'];
  final List<String> _periods = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık', '2023-Q4', '2024-Q1'];
  final List<String> _types = ['Sales', 'Collection', 'Visit'];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _saveTarget() {
    if (_formKey.currentState!.validate()) {
      final target = TargetModel(
        id: const Uuid().v4(),
        userId: _selectedUser,
        targetAmount: double.parse(_amountController.text),
        period: _selectedPeriod,
        type: _selectedType,
        createdAt: DateTime.now().toIso8601String(),
      );

      ref.read(targetProvider.notifier).addTarget(target).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.of(context).translate('target.target_success'))),
        );
        _amountController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetState = ref.watch(targetProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(AppLocalization.of(context).translate('target.target_assignment'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF375A7F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppLocalization.of(context).translate('target.new_target'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedUser,
                        decoration: InputDecoration(
                          labelText: AppLocalization.of(context).translate('target.personnel'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _users.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (val) => setState(() => _selectedUser = val!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedType,
                              decoration: InputDecoration(
                                labelText: AppLocalization.of(context).translate('target.target_type'),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (val) => setState(() => _selectedType = val!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPeriod,
                              decoration: InputDecoration(
                                labelText: AppLocalization.of(context).translate('target.period'),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                              onChanged: (val) => setState(() => _selectedPeriod = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: AppLocalization.of(context).translate('target.target_amount'),
                          prefixIcon: const Icon(Icons.monetization_on, color: Color(0xFF375A7F)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return AppLocalization.of(context).translate('target.enter_amount_error');
                          if (double.tryParse(value) == null) return AppLocalization.of(context).translate('target.invalid_amount_error');
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A8E8),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: targetState.isLoading ? null : _saveTarget,
                        icon: targetState.isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save, color: Colors.white),
                        label: Text(AppLocalization.of(context).translate('target.assign_target'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                 const Icon(Icons.history, color: Colors.grey),
                 const SizedBox(width: 8),
                 Text(AppLocalization.of(context).translate('target.recent_targets'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            if (targetState.isLoading && targetState.targets.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (targetState.targets.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(AppLocalization.of(context).translate('target.no_target_found'))))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: targetState.targets.length,
                itemBuilder: (context, index) {
                  final t = targetState.targets[index];
                  return Card(
                     margin: const EdgeInsets.only(bottom: 12),
                     elevation: 2,
                     shadowColor: Colors.black12,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     child: ListTile(
                       contentPadding: const EdgeInsets.all(12),
                       leading: CircleAvatar(
                         radius: 24,
                         backgroundColor: const Color(0xFF375A7F).withOpacity(0.1),
                         child: const Icon(Icons.person, color: Color(0xFF375A7F)),
                       ),
                       title: Text(t.userId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                       subtitle: Text('${t.type} | ${t.period}', style: TextStyle(color: Colors.grey.shade600)),
                       trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                             Text('${t.targetAmount.toStringAsFixed(0)} ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00A8E8))),
                             const Text('Hedef', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ]
                       ),
                     ),
                  );
                }
              )
          ],
        ),
      ),
    );
  }
}
