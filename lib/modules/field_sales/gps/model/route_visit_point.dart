// Dosya Adı: route_visit_point.dart
// Açıklama: Rota haritası dens ziyaret noktası (route_customers + cari)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template route_visit_point}
/// Rota haritası dens ziyaret noktası — SQLite JOIN satırı.
///
/// Kullanım örneği:
/// ```dart
/// final p = RouteVisitPoint.fromMap(row);
/// ```
/// {@endtemplate}
class RouteVisitPoint {
  /// [id]: route_customers satır kimliği
  final String id;

  /// [routeId]: Rota kimliği
  final String routeId;

  /// [routeName]: Rota adı
  final String routeName;

  /// [customerId]: Cari kimliği
  final String customerId;

  /// [customerCode]: Cari kodu
  final String customerCode;

  /// [customerName]: Cari ünvan
  final String customerName;

  /// [customerAddress]: Adres
  final String customerAddress;

  /// [visitOrder]: Ziyaret sırası (1…n)
  final int visitOrder;

  /// [isMandatory]: Zorunlu durak mı
  final bool isMandatory;

  /// [latitude]: Enlem
  final double? latitude;

  /// [longitude]: Boylam
  final double? longitude;

  /// [isVisited]: Bugün ziyaret edildi mi
  final bool isVisited;

  /// {@macro route_visit_point}
  const RouteVisitPoint({
    required this.id,
    required this.routeId,
    required this.customerId,
    required this.visitOrder,
    this.routeName = '',
    this.customerCode = '',
    this.customerName = '',
    this.customerAddress = '',
    this.isMandatory = true,
    this.latitude,
    this.longitude,
    this.isVisited = false,
  });

  /// {@template route_visit_point_has_coords}
  /// Harita için geçerli koordinat var mı.
  /// {@endtemplate}
  bool get hasCoords => latitude != null && longitude != null;

  /// {@template route_visit_point_copy_with}
  /// Kopya üretir (ör. isVisited güncellemesi).
  /// {@endtemplate}
  RouteVisitPoint copyWith({bool? isVisited}) {
    return RouteVisitPoint(
      id: id,
      routeId: routeId,
      routeName: routeName,
      customerId: customerId,
      customerCode: customerCode,
      customerName: customerName,
      customerAddress: customerAddress,
      visitOrder: visitOrder,
      isMandatory: isMandatory,
      latitude: latitude,
      longitude: longitude,
      isVisited: isVisited ?? this.isVisited,
    );
  }

  /// {@template route_visit_point_from_map}
  /// SQLite JOIN satırı → dens kayıt.
  /// {@endtemplate}
  factory RouteVisitPoint.fromMap(Map<String, dynamic> map) {
    return RouteVisitPoint(
      id: map['id']?.toString() ?? '',
      routeId: map['route_id']?.toString() ?? '',
      routeName: map['route_name']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      customerCode: map['customer_code']?.toString() ?? '',
      customerName: map['customer_name']?.toString() ?? '',
      customerAddress: map['customer_address']?.toString() ?? '',
      visitOrder: (map['visit_order'] as num?)?.toInt() ?? 0,
      isMandatory: (map['is_mandatory'] as num?)?.toInt() != 0,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isVisited: map['is_visited'] == 1 || map['is_visited'] == true,
    );
  }

  /// {@template route_visit_point_to_map}
  /// Seed / debug için map (route_customers alanları hariç join alanları).
  /// {@endtemplate}
  Map<String, dynamic> toRouteCustomerMap() {
    return {
      'id': id,
      'route_id': routeId,
      'customer_id': customerId,
      'visit_order': visitOrder,
      'is_mandatory': isMandatory ? 1 : 0,
    };
  }
}
