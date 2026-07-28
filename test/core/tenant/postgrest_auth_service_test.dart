// Dosya Adı: postgrest_auth_service_test.dart
// Açıklama: bcrypt / SHA-256 şifre doğrulama birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:exfin_ops/core/tenant/postgrest_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  group('PostgrestAuthService.verifyPassword', () {
    test('bcrypt doğru şifre', () {
      final hash = BCrypt.hashpw('admin', BCrypt.gensalt());
      expect(PostgrestAuthService.verifyPassword('admin', hash), isTrue);
      expect(PostgrestAuthService.verifyPassword('wrong', hash), isFalse);
    });

    test('SHA-256 doğru şifre', () {
      final hash = sha256.convert(utf8.encode('secret')).toString();
      expect(PostgrestAuthService.verifyPassword('secret', hash), isTrue);
      expect(PostgrestAuthService.verifyPassword('nope', hash), isFalse);
    });

    test('RetailEX lovan admin hash örneği', () {
      const hash =
          r'$2a$06$C5F0st7vyCiKzRXLOt4LbOcHKz8Ibk5TcS/l22ZjCn/XYqXopWf0S';
      expect(PostgrestAuthService.verifyPassword('admin', hash), isTrue);
    });
  });
}
