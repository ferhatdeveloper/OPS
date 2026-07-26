// Dosya Adı: visit_attachment_picker_test.dart
// Açıklama: Ziyaret EKLER picker stub path ve forceStub birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/localization/app_localization.dart';
import 'package:exfin_ops/modules/field_sales/routes/engine/visit_attachment_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VisitAttachmentPicker.buildStubPath', () {
    test('foto için net stub:// URI üretir', () {
      final path = VisitAttachmentPicker.buildStubPath(
        kind: VisitAttachKind.photo,
        platform: 'android',
        now: DateTime(2026, 7, 26, 12, 25, 0),
      );
      expect(
        path,
        'stub://photo/android/visit_20260726122500.jpg',
      );
    });

    test('dosya için net stub:// URI üretir', () {
      final path = VisitAttachmentPicker.buildStubPath(
        kind: VisitAttachKind.file,
        platform: 'windows',
        now: DateTime(2026, 7, 26, 12, 25, 1),
      );
      expect(
        path,
        'stub://file/windows/visit_20260726122501.bin',
      );
    });
  });

  group('VisitAttachmentPicker.forceStub', () {
    test('pickPhoto stub path döner', () async {
      final picker = VisitAttachmentPicker(
        forceStub: true,
        platformLabel: 'ios',
        clock: () => DateTime(2026, 7, 26, 9, 0, 0),
      );
      final result = await picker.pickPhoto();
      expect(result, isNotNull);
      expect(result!.isStub, isTrue);
      expect(result.kind, VisitAttachKind.photo);
      expect(
        result.path,
        'stub://photo/ios/visit_20260726090000.jpg',
      );
    });

    test('pickFile stub path döner', () async {
      final picker = VisitAttachmentPicker(
        forceStub: true,
        platformLabel: 'linux',
        clock: () => DateTime(2026, 7, 26, 9, 0, 1),
      );
      final result = await picker.pickFile();
      expect(result, isNotNull);
      expect(result!.isStub, isTrue);
      expect(result.kind, VisitAttachKind.file);
      expect(
        result.path,
        'stub://file/linux/visit_20260726090001.bin',
      );
    });
  });

  group('visit EKLER l10n', () {
    test('TR picker mesajları path placeholder içerir', () async {
      final l10n = await AppLocalization.resolve();
      expect(l10n.isLoaded, isTrue);
      expect(
        l10n.translate(
          'field_sales.visit_mbt_attach_picked',
          args: {
            'action': 'Foto',
            'path': '/tmp/a.jpg',
          },
        ),
        'Foto eklendi: /tmp/a.jpg',
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
