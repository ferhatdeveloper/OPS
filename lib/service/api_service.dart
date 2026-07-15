import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/api_config.dart';
import 'settings_service.dart';

/// API service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return ApiService(settingsService);
});

/// Service for making API requests
class ApiService {
  late SettingsService _settingsService;
  late Dio _dio;
  ApiConfig? _apiConfig;

  /// Constructor
  ApiService(SettingsService settingsService) {
    _settingsService = settingsService;
    _initialize();
  }

  /// Initialize the API service with configuration
  Future<void> _initialize() async {
    // Get the API configuration
    final configMap = await _settingsService.getApiConfig();
    _apiConfig = ApiConfig.fromMap(configMap);

    // Configure Dio with base options
    _dio = Dio(
      BaseOptions(
        baseUrl: _apiConfig!.fullUrl,
        connectTimeout: Duration(seconds: _apiConfig!.timeout),
        receiveTimeout: Duration(seconds: _apiConfig!.timeout),
        headers: {
          'Accept': 'application/json',
          if (_apiConfig!.apiKey != null && _apiConfig!.apiKey!.isNotEmpty)
            'Api-Key': _apiConfig!.apiKey!,
        },
      ),
    );

    // Add interceptors for logging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (log) {
          print('DIO: $log');
        },
      ),
    );
  }

  /// Reload API configuration (call when settings are updated)
  Future<void> reloadConfig() async {
    return _initialize();
  }

  /// Make a GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (_apiConfig == null) await _initialize();
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      throw Exception('GET request failed: ${e.toString()}');
    }
  }

  /// Make a POST request
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (_apiConfig == null) await _initialize();
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      throw Exception('POST request failed: ${e.toString()}');
    }
  }

  /// Make a PUT request
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (_apiConfig == null) await _initialize();
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      throw Exception('PUT request failed: ${e.toString()}');
    }
  }

  /// Make a DELETE request
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (_apiConfig == null) await _initialize();
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      throw Exception('DELETE request failed: ${e.toString()}');
    }
  }

  /// Handle Dio errors
  void _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw Exception(
          'Connection timed out. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        String message = 'Server error';

        if (responseData is Map && responseData.containsKey('message')) {
          message = responseData['message'];
        } else if (responseData is String && responseData.isNotEmpty) {
          message = responseData;
        }

        throw Exception('Server error $statusCode: $message');
      case DioExceptionType.cancel:
        throw Exception('Request was cancelled');
      case DioExceptionType.unknown:
        if (e.error != null && e.error.toString().contains('SocketException')) {
          throw Exception(
            'Network error. Please check your internet connection.',
          );
        }
        throw Exception('Unknown error: ${e.message}');
      default:
        throw Exception('Request failed: ${e.message}');
    }
  }

  /// Get the Dio instance for custom requests
  Dio get dio => _dio;

  /// Get the current API configuration
  ApiConfig? get config => _apiConfig;
}
