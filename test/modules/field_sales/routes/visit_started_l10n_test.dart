// Dosya Adı: visit_started_l10n_test.dart
// Açıklama: Ziyaret başlatma bildirim/gamification key'lerinin resolve çevirisi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/localization/app_localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('visit_started l10n (AppLocalization.resolve)', () {
    test('TR key’ler hardcoded metin yerine çözülür', () async {
      final l10n = await AppLocalization.resolve();

      expect(l10n.isLoaded, isTrue);
      expect(
        l10n.translate('field_sales.visit_started_notif_title'),
        'Ziyaret Başladı',
      );
      expect(
        l10n.translate('field_sales.visit_started_notif_body'),
        'Müşteri ziyareti başarıyla başlatıldı ve takip ediliyor.',
      );
      expect(
        l10n.translate('field_sales.visit_started_points_reason'),
        'Ziyaret Başlatıldı',
      );
      expect(AppLocalization.instance.isLoaded, isTrue);
    });

    test('EN locale ile visit_started key’ler İngilizce döner', () async {
      final en = AppLocalization(const Locale('en', 'US'));
      final ok = await en.load();
      expect(ok, isTrue);

      expect(
        en.translate('field_sales.visit_started_notif_title'),
        'Visit Started',
      );
      expect(
        en.translate('field_sales.visit_started_points_reason'),
        'Visit Started',
      );
    });
  });
}
