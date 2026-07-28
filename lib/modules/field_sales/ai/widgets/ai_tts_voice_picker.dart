// Dosya Adı: ai_tts_voice_picker.dart
// Açıklama: Dens TTS konuşmacı (persona) seçici
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/ai/voice/ai_tts_voice.dart';
import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';

/// {@template ai_tts_voice_picker}
/// Insansı konuşmacı stili chip satırı.
/// {@endtemplate}
class AiTtsVoicePicker extends StatelessWidget {
  /// [value]: storageKey
  final String value;

  /// [onChanged]
  final ValueChanged<String> onChanged;

  /// {@macro ai_tts_voice_picker}
  const AiTtsVoicePicker({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final selected = AiTtsVoicePersonaX.parse(value);
    return FieldSalesDensChipRow(
      fontSize: 10,
      items: AiTtsVoicePersona.values
          .map(
            (p) => FieldSalesDensChipItem(
              label: l10n.translate(p.labelKey),
              selected: selected == p,
              onTap: () => onChanged(p.storageKey),
            ),
          )
          .toList(),
    );
  }
}
