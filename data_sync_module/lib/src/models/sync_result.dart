// Dosya Adı: sync_result.dart
// Açıklama: Senkronizasyon sonuç modeli
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

/// Senkronizasyon durumu
enum SyncStatus {
  /// Boşta
  idle,

  /// Senkronize ediliyor
  syncing,

  /// Duraklatıldı
  paused,

  /// Hata
  error,

  /// Tamamlandı
  completed
}

/// Senkronizasyon sonucu
class SyncResult {
  /// Başarılı mı
  final bool success;

  /// Eklenen kayıt sayısı
  final int inserted;

  /// Güncellenen kayıt sayısı
  final int updated;

  /// Silinen kayıt sayısı
  final int deleted;

  /// Çakışma sayısı
  final int conflicts;

  /// Hata listesi
  final List<String> errors;

  /// İşlem süresi
  final Duration duration;

  /// Tablo adı
  final String? tableName;

  /// Senkronizasyon durumu
  final SyncStatus status;

  /// Temel yapıcı
  const SyncResult({
    required this.success,
    required this.inserted,
    required this.updated,
    required this.deleted,
    required this.conflicts,
    required this.errors,
    required this.duration,
    this.tableName,
    this.status = SyncStatus.completed,
  });

  /// Başarılı sonuç oluşturur
  factory SyncResult.success({
    int inserted = 0,
    int updated = 0,
    int deleted = 0,
    int conflicts = 0,
    Duration? duration,
    String? tableName,
  }) {
    return SyncResult(
      success: true,
      inserted: inserted,
      updated: updated,
      deleted: deleted,
      conflicts: conflicts,
      errors: [],
      duration: duration ?? Duration.zero,
      tableName: tableName,
      status: SyncStatus.completed,
    );
  }

  /// Hata sonucu oluşturur
  factory SyncResult.error({
    required String error,
    Duration? duration,
    String? tableName,
    SyncStatus status = SyncStatus.error,
  }) {
    return SyncResult(
      success: false,
      inserted: 0,
      updated: 0,
      deleted: 0,
      conflicts: 0,
      errors: [error],
      duration: duration ?? Duration.zero,
      tableName: tableName,
      status: status,
    );
  }

  /// Alias for error
  factory SyncResult.failure({
    required String errorMessage,
    Duration? duration,
    String? tableName,
  }) => SyncResult.error(
    error: errorMessage,
    duration: duration,
    tableName: tableName,
  );

  /// Hata listesi ile sonuç oluşturur
  factory SyncResult.withErrors({
    required List<String> errors,
    Duration? duration,
    String? tableName,
    SyncStatus status = SyncStatus.error,
  }) {
    return SyncResult(
      success: false,
      inserted: 0,
      updated: 0,
      deleted: 0,
      conflicts: 0,
      errors: errors,
      duration: duration ?? Duration.zero,
      tableName: tableName,
      status: status,
    );
  }

  /// Toplam işlem sayısı
  int get totalOperations => inserted + updated + deleted + conflicts;

  /// Hata var mı
  bool get hasErrors => errors.isNotEmpty;

  /// Hata mesajı (ilk hata)
  String? get errorMessage => errors.isNotEmpty ? errors.first : null;

  /// Tüm hata mesajlarını birleştirir
  String get allErrorMessages => errors.join('; ');

  /// Sonucu kopyalar ve değişiklikleri uygular
  SyncResult copyWith({
    bool? success,
    int? inserted,
    int? updated,
    int? deleted,
    int? conflicts,
    List<String>? errors,
    Duration? duration,
    String? tableName,
    SyncStatus? status,
  }) {
    return SyncResult(
      success: success ?? this.success,
      inserted: inserted ?? this.inserted,
      updated: updated ?? this.updated,
      deleted: deleted ?? this.deleted,
      conflicts: conflicts ?? this.conflicts,
      errors: errors ?? this.errors,
      duration: duration ?? this.duration,
      tableName: tableName ?? this.tableName,
      status: status ?? this.status,
    );
  }

  /// İki sonucu birleştirir
  SyncResult merge(SyncResult other) {
    return SyncResult(
      success: success && other.success,
      inserted: inserted + other.inserted,
      updated: updated + other.updated,
      deleted: deleted + other.deleted,
      conflicts: conflicts + other.conflicts,
      errors: [...errors, ...other.errors],
      duration: duration + other.duration,
      tableName: tableName ?? other.tableName,
      status:
          success && other.success ? SyncStatus.completed : SyncStatus.error,
    );
  }

  /// Sonuç bilgilerini string olarak döndürür
  @override
  String toString() {
    return '''SyncResult(
      success: $success,
      inserted: $inserted,
      updated: $updated,
      deleted: $deleted,
      conflicts: $conflicts,
      totalOperations: $totalOperations,
      hasErrors: $hasErrors,
      duration: $duration,
      tableName: $tableName,
      status: $status,
      errors: $errors,
    )''';
  }

  /// JSON'a dönüştürür
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'inserted': inserted,
      'updated': updated,
      'deleted': deleted,
      'conflicts': conflicts,
      'totalOperations': totalOperations,
      'hasErrors': hasErrors,
      'duration': duration.inMilliseconds,
      'tableName': tableName,
      'status': status.name,
      'errors': errors,
    };
  }

  /// JSON'dan oluşturur
  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      success: json['success'] as bool,
      inserted: json['inserted'] as int,
      updated: json['updated'] as int,
      deleted: json['deleted'] as int,
      conflicts: json['conflicts'] as int,
      errors: List<String>.from(json['errors'] as List),
      duration: Duration(milliseconds: json['duration'] as int),
      tableName: json['tableName'] as String?,
      status: SyncStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SyncStatus.completed,
      ),
    );
  }
}
