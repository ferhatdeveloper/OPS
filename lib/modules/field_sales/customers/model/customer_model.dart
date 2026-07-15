class CustomerModel {
  final String id;
  final String name;
  final String? taxNo;
  final String? taxOffice;
  final String? yetkili;
  final String? address;
  final String? adres2;
  final String? il;
  final String? ilce;
  final String? semt;
  final String? ulke;
  final String? postaKodu;
  final String? tckn;
  final String? phone;
  final String? telefon2;
  final String? fax;
  final String? email;
  final double balance;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final DateTime? lastVisitAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerModel({
    required this.id,
    required this.name,
    this.taxNo,
    this.taxOffice,
    this.yetkili,
    this.address,
    this.adres2,
    this.il,
    this.ilce,
    this.semt,
    this.ulke,
    this.postaKodu,
    this.tckn,
    this.phone,
    this.telefon2,
    this.fax,
    this.email,
    this.balance = 0.0,
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.lastVisitAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerModel.empty() {
    return CustomerModel(
      id: '',
      name: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as String,
      name: map['name'] as String,
      taxNo: map['tax_no'] as String?,
      taxOffice: map['tax_office'] as String?,
      yetkili: map['yetkili'] as String?,
      address: map['address'] as String?,
      adres2: map['adres2'] as String?,
      il: map['il'] as String?,
      ilce: map['ilce'] as String?,
      semt: map['semt'] as String?,
      ulke: map['ulke'] as String?,
      postaKodu: map['posta_kodu'] as String?,
      tckn: map['tckn'] as String?,
      phone: map['phone'] as String?,
      telefon2: map['telefon2'] as String?,
      fax: map['fax'] as String?,
      email: map['email'] as String?,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isActive: (map['is_active'] as int?) == 1,
      lastVisitAt: map['last_visit_at'] != null ? DateTime.parse(map['last_visit_at']) : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tax_no': taxNo,
      'tax_office': taxOffice,
      'yetkili': yetkili,
      'address': address,
      'adres2': adres2,
      'il': il,
      'ilce': ilce,
      'semt': semt,
      'ulke': ulke,
      'posta_kodu': postaKodu,
      'tckn': tckn,
      'phone': phone,
      'telefon2': telefon2,
      'fax': fax,
      'email': email,
      'balance': balance,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive ? 1 : 0,
      'last_visit_at': lastVisitAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
