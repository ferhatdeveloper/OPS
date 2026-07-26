# Kampanya listesi vs Duyurular — tek kaynak (P1)

**Tarih:** 2026-07-26  
**Durum:** Karar alındı · kod alias birleştirmesi yapıldı  
**Commit:** bu turda yok

## Karar

| Rol | Tek kaynak | Rota / dosya |
|-----|------------|--------------|
| **MBT DUYURULAR** (plasiyer kampanya duyurusu dens) | **`AnnouncementsScreen`** | `/field-sales/announcements` · `announcements/view/announcements_screen.dart` |
| Menü seed | `fs_announcements` → `sub_ann_list` | `database_service.dart` |
| Dashboard | `AnnouncementsScreen` | `mobile_dashboard.dart` |
| Eski stub rota | **Alias** → aynı UI | `/field-sales/campaigns-list` · `CampaignsListScreen` |

**`CampaignsListScreen` ayrı içerik üretmez.** Yalnızca `AnnouncementsScreen` döndürür (geriye dönük deep link).

## Bilinçli ayrım (birleştirilmez)

| Bileşen | Amaç |
|---------|------|
| `campaigns/engine/campaign_engine.dart` + `campaign_model.dart` | Fiyat/indirim motoru (sipariş kalemi) |
| `campaign_management_screen.dart` | Yönetici kampanya CRUD / Logo sync (admin) |

Bunlar **duyuru dens listesi değildir**; MBT DUYURULAR ile karıştırılmaz.

## Neden announcements?

1. MBT örnek metin: «KAMPANYA DUYURUSU · Başlangıç · Bitiş» → dens alanlar `AnnouncementsScreen`’de.
2. Grid seed + dashboard zaten `fs_announcements` / `/field-sales/announcements`.
3. `CampaignsListScreen` boş stub’tu; çift kaynak riski yaratıyordu.

## Yapılacak / yapılmayacak

- [x] Alias birleştirme (`CampaignsListScreen` → `AnnouncementsScreen`)
- [x] Bu karar dokümanı
- [ ] İleride: menü/deep link’te yalnızca `/announcements` kullan; alias rotayı deprecasyon notu ile kaldırmayı değerlendir
- [ ] İleride: stub key `field_sales.stubs.campaigns_list` kullanılmıyorsa çevirilerden temizle (dil ajanı)

## OPS panel özeti

| Rol | Durum | Risk | TODO |
|-----|-------|------|------|
| Merkez | hazır | Alias unutulursa çift UI | Deep link denetimi |
| Saha satış | hazır | Plasiyer yanlış menü | Seed `fs_announcements` kalsın |
| Dil | hazır | `campaigns_list` orphan key | Key temizliği (opsiyonel) |
| Tester | yarım | Smoke titleKey | Alias smoke → announcements title |
| Yazılım/mobil | hazır | Route çakışması yok | Alias silme ayrı PR |
| UI | hazır | Dokunulmadı | Announcements görseli korunur |
