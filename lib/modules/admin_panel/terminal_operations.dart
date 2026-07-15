// Dosya Adı: terminal_operations.dart
// Açıklama: Admin paneli için terminal işlemleri ekranı (komut/script çalıştırma, log görüntüleme)
// Oluşturulma Tarihi: 2024-03-22
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-22

import 'package:flutter/material.dart';

/// {@template TerminalOperations}
/// Terminal işlemleri ekranı: Komut/script çalıştırma, log görüntüleme, çıktı gösterme
///
/// Kullanım örneği:
/// ```dart
/// TerminalOperations()
/// ```
/// {@endtemplate}
class TerminalOperations extends StatefulWidget {
  const TerminalOperations({Key? key}) : super(key: key);

  @override
  State<TerminalOperations> createState() => _TerminalOperationsState();
}

class _TerminalOperationsState extends State<TerminalOperations> {
  final TextEditingController _commandController = TextEditingController();
  String _output = '';
  List<String> _logs = [];
  bool _isRunning = false;

  Future<void> _runCommand() async {
    setState(() {
      _isRunning = true;
      _output = '';
      _logs.insert(0,
          '[${DateTime.now()}] Komut çalıştırılıyor: ${_commandController.text}');
    });
    // Gerçek komut/script çalıştırma burada entegre edilmeli
    await Future.delayed(const Duration(seconds: 2)); // Simülasyon
    setState(() {
      _output = 'Çıktı: Komut başarıyla çalıştırıldı.';
      _logs.insert(0,
          '[${DateTime.now()}] Komut tamamlandı: ${_commandController.text}');
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terminal İşlemleri')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    decoration: const InputDecoration(
                      labelText: 'Komut veya script',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runCommand,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Çalıştır'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Çıktı:', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.black12,
              child: Text(_output),
            ),
            const SizedBox(height: 16),
            const Text('Terminal Logları:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) => Text(_logs[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
