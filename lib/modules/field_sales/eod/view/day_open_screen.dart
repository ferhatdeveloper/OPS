// Dosya Adı: day_open_screen.dart
// Açıklama: Güne Başlama ekranı (MBT: plaka, başlangıç KM, Kaydet)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../other/model/day_status_record.dart';
import '../../other/viewmodel/day_status_store.dart';
import '../../other/widgets/day_status_mbt_fields.dart';

/// {@template day_open_screen}
/// MBT "Güne Başlama" ekranı (plaka + başlangıç KM).
/// Route: `/field-sales/day-open`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, '/field-sales/day-open');
/// ```
/// {@endtemplate}
class DayOpenScreen extends StatefulWidget {
  /// {@template day_open_screen_constructor}
  /// Güne Başlama ekranını oluşturur.
  /// {@endtemplate}
  const DayOpenScreen({Key? key}) : super(key: key);

  /// [routeName]: Named route — `/field-sales/day-open`
  static const String routeName = '/field-sales/day-open';

  @override
  State<DayOpenScreen> createState() => _DayOpenScreenState();
}

class _DayOpenScreenState extends State<DayOpenScreen> {
  /// [_formKey]: Form doğrulama anahtarı
  final _formKey = GlobalKey<FormState>();

  /// [_store]: SharedPreferences kalıcılık
  final DayStatusStore _store = const DayStatusStore();

  /// [_plateController]: Plaka alanı
  final TextEditingController _plateController = TextEditingController();

  /// [_startKmController]: Başlangıç KM alanı
  final TextEditingController _startKmController = TextEditingController();

  /// [_endKmController]: Bitiş KM (gizli; store uyumu)
  final TextEditingController _endKmController = TextEditingController();

  /// [_record]: Yüklü gün kaydı
  DayStatusRecord _record = const DayStatusRecord();

  /// [_loading]: Yükleme durumu
  bool _loading = true;

  /// [_saving]: Kayıt durumu
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _plateController.dispose();
    _startKmController.dispose();
    _endKmController.dispose();
    super.dispose();
  }

  /// {@template day_open_load}
  /// Yerel kaydı yükler.
  /// {@endtemplate}
  Future<void> _load() async {
    final record = await _store.load();
    if (!mounted) return;
    setState(() {
      _record = record;
      _plateController.text = record.plate;
      _startKmController.text =
          record.startKm == null ? '' : '${record.startKm}';
      _endKmController.text = record.endKm == null ? '' : '${record.endKm}';
      _loading = false;
    });
  }

  /// {@template day_open_save}
  /// Plaka + başlangıç KM ile günü açar.
  /// {@endtemplate}
  Future<void> _onSave() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final startKm = int.tryParse(_startKmController.text.trim());
      final next = DayStatusRecord.applySave(
        current: _record,
        plate: _plateController.text,
        startKm: startKm,
        endKm: _record.endKm,
        completed: false,
        now: DateTime.now(),
      );
      await _store.save(next);
      if (!mounted) return;
      final l10n = AppLocalization.of(context);
      setState(() => _record = next);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.day_started')),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.day_open');

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
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.translate('field_sales.day_start_check_hint'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DayStatusMbtFields(
                      plateController: _plateController,
                      startKmController: _startKmController,
                      endKmController: _endKmController,
                      completed: false,
                      onCompletedChanged: (_) {},
                      showEndKm: false,
                      showCompleted: false,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saving ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF375A7F),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.translate('common.save'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
