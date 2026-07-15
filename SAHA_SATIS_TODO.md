# SAHA SATIŞ — Plasiyer Gün TODO + Geliştirici Backlog

Bu dosya plasiyer operasyon checklist’i ile 30 ajan audit sonuçlu geliştirici TODO’sunu birleştirir.
Tasarım: `docs/plans/2026-07-15-saha-satis-roadmap-design.md`

---

## A) Plasiyer gün akışı (hedef ürün davranışı)

### 1. Güne başlarken
- [ ] **Mesai Başlat** — GPS + KM; kalıcı `work_logs` (şu an UI-only)
- [ ] **Veri Senkronizasyonu** — stok, fiyat, cari bakiye, kampanya pull
- [ ] **Araç Yükleme Kontrolü** — fiziksel vs sistem; onay (şu an yükleme var, mutabakat yok)
- [ ] **Rota İnceleme** — günlük rut + harita

### 2. Saha operasyonları
- [ ] **Check-In** — GPS geofence (koordinat zorunlu); NFC opsiyon/politika
- [ ] **Cari Durum** — bakiye + risk limiti + yaşlandırma (risk limit P0 eksik)
- [ ] **Merchandising** — audit (rakip tablosu migrate P0)
- [ ] **Soğuk satış** — sipariş + kuyruk (fiyat 0₺ riski P0)
- [ ] **Sıcak satış** — fatura + araç stok (negatif/yetersiz engeli P0)
- [ ] **İade** — stok artışı + Logo TYPE 3 (şu an yanlış düşüm/wholesale)
- [ ] **Tahsilat** — nakit/KK/çek(+senet) + makbuz yazdır
- [ ] **Ziyaret notları** — structured outcome (şu an kısmen kayboluyor)
- [ ] **Check-Out** — imza zorunlu (bypass kapat)

### 3. Gün sonu
- [ ] **Mutabakat** — gerçek satış/tahsilat özeti (mock kaldır)
- [ ] **Kasa teslimi** — nakit/çek dökümü
- [ ] **Araç stok EOD** — sayım + `reconcileEndOfDay` gerçek
- [ ] **Veri gönderimi** — pending=0; Logo REF
- [ ] **Mesai Bitir** — open visit / unsync engeli

---

## B) Geliştirici backlog (öncelik)

### P0 — Bloklayıcı
- [ ] `tr.json` geçerli JSON
- [ ] PriceEngine: `customer_price_maps` migrate + `products.price` fallback
- [ ] JobQueue: backoff, dead-letter, idempotency
- [ ] Logo invoice TYPE map (8/3/van) + iade stok artışı
- [ ] `credit_limit` + satış risk gate
- [ ] Mesai persist + satış gate
- [ ] Satış/tahsilat `visit_id` zorunlu
- [ ] Gerçek EOD (mock checklist kaldır)
- [ ] Fatura listesi SQLite
- [ ] Negatif araç stok engeli
- [ ] Unit test: mapper + queue + fiyat
- [ ] Android main `INTERNET`
- [ ] Competitor DDL migrate (çakışma önle)

### P1 — MVP sertleştirme
- [ ] Tahsilat `printCollection` + çek alanları Logo’ya
- [ ] KDV ürün oranından; print KDV düzelt
- [ ] Kampanya master pull + belgeye iskonto/bedelsiz
- [ ] Birim `convertToMainUnit` satış/stokta
- [ ] Transfer stok hareketi
- [ ] POD sync + imza zorunlu fatura
- [ ] GPS tek facade; iOS location plist
- [ ] Connectivity → `processQueue`
- [ ] Cihaz gate production; plaintext şifre → secure storage
- [ ] Expenses DDL düzelt; DB version/onUpgrade

### P2 — Denetim / yönetim
- [ ] NFC ↔ check-in politika
- [ ] Manager gerçek KPI (mock kaldır/etiketle)
- [ ] Gamification şema + userId
- [ ] Saha ekranları i18n
- [ ] Crash reporting + print temizliği

### P3 — Polish
- [ ] Riverpod modernizasyon
- [ ] Bundle id / release signing
- [ ] Store privacy manifesto

---

## C) Zorunlu ajan paneli

Her P0/P1 işinde:
1. Test ajanı
2. Muhasebe uzmanı
3. Saha satış uzmanı

Kural: `.cursor/rules/multi-agent-sfa-workflow.mdc`

---

> Uygulama sırası: `docs/plans/2026-07-15-saha-satis-implementation-plan.md` Task 1→10
