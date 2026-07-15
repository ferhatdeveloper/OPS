// Dosya Adı: sync_model.dart
// Açıklama: Senkronize edilecek modeller için temel sınıf
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:uuid/uuid.dart';
import 'package:exfin_ops/core/models/approval_status.dart';

/// {@template sync_model}
/// Senkronize edilecek modeller için temel sınıf.
/// Bu sınıfı extend eden tüm modeller otomatik olarak senkronize edilir.
/// {@endtemplate}
abstract class SyncModel {
  /// Benzersiz kimlik
  final String id;

  /// Oluşturulma tarihi
  final DateTime createdAt;

  /// Son güncelleme tarihi
  final DateTime updatedAt;

  /// Senkronizasyon durumu
  final bool isSynced;

  /// Silinme durumu
  final bool isDeleted;

  /// Onay durumu
  final ApprovalStatus approvalStatus;

  /// Temel yapıcı
  SyncModel({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.isDeleted = false,
    ApprovalStatus? approvalStatus,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        approvalStatus = approvalStatus ?? ApprovalStatus.pending;

  /// JSON'dan model oluşturur
  factory SyncModel.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson() metodu implement edilmeli');
  }

  /// Modeli JSON'a dönüştürür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'approval_status': approvalStatus.value,
    };
  }

  /// Modeli kopyalar ve değişiklikleri uygular
  SyncModel copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    bool? isDeleted,
    ApprovalStatus? approvalStatus,
  });

  /// İki modelin eşit olup olmadığını kontrol eder
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncModel && other.id == id;
  }

  /// Hash kodunu döndürür
  @override
  int get hashCode => id.hashCode;

  /// Model bilgilerini string olarak döndürür
  @override
  String toString() {
    return '''SyncModel(
      id: $id,
      createdAt: $createdAt,
      updatedAt: $updatedAt,
      isSynced: $isSynced,
      isDeleted: $isDeleted,
      approvalStatus: $approvalStatus
    )''';
  }

  /// Senkronizasyon için uygun mu kontrol eder
  bool get isReadyForSync => approvalStatus.isReadyForSync;

  /// Senkronizasyon sonrası durumu günceller
  SyncModel markAsSynced() {
    return copyWith(
      approvalStatus: ApprovalStatus.synced,
      isSynced: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Hata durumunu işaretler
  SyncModel markAsError() {
    return copyWith(
      approvalStatus: ApprovalStatus.error,
      updatedAt: DateTime.now(),
    );
  }

  /// Onaylanmış olarak işaretler
  SyncModel markAsApproved() {
    return copyWith(
      approvalStatus: ApprovalStatus.approved,
      updatedAt: DateTime.now(),
    );
  }

  /// Reddedilmiş olarak işaretler
  SyncModel markAsRejected() {
    return copyWith(
      approvalStatus: ApprovalStatus.rejected,
      updatedAt: DateTime.now(),
    );
  }

  /// Silinmiş olarak işaretler
  SyncModel markAsDeleted() {
    return copyWith(
      isDeleted: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Veritabanı için uygun formata dönüştürür
  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'approval_status': approvalStatus.value,
    };
  }

  /// Veritabanından model oluşturur
  factory SyncModel.fromDatabaseMap(Map<String, dynamic> map) {
    throw UnimplementedError('fromDatabaseMap() metodu implement edilmeli');
  }

  /// Tablo adını döndürür
  String get tableName;

  /// Şema sütunlarını döndürür
  List<String> get schemaColumns;

  /// İndeks sütunlarını döndürür
  List<String> get indexColumns =>
      ['is_synced', 'approval_status', 'is_deleted', 'updated_at'];

  /// Validasyon kurallarını döndürür
  Map<String, dynamic> get validationRules => {};

  /// Model geçerli mi kontrol eder
  bool get isValid {
    try {
      for (final rule in validationRules.entries) {
        final field = rule.key;
        final validator = rule.value;

        if (validator is Function) {
          final isValid = validator();
          if (!isValid) return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
