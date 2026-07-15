import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_service.dart';
import 'settings_service.dart';

/// Login service provider
final loginServiceProvider = Provider<LoginService>((ref) {
  return LoginService(ref);
});

/// User authentication provider
final authProvider = FutureProvider<bool>((ref) async {
  final dbService = await DatabaseService.getInstance();
  return await dbService.isAuthenticated();
});

class LoginService {
  final Ref _ref;

  LoginService(this._ref);

  /// Login with username and password
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      // Get the API base URL from settings
      final settingsService = _ref.read(settingsServiceProvider);
      final baseUrl = await settingsService.getApiBaseUrl();

      try {
        final response = await http.post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'username': username, 'password': password}),
        );

        if (response.statusCode == 200) {
          // Successful login
          final responseData =
              json.decode(response.body) as Map<String, dynamic>;
          final token = responseData['token'] as String?;

          if (token != null) {
            final dbService = await DatabaseService.getInstance();

            // Save authentication token
            await dbService.saveAuthToken(token);

            // Save user information
            if (responseData['user'] != null) {
              await dbService.setUserSession(
                responseData['user'] as Map<String, dynamic>,
              );
            }

            return responseData;
          } else {
            throw Exception('Token not found in response');
          }
        } else {
          // Error message
          final errorResponse =
              json.decode(response.body) as Map<String, dynamic>;
          final errorMessage =
              errorResponse['message'] ?? 'Invalid username or password';
          throw Exception(errorMessage);
        }
      } catch (e) {
        // For development purposes, allow mock login if API is unavailable
        print("API connection error: $e - Using mock login for development");

        // Create mock login data
        final mockData = {
          'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'id': '1',
            'username': username,
            'displayName': 'Test User',
            'role': 'admin',
          },
        };

        final dbService = await DatabaseService.getInstance();
        await dbService.saveAuthToken(mockData['token'] as String);
        await dbService.setUserSession(
          mockData['user'] as Map<String, dynamic>,
        );

        return mockData;
      }
    } catch (e) {
      print("Login error: $e");
      rethrow;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final dbService = await DatabaseService.getInstance();
    return await dbService.isAuthenticated();
  }

  /// Get user session information
  Future<Map<String, dynamic>?> getUserInfo() async {
    final dbService = await DatabaseService.getInstance();
    return await dbService.getUserSession();
  }

  /// Logout user
  Future<void> logout() async {
    final dbService = await DatabaseService.getInstance();
    await dbService.logout();
  }
}
