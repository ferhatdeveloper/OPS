import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.exfinerp.com/v1'; // Örnek base URL

  ApiClient() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // İstek ve cevap interceptor'ları
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Token ekleme gibi işlemler
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Cevap işleme
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Hata işleme
          return handler.next(e);
        },
      ),
    );
  }

  // GET isteği
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // POST isteği
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // PUT isteği
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // DELETE isteği
  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      rethrow;
    }
  }
}
