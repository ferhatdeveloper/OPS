import 'package:flutter/material.dart';
import '../engine/competitor_analysis_service.dart';
import '../model/competitor_model.dart';
import 'package:uuid/uuid.dart';

class CompetitorSurveyScreen extends StatefulWidget {
  final String visitId;
  const CompetitorSurveyScreen({Key? key, required this.visitId}) : super(key: key);

  @override
  State<CompetitorSurveyScreen> createState() => _CompetitorSurveyScreenState();
}

class _CompetitorSurveyScreenState extends State<CompetitorSurveyScreen> {
  final _service = CompetitorAnalysisService();
  List<CompetitorProductModel> _products = [];
  List<CompetitorObservationModel> _observations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _service.seedMockProducts(); // Ensure we have something to show
    final products = await _service.getCompetitorProducts();
    final observations = await _service.getObservationsByVisit(widget.visitId);
    setState(() {
      _products = products;
      _observations = observations;
      _isLoading = false;
    });
  }

  void _showSurveyDialog(CompetitorProductModel product) {
    final priceController = TextEditingController();
    bool hasStock = true;
    bool onPromotion = false;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('${product.name} Analizi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Gözlemlenen Fiyat', suffixText: '₺'),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  title: const Text('Stokta Var'),
                  value: hasStock,
                  onChanged: (v) => setModalState(() => hasStock = v),
                ),
                SwitchListTile(
                  title: const Text('Kampanyada'),
                  value: onPromotion,
                  onChanged: (v) => setModalState(() => onPromotion = v),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notlar'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                final obs = CompetitorObservationModel(
                  id: const Uuid().v4(),
                  visitId: widget.visitId,
                  competitorProductId: product.id,
                  observedPrice: double.tryParse(priceController.text),
                  hasStock: hasStock,
                  onPromotion: onPromotion,
                  notes: notesController.text,
                  createdAt: DateTime.now(),
                );
                await _service.saveObservation(obs);
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rakip Analizi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final p = _products[index];
                final obs = _observations.where((o) => o.competitorProductId == p.id).toList();
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${p.brand ?? ""} - ${p.category ?? ""}'),
                    trailing: obs.isNotEmpty 
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.add_chart, color: Colors.blue),
                    onTap: () => _showSurveyDialog(p),
                  ),
                );
              },
            ),
    );
  }
}
