import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'storage_service.dart';

/// A service to monitor storage health and provide diagnostic information
class StorageMonitor {
  final StorageService _storageService;

  StorageMonitor(this._storageService);

  /// Get storage information including location, type, and available space
  Future<StorageInfo> getStorageInfo() async {
    // Detect storage type and platform
    final storageType = await _getStorageType();

    // Get storage path
    final storagePath = await _getStoragePath();

    // Get available space (if applicable)
    final availableSpace = await _getAvailableSpace();

    // Check health
    final isHealthy = await _storageService.checkStorageHealth();

    return StorageInfo(
      storageType: storageType,
      storagePath: storagePath,
      availableSpace: availableSpace,
      isHealthy: isHealthy,
    );
  }

  /// Perform storage diagnostic test
  Future<StorageDiagnosticResult> runDiagnostics() async {
    final stopwatch = Stopwatch()..start();

    try {
      // 1. Check if storage is accessible
      final isAccessible = await _storageService.checkStorageHealth();
      if (!isAccessible) {
        return StorageDiagnosticResult(
          success: false,
          message: 'Storage is not accessible',
          timeTakenMs: stopwatch.elapsedMilliseconds,
        );
      }

      // 2. Test write performance
      final writeTime = await _testWritePerformance();

      // 3. Test read performance
      final readTime = await _testReadPerformance();

      // Calculate average operation time
      final avgOperationTime = (writeTime + readTime) / 2;

      String performanceRating;
      if (avgOperationTime < 10) {
        performanceRating = 'Excellent';
      } else if (avgOperationTime < 50) {
        performanceRating = 'Good';
      } else if (avgOperationTime < 100) {
        performanceRating = 'Average';
      } else {
        performanceRating = 'Slow';
      }

      return StorageDiagnosticResult(
        success: true,
        message:
            'Diagnostics completed successfully. Storage performance: $performanceRating',
        timeTakenMs: stopwatch.elapsedMilliseconds,
        writeTimeMs: writeTime,
        readTimeMs: readTime,
        performanceRating: performanceRating,
      );
    } catch (e) {
      return StorageDiagnosticResult(
        success: false,
        message: 'Diagnostic failed: ${e.toString()}',
        timeTakenMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Test write performance
  Future<int> _testWritePerformance() async {
    final stopwatch = Stopwatch()..start();

    // Write a test object 10 times
    for (int i = 0; i < 10; i++) {
      await _storageService.setSetting(
        '_perf_test_$i',
        'Performance testing value $i with some additional data to test write speed',
      );
    }

    final elapsed = stopwatch.elapsedMilliseconds;
    return elapsed ~/ 10; // Average time per operation in ms
  }

  /// Test read performance
  Future<int> _testReadPerformance() async {
    final stopwatch = Stopwatch()..start();

    // Read test objects 10 times
    for (int i = 0; i < 10; i++) {
      await _storageService.getSetting('_perf_test_$i');
    }

    final elapsed = stopwatch.elapsedMilliseconds;
    return elapsed ~/ 10; // Average time per operation in ms
  }

  /// Get the storage type based on platform
  Future<String> _getStorageType() async {
    if (kIsWeb) {
      return 'Web localStorage';
    } else {
      if (!kIsWeb && Platform.isWindows) {
        return 'Windows SQLite Database';
      } else if (!kIsWeb && Platform.isAndroid) {
        return 'Android SQLite Database';
      } else if (!kIsWeb && Platform.isIOS) {
        return 'iOS SQLite Database';
      } else if (!kIsWeb && Platform.isMacOS) {
        return 'macOS SQLite Database';
      } else if (!kIsWeb && Platform.isLinux) {
        return 'Linux SQLite Database';
      } else {
        return 'SQLite Database';
      }
    }
  }

  /// Get the storage path
  Future<String> _getStoragePath() async {
    if (kIsWeb) {
      return 'Browser localStorage';
    } else {
      if (!kIsWeb && Platform.isWindows) {
        return 'C:\\exfin_erp_data';
      } else if (!kIsWeb) {
        try {
          final documentsDirectory = await getApplicationDocumentsDirectory();
          return path.join(documentsDirectory.path, 'exfin_erp.db');
        } catch (e) {
          return 'Unknown path';
        }
      } else {
        return 'Unknown path';
      }
    }
  }

  /// Get available storage space in MB
  Future<double?> _getAvailableSpace() async {
    if (kIsWeb) {
      return null; // Not applicable for web
    } else {
      try {
        String storagePath;
        if (!kIsWeb && Platform.isWindows) {
          storagePath = 'C:\\';
        } else {
          final documentsDirectory = await getApplicationDocumentsDirectory();
          storagePath = documentsDirectory.path;
        }
        final directory = Directory(storagePath);
        if (!directory.existsSync()) {
          return null;
        }
        if (!kIsWeb &&
            (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
          return null;
        } else {
          return null;
        }
      } catch (e) {
        print('Error getting available space: $e');
        return null;
      }
    }
  }

  /// Clean up temporary test data
  Future<void> cleanupTestData() async {
    try {
      for (int i = 0; i < 10; i++) {
        await _storageService.setSetting('_perf_test_$i', '');
      }
    } catch (e) {
      print('Error cleaning up test data: $e');
    }
  }
}

/// Storage information data class
class StorageInfo {
  final String storageType;
  final String storagePath;
  final double? availableSpace; // in MB
  final bool isHealthy;

  StorageInfo({
    required this.storageType,
    required this.storagePath,
    this.availableSpace,
    required this.isHealthy,
  });

  @override
  String toString() {
    return 'Storage Type: $storageType\n'
        'Storage Path: $storagePath\n'
        'Health Status: ${isHealthy ? 'Healthy' : 'Issues Detected'}\n'
        'Available Space: ${availableSpace != null ? '${availableSpace!.toStringAsFixed(2)} MB' : 'Unknown'}';
  }
}

/// Result of storage diagnostic tests
class StorageDiagnosticResult {
  final bool success;
  final String message;
  final int timeTakenMs;
  final int? writeTimeMs;
  final int? readTimeMs;
  final String? performanceRating;

  StorageDiagnosticResult({
    required this.success,
    required this.message,
    required this.timeTakenMs,
    this.writeTimeMs,
    this.readTimeMs,
    this.performanceRating,
  });

  @override
  String toString() {
    String result = 'Diagnostic Result: ${success ? 'Success' : 'Failed'}\n'
        'Message: $message\n'
        'Time Taken: $timeTakenMs ms\n';

    if (writeTimeMs != null) {
      result += 'Write Time: $writeTimeMs ms\n';
    }

    if (readTimeMs != null) {
      result += 'Read Time: $readTimeMs ms\n';
    }

    if (performanceRating != null) {
      result += 'Performance Rating: $performanceRating\n';
    }

    return result;
  }
}
