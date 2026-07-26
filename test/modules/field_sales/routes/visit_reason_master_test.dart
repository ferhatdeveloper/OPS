// Dosya Adı: visit_reason_master_test.dart
// Açıklama: ZIYARET SEBEBI master listesi birim testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/localization/app_localization.dart';
import 'package:exfin_ops/modules/field_sales/routes/model/visit_reason_master.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VisitReasonMaster', () {
    test('master kodları benzersiz ve dolu', () {
      final codes = VisitReasonMaster.codes;
      expect(codes, isNotEmpty);
      expect(codes.toSet().length, codes.length);
      expect(codes, contains('ROUTINE'));
      expect(codes, contains('COLLECTION'));
      expect(codes, contains('OTHER'));
    });

    test('contains ve byCode', () {
      expect(VisitReasonMaster.contains('ROUTINE'), isTrue);
      expect(VisitReasonMaster.contains(null), isFalse);
      expect(VisitReasonMaster.contains('NOPE'), isFalse);
      expect(VisitReasonMaster.byCode('ORDER')?.l10nKey,
          'field_sales.visit_reason_order');
    });

    test('TR etiketleri l10n ile çözülür', () async {
      final l10n = await AppLocalization.resolve();
      expect(l10n.isLoaded, isTrue);
      expect(
        VisitReasonMaster.labelOf(l10n, 'ROUTINE'),
        'Rutin Ziyaret',
      );
      expect(
        VisitReasonMaster.labelOf(l10n, 'ORDER'),
        'Sipariş Alma',
      );
      expect(
        l10n.translate('field_sales.visit_mbt_reason_select'),
        'Seçim',
      );

      final labeled = VisitReasonMaster.labeled(l10n);
      expect(labeled.length, VisitReasonMaster.options.length);
      expect(labeled.every((m) => m['code']!.isNotEmpty), isTrue);
      expect(labeled.every((m) => m['label']!.isNotEmpty), isTrue);
    });
  });
}
