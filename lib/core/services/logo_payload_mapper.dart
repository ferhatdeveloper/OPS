// Dosya Adı: logo_payload_mapper.dart
// Açıklama: SFA yerel varlıklarını ExfinApi Logo ERP payload formatına dönüştürür
// Oluşturulma Tarihi: 2026-07-15
// Geliştirici: EXFINOPS Team
// Son Güncelleme: 2026-07-26

/// Yerel SFA modellerini ExfinApi `/api/v1/logo/erp/*` beklediği alanlara map eder.
///
/// Backend `_transfer_*_via_objects` / `_normalize_order_payload` alanları:
/// - Header: `customer_code` / `ARP_CODE`, `fiche_no` / `number`, `date`
/// - Satır: `product_code` / `MASTER_CODE`, `quantity` / `QUANTITY`,
///   `price` / `PRICE`, `discount_percent` / `DISCOUNT_RATE`
/// - Sipariş kanalı: `type` / `order_type` = `sales` | `purchase` (≠ fatura TYPE 8)
/// - İrsaliye kanalı: `type` / `dispatch_type` = wholesale|purchase / waybill_*
///   (≠ fatura `invoice_type` / TRCODE 8–3 flatten)
/// - Ziyaret: `reason_code` → `visit_type` / `SPECODE` (VisitReasonMaster)
/// - Tahsilat çek/senet: snake + LG_CSCARD (`SERINO`, `BANKNAME`, `DUEDATE`…)
class LogoPayloadMapper {
  LogoPayloadMapper._();

  /// [visitEntityType]: JobQueue `entity_type` (ziyaret sync)
  static const String visitEntityType = 'visit';

  /// Ziyaret sebebi — rutin (VisitReasonMaster.ROUTINE)
  static const String visitReasonRoutine = 'ROUTINE';

  /// Ziyaret sebebi — tahsilat
  static const String visitReasonCollection = 'COLLECTION';

  /// Ziyaret sebebi — kampanya
  static const String visitReasonCampaign = 'CAMPAIGN';

  /// Ziyaret sebebi — şikayet
  static const String visitReasonComplaint = 'COMPLAINT';

  /// Ziyaret sebebi — sipariş
  static const String visitReasonOrder = 'ORDER';

  /// Ziyaret sebebi — stok kontrol
  static const String visitReasonStock = 'STOCK';

  /// Ziyaret sebebi — teslimat
  static const String visitReasonDelivery = 'DELIVERY';

  /// Ziyaret sebebi — yeni cari
  static const String visitReasonNewCustomer = 'NEW_CUSTOMER';

  /// Ziyaret sebebi — diğer / bilinmeyen
  static const String visitReasonOther = 'OTHER';

  /// [visitReasonCodes]: Sync için kanonik sebep kodları
  static const List<String> visitReasonCodes = [
    visitReasonRoutine,
    visitReasonCollection,
    visitReasonCampaign,
    visitReasonComplaint,
    visitReasonOrder,
    visitReasonStock,
    visitReasonDelivery,
    visitReasonNewCustomer,
    visitReasonOther,
  ];

  /// [dispatchLocalWholesale]: Yerel toptan sevk irsaliye anahtarı
  static const String dispatchLocalWholesale = 'waybill_wholesale';

  /// [dispatchLocalPurchase]: Yerel satın alma irsaliye anahtarı
  static const String dispatchLocalPurchase = 'waybill_purchase';

  /// [dispatchChannelWholesale]: Logo dispatches/sync satış kanalı
  static const String dispatchChannelWholesale = 'wholesale';

  /// [dispatchChannelPurchase]: Logo dispatches/sync alış kanalı
  static const String dispatchChannelPurchase = 'purchase';

  /// Fatura kuyruk anahtarı — toptan satış (Logo TYPE 8)
  static const String invoiceQueueWholesale = 'wholesale';

  /// Fatura kuyruk anahtarı — satış iade (Logo TYPE 3)
  static const String invoiceQueueReturn = 'return';

  /// Fatura kuyruk anahtarı — alış (≠ TYPE 3)
  static const String invoiceQueuePurchase = 'purchase';

  /// Fatura kuyruk anahtarı — van / perakende
  static const String invoiceQueueRetail = 'retail';

  /// Stok fişi kuyruk — üretimden giriş (≠ fatura TYPE 8)
  static const String stockSlipProductionReceipt = 'production_receipt';

  /// Stok fişi kuyruk — konsinye (≠ fatura TYPE 8)
  static const String stockSlipConsignment = 'consignment';

  /// Logo Objects toptan satış faturası TRCODE
  static const int invoiceLogoTypeWholesale = 8;

  /// Logo Objects satış iade faturası TRCODE
  static const int invoiceLogoTypeReturn = 3;

  /// Logo Objects alış faturası TRCODE (firma şeması doğrulanmalı; varsayılan 1)
  static const int invoiceLogoTypePurchase = 1;

  /// {@template resolve_invoice_queue_type}
  /// Yerel fatura tipi → kuyruk / ExfinApi `type` anahtarı.
  ///
  /// Dönüş: [invoiceQueueWholesale] | [invoiceQueueReturn] |
  /// [invoiceQueuePurchase] | [invoiceQueueRetail]
  ///
  /// Kurallar:
  /// - Toptan → `wholesale` (Logo TYPE **8**)
  /// - Satış iade → `return` (Logo TYPE **3**); wholesale'e flatten yok
  /// - Satın alma → `purchase` (**≠ TYPE 3**)
  /// {@endtemplate}
  static String resolveInvoiceQueueType(String? invoiceType) {
    // TR İ → i̇ (combining dot) tuzağı: nokta kaldır, ı→i
    final t = (invoiceType ?? '')
        .toLowerCase()
        .replaceAll('\u0307', '')
        .replaceAll('ı', 'i')
        .trim();
    if (t.isEmpty) return invoiceQueueWholesale;

    // İade TYPE 3 — wholesale flatten yok; satın alma ile karıştırma
    if (t == '3' ||
        t == invoiceQueueReturn ||
        t.endsWith('_3') ||
        t.contains('(3)') ||
        t.contains('sales_return') ||
        t.contains('wholesale_return') ||
        t.contains('return') ||
        t.contains('iade')) {
      return invoiceQueueReturn;
    }

    // Satın alma — TYPE 3 değil
    if (t == invoiceQueuePurchase ||
        t.contains('purchase') ||
        t.contains('satin') ||
        t.contains('alis') ||
        t == 'buy') {
      return invoiceQueuePurchase;
    }

    // Van / perakende — TYPE 8 flatten yok
    if (t == invoiceQueueRetail ||
        t.contains('retail') ||
        t.contains('van_sales') ||
        t.contains('van sales') ||
        t.contains('sicak')) {
      return invoiceQueueRetail;
    }

    // Toptan TYPE 8
    if (t == '8' ||
        t == invoiceQueueWholesale ||
        t.endsWith('_8') ||
        t.contains('(8)') ||
        t.contains('wholesale') ||
        t.contains('toptan')) {
      return invoiceQueueWholesale;
    }

    return invoiceQueueWholesale;
  }

  /// {@template resolve_invoice_logo_type}
  /// Kuyruk tipi / ham fatura tipi → Logo numeric TYPE.
  ///
  /// Dönüş:
  /// - wholesale → **8**
  /// - return → **3**
  /// - purchase → **1** (≠ 3)
  /// - retail → `null` (van kanalı; TYPE 8 flatten yok)
  /// {@endtemplate}
  static int? resolveInvoiceLogoType(String? invoiceTypeOrQueue) {
    final q = resolveInvoiceQueueType(invoiceTypeOrQueue);
    switch (q) {
      case invoiceQueueReturn:
        return invoiceLogoTypeReturn;
      case invoiceQueuePurchase:
        return invoiceLogoTypePurchase;
      case invoiceQueueRetail:
        return null;
      case invoiceQueueWholesale:
      default:
        return invoiceLogoTypeWholesale;
    }
  }

  /// {@template resolve_order_api_type}
  /// Yerel sipariş tipini ExfinApi sipariş kanalına çözer.
  ///
  /// Parametreler:
  /// - [raw]: `sales` / `purchase` / `order_sales` / `order_purchase` / TR varyant
  ///
  /// Dönüş değeri:
  /// - [String]: yalnızca `sales` veya `purchase` (fatura wholesale/return değil)
  /// {@endtemplate}
  static String resolveOrderApiType(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v.contains('purchase') ||
        v.contains('satin') ||
        v.contains('alış') ||
        v.contains('alis') ||
        v == 'buy') {
      return 'purchase';
    }
    return 'sales';
  }

  /// {@template order_channel_key}
  /// Muhasebe checklist yerel anahtarı: `order_sales` | `order_purchase`.
  /// {@endtemplate}
  static String orderChannelKey(String apiType) =>
      apiType == 'purchase' ? 'order_purchase' : 'order_sales';

  /// Sipariş aktarım gövdesi (POST /api/v1/logo/erp/orders)
  ///
  /// [orderType]: Satış / Alış; verilmezse [order] içinden okunur.
  /// Satır `TYPE` = Logo kalem tipi (0 mal / 4 hizmet); fiş kanalı değildir.
  static Map<String, dynamic> orderFromLocal({
    required Map<String, dynamic> order,
    required List<Map<String, dynamic>> items,
    required String customerCode,
    String? salesmanCode,
    String? orderType,
  }) {
    final ficheNo = _firstNonEmpty([
      order['fiche_no'],
      order['order_number'],
      order['number'],
      order['id'],
    ]);
    final dateRaw = order['order_date'] ?? order['date'] ?? order['created_at'];
    final apiType = resolveOrderApiType(
      orderType ??
          order['order_type']?.toString() ??
          order['type']?.toString() ??
          order['order_channel']?.toString(),
    );
    final channel = orderChannelKey(apiType);

    final lines = items.map((item) {
      final productCode = _firstNonEmpty([
        item['product_code'],
        item['MASTER_CODE'],
        item['item_code'],
        item['code'],
        item['product_id'],
      ]);
      // Satır TYPE: Logo Objects kalem (0/4); sipariş sales/purchase değil
      final lineType = item['TYPE'] ?? item['line_type'] ?? 0;
      // order_items.discount_percent → Logo Objects DISCOUNT_RATE (%)
      final discountPercent = _asDouble(
        item['discount_percent'] ??
            item['DISCOUNT_RATE'] ??
            item['discount_rate'],
      );
      return {
        'product_code': productCode,
        'MASTER_CODE': productCode,
        'quantity': _asDouble(item['quantity']),
        'QUANTITY': _asDouble(item['quantity']),
        'price': _asDouble(item['price'] ?? item['unit_price']),
        'PRICE': _asDouble(item['price'] ?? item['unit_price']),
        'unit_price': _asDouble(item['price'] ?? item['unit_price']),
        'discount_percent': discountPercent,
        'DISCOUNT_RATE': discountPercent,
        if (item['unit_name'] != null) 'unit_code': item['unit_name'],
        'TYPE': lineType,
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
      // Sipariş kanalı — fatura TYPE 8 / wholesale'e flatten yok
      'type': apiType,
      'order_type': apiType,
      'order_channel': channel,
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

    final rawType = type.isNotEmpty
        ? type
        : (invoice['type'] ?? invoice['invoice_type'])?.toString() ??
            invoiceQueueWholesale;
    final queueType = resolveInvoiceQueueType(rawType);
    final logoType = resolveInvoiceLogoType(queueType);

    final lines = items.map((item) {
      final productCode = _firstNonEmpty([
        item['product_code'],
        item['MASTER_CODE'],
        item['serviceCode'],
        item['item_code'],
        item['product_id'],
      ]);
      // Satır TYPE: Logo kalem (0 mal / 4 hizmet) — fiş TYPE 8/3 değil
      final isService = queueType == 'service' ||
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
      // Fiş kanalı + Logo TRCODE (8 toptan / 3 iade / 1 alış)
      'type': queueType,
      'invoice_type': queueType,
      if (logoType != null) 'logo_type': logoType,
      if (logoType != null) 'TRCODE': logoType,
      if (salesmanCode != null && salesmanCode.isNotEmpty)
        'salesman_code': salesmanCode,
      'lines': lines,
    };
  }

  /// Logo CSCARD DOC: çek = 1
  static const int collectionDocCheck = 1;

  /// Logo CSCARD DOC: senet = 2
  static const int collectionDocNote = 2;

  /// {@template collection_cl_doc}
  /// `payment_type` → Logo CL/CSCARD `DOC` (çek=1, senet=2); diğerleri null.
  /// {@endtemplate}
  static int? resolveCollectionClDoc(String? paymentType) {
    final t = (paymentType ?? '').trim().toLowerCase();
    if (t == 'check' || t == 'cek' || t == 'çek') {
      return collectionDocCheck;
    }
    if (t == 'note' || t == 'senet' || t == 'promissory') {
      return collectionDocNote;
    }
    return null;
  }

  /// Tahsilat (collections/sync Objects) gövdesi.
  ///
  /// Çek/senet: ExfinApi snake_case + Logo CL/CSCARD alan adları (dual-write).
  /// LG_CSCARD: SERINO, BANKNAME, BNBRANCHNO, DUEDATE, OWING, BNACCOUNTNO, CITY.
  /// Objects alias: SERIAL_NR, BANK_TITLE, DUE_DATE, NEWSERINO.
  static Map<String, dynamic> collectionFromLocal({
    required String customerCode,
    required double amount,
    String? paymentType,
    String? safeCode,
    String? description,
    String? customerName,
    String? documentNo,
    String? currencyCode,
    String? salesmanCode,
    String? specialCode1,
    String? bankName,
    String? branchName,
    String? checkNumber,
    DateTime? dueDate,
    String? endorsement,
    String? originalDebtor,
    String? workplace,
    String? accountNumber,
  }) {
    final resolvedSafe = (safeCode != null && safeCode.trim().isNotEmpty)
        ? safeCode.trim()
        : '01';
    final resolvedDesc =
        (description != null && description.trim().isNotEmpty)
            ? description.trim()
            : 'SFA Tahsilat';
    final resolvedType = paymentType ?? 'cash';
    final clDoc = resolveCollectionClDoc(resolvedType);

    final bank = _trimOrNull(bankName);
    final branch = _trimOrNull(branchName);
    final checkNo = _trimOrNull(checkNumber);
    final endorse = _trimOrNull(endorsement);
    final debtor = _trimOrNull(originalDebtor);
    final place = _trimOrNull(workplace);
    final account = _trimOrNull(accountNumber);
    final dueFormatted =
        dueDate != null ? _formatDate(dueDate) : null;

    return {
      'customer_code': customerCode,
      'ARP_CODE': customerCode,
      'amount': amount,
      'AMOUNT': amount,
      'payment_type': resolvedType,
      'safe_code': resolvedSafe,
      'CODE': resolvedSafe,
      'description': resolvedDesc,
      'DESCRIPTION': resolvedDesc,
      if (clDoc != null) 'DOC': clDoc,
      if (customerName != null) 'customer_name': customerName,
      if (documentNo != null && documentNo.trim().isNotEmpty) ...{
        'fiche_no': documentNo.trim(),
        'number': documentNo.trim(),
        'document_no': documentNo.trim(),
      },
      if (currencyCode != null && currencyCode.trim().isNotEmpty)
        'currency_code': currencyCode.trim(),
      if (salesmanCode != null && salesmanCode.trim().isNotEmpty)
        'salesman_code': salesmanCode.trim(),
      if (specialCode1 != null && specialCode1.trim().isNotEmpty)
        'special_code_1': specialCode1.trim(),
      // Banka → BANKNAME (CSCARD) / BANK_TITLE (Objects)
      if (bank != null) ...{
        'bank_name': bank,
        'BANKNAME': bank,
        'BANK_TITLE': bank,
      },
      // Şube → BNBRANCHNO
      if (branch != null) ...{
        'branch_name': branch,
        'BNBRANCHNO': branch,
      },
      // Çek no → SERINO / SERIAL_NR / NEWSERINO
      if (checkNo != null) ...{
        'check_number': checkNo,
        'SERINO': checkNo,
        'SERIAL_NR': checkNo,
        'NEWSERINO': checkNo,
      },
      // Vade → DUEDATE / DUE_DATE
      if (dueDate != null && dueFormatted != null) ...{
        'due_date': dueDate.toIso8601String(),
        'DUEDATE': dueFormatted,
        'DUE_DATE': dueFormatted,
      },
      if (endorse != null) 'endorsement': endorse,
      // Asıl borçlu → OWING (CSCARD Borçlu)
      if (debtor != null) ...{
        'original_debtor': debtor,
        'OWING': debtor,
      },
      // İşyeri / ödeme yeri → CITY
      if (place != null) ...{
        'workplace': place,
        'CITY': place,
      },
      // Hesap no → BNACCOUNTNO
      if (account != null) ...{
        'account_number': account,
        'BNACCOUNTNO': account,
      },
    };
  }

  /// {@template _trim_or_null_mapper}
  /// Boş / whitespace string → null.
  /// {@endtemplate}
  static String? _trimOrNull(String? value) {
    if (value == null) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  /// {@template virmanFromLocal}
  /// Kasa↔kasa virman payload — ARP yok; tahsilat TYPE'ına flatten edilmez.
  ///
  /// Parametreler:
  /// - [amount]: Virman tutarı
  /// - [fromSafeCode]: Kaynak kasa (safe_code)
  /// - [toSafeCode]: Hedef kasa (target_safe_code)
  /// - [description]: Açıklama
  ///
  /// Dönüş değeri:
  /// - [Map]: collections/sync gövdesi (`payment_type=virman`)
  /// {@endtemplate}
  static Map<String, dynamic> virmanFromLocal({
    required double amount,
    required String fromSafeCode,
    required String toSafeCode,
    String? description,
  }) {
    final from = fromSafeCode.trim();
    final to = toSafeCode.trim();
    final resolvedDesc =
        (description != null && description.trim().isNotEmpty)
            ? description.trim()
            : 'SFA Virman';
    return {
      'payment_type': 'virman',
      'amount': amount,
      'safe_code': from,
      'CODE': from,
      'target_safe_code': to,
      'TARGET_CODE': to,
      'description': resolvedDesc,
      'DESCRIPTION': resolvedDesc,
    };
  }

  /// {@template resolveDispatchType}
  /// Yerel irsaliye anahtarı → Logo `dispatches/sync` kanal tipi.
  ///
  /// Dönüş: [dispatchChannelWholesale] | [dispatchChannelPurchase]
  /// (string kanal; fatura TRCODE `8`/`3` veya `invoice_type` değil).
  ///
  /// Parametreler:
  /// - [localOrChannel]: `waybill_wholesale` / `waybill_purchase` /
  ///   `wholesale` / `purchase` / menü literal
  /// {@endtemplate}
  static String resolveDispatchType(String? localOrChannel) {
    final t = (localOrChannel ?? '').toLowerCase().trim();
    if (t.isEmpty) return dispatchChannelWholesale;
    if (t == dispatchLocalPurchase ||
        t == dispatchChannelPurchase ||
        t.contains('waybill_purchase') ||
        t.contains('purchase') ||
        t.contains('satin') ||
        t.contains('satın') ||
        t.contains('alis') ||
        t.contains('alış')) {
      return dispatchChannelPurchase;
    }
    if (t == dispatchLocalWholesale ||
        t == dispatchChannelWholesale ||
        t.contains('waybill_wholesale') ||
        t.contains('wholesale') ||
        t.contains('toptan') ||
        t.contains('sevk')) {
      return dispatchChannelWholesale;
    }
    return dispatchChannelWholesale;
  }

  /// {@template localDispatchKey}
  /// Kanal tipi → yerel anahtar (`waybill_*`; ≠ `wholesale_invoice_8`).
  /// {@endtemplate}
  static String localDispatchKey(String? localOrChannel) {
    final channel = resolveDispatchType(localOrChannel);
    return channel == dispatchChannelPurchase
        ? dispatchLocalPurchase
        : dispatchLocalWholesale;
  }

  /// {@template isDispatchStockInbound}
  /// Satın alma irsaliyesinde stok giriş yönü.
  /// {@endtemplate}
  static bool isDispatchStockInbound(String? localOrChannel) =>
      resolveDispatchType(localOrChannel) == dispatchChannelPurchase;

  /// İrsaliye (dispatches/sync) header + satırlar.
  ///
  /// Fatura alanları (`invoice_type`, numeric TYPE 8) yazılmaz.
  static Map<String, dynamic> dispatchHeaderFromLocal({
    required String customerCode,
    Map<String, dynamic>? header,
    String? ficheNo,
    String? dispatchType,
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
    final rawType = dispatchType ??
        h['dispatch_type'] ??
        h['waybill_type'] ??
        h['type'];
    final channel = resolveDispatchType(
      rawType is String ? rawType : rawType?.toString(),
    );
    final localKey = localDispatchKey(channel);
    return {
      'customer_code': customerCode,
      'ARP_CODE': customerCode,
      'formatted_number': number ?? '~',
      'created_at': dateRaw is DateTime
          ? dateRaw.toIso8601String()
          : dateRaw.toString(),
      'date': _formatDate(dateRaw),
      // Dispatch kanalı — invoice TYPE 8/3 flatten yasak
      'type': channel,
      'dispatch_type': localKey,
      'waybill_type': localKey,
      'entity': 'dispatch',
      if (h['customer_ref'] != null) 'customer_ref': h['customer_ref'],
      if (h['notes'] != null) 'notes': h['notes'],
      if (h['warehouse_code'] != null) 'warehouse_code': h['warehouse_code'],
      if (h['plate'] != null || h['plaka'] != null)
        'plate': h['plate'] ?? h['plaka'],
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
        // Satır TYPE: mal/hizmet (0/4) — fiş invoice TRCODE değil
        'TYPE': item['TYPE'] ?? item['line_type'] ?? 0,
      };
    }).toList();
  }

  /// {@template resolve_visit_reason_code}
  /// Yerel `visits.reason_code` / alias → kanonik sync kodu.
  ///
  /// Parametreler:
  /// - [raw]: Master kod, küçük harf veya TR alias
  ///
  /// Dönüş değeri:
  /// - [String?]: VisitReasonMaster kodu; boşsa null; bilinmeyense OTHER
  /// {@endtemplate}
  static String? resolveVisitReasonCode(String? raw) {
    final original = (raw ?? '').trim();
    if (original.isEmpty) return null;

    final t = original
        .toUpperCase()
        .replaceAll('\u0307', '')
        .replaceAll('İ', 'I')
        .replaceAll('ı', 'I')
        .replaceAll(' ', '_')
        .replaceAll('-', '_');

    if (visitReasonCodes.contains(t)) return t;

    final lower = original
        .toLowerCase()
        .replaceAll('\u0307', '')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .trim();

    if (lower.contains('rutin') || lower == 'routine') {
      return visitReasonRoutine;
    }
    if (lower.contains('tahsil') || lower.contains('collection')) {
      return visitReasonCollection;
    }
    if (lower.contains('kampanya') || lower.contains('campaign')) {
      return visitReasonCampaign;
    }
    if (lower.contains('sikayet') ||
        lower.contains('şikayet') ||
        lower.contains('complaint')) {
      return visitReasonComplaint;
    }
    if (lower.contains('siparis') ||
        lower.contains('sipariş') ||
        lower.contains('order')) {
      return visitReasonOrder;
    }
    if (lower.contains('stok') || lower.contains('stock')) {
      return visitReasonStock;
    }
    if (lower.contains('teslim') || lower.contains('delivery')) {
      return visitReasonDelivery;
    }
    if (lower.contains('yeni') ||
        lower.contains('new_customer') ||
        lower.contains('new customer')) {
      return visitReasonNewCustomer;
    }
    if (lower.contains('diger') ||
        lower.contains('diğer') ||
        lower.contains('other')) {
      return visitReasonOther;
    }

    return visitReasonOther;
  }

  /// {@template visit_from_local}
  /// Ziyaret aktarım gövdesi (Postgres `visit_type` + Logo SPECODE).
  ///
  /// `reason_code` / `visit_type` / `visit_reason` alanlarından kanonik
  /// kod üretir; yoksa SPECODE alanları eklenmez.
  ///
  /// Parametreler:
  /// - [visit]: Yerel visits satırı
  /// - [customerCode]: Cari kodu (zorunlu)
  /// - [customerName]: Cari unvanı
  /// - [salesmanCode]: Plasiyer kodu
  ///
  /// Dönüş değeri:
  /// - [Map]: Sync / Logo uyumlu payload
  /// {@endtemplate}
  static Map<String, dynamic> visitFromLocal({
    required Map<String, dynamic> visit,
    required String customerCode,
    String? customerName,
    String? salesmanCode,
  }) {
    final reason = resolveVisitReasonCode(
      _firstNonEmpty([
        visit['reason_code'],
        visit['visit_type'],
        visit['visit_reason'],
        visit['SPECODE'],
      ]),
    );

    final checkInRaw = visit['check_in_at'] ?? visit['check_in_time'];
    final checkOutRaw = visit['check_out_at'] ?? visit['check_out_time'];
    final lat = visit['check_in_lat'] ?? visit['check_in_latitude'];
    final lng = visit['check_in_long'] ??
        visit['check_in_lng'] ??
        visit['check_in_longitude'];

    return {
      'customer_code': customerCode,
      if (customerName != null && customerName.trim().isNotEmpty)
        'customer_name': customerName.trim(),
      'local_visit_id': visit['id']?.toString(),
      'status': visit['status']?.toString() ?? 'Open',
      'notes': visit['notes']?.toString() ?? '',
      if (reason != null) ...{
        'reason_code': reason,
        'visit_type': reason,
        'SPECODE': reason,
        'special_code': reason,
      },
      if (checkInRaw != null) 'check_in_time': checkInRaw.toString(),
      if (checkOutRaw != null) 'check_out_time': checkOutRaw.toString(),
      if (lat != null) 'check_in_lat': _asDouble(lat),
      if (lng != null) 'check_in_lng': _asDouble(lng),
      if (visit['duration_minutes'] != null)
        'duration_minutes': visit['duration_minutes'],
      if (salesmanCode != null && salesmanCode.isNotEmpty)
        'salesman_code': salesmanCode,
    };
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

  /// [stockTransferEntityType]: JobQueue entity_type (ambar transfer)
  static const String stockTransferEntityType = 'stock_transfer';

  /// [stockTransferLocalType]: Yerel dens ambar transfer anahtarı
  static const String stockTransferLocalType = 'warehouse_transfer';

  /// {@template stock_transfer_from_local}
  /// Ambar transferi dens → Logo stock-transfers/sync gövdesi.
  ///
  /// Fatura/sipariş TYPE flatten yok; `entity` = stock_transfer.
  /// {@endtemplate}
  static Map<String, dynamic> stockTransferFromLocal({
    required String batchId,
    required List<String> transferIds,
    required String fromWarehouse,
    required String toWarehouse,
    required DateTime date,
    required List<Map<String, dynamic>> lines,
    Map<String, dynamic>? source,
    Map<String, dynamic>? target,
  }) {
    final mappedLines = lines.map((item) {
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
        'QUANTITY': _asDouble(item['quantity']),
        if (item['transfer_id'] != null) 'transfer_id': item['transfer_id'],
        if (item['unit_name'] != null) 'unit_name': item['unit_name'],
      };
    }).toList();

    return {
      'id': batchId,
      'batch_id': batchId,
      'transfer_ids': transferIds,
      'entity': stockTransferEntityType,
      'type': stockTransferLocalType,
      'transfer_type': stockTransferLocalType,
      'from_warehouse': fromWarehouse,
      'to_warehouse': toWarehouse,
      'from_warehouse_code': fromWarehouse,
      'to_warehouse_code': toWarehouse,
      'SOURCE_WH': fromWarehouse,
      'TARGET_WH': toWarehouse,
      'date': _formatDate(date),
      'created_at': date.toIso8601String(),
      'lines': mappedLines,
      'items': mappedLines,
      if (source != null) 'source': source,
      if (target != null) 'target': target,
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
