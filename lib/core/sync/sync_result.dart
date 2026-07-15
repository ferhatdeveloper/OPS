// Dosya Adı: sync_result.dart
// Açıklama: Senkronizasyon sonuç ve ilerleme modelleri
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

/// {@template sync_result}
/// Senkronizasyon işlemi sonucunu temsil eden sınıf
/// {@endtemplate}
class SyncResult {
  /// Senkronizasyon başarılı mı?
  final bool isSuccess;

  /// Hata mesajı (varsa)
  final String? errorMessage;

  /// Senkronize edilen kayıt sayısı
  final int syncedRecords;

  /// Senkronizasyon süresi (milisaniye)
  final int duration;

  /// Senkronize edilen tablolar
  final List<String> syncedTables;

  /// Timestamp
  final DateTime timestamp;

  SyncResult({
    required this.isSuccess,
    this.errorMessage,
    this.syncedRecords = 0,
    this.duration = 0,
    this.syncedTables = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Başarılı senkronizasyon sonucu oluşturur
  factory SyncResult.success({
    int syncedRecords = 0,
    int duration = 0,
    List<String> syncedTables = const [],
  }) {
    return SyncResult(
      isSuccess: true,
      syncedRecords: syncedRecords,
      duration: duration,
      syncedTables: syncedTables,
      timestamp: DateTime.now(),
    );
  }

  /// Başarısız senkronizasyon sonucu oluşturur
  factory SyncResult.failure({
    required String errorMessage,
    int syncedRecords = 0,
    int duration = 0,
    List<String> syncedTables = const [],
  }) {
    return SyncResult(
      isSuccess: false,
      errorMessage: errorMessage,
      syncedRecords: syncedRecords,
      duration: duration,
      syncedTables: syncedTables,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'SyncResult{isSuccess: $isSuccess, errorMessage: $errorMessage, syncedRecords: $syncedRecords, duration: ${duration}ms, syncedTables: $syncedTables, timestamp: $timestamp}';
  }
}

/// {@template sync_progress_item}
/// Tek bir tablo için senkronizasyon ilerleme durumu.
/// {@endtemplate}
class SyncProgressItem {
  final String tableName;
  final int totalRecords;
  final int processedRecords;
  final int errorCount;
  final bool isCompleted;

  const SyncProgressItem({
    required this.tableName,
    this.totalRecords = 0,
    this.processedRecords = 0,
    this.errorCount = 0,
    this.isCompleted = false,
  });

  double get percentage => totalRecords == 0 ? 0 : (processedRecords / totalRecords) * 100;

  SyncProgressItem copyWith({
    int? totalRecords,
    int? processedRecords,
    int? errorCount,
    bool? isCompleted,
  }) {
    return SyncProgressItem(
      tableName: tableName,
      totalRecords: totalRecords ?? this.totalRecords,
      processedRecords: processedRecords ?? this.processedRecords,
      errorCount: errorCount ?? this.errorCount,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// {@template sync_progress}
/// Genel senkronizasyon ilerleme durumu.
/// {@endtemplate}
class SyncProgress {
  final bool isSyncing;
  final String? currentTable;
  final List<SyncProgressItem> tableProgress;
  final DateTime startTime;

  SyncProgress({
    this.isSyncing = false,
    this.currentTable,
    this.tableProgress = const [],
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  static SyncProgress idle() => SyncProgress(isSyncing: false);

  int get totalTables => tableProgress.length;
  int get completedTables => tableProgress.where((t) => t.isCompleted).length;
  
  int get totalRecords => tableProgress.fold(0, (sum, item) => sum + item.totalRecords);
  int get processedRecords => tableProgress.fold(0, (sum, item) => sum + item.processedRecords);
  
  double get overallPercentage {
    if (totalTables == 0) return 0;
    return (processedRecords / (totalRecords > 0 ? totalRecords : 1)) * 100;
  }

  SyncProgress copyWith({
    bool? isSyncing,
    String? currentTable,
    List<SyncProgressItem>? tableProgress,
  }) {
    return SyncProgress(
      isSyncing: isSyncing ?? this.isSyncing,
      currentTable: currentTable ?? this.currentTable,
      tableProgress: tableProgress ?? this.tableProgress,
      startTime: startTime,
    );
  }
}
