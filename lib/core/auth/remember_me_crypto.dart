// Dosya Adı: remember_me_crypto.dart
// Açıklama: Beni hatırla şifre obfuscation (PostgREST JWT yok; yerel saklama)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28
//
// Güvenlik notu: PostgREST girişinde JWT dönmüyor; otomatik giriş için
// oturum token (session_id) tercih edilir. Şifre yalnızca yedek / form
// doldurma için obfuscate edilir — OS keychain (flutter_secure_storage)
// yoksa bu obfuscation gerçek şifreleme değildir; cihaz erişimi olan
// saldırgana karşı sınırlı koruma sağlar.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// {@template remember_me_crypto}
/// Şifreyi anahtar materyalinden türetilen XOR akışı ile obfuscate eder.
///
/// Kullanım örneği:
/// ```dart
/// final c = RememberMeCrypto.encrypt('x', keyMaterial: 'device');
/// print(RememberMeCrypto.decrypt(c, keyMaterial: 'device')); // x
/// ```
/// {@endtemplate}
class RememberMeCrypto {
  RememberMeCrypto._();

  static const String _appSalt = 'exfinops.remember.me.v1';

  /// {@template remember_me_crypto_encrypt}
  /// Düz metni Base64 obfuscation string’e çevirir.
  ///
  /// Parametreler:
  /// - [plain]: Düz şifre
  /// - [keyMaterial]: Cihaz / uygulama anahtar tohumu
  ///
  /// Dönüş değeri:
  /// - [String]: Ciphertext (boş plain → boş)
  /// {@endtemplate}
  static String encrypt(String plain, {required String keyMaterial}) {
    if (plain.isEmpty) return '';
    final key = _deriveKey(keyMaterial);
    final bytes = utf8.encode(plain);
    final out = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i++) {
      out[i] = bytes[i] ^ key[i % key.length];
    }
    return base64Encode(out);
  }

  /// {@template remember_me_crypto_decrypt}
  /// Obfuscation string’i düz metne çevirir.
  ///
  /// Parametreler:
  /// - [cipher]: encrypt çıktısı
  /// - [keyMaterial]: Aynı tohum
  ///
  /// Dönüş değeri:
  /// - [String]: Düz şifre; geçersiz Base64 → boş
  /// {@endtemplate}
  static String decrypt(String cipher, {required String keyMaterial}) {
    if (cipher.isEmpty) return '';
    try {
      final key = _deriveKey(keyMaterial);
      final bytes = base64Decode(cipher);
      final out = Uint8List(bytes.length);
      for (var i = 0; i < bytes.length; i++) {
        out[i] = bytes[i] ^ key[i % key.length];
      }
      return utf8.decode(out);
    } catch (_) {
      return '';
    }
  }

  static List<int> _deriveKey(String keyMaterial) {
    final digest = sha256.convert(utf8.encode('$_appSalt|$keyMaterial'));
    return digest.bytes;
  }
}
