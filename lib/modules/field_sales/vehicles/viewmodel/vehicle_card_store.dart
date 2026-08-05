// Dosya Adı: vehicle_card_store.dart
// Açıklama: Araç kartı SQLite liste / upsert (güne başlama + vision)
// Oluşturulma Tarihi: 2026-08-04
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-04

import 'package:uuid/uuid.dart';

import '../../../../service/database_service.dart';
import '../model/vehicle_model.dart';

/// {@template filter_vehicles_by_query}
/// Plaka / ad üzerinde yerel arama filtresi (unit test dostu).
///
/// Parametreler:
/// - [vehicles]: Kaynak liste
/// - [query]: Arama metni
///
/// Dönüş değeri:
/// - [List<VehicleModel>]: Filtrelenmiş liste
/// {@endtemplate}
List<VehicleModel> filterVehiclesByQuery(
  List<VehicleModel> vehicles,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return List<VehicleModel>.from(vehicles);
  return vehicles.where((v) {
    final plate = v.plate.toLowerCase();
    final name = (v.name ?? '').toLowerCase();
    return plate.contains(q) || name.contains(q);
  }).toList();
}

/// {@template vehicle_card_store}
/// Aktif araç kartlarını listeler; plaka ile upsert eder (offline-first).
///
/// Kullanım örneği:
/// ```dart
/// final store = VehicleCardStore();
/// final list = await store.listActive();
/// await store.upsertByPlate(plate: '34 ABC 123', name: 'Ford Transit');
/// ```
/// {@endtemplate}
class VehicleCardStore {
  /// [uuid]: Kimlik üretici (test enjeksiyonu)
  final Uuid _uuid;

  /// {@macro vehicle_card_store}
  VehicleCardStore({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  /// {@template vehicle_card_store_list_active}
  /// Aktif araçları plakaya göre sıralar.
  ///
  /// Dönüş değeri:
  /// - [List<VehicleModel>]: Aktif araçlar
  /// {@endtemplate}
  Future<List<VehicleModel>> listActive() async {
    final svc = await DatabaseService.getInstance();
    final db = await svc.getDatabase();
    final maps = await db.query(
      'vehicles',
      where: 'is_active = 1',
      orderBy: 'plate COLLATE NOCASE',
    );
    return maps.map(VehicleModel.fromMap).toList();
  }

  /// {@template vehicle_card_store_upsert_by_plate}
  /// Plaka ile araç kartı oluşturur veya günceller (`is_synced = 0`).
  ///
  /// Parametreler:
  /// - [plate]: Plaka (zorunlu)
  /// - [name]: Marka/model/özet (opsiyonel)
  ///
  /// Dönüş değeri:
  /// - [VehicleModel?]: Başarısız/boş plakada null
  /// {@endtemplate}
  Future<VehicleModel?> upsertByPlate({
    required String plate,
    String? name,
  }) async {
    final normalized = plate.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    final svc = await DatabaseService.getInstance();
    final db = await svc.getDatabase();
    final session = await svc.getUserSession();
    final userId = session?['id'] as String? ?? 'system';
    final displayName = name?.trim();
    final safeName =
        (displayName != null && displayName.isNotEmpty) ? displayName : null;

    final existing = await db.query(
      'vehicles',
      where: 'plate = ? COLLATE NOCASE',
      whereArgs: [normalized],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as String;
      final salespersonId =
          existing.first['salesperson_id'] as String? ?? userId;
      await db.update(
        'vehicles',
        {
          if (safeName != null) 'name': safeName,
          'is_active': 1,
          'is_synced': 0,
          'salesperson_id': salespersonId,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return VehicleModel(
        id: id,
        plate: normalized,
        name: safeName ?? existing.first['name'] as String?,
        salespersonId: salespersonId,
        isActive: true,
        isSynced: false,
      );
    }

    final id = _uuid.v4();
    await db.insert('vehicles', {
      'id': id,
      'plate': normalized,
      'name': safeName,
      'salesperson_id': userId,
      'is_active': 1,
      'is_synced': 0,
    });
    return VehicleModel(
      id: id,
      plate: normalized,
      name: safeName,
      salespersonId: userId,
      isActive: true,
      isSynced: false,
    );
  }
}
