# Tenant Registry Logo Yapılandırması Tasarımı

**Tarih:** 2026-07-29  
**Durum:** Onaylandı  
**Kapsam:** Kiracı koduyla merkez `tenant_registry` kaydından Logo REST
başlangıç yapılandırmasının alınması  
**Kapsam dışı:** Production implementasyonu, merkez veritabanı migration'ı,
secret dağıtımı ve UI redesign

---

## 1. Amaç

Kullanıcı kiracı koduyla giriş yaptığında merkez `tenant_registry` satırındaki
Logo bağlantı başlangıç değerlerini alıp cihazda offline kullanılabilir biçimde
saklamak. Bu işlem mevcut PostgREST tenant çözümlemesini, elle girilmiş Logo
ayarlarını ve kullanıcının aktif firma/dönem seçimini bozmamalıdır.

Merkezde kesinleşen kolonlar:

- `logo_rest_api_url`
- `logo_firm_nr`
- `logo_period_nr`
- `logo_db`
- `updated_at`

Mevcut tenant çözümlemesinin ihtiyaç duyduğu `code`, `rest_base_url`,
`display_name` ve `is_active` alanları aynı sorguda alınır.

## 2. Mevcut Durum

`PostgrestTenantService._tryResolveFromMerkezRegistry`, şu endpoint'i anonim
PostgREST isteğiyle sorgular:

```text
GET {saasOrigin}/merkez/tenant_registry?code=eq.{tenantCode}
```

İstek yalnızca `Accept` ve `Accept-Profile: public` header'larını gönderir.
Yanıt regex ile ayrıştırılır. `httpClient` yoksa veya aynı kiracı için
`remoteRestUrl` cache'te varsa merkez probe atlanır. Bu nedenle mevcut metoda
yalnızca yeni regex'ler eklemek Logo alanlarının güvenilir biçimde alınmasını
sağlamaz.

Logo yapılandırması bugün `LogoTigerSettingsStore` üzerinden okunur.
`LogoServerUrlBridge` URL kaynağı olarak sırasıyla Tiger store, Logo REST
ayarları ve genel `api_config` kaydını kullanır. Firma ve dönem için ayrıca
`ActiveCompanyStore` tarafından yönetilen kullanıcı seçimi vardır.

## 3. Karar

Merkez registry erişimi tipli bir servis olarak ayrılacak ve Logo başlangıç
yapılandırması ayrı bir seed katmanıyla uygulanacaktır.

### 3.1 Tipli registry modeli ve servisi

`TenantRegistryRow`, merkez satırını `jsonDecode` ile ayrıştırır. Model şu
alanları taşır:

- `code`
- `restBaseUrl`
- `displayName`
- `isActive`
- `logoRestApiUrl`
- `logoFirmNr`
- `logoPeriodNr`
- `logoDb`
- `updatedAt`

`MerkezTenantRegistryService`, normalize edilmiş kiracı koduyla tek satır
ister. Sorgunun `select` değeri tam olarak şöyledir:

```text
code,rest_base_url,display_name,is_active,logo_rest_api_url,
logo_firm_nr,logo_period_nr,logo_db,updated_at
```

Servis HTTP transport, timeout, header üretimi ve parse sorumluluğunu taşır.
Boş dizi, aktif olmayan satır, 2xx dışı yanıt, timeout ve geçersiz JSON
çözümlenemeyen registry sonucu olarak ele alınır; mevcut SaaS fallback
davranışını bozmaz.

### 3.2 Cache modeli

Registry'den gelen Logo değerleri tenant'a bağlı ayrı bir cache kaydında
saklanır. Cache en az şu bilgileri taşır:

- normalize kiracı kodu
- Logo REST API URL
- Logo firma numarası
- Logo dönem numarası
- Logo veritabanı
- registry `updated_at`
- cihazın son başarılı fetch zamanı

Cache'in amacı ilk başarılı girişten sonra offline çalışma ve aynı kiracı için
gereksiz ağ isteklerini sınırlamaktır. Farklı tenant'ın cache'i aktif tenant'a
uygulanamaz.

Mevcut `remoteRestUrl` kısa devresi Logo bootstrap'ı tamamen atlamaz.
Registry Logo cache'i yoksa merkez sorgusu yapılır; cache varsa belirlenen
yenileme süresi içinde offline değer kullanılır. Süre dolduğunda yenileme
best-effort çalışır ve hata halinde son geçerli cache korunur.

### 3.3 Logo seed politikası

`LogoTenantConfigSeeder`, registry cache'ini `LogoTigerSettingsStore` ile
birleştirir:

1. `logo_rest_api_url` boşsa seed yapılmaz.
2. URL `LogoTigerUrls` ile normalize edilir; geçersiz URL uygulanmaz.
3. `logo_firm_nr` ve `logo_period_nr` pozitif integer değilse ilgili değer
   uygulanmaz.
4. `logo_db` trim edilir; boş değer mevcut veriyi silmez.
5. `apiKey`, `username`, `password`, `clientId`, `clientSecret` ve access
   token alanlarına dokunulmaz.
6. Kullanıcının açık manuel override'ı varsa registry seed mevcut Logo
   ayarlarını ezmez.
7. Manuel override yoksa daha yeni registry `updated_at` değeri seed'i
   yenileyebilir.

Elle Logo ayarı kaydedildiğinde `logo_tiger_manual_override` işareti set
edilir. Registry tarafından yapılan kayıt bu işareti set etmez. Böylece veri
kaynağı açık ve test edilebilir kalır.

### 3.4 Firma/dönem önceliği

Registry'deki `logo_firm_nr` ve `logo_period_nr` yalnızca bootstrap
varsayılanıdır. Kullanıcının `ActiveCompanyStore` ile seçtiği firma/dönem
etkin çalışma bağlamıdır ve registry tarafından sessizce değiştirilemez.

Logo push/pull başlatılırken etkin firma/dönem ile bootstrap değerleri
arasındaki ilişkinin görünür ve doğrulanmış olması gerekir. Bekleyen Logo job
varken bağlam değişimi ayrı iş kuralı olarak ele alınır; bu tasarım otomatik
job migration'ı yapmaz.

## 4. Veri Akışı

1. Login ekranı normalize edilmiş kiracı kodunu
   `PostgrestTenantService.applyTenantCode` metoduna verir.
2. Tenant servisi `MerkezTenantRegistryService.fetch` ile merkez satırını
   ister.
3. Aktif registry satırındaki `rest_base_url`, mevcut tenant context çözümüne
   uygulanır.
4. Logo alanları tenant'a bağlı cache'e atomik olarak kaydedilir.
5. `LogoTenantConfigSeeder`, manuel override ve `updated_at` kurallarını
   değerlendirir.
6. Uygulanabilir değerler mevcut secret alanlar korunarak Tiger store'a
   yazılır.
7. `LogoServerUrlBridge`, manuel Tiger ayarından sonra tenant registry
   cache'ini; ardından mevcut Logo REST ve `api_config` fallback'lerini
   değerlendirir.
8. Ağ yoksa son geçerli tenant ve Logo cache'i kullanılır.

## 5. Kaynak Önceliği

Logo endpoint çözümleme sırası:

1. Kullanıcının manuel Tiger ayarı
2. Aktif tenant'a ait registry cache'i
3. Mevcut Logo REST preferences
4. Genel SQLite `api_config`
5. Yapılandırılmamış durum

Secret alanlar bu öncelik zincirinden bağımsızdır; registry hiçbir secret
sağlamaz ve mevcut secret'ları temizlemez.

## 6. Hata ve Fallback Davranışı

| Durum | Davranış |
|---|---|
| Merkez timeout / ağ yok | Son tenant Logo cache'i; yoksa mevcut Logo ayarları |
| HTTP 4xx / 5xx | Mevcut SaaS slug ve Logo fallback zinciri |
| Boş registry dizisi | Registry uygulanmaz |
| `is_active=false` | Tenant ve Logo registry değerleri uygulanmaz |
| Geçersiz JSON / tip | Son geçerli cache korunur; kısmi bozuk satır yazılmaz |
| Geçersiz Logo URL | Logo seed atlanır |
| Eksik Logo firma/dönem | Geçerli alanlar uygulanır, eksik alan mevcut değeri silmez |
| Eski `updated_at` | Daha yeni yerel seed ezilmez |
| Manuel override | Registry mevcut manuel ayarı ezmez |
| Tenant değişimi | Önceki tenant'ın Logo cache'i kullanılmaz |

Registry erişimi best-effort'tur; başarısızlık offline login'i veya mevcut
tenant PostgREST fallback'ini bloke etmez.

## 7. Güvenlik

- Registry'den `api_key`, parola, OAuth client secret veya access token
  okunmaz.
- Secret alanlar loglanmaz ve mevcut `RememberMeCrypto` saklama davranışı
  korunur.
- Tanılama çıktısı URL query secret'larını göstermemelidir.
- `Accept-Profile` sabit tutulur; kullanıcı girdisi header veya şema adı
  olamaz.
- Kiracı kodu query parametresi URI encoding ile gönderilir.
- Merkez endpoint şu an anonimdir. Production'da RLS/sınırlı view veya merkez
  `apikey`/JWT ile yalnızca gerekli kolonların okunması önerilir.
- `logo_db`, firma ve dönem değerleri yetkilendirme kararı değildir; sunucu
  her Logo işleminde tenant/firma yetkisini ayrıca doğrulamalıdır.

## 8. Gözlemlenebilirlik

Loglar secret veya tam hassas URL içermeden şu sonuçları ayırabilmelidir:

- registry fetch başarılı
- cache kullanıldı
- registry erişilemedi, fallback kullanıldı
- manuel override korundu
- registry satırı geçersiz veya aktif değil

UI redesign yapılmaz. Gerekirse mevcut dens Logo ayar ekranında yalnızca
lokalize, kompakt bir kaynak bilgisi gösterilir.

## 9. Test Stratejisi

TDD ile aşağıdaki katmanlar ayrı test edilir:

1. `TenantRegistryRow`: tam, eksik, null ve yanlış tipli JSON.
2. `MerkezTenantRegistryService`: URI/select/header, 200, boş dizi,
   `is_active=false`, 4xx/5xx, timeout ve malformed JSON.
3. Tenant Logo cache'i: tenant izolasyonu, round-trip, temizleme ve eski cache.
4. `LogoTenantConfigSeeder`: ilk seed, daha yeni/eski `updated_at`, manuel
   override, kısmi alanlar, geçersiz URL ve secret koruma.
5. `PostgrestTenantService`: cache kısa devresinde Logo bootstrap'ın
   kaybolmaması ve mevcut SaaS fallback regresyonları.
6. `LogoServerUrlBridge`: kaynak önceliği ve tenant değişimi.
7. Login/ayar widget testleri: yalnızca kaynak bilgisi eklenirse l10n ve dens
   layout regresyonu.

## 10. Kabul Kriterleri

- Doğrulanmış beş Logo kolonu kiracı koduyla tek merkez isteğinde okunur.
- Aynı istek mevcut tenant REST URL çözümünü de destekler.
- İlk başarılı fetch sonrası Logo başlangıç değerleri offline kullanılabilir.
- Manuel Logo ayarı registry tarafından ezilmez.
- Registry secret taşımaz ve mevcut secret'ları değiştirmez.
- Kullanıcının aktif firma/dönem seçimi registry varsayılanından önceliklidir.
- Registry hatası login'i veya mevcut Logo fallback'lerini bozmaz.
- Eski tenant'ın cache'i yeni tenant'a sızmaz.
- Tüm yeni davranışlar birim/widget testleriyle TDD olarak kapsanır.
- UI görsel dili değiştirilmez.

## 11. Uygulama Dışı Kararlar

Bu tasarım:

- merkez `tenant_registry` DDL migration'ı oluşturmaz;
- anonim endpoint güvenliğini tek başına çözmez;
- Logo kimlik bilgilerini merkezden dağıtmaz;
- bekleyen job'ları başka firma/döneme taşımaz;
- yeni ayar ekranı veya görsel redesign yapmaz.

