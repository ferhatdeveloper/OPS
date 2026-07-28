// Dosya Adı: invoice_ocr_parse_test.dart
// Açıklama: Fatura OCR JSON → InvoiceOcrDraft / satır modeli unit test
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/modules/field_sales/ai_invoice_scan/engine/invoice_ocr_analyzer.dart';
import 'package:exfin_ops/modules/field_sales/ai_invoice_scan/model/invoice_ocr_line.dart';
import 'package:exfin_ops/modules/field_sales/ai_vision_competitor/engine/product_fuzzy_matcher.dart';
import 'package:exfin_ops/modules/field_sales/products/model/product_catalog_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('JSON obje → taslak satırlar', () {
    const raw = '''
    {
      "party_name": "ABC Market",
      "party_code": "C-100",
      "document_no": "FTR-9",
      "document_date": "2026-07-28",
      "currency": "TRY",
      "confidence": 0.9,
      "lines": [
        {
          "name": "Süt 1L",
          "sku": "STK-1",
          "quantity": 2,
          "unit": "ADET",
          "unit_price": 25.5,
          "vat_rate": 1,
          "line_total": 51,
          "confidence": 0.88
        }
      ]
    }
    ''';
    final draft = InvoiceOcrAnalyzer.parseDraftJson(raw);
    expect(draft, isNotNull);
    expect(draft!.partyName, 'ABC Market');
    expect(draft.partyCode, 'C-100');
    expect(draft.documentNo, 'FTR-9');
    expect(draft.lines, hasLength(1));
    expect(draft.lines.first.name, 'Süt 1L');
    expect(draft.lines.first.quantity, 2);
    expect(draft.lines.first.effectiveUnitPrice, 25.5);
    expect(draft.lines.first.vatRate, 1);
  });

  test('fence + düşük confidence → isUncertain', () {
    const raw = '''
```json
{"party_name":"X","lines":[{"name":"Y","confidence":0.2,"unit_price":10}]}
```
''';
    final draft = InvoiceOcrAnalyzer.parseDraftJson(raw);
    expect(draft, isNotNull);
    expect(draft!.lines.first.isUncertain, isTrue);
  });

  test('boş / geçersiz → null veya hasContent false', () {
    expect(InvoiceOcrAnalyzer.parseDraftJson(''), isNull);
    expect(InvoiceOcrAnalyzer.parseDraftJson('not json'), isNull);
  });

  test('ürün fuzzy eşleme', () {
    final analyzer = InvoiceOcrAnalyzer();
    final catalog = [
      const ProductCatalogRow(
        id: 'p1',
        code: 'STK-1',
        name: 'Süt 1 Litre',
        barcode: '8690001',
      ),
    ];
    final matches = analyzer.matchProducts(
      lines: const [
        InvoiceOcrLine(name: 'Sut 1L', sku: '8690001', confidence: 0.9),
      ],
      catalog: catalog,
    );
    expect(matches.first.hasProductMatch, isTrue);
    expect(matches.first.matchedProductId, 'p1');
  });

  test('cari kod tam eşleşme', () {
    final analyzer = InvoiceOcrAnalyzer();
    final m = analyzer.matchCustomer(
      partyName: 'ABC',
      partyCode: 'C-100',
      customers: [
        {'id': 'u1', 'code': 'C-100', 'name': 'ABC Market'},
      ],
    );
    expect(m.hasMatch, isTrue);
    expect(m.customerId, 'u1');
    expect(m.score, 1);
  });

  test('ProductFuzzyMatcher.similarity temel', () {
    expect(ProductFuzzyMatcher.similarity('Süt', 'Süt'), 1);
  });
}
