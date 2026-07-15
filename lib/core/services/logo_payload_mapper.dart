// Dosya Adı: logo_payload_mapper.dart
// Açıklama: SFA yerel varlıklarını ExfinApi Logo ERP payload formatına dönüştürür
// Oluşturulma Tarihi: 2026-07-15
// Geliştirici: EXFINOPS Team
// Son Güncelleme: 2026-07-15

/// Yerel SFA modellerini ExfinApi `/api/v1/logo/erp/*` beklediği alanlara map eder.
///
/// Backend `_transfer_*_via_objects` / `_normalize_order_payload` alanları:
/// - Header: `customer_code` / `ARP_CODE`, `fiche_no` / `number`, `date`
/// - Satır: `product_code` / `MASTER_CODE`, `quantity` / `QUANTITY`, `price` / `PRICE`
class LogoPayloadMapper {
  LogoPayloadMapper._();

  /// Sipariş aktarım gövdesi (POST /api/v1/logo/erp/orders)
  static Map<String, dynamic> orderFromLocal({
    required Map<String, dynamic> order,
    required List<Map<String, dynamic>> items,
    required String customerCode,
    String? salesmanCode,
  }) {
    final ficheNo = _firstNonEmpty([
      order['fiche_no'],
      order['order_number'],
      order['number'],
      order['id'],
    ]);
    final dateRaw = order['order_date'] ?? order['date'] ?? order['created_at'];

    final lines = items.map((item) {
      final productCode = _firstNonEmpty([
        item['product_code'],
        item['MASTER_CODE'],
        item['item_code'],
        item['code'],
        item['product_id'],
      ]);
      return {
        'product_code': productCode,
        'MASTER_CODE': productCode,
        'quantity': _asDouble(item['quantity']),
        'QUANTITY': _asDouble(item['quantity']),
        'price': _asDouble(item['price'] ?? item['unit_price']),
        'PRICE': _asDouble(item['price'] ?? item['unit_price']),
        'unit_price': _asDouble(item['price'] ?? item['unit_price']),
        if (item['unit_name'] != null) 'unit_code': item['unit_name'],
        'TYPE': item['TYPE'] ?? item['type'] ?? 0,
      };
    }).toList();

    return {
      'customer_code': customerCode,
      'arp_code': customerCode,
      'ARP_CODE': customerCode,
      'fiche_no': ficheNo ?? '~',
      'number': ficheNo ?? '~',
      'date': _formatDate(dateRaw),
      'notes': order['notes']?.toString() ?? '',
      if (salesmanCode != null && salesmanCode.isNotEmpty)
        'salesman_code': salesmanCode,
      'lines': lines,
      'items': lines,
    };
  }

  /// Fatura aktarımı için yerel gövde (Objects alanlarıyla uyumlu yardımcı)
  ///
  /// Not: ERP `POST /invoices` endpoint'i `local_invoice_id` query kullanır;
  /// bu map payload tabanlı / service-invoice senaryoları ve yerel hazırlık içindir.
  static Map<String, dynamic> invoiceFromLocal({
    required Map<String, dynamic> invoice,
    required List<Map<String, dynamic>> items,
    required String customerCode,
    String type = 'wholesale',
    String? salesmanCode,
  }) {
    final ficheNo = _firstNonEmpty([
      invoice['formatted_number'],
      invoice['invoice_number'],
      invoice['number'],
      invoice['id'],
    ]);
    final dateRaw =
        invoice['invoice_date'] ?? invoice['date'] ?? invoice['created_at'];

    final lines = items.map((item) {
      final productCode = _firstNonEmpty([
        item['product_code'],
        item['MASTER_CODE'],
        item['serviceCode'],
        item['item_code'],
        item['product_id'],
      ]);
      final isService = type == 'service' ||
          item['is_service'] == true ||
          item['TYPE'] == 4;
      return {
        'product_code': productCode,
        'MASTER_CODE': productCode,
        'quantity': _asDouble(item['quantity'] ?? 1),
        'QUANTITY': _asDouble(item['quantity'] ?? 1),
        'price': _asDouble(item['price'] ?? item['unit_price']),
        'PRICE': _asDouble(item['price'] ?? item['unit_price']),
        'unit_price': _asDouble(item['price'] ?? item['unit_price']),
        'TYPE': isService ? 4 : 0,
        'is_service': isService,
        if (item['vat_amount'] != null || item['vat_rate'] != null)
          'vat_rate': item['vat_rate'] ?? item['vat_amount'],
      };
    }).toList();

    return {
      'customer_code': customerCode,
      'arp_code': customerCode,
      'ARP_CODE': customerCode,
      'arpCode': customerCode,
      'formatted_number': ficheNo ?? '~',
      'invoiceNumber': ficheNo ?? '~',
      'number': ficheNo ?? '~',
      'date': _formatDate(dateRaw),
      'notes': invoice['notes']?.toString() ?? '',
      'invoice_type': type,
      if (salesmanCode != null && salesmanCode.isNotEmpty)
        'salesman_code': salesmanCode,
      'lines': lines,
    };
  }

  /// Tahsilat (collections/sync Objects) gövdesi
  static Map<String, dynamic> collectionFromLocal({
    required String customerCode,
    required double amount,
    String? paymentType,
    String? safeCode,
    String? description,
    String? customerName,
  }) {
    return {
      'customer_code': customerCode,
      'ARP_CODE': customerCode,
      'amount': amount,
      'AMOUNT': amount,
      'payment_type': paymentType ?? 'cash',
      'safe_code': safeCode ?? '01',
      'CODE': safeCode ?? '01',
      'description': description ?? 'SFA Tahsilat',
      'DESCRIPTION': description ?? 'SFA Tahsilat',
      if (customerName != null) 'customer_name': customerName,
    };
  }

  /// İrsaliye (dispatches/sync) header + satırlar
  static Map<String, dynamic> dispatchHeaderFromLocal({
    required String customerCode,
    Map<String, dynamic>? header,
    String? ficheNo,
  }) {
    final h = header ?? {};
    final number = _firstNonEmpty([
      ficheNo,
      h['formatted_number'],
      h['fiche_no'],
      h['number'],
      h['id'],
    ]);
    final dateRaw = h['date'] ?? h['created_at'] ?? DateTime.now();
    return {
      'customer_code': customerCode,
      'ARP_CODE': customerCode,
      'formatted_number': number ?? '~',
      'created_at': dateRaw is DateTime
          ? dateRaw.toIso8601String()
          : dateRaw.toString(),
      'date': _formatDate(dateRaw),
      if (h['customer_ref'] != null) 'customer_ref': h['customer_ref'],
      if (h['notes'] != null) 'notes': h['notes'],
    };
  }

  static List<Map<String, dynamic>> dispatchItemsFromLocal(
    List<Map<String, dynamic>> items,
  ) {
    return items.map((item) {
      final productCode = _firstNonEmpty([
        item['product_code'],
        item['MASTER_CODE'],
        item['item_code'],
        item['product_id'],
      ]);
      return {
        'product_code': productCode,
        'MASTER_CODE': productCode,
        'quantity': _asDouble(item['quantity']),
        'unit_price': _asDouble(item['price'] ?? item['unit_price']),
        'PRICE': _asDouble(item['price'] ?? item['unit_price']),
        'AMOUNT': _asDouble(item['quantity']),
      };
    }).toList();
  }

  /// Cari kart (clients/sync) gövdesi
  static Map<String, dynamic> customerFromLocal({
    required String code,
    required String name,
    String? address,
    String? city,
    String? taxOffice,
    String? taxNumber,
  }) {
    return {
      'code': code,
      'name': name,
      'TITLE': name,
      'address': address ?? '',
      'ADDRESS1': address ?? '',
      'city': city ?? '',
      'CITY': city ?? '',
      'tax_office': taxOffice ?? '',
      'TAX_OFFICE': taxOffice ?? '',
      'tax_number': taxNumber ?? '',
      'TAX_ID': taxNumber ?? '',
    };
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  /// Logo / ExfinApi genelde `dd.MM.yyyy` veya ISO kabul eder; ISO gönderiyoruz,
  /// backend `_format_logo_date` ile dönüştürür.
  static String _formatDate(dynamic value) {
    if (value == null) {
      return DateTime.now().toIso8601String().split('T').first;
    }
    if (value is DateTime) {
      return value.toIso8601String().split('T').first;
    }
    final raw = value.toString().trim();
    if (raw.isEmpty) {
      return DateTime.now().toIso8601String().split('T').first;
    }
    try {
      return DateTime.parse(raw).toIso8601String().split('T').first;
    } catch (_) {
      return raw;
    }
  }
}
