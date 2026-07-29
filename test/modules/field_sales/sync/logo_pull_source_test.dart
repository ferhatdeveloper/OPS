// Dosya Adı: logo_pull_source_test.dart
// Açıklama: Logo indirme kaynak kataloğu birim testleri
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/sync/model/logo_pull_source.dart';

void main() {
  group('LogoPullSourceCatalog.forMode', () {
    test('Tiger REST modunda MBT dokuz alınacak satırı sırayla listeler', () {
      expect(
        LogoPullSourceCatalog.forMode(tigerEnabled: true),
        const <LogoPullSource>[
          LogoPullSource.products,
          LogoPullSource.customers,
          LogoPullSource.cash,
          LogoPullSource.banks,
          LogoPullSource.currency,
          LogoPullSource.general,
          LogoPullSource.variants,
          LogoPullSource.routes,
          LogoPullSource.announcements,
        ],
      );
    });

    test('sipariş MBT alınacak listesinde yoktur (gönderilecek tarafı)', () {
      expect(
        LogoPullSourceCatalog.forMode(tigerEnabled: true),
        isNot(contains(LogoPullSource.orders)),
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

    test('kasa / banka / döviz / genel Tiger pull ile çekilebilir', () {
      for (final source in const [
        LogoPullSource.cash,
        LogoPullSource.banks,
        LogoPullSource.currency,
        LogoPullSource.general,
      ]) {
        expect(
          LogoPullSourceCatalog.supportsTiger(source),
          isTrue,
          reason: '$source Tiger pull kapsamında olmalı',
        );
      }
    });

    test('ekran listesinden çıkan sipariş / ambar / plasiyer çekilebilir kalır',
        () {
      for (final source in const [
        LogoPullSource.orders,
        LogoPullSource.warehouses,
        LogoPullSource.salesmen,
      ]) {
        expect(
          LogoPullSourceCatalog.supportsTiger(source),
          isTrue,
          reason: '$source için pull yeteneği korunmalı',
        );
      }
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

  group('LogoPullSourceCatalog yakında / merkez kaynak', () {
    test('varyant, rota ve duyurular yakında olarak işaretlidir', () {
      for (final source in const [
        LogoPullSource.variants,
        LogoPullSource.routes,
        LogoPullSource.announcements,
      ]) {
        expect(LogoPullSourceCatalog.isComingSoon(source), isTrue);
        expect(LogoPullSourceCatalog.supportsTiger(source), isFalse);
      }
    });

    test('rota ve duyurular merkez kaynaklıdır, varyant değildir', () {
      expect(
        LogoPullSourceCatalog.isCenterSource(LogoPullSource.routes),
        isTrue,
      );
      expect(
        LogoPullSourceCatalog.isCenterSource(LogoPullSource.announcements),
        isTrue,
      );
      expect(
        LogoPullSourceCatalog.isCenterSource(LogoPullSource.variants),
        isFalse,
      );
    });

    test('bekleyen satır mesaj anahtarı kaynağına göre seçilir', () {
      expect(
        LogoPullSourceCatalog.pendingMessageKey(LogoPullSource.variants),
        LogoPullSourceCatalog.comingSoonKey,
      );
      expect(
        LogoPullSourceCatalog.pendingMessageKey(LogoPullSource.routes),
        LogoPullSourceCatalog.centerSourceKey,
      );
    });

    test('çekilebilir satırlar yakında sayılmaz', () {
      for (final source in LogoPullSourceCatalog.tigerSources) {
        if (LogoPullSourceCatalog.isComingSoon(source)) continue;
        expect(
          LogoPullSourceCatalog.supportsTiger(source),
          isTrue,
          reason: '$source ne çekilebilir ne yakında',
        );
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

    test('Tiger modunda MBT başlıkları kullanılır', () {
      expect(
        LogoPullSourceCatalog.titleKey(LogoPullSource.products),
        'field_sales.logo_pull_mbt_stock',
      );
      expect(
        LogoPullSourceCatalog.titleKey(LogoPullSource.customers),
        'field_sales.logo_pull_mbt_customers',
      );
      expect(
        LogoPullSourceCatalog.titleKey(LogoPullSource.general),
        'field_sales.logo_pull_mbt_general',
      );
    });

    test('ExfinApi modunda eski satır başlıkları korunur', () {
      expect(
        LogoPullSourceCatalog.titleKey(
          LogoPullSource.products,
          tigerEnabled: false,
        ),
        'field_sales.product_list',
      );
      expect(
        LogoPullSourceCatalog.titleKey(
          LogoPullSource.customers,
          tigerEnabled: false,
        ),
        'field_sales.customer_list',
      );
      expect(
        LogoPullSourceCatalog.titleKey(
          LogoPullSource.stock,
          tigerEnabled: false,
        ),
        'field_sales.stock',
      );
    });

    test('MBT satır başlıkları birbirinden farklıdır', () {
      final keys = LogoPullSourceCatalog.tigerSources
          .map(LogoPullSourceCatalog.titleKey)
          .toList();
      expect(keys.toSet().length, keys.length);
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

    test('eski kalıcılık anahtarları korunur (indirme geçmişi kaybolmaz)', () {
      expect(
        LogoPullSourceCatalog.fromStorageKey('products'),
        LogoPullSource.products,
      );
      expect(
        LogoPullSourceCatalog.fromStorageKey('customers'),
        LogoPullSource.customers,
      );
      expect(
        LogoPullSourceCatalog.fromStorageKey('warehouses'),
        LogoPullSource.warehouses,
      );
      expect(
        LogoPullSourceCatalog.fromStorageKey('salesmen'),
        LogoPullSource.salesmen,
      );
      expect(
        LogoPullSourceCatalog.fromStorageKey('orders'),
        LogoPullSource.orders,
      );
      expect(
        LogoPullSourceCatalog.fromStorageKey('stock'),
        LogoPullSource.stock,
      );
      expect(
        LogoPullSourceCatalog.fromStorageKey('balances'),
        LogoPullSource.balances,
      );
    });

    test('bilinmeyen storageKey null döner', () {
      expect(LogoPullSourceCatalog.fromStorageKey('prices'), isNull);
      expect(LogoPullSourceCatalog.fromStorageKey(''), isNull);
    });
  });
}
