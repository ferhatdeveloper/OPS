import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/widgets/signature_pad.dart';
import '../viewmodel/visit_provider.dart';

class VisitSignatureScreen extends ConsumerStatefulWidget {
  final String notes;
  const VisitSignatureScreen({super.key, required this.notes});

  @override
  ConsumerState<VisitSignatureScreen> createState() => _VisitSignatureScreenState();
}

class _VisitSignatureScreenState extends ConsumerState<VisitSignatureScreen> {
  List<Offset?> _signaturePoints = [];
  final TextEditingController _notesController = TextEditingController();
  late String _selectedOutcome;

  @override
  void initState() {
    super.initState();
    _selectedOutcome = AppLocalization.of(context).translate('field_sales.outcome_ordered');
    _notesController.text = widget.notes;
  }

  List<String> get _visitOutcomes => [
    AppLocalization.of(context).translate('field_sales.outcome_ordered'),
    AppLocalization.of(context).translate('field_sales.outcome_not_ordered'),
    AppLocalization.of(context).translate('field_sales.outcome_not_found'),
    AppLocalization.of(context).translate('field_sales.outcome_postponed'),
    AppLocalization.of(context).translate('field_sales.outcome_collected'),
    AppLocalization.of(context).translate('field_sales.outcome_discovery')
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Sleek dark aesthetic
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalization.of(context).translate('field_sales.finish_visit'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalization.of(context).translate('field_sales.visit_outcome'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedOutcome,
                        dropdownColor: const Color(0xFF2C2C2C),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() => _selectedOutcome = newValue);
                          }
                        },
                        items: _visitOutcomes.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(AppLocalization.of(context).translate('field_sales.visit_note'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      hintText: AppLocalization.of(context).translate('field_sales.visit_notes_placeholder'),
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade800),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade800),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF00A8E8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    AppLocalization.of(context).translate('field_sales.digital_signature'),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalization.of(context).translate('field_sales.digital_signature_hint'),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.white,
                      child: SignaturePadWidget(
                        onSigned: (points) {
                          _signaturePoints = points;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.grey, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalization.of(context).translate('field_sales.signature_verification_hint'),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _completeCheckOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A8E8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(AppLocalization.of(context).translate('field_sales.complete_visit_and_sign'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _completeCheckOut() async {
    if (_signaturePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalization.of(context).translate('field_sales.sign_required')), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // Convert points to JSON string for storage
    final signatureData = jsonEncode(_signaturePoints.map((p) => p == null ? null : {'x': p.dx, 'y': p.dy}).toList());
    
    // Construct final aggregated note
    final l10n = AppLocalization.of(context);
    final finalNotes = "${l10n.translate('field_sales.visit_status_label')}: $_selectedOutcome\n${l10n.translate('field_sales.visit_note_label')}: ${_notesController.text}";

    final success = await ref.read(visitProvider.notifier).checkOut(
      finalNotes,
      signatureData: signatureData,
    );

    if (success) {
      if (mounted) {
        Navigator.pop(context); // Pop signature screen
        Navigator.pop(context); // Pop form screen
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.of(context).translate('field_sales.visit_finish_error'))),
        );
      }
    }
  }
}
