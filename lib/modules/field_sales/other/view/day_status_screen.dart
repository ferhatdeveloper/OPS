import 'package:flutter/material.dart';
class DayStatusScreen extends StatefulWidget {
  const DayStatusScreen({Key? key}) : super(key: key);

  @override
  State<DayStatusScreen> createState() => _DayStatusScreenState();
}

class _DayStatusScreenState extends State<DayStatusScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _kmController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  bool _isDayStarted = false;
  DateTime? _startTime;
  DateTime? _endTime;

  void _toggleDayStatus() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        if (!_isDayStarted) {
          _isDayStarted = true;
          _startTime = DateTime.now();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Güne başarıyla başlandı.'), backgroundColor: Colors.green),
          );
        } else {
          _isDayStarted = false;
          _endTime = DateTime.now();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gün başarıyla sonlandırıldı.'), backgroundColor: Colors.orange),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _kmController.dispose();
    _notesController.dispose();
    super.dispose();
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
        title: const Text('Güne Başlama / Bitirme', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current Status Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isDayStarted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isDayStarted ? Icons.play_arrow_rounded : Icons.stop_rounded,
                        size: 48,
                        color: _isDayStarted ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isDayStarted ? 'Mesai Devam Ediyor' : 'Mesai Dışı',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _isDayStarted ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_startTime != null)
                      Text(
                        "Başlangıç: \${_startTime!.hour.toString().padLeft(2, '0')}:\${_startTime!.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    if (_endTime != null && !_isDayStarted)
                      Text(
                        "Bitiş: \${_endTime!.hour.toString().padLeft(2, '0')}:\${_endTime!.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Inputs
              Text('Araç Bilgileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kmController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Araç Kilometresi (KM)',
                  prefixIcon: const Icon(Icons.speed, color: Color(0xFF375A7F)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Lütfen kilometre bilgisini giriniz.';
                  if (int.tryParse(val) == null) return 'Geçerli bir rakam giriniz.';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              Text('Günlük Notlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Varsa notlarınızı buraya ekleyin...',
                  prefixIcon: const Icon(Icons.notes, color: Color(0xFF375A7F)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
              const SizedBox(height: 32),

              // Action Button
              ElevatedButton(
                onPressed: _toggleDayStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDayStarted ? Colors.orange : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Text(
                  _isDayStarted ? 'GÜNÜ BİTİR' : 'GÜNE BAŞLA',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
