// Dosya Adı: logo_tiger_rest_client.dart
// Açıklama: Logo Tiger Objects REST istemcisi (token, help, list, create)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'logo_tiger_config.dart';
import 'logo_tiger_settings_store.dart';
import 'logo_tiger_urls.dart';

/// {@template logo_tiger_result}
/// Tiger REST çağrı sonucu — exception fırlatmaz.
/// {@endtemplate}
class LogoTigerResult {
  final bool success;
  final dynamic data;
  final String? error;
  final int? statusCode;

  const LogoTigerResult({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  factory LogoTigerResult.ok(dynamic data, {int? statusCode}) =>
      LogoTigerResult(success: true, data: data, statusCode: statusCode);

  factory LogoTigerResult.fail(
    String error, {
    int? statusCode,
    dynamic data,
  }) =>
      LogoTigerResult(
        success: false,
        error: error,
        statusCode: statusCode,
        data: data,
      );

  /// Liste öğelerini Map listesine çevirir (items/Items/data).
  List<Map<String, dynamic>> asMapList() {
    return LogoTigerRestClient.extractItems(data);
  }

  Map<String, dynamic> asMap() {
    if (data is Map<String, dynamic>) return data as Map<String, dynamic>;
    if (data is Map) return Map<String, dynamic>.from(data as Map);
    return {};
  }
}

/// {@template logo_tiger_list_page}
/// Sayfalı liste sonucu.
/// {@endtemplate}
class LogoTigerListPage {
  final int? count;
  final List<Map<String, dynamic>> items;
  final dynamic raw;

  const LogoTigerListPage({
    required this.items,
    this.count,
    this.raw,
  });
}

/// {@template logo_tiger_rest_client}
/// RetailEX `logoRestApi` Dart karşılığı.
/// Auth: POST `/token` + GET `/methods/CompanyLogin/{firm}/{period}`.
/// Liste: GET `/{resource}` (fallback `/services/{resource}`).
///
/// Kullanım örneği:
/// ```dart
/// final client = LogoTigerRestClient();
/// final help = await client.pingHelp();
/// ```
/// {@endtemplate}
class LogoTigerRestClient {
  /// Önemli kaynaklar (RetailEX LOGO_KEY_RESOURCES alt kümesi + ambar).
  static const List<String> keyResources = [
    'items',
    'Arps',
    'salesOrders',
    'purchaseOrders',
    'locationCodes',
    'itemSlips',
    'unitSets',
    'salesInvoices',
    'salesmen',
  ];

  /// Logo plasiyer / salesman resource adayları (sıra önemli).
  static const List<String> salesmanResourceCandidates = [
    'salesmen',
    'Salesmen',
    'salesMan',
    'SLSMAN',
  ];

  /// Kasa / safe resource adayları (404’te sessizce sonraki).
  static const List<String> cashResourceCandidates = [
    'safeDeposits',
    'safes',
    'cashSafes',
    'SafeDeposits',
    'Safes',
  ];

  /// Banka hesap / bank resource adayları.
  static const List<String> bankResourceCandidates = [
    'bankAccounts',
    'banks',
    'BankAccounts',
    'Banks',
  ];

  /// Döviz / kur resource adayları.
  static const List<String> currencyResourceCandidates = [
    'currencies',
    'currencyRates',
    'Currencies',
    'CurrencyRates',
  ];

  /// Birim seti resource adayları.
  static const List<String> unitSetResourceCandidates = [
    'unitSets',
    'UnitSets',
  ];

  final LogoTigerSettingsStore _store;
  Dio? _dio;
  LogoTigerConfig _config;
  String? _accessToken;

  /// Test için enjekte edilebilir Dio.
  LogoTigerRestClient({
    LogoTigerSettingsStore? store,
    Dio? dio,
    LogoTigerConfig? config,
  })  : _store = store ?? LogoTigerSettingsStore(),
        _dio = dio,
        _config = config ?? const LogoTigerConfig(baseUrl: '');

  LogoTigerConfig get config => _config;

  /// {@template logo_tiger_rest_client_ensure}
  /// Store’dan config yükler ve Dio hazırlar.
  /// {@endtemplate}
  Future<void> ensureReady() async {
    await _store.ensureDefaultsPersisted();
    _config = await _store.load();
    _accessToken = await _store.getAccessToken();
    _ensureDio();
  }

  void applyConfig(LogoTigerConfig config) {
    _config = config;
    _ensureDio();
  }

  Future<void> persistConfig(LogoTigerConfig config) async {
    await _store.save(config);
    await _store.setEnabled(true);
    applyConfig(config);
  }

  void _ensureDio() {
    final base = _config.normalizedBaseUrl;
    if (_dio == null) {
      _dio = Dio(
        BaseOptions(
          baseUrl: base.isEmpty ? 'http://127.0.0.1' : base,
          connectTimeout: _config.connectTimeout,
          receiveTimeout: _config.receiveTimeout,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (_) => true,
        ),
      );
    } else if (base.isNotEmpty) {
      _dio!.options.baseUrl = base;
      _dio!.options.connectTimeout = _config.connectTimeout;
      _dio!.options.receiveTimeout = _config.receiveTimeout;
    }
  }

  // ---------------------------------------------------------------------------
  // Help / discovery
  // ---------------------------------------------------------------------------

  /// {@template logo_tiger_rest_client_ping_help}
  /// `GET /services/help?expandLevel=full&api_key=` — OAuth gerekmez.
  /// {@endtemplate}
  Future<LogoTigerResult> pingHelp({String? apiKey}) async {
    await ensureReady();
    final key = (apiKey ?? _config.apiKey).trim();
    if (_config.normalizedBaseUrl.isEmpty) {
      return LogoTigerResult.fail('Base URL tanımlı değil');
    }
    if (key.isEmpty) {
      return LogoTigerResult.fail('api_key gerekli');
    }
    try {
      final uri = LogoTigerUrls.helpUri(_config.baseUrl, apiKey: key);
      final response = await _dio!.getUri(uri);
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        return LogoTigerResult.ok(response.data, statusCode: code);
      }
      return LogoTigerResult.fail(
        _extractError(response.data) ?? 'HTTP $code',
        statusCode: code,
        data: response.data,
      );
    } on DioException catch (e) {
      return _fromDio(e, 'help');
    } catch (e) {
      return LogoTigerResult.fail(e.toString());
    }
  }

  /// Opsiyonel describe (Bearer gerekir).
  Future<LogoTigerResult> describeServices() async {
    final auth = await ensureSession();
    if (!auth.success) return auth;
    return _get(
      '/services/describe',
      query: {
        if (_config.apiKey.isNotEmpty) 'api_key': _config.apiKey,
        if (_config.apiKey.isEmpty && _config.clientId.isNotEmpty)
          'api_key': _config.clientId,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  /// {@template logo_tiger_rest_client_obtain_token}
  /// POST `/token` — password grant + client_id/secret.
  /// {@endtemplate}
  Future<LogoTigerResult> obtainToken() async {
    await ensureReady();
    if (!_config.hasAuthCredentials) {
      return LogoTigerResult.fail(
        'username, password ve client_id gerekli',
      );
    }
    final body = <String, String>{
      'grant_type': 'password',
      'username': _config.username.trim(),
      'password': _config.password,
      'firmno': '${_config.firmNr}',
      'client_id': _config.clientId.trim(),
      if (_config.clientSecret.isNotEmpty)
        'client_secret': _config.clientSecret,
      if (_config.logoDb != null && _config.logoDb!.isNotEmpty)
        'logodb': _config.logoDb!,
    };

    try {
      final response = await _dio!.post(
        '/token',
        data: body,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Authorization': null, 'Accept': 'application/json'},
        ),
      );
      final code = response.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        // Basic auth yedek (RetailEX)
        if (_config.clientSecret.isNotEmpty) {
          final basic = base64Encode(
            utf8.encode(
              '${_config.clientId.trim()}:${_config.clientSecret}',
            ),
          );
          final retry = await _dio!.post(
            '/token',
            data: {
              'grant_type': 'password',
              'username': _config.username.trim(),
              'password': _config.password,
              'firmno': '${_config.firmNr}',
              if (_config.logoDb != null && _config.logoDb!.isNotEmpty)
                'logodb': _config.logoDb!,
            },
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              headers: {
                'Authorization': 'Basic $basic',
                'Accept': 'application/json',
              },
            ),
          );
          return _parseTokenResponse(retry);
        }
        return LogoTigerResult.fail(
          _extractError(response.data) ?? 'token HTTP $code',
          statusCode: code,
          data: response.data,
        );
      }
      return _parseTokenResponse(response);
    } on DioException catch (e) {
      return _fromDio(e, 'token');
    } catch (e) {
      return LogoTigerResult.fail(e.toString());
    }
  }

  Future<LogoTigerResult> _parseTokenResponse(Response response) async {
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      return LogoTigerResult.fail(
        _extractError(response.data) ?? 'token HTTP $code',
        statusCode: code,
        data: response.data,
      );
    }
    final data = response.data;
    String? token;
    int expiresIn = 3600;
    if (data is Map) {
      token = data['access_token']?.toString();
      final exp = data['expires_in'];
      if (exp is num) expiresIn = exp.toInt();
    }
    if (token == null || token.isEmpty) {
      return LogoTigerResult.fail(
        'access_token yok',
        statusCode: code,
        data: data,
      );
    }
    _accessToken = token;
    await _store.saveAccessToken(
      token,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn - 30)),
    );
    return LogoTigerResult.ok(data, statusCode: code);
  }

  /// CompanyLogin — firma/dönem bağlamı.
  Future<LogoTigerResult> companyLogin({int? firmNr, int? periodNr}) async {
    final f = firmNr ?? _config.firmNr;
    final p = periodNr ?? _config.periodNr;
    return _get('/methods/CompanyLogin/$f/$p', authRequired: true);
  }

  /// Logo "Already connected" — oturum zaten firma bağlamında.
  static bool isAlreadyConnectedError(LogoTigerResult result) {
    final blob = '${result.error ?? ''} ${result.data ?? ''}'.toLowerCase();
    return blob.contains('already connected');
  }

  /// Token + CompanyLogin.
  Future<LogoTigerResult> ensureSession() async {
    await ensureReady();
    if (_accessToken == null || _accessToken!.isEmpty) {
      final tok = await obtainToken();
      if (!tok.success) return tok;
    }
    final login = await companyLogin();
    if (!login.success) {
      // Aynı token ile zaten bağlıysa pull/push devam edebilir (RetailEX).
      if (isAlreadyConnectedError(login)) {
        return LogoTigerResult.ok(
          {'session': true, 'alreadyConnected': true},
          statusCode: login.statusCode,
        );
      }
      // Token bayatsa yenile
      if (login.statusCode == 401) {
        await _store.clearAccessToken();
        _accessToken = null;
        final tok = await obtainToken();
        if (!tok.success) return tok;
        final retry = await companyLogin();
        if (!retry.success && isAlreadyConnectedError(retry)) {
          return LogoTigerResult.ok(
            {'session': true, 'alreadyConnected': true},
            statusCode: retry.statusCode,
          );
        }
        return retry.success
            ? LogoTigerResult.ok(
                {'session': true},
                statusCode: retry.statusCode,
              )
            : retry;
      }
    }
    return login.success
        ? LogoTigerResult.ok({'session': true}, statusCode: login.statusCode)
        : login;
  }

  Future<LogoTigerResult> testConnection() async {
    final help = await pingHelp();
    if (!help.success) return help;
    if (!_config.hasAuthCredentials) {
      return LogoTigerResult.ok({
        'help': true,
        'auth': false,
        'message': 'Help OK — OAuth kimlik bilgileri yok',
      });
    }
    final session = await ensureSession();
    if (!session.success) return session;
    final sample = await listResource('items', limit: 1);
    if (sample.items.isEmpty && sample.raw is String) {
      return LogoTigerResult.fail(sample.raw as String);
    }
    return LogoTigerResult.ok({
      'help': true,
      'auth': true,
      'itemsSample': sample.items.length,
    });
  }

  // ---------------------------------------------------------------------------
  // List / pull
  // ---------------------------------------------------------------------------

  /// {@template logo_tiger_rest_client_list}
  /// Tek sayfa kaynak listesi.
  /// {@endtemplate}
  Future<LogoTigerListPage> listResource(
    String resource, {
    int? limit,
    int? offset,
    String? q,
    bool withCount = false,
    String? expandLevel,
  }) async {
    final session = await ensureSession();
    if (!session.success) {
      return LogoTigerListPage(items: const [], raw: session.error);
    }

    final query = <String, dynamic>{
      'limit': LogoTigerUrls.clampLimit(limit),
      if (offset != null && offset > 0) 'offset': offset,
      if (q != null && q.isNotEmpty) 'q': q,
      if (withCount) 'withCount': 'true',
      if (expandLevel != null && expandLevel.isNotEmpty)
        'expandLevel': expandLevel,
      if (_config.apiKey.isNotEmpty) 'api_key': _config.apiKey,
    };

    var result = await _get(
      LogoTigerUrls.resourcePath(resource),
      query: query,
      authRequired: true,
    );
    // Swagger `/services/{resource}` yedek
    if (!result.success &&
        (result.statusCode == 404 || result.statusCode == 405)) {
      result = await _get(
        LogoTigerUrls.servicesResourcePath(resource),
        query: query,
        authRequired: true,
      );
    }
    if (!result.success) {
      return LogoTigerListPage(items: const [], raw: result.error);
    }
    return LogoTigerListPage(
      count: extractCount(result.data),
      items: extractItems(result.data),
      raw: result.data,
    );
  }

  /// Tüm sayfalar (maxPages güvenlik tavanı).
  Future<List<Map<String, dynamic>>> fetchAllPaginated(
    String resource, {
    int pageSize = 15,
    int maxPages = 200,
    String? q,
  }) async {
    final all = <Map<String, dynamic>>[];
    final size = LogoTigerUrls.clampLimit(pageSize);
    for (var page = 0; page < maxPages; page++) {
      final offset = page * size;
      final batch = await listResource(
        resource,
        limit: size,
        offset: offset,
        q: q,
        withCount: page == 0,
      );
      if (batch.items.isEmpty) break;
      all.addAll(batch.items);
      if (batch.items.length < size) break;
      final total = batch.count;
      if (total != null && all.length >= total) break;
    }
    return all;
  }

  Future<List<Map<String, dynamic>>> fetchItems({int maxPages = 200}) =>
      fetchAllPaginated('items', maxPages: maxPages);

  Future<List<Map<String, dynamic>>> fetchArps({int maxPages = 200}) =>
      fetchAllPaginated('Arps', maxPages: maxPages);

  Future<List<Map<String, dynamic>>> fetchSalesOrders({
    int maxPages = 100,
  }) =>
      fetchAllPaginated('salesOrders', maxPages: maxPages);

  /// Ambar benzeri master — Logo’da ayrı warehouses yok; locationCodes.
  Future<List<Map<String, dynamic>>> fetchLocationCodes({
    int maxPages = 50,
  }) =>
      fetchAllPaginated('locationCodes', maxPages: maxPages);

  /// {@template logo_tiger_rest_client_fetch_salesmen}
  /// Plasiyer kartları — aday resource adlarını dener.
  /// {@endtemplate}
  Future<List<Map<String, dynamic>>> fetchSalesmen({
    int maxPages = 100,
  }) =>
      fetchWithResourceCandidates(
        salesmanResourceCandidates,
        maxPages: maxPages,
      );

  /// {@template logo_tiger_rest_client_fetch_cash}
  /// Kasa kartları — safeDeposits / safes / cashSafes adayları.
  /// Yoksa veya 404 → boş liste (exception yok).
  /// {@endtemplate}
  Future<List<Map<String, dynamic>>> fetchCash({int maxPages = 50}) =>
      fetchWithResourceCandidates(
        cashResourceCandidates,
        maxPages: maxPages,
      );

  /// {@template logo_tiger_rest_client_fetch_banks}
  /// Banka kartları — bankAccounts / banks adayları.
  /// {@endtemplate}
  Future<List<Map<String, dynamic>>> fetchBanks({int maxPages = 50}) =>
      fetchWithResourceCandidates(
        bankResourceCandidates,
        maxPages: maxPages,
      );

  /// {@template logo_tiger_rest_client_fetch_currencies}
  /// Döviz / kur — currencies / currencyRates adayları.
  /// {@endtemplate}
  Future<List<Map<String, dynamic>>> fetchCurrencies({
    int maxPages = 50,
  }) =>
      fetchWithResourceCandidates(
        currencyResourceCandidates,
        maxPages: maxPages,
      );

  /// {@template logo_tiger_rest_client_fetch_unit_sets}
  /// Birim setleri — unitSets.
  /// {@endtemplate}
  Future<List<Map<String, dynamic>>> fetchUnitSets({int maxPages = 50}) =>
      fetchWithResourceCandidates(
        unitSetResourceCandidates,
        maxPages: maxPages,
      );

  /// {@template logo_tiger_rest_client_fetch_with_candidates}
  /// Aday resource listesini sırayla dener; 404/405 ve hata stringlerinde
  /// sessizce sonraki adaya geçer. Hiçbiri yoksa boş liste.
  ///
  /// Parametreler:
  /// - [candidates]: Denenecek resource adları (sıra önemli)
  /// - [maxPages]: Sayfa tavanı
  ///
  /// Dönüş değeri:
  /// - [List]: İlk başarılı kaynaktan satırlar (veya boş)
  /// {@endtemplate}
  Future<List<Map<String, dynamic>>> fetchWithResourceCandidates(
    List<String> candidates, {
    int maxPages = 100,
  }) async {
    if (candidates.isEmpty) return const [];
    for (final name in candidates) {
      try {
        final probe = await listResource(name, limit: 1);
        if (_isMissingResourceProbe(probe)) {
          continue;
        }
        final all = await fetchAllPaginated(name, maxPages: maxPages);
        // Boş ama 200: ilk adayı kabul (firma kayıtsız olabilir);
        // sonraki adaylar yalnızca doluysa veya tek aday kaldıysa
        if (all.isNotEmpty || name == candidates.first) {
          return all;
        }
      } catch (e) {
        debugPrint('LogoTiger fetchCandidates($name): $e');
      }
    }
    return const [];
  }

  /// Probe sonucu kaynak yok / yetkisiz mi?
  static bool _isMissingResourceProbe(LogoTigerListPage probe) {
    if (probe.raw is! String) return false;
    final err = (probe.raw as String).toLowerCase();
    return err.contains('404') ||
        err.contains('405') ||
        err.contains('not found');
  }

  // ---------------------------------------------------------------------------
  // Create / push (RetailEX logoCreateResource)
  // ---------------------------------------------------------------------------

  /// {@template logo_tiger_rest_client_create}
  /// `POST /{resource}` — gövde `{ "restRecord": ... }` (RetailEX uyumu).
  /// 404/405 → `/services/{resource}` yedek.
  /// {@endtemplate}
  Future<LogoTigerResult> createResource(
    String resource,
    Map<String, dynamic> restRecord, {
    bool wrapRestRecord = true,
  }) async {
    final session = await ensureSession();
    if (!session.success) return session;

    final body = wrapRestRecord
        ? <String, dynamic>{'restRecord': restRecord}
        : restRecord;
    final query = <String, dynamic>{
      if (_config.apiKey.isNotEmpty) 'api_key': _config.apiKey,
    };

    var result = await _post(
      LogoTigerUrls.resourcePath(resource),
      data: body,
      query: query,
      authRequired: true,
    );
    if (!result.success &&
        (result.statusCode == 404 || result.statusCode == 405)) {
      result = await _post(
        LogoTigerUrls.servicesResourcePath(resource),
        data: body,
        query: query,
        authRequired: true,
      );
    }
    return result;
  }

  /// {@template logo_tiger_rest_client_find_by_number}
  /// Aynı NUMBER ile mevcut fiş var mı? (çift fatura engeli).
  /// `q` ile arar; eşleşen NUMBER satırını döner.
  /// {@endtemplate}
  Future<Map<String, dynamic>?> findByNumber(
    String resource,
    String number,
  ) async {
    final n = number.trim();
    if (n.isEmpty || n == '~') return null;
    final page = await listResource(resource, limit: 25, q: n);
    for (final item in page.items) {
      final candidate = (item['NUMBER'] ??
              item['number'] ??
              item['FICHENO'] ??
              item['fiche_no'] ??
              '')
          .toString()
          .trim();
      if (candidate == n) return item;
    }
    return null;
  }

  /// Create / list yanıtından Logo referansı (LOGICALREF vb.).
  static String? extractLogoRef(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in const [
        'INTERNAL_REFERENCE',
        'LOGICALREF',
        'logicalRef',
        'REF',
        'ref',
        'ID',
        'id',
      ]) {
        final v = map[key];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      }
      final nested = map['data'] ?? map['restRecord'] ?? map['item'];
      if (nested != null && nested != data) {
        return extractLogoRef(nested);
      }
      final items = extractItems(data);
      if (items.isNotEmpty) return extractLogoRef(items.first);
    }
    return null;
  }

  /// Satış siparişi — `POST /salesOrders`.
  Future<LogoTigerResult> createSalesOrder(
    Map<String, dynamic> restRecord,
  ) =>
      createResource('salesOrders', restRecord);

  /// Satın alma siparişi — `POST /purchaseOrders`.
  Future<LogoTigerResult> createPurchaseOrder(
    Map<String, dynamic> restRecord,
  ) =>
      createResource('purchaseOrders', restRecord);

  /// Satış faturası — `POST /salesInvoices`.
  Future<LogoTigerResult> createSalesInvoice(
    Map<String, dynamic> restRecord,
  ) =>
      createResource('salesInvoices', restRecord);

  /// Alış faturası — `POST /purchaseInvoices`.
  Future<LogoTigerResult> createPurchaseInvoice(
    Map<String, dynamic> restRecord,
  ) =>
      createResource('purchaseInvoices', restRecord);

  /// Satış irsaliyesi — `POST /salesDispatches`.
  Future<LogoTigerResult> createSalesDispatch(
    Map<String, dynamic> restRecord,
  ) =>
      createResource('salesDispatches', restRecord);

  /// Alış irsaliyesi — `POST /purchaseDispatches`.
  Future<LogoTigerResult> createPurchaseDispatch(
    Map<String, dynamic> restRecord,
  ) =>
      createResource('purchaseDispatches', restRecord);

  // ---------------------------------------------------------------------------
  // HTTP helpers
  // ---------------------------------------------------------------------------

  Future<LogoTigerResult> _get(
    String path, {
    Map<String, dynamic>? query,
    bool authRequired = false,
  }) async {
    await ensureReady();
    if (authRequired) {
      if (_accessToken == null || _accessToken!.isEmpty) {
        final tok = await obtainToken();
        if (!tok.success) return tok;
      }
    }
    try {
      final headers = <String, dynamic>{};
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_accessToken';
      }
      final response = await _dio!.get(
        path,
        queryParameters: query,
        options: Options(headers: headers),
      );
      return _fromResponse(response);
    } on DioException catch (e) {
      return _fromDio(e, 'GET $path');
    } catch (e) {
      debugPrint('LogoTiger GET $path: $e');
      return LogoTigerResult.fail(e.toString());
    }
  }

  Future<LogoTigerResult> _post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool authRequired = false,
  }) async {
    await ensureReady();
    if (authRequired) {
      if (_accessToken == null || _accessToken!.isEmpty) {
        final tok = await obtainToken();
        if (!tok.success) return tok;
      }
    }
    try {
      final headers = <String, dynamic>{
        'Content-Type': 'application/json',
      };
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_accessToken';
      }
      final response = await _dio!.post(
        path,
        data: data,
        queryParameters: query,
        options: Options(headers: headers),
      );
      return _fromResponse(response);
    } on DioException catch (e) {
      return _fromDio(e, 'POST $path');
    } catch (e) {
      debugPrint('LogoTiger POST $path: $e');
      return LogoTigerResult.fail(e.toString());
    }
  }

  LogoTigerResult _fromResponse(Response response) {
    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      return LogoTigerResult.ok(response.data, statusCode: code);
    }
    return LogoTigerResult.fail(
      _extractError(response.data) ?? 'HTTP $code',
      statusCode: code,
      data: response.data,
    );
  }

  LogoTigerResult _fromDio(DioException e, String context) {
    final code = e.response?.statusCode;
    final msg =
        _extractError(e.response?.data) ?? e.message ?? e.toString();
    debugPrint('LogoTiger $context: $msg (status=$code)');
    return LogoTigerResult.fail(msg, statusCode: code, data: e.response?.data);
  }

  String? _extractError(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      final model = data['ModelState'];
      if (model is Map) {
        final parts = <String>[];
        for (final v in model.values) {
          if (v is List) {
            parts.addAll(v.map((e) => e.toString()));
          } else {
            parts.add(v.toString());
          }
        }
        if (parts.isNotEmpty) return parts.join('; ');
      }
      return data['detail']?.toString() ??
          data['message']?.toString() ??
          data['Message']?.toString() ??
          data['error_description']?.toString() ??
          data['error']?.toString();
    }
    return data.toString();
  }

  /// items/Items/data çıkarımı (test edilebilir static).
  static List<Map<String, dynamic>> extractItems(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      for (final key in ['items', 'Items', 'data', 'Data']) {
        final v = data[key];
        if (v is List) {
          return v
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }
    return [];
  }

  static int? extractCount(dynamic data) {
    if (data is Map) {
      final c = data['count'] ?? data['Count'];
      if (c is num) return c.toInt();
      final meta = data['Meta'] ?? data['meta'];
      if (meta is Map) {
        final mc = meta['count'] ?? meta['Count'];
        if (mc is num) return mc.toInt();
      }
    }
    return null;
  }
}
