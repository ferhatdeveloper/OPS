import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LogoApiService {
  static final LogoApiService _instance = LogoApiService._internal();
  factory LogoApiService() => _instance;
  LogoApiService._internal();

  late final Dio _dio;
  String? _accessToken;
  final String _baseUrl = 'http://localhost:8000'; // Default, should be configurable

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        return handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          // Token expired, handle refresh if supported by API
          // For now, logout or prompt for relogin
        }
        return handler.next(e);
      },
    ));
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post('/api/v1/auth/login', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        _accessToken = response.data['access_token'];
        // Store token in secure storage if necessary
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Logo API Login Error: $e');
      return false;
    }
  }

  // --- Data Retrieval (DirectDB) ---

  Future<List<Map<String, dynamic>>> getArpBalances({String? code}) async {
    try {
      final response = await _dio.get('/api/v1/logo/data/arp-balances', queryParameters: {
        if (code != null) 'code': code,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      debugPrint('Error fetching ARP balances: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStockStatus() async {
    try {
      // Mocking endpoint based on common patterns in the repo
      final response = await _dio.get('/api/v1/logo/data/stock-status');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      debugPrint('Error fetching stock status: $e');
      return [];
    }
  }

  // --- Transactions (Objects/WCF) ---

  Future<bool> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _dio.post('/api/v1/logo/orders', data: orderData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating LOGO order: $e');
      return false;
    }
  }

  // --- Campaign Integration ---

  Future<bool> createCampaign(Map<String, dynamic> campaignData) async {
    try {
      final response = await _dio.post('/api/v1/logo/campaigns', data: campaignData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating LOGO campaign: $e');
      return false;
    }
  }

  // --- Reports (BI) ---

  Future<Map<String, dynamic>> getDailySalesReports() async {
    try {
      final response = await _dio.get('/api/v1/yoy-reports/daily-sales');
      return response.data;
    } catch (e) {
      debugPrint('Error fetching BI report: $e');
      return {};
    }
  }
}
