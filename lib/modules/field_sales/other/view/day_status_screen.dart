// Dosya Adı: day_status_screen.dart
// Açıklama: Güne başlama / bitirme ekranı (MBT plaka/km/tamamlandı)
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/day_status_record.dart';
import '../viewmodel/day_status_store.dart';
import '../widgets/day_status_mbt_fields.dart';

/// {@template day_status_screen}
/// Plasiyer gün durumu (başla / bitir) ekranı — MBT alanları.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => const DayStatusScreen(),
/// ));
/// ```
/// {@endtemplate}
class DayStatusScreen extends StatefulWidget {
  /// {@macro day_status_screen}
  const DayStatusScreen({Key? key}) : super(key: key);

  @override
  State<DayStatusScreen> createState() => _DayStatusScreenState();
}

class _DayStatusScreenState extends State<DayStatusScreen> {
  /// [_formKey]: Form doğrulama anahtarı
  final _formKey = GlobalKey<FormState>();

  /// [_store]: SharedPreferences kalıcılık
  final DayStatusStore _store = const DayStatusStore();

  /// [_plateController]: Plaka alanı
  final TextEditingController _plateController = TextEditingController();

  /// [_startKmController]: Başlangıç KM alanı
  final TextEditingController _startKmController = TextEditingController();

  /// [_endKmController]: Bitiş KM alanı
  final TextEditingController _endKmController = TextEditingController();

  /// [_record]: Yüklü gün kaydı
  DayStatusRecord _record = const DayStatusRecord();

  /// [_completed]: Tamamlandı? checkbox
  bool _completed = false;

  /// [_loading]: Yükleme durumu
  bool _loading = true;

  /// [_saving]: Kayıt durumu
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// {@template _load}
  /// Yerel gün kaydını yükler.
  /// {@endtemplate}
  Future<void> _load() async {
    final record = await _store.load();
    if (!mounted) return;
    setState(() {
      _record = record;
      _completed = record.completed;
      _plateController.text = record.plate;
      _startKmController.text =
          record.startKm == null ? '' : '${record.startKm}';
      _endKmController.text = record.endKm == null ? '' : '${record.endKm}';
      _loading = false;
    });
  }

  /// {@template _parse_km}
  /// Metin KM değerini int? olarak okur.
  /// {@endtemplate}
  int? _parseKm(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  /// {@template _on_save}
  /// MBT formunu doğrular ve SharedPreferences'a kaydeder.
  /// {@endtemplate}
  Future<void> _onSave() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final next = DayStatusRecord.applySave(
        current: _record,
        plate: _plateController.text,
        startKm: _parseKm(_startKmController.text),
        endKm: _parseKm(_endKmController.text),
        completed: _completed,
        now: DateTime.now(),
      );
      await _store.save(next);
      if (!mounted) return;
      final l10n = AppLocalization.of(context);
      setState(() => _record = next);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next.completed
                ? l10n.translate('field_sales.day_ended')
                : l10n.translate('field_sales.day_started'),
          ),
          backgroundColor: next.completed ? Colors.orange : Colors.green,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// {@template _format_hm}
  /// Saati HH:mm biçiminde döndürür.
  ///
  /// Parametreler:
  /// - [dt]: Biçimlenecek zaman
  ///
  /// Dönüş değeri:
  /// - [String]: HH:mm metni
  /// {@endtemplate}
  String _formatHm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _plateController.dispose();
    _startKmController.dispose();
    _endKmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDayStarted = _record.isDayStarted && !_record.completed;

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          l10n.translate('submodules.gune_baslama_bitirme'),
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
                      l10n.translate('field_sales.day_flow_guide'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isDayStarted
                                ? Icons.play_arrow_rounded
                                : Icons.stop_rounded,
                            size: 36,
                            color: isDayStarted ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isDayStarted
                                ? l10n.translate(
                                    'field_sales.work_in_progress',
                                  )
                                : l10n.translate('field_sales.off_duty'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDayStarted
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                          if (_record.startTime != null)
                            Text(
                              l10n.translate(
                                'field_sales.day_start_time',
                                args: {
                                  'time': _formatHm(_record.startTime!),
                                },
                              ),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          if (_record.endTime != null && !isDayStarted)
                            Text(
                              l10n.translate(
                                'field_sales.day_end_time',
                                args: {
                                  'time': _formatHm(_record.endTime!),
                                },
                              ),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.translate('field_sales.vehicle_info'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
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
