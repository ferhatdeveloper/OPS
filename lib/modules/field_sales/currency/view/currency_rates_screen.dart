// Dosya Adı: currency_rates_screen.dart
// Açıklama: MBT Döviz Kuru dens + SharedPreferences + Hatwan manuel pull
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localization.dart';
import '../engine/hatwan_market_rates_service.dart';
import '../model/currency_rate_record.dart';
import '../model/currency_rate_seed.dart';
import '../viewmodel/currency_rate_store.dart';

/// {@template currency_rates_screen}
/// Döviz Kuru dens ekranı — tarih, kur satırları, Kaydet.
/// Route: `/field-sales/currency-rates`
///
/// AppBar yenile: Hatwan serbest piyasa manuel pull (iskelet).
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, CurrencyRatesScreen.routeName);
/// ```
/// {@endtemplate}
class CurrencyRatesScreen extends StatefulWidget {
  /// [routeName]: Named route — menü seed ile aynı
  static const String routeName = CurrencyRateSeed.route;

  /// {@macro currency_rates_screen}
  const CurrencyRatesScreen({Key? key}) : super(key: key);

  @override
  State<CurrencyRatesScreen> createState() => _CurrencyRatesScreenState();
}

class _CurrencyRatesScreenState extends State<CurrencyRatesScreen> {
  /// [_store]: SharedPreferences kalıcılık
  final CurrencyRateStore _store = const CurrencyRateStore();

  /// [_hatwan]: Hatwan serbest piyasa çekim iskeleti
  final HatwanMarketRatesService _hatwan = HatwanMarketRatesService();

  /// [_rateControllers]: Kod → kur alanı
  late final Map<String, TextEditingController> _rateControllers;

  /// [_rateDate]: Kur tarihi (MBT üst satır)
  late DateTime _rateDate;

  /// [_saving]: Kaydet durumu
  bool _saving = false;

  /// [_pulling]: Hatwan manuel çekim durumu
  bool _pulling = false;

  @override
  void initState() {
    super.initState();
    _rateDate = DateTime.now();
    _rateControllers = {
      for (final row in CurrencyRateSeed.defaultRows)
        row.code: TextEditingController(text: row.rateText),
    };
    _loadSaved();
  }

  @override
  void dispose() {
    for (final c in _rateControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// {@template _load_saved}
  /// Kaydedilmiş kurları SharedPreferences'tan yükler.
  /// {@endtemplate}
  Future<void> _loadSaved() async {
    final record = await _store.load();
    if (!mounted) return;
    setState(() {
      _rateDate = record.rateDate;
      for (final code in CurrencyRateSeed.codes) {
        _rateControllers[code]?.text = record.rateOf(code);
      }
    });
  }

  /// {@template _pick_date}
  /// Kur tarihini dens date picker ile seçer.
  /// {@endtemplate}
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rateDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _rateDate = picked);
  }

  /// {@template _on_save}
  /// Kurları SharedPreferences'a yazar — SnackBar + pop.
  /// {@endtemplate}
  Future<void> _onSave() async {
    if (_saving || _pulling) return;
    setState(() => _saving = true);
    try {
      await _store.save(
        CurrencyRateRecord(
          rateDate: _rateDate,
          rates: {
            for (final code in CurrencyRateSeed.codes)
              code: _rateControllers[code]?.text ?? '',
          },
        ),
      );
      if (!mounted) return;
      final l10n = AppLocalization.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.currency_rates_saved'),
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// {@template _on_pull_hatwan}
  /// Hatwan serbest piyasa kurlarını manuel çeker; eşleşen dens
  /// satırlarına satış kurunu yazar ve [CurrencyRateStore] ile kaydeder.
  /// {@endtemplate}
  Future<void> _onPullHatwan() async {
    if (_pulling || _saving) return;
    setState(() => _pulling = true);
    final l10n = AppLocalization.of(context);
    try {
      final rates = await _hatwan.fetchCurrencies();
      if (!mounted) return;
      final byCode = HatwanMarketRatesService.sellRatesByCode(rates);
      var applied = 0;
      for (final entry in _rateControllers.entries) {
        final sell = byCode[entry.key];
        if (sell == null) continue;
        entry.value.text = HatwanMarketRatesService.formatRateTr(sell);
        applied++;
      }
      if (applied > 0) {
        await _store.save(
          CurrencyRateRecord(
            rateDate: _rateDate,
            rates: {
              for (final code in CurrencyRateSeed.codes)
                code: _rateControllers[code]?.text ?? '',
            },
          ),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate(
              'field_sales.currency_rates_hatwan_pulled',
              args: {'count': '$applied'},
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } on HatwanMarketRatesException catch (e) {
      if (!mounted) return;
      final key = e.message.toLowerCase().contains('cors')
          ? 'field_sales.currency_rates_hatwan_cors'
          : 'field_sales.currency_rates_hatwan_error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate(key)),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.currency_rates_hatwan_error'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
  }

  InputDecoration _rateDecoration() {
    return InputDecoration(
      isDense: true,
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF375A7F)),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const Color primary = Color(0xFF375A7F);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          l10n.translate('field_sales.stubs.currency_rates'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_pulling)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.translate(
                'field_sales.currency_rates_hatwan_pull',
              ),
              onPressed: _saving ? null : _onPullHatwan,
            ),
        ],
      ),
      body: Column(
        children: [
          InkWell(
            onTap: _pickDate,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                CurrencyRateSeed.formatDate(_rateDate),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: CurrencyRateSeed.codes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final code = CurrencyRateSeed.codes[index];
                final controller = _rateControllers[code]!;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          code,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        ':',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.right,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: index ==
                                  CurrencyRateSeed.codes.length - 1
                              ? TextInputAction.done
                              : TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9,.]'),
                            ),
                          ],
                          decoration: _rateDecoration(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_saving || _pulling) ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.translate('common.save'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
