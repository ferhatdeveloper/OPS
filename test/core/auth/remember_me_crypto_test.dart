// Dosya Adı: remember_me_crypto_test.dart
// Açıklama: Beni hatırla şifre obfuscation birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/auth/remember_me_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RememberMeCrypto', () {
    test('encrypt/decrypt roundtrip', () {
      const plain = 'Sifre!123';
      final enc = RememberMeCrypto.encrypt(plain, keyMaterial: 'device-key');
      expect(enc, isNot(equals(plain)));
      expect(
        RememberMeCrypto.decrypt(enc, keyMaterial: 'device-key'),
        plain,
      );
    });

    test('yanlış anahtar çözemez veya boş döner', () {
      final enc = RememberMeCrypto.encrypt('secret', keyMaterial: 'a');
      final wrong = RememberMeCrypto.decrypt(enc, keyMaterial: 'b');
      expect(wrong, isNot(equals('secret')));
    });

    test('boş şifre → boş ciphertext', () {
      expect(RememberMeCrypto.encrypt('', keyMaterial: 'k'), isEmpty);
      expect(RememberMeCrypto.decrypt('', keyMaterial: 'k'), isEmpty);
    });
  });
}
