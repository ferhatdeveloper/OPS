// Dosya Adı: logo_connection_health_test.dart
// Açıklama: Logo REST bağlantı sağlık göstergesi birim testleri
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/core/logo/logo_connection_health.dart';

void main() {
  late int probeCalls;
  late DateTime clock;

  setUp(() {
    probeCalls = 0;
    clock = DateTime.utc(2026, 7, 29, 12);
  });

  LogoConnectionHealthChecker buildChecker({
    bool ok = true,
    bool authReady = true,
    String? detail,
    Object? throws,
    Duration minInterval = const Duration(seconds: 60),
  }) {
    return LogoConnectionHealthChecker(
      minInterval: minInterval,
      now: () => clock,
      probe: () async {
        probeCalls++;
        if (throws != null) throw throws;
        return ok
            ? LogoHealthProbeResult.online(
                detail: detail,
                authReady: authReady,
              )
            : LogoHealthProbeResult.offline(detail: detail);
      },
    );
  }

  group('LogoConnectionHealthChecker.check', () {
    test('başlangıç durumu bilinmiyor', () {
      final checker = buildChecker();
      expect(checker.last.status, LogoConnectionStatus.unknown);
      expect(checker.last.checkedAt, isNull);
      expect(probeCalls, 0);
    });

    test('ilk denetim probe çalıştırır ve yeşil durum döner', () async {
      final checker = buildChecker(detail: 'HTTP 200');

      final health = await checker.check();

      expect(probeCalls, 1);
      expect(health.status, LogoConnectionStatus.online);
      expect(health.isOnline, isTrue);
      expect(health.checkedAt, clock);
      expect(health.detail, 'HTTP 200');
    });

    test('probe başarısızsa kırmızı durum ve detay taşınır', () async {
      final checker = buildChecker(ok: false, detail: 'api_key gerekli');

      final health = await checker.check();

      expect(health.status, LogoConnectionStatus.offline);
      expect(health.isOnline, isFalse);
      expect(health.detail, 'api_key gerekli');
    });

    test('help başarılı ama OAuth eksikse kimlik uyarısı döner', () async {
      final checker = buildChecker(
        authReady: false,
        detail: 'client_id',
      );

      final health = await checker.check();

      expect(health.status, LogoConnectionStatus.credentialsMissing);
      expect(health.isOnline, isFalse);
      expect(
        health.labelKey,
        'field_sales.logo_connection_credentials_missing',
      );
      expect(health.detail, 'client_id');
    });

    test('probe istisna fırlatırsa kırmızı durur, hata sızdırmaz', () async {
      final checker = buildChecker(throws: StateError('kapalı'));

      final health = await checker.check();

      expect(health.status, LogoConnectionStatus.offline);
      expect(health.detail, isNotNull);
    });

    test('aralık içinde tekrar denetim probe çağırmaz', () async {
      final checker = buildChecker();
      await checker.check();

      clock = clock.add(const Duration(seconds: 30));
      final second = await checker.check();

      expect(probeCalls, 1);
      expect(second.checkedAt, DateTime.utc(2026, 7, 29, 12));
    });

    test('force ile aralık yok sayılır', () async {
      final checker = buildChecker();
      await checker.check();

      clock = clock.add(const Duration(seconds: 5));
      await checker.check(force: true);

      expect(probeCalls, 2);
      expect(checker.last.checkedAt, clock);
    });

    test('aralık geçtikten sonra yeniden denetler', () async {
      final checker = buildChecker(
        minInterval: const Duration(seconds: 60),
      );
      await checker.check();

      clock = clock.add(const Duration(seconds: 61));
      await checker.check();

      expect(probeCalls, 2);
    });

    test('eşzamanlı iki denetim tek probe çalıştırır', () async {
      final checker = buildChecker();

      await Future.wait([checker.check(), checker.check(force: true)]);

      expect(probeCalls, 1);
    });
  });

  group('LogoConnectionHealth.labelKey', () {
    test('her durum için field_sales l10n anahtarı tanımlı', () {
      for (final status in LogoConnectionStatus.values) {
        expect(
          LogoConnectionHealth(status: status).labelKey,
          startsWith('field_sales.logo_connection_'),
          reason: '$status için anahtar yok',
        );
      }
    });
  });
}
