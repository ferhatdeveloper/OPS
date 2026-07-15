import 'package:flutter/material.dart';

class TargetAssignmentScreen extends StatefulWidget {
  const TargetAssignmentScreen({Key? key}) : super(key: key);

  @override
  State<TargetAssignmentScreen> createState() => _TargetAssignmentScreenState();
}

class _TargetAssignmentScreenState extends State<TargetAssignmentScreen> {
  // Dummy data for sales representatives
  final List<Map<String, dynamic>> _reps = [
    {'id': '1', 'name': 'Ahmet Yılmaz', 'region': 'Marmara Bölgesi', 'revenueTarget': 150000.0, 'visitTarget': 120, 'newCustTarget': 10},
    {'id': '2', 'name': 'Ayşe Demir', 'region': 'Ege Bölgesi', 'revenueTarget': null, 'visitTarget': null, 'newCustTarget': null},
    {'id': '3', 'name': 'Mehmet Kaya', 'region': 'İç Anadolu Bölgesi', 'revenueTarget': 200000.0, 'visitTarget': 150, 'newCustTarget': 15},
    {'id': '4', 'name': 'Fatma Şahin', 'region': 'Akdeniz Bölgesi', 'revenueTarget': null, 'visitTarget': null, 'newCustTarget': null},
  ];

  void _showSetTargetBottomSheet(Map<String, dynamic> rep) {
    final revenueCtrl = TextEditingController(text: rep['revenueTarget']?.toString() ?? '');
    final visitCtrl = TextEditingController(text: rep['visitTarget']?.toString() ?? '');
    final newCustCtrl = TextEditingController(text: rep['newCustTarget']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFE3F2FD),
                        child: Text(rep['name'].substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF375A7F))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rep['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF375A7F))),
                            Text(rep['region'], style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Aylık Hedefleri Belirleyin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: revenueCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Aylık Ciro Hedefi (₺)',
                      prefixIcon: const Icon(Icons.monetization_on, color: Color(0xFF00A8E8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Lütfen ciro hedefi giriniz' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: visitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Aylık Ziyaret Hedefi (Adet)',
                      prefixIcon: const Icon(Icons.location_on, color: Color(0xFF00A8E8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Lütfen ziyaret hedefi giriniz' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newCustCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Aylık Yeni Müşteri Hedefi (Kişi/Firma)',
                      prefixIcon: const Icon(Icons.person_add, color: Color(0xFF00A8E8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Lütfen yeni müşteri hedefi giriniz' : null,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          rep['revenueTarget'] = double.parse(revenueCtrl.text.replaceAll(',', '.'));
                          rep['visitTarget'] = int.parse(visitCtrl.text);
                          rep['newCustTarget'] = int.parse(newCustCtrl.text);
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hedefler başarıyla atandı!'), backgroundColor: Colors.green));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF375A7F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('HEDEFİ ATA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Hedef Atama', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'ERP ile Eşitle',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hedefler Logo ERP ile eşitleniyor...')));
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reps.length,
        itemBuilder: (context, index) {
          final rep = _reps[index];
          final bool hasTarget = rep['revenueTarget'] != null;

          return Card(
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () => _showSetTargetBottomSheet(rep),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: hasTarget ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          child: Icon(
                            hasTarget ? Icons.check_circle : Icons.pending_actions,
                            color: hasTarget ? Colors.green : Colors.orange,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rep['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50))),
                              const SizedBox(height: 4),
                              Text(rep['region'], style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                      ],
                    ),
                    if (hasTarget) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(child: _buildTargetPill('Ciro', "\${rep['revenueTarget']}₺", Icons.monetization_on, Colors.blue)),
                          Expanded(child: _buildTargetPill('Ziyaret', "\${rep['visitTarget']}", Icons.location_on, Colors.purple)),
                          Expanded(child: _buildTargetPill('Müşteri', "\${rep['newCustTarget']}", Icons.person_add, Colors.orange)),
                        ],
                      )
                    ] else ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Text('Aylık hedef atanmamış.', style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTargetPill(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 1),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 1),
      ],
    );
  }
}
