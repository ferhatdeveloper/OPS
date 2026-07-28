// Dosya Adı: whms_ai_insight_banner.dart
// Açıklama: WHMS ekranları opt-in AI insight dens şerit
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../core/ai/features/whms_insight_service.dart';
import '../../../core/localization/app_localization.dart';
import '../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../field_sales/shared/view/field_sales_dens_theme.dart';

/// {@template whms_ai_insight_banner}
/// Kompakt WHMS AI insight paneli — liste üstü dens şerit.
/// Opt-in + key yoksa l10n; uygulama kırılmaz.
///
/// Kullanım örneği:
/// ```dart
/// WhmsAiInsightBanner(
///   contextTitle: 'Emirler',
///   rows: [{'status': 'draft', 'n': '3'}],
/// )
/// ```
/// {@endtemplate}
class WhmsAiInsightBanner extends StatefulWidget {
  /// [contextTitle]: Ekran başlığı
  final String contextTitle;

  /// [rows]: Insight satırları
  final List<Map<String, String>> rows;

  /// [service]: Test inject
  final WhmsInsightService? service;

  /// {@macro whms_ai_insight_banner}
  const WhmsAiInsightBanner({
    Key? key,
    required this.contextTitle,
    required this.rows,
    this.service,
  }) : super(key: key);

  @override
  State<WhmsAiInsightBanner> createState() => _WhmsAiInsightBannerState();
}

class _WhmsAiInsightBannerState extends State<WhmsAiInsightBanner> {
  late final WhmsInsightService _service =
      widget.service ?? WhmsInsightService();

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
    final summaries = WhmsInsightService.summarizeRows(widget.rows);
    final result = await _service.analyze(
      contextTitle: widget.contextTitle,
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
                  _t('whms.ai.insight_title'),
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
