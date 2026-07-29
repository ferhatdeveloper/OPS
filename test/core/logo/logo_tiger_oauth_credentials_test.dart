// Dosya Adı: logo_tiger_oauth_credentials_test.dart
// Açıklama: Logo panel OAuth client_id/secret format ayrıştırma testleri
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'dart:convert';

import 'package:exfin_ops/core/logo/logo_tiger_oauth_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogoTigerOAuthCredentials', () {
    test('panel Base64 (CLIENTID~SECRET) → client_id ve secret ayırır', () {
      // Logo paneli: Base64(clientId + "~" + secret) — sentetik örnek.
      final panelB64 = base64Encode(utf8.encode('DEMO~sec+retValue='));
      final parsed = LogoTigerOAuthCredentials.tryParsePanelKey(panelB64);
      expect(parsed, isNotNull);
      expect(parsed!.clientId, 'DEMO');
      expect(parsed.clientSecret, 'sec+retValue=');
    });

    test('eski CLIENTID+SECRET metni de ayrılır', () {
      final parsed = LogoTigerOAuthCredentials.tryParsePanelKey(
        'ARZEN+plainSecret123',
      );
      expect(parsed, isNotNull);
      expect(parsed!.clientId, 'ARZEN');
      expect(parsed.clientSecret, 'plainSecret123');
    });

    test('yalnız secret (Base64 bütünü değil) → null; uygulama olduğu gibi kullanır',
        () {
      expect(
        LogoTigerOAuthCredentials.tryParsePanelKey('only-secret-no-plus'),
        isNull,
      );
    });

    test('token form body client_secret ham secret bekler (panel B64 değil)', () {
      final panelB64 = base64Encode(utf8.encode('CID~REALSECRET'));
      final parsed = LogoTigerOAuthCredentials.tryParsePanelKey(panelB64)!;
      expect(parsed.clientSecret, 'REALSECRET');
      expect(parsed.clientSecret, isNot(panelB64));
    });
  });
}
