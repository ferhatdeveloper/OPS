# MBT Alınacak Veriler — Çoklu Ajan Planı

Tarih: 2026-07-29  
Kaynak: MBT Veri Güncelleme ekranı parity

## Hedef

Güncelleme ekranında MBT ile aynı 9 alınacak satır:

1. STOK BİLGİLERİ
2. CARİ BİLGİLERİ
3. KASA BİLGİLERİ
4. BANKA BİLGİLERİ
5. DÖVİZ BİLGİLERİ
6. GENEL BİLGİLER
7. VARYANT BİLGİLERİ
8. ROTA BİLGİLERİ
9. DUYURULAR

Her satır ayrı indirilebilir + toplu al. Desteklenmeyenler “yakında / merkez kaynaklı” olarak görünür, uydurma endpoint yok.

## Dosya sahipliği (çakışma yok)

| Ajan | Sahip dosyalar |
|------|----------------|
| Yazılım-mobil | `lib/core/logo/logo_tiger_rest_client.dart`, `logo_tiger_pull_sync.dart`, ilgili unit testler |
| Saha+UI | `logo_pull_source.dart`, `logo_pull_source_runner.dart`, `data_transfer_screen.dart`, sync widget testleri |
| Dil | `assets/translations/*.json`, `test/core/l10n/logo_pull_l10n_parity_test.dart` |
| Muhasebe | Bu plan + alan eşleme notları (yalnız `docs/plans/`) |
| Tester | Entegrasyon sonrası regresyon; yeni test dosyaları `test/modules/field_sales/sync/` |

## Kaynak eşlemesi

| Satır | Pull | Not |
|-------|------|-----|
| STOK | Tiger `items` → products | ONHAND stok dahil |
| CARİ | Tiger `Arps` → customers | BALANCE dahil |
| KASA | Tiger `safeDeposits` → cash_cards | Yoksa yakında |
| BANKA | Tiger `banks`/`bankAccounts` → bank_cards | Yoksa yakında |
| DÖVİZ | Tiger `currencies`/`currencyRates` | Yerel tablo yoksa yakında |
| GENEL | locationCodes + salesmen (+ unitSets mümkünse) | Composite pull |
| VARYANT | Şema yok | Yakında |
| ROTA | Merkez/PostgREST | Yakında (Logo değil) |
| DUYURULAR | Merkez/PostgREST campaigns | Yakında (Logo değil) |

## Bağımlılık

1. Dil + Yazılım + Muhasebe (paralel)
2. Saha+UI (yazılım API imzalarına göre bağlar)
3. Tester
