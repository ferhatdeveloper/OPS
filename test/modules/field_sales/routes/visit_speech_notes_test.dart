// Dosya Adı: visit_speech_notes_test.dart
// Açıklama: Ziyaret STT not birleştirme ve locale seçimi birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/localization/app_localization.dart';
import 'package:exfin_ops/modules/field_sales/routes/model/visit_speech_notes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VisitSpeechNotes.appendFinal', () {
    test('boş not + chunk → chunk', () {
      expect(VisitSpeechNotes.appendFinal('', 'Merhaba'), 'Merhaba');
      expect(VisitSpeechNotes.appendFinal('  ', 'Merhaba'), 'Merhaba');
    });

    test('mevcut not + chunk boşlukla birleşir', () {
      expect(
        VisitSpeechNotes.appendFinal('Merhaba', 'dünya'),
        'Merhaba dünya',
      );
    });

    test('satır sonundan sonra boşluksuz ekler', () {
      expect(
        VisitSpeechNotes.appendFinal('Satır1\n', 'Satır2'),
        'Satır1\nSatır2',
      );
    });

    test('boş chunk mevcut metni korur', () {
      expect(VisitSpeechNotes.appendFinal('Not', '  '), 'Not');
      expect(VisitSpeechNotes.appendFinal('Not', ''), 'Not');
    });
  });

  group('VisitSpeechNotes.buildAudioFilePath', () {
    test('directory + visitId → speech.m4a', () {
      expect(
        VisitSpeechNotes.buildAudioFilePath(
          directory: '/docs',
          visitId: 'v9',
        ),
        '/docs/v9_speech.m4a',
      );
    });

    test('güvensiz karakterler sanitize edilir', () {
      expect(
        VisitSpeechNotes.buildAudioFilePath(
          directory: '/tmp',
          visitId: 'a/b c',
        ),
        '/tmp/a_b_c_speech.m4a',
      );
    });
  });

  group('VisitSpeechNotes.resolveLocaleId', () {
    const available = [
      'tr_TR',
      'en_US',
      'ar_SA',
      'de_DE',
      'fa_IR',
    ];

    test('tr → tr_TR', () {
      expect(
        VisitSpeechNotes.resolveLocaleId('tr', available),
        'tr_TR',
      );
    });

    test('ar → ar_SA', () {
      expect(
        VisitSpeechNotes.resolveLocaleId('ar', available),
        'ar_SA',
      );
    });

    test('ku → ar yedek (cihazda ku yoksa)', () {
      expect(
        VisitSpeechNotes.resolveLocaleId('ku', available),
        'ar_SA',
      );
    });

    test('ckb → ar yedek', () {
      expect(
        VisitSpeechNotes.resolveLocaleId('ckb', available),
        'ar_SA',
      );
    });

    test('bilinmeyen dil → null', () {
      expect(
        VisitSpeechNotes.resolveLocaleId('zh', available),
        isNull,
      );
    });

    test('boş liste → null', () {
      expect(VisitSpeechNotes.resolveLocaleId('tr', const []), isNull);
    });
  });

  group('visit speech l10n', () {
    test('TR STT anahtarları çözülür', () async {
      final l10n = await AppLocalization.resolve();
      expect(l10n.isLoaded, isTrue);
      expect(
        l10n.translate('field_sales.visit_speech_idle'),
        'Sesli not',
      );
      expect(
        l10n.translate('field_sales.visit_speech_listening'),
        'Dinleniyor',
      );
      expect(
        l10n.translate('field_sales.visit_speech_mic_denied'),
        contains('Mikrofon'),
      );
      expect(
        l10n.translate('field_sales.visit_speech_unavailable'),
        isNotEmpty,
      );
      expect(
        l10n.translate('field_sales.visit_speech_error'),
        isNotEmpty,
      );
    });
  });
}
