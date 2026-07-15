import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';
import 'visit_signature_screen.dart';
import '../../other/engine/extra_ops_service.dart';
import '../../other/model/extra_ops_model.dart';

class VisitFormScreen extends ConsumerStatefulWidget {
  final String customerId;
  const VisitFormScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  ConsumerState<VisitFormScreen> createState() => _VisitFormScreenState();
}

class _VisitFormScreenState extends ConsumerState<VisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _nextVisitController = TextEditingController();
  late String _selectedTopic;
  List<VisitTaskModel> _tasks = [];
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _selectedTopic = AppLocalization.of(context).translate('field_sales.routine_visit');
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    await ExtraOpsService().seedMockTasks(widget.customerId);
    final tasks = await ExtraOpsService().getTasksByCustomer(widget.customerId);
    setState(() => _tasks = tasks);
  }
  List<String> get _topics => [
    AppLocalization.of(context).translate('field_sales.routine_visit'),
    AppLocalization.of(context).translate('field_sales.collection_meeting'),
    AppLocalization.of(context).translate('field_sales.campaign_intro'),
    AppLocalization.of(context).translate('field_sales.complaint_management')
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _nextVisitController.dispose();
    super.dispose();
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
        title: Text(
          l10n.translate('field_sales.visit_record'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _saveForm(context, l10n),
            child: Text(l10n.translate('common.save'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionCard(
                title: l10n.translate('field_sales.visit_topic'),
                icon: Icons.topic,
                child: DropdownButtonFormField<String>(
                  value: _topics.contains(_selectedTopic) ? _selectedTopic : _topics.first,
                  decoration: _inputDecoration(l10n.translate('field_sales.select_topic')),
                  items: _topics.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTopic = val);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: l10n.translate('field_sales.visit_notes'),
                icon: Icons.notes,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _notesController,
                      maxLines: 5,
                      decoration: _inputDecoration(l10n.translate('field_sales.visit_notes_hint')),
                      validator: (value) => value == null || value.isEmpty ? l10n.translate('field_sales.note_required') : null,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _isListening = !_isListening);
                        if (_isListening) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dinleniyor... (Simülasyon)')));
                          Future.delayed(const Duration(seconds: 3), () {
                            if (mounted) {
                              setState(() {
                                _isListening = false;
                                _notesController.text += " Müşteri yeni kampanyadan memnun kaldı.";
                              });
                            }
                          });
                        }
                      },
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : Colors.blue),
                      label: Text(_isListening ? 'Durdur' : 'Sesli Not Ekle'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_tasks.isNotEmpty) ...[
                _buildSectionCard(
                  title: 'Ziyaret Görevleri',
                  icon: Icons.checklist,
                  child: Column(
                    children: _tasks.map((t) => CheckboxListTile(
                      title: Text(t.title),
                      subtitle: Text(t.description ?? ''),
                      value: t.isCompleted,
                      onChanged: (val) async {
                        if (val == true) {
                          await ExtraOpsService().completeTask(t.id);
                          _loadTasks();
                        }
                      },
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              _buildSectionCard(
                title: l10n.translate('field_sales.next_visit_optional'),
                icon: Icons.calendar_today,
                child: TextFormField(
                  controller: _nextVisitController,
                  readOnly: true,
                  decoration: _inputDecoration(l10n.translate('field_sales.select_date')).copyWith(
                    suffixIcon: const Icon(Icons.date_range, color: Color(0xFF00A8E8)),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _nextVisitController.text = "\${date.day}.\${date.month}.\${date.year}";
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _saveForm(context, l10n),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF00A8E8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Text(l10n.translate('field_sales.complete_form'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF375A7F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF375A7F), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8F9FD),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  void _saveForm(BuildContext context, AppLocalization l10n) {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VisitSignatureScreen(notes: _notesController.text),
        ),
      );
    }
  }
}
