// Dosya Adı: vehicle_vision_result.dart
// Açıklama: Araç fotoğrafı AI vision yapılandırılmış sonucu
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template vehicle_vision_result}
/// Plaka / marka / tür / renk ve diğer görünen özellikler.
///
/// Kullanım örneği:
/// ```dart
/// final v = VehicleVisionResult.fromJson(map);
/// ```
/// {@endtemplate}
class VehicleVisionResult {
  /// [plate]: Plaka
  final String plate;

  /// [brand]: Marka
  final String brand;

  /// [model]: Model (opsiyonel)
  final String model;

  /// [type]: Tür (otomobil / kamyonet / …)
  final String type;

  /// [color]: Renk
  final String color;

  /// [year]: Model yılı (opsiyonel)
  final String year;

  /// [notes]: Diğer görünen özellikler
  final String notes;

  /// [confidence]: 0–1
  final double confidence;

  /// [manualOverride]: Kullanıcı düzeltti
  final bool manualOverride;

  /// {@macro vehicle_vision_result}
  const VehicleVisionResult({
    this.plate = '',
    this.brand = '',
    this.model = '',
    this.type = '',
    this.color = '',
    this.year = '',
    this.notes = '',
    this.confidence = 0,
    this.manualOverride = false,
  });

  /// Düşük güven eşiği
  static const double uncertainThreshold = 0.55;

  /// Belirsiz mi?
  bool get isUncertain =>
      !manualOverride && confidence < uncertainThreshold;

  /// Kayda değer içerik var mı?
  bool get hasContent =>
      plate.trim().isNotEmpty ||
      brand.trim().isNotEmpty ||
      type.trim().isNotEmpty ||
      color.trim().isNotEmpty;

  /// vehicles.name için kısa özet
  String get displayName {
    final parts = <String>[
      if (brand.trim().isNotEmpty) brand.trim(),
      if (model.trim().isNotEmpty) model.trim(),
      if (type.trim().isNotEmpty) type.trim(),
      if (color.trim().isNotEmpty) color.trim(),
    ];
    if (parts.isEmpty) return plate.trim();
    return parts.join(' ');
  }

  /// JSON → model
  factory VehicleVisionResult.fromJson(Map<String, dynamic> json) {
    double conf = 0;
    final rawConf = json['confidence'];
    if (rawConf is num) {
      conf = rawConf.toDouble();
    } else if (rawConf is String) {
      conf = double.tryParse(rawConf.replaceAll(',', '.')) ?? 0;
    }
    if (conf > 1 && conf <= 100) conf = conf / 100;
    conf = conf.clamp(0.0, 1.0);

    String str(dynamic v) => (v?.toString() ?? '').trim();

    final yearRaw = json['year'];
    String year = '';
    if (yearRaw is num) {
      year = yearRaw.toInt().toString();
    } else {
      year = str(yearRaw);
    }

    return VehicleVisionResult(
      plate: str(json['plate'] ?? json['plaka']),
      brand: str(json['brand'] ?? json['marka']),
      model: str(json['model']),
      type: str(json['type'] ?? json['vehicle_type'] ?? json['tur']),
      color: str(json['color'] ?? json['renk']),
      year: year,
      notes: str(json['notes'] ?? json['features'] ?? json['other']),
      confidence: conf,
      manualOverride: json['manual_override'] == true,
    );
  }

  /// Model → JSON
  Map<String, dynamic> toJson() => {
        'plate': plate,
        'brand': brand,
        'model': model,
        'type': type,
        'color': color,
        'year': year,
        'notes': notes,
        'confidence': confidence,
        if (manualOverride) 'manual_override': true,
      };

  /// Kopya
  VehicleVisionResult copyWith({
    String? plate,
    String? brand,
    String? model,
    String? type,
    String? color,
    String? year,
    String? notes,
    double? confidence,
    bool? manualOverride,
  }) {
    return VehicleVisionResult(
      plate: plate ?? this.plate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      type: type ?? this.type,
      color: color ?? this.color,
      year: year ?? this.year,
      notes: notes ?? this.notes,
      confidence: confidence ?? this.confidence,
      manualOverride: manualOverride ?? this.manualOverride,
    );
  }
}
