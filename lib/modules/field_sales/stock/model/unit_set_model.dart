class UnitSetModel {
  final String id;
  final String name;
  final bool isActive;
  final bool isSynced;
  final DateTime? createdAt;
  final List<UnitSetLineModel> lines;

  UnitSetModel({
    required this.id,
    required this.name,
    this.isActive = true,
    this.isSynced = false,
    this.createdAt,
    this.lines = const [],
  });

  factory UnitSetModel.fromMap(Map<String, dynamic> map, List<UnitSetLineModel> lines) {
    return UnitSetModel(
      id: map['id'] as String,
      name: map['name'] as String,
      isActive: (map['is_active'] as int?) == 1,
      isSynced: (map['is_synced'] as int?) == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      lines: lines,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_active': isActive ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class UnitSetLineModel {
  final String id;
  final String unitSetId;
  final String unitName;
  final double conversionFactor;
  final bool isMainUnit;

  UnitSetLineModel({
    required this.id,
    required this.unitSetId,
    required this.unitName,
    required this.conversionFactor,
    this.isMainUnit = false,
  });

  factory UnitSetLineModel.fromMap(Map<String, dynamic> map) {
    return UnitSetLineModel(
      id: map['id'] as String,
      unitSetId: map['unit_set_id'] as String,
      unitName: map['unit_name'] as String,
      conversionFactor: (map['conversion_factor'] as num).toDouble(),
      isMainUnit: (map['is_main_unit'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unit_set_id': unitSetId,
      'unit_name': unitName,
      'conversion_factor': conversionFactor,
      'is_main_unit': isMainUnit ? 1 : 0,
    };
  }
}
