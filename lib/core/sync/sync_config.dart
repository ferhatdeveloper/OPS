// Dosya Adı: sync_config.dart
// Açıklama: Senkronizasyon konfigürasyon modeli
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'conflict_strategy.dart';

// JSON serialization kaldırıldı - basit model kullanılıyor

/// {@template SyncConfig}
/// Senkronizasyon konfigürasyon modeli
///
/// Kullanım örneği:
/// ```dart
/// final config = SyncConfig(
///   autoSyncEnabled: true,
///   syncInterval: Duration(minutes: 5),
///   maxRetryAttempts: 3,
/// );
/// ```
/// {@endtemplate}
class SyncConfig {
  /// Otomatik senkronizasyon etkin mi
  final bool autoSyncEnabled;

  /// Senkronizasyon aralığı
  final int syncIntervalSeconds; // 5 dakika (saniye cinsinden)

  /// Maksimum yeniden deneme sayısı
  final int maxRetryAttempts;

  /// Çakışma çözüm stratejisi
  final ConflictStrategy conflictStrategy;

  /// Tablo öncelikleri (Tablo Adı -> Öncelik Değeri, düşük olan önce senkronize edilir)
  final Map<String, int> tablePriorities;

  /// Yedekleme etkin mi
  final bool backupEnabled;

  /// Şifreleme etkin mi
  final bool encryptionEnabled;

  /// Audit log etkin mi
  final bool auditLogEnabled;

  /// Batch işlem boyutu
  final int batchSize;

  /// Timeout süresi (saniye)
  final int timeoutSeconds;

  /// Senkronize edilecek tablolar listesi
  final List<String> syncableTables;

  /// Temel yapıcı
  const SyncConfig({
    this.autoSyncEnabled = true,
    this.syncIntervalSeconds = 300,
    this.maxRetryAttempts = 3,
    this.conflictStrategy = ConflictStrategy.lastWriteWins,
    this.backupEnabled = true,
    this.encryptionEnabled = false,
    this.auditLogEnabled = true,
    this.batchSize = 100,
    this.timeoutSeconds = 30,
    this.syncableTables = const [],
    this.tablePriorities = const {
      'visits': 1,
      'routes': 2,
      'orders': 3,
      'stock': 4,
      'customers': 5,
    },
  });

  /// JSON'dan model oluşturur (basit implementasyon)
  factory SyncConfig.fromJson(Map<String, dynamic> json) {
    return SyncConfig(
      autoSyncEnabled: json['autoSyncEnabled'] ?? true,
      syncIntervalSeconds: json['syncIntervalSeconds'] ?? 300,
      maxRetryAttempts: json['maxRetryAttempts'] ?? 3,
      conflictStrategy: ConflictStrategyExtension.fromString(json['conflictStrategy'] ?? 'lastWriteWins'),
      backupEnabled: json['backupEnabled'] ?? true,
      encryptionEnabled: json['encryptionEnabled'] ?? false,
      auditLogEnabled: json['auditLogEnabled'] ?? true,
      batchSize: json['batchSize'] ?? 100,
      timeoutSeconds: json['timeoutSeconds'] ?? 30,
      syncableTables: List<String>.from(json['syncableTables'] ?? []),
      tablePriorities: Map<String, int>.from(json['tablePriorities'] ?? {}),
    );
  }

  /// Modeli JSON'a dönüştürür (basit implementasyon)
  Map<String, dynamic> toJson() {
    return {
      'autoSyncEnabled': autoSyncEnabled,
      'syncIntervalSeconds': syncIntervalSeconds,
      'maxRetryAttempts': maxRetryAttempts,
      'conflictStrategy': conflictStrategy,
      'backupEnabled': backupEnabled,
      'encryptionEnabled': encryptionEnabled,
      'auditLogEnabled': auditLogEnabled,
      'batchSize': batchSize,
      'timeoutSeconds': timeoutSeconds,
      'syncableTables': syncableTables,
      'tablePriorities': tablePriorities,
    };
  }

  /// Senkronizasyon aralığını Duration olarak döndürür
  Duration get syncInterval => Duration(seconds: syncIntervalSeconds);

  /// Timeout süresini Duration olarak döndürür
  Duration get timeout => Duration(seconds: timeoutSeconds);

  /// Modeli kopyalar ve değişiklikleri uygular
  SyncConfig copyWith({
    bool? autoSyncEnabled,
    int? syncIntervalSeconds,
    int? maxRetryAttempts,
    ConflictStrategy? conflictStrategy,
    bool? backupEnabled,
    bool? encryptionEnabled,
    bool? auditLogEnabled,
    int? batchSize,
    int? timeoutSeconds,
    Map<String, int>? tablePriorities,
  }) {
    return SyncConfig(
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      syncIntervalSeconds: syncIntervalSeconds ?? this.syncIntervalSeconds,
      maxRetryAttempts: maxRetryAttempts ?? this.maxRetryAttempts,
      conflictStrategy: conflictStrategy ?? this.conflictStrategy,
      backupEnabled: backupEnabled ?? this.backupEnabled,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      auditLogEnabled: auditLogEnabled ?? this.auditLogEnabled,
      batchSize: batchSize ?? this.batchSize,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      tablePriorities: tablePriorities ?? this.tablePriorities,
    );
  }

  /// İki konfigürasyonun eşit olup olmadığını kontrol eder
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncConfig &&
        other.autoSyncEnabled == autoSyncEnabled &&
        other.syncIntervalSeconds == syncIntervalSeconds &&
        other.maxRetryAttempts == maxRetryAttempts &&
        other.conflictStrategy == conflictStrategy &&
        other.backupEnabled == backupEnabled &&
        other.encryptionEnabled == encryptionEnabled &&
        other.auditLogEnabled == auditLogEnabled &&
        other.batchSize == batchSize &&
        other.timeoutSeconds == timeoutSeconds &&
        other.tablePriorities == tablePriorities;
  }

  /// Hash kodunu döndürür
  @override
  int get hashCode {
    return Object.hash(
      autoSyncEnabled,
      syncIntervalSeconds,
      maxRetryAttempts,
      conflictStrategy,
      backupEnabled,
      encryptionEnabled,
      auditLogEnabled,
      batchSize,
      timeoutSeconds,
      tablePriorities,
    );
  }

  /// Konfigürasyon bilgilerini string olarak döndürür
  @override
  String toString() {
    return '''SyncConfig(
      autoSyncEnabled: $autoSyncEnabled,
      syncInterval: $syncInterval,
      maxRetryAttempts: $maxRetryAttempts,
      conflictStrategy: $conflictStrategy,
      backupEnabled: $backupEnabled,
      encryptionEnabled: $encryptionEnabled,
      auditLogEnabled: $auditLogEnabled,
      batchSize: $batchSize,
      timeout: $timeout,
    )''';
  }

  /// Varsayılan konfigürasyon
  static const SyncConfig defaultConfig = SyncConfig();

  /// Geliştirme ortamı için konfigürasyon
  static const SyncConfig developmentConfig = SyncConfig(
    autoSyncEnabled: true,
    syncIntervalSeconds: 60, // 1 dakika
    maxRetryAttempts: 5,
    conflictStrategy: ConflictStrategy.lastWriteWins,
    backupEnabled: true,
    encryptionEnabled: false,
    auditLogEnabled: true,
    batchSize: 50,
    timeoutSeconds: 60,
  );

  /// Üretim ortamı için konfigürasyon
  static const SyncConfig productionConfig = SyncConfig(
    autoSyncEnabled: true,
    syncIntervalSeconds: 600, // 10 dakika
    maxRetryAttempts: 3,
    conflictStrategy: ConflictStrategy.lastWriteWins,
    backupEnabled: true,
    encryptionEnabled: true,
    auditLogEnabled: true,
    batchSize: 200,
    timeoutSeconds: 30,
  );
}
