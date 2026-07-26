# ku.json — field_sales finans / virman Latin polish (P1)

**Tarih:** 2026-07-26  
**Kapsam:** `assets/translations/ku.json` → `field_sales` kritik finans/ödeme/virman metinleri  
**Commit:** yok (bu turda)

## Kural

`field_sales` finans yolunda **Latin Kurmanji** + ERP ödünç terimler tutarlı kalsın:

| Terim | Latin standart | Kaçın |
|-------|----------------|-------|
| Virman | `Virman` / `Fîşa Virmanê` | `Virmên`, `Veguheztin` (fiş adı olarak) |
| Tahsilat | `Tahsîlat` | karışık `Berhevkirin` (yalnız tip sheet / nakit başlık) |
| Nakit / KK | `Nakit`, `KK` | İngilizce kalıntı |
| Kasa | `Kasa` | `Qase`, `Safe Code` |
| Finans | `Finans` / `FINANS` | `Malî` (menü etiketi) |

## Bu turda düzeltilen anahtarlar

- Menü: `modules.virman`, `finans`
- Ödeme: `payment_entry*`, `payment_cash_out`, `payment_cash_code`, `payment_out_saved`
- Virman formu: `virman_entry_title` … `virman_saved` (başlık = menü ile aynı `Fîşa Virmanê`)
- Tip sheet: `finance_type_group_out`, `finance_type_virman`
- Tahsilat giriş: `collection_entry_title` / `collection_confirm` / `collection_saved` + çek alan etiketleri

## Not

Eski menü/dashboard anahtarlarının bir kısmı hâlâ Sorani (Arap harfli) kalabilir; **yeni MBT finans ekranları** Latin tutarlılığı hedefler. UI redesign yok — yalnızca l10n metin.
