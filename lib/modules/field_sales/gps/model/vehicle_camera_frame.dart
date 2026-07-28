// Dosya Adı: vehicle_camera_frame.dart
// Açıklama: Araç kamera anlık kare (polling canlı izleme)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'vehicle_camera_lens.dart';

/// {@template vehicle_camera_frame}
/// Plasiyer cihazından periyodik snapshot — WebRTC yoksa “canlı”
/// deneyim için polling kaynağı.
///
/// Kullanım örneği:
/// ```dart
/// final f = VehicleCameraFrame(
///   id: '1',
///   userId: 'u1',
///   salespersonCode: 'PLS01',
///   lens: VehicleCameraLens.front,
///   capturedAt: DateTime.now(),
///   imageBase64: '...',
/// );
/// ```
/// {@endtemplate}
class VehicleCameraFrame {
  /// [id]: Kare kimliği
  final String id;

  /// [userId]: Plasiyer kullanıcı id
  final String userId;

  /// [salespersonCode]: Plasiyer kodu
  final String salespersonCode;

  /// [lens]: Ön / arka
  final VehicleCameraLens lens;

  /// [capturedAt]: Çekim zamanı
  final DateTime capturedAt;

  /// [imageBase64]: JPEG base64 (küçük çerçeve)
  final String imageBase64;

  /// [isSynced]: Sunucuya aktarıldı mı
  final bool isSynced;

  /// {@macro vehicle_camera_frame}
  const VehicleCameraFrame({
    required this.id,
    required this.userId,
    required this.salespersonCode,
    required this.lens,
    required this.capturedAt,
    required this.imageBase64,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'salesperson_code': salespersonCode,
      'lens': lens.storageKey,
      'captured_at': capturedAt.toIso8601String(),
      'image_base64': imageBase64,
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': 0,
      'created_at': capturedAt.toIso8601String(),
      'updated_at': capturedAt.toIso8601String(),
    };
  }

  factory VehicleCameraFrame.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v is DateTime) return v;
      return DateTime.tryParse(v?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    final syncedRaw = map['is_synced'];
    final synced = syncedRaw == true ||
        syncedRaw == 1 ||
        syncedRaw?.toString() == '1';

    return VehicleCameraFrame(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      salespersonCode: map['salesperson_code']?.toString() ?? '',
      lens: VehicleCameraLens.parse(map['lens']?.toString()),
      capturedAt: parseDate(map['captured_at']),
      imageBase64: map['image_base64']?.toString() ?? '',
      isSynced: synced,
    );
  }

  /// Kullanıcı + lens başına en güncel kare.
  static List<VehicleCameraFrame> latestByUserAndLens(
    List<VehicleCameraFrame> rows,
  ) {
    final byKey = <String, VehicleCameraFrame>{};
    for (final row in rows) {
      final key = '${row.userId}|${row.lens.storageKey}';
      final prev = byKey[key];
      if (prev == null || row.capturedAt.isAfter(prev.capturedAt)) {
        byKey[key] = row;
      }
    }
    final list = byKey.values.toList(growable: false);
    list.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return list;
  }
}
