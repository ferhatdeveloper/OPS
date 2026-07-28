// Dosya Adı: ai_speech_language_picker.dart
// Açıklama: Dens konuşma dili seçici — Auto/TR/EN/… (AppBar / ayarlar)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/ai/voice/ai_speech_language_detector.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';

/// {@template ai_speech_language_picker}
/// Dens dil seçici — chip satırı veya kompakt AppBar popup.
///
/// Kullanım örneği:
/// ```dart
/// AiSpeechLanguagePicker(
///   value: 'auto',
///   onChanged: (v) {},
/// )
/// ```
/// {@endtemplate}
class AiSpeechLanguagePicker extends StatelessWidget {
  /// [value]: Tercih (auto | tr | …)
  final String value;

  /// [onChanged]: Seçim
  final ValueChanged<String> onChanged;

  /// [compact]: true → AppBar popup; false → chip satırı
  final bool compact;

  /// [primary]: Dens primary
  final Color primary;

  /// {@macro ai_speech_language_picker}
  const AiSpeechLanguagePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.compact = false,
    this.primary = FieldSalesDensAppBar.primaryColor,
  });

  String get _current =>
      AiSpeechLanguageDetector.normalizePreference(value);

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact(context);
    return _buildChips();
  }

  Widget _buildCompact(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: AiSpeechLanguageDetector.labelFor(_current),
      padding: EdgeInsets.zero,
      onSelected: onChanged,
      itemBuilder: (ctx) => [
        for (final opt in AiSpeechLanguageDetector.preferenceOptions)
          PopupMenuItem<String>(
            value: opt,
            height: 36,
            child: Text(
              AiSpeechLanguageDetector.labelFor(opt),
              style: TextStyle(
                fontSize: 13,
                fontWeight: opt == _current
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: primary,
              ),
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: FieldSalesDensChip(
          label: AiSpeechLanguageDetector.labelFor(_current),
          selected: true,
          primary: primary,
          fontSize: 11,
          onTap: null,
        ),
      ),
    );
  }

  Widget _buildChips() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final opt in AiSpeechLanguageDetector.preferenceOptions)
          IntrinsicWidth(
            child: FieldSalesDensChip(
              label: AiSpeechLanguageDetector.labelFor(opt),
              selected: opt == _current,
              primary: primary,
              fontSize: 11,
              onTap: () => onChanged(opt),
            ),
          ),
      ],
    );
  }
}
