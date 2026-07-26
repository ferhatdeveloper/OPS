// Dosya Adı: customer_model.dart
// Açıklama: Saha satış cari (müşteri) kartı veri modeli
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template cari_card_role}
/// Cari kart rolü: satış müşterisi / tedarikçi / her ikisi.
///
/// Kullanım örneği:
/// ```dart
/// final role = CariCardRole.fromStorage('supplier');
/// role.allowsPurchaseOrder; // true
/// ```
/// {@endtemplate}
enum CariCardRole {
  /// Satış carisi (müşteri)
  customer,

  /// Alış / tedarikçi carisi
  supplier,

  /// Hem satış hem alış
  both;

  /// {@template cari_card_role_storage}
  /// SQLite saklama değeri.
  /// {@endtemplate}
  String get storageValue {
    switch (this) {
      case CariCardRole.supplier:
        return 'supplier';
      case CariCardRole.both:
        return 'both';
      case CariCardRole.customer:
        return 'customer';
    }
  }

  /// {@template cari_card_role_from_storage}
  /// Saklama / Logo değerinden rol üretir; bilinmeyen → customer.
  /// {@endtemplate}
  static CariCardRole fromStorage(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v == 'supplier' ||
        v == 'tedarikci' ||
        v == 'tedarikçi' ||
        v == 'vendor' ||
        v == 's') {
      return CariCardRole.supplier;
    }
    if (v == 'both' || v == 'heriki' || v == 'her_iki' || v == 'c') {
      return CariCardRole.both;
    }
    return CariCardRole.customer;
  }

  /// {@template allows_purchase_order}
  /// Alış siparişi için uygun mu (tedarikçi ARP).
  /// {@endtemplate}
  bool get allowsPurchaseOrder =>
      this == CariCardRole.supplier || this == CariCardRole.both;

  /// {@template allows_sales_order}
  /// Satış siparişi için uygun mu (müşteri ARP).
  /// {@endtemplate}
  bool get allowsSalesOrder =>
      this == CariCardRole.customer || this == CariCardRole.both;
}

class CustomerModel {
  final String id;
  /// [code]: Logo/ERP cari kodu (opsiyonel)
  final String? code;
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

  /// [cardRole]: Müşteri / tedarikçi / her ikisi
  final CariCardRole cardRole;

  CustomerModel({
    required this.id,
    this.code,
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
    this.cardRole = CariCardRole.customer,
  });

  factory CustomerModel.empty() {
    return CustomerModel(
      id: '',
      name: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// {@template CustomerModel_parseDate}
  /// SQLite null / boş tarih alanlarını güvenli parse eder.
  /// Seed kayıtlarında `updated_at` eksik olabiliyor.
  /// {@endtemplate}
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (value is DateTime) return value;
    final raw = value.toString().trim();
    if (raw.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// {@template CustomerModel_parseIsActive}
  /// is_active alanını int/bool/string fark etmeksizin güvenli okur.
  /// Cast hatası tüm satırın atlanmasına yol açmasın.
  /// {@endtemplate}
  static bool _parseIsActive(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final raw = value.toString().trim().toLowerCase();
    if (raw.isEmpty || raw == '0' || raw == 'false') return false;
    return true;
  }

  /// {@template CustomerModel_displayCode}
  /// Liste satırında gösterilecek kod/VKN özeti.
  /// {@endtemplate}
  String get displayCodeOrTax {
    final parts = <String>[];
    final codeVal = code?.trim();
    if (codeVal != null && codeVal.isNotEmpty) {
      parts.add(codeVal);
    } else if (id.isNotEmpty) {
      parts.add(id);
    }
    final tax = taxNo?.trim();
    if (tax != null && tax.isNotEmpty) {
      parts.add('VKN: $tax');
    }
    return parts.isEmpty ? '-' : parts.join(' · ');
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: (map['id'] ?? '').toString(),
      code: map['code']?.toString(),
      name: (map['name'] ?? '').toString(),
      taxNo: map['tax_no']?.toString(),
      taxOffice: map['tax_office']?.toString(),
      yetkili: map['yetkili']?.toString(),
      address: map['address']?.toString(),
      adres2: map['adres2']?.toString(),
      il: map['il']?.toString(),
      ilce: map['ilce']?.toString(),
      semt: map['semt']?.toString(),
      ulke: map['ulke']?.toString(),
      postaKodu: map['posta_kodu']?.toString(),
      tckn: map['tckn']?.toString(),
      phone: map['phone']?.toString(),
      telefon2: map['telefon2']?.toString(),
      fax: map['fax']?.toString(),
      email: map['email']?.toString(),
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isActive: _parseIsActive(map['is_active']),
      lastVisitAt: map['last_visit_at'] != null
          ? _parseDate(map['last_visit_at'])
          : null,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
      cardRole: CariCardRole.fromStorage(
        map['card_role']?.toString() ?? map['CARD_ROLE']?.toString(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
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
      'card_role': cardRole.storageValue,
    };
  }
}
