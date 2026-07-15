# EXFIN OPS Localization (Dil Çevirisi) Sistemi Rehberi

Bu döküman, EXFIN OPS projesinde kullanılan dil çeviri sisteminin mimarisini, dosya yapısını ve kullanımını detaylandırmaktadır.

## 1. Mimariye Genel Bakış

Proje, Flutter'ın standart `LocalizationsDelegate` yapısını kullanan, ancak veri kaynağı olarak JSON dosyalarını ve durum yönetimi için **Riverpod**'u tercih eden özel bir sisteme sahiptir.

-   **Alt Yapı:** Riverpod (`flutter_riverpod`)
-   **Kapsam:** Statik metinler, dinamik argümanlı metinler, RTL (Sağdan Sola) desteği.
-   **Dosya Formatı:** JSON

## 2. Dosya Yapısı ve Konumlar

Tüm dil dosyaları `assets` dizini altında merkezi bir konumda tutulur:

```text
/assets/translations/
├── tr.json      (Varsayılan / Kaynak Dil)
├── en.json      (İngilizce)
├── ar.json      (Arapça)
├── ku.json      (Kürtçe - Sorani)
├── fa.json      (Farsça)
├── de.json      (Almanca)
├── ... (Diğer diller)
```

### Kod Dosyaları
-   [app_localization.dart](file:///Users/ferhatnas/App/EXFINOPS/lib/core/localization/app_localization.dart): Ana mantık, JSON yükleme ve çeviri fonksiyonu.
-   [app_localization_delegate.dart](file:///Users/ferhatnas/App/EXFINOPS/lib/core/localization/app_localization_delegate.dart): Flutter motoru ile entegrasyonu sağlayan delege sınıfı.

## 3. Sistem Nasıl Çalışır?

### Başlatma (Initialization)
Uygulama başlarken `main.dart` içerisinde `LanguageService.initializeLanguageTables()` çağrılarak veritabanı seviyesindeki dil ayarları kontrol edilir. Ardından, kullanıcının seçtiği dil `localeProvider` üzerinden sisteme bildirilir.

### Dil Yükleme
`AppLocalization` sınıfı seçilen dile göre ilgili JSON dosyasını (`assets/translations/xx.json`) `rootBundle` kullanarak asenkron olarak yükler.

### Fallback (Yedek Dil) Mekanizması
Sistem son derece dayanıklı (resilient) tasarlanmıştır:
1.  Her zaman `tr.json` (Türkçe) dosyası ana bellek üzerinde tutulur.
2.  Eğer seçilen dilde bir anahtar (key) bulunamazsa, otomatik olarak Türkçe sürümü gösterilir.
3.  Dosya yükleme hatası durumunda uygulama kırılmaz, varsayılan dile döner.

## 4. Kullanım Rehberi

### Temel Çeviri
Widget içerisinde çeviri yapmak için `AppLocalization` sınıfının `translate` metodunu kullanabilirsiniz:

```dart
Text(
  AppLocalization.of(context).translate('auth.login_title'),
)
```

### Argümanlı Çeviri
Parametrik metinler için JSON dosyasında `{param}` formatı kullanılır.

**JSON:**
```json
"welcome_user": "Hoş geldin, {name}!"
```

**Kod:**
```dart
AppLocalization.of(context).translate(
  'welcome_user', 
  args: {'name': 'Ferhat'}
)
```

## 5. RTL (Sağdan Sola) Desteği

Arapça (`ar`), Farsça (`fa`) ve Kürtçe (`ku`/`ckb`) gibi diller için sistem otomatik olarak RTL moduna geçer.

-   **Kontrol:** `AppLocalization.isRtl(languageCode)` fonksiyonu ile yapılır.
-   **Uygulama:** `main.dart` içerisinde `MaterialApp`'in `builder` metodunda `Directionality` widget'ı ile tüm uygulama ağacı sarılır. Bu sayede hizalamalar ve ikon yönleri otomatik olarak düzelir.

## 6. Yeni Dil Ekleme

1.  `assets/translations/` altına yeni bir `.json` dosyası ekleyin (Örn: `it.json`).
2.  [app_localization.dart](file:///Users/ferhatnas/App/EXFINOPS/lib/core/localization/app_localization.dart) içerisindeki `supportedLanguageFiles` map'ine yeni kodu ekleyin.
3.  `AppLocalization.supportedLocales()` listesine yeni `Locale` objesini ekleyin.
4.  `pubspec.yaml` içerisinde assets kısmına yeni dosyanın dahil edildiğinden emin olun (genellikle klasör dahil edildiği için otomatiktir).

## 7. Önemli Notlar

-   **İç içe JSON yapısı:** Anahtarlar `.` (nokta) operatörü ile erişilebilir (Örn: `settings.account.name`).
-   **Riverpod Entegrasyonu:** `localeProvider` watch edilerek uygulama genelinde anlık dil değişimi tetiklenebilir.
