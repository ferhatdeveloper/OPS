# AI Resim → Fatura (Invoice OCR)

**Tarih:** 2026-07-28  
**Durum:** Uygulandı (commit yok)

## Özet

Fotoğraf / galeri → multimodal OCR (kötü el yazısı dahil) → dens doğrulama
listesi → kullanıcı onayı → mevcut `invoiceProvider` ile fatura oluşturma.
Otomatik sessiz fatura yok.

## Akış

1. Dens ekran: kamera + galeri
2. Tip chip: Alış / Satış / Gider / Diğer
3. `AiGateway.invoiceOcr` (use-case `invoiceOcr`)
4. Düzenlenebilir satırlar + cari fuzzy eşleme
5. Onayla → `startNewInvoice` + `addItem` + `saveInvoice`
6. Key yok / ağ yok → l10n + yerel görüntü + AI bekleyen kuyruk

## Mimari

| Parça | Yol |
|-------|-----|
| Use-case | `AiUseCase.invoiceOcr` |
| Gateway | `AiGateway.invoiceOcr` |
| Modül | `lib/modules/field_sales/ai_invoice_scan/` |
| Route | `/field-sales/invoice-scan` |
| Menü | `sub_oth_invoice_scan` (Diğer) |

## Güvenlik

- Görüntü / API key loglanmaz
- Kullanıcı onayı zorunlu

## Test

- `test/modules/field_sales/ai_invoice_scan/invoice_ocr_parse_test.dart`
