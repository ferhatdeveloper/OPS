---
name: muhasebe-yonetimi
description: Use when implementing accounting, finance, invoicing, or payment features - covers Turkish accounting standards, e-Fatura/e-İrsaliye GİB compliance, cari hesap management, and financial reporting for the saha satış application
---

# Muhasebe Yönetimi Skill

## Türk Muhasebe ve e-Dönüşüm Standartları

### Belge Türleri

| Belge | Açıklama | e-Dönüşüm |
|-------|----------|-----------|
| Fatura | Satış faturası | e-Fatura / e-Arşiv |
| İrsaliye | Sevk irsaliyesi | e-İrsaliye |
| Sipariş | Sipariş belgesi | - |
| İade Faturası | Müşteriden iade | e-Fatura |
| Tahsilat Makbuzu | Ödeme alındı belgesi | - |
| SMM | Serbest meslek makbuzu | e-SMM |

### e-Fatura Mükellef Tipleri
```dart
enum InvoiceType {
  eFatura,    // GİB kayıtlı mükelleflere
  eArsiv,     // GİB kayıtlı olmayanlara (artık zorunlu)
}

// VKN sorgulama ile otomatik belirleme
Future<InvoiceType> detectInvoiceType(String taxNumber) async {
  final isRegistered = await gibService.checkMukellef(taxNumber);
  return isRegistered ? InvoiceType.eFatura : InvoiceType.eArsiv;
}
```

### KDV Oranları (Türkiye 2024+)
```dart
const Map<String, double> kdvRates = {
  'standart': 0.20,    // %20 - genel
  'indirimli1': 0.10,  // %10 - bazı gıda
  'indirimli2': 0.01,  // %1 - bazı temel gıda
  'muaf': 0.00,        // %0 - muaf
};
```

## Cari Hesap Yönetimi

### Bakiye Hesaplama
```dart
// Borç - Alacak = Bakiye
double calculateBalance(List<Transaction> transactions) {
  return transactions.fold(0.0, (sum, t) => sum + t.debit - t.credit);
}

// Pozitif = müşteri borçlu, Negatif = bize borçlu
```

### Yaşlandırma Raporu
```dart
class AgingReport {
  final double current;      // 0-30 gün
  final double days30to60;   // 30-60 gün
  final double days60to90;   // 60-90 gün
  final double over90;       // 90+ gün
}

AgingReport generateAging(List<Invoice> openInvoices) {
  final now = DateTime.now();
  // Her fatura için vade tarihinden bugüne kaç gün geçmiş hesapla
  ...
}
```

### Kredi Limiti Kontrolü
```dart
Future<CreditCheckResult> checkCreditLimit(
  String customerId,
  double orderAmount,
) async {
  final customer = await customerRepo.getById(customerId);
  final openBalance = await getOpenBalance(customerId);
  final newTotal = openBalance + orderAmount;

  if (newTotal > customer.creditLimit) {
    return CreditCheckResult.exceeded(
      limit: customer.creditLimit,
      current: openBalance,
      requested: orderAmount,
    );
  }
  return CreditCheckResult.ok();
}
```

## Ödeme Tipleri

### Çek / Senet Modeli
```dart
class CheckPayment {
  final String checkNumber;
  final String bankName;
  final String bankBranch;
  final DateTime issueDate;
  final DateTime dueDate;
  final double amount;
  final String drawer;  // Keşideci
}

class PromissoryNote {
  final String noteNumber;
  final String debtor;   // Borçlu
  final DateTime issueDate;
  final DateTime dueDate;
  final double amount;
}
```

### Tahsilat Mutabakatı
```dart
// Günlük kasa kapatma
class DailyCashReconciliation {
  final DateTime date;
  final double openingCash;
  final List<Collection> collections;
  final double closingCash;

  double get totalCash => collections
    .where((c) => c.paymentType == PaymentType.cash)
    .fold(0.0, (sum, c) => sum + c.amount);
}
```

## Fatura Numaralandırma

### Türkiye standartlarına uygun numara formatı
```dart
// Format: SAHASATIS2024000001
String generateInvoiceNumber({
  required String prefix,  // 'SAHASATIS'
  required int year,
  required int sequence,
}) {
  return '$prefix$year${sequence.toString().padLeft(6, '0')}';
}
```

## Vergi Hesaplama

### Fatura Kalemi Hesaplama
```dart
class InvoiceLineCalculation {
  final double quantity;
  final double unitPrice;
  final double discountRate;  // 0.0 - 1.0
  final double taxRate;       // 0.20, 0.10, 0.01, 0.00

  double get subtotal => quantity * unitPrice;
  double get discountAmount => subtotal * discountRate;
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxableAmount * taxRate;
  double get total => taxableAmount + taxAmount;
}
```

## GİB e-Fatura Entegrasyonu

### e-Fatura XML Yapısı (UBL-TR)
```xml
<!-- Temel yapı - GİB UBL-TR standardı -->
<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2">
  <UBLVersionID>2.1</UBLVersionID>
  <CustomizationID>TR1.2</CustomizationID>
  <ProfileID>TICARIFATURA</ProfileID>
  <ID>SAHASATIS2024000001</ID>
  <CopyIndicator>false</CopyIndicator>
  <UUID>...</UUID>
  <IssueDate>2024-01-15</IssueDate>
  ...
</Invoice>
```

### Entegrasyon Sağlayıcıları
- **Dijital Fatura** - Logo, Netsis uyumlu
- **Edoksis** - Yaygın kullanılan
- **Sovos** - Kurumsal
- **Paraşüt** - KOBİ odaklı
- Direkt GİB Portal (küçük hacimler için)

## Raporlama Şablonları

### Plasiyer Gün Sonu Raporu
```
Tarih: {tarih}
Plasiyer: {plasiyer_adı}
Araç: {araç_plakası}

--- SATIŞLAR ---
Fatura Sayısı: {n}
Toplam Tutar: {tutar} TL
KDV: {kdv} TL
Genel Toplam: {toplam} TL

--- TAHSİLATLAR ---
Nakit: {nakit} TL
Çek: {cek} TL
Senet: {senet} TL
Kredi Kartı: {kart} TL
Toplam: {toplam_tahsilat} TL

--- ARAÇ STOĞU ---
Açılış: {acilis_adet} ürün / {acilis_tutar} TL
Satış: {satis_adet} ürün / {satis_tutar} TL
İade: {iade_adet} ürün / {iade_tutar} TL
Fire: {fire_adet} ürün / {fire_tutar} TL
Kapanış: {kapanis_adet} ürün / {kapanis_tutar} TL
```

## KVKK Uyumluluğu

```dart
// Müşteri verilerinde KVKK uyumu
class CustomerDataPolicy {
  // Kişisel veri saklama süresi (muhasebe: 10 yıl)
  static const int retentionYears = 10;

  // Konum verisi saklama (KVKK - en fazla 1 yıl)
  static const int locationRetentionDays = 365;

  // Veri silme talebi
  Future<void> handleDeletionRequest(String customerId) async {
    await anonymizePersonalData(customerId);
    // Muhasebe kayıtları anonim tutulur, silinmez
  }
}
```

## Sık Sorulan Sorular

**S: e-Fatura ile e-Arşiv farkı nedir?**
C: e-Fatura: GİB sistemine kayıtlı mükelleflere gönderilir, alıcı onaylar. e-Arşiv: Sisteme kayıtlı olmayanlara veya tüketicilere; PDF olarak paylaşılır.

**S: Fatura iptali nasıl yapılır?**
C: e-Fatura iptal edilemez, iade faturası kesilir. e-Arşiv belirli süre içinde iptal edilebilir.

**S: KDV hesaplamasında yuvarlama?**
C: Her kalem ayrı hesaplanır, toplam sonunda yuvarlanır. `double.toStringAsFixed(2)` ve `round()` kullan.
