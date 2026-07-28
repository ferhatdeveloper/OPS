// Dosya Adı: ai_tts_engine_picker.dart
// Açıklama: Dens TTS motor seçici — OpenAI TTS | Cihaz TTS
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';

/// {@template ai_tts_engine_picker}
/// TTS motoru: OpenAI (bulut) veya cihaz. Varsayılan OpenAI.
///
/// Kullanım örneği:
/// ```dart
/// AiTtsEnginePicker(
///   cloudEnabled: true,
///   onChanged: (v) {},
/// )
/// ```
/// {@endtemplate}
class AiTtsEnginePicker extends StatelessWidget {
  /// [cloudEnabled]: true = OpenAI TTS
  final bool cloudEnabled;

  /// [onChanged]
  final ValueChanged<bool> onChanged;

  /// [compact]: AppBar için dar etiket
  final bool compact;

  /// [enabled]: false → chip’ler pasif (TTS kapalı)
  final bool enabled;

  /// [primary]
  final Color primary;

  /// {@macro ai_tts_engine_picker}
  const AiTtsEnginePicker({
    Key? key,
    required this.cloudEnabled,
    required this.onChanged,
    this.compact = false,
    this.enabled = true,
    this.primary = FieldSalesDensAppBar.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final openaiLabel = compact
        ? l10n.translate('ai.tts_engine_openai_short')
        : l10n.translate('ai.tts_engine_openai');
    final deviceLabel = compact
        ? l10n.translate('ai.tts_engine_device_short')
        : l10n.translate('ai.tts_engine_device');

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: FieldSalesDensChipRow(
        fontSize: compact ? 10 : 11,
        items: [
          FieldSalesDensChipItem(
            label: openaiLabel,
            selected: cloudEnabled,
            onTap: enabled ? () => onChanged(true) : () {},
          ),
          FieldSalesDensChipItem(
            label: deviceLabel,
            selected: !cloudEnabled,
            onTap: enabled ? () => onChanged(false) : () {},
          ),
        ],
      ),
    );
  }
}
