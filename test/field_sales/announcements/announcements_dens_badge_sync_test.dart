// Dosya Adı: announcements_dens_badge_sync_test.dart
// Açıklama: Dashboard Duyurular badge adedi dens listesi ile senkron
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/announcements/model/campaign_announcement_seed.dart';
import 'package:exfin_ops/modules/field_sales/announcements/view/announcements_screen.dart';

void main() {
  group('AnnouncementsScreen densCount (SQLite cache)', () {
    test('applyDensCacheFromMaps densCount = densRows.length', () {
      final n = AnnouncementsScreen.applyDensCacheFromMaps(
        CampaignAnnouncementSeed.defaultMaps,
      );
      expect(n, AnnouncementsScreen.densRows.length);
      expect(AnnouncementsScreen.densCount, greaterThan(0));
      expect(AnnouncementsScreen.densCount, n);
    });

    test('dens satırında kampanya adı · başlangıç · bitiş dolu', () {
      AnnouncementsScreen.applyDensCacheFromMaps(
        CampaignAnnouncementSeed.defaultMaps,
      );
      for (final row in AnnouncementsScreen.densRows) {
        expect(row.title, isNotEmpty);
        expect(row.startDisplay, isNotEmpty);
        expect(row.endDisplay, isNotEmpty);
      }
      expect(
        AnnouncementsScreen.densRows.first.startDisplay,
        '27-01-2026',
      );
      expect(
        AnnouncementsScreen.densRows.first.endDisplay,
        '27-04-2027',
      );
    });

    test('pasif kampanya badge sayısına girmez', () {
      final n = AnnouncementsScreen.applyDensCacheFromMaps([
        {
          'id': 'off',
          'name': 'Kapalı',
          'start_date': '2026-01-01',
          'end_date': '2026-12-31',
          'is_active': 0,
        },
      ]);
      expect(n, 0);
      expect(AnnouncementsScreen.densCount, 0);
    });
  });
}
