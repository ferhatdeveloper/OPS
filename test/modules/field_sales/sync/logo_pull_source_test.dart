// Dosya Adı: logo_pull_source_test.dart
// Açıklama: Logo indirme kaynak kataloğu birim testleri
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/sync/model/logo_pull_source.dart';

void main() {
  group('LogoPullSourceCatalog.forMode', () {
    test('Tiger REST modunda pull sync yeteneklerini birebir yansıtır', () {
      expect(
        LogoPullSourceCatalog.forMode(tigerEnabled: true),
        const <LogoPullSource>[
          LogoPullSource.customers,
          LogoPullSource.products,
          LogoPullSource.warehouses,
          LogoPullSource.salesmen,
          LogoPullSource.orders,
        ],
      );
    });

    test('ExfinApi modunda yalnızca middleware kaynakları listelenir', () {
      expect(
        LogoPullSourceCatalog.forMode(tigerEnabled: false),
        const <LogoPullSource>[
          LogoPullSource.customers,
          LogoPullSource.products,
          LogoPullSource.stock,
          LogoPullSource.balances,
        ],
      );
    });
  });

  group('LogoPullSourceCatalog yetenek sınırları', () {
    test('stok ve bakiye Tiger pull kaynağı değildir', () {
      expect(
        LogoPullSourceCatalog.supportsTiger(LogoPullSource.stock),
        isFalse,
      );
      expect(
        LogoPullSourceCatalog.supportsTiger(LogoPullSource.balances),
        isFalse,
      );
    });

    test('plasiyer / depo / sipariş ExfinApi kaynağı değildir', () {
      expect(
        LogoPullSourceCatalog.supportsExfin(LogoPullSource.salesmen),
        isFalse,
      );
      expect(
        LogoPullSourceCatalog.supportsExfin(LogoPullSource.warehouses),
        isFalse,
      );
      expect(
        LogoPullSourceCatalog.supportsExfin(LogoPullSource.orders),
        isFalse,
      );
    });

    test('cari ve ürün her iki bağlantı türünde de desteklenir', () {
      for (final source in const [
        LogoPullSource.customers,
        LogoPullSource.products,
      ]) {
        expect(LogoPullSourceCatalog.supportsTiger(source), isTrue);
        expect(LogoPullSourceCatalog.supportsExfin(source), isTrue);
      }
    });
  });

  group('LogoPullSourceCatalog anahtarları', () {
    test('her kaynak için field_sales l10n başlık anahtarı tanımlı', () {
      for (final source in LogoPullSource.values) {
        expect(
          LogoPullSourceCatalog.titleKey(source),
          startsWith('field_sales.'),
          reason: '$source için başlık anahtarı yok',
        );
      }
    });

    test('storageKey benzersiz ve gidiş dönüşü kararlı', () {
      final keys = <String>{};
      for (final source in LogoPullSource.values) {
        final key = LogoPullSourceCatalog.storageKey(source);
        expect(key, isNotEmpty);
        expect(keys.add(key), isTrue, reason: '$key yinelendi');
        expect(LogoPullSourceCatalog.fromStorageKey(key), source);
      }
    });

    test('bilinmeyen storageKey null döner', () {
      expect(LogoPullSourceCatalog.fromStorageKey('prices'), isNull);
      expect(LogoPullSourceCatalog.fromStorageKey(''), isNull);
    });
  });
}
