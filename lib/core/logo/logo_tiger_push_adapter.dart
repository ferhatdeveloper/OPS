// Dosya Adı: logo_tiger_push_adapter.dart
// Açıklama: LogoPayloadMapper → Tiger Objects REST restRecord uyarlayıcı
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../services/logo_payload_mapper.dart';
import '../sync/outbound_idempotency.dart';

/// {@template logo_tiger_push_target}
/// Tiger POST hedefi: kaynak adı + restRecord gövdesi.
///
/// Kullanım örneği:
/// ```dart
/// final t = LogoTigerPushAdapter.orderFromMapped(payload);
/// // POST /salesOrders { restRecord: t.restRecord }
/// ```
/// {@endtemplate}
class LogoTigerPushTarget {
  /// [resource]: örn. salesOrders, salesInvoices
  final String resource;

  /// [restRecord]: Logo Objects alanları (ARP_CODE, TRANSACTIONS…)
  final Map<String, dynamic> restRecord;

  const LogoTigerPushTarget({
    required this.resource,
    required this.restRecord,
  });
}

/// {@template logo_tiger_push_adapter}
/// Exfin / SFA mapper çıktısını RetailEX `logoCreateResource` şemasına çevirir.
///
/// Kaynak of truth SQLite + JobQueue kalır; bu sınıf yalnızca transport payload’ı.
/// {@endtemplate}
class LogoTigerPushAdapter {
  LogoTigerPushAdapter._();

  /// Tiger push desteklenen kuyruk tipleri.
  static const Set<String> supportedQueueTypes = {
    'order',
    'orders',
    'invoice',
    'invoices',
    'dispatch',
    'dispatches',
    'waybill',
    'waybills',
    'supplier_purchase_request',
    'supplier_purchase_requests',
    'supply_request',
  };

  /// {@template logo_tiger_push_adapter_is_supported}
  /// Tip Tiger’a yazılıyor mu? (tahsilat vb. → false → Exfin fallback)
  /// {@endtemplate}
  static bool isSupported(String type) =>
      supportedQueueTypes.contains(type.toLowerCase());

  /// {@template logo_tiger_push_adapter_from_queue}
  /// JobQueue tip + mapper/local payload → Tiger hedefi.
  /// [entityId] verilirse boş/`~` NUMBER → kararlı idempotency kodu.
  /// Desteklenmeyen tip → null.
  /// {@endtemplate}
  static LogoTigerPushTarget? fromQueuePayload(
    String type,
    Map<String, dynamic> payload, {
    String? entityId,
  }) {
    final t = type.toLowerCase();
    LogoTigerPushTarget? target;
    switch (t) {
      case 'order':
      case 'orders':
        target = orderFromMapped(payload);
        break;
      case 'invoice':
      case 'invoices':
        target = invoiceFromMapped(payload);
        break;
      case 'dispatch':
      case 'dispatches':
      case 'waybill':
      case 'waybills':
        target = dispatchFromMapped(payload);
        break;
      case 'supplier_purchase_request':
      case 'supplier_purchase_requests':
      case 'supply_request':
        final body = Map<String, dynamic>.from(payload);
        body['type'] = 'purchase';
        body['order_type'] = 'purchase';
        target = orderFromMapped(body);
        break;
      default:
        return null;
    }
    if (target != null && entityId != null && entityId.isNotEmpty) {
      OutboundIdempotency.applyToRecord(
        target.restRecord,
        entityType: type,
        entityId: entityId,
      );
    }
    return target;
  }

  /// {@template logo_tiger_push_adapter_order}
  /// Sipariş → salesOrders | purchaseOrders.
  /// {@endtemplate}
  static LogoTigerPushTarget orderFromMapped(Map<String, dynamic> mapped) {
    final apiType = LogoPayloadMapper.resolveOrderApiType(
      mapped['type']?.toString() ??
          mapped['order_type']?.toString() ??
          mapped['order_channel']?.toString(),
    );
    final isPurchase = apiType == 'purchase';
    final arp = _firstNonEmpty([
      mapped['ARP_CODE'],
      mapped['arp_code'],
      mapped['customer_code'],
    ]);
    final number = _firstNonEmpty([
          mapped['NUMBER'],
          mapped['number'],
          mapped['fiche_no'],
          mapped['order_number'],
        ]) ??
        '~';
    final lines = _extractLines(mapped);
    final txItems = <Map<String, dynamic>>[];
    for (var i = 0; i < lines.length; i++) {
      final ln = lines[i];
      final master = _firstNonEmpty([
        ln['MASTER_CODE'],
        ln['product_code'],
        ln['item_code'],
        ln['code'],
      ]);
      if (master == null || master.isEmpty) continue;
      txItems.add({
        'TYPE': ln['TYPE'] ?? ln['line_type'] ?? 0,
        'MASTER_CODE': master,
        'QUANTITY': _asDouble(ln['QUANTITY'] ?? ln['quantity']) ?? 0,
        'PRICE': _asDouble(ln['PRICE'] ?? ln['price'] ?? ln['unit_price']) ?? 0,
        if (_asDouble(ln['DISCOUNT_RATE'] ?? ln['discount_percent']) != null)
          'DISCOUNT_RATE':
              _asDouble(ln['DISCOUNT_RATE'] ?? ln['discount_percent']),
        if (_asDouble(ln['VAT_RATE'] ?? ln['vat_rate']) != null)
          'VAT_RATE': _asDouble(ln['VAT_RATE'] ?? ln['vat_rate']),
        'UNIT_CODE': _firstNonEmpty([
              ln['UNIT_CODE'],
              ln['unit_code'],
              ln['unit_name'],
            ]) ??
            'AD',
        'LINE_NO': i + 1,
      });
    }

    final record = <String, dynamic>{
      'TYPE': isPurchase ? 2 : 1,
      'NUMBER': number,
      'DATE': _formatDate(
        mapped['DATE'] ?? mapped['date'] ?? mapped['order_date'],
      ),
      'ARP_CODE': arp ?? '',
      if (_firstNonEmpty([mapped['NOTES1'], mapped['notes']]) != null)
        'NOTES1': _firstNonEmpty([mapped['NOTES1'], mapped['notes']]),
      if (_firstNonEmpty([
            mapped['SALESMAN_CODE'],
            mapped['salesman_code'],
          ]) !=
          null)
        'SALESMAN_CODE': _firstNonEmpty([
          mapped['SALESMAN_CODE'],
          mapped['salesman_code'],
        ]),
      'TRANSACTIONS': {'items': txItems},
    };

    return LogoTigerPushTarget(
      resource: isPurchase ? 'purchaseOrders' : 'salesOrders',
      restRecord: record,
    );
  }

  /// {@template logo_tiger_push_adapter_invoice}
  /// Fatura → salesInvoices | purchaseInvoices (RetailEX TYPE 8/3/1).
  /// {@endtemplate}
  static LogoTigerPushTarget invoiceFromMapped(Map<String, dynamic> mapped) {
    final queueType = LogoPayloadMapper.resolveInvoiceQueueType(
      mapped['type']?.toString() ??
          mapped['invoice_type']?.toString() ??
          mapped['logo_type']?.toString(),
    );
    final logoType = mapped['TRCODE'] as int? ??
        mapped['logo_type'] as int? ??
        LogoPayloadMapper.resolveInvoiceLogoType(queueType) ??
        LogoPayloadMapper.invoiceLogoTypeWholesale;

    final isPurchase = queueType == LogoPayloadMapper.invoiceQueuePurchase;
    final arp = _firstNonEmpty([
      mapped['ARP_CODE'],
      mapped['arp_code'],
      mapped['arpCode'],
      mapped['customer_code'],
    ]);
    final number = _firstNonEmpty([
          mapped['NUMBER'],
          mapped['number'],
          mapped['formatted_number'],
          mapped['invoiceNumber'],
          mapped['invoice_number'],
        ]) ??
        '~';
    final lines = _extractLines(mapped);
    final txItems = <Map<String, dynamic>>[];
    for (var i = 0; i < lines.length; i++) {
      final ln = lines[i];
      final master = _firstNonEmpty([
        ln['MASTER_CODE'],
        ln['product_code'],
        ln['serviceCode'],
        ln['item_code'],
      ]);
      if (master == null || master.isEmpty) continue;
      final qty = _asDouble(ln['QUANTITY'] ?? ln['quantity']) ?? 1;
      final price =
          _asDouble(ln['PRICE'] ?? ln['price'] ?? ln['unit_price']) ?? 0;
      txItems.add({
        'TYPE': ln['TYPE'] ?? (ln['is_service'] == true ? 4 : 0),
        'MASTER_CODE': master,
        'QUANTITY': qty,
        'PRICE': price,
        'TOTAL': _asDouble(ln['TOTAL'] ?? ln['total_amount']) ?? (qty * price),
        if (_asDouble(ln['VAT_RATE'] ?? ln['vat_rate']) != null)
          'VAT_RATE': _asDouble(ln['VAT_RATE'] ?? ln['vat_rate']),
        'UNIT_CODE': _firstNonEmpty([
              ln['UNIT_CODE'],
              ln['unit_code'],
              ln['unit_name'],
            ]) ??
            'AD',
        'LINE_NO': i + 1,
      });
    }

    final record = <String, dynamic>{
      'TYPE': logoType,
      'NUMBER': number,
      'DATE': _formatDate(
        mapped['DATE'] ?? mapped['date'] ?? mapped['invoice_date'],
      ),
      'ARP_CODE': arp ?? '',
      'SOURCE_WH': mapped['SOURCE_WH'] ?? 0,
      if (mapped['SOURCEINDEX'] != null) 'SOURCEINDEX': mapped['SOURCEINDEX'],
      if (_asDouble(mapped['TOTAL_NET'] ?? mapped['total_net']) != null)
        'TOTAL_NET': _asDouble(mapped['TOTAL_NET'] ?? mapped['total_net']),
      if (_asDouble(mapped['TOTAL_VAT'] ?? mapped['total_vat']) != null)
        'TOTAL_VAT': _asDouble(mapped['TOTAL_VAT'] ?? mapped['total_vat']),
      if (_asDouble(
            mapped['TOTAL_GROSS'] ??
                mapped['total_gross'] ??
                mapped['total_amount'],
          ) !=
          null)
        'TOTAL_GROSS': _asDouble(
          mapped['TOTAL_GROSS'] ??
              mapped['total_gross'] ??
              mapped['total_amount'],
        ),
      if (_firstNonEmpty([mapped['NOTES1'], mapped['notes']]) != null)
        'NOTES1': _firstNonEmpty([mapped['NOTES1'], mapped['notes']]),
      if (_firstNonEmpty([
            mapped['SALESMAN_CODE'],
            mapped['salesman_code'],
          ]) !=
          null)
        'SALESMAN_CODE': _firstNonEmpty([
          mapped['SALESMAN_CODE'],
          mapped['salesman_code'],
        ]),
      'TRANSACTIONS': {'items': txItems},
    };

    return LogoTigerPushTarget(
      resource: isPurchase ? 'purchaseInvoices' : 'salesInvoices',
      restRecord: record,
    );
  }

  /// {@template logo_tiger_push_adapter_dispatch}
  /// İrsaliye → salesDispatches | purchaseDispatches.
  /// {@endtemplate}
  static LogoTigerPushTarget dispatchFromMapped(Map<String, dynamic> mapped) {
    final channel = LogoPayloadMapper.resolveDispatchType(
      mapped['dispatch_type']?.toString() ??
          mapped['waybill_type']?.toString() ??
          mapped['type']?.toString(),
    );
    final isPurchase =
        channel == LogoPayloadMapper.dispatchChannelPurchase;
    final arp = _firstNonEmpty([
      mapped['ARP_CODE'],
      mapped['arp_code'],
      mapped['customer_code'],
    ]);
    final number = _firstNonEmpty([
          mapped['NUMBER'],
          mapped['number'],
          mapped['formatted_number'],
          mapped['fiche_no'],
        ]) ??
        '~';
    final lines = _extractLines(mapped);
    final txItems = <Map<String, dynamic>>[];
    for (var i = 0; i < lines.length; i++) {
      final ln = lines[i];
      final master = _firstNonEmpty([
        ln['MASTER_CODE'],
        ln['product_code'],
        ln['item_code'],
      ]);
      if (master == null || master.isEmpty) continue;
      txItems.add({
        'TYPE': ln['TYPE'] ?? ln['line_type'] ?? 0,
        'MASTER_CODE': master,
        'QUANTITY': _asDouble(ln['QUANTITY'] ?? ln['quantity'] ?? ln['AMOUNT']) ??
            0,
        'PRICE': _asDouble(ln['PRICE'] ?? ln['price'] ?? ln['unit_price']) ?? 0,
        'UNIT_CODE': _firstNonEmpty([
              ln['UNIT_CODE'],
              ln['unit_code'],
            ]) ??
            'AD',
        'LINE_NO': i + 1,
      });
    }

    final record = <String, dynamic>{
      'TYPE': isPurchase ? 1 : 8,
      'NUMBER': number,
      'DATE': _formatDate(
        mapped['DATE'] ?? mapped['date'] ?? mapped['waybill_date'],
      ),
      'ARP_CODE': arp ?? '',
      if (_firstNonEmpty([mapped['NOTES1'], mapped['notes']]) != null)
        'NOTES1': _firstNonEmpty([mapped['NOTES1'], mapped['notes']]),
      if (_firstNonEmpty([
            mapped['SOURCE_WH'],
            mapped['warehouse_code'],
          ]) !=
          null)
        'SOURCE_WH': mapped['SOURCE_WH'] ?? mapped['warehouse_code'],
      'TRANSACTIONS': {'items': txItems},
    };

    return LogoTigerPushTarget(
      resource: isPurchase ? 'purchaseDispatches' : 'salesDispatches',
      restRecord: record,
    );
  }

  static List<Map<String, dynamic>> _extractLines(Map<String, dynamic> mapped) {
    final raw = mapped['TRANSACTIONS'] ??
        mapped['transactions'] ??
        mapped['lines'] ??
        mapped['items'];
    if (raw is Map) {
      final items = raw['items'] ?? raw['Items'] ?? raw['lines'];
      if (items is List) {
        return items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }

  /// Logo DATE — `YYYY-MM-DD` (RetailEX formatLogoDate).
  static String _formatDate(dynamic raw) {
    if (raw == null) {
      return DateTime.now().toIso8601String().substring(0, 10);
    }
    if (raw is DateTime) {
      return raw.toIso8601String().substring(0, 10);
    }
    final s = raw.toString().trim();
    if (s.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
      return s.substring(0, 10);
    }
    final parsed = DateTime.tryParse(s);
    if (parsed != null) {
      return parsed.toIso8601String().substring(0, 10);
    }
    return DateTime.now().toIso8601String().substring(0, 10);
  }
}
