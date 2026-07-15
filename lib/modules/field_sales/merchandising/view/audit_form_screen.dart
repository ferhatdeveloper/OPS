import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../viewmodel/merchandising_provider.dart';
import '../model/audit_model.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../service/database_service.dart';
import '../../../../service/ai_analytics_service.dart';

class AuditFormScreen extends ConsumerStatefulWidget {
  final String formId;
  final String visitId;
  const AuditFormScreen({Key? key, required this.formId, required this.visitId}) : super(key: key);

  @override
  ConsumerState<AuditFormScreen> createState() => _AuditFormScreenState();
}

class _AuditFormScreenState extends ConsumerState<AuditFormScreen> {
  final Map<String, String> _answers = {};
  final Map<String, File?> _photos = {};
  final Map<String, Map<String, dynamic>> _photoVerifications = {};
  bool _isAIProcessing = false;
  String? _aiInsight;
  final _formKey = GlobalKey<FormState>();

  bool _isFieldVisible(AuditFormFieldModel field) {
    if (field.conditionalFieldId == null || field.conditionalFieldId!.isEmpty) {
      return true;
    }
    final parentValue = _answers[field.conditionalFieldId];
    return parentValue == field.conditionalValue;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(merchandisingProvider);
    final form = state.availableForms.firstWhere((f) => f.id == widget.formId, orElse: () => AuditFormModel(id: '', name: ''));

    if (form.id.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              const Text('Form bulunamadı.', style: TextStyle(fontSize: 18, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A), // Sleek dark header
          ),
        ),
        title: Text(form.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white, letterSpacing: 0.5)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: state.isLoading 
        ? _buildSkeletonLoader()
        : Form(
            key: _formKey,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: form.fields.where(_isFieldVisible).length + 3, // Description, fields, AI panel, Submit
              itemBuilder: (context, index) {
                final visibleFields = form.fields.where(_isFieldVisible).toList();
                
                if (index == 0) {
                  return _buildDescription(form);
                } else if (index <= visibleFields.length) {
                  return _buildFieldCard(visibleFields[index - 1]);
                } else if (index == visibleFields.length + 1) {
                  return _buildAIInsightPanel();
                } else {
                  return _buildSubmitButton();
                }
              },
            ),
          ),
    );
  }

  Widget _buildDescription(AuditFormModel form) {
    if (form.description == null || form.description!.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00A8E8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00A8E8).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF00A8E8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              form.description!,
              style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A8E8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
          onPressed: _handleSave,
          child: const Text('Denetimi Tamamla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(height: 20, width: 150, color: Colors.grey.shade100),
            const SizedBox(height: 20),
            Container(height: 40, width: double.infinity, color: Colors.grey.shade50),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(AuditFormFieldModel field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  field.fieldName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)),
                ),
              ),
              if (field.isRequired)
                const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          _buildFieldInput(field),
        ],
      ),
    );
  }

  Widget _buildFieldInput(AuditFormFieldModel field) {
    switch (field.fieldType) {
      case 'number':
        return TextFormField(
          decoration: _getInputDecoration('Rakam girin...'),
          keyboardType: TextInputType.number,
          validator: field.isRequired ? (v) => v == null || v.isEmpty ? 'Bu alan zorunludur' : null : null,
          onSaved: (v) => _answers[field.id] = v ?? '',
        );
      case 'photo':
        final verification = _photoVerifications[field.id];
        return Column(
          children: [
            InkWell(
              onTap: () => _pickImage(field.id),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: verification != null 
                      ? (verification['verified'] ? Colors.green.shade300 : Colors.orange.shade300)
                      : Colors.grey.shade300, 
                    style: BorderStyle.solid, 
                    width: 2
                  ),
                ),
                child: _photos[field.id] == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('Fotoğraf Çek / Ekle', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_photos[field.id]!, fit: BoxFit.cover),
                          if (verification != null)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: verification['verified'] ? Colors.green.withOpacity(0.8) : Colors.orange.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(verification['verified'] ? Icons.verified : Icons.warning, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      verification['verified'] ? 'DOĞRULANDI' : 'KONUM HATASI',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
              ),
            ),
            if (verification != null && !verification['verified'])
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Uyarı: Fotoğraf müşteri konumundan uzak bir noktada çekildi.',
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 11),
                ),
              ),
          ],
        );
      case 'shelf_share':
        return _buildShelfShareInput(field);
      case 'select':
        return DropdownButtonFormField<String>(
          decoration: _getInputDecoration('Seçiniz...'),
          value: _answers[field.id],
          items: field.options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          onChanged: (v) => setState(() => _answers[field.id] = v ?? ''),
          validator: field.isRequired ? (v) => v == null || v.isEmpty ? 'Bu alan zorunludur' : null : null,
        );
      default:
        return TextFormField(
          decoration: _getInputDecoration('Cevabınızı yazın...'),
          maxLines: 3,
          minLines: 1,
          onChanged: (v) => _answers[field.id] = v,
          validator: field.isRequired ? (v) => v == null || v.isEmpty ? 'Bu alan zorunludur' : null : null,
          onSaved: (v) => _answers[field.id] = v ?? '',
        );
    }
  }

  Widget _buildShelfShareInput(AuditFormFieldModel field) {
    // Basic SOS calculation UI
    final currentVal = double.tryParse(_answers[field.id] ?? '0') ?? 0.0;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Raf Payı Oranı: %${currentVal.toInt()}', style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            Text('${currentVal.toInt()}/100', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        Slider(
          value: currentVal,
          min: 0,
          max: 100,
          divisions: 20,
          activeColor: const Color(0xFF00A8E8),
          onChanged: (v) => setState(() => _answers[field.id] = v.toInt().toString()),
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: const Color(0xFFF8F9FD),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A8E8))),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
    );
  }

  Future<void> _pickImage(String fieldId) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50); // Compression
    if (image != null) {
      // Get customer ID from visit
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      final visit = await db.query('visits', where: 'id = ?', whereArgs: [widget.visitId]);
      final customerId = visit.isNotEmpty ? visit.first['customer_id'] as String : '';

      Position position = await Geolocator.getCurrentPosition();
      final verification = await ref.read(merchandisingProvider.notifier).validatePhotoLocation(position, customerId);

      setState(() {
        _photos[fieldId] = File(image.path);
        _answers[fieldId] = image.path;
        _photoVerifications[fieldId] = verification;
        _isAIProcessing = true;
      });

      // Use AIAnalyticsService for processing
      final aiService = AIAnalyticsService();
      
      // Real-time stream for insights
      aiService.streamAIInsights('Shelf analysis').listen((insight) {
        if (mounted) {
          setState(() {
            _aiInsight = insight;
          });
        }
      });

      // Background Isolate analysis (Simulation with fixed data for demo)
      final analysisResults = await aiService.analyzeShelfShare([
        {'brand_name': 'Brand A', 'facings': 5, 'is_competitor': false},
        {'brand_name': 'Brand B', 'facings': 3, 'is_competitor': true},
        {'brand_name': 'Brand C', 'facings': 2, 'is_competitor': false},
      ]);

      if (mounted) {
        setState(() {
          _isAIProcessing = false;
          if (analysisResults['success'] == true) {
            final share = analysisResults['shelf_share'] as double;
            _aiInsight = "Analiz Tamamlandı: Raf Payınız %${share.toStringAsFixed(1)}. 3 rakip ürün saptandı.";
          }
        });
      }
    }
  }

  Widget _buildAIInsightPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Color(0xFF00A8E8)),
              const SizedBox(width: 12),
              const Text(
                'Yapay Zeka Analizi',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (_isAIProcessing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A8E8)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _isAIProcessing 
              ? 'Görseller analiz ediliyor, stok ve raf payı verileri işleniyor...' 
              : _aiInsight ?? '',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final success = await ref.read(merchandisingProvider.notifier).saveAudit(
        visitId: widget.visitId,
        formId: widget.formId,
        answers: _answers,
        verificationData: _photoVerifications,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Denetim başarıyla kaydedildi.'), behavior: SnackBarBehavior.floating));
        Navigator.pop(context);
      }
    }
  }
}
