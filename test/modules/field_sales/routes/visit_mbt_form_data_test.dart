// Dosya Adı: visit_mbt_form_data_test.dart
// Açıklama: MBT ziyaret form verisi ve l10n smoke testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/localization/app_localization.dart';
import 'package:exfin_ops/modules/field_sales/routes/model/visit_mbt_form_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VisitMbtFormData', () {
    test('toPersistedNotes not/sonuç/sebep satırlarını üretir', () {
      const data = VisitMbtFormData(
        visitReason: 'ROUTINE',
        notes: 'Görüşme notu',
        outcome: 'Sipariş Alındı',
        projectCode: 'P-1',
      );
      final notes = data.toPersistedNotes();
      expect(notes, contains('SONUC: Sipariş Alındı'));
      expect(notes, contains('SEBEP: ROUTINE'));
      expect(notes, contains('NOT: Görüşme notu'));
      expect(notes, contains('PROJE: P-1'));
      expect(data.hasReason, isTrue);
      expect(data.hasNotes, isTrue);
    });

    test('boş formda toPersistedNotes boş string', () {
      const data = VisitMbtFormData();
      expect(data.toPersistedNotes(), isEmpty);
      expect(data.hasReason, isFalse);
    });
    test('EKLER satırı toPersistedNotes içinde', () {
      const data = VisitMbtFormData(
        attachments:
            'stub://file/windows/visit_1.bin, /tmp/photo.jpg',
        notes: 'Not',
        outcome: 'Sipariş Alındı',
        visitReason: 'ROUTINE',
      );
      final notes = data.toPersistedNotes();
      expect(
        notes,
        contains(
          'EKLER: stub://file/windows/visit_1.bin, /tmp/photo.jpg',
        ),
      );
    });
  });

  group('visit MBT l10n', () {
    test('TR MBT alan etiketleri çözülür', () async {
      final l10n = await AppLocalization.resolve();
      expect(l10n.isLoaded, isTrue);
      expect(l10n.translate('field_sales.visit_mbt_code'), 'KOD');
      expect(l10n.translate('field_sales.visit_mbt_title'), 'ÜNVAN');
      expect(l10n.translate('field_sales.visit_mbt_reason'), 'ZIYARET SEBEBI');
      expect(l10n.translate('field_sales.visit_mbt_reason_select'), 'Seçim');
      expect(l10n.translate('field_sales.complete_visit'), 'Ziyareti Tamamla');
      expect(l10n.translate('field_sales.visit_reason_order'), 'Sipariş Alma');
      expect(l10n.translate('field_sales.visit_reason_other'), 'Diğer');
      expect(l10n.translate('field_sales.visit_mbt_cancel'), 'VAZGEÇ');
      expect(l10n.translate('field_sales.visit_note_label'), 'Not');
      expect(l10n.translate('field_sales.visit_outcome'), 'Ziyaret Sonucu');
      expect(l10n.translate('field_sales.visit_mbt_attachments'), 'EKLER');
      expect(l10n.translate('field_sales.visit_mbt_attach_file'), 'Dosya');
      expect(l10n.translate('field_sales.visit_mbt_attach_photo'), 'Foto');
      expect(
        l10n.translate(
          'field_sales.visit_mbt_attach_picked',
          args: {'action': 'Dosya', 'path': '/tmp/a.pdf'},
        ),
        'Dosya eklendi: /tmp/a.pdf',
      );
      expect(
        l10n.translate(
          'field_sales.visit_mbt_attach_picker_stub',
          args: {
            'action': 'Dosya',
            'path': 'stub://file/windows/visit_1.bin',
          },
        ),
        'Dosya platform stub: stub://file/windows/visit_1.bin',
      );
    });
  });
}
