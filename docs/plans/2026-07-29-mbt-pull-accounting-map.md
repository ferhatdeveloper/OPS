# MBT Alınacak Veriler — Muhasebe Eşleme Haritası

Tarih: 2026-07-29  
Rol: Muhasebe uzmanı  
Kapsam: Logo Tiger master verilerinin OPS yerel muhasebe yapılarına alınması

## Temel muhasebe ilkesi

Master kayıtlar firma ve dönem bağlamında, fişlerden önce alınmalıdır. Logo
alan adları sürüm ve endpoint çıktısına göre değişebileceği için aşağıdaki
kaynak alan adayları gerçek API fixture'ı ile doğrulanmadan kesin sözleşme
sayılmaz. Kod, para birimi, miktar ve bakiye işaretleri sessiz varsayımla
dönüştürülmemelidir.

## 1. STOK — `items` → `products`

**Durum: yarım**

| Logo alanı | Yerel alan | Muhasebe notu |
|---|---|---|
| `CODE` | `products.code` | Zorunlu, firma içinde tekil stok kodu |
| `NAME` | `products.name` | Boşsa kayıt reddedilmeli; kod ad yerine kalıcı kullanılmamalı |
| `VAT` | `products.vat_rate` | Yüzde olarak saklanır; 0/1/10/20 dışında istisna kodu ayrıca gerekebilir |
| `ONHAND` | `products.stock_quantity` | Toplam stoktur; ambar kırılımının yerine geçmez |
| `PRICE` / fiyat kartı | `products.price` | Fiyat türü, para birimi ve KDV dahil/hariç bilgisi doğrulanmalı |

Mevcut pull kodu bu beş temel alanı yazıyor. Ancak `price` tek fiyat ve
`stock_quantity` tek toplam olduğu için fiyat listesi, döviz ve ambar bazlı
stok muhasebesi tamamlanmış değildir.

**Risk:** Yanlış fiyat türü veya toplam `ONHAND` değerinin araç ambarı stoğu
gibi kullanılması, fiş tutarı ve eksi stok kontrolünü hatalı üretir.

**TODO:**
1. Gerçek `items` yanıtında `VAT`, `ONHAND`, fiyat türü ve para birimi
   alanlarını fixture ile doğrula.
2. `products.price` için satış fiyatı seçme kuralını; ambar stokları için
   `warehouse_stocks` kırılımını tanımla.
3. Kod/KDV/fiyat/miktar boş veya geçersiz olduğunda atlama ve hata raporu
   kabul kriterlerini ekle.

**İlgili dosyalar:**
- `lib/core/logo/logo_tiger_pull_sync.dart`
- `lib/core/database/migrations/SqlQuerys.dart`
- `lib/modules/field_sales/stock/viewmodel/warehouse_stock_query_store.dart`

## 2. CARİ — `Arps` → `customers`

**Durum: yarım**

| Logo alanı | Yerel alan | Muhasebe notu |
|---|---|---|
| `CODE` | `customers.code` | Zorunlu cari kod |
| `DEFINITION_` / `TITLE` | `customers.name` | Ticari ünvan |
| `TAXNR` | `customers.tax_no` | VKN/TCKN ayrımı ayrıca korunmalı |
| `BALANCE` | `customers.balance` | Borç/alacak işaret sözleşmesi zorunlu |
| risk limiti/açık risk | Yerel karşılık yok | Sipariş ve fatura risk kontrolü için şema eksik |

Adres, vergi dairesi, telefon ve e-posta mevcut pull tarafından alınmaktadır.
Fakat `customers` tablosunda kredi/risk limiti, açık sipariş riski, döviz
bakiyesi ve bakiye yönü için ayrı alan yoktur.

**Risk:** Bakiye işareti ve risk limiti tanımlanmadan satışa izin verilmesi,
müşteri limit aşımını gizleyebilir veya borç/alacak yönünü ters gösterebilir.

**TODO:**
1. `Arps` fixture'ında bakiye işaretini, cari türünü, VKN/TCKN ve Logo risk
   alanlarını doğrula.
2. `customers` için `risk_limit`, `open_risk`, `currency_code` ve hesaplama
   zaman damgası gereksinimini şema kararı olarak çıkar.
3. Sipariş/fatura öncesi kullanılabilir limit formülünü
   `limit - (bakiye + açık fiş riski)` olarak sözleşmeye bağla.

**İlgili dosyalar:**
- `lib/core/logo/logo_tiger_pull_sync.dart`
- `lib/core/database/migrations/SqlQuerys.dart`
- `lib/modules/field_sales/customers/view/customer_risk_screen.dart`

## 3. KASA — `safeDeposits` → `cash_cards`

**Durum: eksik**

Zorunlu hedef alanlar `code`, `name`, `currency` ve `balance` olmalıdır.
Mevcut `cash_cards` tablosu yalnız `code`, `name`, `name_key` ve durum
alanlarını taşır; para birimi ile bakiye kolonları yoktur.

| Logo alan adayı | Gerekli yerel alan | Kural |
|---|---|---|
| `CODE` | `code` | Zorunlu ve tekil |
| `NAME` / `DEFINITION_` | `name` | Zorunlu kasa adı |
| `CURR_CODE` / `CURRSEL` | `currency_code` | ISO koduna normalize edilmeli |
| `BALANCE` | `balance` | Kur ve borç/alacak yönü değiştirilmeden saklanmalı |

**Risk:** Kasa para birimi ve bakiyesi olmadan tahsilatın yanlış kasaya veya
yanlış dövizle kaydedilmesi günlük kasa mutabakatını bozar.

**TODO:**
1. Tiger sürümünde `safeDeposits` kaynağını ve kod/ad/döviz/bakiye alanlarını
   gerçek yanıtla doğrula.
2. `cash_cards` için `currency_code`, `balance`, `balance_as_of` ve gerekli
   soft-delete alanlarını içeren geriye uyumlu migration tasarla.
3. Kasa tahsilatında fiş dövizi ile kasa dövizi uyuşmazsa uygulanacak kur ve
   engelleme kuralını tanımla.

**İlgili dosyalar:**
- `lib/core/database/migrations/SqlQuerys.dart`
- `lib/modules/field_sales/collections/model/cash_card_seed.dart`
- `lib/modules/field_sales/collections/viewmodel/cash_card_store.dart`

## 4. BANKA — `bankAccounts` → `bank_cards`

**Durum: yarım**

`bank_cards` mevcuttur; ancak hesap para birimini tek satırda ifade etmek
yerine `balance_tl`, `balance_usd`, `balance_iqd` sabit kolonlarını kullanır.
`bankAccounts` için önerilen hedef sözleşme `code`, `name`, `bank_code`,
`branch_code`, `iban`, `currency_code`, `balance` ve `balance_as_of`
alanlarıdır.

**Risk:** Sabit para birimi kolonları farklı dövizleri kaybettirir ve aynı
banka hesabının bakiyesini birden çok bağımsız hesap gibi yorumlatabilir.

**TODO:**
1. `bankAccounts` endpoint ve alanlarını; gerekiyorsa banka master'ı ile join
   anahtarını fixture üzerinden doğrula.
2. Tek `currency_code + balance` satır modeli ile mevcut sabit bakiye
   kolonları arasında migration/uyumluluk kararı ver.
3. IBAN, şube, hesap numarası ve bakiye tarihi için doğrulama ile maskeleme
   kurallarını tanımla.

**İlgili dosyalar:**
- `lib/core/database/migrations/SqlQuerys.dart`
- `lib/modules/field_sales/collections/viewmodel/bank_card_store.dart`
- `lib/core/services/logo_payload_mapper.dart`

## 5. DÖVİZ — `currencyRates` → yerel kur yapısı

**Durum: eksik**

Kalıcı ve dönemsel bir yerel kur tablosu görünmemektedir. Gerekli yapı en az
`id`, `company_no`, `period_no`, `rate_date`, `currency_code`, `rate_type`,
`buying_rate`, `selling_rate`, `source`, `fetched_at` ve tekillik olarak
`company_no + period_no + rate_date + currency_code + rate_type` taşımalıdır.
Fiş, kullandığı kurun kimliğini veya tarih/tür/değer snapshot'ını saklamalıdır.

**Risk:** Yalnız güncel kurun tutulması geçmiş fişlerin yeniden
hesaplanmasına, dönem kapanışında kur farkı ve matrah tutarsızlığına yol açar.

**TODO:**
1. `currencyRates` alanlarını, kur türlerini ve Logo'nun firma/dönem/tarih
   filtre davranışını doğrula.
2. Tarihçeli `currency_rates` tablosu ile fiş üzerindeki kur snapshot'ı için
   migration sözleşmesi hazırla.
3. Hafta sonu/eksik gün, ters kur, sıfır kur ve dönem dışı tarih için seçim
   ve kayıt engelleme kurallarını belirle.

**İlgili dosyalar:**
- `lib/core/logo/logo_tiger_rest_client.dart`
- `lib/core/database/migrations/SqlQuerys.dart`
- `lib/modules/field_sales/currency/engine/hatwan_market_rates_service.dart`

## 6. GENEL — `unitSets`, plasiyer ve ambar

**Durum: yarım**

Yerelde `unit_sets`, `unit_set_lines`, `salesmen` ve `warehouses` yapıları
vardır. Ürün `unit_set_id` ile sete bağlanmalı; her fiş satırı seçilen birim,
miktar, ana birime dönüşüm katsayısı ve mümkünse katsayı snapshot'ı
taşımalıdır. Plasiyer ve ambar kodları firma/dönem bağlamından koparılmamalıdır.

**Risk:** Birim seti fişten sonra gelirse koli/adet dönüşümü yanlış yapılır;
yanlış ambar veya plasiyer de stok ve satış sorumluluğunu hatalı hesaba yazar.

**TODO:**
1. `unitSets` satırlarında ana birim, çarpan/bölen ve yuvarlama alanlarını;
   plasiyer/ambar kaynaklarının firma-dönem anahtarlarını doğrula.
2. Pull sırasını `unitSets → ambar/plasiyer → products → stok bakiyesi`
   şeklinde bağımlılık kontrollü uygula.
3. Fiş satırında `unit_name`, dönüşüm katsayısı ve ambar kodunun zorunluluk
   ve snapshot kurallarını tanımla.

**İlgili dosyalar:**
- `lib/core/database/migrations/SqlQuerys.dart`
- `lib/modules/field_sales/stock/model/unit_set_model.dart`
- `lib/modules/field_sales/stock/engine/unit_conversion_service.dart`
- `lib/core/logo/logo_tiger_pull_sync.dart`

## 7. VARYANT — barkod ve çoklu birim

**Durum: eksik**

Mevcut `products.barcode` tek barkod taşır; ayrı varyant/barkod master
sözleşmesi görünmemektedir. Gerekli ilişki en az
`product_id + variant_code + barcode + unit_code + conversion_factor`
alanlarını ve barkod tekillik kapsamını taşımalıdır. Renk/beden/lot gibi
varyant boyutları Logo kaynağında varsa ayrı kimlikle korunmalıdır.

**Risk:** Barkodun ürün, varyant ve birime kesin bağlanmaması yanlış miktar,
fiyat ve KDV ile fatura satırı üretir.

**TODO:**
1. Logo item/variant/barcode kaynaklarında çoklu barkod, varyant ve birim
   bağlarını gerçek veriyle envanterle.
2. `product_barcodes` ve gerekiyorsa `product_variants` için tekillik,
   yabancı anahtar ve pasifleştirme modelini tasarla.
3. Barkod okutulunca ürün + varyant + birim tekil çözülemiyorsa fiş satırı
   oluşturmayı engelleyen kabul kriteri ekle.

**İlgili dosyalar:**
- `lib/core/database/migrations/SqlQuerys.dart`
- `lib/core/logo/logo_tiger_pull_sync.dart`
- `lib/modules/field_sales/stock/model/unit_set_model.dart`

## 8. Gönderilecek fişler ile alınacak master bağımlılığı

**Durum: yarım**

FATURA, İRSALİYE, SİPARİŞ, TAHSİLAT ve stok fişleri gönderilmeden önce
referans verdikleri master kayıtlar yerelde bulunmalı ve Logo kimliği/kodu
doğrulanmalıdır. Zorunlu sıra:

1. Firma + dönem + döviz/kurlar
2. Birim setleri + ambar + plasiyer
3. Stok + varyant/barkod + fiyat + ambar bakiyesi
4. Cari + risk/bakiye
5. Kasa + banka
6. Fiş oluşturma ve gönderim kuyruğu

**Risk:** Master tamamlanmadan gönderilen fiş Logo'da referans hatası alır
veya daha tehlikeli olarak yanlış kodla muhasebeleşir.

**TODO:**
1. Her fiş türü için zorunlu master bağımlılık matrisi ve `master_version`
   önkoşulunu tanımla.
2. Eksik/pasif master, eski kur ve çözülemeyen birim varsa fişi kuyrukta
   bloke edip kullanıcıya somut hata döndür.
3. Toplu “Sunucudan Al” işleminde bağımlılık sırası, transaction sınırı,
   kısmi hata ve yeniden deneme davranışını test senaryosuna bağla.

**İlgili dosyalar:**
- `lib/core/logo/logo_tiger_pull_sync.dart`
- `lib/core/logo/logo_tiger_push_adapter.dart`
- `lib/service/job_queue_service.dart`
- `lib/service/job_queue_entity_map.dart`

## Kabul özeti

Muhasebe açısından STOK ve CARİ temel pull'u kullanılabilir başlangıç
seviyesindedir; ancak fiyat/ambar/risk detayları tamamlanmadan fiş güvenliği
sağlanmış sayılmaz. KASA, DÖVİZ ve VARYANT için yerel şema eksiktir. BANKA
şeması çoklu döviz açısından yeniden ele alınmalıdır. “Önce master, sonra
fiş” sırası teknik bir optimizasyon değil, muhasebe bütünlüğü önkoşuludur.
