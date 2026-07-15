// Dosya Adı: sync_config.dart
// Açıklama: Senkronizasyon konfigürasyon modeli
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:json_annotation/json_annotation.dart';

part 'sync_config.g.dart';

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
@JsonSerializable()
class SyncConfig {
  /// Otomatik senkronizasyon etkin mi
  @JsonKey(defaultValue: true)
  final bool autoSyncEnabled;

  /// Senkronizasyon aralığı
  @JsonKey(defaultValue: 300) // 5 dakika (saniye cinsinden)
  final int syncIntervalSeconds;

  /// Maksimum yeniden deneme sayısı
  @JsonKey(defaultValue: 3)
  final int maxRetryAttempts;

  /// Çakışma çözüm stratejisi
  @JsonKey(defaultValue: 'smartMerge')
  final String conflictStrategy;

  /// Yedekleme etkin mi
  @JsonKey(defaultValue: true)
  final bool backupEnabled;

  /// Şifreleme etkin mi
  @JsonKey(defaultValue: false)
  final bool encryptionEnabled;

  /// Audit log etkin mi
  @JsonKey(defaultValue: true)
  final bool auditLogEnabled;

  /// Batch işlem boyutu
  @JsonKey(defaultValue: 100)
  final int batchSize;

  /// Timeout süresi (saniye)
  @JsonKey(defaultValue: 30)
  final int timeoutSeconds;

  /// Temel yapıcı
  const SyncConfig({
    this.autoSyncEnabled = true,
    this.syncIntervalSeconds = 300,
    this.maxRetryAttempts = 3,
    this.conflictStrategy = 'smartMerge',
    this.backupEnabled = true,
    this.encryptionEnabled = false,
    this.auditLogEnabled = true,
    this.batchSize = 100,
    this.timeoutSeconds = 30,
  });

  /// JSON'dan model oluşturur
  factory SyncConfig.fromJson(Map<String, dynamic> json) =>
      _$SyncConfigFromJson(json);

  /// Modeli JSON'a dönüştürür
  Map<String, dynamic> toJson() => _$SyncConfigToJson(this);

  /// Senkronizasyon aralığını Duration olarak döndürür
  Duration get syncInterval => Duration(seconds: syncIntervalSeconds);

  /// Timeout süresini Duration olarak döndürür
  Duration get timeout => Duration(seconds: timeoutSeconds);

  /// Modeli kopyalar ve değişiklikleri uygular
  SyncConfig copyWith({
    bool? autoSyncEnabled,
    int? syncIntervalSeconds,
    int? maxRetryAttempts,
    String? conflictStrategy,
    bool? backupEnabled,
    bool? encryptionEnabled,
    bool? auditLogEnabled,
    int? batchSize,
    int? timeoutSeconds,
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
        other.timeoutSeconds == timeoutSeconds;
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
    conflictStrategy: 'smartMerge',
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
    conflictStrategy: 'lastWriteWins',
    backupEnabled: true,
    encryptionEnabled: true,
    auditLogEnabled: true,
    batchSize: 200,
    timeoutSeconds: 30,
  );
}
