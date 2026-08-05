// Dosya Adı: logo_tiger_urls_test.dart
// Açıklama: Logo Tiger URL normalize / header / query birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'package:exfin_ops/core/logo/logo_tiger_urls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogoTigerUrls defaults', () {
    test('varsayılan host 185.206.80.132, port 32001', () {
      expect(LogoTigerUrls.defaultHost, '185.206.80.132');
      expect(LogoTigerUrls.defaultPort, 32001);
      expect(
        LogoTigerUrls.composeBaseUrl(LogoTigerUrls.defaultHost),
        'http://185.206.80.132:32001/api/v1',
      );
    });
  });

  group('LogoTigerUrls.normalizeBaseUrl', () {
    test('host:port → /api/v1', () {
      expect(
        LogoTigerUrls.normalizeBaseUrl('http://192.0.2.10:32001'),
        'http://192.0.2.10:32001/api/v1',
      );
    });

    test('help path kırpılır', () {
      expect(
        LogoTigerUrls.normalizeBaseUrl(
          'http://host:32001/api/v1/services/help?expandLevel=full',
        ),
        'http://host:32001/api/v1',
      );
    });

    test('şemasız host tamamlanır', () {
      expect(
        LogoTigerUrls.normalizeBaseUrl('127.0.0.1:32001'),
        'http://127.0.0.1:32001/api/v1',
      );
    });

    test('port yoksa varsayılan 32001', () {
      expect(
        LogoTigerUrls.normalizeBaseUrl(LogoTigerUrls.defaultHost),
        'http://185.206.80.132:32001/api/v1',
      );
    });

    test('düz IP:port yeterli', () {
      expect(
        LogoTigerUrls.normalizeBaseUrl('185.206.80.132:32001'),
        'http://185.206.80.132:32001/api/v1',
      );
    });

    test('query ve help path kırpılır', () {
      expect(
        LogoTigerUrls.normalizeBaseUrl(
          'http://host:32001/api/v1/services/help?expandLevel=full&api_key=x',
        ),
        'http://host:32001/api/v1',
      );
    });

    test('boş → boş', () {
      expect(LogoTigerUrls.normalizeBaseUrl('  '), '');
    });
  });

  group('LogoTigerUrls host/port', () {
    test('composeBaseUrl host + varsayılan port', () {
      expect(
        LogoTigerUrls.composeBaseUrl(LogoTigerUrls.defaultHost),
        'http://185.206.80.132:32001/api/v1',
      );
    });

    test('composeBaseUrl özel port', () {
      expect(
        LogoTigerUrls.composeBaseUrl('10.0.0.1', port: 8080),
        'http://10.0.0.1:8080/api/v1',
      );
    });

    test('splitHostPort', () {
      final s = LogoTigerUrls.splitHostPort('http://h:32001/api/v1');
      expect(s.host, 'h');
      expect(s.port, 32001);
    });

    test('parseUserInput düz adres + help linkinden api_key', () {
      final p = LogoTigerUrls.parseUserInput(
        '185.206.80.132:32001/api/v1/services/help'
        '?expandLevel=full&api_key=logotigerrestservice',
      );
      expect(p.baseUrl, 'http://185.206.80.132:32001/api/v1');
      expect(p.apiKey, 'logotigerrestservice');
      expect(p.host, '185.206.80.132');
      expect(p.port, 32001);
    });

    test('displayPlain şemasız host:port', () {
      expect(
        LogoTigerUrls.displayPlain('http://host:32001/api/v1'),
        'host:32001',
      );
    });
  });

  group('LogoTigerUrls.helpUri', () {
    test('api_key query ayrı alan', () {
      final uri = LogoTigerUrls.helpUri(
        'http://host:32001',
        apiKey: 'my-key',
      );
      expect(uri.path, contains('/services/help'));
      expect(uri.queryParameters['expandLevel'], 'full');
      expect(uri.queryParameters['api_key'], 'my-key');
      expect(uri.toString(), isNot(contains('logotigerrestservice')));
    });
  });

  group('LogoTigerUrls.authHeaders', () {
    test('Bearer ekler', () {
      final h = LogoTigerUrls.authHeaders('tok123');
      expect(h['Authorization'], 'Bearer tok123');
      expect(h['Accept'], 'application/json');
    });

    test('token yoksa Authorization yok', () {
      final h = LogoTigerUrls.authHeaders(null);
      expect(h.containsKey('Authorization'), isFalse);
    });
  });

  group('LogoTigerUrls resource paths', () {
    test('items ve services fallback', () {
      expect(LogoTigerUrls.resourcePath('items'), '/items');
      expect(
        LogoTigerUrls.servicesResourcePath('items'),
        '/services/items',
      );
    });

    test('clampLimit', () {
      expect(LogoTigerUrls.clampLimit(null), 25);
      expect(LogoTigerUrls.clampLimit(100), 25);
      expect(LogoTigerUrls.clampLimit(0), 1);
      expect(LogoTigerUrls.clampLimit(10), 10);
    });
  });

  group('encodeQuery', () {
    test('boş değer atılır', () {
      final q = LogoTigerUrls.encodeQuery({
        'limit': '10',
        'api_key': '',
        'q': 'CODE like A*',
      });
      expect(q.contains('limit=10'), isTrue);
      expect(q.contains('api_key'), isFalse);
      expect(q.contains('q='), isTrue);
    });
  });
}
