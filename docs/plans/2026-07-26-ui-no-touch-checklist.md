# UI No-Touch Checklist — 2026-07-26

**Rol:** UI uzmanı · **Amaç:** Görsel redesign yok; sadece dil bağlama.

## Denetim özeti (son değişiklikler)

| Alan | Sonuç | Not |
|------|--------|-----|
| Login slogan (`AnimatedLoginSlogan`) | **OK** | Aynı stil/genişlik; `height: 28` + ellipsis; l10n `auth.slogan`. Layout bozulmuyor → timing dokunulmadı. |
| `order_customer_selection_screen` | **Minimal / kabul** | Yeni zorunlu cari seçim ekranı. Mevcut field_sales paleti (`#375A7F`, `#F8F9FD`). Redesign değil. |
| `order_entry` AppBar alt başlık | **Minimal / kabul** | Cari ad/kod bilgisi; title 20→18 (yer için). Tema/renk değişmedi. |

## Agent checklist (her PR / özellik)

- [ ] Renk / gradient / font / padding / radius değişmedi mi?
- [ ] Yeni ekran varsa mevcut Flat UI paletine mi uyuyor? (yeni tasarım dili yok)
- [ ] Hardcoded TR string → `translate('...')` + çeviri dosyaları mı?
- [ ] Animasyon varsa layout sabit mi? (sabit boyut / overflow). Bozuluyorsa sadece timing.
- [ ] “Güzelleştirme” commit’i yok mu? (iş kuralı / l10n / bugfix)

## Yazılacak / yazılan kural

- `.cursor/rules/ui-no-touch.mdc` → **UI güzel — dokunma; sadece dil bağlama**

## Bilinçli dokunulmayanlar

- Login slogan animasyon timing’i (layout stabil)
- `order_customer_selection` görsel bileşenleri (iş akışı ekranı; redesign yapılmadı)
- Büyük UI refaktör yok · Commit yok (bu denetim oturumu)
