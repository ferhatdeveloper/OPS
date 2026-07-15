import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../model/api_config.dart';
import 'database_service.dart';

/// Settings service provider
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// API configuration provider
final apiConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dbService = await DatabaseService.getInstance();
  return await dbService.getApiConfig();
});

/// Service to manage application settings
class SettingsService {
  late DatabaseService _dbService;

  /// Initialize settings service
  Future<void> initialize() async {
    _dbService = await DatabaseService.getInstance();
    await _dbService.initialize();
  }

  /// Get the current API base URL
  Future<String> getApiBaseUrl() async {
    final config = await _dbService.getApiConfig();
    return config['base_url'] as String;
  }

  /// Update the API base URL
  Future<void> updateApiBaseUrl(String baseUrl) async {
    // Validate URL format
    if (!_isValidUrl(baseUrl)) {
      throw Exception('Invalid URL format');
    }
    await _dbService.updateApiConfig(baseUrl: baseUrl);
  }

  /// Validate if a string is a valid URL
  bool _isValidUrl(String url) {
    // Handle URLs with http/https scheme
    if (url.startsWith('http://') || url.startsWith('https://')) {
      url = url.replaceFirst(RegExp(r'^https?://'), '');
    }

    // Very flexible URL validation that accepts:
    // - Standard domain names (example.com)
    // - IP addresses (192.168.1.1)
    // - Localhost (localhost, 127.0.0.1)
    // - Custom domains without TLD for local development
    // - With or without port numbers
    // - With or without paths

    // First check if it's just an IP address or localhost
    if (url == 'localhost' || url == '127.0.0.1') {
      return true;
    }

    // Check for IP pattern
    final ipPattern = RegExp(
      r'^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(:[0-9]{1,5})?(\/.*)?$',
    );
    if (ipPattern.hasMatch(url)) {
      return true;
    }

    // Check for domain pattern (more flexible - allows custom domains)
    final domainPattern = RegExp(
      r'^[a-zA-Z0-9]+([\-\.]{1}[a-zA-Z0-9]+)*(:[0-9]{1,5})?(\/.*)?$',
    );

    return domainPattern.hasMatch(url);
  }

  /// Get API configuration
  Future<Map<String, dynamic>> getApiConfig() async {
    return await _dbService.getApiConfig();
  }

  /// Update API configuration with validation
  Future<void> updateApiConfig({
    required String baseUrl,
    String? printerUrl,
    String? apiKey,
    int? timeout,
    bool? useHttps,
  }) async {
    // Validate URL format
    if (!_isValidUrl(baseUrl)) {
      throw Exception('Invalid base URL format');
    }

    // Validate printer URL if provided
    if (printerUrl != null &&
        printerUrl.isNotEmpty &&
        !_isValidUrl(printerUrl)) {
      throw Exception('Invalid printer URL format');
    }

    // Validate timeout range
    if (timeout != null && (timeout < 5 || timeout > 120)) {
      throw Exception('Timeout must be between 5 and 120 seconds');
    } // Create ApiConfig object to validate all fields as a whole
    // If this doesn't throw an exception, the config is valid
    ApiConfig(
      baseUrl: baseUrl,
      printerUrl: printerUrl,
      apiKey: apiKey,
      timeout: timeout ?? 30,
      useHttps: useHttps ?? true,
    );

    // If validation passes, update the config
    await _dbService.updateApiConfig(
      baseUrl: baseUrl,
      printerUrl: printerUrl,
      apiKey: apiKey,
      timeout: timeout,
      useHttps: useHttps,
    );
  }

  /// Save a setting
  Future<void> setSetting(String key, String value) async {
    // Validate key format (no spaces or special characters)
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(key)) {
      throw Exception('Invalid setting key format');
    }
    await _dbService.setSetting(key, value);
  }

  /// Get a setting
  Future<String?> getSetting(String key) async {
    return await _dbService.getSetting(key);
  }

  /// Save an object
  Future<void> setObject(String key, Map<String, dynamic> value) async {
    // Validate key format (no spaces or special characters)
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(key)) {
      throw Exception('Invalid object key format');
    }
    await _dbService.setObject(key, value);
  }

  /// Get an object
  Future<Map<String, dynamic>?> getObject(String key) async {
    return await _dbService.getObject(key);
  }

  /// Test API and printer URL connections
  Future<Map<String, Map<String, dynamic>>> testApiConnections() async {
    final config = await getApiConfig();
    final baseUrl = config['base_url'] as String;
    final printerUrl = config['printer_url'] as String?;
    final useHttps = (config['use_https'] as int?) == 1;
    final timeout = (config['timeout'] as int?) ?? 30;
    final defaultPort = useHttps ? 443 : 80; // Default port based on protocol

    final results = <String, Map<String, dynamic>>{};

    // Test base URL connection
    try {
      final baseUrlWithProtocol = '${useHttps ? 'https' : 'http'}://$baseUrl';
      final uri = Uri.parse(baseUrlWithProtocol);
      final portNumber = uri.port != 0 ? uri.port : defaultPort;

      final baseUrlResponse = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(Duration(seconds: timeout));

      results['baseUrl'] = {
        'success':
            baseUrlResponse.statusCode >= 200 &&
            baseUrlResponse.statusCode < 400,
        'statusCode': baseUrlResponse.statusCode,
        'message':
            'Status: ${baseUrlResponse.statusCode} - ${_getStatusCodeMessage(baseUrlResponse.statusCode)}',
        'port': {'isOpen': true, 'number': portNumber},
        'body':
            baseUrlResponse.body.length > 500
                ? '${baseUrlResponse.body.substring(0, 500)}...'
                : baseUrlResponse.body,
      };
    } catch (e) {
      String errorMessage = e.toString();
      bool isPortClosed = false;
      int portNumber = defaultPort;

      // Check for common port/connection related error messages
      if (errorMessage.contains('SocketException') ||
          errorMessage.contains('Connection refused')) {
        isPortClosed = true;
        errorMessage =
            'Bağlantı reddedildi: Port kapalı veya sunucu erişilemez.';
      } else if (errorMessage.contains('timed out')) {
        errorMessage = 'Bağlantı zaman aşımına uğradı: Sunucu yanıt vermiyor.';
      } else if (errorMessage.contains('certificate') ||
          errorMessage.contains('SSL')) {
        errorMessage = 'SSL/TLS sertifika hatası: Güvenli bağlantı kurulamadı.';
      } else if (errorMessage.contains('Failed host lookup')) {
        errorMessage = 'DNS çözümleme hatası: Sunucu adı bulunamadı.';
      }

      // Try to extract port information
      try {
        final uri = Uri.parse('${useHttps ? 'https' : 'http'}://$baseUrl');
        portNumber = uri.port != 0 ? uri.port : defaultPort;
      } catch (_) {
        // Use default port if URI parsing fails
      }

      results['baseUrl'] = {
        'success': false,
        'message': 'Bağlantı hatası: $errorMessage',
        'port': {'isOpen': !isPortClosed, 'number': portNumber},
        'body': null,
      };
    }

    // Test printer URL connection if available
    if (printerUrl != null && printerUrl.isNotEmpty) {
      try {
        final printerUrlWithProtocol =
            '${useHttps ? 'https' : 'http'}://$printerUrl';
        final uri = Uri.parse(printerUrlWithProtocol);
        final portNumber = uri.port != 0 ? uri.port : defaultPort;

        final printerUrlResponse = await http
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(Duration(seconds: timeout));

        results['printerUrl'] = {
          'success':
              printerUrlResponse.statusCode >= 200 &&
              printerUrlResponse.statusCode < 400,
          'statusCode': printerUrlResponse.statusCode,
          'message':
              'Status: ${printerUrlResponse.statusCode} - ${_getStatusCodeMessage(printerUrlResponse.statusCode)}',
          'port': {'isOpen': true, 'number': portNumber},
          'body':
              printerUrlResponse.body.length > 500
                  ? '${printerUrlResponse.body.substring(0, 500)}...'
                  : printerUrlResponse.body,
        };
      } catch (e) {
        String errorMessage = e.toString();
        bool isPortClosed = false;
        int portNumber = defaultPort;

        // Check for common port/connection related error messages
        if (errorMessage.contains('SocketException') ||
            errorMessage.contains('Connection refused')) {
          isPortClosed = true;
          errorMessage =
              'Bağlantı reddedildi: Port kapalı veya sunucu erişilemez.';
        } else if (errorMessage.contains('timed out')) {
          errorMessage =
              'Bağlantı zaman aşımına uğradı: Sunucu yanıt vermiyor.';
        } else if (errorMessage.contains('certificate') ||
            errorMessage.contains('SSL')) {
          errorMessage =
              'SSL/TLS sertifika hatası: Güvenli bağlantı kurulamadı.';
        } else if (errorMessage.contains('Failed host lookup')) {
          errorMessage = 'DNS çözümleme hatası: Sunucu adı bulunamadı.';
        }

        // Try to extract port information
        try {
          final uri = Uri.parse('${useHttps ? 'https' : 'http'}://$printerUrl');
          portNumber = uri.port != 0 ? uri.port : defaultPort;
        } catch (_) {
          // Use default port if URI parsing fails
        }

        results['printerUrl'] = {
          'success': false,
          'message': 'Bağlantı hatası: $errorMessage',
          'port': {'isOpen': !isPortClosed, 'number': portNumber},
          'body': null,
        };
      }
    }

    return results;
  }

  /// Get a friendly message for HTTP status codes
  String _getStatusCodeMessage(int statusCode) {
    switch (statusCode) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 204:
        return 'No Content';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 500:
        return 'Internal Server Error';
      default:
        return statusCode >= 200 && statusCode < 300
            ? 'Success'
            : statusCode >= 400 && statusCode < 500
            ? 'Client Error'
            : statusCode >= 500
            ? 'Server Error'
            : 'Unknown';
    }
  }
}
