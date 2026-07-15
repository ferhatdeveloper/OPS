<!-- Dosya: 2026-07-15-saha-satis-roadmap-design.md -->
<!-- Açıklama: İdeal SFA modeli + EXFINOPS gap + fazlı roadmap (30 ajan audit sentezi) -->
<!-- Oluşturulma: 2026-07-15 | Geliştirici: Ferhat NAS | Son Güncelleme: 2026-07-15 -->

# Saha Satış Roadmap Tasarımı

> **Kaynak:** 30 paralel domain audit (Test + Muhasebe + Saha Satış zorunlu)  
> **Mimari kısıt:** Mevcut `lib/modules/field_sales/` yapısı korunur; sıfırdan rewrite yok.

## 1. İdeal plasiyer günü

```
Mesai başlat → Sync indir → Araç yükleme/mutabakat → Rota
  → Check-in (GPS/NFC) → Cari risk → Satış/İade → Tahsilat + makbuz
  → Check-out + POD → (tekrar rota) → EOD mutabakat → Logo gönder → Mesai bitir
```

Offline-first: yerel SQLite → `JobQueueService` → Logo REST; bağlantıda otomatik retry.

## 2. Genel verdict

| Katman | Durum | Not |
|--------|--------|-----|
| UI ekranları | **Hazır / yarım** | Çoğu menüde var; çoğu mock veya kopuk |
| Logo REST + queue | **Yarım** | Yeni iskelet; tip map, idempotency, test eksik |
| Muhasebe bütünlüğü | **Riskli** | KDV, risk limiti, iade stok yönü, fiş TYPE |
| Gün akışı gate | **Eksik** | Mesai/ziyaret zorunluluğu yok |
| Test | **Eksik** | Kritik sync zinciri testsiz |
| Production | **Blokeli** | Android INTERNET release, imza, iOS privacy |

## 3. Domain panosu (30 ajan)

| # | Domain | Durum | En kritik P0 |
|---|--------|--------|--------------|
| 01 | Test | eksik | Mapper + JobQueue + provider testleri |
| 02 | Muhasebe | yarım | KDV, cari risk, Logo TYPE 8/3 |
| 03 | Saha satış | yarım | Mesai/EOD gate; visit_id satışa |
| 04 | Logo REST | yarım | Tip map + REF no + retry |
| 05 | Sipariş | yarım | Fiyat 0₺; fiyat sync |
| 06 | Fatura | yarım | Liste mock; stok/iade yönü; tip map |
| 07 | Tahsilat | yarım | Makbuz UI; çek→Logo; senet yok |
| 08 | Müşteri | yarım | `credit_limit` yok; risk motoru yok |
| 09 | Araç | stub | EOD sahte; fiziksel sayım 0 |
| 10 | Rota/ziyaret | yarım | İmzasız checkout; sync mapper |
| 11 | Kampanya | iskelet | Pull yok; şema drift; belgeye yazılmıyor |
| 12 | Stok/birim | düşük | Convert unused; transfer stok düşmez |
| 13 | Merchandising | kırılgan | Competitor DDL migrate edilmiyor |
| 14 | Maps/GPS | yarım | Çift servis; iOS Info.plist; background persist |
| 15 | Sync UI | yarım | Manuel; bağlantı→queue tetik yok |
| 16 | Gün sonu | stub | work_logs UI bağlı değil |
| 17 | Yazıcı | yarım | KDV mock; printCollection ölü |
| 18 | NFC/Geofence | kısmi | NFC≠check-in; koordinat bypass |
| 19 | Gamification | demo | Tablo migrate yok; userId uyumsuz |
| 20 | Rapor/KPI | mock | Gerçek veri yok |
| 21 | Auth | riskli | Cihaz gate bypass; plaintext şifre |
| 22 | DB şema | drift | version=1; expenses DDL bozuk; ONAY adı yok |
| 23 | Offline | riskli | Idempotency yok; negatif stok |
| 24 | Manager | mock | Menü reports mock; targets dead |
| 25 | L10n | kırık | `tr.json` geçersiz JSON |
| 26 | Güvenlik | P0/P1 | Admin `'1'`; credential anti-pattern |
| 27 | Fiyat motor | kritik | maps migrate yok; defaultPrice 0 |
| 28 | İade | hatalı | Stok düşüyor; Logo wholesale |
| 29 | POD | kısmi | Sync yok; imza zorunlu değil |
| 30 | Production | blokeli | INTERNET/signing/privacy/crash |

## 4. Fazlı roadmap

### Faz 0 — Güvenilirlik (hemen)
- JobQueue: `scheduled_at`, max retry, dead-letter, unknown-type fail
- Idempotency (`client_ref` / Logo answer)
- PriceEngine: migrate `customer_price_maps` + `products.price` fallback
- Logo tip map (van/toptan 8 / iade 3)
- `tr.json` JSON fix
- Android main `INTERNET`; secure defaults checklist

### Faz 1 — MVP plasiyer günü
- Mesai persist + gate (`work_logs`)
- Check-in zorunlu satış/tahsilat (`visit_id`)
- Gerçek EOD + araç sayım
- Cari `credit_limit` + satış öncesi risk
- Makbuz yazdırma (tahsilat)
- Fatura listesi gerçek DB
- Negatif stok engeli; iadede stok artışı

### Faz 2 — Stok / fiyat / kampanya
- Birim çevrimi stoka yansısın
- Transfer stok hareketi + Logo
- Kampanya pull + belgeye iskonto/bedelsiz
- PriceEngine sipariş+fatura+fiyat gör ortak

### Faz 3 — Denetim
- NFC↔check-in veya politika
- Geofence fail-closed + parametrik radius
- POD sync + PNG/PDF
- GPS tek facade + iOS privacy

### Faz 4 — Yönetim
- Gerçek KPI / hedef / leaderboard
- Gamification şema + abuse engeli

### Faz 5 — Sertleştirme
- Unit/widget test suite (P0 domainler)
- Crash reporting; print→logger
- Store checklist (Play/App Store)
- Secret env + admin şifre

## 5. Zorunlu ajan paneli (kural)

Her özellik tamamlanırken:
1. **Test ajanı** — regresyon testi
2. **Muhasebe uzmanı** — KDV/cari/fiş
3. **Saha satış uzmanı** — plasiyer gün akışı

Kural dosyası: `.cursor/rules/multi-agent-sfa-workflow.mdc`

## 6. Onay

Tasarım mevcut mimariyi değiştirmez; gap kapatma sırası yukarıdaki fazlara göre uygulanır.
**Sonraki adım:** `2026-07-15-saha-satis-implementation-plan.md` (Faz 0–1 bite-size).
