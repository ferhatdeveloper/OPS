// Dosya Adı: report_ai_insight_banner.dart
// Açıklama: Rapor sonuç ekranı opt-in AI insight dens şerit
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/ai/features/report_insight_service.dart';
import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_theme.dart';

/// {@template report_ai_insight_banner}
/// Kompakt AI insight paneli — AppBar altı / liste üstü.
/// Opt-in + key yoksa l10n; uygulama kırılmaz.
/// {@endtemplate}
class ReportAiInsightBanner extends StatefulWidget {
  /// [reportTitle]: Rapor başlığı
  final String reportTitle;

  /// [rows]: Sonuç satırları
  final List<Map<String, String>> rows;

  /// [service]: Test inject
  final ReportInsightService? service;

  /// {@macro report_ai_insight_banner}
  const ReportAiInsightBanner({
    Key? key,
    required this.reportTitle,
    required this.rows,
    this.service,
  }) : super(key: key);

  @override
  State<ReportAiInsightBanner> createState() => _ReportAiInsightBannerState();
}

class _ReportAiInsightBannerState extends State<ReportAiInsightBanner> {
  late final ReportInsightService _service =
      widget.service ?? ReportInsightService();

  bool _busy = false;
  String? _text;
  String? _statusKey;

  String _t(String key) => AppLocalization.of(context).translate(key);

  Future<void> _run() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _statusKey = null;
      _text = null;
    });
    final summaries = ReportInsightService.summarizeRows(widget.rows);
    final result = await _service.analyze(
      reportTitle: widget.reportTitle,
      rowSummaries: summaries,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.isOk) {
        _text = result.text;
      } else {
        _statusKey = result.l10nKey ?? 'ai.request_failed';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final onBody = FieldSalesDensTheme.title(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: FieldSalesDensTheme.surface(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: FieldSalesDensTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 16,
                color: FieldSalesDensAppBar.primaryColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _t('ai.report_insight_title'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: onBody,
                  ),
                ),
              ),
              SizedBox(
                height: 30,
                child: TextButton(
                  onPressed: _busy ? null : _run,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: FieldSalesDensAppBar.primaryColor,
                  ),
                  child: Text(
                    _busy ? _t('ai.analyzing') : _t('ai.generate_insight'),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          if (_statusKey != null) ...[
            const SizedBox(height: 4),
            Text(
              _t(_statusKey!),
              style: const TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ],
          if (_text != null) ...[
            const SizedBox(height: 4),
            Text(
              _text!,
              style: TextStyle(fontSize: 12, height: 1.35, color: onBody),
            ),
          ],
        ],
      ),
    );
  }
}
