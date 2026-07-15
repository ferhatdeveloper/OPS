import 'dart:convert';

class ApiConfigValidationException implements Exception {
  final String message;
  ApiConfigValidationException(this.message);

  @override
  String toString() => 'ApiConfigValidationException: $message';
}

class ApiConfig {
  final String baseUrl;
  final String? printerUrl;
  final String? apiKey;
  final int timeout;
  final bool useHttps;

  ApiConfig({
    required this.baseUrl,
    this.printerUrl,
    this.apiKey,
    this.timeout = 30,
    this.useHttps = true,
  }) {
    // Validate fields on creation
    validate();
  }

  /// Validate API configuration fields
  void validate() {
    if (baseUrl.isEmpty) {
      throw ApiConfigValidationException('Base URL cannot be empty');
    }

    // Basic URL validation for baseUrl - must contain at least a domain
    if (!_isValidUrlFormat(baseUrl)) {
      throw ApiConfigValidationException('Invalid base URL format: $baseUrl');
    }

    // Validate printer URL if provided
    if (printerUrl != null && printerUrl!.isNotEmpty) {
      if (!_isValidUrlFormat(printerUrl!)) {
        throw ApiConfigValidationException(
          'Invalid printer URL format: $printerUrl',
        );
      }
    }

    // Validate timeout range
    if (timeout < 5 || timeout > 120) {
      throw ApiConfigValidationException(
        'Timeout must be between 5 and 120 seconds',
      );
    }
  }

  /// Check if a string is a valid URL format
  bool _isValidUrlFormat(String url) {
    // Handle URLs with http/https scheme
    if (url.startsWith('http://') || url.startsWith('https://')) {
      url = url.replaceFirst(RegExp(r'^https?://'), '');
    }

    // Very flexible URL validation that accepts:
    // - Standard domain names (example.com)
    // - IP addresses (192.168.1.1)
    // - Localhost (localhost, 127.0.0.1)
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

    // Check for domain pattern (more flexible)
    final domainPattern = RegExp(
      r'^[a-zA-Z0-9]+([\-\.]{1}[a-zA-Z0-9]+)*(:[0-9]{1,5})?(\/.*)?$',
    );

    return domainPattern.hasMatch(url);
  }

  /// Create from Map (from database)
  factory ApiConfig.fromMap(Map<String, dynamic> map) {
    try {
      return ApiConfig(
        baseUrl: map['base_url'] as String? ?? 'https://api.default.com',
        printerUrl: map['printer_url'] as String?,
        apiKey: map['api_key'] as String?,
        timeout: (map['timeout'] is int) ? map['timeout'] : 30,
        useHttps: (map['use_https'] is int) ? map['use_https'] == 1 : true,
      );
    } catch (e) {
      print('Error creating ApiConfig from map: $e, map: $map');
      // Return default config on error
      return ApiConfig(
        baseUrl: 'https://api.default.com',
        timeout: 30,
        useHttps: true,
      );
    }
  }

  /// Convert to Map (for database)
  Map<String, dynamic> toMap() {
    return {
      'base_url': baseUrl,
      'printer_url': printerUrl,
      'api_key': apiKey,
      'timeout': timeout,
      'use_https': useHttps ? 1 : 0,
    };
  }

  /// Create from JSON string
  factory ApiConfig.fromJson(String json) {
    try {
      return ApiConfig.fromMap(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      print('Error parsing JSON: $e');
      // Return default config on error
      return ApiConfig(
        baseUrl: 'https://api.default.com',
        timeout: 30,
        useHttps: true,
      );
    }
  }

  /// Convert to JSON string
  String toJson() {
    return jsonEncode(toMap());
  }

  /// Create a copy with some properties changed
  ApiConfig copyWith({
    String? baseUrl,
    String? printerUrl,
    String? apiKey,
    int? timeout,
    bool? useHttps,
  }) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      printerUrl: printerUrl ?? this.printerUrl,
      apiKey: apiKey ?? this.apiKey,
      timeout: timeout ?? this.timeout,
      useHttps: useHttps ?? this.useHttps,
    );
  }

  /// Gets the full API URL including protocol
  String get fullUrl {
    final protocol = useHttps ? 'https://' : 'http://';

    // Ensure the base URL ends with /api
    String url = baseUrl;
    if (!url.endsWith('/api')) {
      // Remove trailing slash if present before adding /api
      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }
      url = '$url/api';
    }

    return '$protocol$url';
  }

  /// Gets the full printer URL including protocol
  String? get fullPrinterUrl {
    if (printerUrl == null || printerUrl!.isEmpty) {
      return null;
    }
    final protocol = useHttps ? 'https://' : 'http://';
    return '$protocol$printerUrl';
  }
}
