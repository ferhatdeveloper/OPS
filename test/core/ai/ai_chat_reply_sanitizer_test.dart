// Dosya Adı: ai_chat_reply_sanitizer_test.dart
// Açıklama: Klon ID gizleme / TTS durum metni testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/ai/features/ai_chat_reply_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sample = '''
Son satış bilgileri aşağıdaki gibidir:
- **Sipariş ID:** ord_2
- **Müşteri ID:** cust_2
- **Sipariş Tarihi:** 28 Temmuz 2026
- **Toplam Tutar:** 120.0 TL
- **Durum:** Beklemede
Bu sipariş henüz onaylanmamış durumda.
''';

  test('forDisplay klon ID satırlarını çıkarır', () {
    final d = AiChatReplySanitizer.forDisplay(sample);
    expect(d.contains('ord_2'), isFalse);
    expect(d.contains('cust_2'), isFalse);
    expect(d.contains('Sipariş ID'), isFalse);
    expect(d.contains('Müşteri ID'), isFalse);
    expect(d.contains('Beklemede'), isTrue);
    expect(d.contains('120.0 TL'), isTrue);
  });

  test('forSpeech ID okumaz durum anlatır', () {
    final s = AiChatReplySanitizer.forSpeech(sample);
    expect(s.contains('ord_2'), isFalse);
    expect(s.contains('cust_2'), isFalse);
    expect(s.contains('**'), isFalse);
    expect(s.toLowerCase().contains('beklemede'), isTrue);
  });

  test('slimRowForPrompt internal key atar', () {
    final slim = AiChatReplySanitizer.slimRowForPrompt({
      'id': 'ord_2',
      'customer_id': 'cust_2',
      'customer_name': 'Anadolu Gıda',
      'status': 'pending',
      'total_amount': 120,
    });
    expect(slim.containsKey('id'), isFalse);
    expect(slim.containsKey('customer_id'), isFalse);
    expect(slim['customer_name'], 'Anadolu Gıda');
    expect(slim['status'], 'pending');
  });
}
