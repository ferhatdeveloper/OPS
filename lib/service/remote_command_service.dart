import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'notification_service.dart';
import 'job_queue_service.dart';
 // We'll need to create/refactor this

class RemoteCommandService {
  static final RemoteCommandService _instance = RemoteCommandService._internal();
  factory RemoteCommandService() => _instance;
  RemoteCommandService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;

  void connect(String wsUrl) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      
      _channel!.stream.listen(
        (message) {
          _handleCommand(message);
        },
        onDone: () {
          _isConnected = false;
          debugPrint('WS Connection Closed');
          // Retry logic could go here
        },
        onError: (error) {
          _isConnected = false;
          debugPrint('WS Error: $error');
        },
      );
    } catch (e) {
      debugPrint('WS Connection Failed: $e');
    }
  }

  void _handleCommand(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      final String command = data['command'] ?? '';
      final Map<String, dynamic> params = data['params'] ?? {};

      debugPrint('Received Remote Command: $command');

      switch (command) {
        case 'FORCE_SYNC':
          _executeForceSync();
          break;
        case 'LOCK_DEVICE':
          _executeDeviceLock(params['lock_message']);
          break;
        case 'RETRIEVE_LOGS':
          _executeSendLogs();
          break;
        case 'BLOCK_SITES':
          _executeBlockSites(List<String>.from(params['blocked_urls'] ?? []));
          break;
        default:
          debugPrint('Unknown command: $command');
      }
    } catch (e) {
      debugPrint('Error parsing command: $e');
    }
  }

  Future<void> _executeForceSync() async {
    await NotificationService().showNotification(
      id: 400,
      title: '📢 Merkez Komutu',
      body: 'Yönetici tarafından anlık veri senkronizasyonu başlatıldı.',
    );
    
    // Trigger Phase 7 Job Queue processing
    await JobQueueService().processQueue();
  }

  void _executeDeviceLock(String? message) {
    // Phase 8: MDM Lock
    // In a real app, this would trigger a full-screen overlay or Device Admin lock
    NotificationService().showNotification(
      id: 401,
      title: '🔒 Cihaz Kilitlendi',
      body: message ?? 'Bu cihaz yönetici tarafından geçici olarak kilitlenmiştir.',
    );
  }

  void _executeSendLogs() {
    debugPrint('Sending device diagnostics to center...');
    // Mock: Send battery, GPS status, and SQLite integrity report
  }

  void _executeBlockSites(List<String> urls) {
    debugPrint('Updating Content Filter: $urls');
    // Save to local settings for the restricted browser/webview
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }
}
