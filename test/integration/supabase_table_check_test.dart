// Dosya Adı: supabase_table_check_test.dart
// Açıklama: Supabase'te SQLite tablolalarının varlığını otomatik test eden dosya
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  // Test edilecek tablo isimleri
  final tablolar = [
    'companies',
    'menu',
    'settings',
    'api_config',
    'languages',
    'translations',
  ];

  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://ngwifzvociljnrliuzbd.supabase.co',
      anonKey:
          'YOUR_SUPABASE_ANON_KEY',
    );
  });

  for (final tablo in tablolar) {
    test('Supabase tablosu var mı: $tablo', () async {
      try {
        final data = await Supabase.instance.client
            .from(tablo)
            .select()
            .limit(1)
            .maybeSingle();
        // Eğer tablo yoksa hata fırlatır
        expect(data, isNotNull,
            reason: 'Tabloya erişilemiyor veya tablo yok: $tablo');
      } catch (e) {
        fail('Tabloya erişilemiyor veya tablo yok: $tablo\nHata: $e');
      }
    });
  }
}
