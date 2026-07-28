# MBT RAPORLAR Envanteri

**Kaynak (truth):** MBT Mobil (Logo) v2.1.14.0 — cihaz A065 (`6544bc4b`)
**Tarih:** 2026-07-27
**Kapsam:** Yalnızca **RAPORLAR** sheet + alt kategoriler (OPS uygulama redesign yok).
**Not:** OPS başlangıç sayfaları görsel olarak biraz farklı olabilir; içerik/yapı için MBT referanstır.

## Sheet giriş

Ana menü → **RAPORLAR** → bottom sheet (2 sütun kart):

1. **CARİ**
2. **STOK**
3. **SİPARİŞ**
4. **FATURA**
5. **İRSALİYE**
6. **DİĞER**
7. **Rapor Yedekle/İndir**

- **Rapor Yedekle/İndir:** Rapor Yedekle/İndir dokunulunca sheet kapanıp ana menüye dönüyor; ayrı Parametreler ekranı görülmedi.

## Ortak Parametreler chrome

| Alan | Değer |
|---|---|
| Tarih kısayolları | Bugün · Bu Hafta · Bu Ay · Bu Yıl |
| Alt aksiyonlar | Görüntüle (PDF) · Paylaş · E-MAIL · Görüntüle (grid) |
| AppBar | Geri · Hesap makinesi · Ana sayfa |
| Tasarım | `DIZAYN DOSYA` → `*.repx` (çoğu raporda) |

## Özet sayılar

| Kategori | Rapor adedi |
|---|---:|
| CARİ | 14 |
| STOK | 9 |
| SİPARİŞ | 4 |
| FATURA | 3 |
| İRSALİYE | 4 |
| DİĞER | 6 |
| **Toplam** | **40** |

## PDF örnek sütunları (açılanlar)

| Rapor | PDF sütunları |
|---|---|
| CARİ HESAP EKSTRESİ | RefNo Tarih · Açıklama · Borç · Alacak · Bakiye |
| TAHSİLAT LİSTESİ | Kod · Unvan · İşlem Tarihi · Vade Tarihi · İşlem · Tutar · Kalan · FarkGun |
| STOK BAKİYE LİSTESİ | Stok Kodu · Stok Cinsi · Bakiye |

## CARİ

| # | Rapor | DİZAYN (.repx) | Tarih kısayol | Parametre alanları | Not |
|---:|---|---|:---:|---|---|
| 1 | CARİ HESAP EKSTRESİ | `CariExtre.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD · DÖVIZ DEĞERLEME · DÖVIZ KODU · RAPORLAMA DÖVIZI |  |
| 2 | TAHSİLAT LİSTESİ | `TahsilatListesi.repx` | Hayır | BITIŞ · KOD · AD · KOD 2 · AD 2 · ÖZELKOD 1 · ÖZELKOD 2 · ÖZELKOD 3 · ÖZELKOD 4 · ÖZELKOD 5 |  |
| 3 | DETAYLI CARİ HESAP EKSTRESİ | `StokluCariExtre.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD · RAPORLAMA DÖVIZI |  |
| 4 | YAKINIMDAKİ CARİ HESAPLAR (GPS) | `—` | Hayır | — | Özel ekran (Parametreler değil) — GPS (KONUM) |
| 5 | BORÇ / ALACAK DURUM RAPORU | `CariBakiyeListe.repx` | Hayır | KOD · AD · KOD 2 · AD 2 · BORÇLU HESAPLAR · ALACAKLI HESAPLAR · BAKIYESI '0' OLANLAR · ÖZELKOD 1 · ÖZELKOD 2 · ÖZELKOD 3 · ÖZELKOD 4 · ÖZELKOD 5 |  |
| 6 | CARİ HAREKET LİSTESİ | `CariHareketListe.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD · KOD 2 · AD 2 · ÖZELKOD 1 · ÖZELKOD 2 · ÖZELKOD 3 · ÖZELKOD 4 · ÖZELKOD 5 |  |
| 7 | SATIŞ YAPILMAYAN CARİ HESAPLAR | `HareketGormeyenCariler.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD · KOD 2 · AD 2 · ÖZELKOD 1 · ÖZELKOD 2 · ÖZELKOD 3 · ÖZELKOD 4 · ÖZELKOD 5 |  |
| 8 | EN ÇOK SATIŞ YAPILAN CARİLER | `EncokSatisYapilanCari.repx` | Evet | BAŞLANGIÇ · BITIŞ · ÖZELKOD 1 · ÖZELKOD 2 · ÖZELKOD 3 · ÖZELKOD 4 · ÖZELKOD 5 |  |
| 9 | EN ÇOK ALIM YAPILAN CARİLER | `EncokAlimYapilanCari.repx` | Evet | BAŞLANGIÇ · BITIŞ · ÖZELKOD 1 · ÖZELKOD 2 · ÖZELKOD 3 · ÖZELKOD 4 · ÖZELKOD 5 |  |
| 10 | EN ÇOK TERCİH EDİLEN ÜRÜNLER ( SATIŞLAR ) | `CariStokTercih.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD |  |
| 11 | EN ÇOK TERCİH EDİLEN ÜRÜNLER ( ALIŞLAR ) | `CariStokTercih.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD |  |
| 12 | GPS (KONUM) RAPORU | `—` | Hayır | ÖZELKOD 1 · ÖZELKOD 2 · ÖZELKOD 3 · ÖZELKOD 4 · ÖZELKOD 5 | Parametreler var; DIZAYN DOSYA/.repx yok (ÖZELKOD 1–5) |
| 13 | MÜŞTERİ ÇEK LİSTESİ | `MusteriCekSenetListe.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD |  |
| 14 | MÜŞTERİ SENET LİSTESİ | `MusteriCekSenetListe.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD |  |

## STOK

| # | Rapor | DİZAYN (.repx) | Tarih kısayol | Parametre alanları | Not |
|---:|---|---|:---:|---|---|
| 1 | STOK BAKİYE LİSTESİ | `StokBakiye.repx` | Hayır | KOD · AD · KOD 2 · AD 2 · CARIKODU · '0'DAN BÜYÜK OLANLAR · '0'DAN KÜÇÜK OLANLAR · BAKIYESI '0' OLANLAR · ÖZELKOD 1 · ÖZELKOD 2 · ÖZELKOD 3 · ÖZELKOD 4 · ÖZELKOD 5 |  |
| 2 | STOK ENVANTER RAPORU | `StokEnvanter.repx` | Hayır | İŞYERI · FABRIKA · AMBAR · KOD · AD · KOD 2 · AD 2 · CARIKODU · ÖZELKOD 1 · ÖZELKOD 2 · ÖZELKOD 3 · ÖZELKOD 4 · ÖZELKOD 5 |  |
| 3 | STOK HAREKET LİSTESİ | `StokHareketListe.repx` | Evet | BAŞLANGIÇ · BITIŞ · SEÇIM · İŞYERI · FABRIKA · AMBAR · KOD · AD · KOD 2 · AD 2 · CARIKODU · ÖZELKOD 1 · ÖZELKOD 2 · ÖZELKOD 3 · ÖZELKOD 4 · ÖZELKOD 5 |  |
| 4 | SERİ / LOT | `—` | Hayır | İŞYERI · FABRIKA · AMBAR · KOD · AD · KOD 2 · AD 2 · CARIKODU · ÖZELKOD 1 · ÖZELKOD 2 · ÖZELKOD 3 · ÖZELKOD 4 · ÖZELKOD 5 | Parametreler var; DIZAYN DOSYA satırı/UI dump’ta .repx yok |
| 5 | ÜRÜN HANGİ DEPODA | `UrunHangiDepolarda.repx` | Hayır | KOD · AD · KOD 2 · AD 2 · CARIKODU · ÖZELKOD 1 · ÖZELKOD 2 · ÖZELKOD 3 · ÖZELKOD 4 · ÖZELKOD 5 |  |
| 6 | DEPODA HANGİ ÜRÜNLER MEVCUT | `DepodakiUrunler.repx` | Hayır | İŞYERI · FABRIKA · AMBAR · KOD · AD · KOD 2 · AD 2 · CARIKODU · ÖZELKOD 1 · ÖZELKOD 2 · ÖZELKOD 3 · ÖZELKOD 4 · ÖZELKOD 5 |  |
| 7 | SATIŞI YAPILMAYAN ÜRÜNLER | `HareketGormeyenStoklar.repx` | Evet | BAŞLANGIÇ · BITIŞ · CARIKODU · AD · ÖZELKOD 1 · ÖZELKOD 2 · ÖZELKOD 3 · ÖZELKOD 4 · ÖZELKOD 5 |  |
| 8 | EN ÇOK SATILAN ÜRÜNLER | `EncokSatilanStok.repx` | Evet | BAŞLANGIÇ · BITIŞ · CARIKODU · AD · ÖZELKOD 1 · ÖZELKOD 2 · ÖZELKOD 3 · ÖZELKOD 4 · ÖZELKOD 5 |  |
| 9 | EN ÇOK ALINAN ÜRÜNLER | `EncokAlinanStok.repx` | Evet | BAŞLANGIÇ · BITIŞ · CARIKODU · AD · ÖZELKOD 1 · ÖZELKOD 2 · ÖZELKOD 3 · ÖZELKOD 4 · ÖZELKOD 5 |  |

## SİPARİŞ

| # | Rapor | DİZAYN (.repx) | Tarih kısayol | Parametre alanları | Not |
|---:|---|---|:---:|---|---|
| 1 | SATIŞ SİPARİŞLERİ | `SiparisListesi.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD · KOD 2 · AD 2 · İŞYERI · FABRIKA · AMBAR |  |
| 2 | ALIŞ SİPARİŞLERİ | `SiparisListesi.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD · KOD 2 · AD 2 · İŞYERI · FABRIKA · AMBAR |  |
| 3 | BEKLEYEN SATIŞ SİPARİŞLERİ | `BekleyenSatisSiparisler.repx` | Evet | BAŞLANGIÇ · BITIŞ · STK.KOD · STK.AD · KOD · AD · KOD 2 · AD 2 · İŞYERI · FABRIKA · AMBAR |  |
| 4 | BEKLEYEN ALIŞ SİPARİŞLERİ | `BekleyenAlisSiparisler.repx` | Evet | BAŞLANGIÇ · BITIŞ · STK.KOD · STK.AD · KOD · AD · KOD 2 · AD 2 · İŞYERI · FABRIKA · AMBAR |  |

## FATURA

| # | Rapor | DİZAYN (.repx) | Tarih kısayol | Parametre alanları | Not |
|---:|---|---|:---:|---|---|
| 1 | SATIŞ FATURALARI | `SatisFaturaListesi.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD · KOD 2 · AD 2 · İŞYERI · FABRIKA · AMBAR |  |
| 2 | ALIŞ FATURALARI | `AlisFaturaListesi.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD · KOD 2 · AD 2 · İŞYERI · FABRIKA · AMBAR |  |
| 3 | FATURA KARLILIK DURUMU | `FisMaliyet.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD |  |

## İRSALİYE

| # | Rapor | DİZAYN (.repx) | Tarih kısayol | Parametre alanları | Not |
|---:|---|---|:---:|---|---|
| 1 | SATIŞ İRSALİYELERİ | `IrsaliyeListesi.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD · KOD 2 · AD 2 · İŞYERI · FABRIKA · AMBAR |  |
| 2 | ALIŞ İRSALİYELERİ | `IrsaliyeListesi.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD · KOD 2 · AD 2 · İŞYERI · FABRIKA · AMBAR |  |
| 3 | FATURA KESİLMEYEN İRSALİYELER (SATIŞLAR) | `IrsaliyeListesi.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD · KOD 2 · AD 2 · İŞYERI · FABRIKA · AMBAR |  |
| 4 | FATURA KESİLMEYEN İRSALİYELER (ALIŞLAR) | `IrsaliyeListesi.repx` | Evet | BAŞLANGIÇ · BITIŞ · KOD · AD · KOD 2 · AD 2 · İŞYERI · FABRIKA · AMBAR |  |

## DİĞER

| # | Rapor | DİZAYN (.repx) | Tarih kısayol | Parametre alanları | Not |
|---:|---|---|:---:|---|---|
| 1 | PLASİYER GPS RAPOR | `—` | Hayır | BAŞLANGIÇ · PLASIYER KODU · AD | Alt aksiyon yalnızca Görüntüle; .repx yok |
| 2 | PLASİYER ROTA RAPORU | `SaticiRotaRapor.repx` | Evet | BAŞLANGIÇ · BITIŞ · PLASIYER KODU · AD |  |
| 3 | PLASİYER GÜNLÜK İŞLEMLER | `SaticiGunlukRapor.repx` | Evet | BAŞLANGIÇ · BITIŞ · PLASIYER KODU · AD |  |
| 4 | ZİYARET LİSTESİ | `ZiyaretListesi.repx` | Evet | BAŞLANGIÇ · BITIŞ |  |
| 5 | ZİYARET LİSTESİ (ÖZEL) | `GelismisZiyaretListesi.repx` | Evet | BAŞLANGIÇ · BITIŞ |  |
| 6 | KASA HAREKET RAPORU | `KasaHareketRapor.repx` | Evet | BAŞLANGIÇ · BITIŞ · KASA KODU · BAKIYE |  |

## Alt aksiyon matrisi

Standart Parametreler ekranı (çoğu rapor):

1. **Görüntüle** (kırmızı PDF) → `Görüntüle (PDF)` viewer
2. **Paylaş**
3. **E-MAIL**
4. **Görüntüle** (sarı grafik) → uygulama içi görünüm

İstisnalar:

- **PLASİYER GPS RAPOR** — yalnızca **Görüntüle**
- **YAKINIMDAKİ CARİ HESAPLAR (GPS)** — özel `GPS (KONUM)` ekranı (Parametreler değil)

## .repx dosya listesi (benzersiz)

- `AlisFaturaListesi.repx`
- `BekleyenAlisSiparisler.repx`
- `BekleyenSatisSiparisler.repx`
- `CariBakiyeListe.repx`
- `CariExtre.repx`
- `CariHareketListe.repx`
- `CariStokTercih.repx`
- `DepodakiUrunler.repx`
- `EncokAlimYapilanCari.repx`
- `EncokAlinanStok.repx`
- `EncokSatilanStok.repx`
- `EncokSatisYapilanCari.repx`
- `FisMaliyet.repx`
- `GelismisZiyaretListesi.repx`
- `HareketGormeyenCariler.repx`
- `HareketGormeyenStoklar.repx`
- `IrsaliyeListesi.repx`
- `KasaHareketRapor.repx`
- `MusteriCekSenetListe.repx`
- `SaticiGunlukRapor.repx`
- `SaticiRotaRapor.repx`
- `SatisFaturaListesi.repx`
- `SiparisListesi.repx`
- `StokBakiye.repx`
- `StokEnvanter.repx`
- `StokHareketListe.repx`
- `StokluCariExtre.repx`
- `TahsilatListesi.repx`
- `UrunHangiDepolarda.repx`
- `ZiyaretListesi.repx`

**Benzersiz .repx sayısı:** 30

## Kaynaklar

- Canlı adb/uiautomator dump (A065)
- Kullanıcı ekran görüntüleri (`~/.cursor/projects/.../assets/image-*`)
- `docs/plans/2026-07-25-mbt-app-structure-schema.md` (sheet iskeleti)
