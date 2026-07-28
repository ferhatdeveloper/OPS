// Dosya Adı: postgres_service_web_host_test.dart
// Açıklama: Yerel PG host çözümlemesi (web’de Platform yok)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/service/postgres_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveLocalPgHost boş değil (VM/test ortamı)', () {
    final host = PostgresService.resolveLocalPgHost();
    expect(host, isNotEmpty);
    expect(host == '127.0.0.1' || host == '10.0.2.2', isTrue);
  });
}
