// Dosya Adı: logo_api_service.dart
// Açıklama: ExfinApi Logo REST istemcisi (auth, ERP okuma/yazma, senkron)
// Oluşturulma Tarihi: 2026-07-15
// Geliştirici: EXFINOPS Team
// Son Güncelleme: 2026-07-15

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../service/database_service.dart';
import 'logo_rest_settings_service.dart';

/// Logo API çağrı sonucu — yakalanmayan exception fırlatılmaz
class LogoApiResult {
  final bool success;
  final dynamic data;
  final String? error;
  final int? statusCode;

  const LogoApiResult({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  factory LogoApiResult.ok(dynamic data, {int? statusCode}) => LogoApiResult(
        success: true,
        data: data,
        statusCode: statusCode,
      );

  factory LogoApiResult.fail(String error, {int? statusCode, dynamic data}) =>
      LogoApiResult(
        success: false,
        error: error,
        statusCode: statusCode,
        data: data,
      );

  List<Map<String, dynamic>> asMapList() {
    if (data is List) {
      return data
          .map((e) => e is Map<String, dynamic>
              ? e
              : Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  Map<String, dynamic> asMap() {
    if (data is Map<String, dynamic>) return data as Map<String, dynamic>;
    if (data is Map) return Map<String, dynamic>.from(data as Map);
    return {};
  }
}

/// ExfinApi `/api/v1/logo/*` ve `/api/v1/auth/login` istemcisi (singleton)
class LogoApiService {
  static final LogoApiService _instance = LogoApiService._internal();
  factory LogoApiService() => _instance;
  LogoApiService._internal();

  final LogoRestSettingsService _settingsService = LogoRestSettingsService();

  Dio? _dio;
  String? _accessToken;
  LogoRestSettings _settings = LogoRestSettings(
    baseUrl: LogoRestSettingsService.defaultBaseUrl(),
  );
  bool _initialized = false;
  Future<void>? _configLoadFuture;

  /// Senkron init — config yüklemesini arka planda başlatır
  void init() {
    if (_initialized) return;
    _dio = Dio(
      BaseOptions(
        baseUrl: _settings.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null && _accessToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          if (_settings.firma.isNotEmpty) {
            options.headers['X-Firma'] = _settings.firma;
          }
          if (_settings.period.isNotEmpty) {
            options.headers['X-Period'] = _settings.period;
          }
          final apiKey = _settings.apiKey;
          if (apiKey != null && apiKey.isNotEmpty) {
            options.headers['X-API-Key'] = apiKey;
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            debugPrint('Logo API 401 — token temizleniyor');
            _accessToken = null;
            await _settingsService.clearAccessToken();
          }
          return handler.next(e);
        },
      ),
    );
    _initialized = true;
    _configLoadFuture = loadConfig();
  }

  Future<void> ensureReady() async {
    if (!_initialized) init();
    if (_configLoadFuture != null) {
      await _configLoadFuture;
      _configLoadFuture = null;
    }
  }

  /// SharedPreferences (+ mümkünse DB ApiConfig) üzerinden yapılandırma
  Future<void> loadConfig() async {
    try {
      if (!_initialized) init();
      _settings = await _settingsService.getSettings();

      // Varsayılan localhost ise DatabaseService ApiConfig base_url dene
      try {
        if (_settings.baseUrl == LogoRestSettingsService.defaultBaseUrl()) {
          final dbUrl = await _tryLoadDbBaseUrl();
          if (dbUrl != null && dbUrl.isNotEmpty) {
            _settings = _settings.copyWith(baseUrl: _normalizeBaseUrl(dbUrl));
          }
        }
      } catch (e) {
        debugPrint('Logo API: ApiConfig okunamadı (opsiyonel): $e');
      }

      _accessToken = await _settingsService.getAccessToken();
      _dio?.options.baseUrl = _settings.baseUrl;
      debugPrint('Logo API config yüklendi: ${_settings.baseUrl}');
    } catch (e) {
      debugPrint('Logo API loadConfig hata: $e');
    }
  }

  Future<String?> _tryLoadDbBaseUrl() async {
    try {
      final dbService = await DatabaseService.getInstance();
      final config = await dbService.getApiConfig();
      final base = config['base_url']?.toString();
      if (base == null || base.isEmpty) return null;
      if (base.contains('default.com') || base.contains('exfinerp.com')) {
        return null;
      }
      return base;
    } catch (_) {
      return null;
    }
  }

  String _normalizeBaseUrl(String url) {
    var u = url.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }
    // `/api` ile bitiyorsa kök URL'e indir
    if (u.endsWith('/api')) {
      u = u.substring(0, u.length - 4);
    }
    return u;
  }

  Future<void> applySettings(LogoRestSettings settings) async {
    await _settingsService.saveSettings(settings);
    _settings = settings;
    _dio?.options.baseUrl = settings.baseUrl;
  }

  LogoRestSettings get currentSettings => _settings;
  bool get isAuthenticated =>
      _accessToken != null && _accessToken!.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  Future<LogoApiResult> login({String? username, String? password}) async {
    await ensureReady();
    final user = (username ?? _settings.username).trim();
    final pass = password ?? _settings.password;
    if (user.isEmpty || pass.isEmpty) {
      return LogoApiResult.fail('Kullanıcı adı veya şifre boş');
    }
    try {
      final response = await _dio!.post(
        '/api/v1/auth/login',
        data: {'username': user, 'password': pass},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Authorization': null},
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        String? token;
        if (data is Map) {
          token = data['access_token']?.toString() ??
              data['accessToken']?.toString() ??
              data['token']?.toString();
        }
        if (token == null || token.isEmpty) {
          return LogoApiResult.fail(
            'Yanıtta access_token yok',
            statusCode: response.statusCode,
            data: data,
          );
        }
        _accessToken = token;
        await _settingsService.saveAccessToken(token);
        if (username != null || password != null) {
          await _settingsService.setCredentials(
            username: user,
            password: pass,
          );
          _settings = _settings.copyWith(username: user, password: pass);
        }
        return LogoApiResult.ok(data, statusCode: response.statusCode);
      }
      return LogoApiResult.fail(
        'Login başarısız',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      return _fromDio(e, 'Login hatası');
    } catch (e) {
      debugPrint('Logo API Login Error: $e');
      return LogoApiResult.fail(e.toString());
    }
  }

  Future<LogoApiResult> ensureAuthenticated() async {
    await ensureReady();
    if (isAuthenticated) {
      return LogoApiResult.ok({'token': true});
    }
    return login();
  }

  Future<LogoApiResult> testConnection() async {
    await ensureReady();
    final auth = await ensureAuthenticated();
    if (!auth.success) return auth;
    // Basit sağlık kontrolü: müşteri listesi (boş arama)
    return getCustomers();
  }

  // ---------------------------------------------------------------------------
  // Okuma
  // ---------------------------------------------------------------------------

  Future<LogoApiResult> getCustomers({String? search}) => _get(
        '/api/v1/logo/erp/customers',
        query: {if (search != null && search.isNotEmpty) 'search': search},
      );

  Future<LogoApiResult> getItems({String? search}) => _get(
        '/api/v1/logo/erp/items',
        query: {if (search != null && search.isNotEmpty) 'search': search},
      );

  Future<LogoApiResult> getStock(String itemCode) =>
      _get('/api/v1/logo/erp/stock/$itemCode');

  Future<LogoApiResult> getOrders({String? customerCode}) => _get(
        '/api/v1/logo/erp/orders',
        query: {
          if (customerCode != null && customerCode.isNotEmpty)
            'customer_code': customerCode,
        },
      );

  Future<LogoApiResult> getBalances() =>
      _get('/api/v1/logo/erp/reports/balances');

  Future<LogoApiResult> getSalesReport({
    required String startDate,
    required String endDate,
  }) =>
      _get(
        '/api/v1/logo/erp/reports/sales',
        query: {'start_date': startDate, 'end_date': endDate},
      );

  Future<LogoApiResult> getInventoryReport() =>
      _get('/api/v1/logo/erp/reports/inventory');

  /// Eski stub uyumluluğu
  Future<List<Map<String, dynamic>>> getArpBalances({String? code}) async {
    final r = await getBalances();
    final list = r.asMapList();
    if (code == null || code.isEmpty) return list;
    return list
        .where((e) =>
            (e['code']?.toString() ?? e['CODE']?.toString() ?? '') == code)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getStockStatus({String? itemCode}) async {
    if (itemCode != null && itemCode.isNotEmpty) {
      final r = await getStock(itemCode);
      return r.asMapList().isNotEmpty
          ? r.asMapList()
          : (r.data is Map ? [r.asMap()] : []);
    }
    final r = await getInventoryReport();
    return r.asMapList();
  }

  Future<Map<String, dynamic>> getDailySalesReports() async {
    final today = DateTime.now();
    final d =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final r = await getSalesReport(startDate: d, endDate: d);
    return r.asMap().isNotEmpty
        ? r.asMap()
        : {'items': r.asMapList(), 'success': r.success, 'error': r.error};
  }

  // ---------------------------------------------------------------------------
  // Yazma / aktarım
  // ---------------------------------------------------------------------------

  Future<LogoApiResult> createOrder(Map<String, dynamic> orderData) =>
      _post('/api/v1/logo/erp/orders', data: orderData);

  Future<LogoApiResult> createInvoice({
    required String localInvoiceId,
    String type = 'wholesale',
  }) =>
      _post(
        '/api/v1/logo/erp/invoices',
        query: {'local_invoice_id': localInvoiceId, 'type': type},
      );

  Future<LogoApiResult> createCollectionSync(Map<String, dynamic> body) =>
      _post('/api/v1/logo/erp/collections/sync', data: body);

  Future<LogoApiResult> createCollectionSimple({
    required String customerCode,
    required double amount,
  }) =>
      _post(
        '/api/v1/logo/erp/collections',
        data: {'customer_code': customerCode, 'amount': amount},
      );

  Future<LogoApiResult> createDispatch(
    Map<String, dynamic> header,
    List<Map<String, dynamic>> items,
  ) =>
      _post(
        '/api/v1/logo/erp/dispatches/sync',
        data: {'dispatch_data': header, 'items': items},
      );

  Future<LogoApiResult> createCustomerSync(Map<String, dynamic> clientData) =>
      _post('/api/v1/logo/erp/clients/sync', data: clientData);

  Future<LogoApiResult> syncMasterData({int? companyId, int? periodId}) async {
    await ensureReady();
    final cid = companyId ?? _settings.companyId ?? 1;
    final pid = periodId ?? _settings.periodId;
    return _post(
      '/api/v1/logo/data/sync/all',
      query: {
        'company_id': cid,
        if (pid != null) 'period_id': pid,
      },
    );
  }

  /// Kampanya: önce erp/campaigns, yoksa data/campaigns
  Future<LogoApiResult> createCampaign(Map<String, dynamic> campaignData) async {
    final primary = await _post(
      '/api/v1/logo/campaigns',
      data: campaignData,
      authRequired: true,
    );
    if (primary.success) return primary;
    if (primary.statusCode == 404 || primary.statusCode == 405) {
      return _post(
        '/api/v1/logo/data/campaigns',
        data: campaignData,
        authRequired: true,
      );
    }
    return primary;
  }

  // ---------------------------------------------------------------------------
  // HTTP helpers
  // ---------------------------------------------------------------------------

  Future<LogoApiResult> _get(
    String path, {
    Map<String, dynamic>? query,
    bool authRequired = true,
  }) async {
    await ensureReady();
    if (authRequired) {
      final auth = await ensureAuthenticated();
      if (!auth.success) return auth;
    }
    try {
      final response =
          await _dio!.get(path, queryParameters: query);
      return _fromResponse(response);
    } on DioException catch (e) {
      return _fromDio(e, 'GET $path');
    } catch (e) {
      debugPrint('Logo API GET $path error: $e');
      return LogoApiResult.fail(e.toString());
    }
  }

  Future<LogoApiResult> _post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool authRequired = true,
  }) async {
    await ensureReady();
    if (authRequired) {
      final auth = await ensureAuthenticated();
      if (!auth.success) return auth;
    }
    try {
      final response = await _dio!.post(
        path,
        data: data,
        queryParameters: query,
      );
      return _fromResponse(response);
    } on DioException catch (e) {
      return _fromDio(e, 'POST $path');
    } catch (e) {
      debugPrint('Logo API POST $path error: $e');
      return LogoApiResult.fail(e.toString());
    }
  }

  LogoApiResult _fromResponse(Response response) {
    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      return LogoApiResult.ok(response.data, statusCode: code);
    }
    return LogoApiResult.fail(
      _extractError(response.data) ?? 'HTTP $code',
      statusCode: code,
      data: response.data,
    );
  }

  LogoApiResult _fromDio(DioException e, String context) {
    final code = e.response?.statusCode;
    final msg = _extractError(e.response?.data) ??
        e.message ??
        e.toString();
    debugPrint('Logo API $context: $msg (status=$code)');
    return LogoApiResult.fail(msg, statusCode: code, data: e.response?.data);
  }

  String? _extractError(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      return data['detail']?.toString() ??
          data['message']?.toString() ??
          data['error']?.toString();
    }
    return data.toString();
  }
}
