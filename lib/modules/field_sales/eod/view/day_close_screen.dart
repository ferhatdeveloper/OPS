// Dosya Adı: day_close_screen.dart
// Açıklama: Gün sonu kapanış ekranı (MBT: bitiş KM, Tamamlandı?, Kaydet)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../other/model/day_status_record.dart';
import '../../other/viewmodel/day_status_store.dart';
import '../../other/widgets/day_status_mbt_fields.dart';
import '../../gps/viewmodel/live_location_session.dart';
import '../viewmodel/day_close_sync_defaults.dart';
import '../viewmodel/day_close_sync_service.dart';

/// {@template day_close_screen}
/// Plasiyer gün sonu kapanış (MBT bitiş KM + Tamamlandı?).
///
/// Rota: `/field-sales/day-close`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, DayCloseScreen.routeName);
/// ```
/// {@endtemplate}
class DayCloseScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/day-close`
  static const String routeName = '/field-sales/day-close';

  const DayCloseScreen({Key? key}) : super(key: key);

  @override
  State<DayCloseScreen> createState() => _DayCloseScreenState();
}

class _DayCloseScreenState extends State<DayCloseScreen> {
  /// [_formKey]: Form doğrulama anahtarı
  final _formKey = GlobalKey<FormState>();

  /// [_store]: SharedPreferences kalıcılık
  final DayStatusStore _store = const DayStatusStore();

  /// [_syncService]: Gün sonu sync_queue + audit_log
  final DayCloseSyncService _syncService = createDefaultDayCloseSyncService();

  /// [_plateController]: Plaka alanı
  final TextEditingController _plateController = TextEditingController();

  /// [_startKmController]: Başlangıç KM (salt okunur bağlam)
  final TextEditingController _startKmController = TextEditingController();

  /// [_endKmController]: Bitiş KM alanı
  final TextEditingController _endKmController = TextEditingController();

  /// [_record]: Yüklü gün kaydı
  DayStatusRecord _record = const DayStatusRecord();

  /// [_completed]: Tamamlandı? checkbox
  bool _completed = true;

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

  /// {@template day_close_load}
  /// Yerel kaydı yükler.
  /// {@endtemplate}
  Future<void> _load() async {
    final record = await _store.load();
    if (!mounted) return;
    setState(() {
      _record = record;
      _completed = true;
      _plateController.text = record.plate;
      _startKmController.text =
          record.startKm == null ? '' : '${record.startKm}';
      _endKmController.text = record.endKm == null ? '' : '${record.endKm}';
      _loading = false;
    });
  }

  /// {@template day_close_save}
  /// Bitiş KM + Tamamlandı? ile günü kapatır.
  /// {@endtemplate}
  Future<void> _onSave() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final endKm = int.tryParse(_endKmController.text.trim());
      final startKm = int.tryParse(_startKmController.text.trim()) ??
          _record.startKm;
      final next = DayStatusRecord.applySave(
        current: _record,
        plate: _plateController.text.isEmpty
            ? _record.plate
            : _plateController.text,
        startKm: startKm,
        endKm: endKm,
        completed: _completed,
        now: DateTime.now(),
      );
      final previous = _record;
      await _store.save(next);
      LiveLocationSession().stop();
      try {
        await _syncService.recordClose(
          record: next,
          previous: previous,
        );
      } catch (_) {
        // Yerel gün kapanışı başarılı; sync/audit sonraki denemede
      }
      if (!mounted) return;
      final l10n = AppLocalization.of(context);
      setState(() => _record = next);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.day_ended')),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.day_close');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                      l10n.translate('field_sales.end_of_day'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DayStatusMbtFields(
                      plateController: _plateController,
                      startKmController: _startKmController,
                      endKmController: _endKmController,
                      completed: _completed,
                      onCompletedChanged: (v) {
                        setState(() => _completed = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saving || !_completed ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A8E8),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
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
