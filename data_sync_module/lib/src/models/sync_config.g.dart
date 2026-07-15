// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncConfig _$SyncConfigFromJson(Map<String, dynamic> json) => SyncConfig(
      autoSyncEnabled: json['autoSyncEnabled'] as bool? ?? true,
      syncIntervalSeconds:
          (json['syncIntervalSeconds'] as num?)?.toInt() ?? 300,
      maxRetryAttempts: (json['maxRetryAttempts'] as num?)?.toInt() ?? 3,
      conflictStrategy: json['conflictStrategy'] as String? ?? 'smartMerge',
      backupEnabled: json['backupEnabled'] as bool? ?? true,
      encryptionEnabled: json['encryptionEnabled'] as bool? ?? false,
      auditLogEnabled: json['auditLogEnabled'] as bool? ?? true,
      batchSize: (json['batchSize'] as num?)?.toInt() ?? 100,
      timeoutSeconds: (json['timeoutSeconds'] as num?)?.toInt() ?? 30,
    );

Map<String, dynamic> _$SyncConfigToJson(SyncConfig instance) =>
    <String, dynamic>{
      'autoSyncEnabled': instance.autoSyncEnabled,
      'syncIntervalSeconds': instance.syncIntervalSeconds,
      'maxRetryAttempts': instance.maxRetryAttempts,
      'conflictStrategy': instance.conflictStrategy,
      'backupEnabled': instance.backupEnabled,
      'encryptionEnabled': instance.encryptionEnabled,
      'auditLogEnabled': instance.auditLogEnabled,
      'batchSize': instance.batchSize,
      'timeoutSeconds': instance.timeoutSeconds,
    };
