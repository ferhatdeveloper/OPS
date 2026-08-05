// Dosya Adı: day_status_l10n_test.dart
// Açıklama: MBT gün başla/bitir l10n anahtarlarının resolve testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/localization/app_localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('day_status MBT l10n', () {
    test('TR MBT alan etiketleri çözülür', () async {
      final l10n = await AppLocalization.resolve();
      expect(l10n.isLoaded, isTrue);
      expect(l10n.translate('field_sales.day_plate_label'), 'Plaka');
      expect(
        l10n.translate('field_sales.day_start_km_label'),
        'Başlangıç KM',
      );
      expect(l10n.translate('field_sales.day_end_km_label'), 'Bitiş KM');
      expect(
        l10n.translate('field_sales.day_completed_label'),
        'Tamamlandı?',
      );
      expect(l10n.translate('common.save'), 'Kaydet');
      expect(
        l10n.translate('field_sales.day_end_km_invalid'),
        'Bitiş KM başlangıçtan küçük olamaz.',
      );
      expect(
        l10n.translate('field_sales.day_vehicle_select_title'),
        'Araç seç',
      );
      expect(
        l10n.translate('field_sales.day_vehicle_manual_title'),
        'Araç kartı',
      );
    });
  });
}
