import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/campaign_model.dart';
import '../../../../core/services/logo_api_service.dart';

class CampaignManagementScreen extends ConsumerStatefulWidget {
  const CampaignManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CampaignManagementScreen> createState() => _CampaignManagementScreenState();
}

class _CampaignManagementScreenState extends ConsumerState<CampaignManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  CampaignType _type = CampaignType.discount;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kampanya Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAndSync,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Genel Bilgiler'),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Kampanya Adı'),
                onChanged: (v) => _name = v,
                validator: (v) => v!.isEmpty ? 'Ad zorunludur' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CampaignType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Kampanya Türü'),
                items: CampaignType.values.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.name.toUpperCase()),
                )).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Geçerlilik Tarihleri'),
              ListTile(
                title: const Text('Başlangıç Tarihi'),
                subtitle: Text('${_startDate.toLocal()}'.split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, true),
              ),
              ListTile(
                title: const Text('Bitiş Tarihi'),
                subtitle: Text('${_endDate.toLocal()}'.split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, false),
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.sync),
                  label: const Text('Kaydet ve LOGOya Gönder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF375A7F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  onPressed: _saveAndSync,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF375A7F))),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  void _saveAndSync() async {
    if (_formKey.currentState!.validate()) {
      if (_endDate.isBefore(_startDate)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitiş tarihi başlangıçtan önce olamaz!')));
        return;
      }

      final campaignData = {
        'name': _name,
        'campaign_type': _type.name,
        'start_date': _startDate.toIso8601String(),
        'end_date': _endDate.toIso8601String(),
        'is_active': 1,
      };

      // 1. Send to LOGO API
      final result = await LogoApiService().createCampaign(campaignData);
      
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kampanya başarıyla LOGOya gönderildi.')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hata: Kampanya LOGOya gönderilemedi.')));
      }
    }
  }
}
