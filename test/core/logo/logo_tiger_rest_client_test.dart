// Dosya Adı: logo_tiger_rest_client_test.dart
// Açıklama: Logo Tiger client parse + mock HTTP birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:exfin_ops/core/logo/logo_tiger_config.dart';
import 'package:exfin_ops/core/logo/logo_tiger_rest_client.dart';
import 'package:exfin_ops/core/logo/logo_tiger_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LogoTigerRestClient.extractItems', () {
    test('items anahtarı', () {
      final list = LogoTigerRestClient.extractItems({
        'items': [
          {'CODE': 'P1'},
          {'CODE': 'P2'},
        ],
        'count': 2,
      });
      expect(list.length, 2);
      expect(list.first['CODE'], 'P1');
    });

    test('Items / düz liste', () {
      expect(
        LogoTigerRestClient.extractItems([
          {'CODE': 'A'},
        ]).single['CODE'],
        'A',
      );
      expect(
        LogoTigerRestClient.extractItems({
          'Items': [
            {'CODE': 'B'},
          ],
        }).single['CODE'],
        'B',
      );
    });

    test('extractCount', () {
      expect(LogoTigerRestClient.extractCount({'count': 12}), 12);
      expect(
        LogoTigerRestClient.extractCount({
          'Meta': {'Count': 3},
        }),
        3,
      );
    });
  });

  group('LogoTigerRestClient mock HTTP', () {
    late Dio dio;
    late LogoTigerRestClient client;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      dio = Dio(
        BaseOptions(
          baseUrl: 'http://logo.test/api/v1',
          validateStatus: (_) => true,
        ),
      );
      final store = LogoTigerSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );
      await store.save(
        const LogoTigerConfig(
          baseUrl: 'http://logo.test:32001',
          apiKey: 'test-api-key',
          username: 'LOGO',
          password: 'x',
          clientId: 'CID',
          clientSecret: 'SEC',
          firmNr: 1,
          periodNr: 1,
        ),
      );
      client = LogoTigerRestClient(
        store: store,
        dio: dio,
        config: const LogoTigerConfig(
          baseUrl: 'http://logo.test:32001',
          apiKey: 'test-api-key',
          username: 'LOGO',
          password: 'x',
          clientId: 'CID',
          clientSecret: 'SEC',
        ),
      );
    });

    test('pingHelp api_key query + 200 parse', () async {
      dio.httpClientAdapter = _MockAdapter((options) async {
        expect(options.uri.path, contains('/services/help'));
        expect(options.uri.queryParameters['api_key'], 'test-api-key');
        expect(options.uri.queryParameters['expandLevel'], 'full');
        return ResponseBody.fromString(
          jsonEncode({
            'swagger': '2.0',
            'info': {'title': 'Logo Objects Rest Service v1'},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final r = await client.pingHelp();
      expect(r.success, isTrue);
      expect(r.statusCode, 200);
      expect(r.asMap()['swagger'], '2.0');
    });

    test('obtainToken Authorization Bearer saklanır', () async {
      dio.httpClientAdapter = _MockAdapter((options) async {
        expect(options.path, '/token');
        expect(options.method, 'POST');
        final data = options.data;
        expect(data, isA<Map>());
        final map = Map<String, dynamic>.from(data as Map);
        expect(map['grant_type'], 'password');
        expect(map['client_id'], 'CID');
        return ResponseBody.fromString(
          jsonEncode({
            'access_token': 'abc.token',
            'expires_in': 3600,
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final r = await client.obtainToken();
      expect(r.success, isTrue);
      expect(r.asMap()['access_token'], 'abc.token');
    });

    test('listResource Bearer header + items parse', () async {
      var sawAuth = false;
      dio.httpClientAdapter = _MockAdapter((options) async {
        if (options.path == '/token') {
          return ResponseBody.fromString(
            jsonEncode({'access_token': 'tok', 'expires_in': 3600}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        if (options.path.contains('CompanyLogin')) {
          return ResponseBody.fromString('true', 200);
        }
        sawAuth =
            options.headers['Authorization']?.toString() == 'Bearer tok';
        expect(options.path, '/items');
        expect(options.queryParameters['limit'], isNotNull);
        return ResponseBody.fromString(
          jsonEncode({
            'items': [
              {'CODE': 'SKU1', 'NAME': 'Ürün 1'},
            ],
            'count': 1,
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final page = await client.listResource('items', limit: 10);
      expect(sawAuth, isTrue);
      expect(page.items.length, 1);
      expect(page.items.first['CODE'], 'SKU1');
      expect(page.count, 1);
    });

    test('createSalesOrder POST path + restRecord + 201 success', () async {
      RequestOptions? posted;
      dio.httpClientAdapter = _MockAdapter((options) async {
        if (options.path == '/token') {
          return ResponseBody.fromString(
            jsonEncode({'access_token': 'tok', 'expires_in': 3600}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        if (options.path.contains('CompanyLogin')) {
          return ResponseBody.fromString('true', 200);
        }
        posted = options;
        expect(options.method, 'POST');
        expect(options.path, '/salesOrders');
        expect(
          options.headers['Authorization']?.toString(),
          'Bearer tok',
        );
        final data = Map<String, dynamic>.from(options.data as Map);
        expect(data.containsKey('restRecord'), isTrue);
        final rr = Map<String, dynamic>.from(data['restRecord'] as Map);
        expect(rr['ARP_CODE'], 'C120');
        return ResponseBody.fromString(
          jsonEncode({'INTERNAL_REFERENCE': 99}),
          201,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final r = await client.createSalesOrder({
        'TYPE': 1,
        'NUMBER': '~',
        'DATE': '2026-07-28',
        'ARP_CODE': 'C120',
        'TRANSACTIONS': {
          'items': [
            {'TYPE': 0, 'MASTER_CODE': 'SKU1', 'QUANTITY': 1, 'PRICE': 10},
          ],
        },
      });
      expect(posted, isNotNull);
      expect(r.success, isTrue);
      expect(r.statusCode, 201);
      expect(r.asMap()['INTERNAL_REFERENCE'], 99);
    });

    test('createResource fail → success false (retry path)', () async {
      dio.httpClientAdapter = _MockAdapter((options) async {
        if (options.path == '/token') {
          return ResponseBody.fromString(
            jsonEncode({'access_token': 'tok', 'expires_in': 3600}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        if (options.path.contains('CompanyLogin')) {
          return ResponseBody.fromString('true', 200);
        }
        return ResponseBody.fromString(
          jsonEncode({
            'Message': 'Validation failed',
            'ModelState': {
              'ARP_CODE': ['required'],
            },
          }),
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final r = await client.createSalesInvoice({
        'TYPE': 8,
        'ARP_CODE': '',
        'TRANSACTIONS': {'items': []},
      });
      expect(r.success, isFalse);
      expect(r.statusCode, 400);
      expect(r.error, contains('required'));
    });
  });
}
