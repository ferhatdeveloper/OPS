import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'database_service.dart';
import 'package:flutter/foundation.dart';

class JobQueueService {
  static final JobQueueService _instance = JobQueueService._internal();
  factory JobQueueService() => _instance;
  JobQueueService._internal();

  bool _isProcessing = false;

  /// Add a job to the queue for background processing
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    Map<String, dynamic>? payload,
    int priority = 0,
  }) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();

    final jobId = const Uuid().v4();
    await db.insert('sync_queue', {
      'id': jobId,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': payload != null ? jsonEncode(payload) : null,
      'priority': priority,
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    debugPrint('Job Enqueued: $entityType ($entityId)');
    
    // Trigger processing
    processQueue();
  }

  /// Process pending jobs in the queue
  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();

      // Get pending jobs ordered by priority and age
      final jobs = await db.query(
        'sync_queue',
        orderBy: 'priority DESC, created_at ASC',
        limit: 10,
      );

      for (var job in jobs) {
        final jobId = job['id'] as String;
        final type = job['entity_type'] as String;
        final entityId = job['entity_id'] as String;
        
        debugPrint('Processing Job: $type ($entityId)');

        // Mock: Simulated network request to ERP/Server
        bool success = await _mockSyncRequest(type, entityId);

        if (success) {
          await db.delete('sync_queue', where: 'id = ?', whereArgs: [jobId]);
          debugPrint('Job Completed: $jobId');
        } else {
          final currentRetry = (job['retry_count'] as int) + 1;
          if (currentRetry > 5) {
            // Move to dead letter or just keep with error
            await db.update('sync_queue', {
              'retry_count': currentRetry,
              'last_error': 'Max retries exceeded',
            }, where: 'id = ?', whereArgs: [jobId]);
          } else {
            await db.update('sync_queue', {
              'retry_count': currentRetry,
              'scheduled_at': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
            }, where: 'id = ?', whereArgs: [jobId]);
          }
        }
      }
    } catch (e) {
      debugPrint('Queue Processing Error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _mockSyncRequest(String type, String id) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    // Simulate 90% success rate
    return true; 
  }
}
