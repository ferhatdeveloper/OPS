// Dosya Adı: announcement_campaign_row_test.dart
// Açıklama: Duyuru dens satırının campaigns SQLite map eşlemesi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/announcements/model/announcement_campaign_row.dart';

void main() {
  group('AnnouncementCampaignRow.fromCampaignMap', () {
    test('ISO tarihleri MBT DD-MM-YYYY gösterir; name başlık olur', () {
      final row = AnnouncementCampaignRow.fromCampaignMap({
        'id': 'c1',
        'name': 'Yaz Kampanyası',
        'start_date': '2026-01-27',
        'end_date': '2027-04-27',
        'is_active': 1,
      });

      expect(row.id, 'c1');
      expect(row.title, 'Yaz Kampanyası');
      expect(row.startDisplay, '27-01-2026');
      expect(row.endDisplay, '27-04-2027');
    });

    test('zaten DD-MM-YYYY olan tarihleri korur', () {
      final row = AnnouncementCampaignRow.fromCampaignMap({
        'id': 'c2',
        'name': 'Mart İndirim',
        'start_date': '01-03-2026',
        'end_date': '31-03-2026',
      });

      expect(row.startDisplay, '01-03-2026');
      expect(row.endDisplay, '31-03-2026');
    });

    test('boş name → boş title; null tarihler → boş string', () {
      final row = AnnouncementCampaignRow.fromCampaignMap({
        'id': 'c3',
        'name': null,
        'start_date': null,
        'end_date': null,
      });

      expect(row.title, '');
      expect(row.startDisplay, '');
      expect(row.endDisplay, '');
    });
  });

  group('AnnouncementCampaignRow.fromCampaignMaps', () {
    test('aktif satırları start_date azalan sırada döner', () {
      final rows = AnnouncementCampaignRow.fromCampaignMaps([
        {
          'id': 'old',
          'name': 'Eski',
          'start_date': '2025-01-01',
          'end_date': '2025-12-31',
          'is_active': 1,
        },
        {
          'id': 'off',
          'name': 'Kapalı',
          'start_date': '2026-06-01',
          'end_date': '2026-12-31',
          'is_active': 0,
        },
        {
          'id': 'new',
          'name': 'Yeni',
          'start_date': '2026-01-27',
          'end_date': '2027-04-27',
          'is_active': 1,
        },
      ]);

      expect(rows.map((r) => r.id).toList(), ['new', 'old']);
      expect(rows.first.title, 'Yeni');
    });
  });
}
