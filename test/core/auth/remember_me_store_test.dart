// Dosya Adı: remember_me_store_test.dart
// Açıklama: Beni hatırla oturum saklama / temizleme birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/auth/remember_me_session.dart';
import 'package:exfin_ops/core/auth/remember_me_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('RememberMeStore', () {
    test('save + load: remember me açık ve geçerli oturum', () async {
      const store = RememberMeStore();
      await store.save(
        RememberMeSession(
          sessionToken: 'sid-1',
          username: 'plasiyer',
          userId: 'u1',
          role: 'salesperson',
          email: 'a@b.c',
          fullName: 'Ali',
          tenantCode: 'lovan',
        ),
        plainPassword: 'gizli',
      );

      expect(await store.isEnabled(), isTrue);
      expect(await store.canAutoLogin(), isTrue);

      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!.username, 'plasiyer');
      expect(loaded.sessionToken, 'sid-1');
      expect(loaded.tenantCode, 'lovan');
      expect(await store.loadPlainPassword(), 'gizli');
    });

    test('clear: oturum ve şifre silinir', () async {
      const store = RememberMeStore();
      await store.save(
        const RememberMeSession(
          sessionToken: 'sid-1',
          username: 'admin',
          userId: '1',
          role: 'admin',
          email: '',
          fullName: 'Admin',
          tenantCode: 'x',
        ),
        plainPassword: 'p',
      );
      await store.clear();

      expect(await store.isEnabled(), isFalse);
      expect(await store.canAutoLogin(), isFalse);
      expect(await store.load(), isNull);
      expect(await store.loadPlainPassword(), isNull);
    });

    test('sessionToken yoksa canAutoLogin false', () async {
      const store = RememberMeStore();
      await store.save(
        const RememberMeSession(
          sessionToken: '',
          username: 'admin',
          userId: '1',
          role: 'admin',
          email: '',
          fullName: 'Admin',
          tenantCode: 'x',
        ),
      );
      expect(await store.canAutoLogin(), isFalse);
    });

    test('disableWithoutClearingCredentials: bayrak kapanır', () async {
      const store = RememberMeStore();
      await store.save(
        const RememberMeSession(
          sessionToken: 'sid',
          username: 'u',
          userId: '1',
          role: 'admin',
          email: '',
          fullName: 'U',
          tenantCode: 't',
        ),
      );
      await store.setEnabled(false);
      expect(await store.isEnabled(), isFalse);
      expect(await store.canAutoLogin(), isFalse);
    });
  });
}
