// Dosya Adı: ai_tts_engine_picker_test.dart
// Açıklama: TTS motor varsayılan OpenAI + l10n anahtarları
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/ai/ai_provider_config.dart';
import 'package:exfin_ops/core/localization/app_localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AiSettingsSnapshot cloudTtsEnabled varsayılan true (OpenAI)', () {
    final snap = AiSettingsSnapshot.empty();
    expect(snap.cloudTtsEnabled, isTrue);
  });

  test('TTS motor l10n anahtarları TR’de dolu', () async {
    final l10n = await AppLocalization.resolve();
    expect(l10n.isLoaded, isTrue);
    expect(l10n.translate('ai.tts_engine'), 'TTS motoru');
    expect(l10n.translate('ai.tts_engine_openai'), 'OpenAI TTS');
    expect(l10n.translate('ai.tts_engine_device'), 'Cihaz TTS');
    expect(
      l10n.translate('ai.tts_engine_openai_key_hint'),
      contains('OpenAI'),
    );
  });
}
