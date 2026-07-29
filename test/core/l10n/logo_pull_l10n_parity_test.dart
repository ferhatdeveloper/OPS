// Dosya Adı: logo_pull_l10n_parity_test.dart
// Açıklama: Logo indirme / bağlantı / kiracı kaydı anahtarlarının tüm dillerde varlığı
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/core/logo/logo_connection_health.dart';
import 'package:exfin_ops/core/tenant/tenant_logo_config_source.dart';
import 'package:exfin_ops/modules/field_sales/sync/model/logo_pull_source.dart';

/// [_requiredKeys]: Ekranlarda kullanılan yeni `field_sales` yaprak anahtarları
const List<String> _requiredKeys = [
  'logo_pull_warehouses',
  'logo_pull_salesmen',
  'logo_pull_orders',
  'logo_pull_download_one',
  'logo_pull_download_all',
  'logo_pull_last_update',
  'logo_pull_never',
  'logo_pull_record_count',
  'logo_pull_unsupported',
  'logo_connection_online',
  'logo_connection_offline',
  'logo_connection_unknown',
  'logo_connection_checking',
  'logo_connection_refresh',
  'logo_registry_fetch',
  'logo_registry_fetching',
  'logo_registry_fetch_ok',
  'logo_registry_fetch_cached',
  'logo_registry_no_tenant',
  'logo_registry_not_found',
  'logo_registry_apply_failed',
  'logo_registry_overwrite_title',
  'logo_registry_overwrite_body',
  'logo_registry_overwrite_confirm',
  'logo_config_source_label',
  'logo_config_source_manual',
  'logo_config_source_registry',
  'logo_config_source_legacy',
  'logo_config_source_none',
];

Map<String, dynamic> _fieldSales(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  expect(decoded, isA<Map>(), reason: '${file.path} geçerli JSON değil');
  final root = Map<String, dynamic>.from(decoded as Map);
  final section = root['field_sales'];
  expect(section, isA<Map>(), reason: '${file.path} field_sales eksik');
  return Map<String, dynamic>.from(section as Map);
}

void main() {
  late List<File> files;

  setUpAll(() {
    files = Directory('assets/translations')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    expect(files, isNotEmpty);
  });

  group('Logo indirme l10n yayılımı', () {
    test('tüm dil dosyaları yeni anahtarları içerir', () {
      final missing = <String>[];
      for (final file in files) {
        final section = _fieldSales(file);
        for (final key in _requiredKeys) {
          final value = section[key];
          if (value == null || '$value'.trim().isEmpty) {
            missing.add('${file.uri.pathSegments.last}: $key');
          }
        }
      }
      expect(missing, isEmpty, reason: 'eksik çeviri: ${missing.join(', ')}');
    });

    test('yer tutucu içeren anahtarlar her dilde yer tutucuyu korur', () {
      const placeholders = {
        'logo_pull_last_update': '{time}',
        'logo_pull_record_count': '{count}',
        'logo_config_source_label': '{source}',
      };
      for (final file in files) {
        final section = _fieldSales(file);
        placeholders.forEach((key, token) {
          expect(
            '${section[key]}',
            contains(token),
            reason: '${file.uri.pathSegments.last} → $key yer tutucusu yok',
          );
        });
      }
    });
  });

  group('Kod tarafındaki anahtarlar çeviri dosyalarıyla eşleşir', () {
    test('kaynak başlıkları tr ve en içinde tanımlı', () {
      final tr = _fieldSales(File('assets/translations/tr.json'));
      final en = _fieldSales(File('assets/translations/en.json'));
      for (final source in LogoPullSource.values) {
        final leaf = LogoPullSourceCatalog.titleKey(source).split('.').last;
        expect(tr[leaf], isNotNull, reason: 'tr.json eksik: $leaf');
        expect(en[leaf], isNotNull, reason: 'en.json eksik: $leaf');
      }
    });

    test('bağlantı durumu ve ayar kaynağı etiketleri tanımlı', () {
      final tr = _fieldSales(File('assets/translations/tr.json'));
      for (final status in LogoConnectionStatus.values) {
        final leaf =
            LogoConnectionHealth(status: status).labelKey.split('.').last;
        expect(tr[leaf], isNotNull, reason: 'tr.json eksik: $leaf');
      }
      for (final source in TenantLogoConfigSource.values) {
        final leaf =
            TenantLogoConfigSourceResolver.labelKey(source).split('.').last;
        expect(tr[leaf], isNotNull, reason: 'tr.json eksik: $leaf');
      }
      expect(
        tr[LogoPullSourceCatalog.unsupportedKey.split('.').last],
        isNotNull,
      );
    });
  });
}
