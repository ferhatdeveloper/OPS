// Dosya Adı: weekly_route_stop.dart
// Açıklama: Haftalık rota planı dens durak satırı (gün + sıra + cari)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template weekly_route_stop}
/// Haftalık rota planındaki tek durak (route_customers JOIN customers).
///
/// Kullanım örneği:
/// ```dart
/// final stop = WeeklyRouteStop.fromMap(row);
/// print(stop.customerName);
/// ```
/// {@endtemplate}
class WeeklyRouteStop {
  /// [id]: route_customers.id
  final String id;

  /// [routeId]: routes.id
  final String routeId;

  /// [customerId]: customers.id
  final String customerId;

  /// [visitOrder]: Ziyaret sırası (1-based)
  final int visitOrder;

  /// [isMandatory]: Zorunlu durak
  final bool isMandatory;

  /// [dayOfWeek]: 1–7
  final int dayOfWeek;

  /// [customerCode]: Cari kod
  final String customerCode;

  /// [customerName]: Cari ünvan
  final String customerName;

  /// [customerAddress]: Adres
  final String customerAddress;

  /// [latitude]: Cari enlem (yoksa null)
  final double? latitude;

  /// [longitude]: Cari boylam (yoksa null)
  final double? longitude;

  /// {@macro weekly_route_stop}
  const WeeklyRouteStop({
    required this.id,
    required this.routeId,
    required this.customerId,
    required this.visitOrder,
    this.isMandatory = true,
    required this.dayOfWeek,
    this.customerCode = '',
    this.customerName = '',
    this.customerAddress = '',
    this.latitude,
    this.longitude,
  });

  /// Geçerli lat/long var mı (0,0 dışlanır)
  bool get hasCoords {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return false;
    if (lat == 0 && lng == 0) return false;
    return true;
  }

  /// {@template weekly_route_stop_from_map}
  /// SQLite satırından dens model.
  ///
  /// Parametreler:
  /// - [map]: JOIN sonucu
  ///
  /// Dönüş değeri:
  /// - [WeeklyRouteStop]: Dens durak
  /// {@endtemplate}
  factory WeeklyRouteStop.fromMap(Map<String, dynamic> map) {
    return WeeklyRouteStop(
      id: map['id'] as String? ?? '',
      routeId: map['route_id'] as String? ?? '',
      customerId: map['customer_id'] as String? ?? '',
      visitOrder: (map['visit_order'] as num?)?.toInt() ?? 0,
      isMandatory: (map['is_mandatory'] as num?)?.toInt() != 0,
      dayOfWeek: (map['day_of_week'] as num?)?.toInt() ?? 0,
      customerCode: map['customer_code'] as String? ?? '',
      customerName: map['customer_name'] as String? ?? '',
      customerAddress: map['customer_address'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

/// {@template weekly_route_salesperson}
/// Rota planı personel seçici dens satırı.
/// {@endtemplate}
class WeeklyRouteSalesperson {
  /// [id]: users.id (routes.salesperson_id)
  final String id;

  /// [code]: Kullanıcı adı / kod
  final String code;

  /// [name]: Görünen ad
  final String name;

  /// {@macro weekly_route_salesperson}
  const WeeklyRouteSalesperson({
    required this.id,
    this.code = '',
    required this.name,
  });

  /// Dens etiket
  String get label {
    if (name.isNotEmpty && code.isNotEmpty) return '$name · $code';
    if (name.isNotEmpty) return name;
    return code.isNotEmpty ? code : id;
  }

  /// users satırından model
  factory WeeklyRouteSalesperson.fromMap(Map<String, dynamic> map) {
    final id = map['id'] as String? ?? '';
    final fullName = (map['full_name'] as String?)?.trim() ?? '';
    final username = (map['username'] as String?)?.trim() ?? '';
    return WeeklyRouteSalesperson(
      id: id,
      code: username,
      name: fullName.isNotEmpty ? fullName : username,
    );
  }
}

/// {@template weekly_route_customer_pick}
/// Cari seçici dens satırı.
/// {@endtemplate}
class WeeklyRouteCustomerPick {
  /// [id]: customers.id
  final String id;

  /// [code]: Cari kod
  final String code;

  /// [name]: Ünvan
  final String name;

  /// [address]: Adres
  final String address;

  /// {@macro weekly_route_customer_pick}
  const WeeklyRouteCustomerPick({
    required this.id,
    this.code = '',
    required this.name,
    this.address = '',
  });

  /// {@template weekly_route_customer_pick_from_map}
  /// customers satırından seçici model.
  /// {@endtemplate}
  factory WeeklyRouteCustomerPick.fromMap(Map<String, dynamic> map) {
    return WeeklyRouteCustomerPick(
      id: map['id'] as String? ?? '',
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
    );
  }
}
