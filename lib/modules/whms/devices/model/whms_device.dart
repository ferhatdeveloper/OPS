// Dosya Adı: whms_device.dart
// Açıklama: WHMS etiket / terminal cihaz modeli
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template whms_device}
/// Yerel cihaz / terminal kaydı (MAC + model + roller).
///
/// Kullanım örneği:
/// ```dart
/// const d = WhmsDevice(id: '1', name: 'RF-1', mac: 'AA:BB:CC:DD:EE:FF');
/// ```
/// {@endtemplate}
class WhmsDevice {
  /// [id]: PK
  final String id;

  /// [name]: Cihaz adı
  final String name;

  /// [mac]: Normalize MAC (AA:BB:…)
  final String? mac;

  /// [model]: Model
  final String? model;

  /// [osName]: OS
  final String? osName;

  /// [roles]: Terminal rol wire kodları (pick, sevk, …)
  final List<String> roles;

  /// [defaultWarehouseCode]: Varsayılan ambar
  final String? defaultWarehouseCode;

  /// [isActive]: Aktif
  final bool isActive;

  /// [createdAt]: Oluşturma
  final String? createdAt;

  /// [updatedAt]: Güncelleme
  final String? updatedAt;

  /// {@macro whms_device}
  const WhmsDevice({
    required this.id,
    required this.name,
    this.mac,
    this.model,
    this.osName,
    this.roles = const [],
    this.defaultWarehouseCode,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// {@template whms_device_parse_roles}
  /// CSV / JSON-ish roller → trim liste.
  /// {@endtemplate}
  static List<String> parseRoles(Object? raw) {
    if (raw == null) return const [];
    final s = raw.toString().trim();
    if (s.isEmpty) return const [];
    if (s.startsWith('[') && s.endsWith(']')) {
      final inner = s.substring(1, s.length - 1);
      if (inner.trim().isEmpty) return const [];
      return inner
          .split(',')
          .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ''))
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return s
        .split(RegExp(r'[,|;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  /// {@template whms_device_roles_csv}
  /// Rolleri CSV olarak saklar.
  /// {@endtemplate}
  static String rolesToCsv(List<String> roles) =>
      roles.map((e) => e.trim()).where((e) => e.isNotEmpty).join(',');

  factory WhmsDevice.fromMap(Map<String, dynamic> map) {
    return WhmsDevice(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      mac: map['mac']?.toString(),
      model: map['model']?.toString(),
      osName: map['os_name']?.toString(),
      roles: parseRoles(map['roles']),
      defaultWarehouseCode: map['default_warehouse_code']?.toString(),
      isActive: (map['is_active'] as num?)?.toInt() != 0,
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'mac': mac,
      'model': model,
      'os_name': osName,
      'roles': rolesToCsv(roles),
      'default_warehouse_code': defaultWarehouseCode,
      'is_active': isActive ? 1 : 0,
      'ONAY': 0,
      'is_synced': 0,
      'is_deleted': 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  WhmsDevice copyWith({
    String? name,
    String? mac,
    String? model,
    String? osName,
    List<String>? roles,
    String? defaultWarehouseCode,
    bool? isActive,
    String? updatedAt,
  }) {
    return WhmsDevice(
      id: id,
      name: name ?? this.name,
      mac: mac ?? this.mac,
      model: model ?? this.model,
      osName: osName ?? this.osName,
      roles: roles ?? this.roles,
      defaultWarehouseCode:
          defaultWarehouseCode ?? this.defaultWarehouseCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
