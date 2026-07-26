# Yeni Modül UI Şablonu — Kopyala Mevcut Stil

**Tarih:** 2026-07-26  
**Rol:** UI uzmanı  
**Kural:** Redesign yasak. Yeni ekran = mevcut field_sales stilinin birebir kopyası.  
**Kaynak kural:** `.cursor/rules/ui-no-touch.mdc` · `docs/plans/2026-07-26-ui-no-touch-checklist.md`

## Referans dosyalar (zorunlu okuma)

| Öncelik | Dosya | Ne kopyalanır |
|--------:|-------|----------------|
| 1 | `lib/modules/field_sales/orders/view/order_customer_selection_screen.dart` | AppBar gradient, Scaffold bg, arama, boş state, kartlı liste satırı |
| 2 | `lib/modules/field_sales/customers/view/customer_list_screen.dart` | Liste satırı (avatar + başlık + alt satır + chevron), loading, boş ikon |
| 3 | `lib/modules/field_sales/orders/view/order_entry_screen.dart` | AppBar çift satır title (ana + alt başlık) |

> Yeni modül ekranı açmadan önce bu üç dosyayı aç; token’ları ezberden uydurma.

---

## 1. Renk ve yüzey token’ları (değiştirme)

| Token | Değer | Kullanım |
|-------|--------|----------|
| Primary | `#375A7F` → `Color(0xFF375A7F)` | Avatar metin, gölge tonu, vurgu |
| Gradient uç | `#00A8E8` → `Color(0xFF00A8E8)` | AppBar gradient sağ/alt |
| Scaffold bg | `#F8F9FD` → `Color(0xFFF8F9FD)` | Sayfa arka planı |
| Kart / input fill | `Colors.white` | Liste kartı, arama alanı |
| Border | `Colors.grey.shade300` | OutlineInputBorder / arama kenarlığı |
| Alt metin | `Colors.grey.shade600` / `shade500` / `shade700` | Subtitle, hint, yardımcı metin |
| Gölge | `primary.withOpacity(0.08)` | Kart elevation gölgesi |

```dart
// ❌ BAD — yeni palet / “modernize”
const Color primary = Color(0xFF1389FD);
backgroundColor: Colors.grey.shade50,

// ✅ GOOD — referansla aynı
const Color primary = Color(0xFF375A7F);
backgroundColor: const Color(0xFFF8F9FD),
```

**Not:** `customer_list_screen` mockup mavi (`#2691E5`) kullanır; **yeni standart OPS ekranları** için `order_customer_selection` paletini (`#375A7F` + `#F8F9FD`) tercih et. Mevcut `customer_list` görünümünü yeniden boyama — dokunma.

---

## 2. AppBar checklist

- [ ] `AppBar(elevation: 0)`
- [ ] `flexibleSpace` → `LinearGradient`  
      `begin: topLeft`, `end: bottomRight`  
      `colors: [Color(0xFF375A7F), Color(0xFF00A8E8)]`
- [ ] Title: `fontWeight: FontWeight.bold`, `fontSize: 20` (tek satır)  
      veya order_entry gibi çift satır: ana `18` + alt `12` / `Colors.white70`
- [ ] Title metni: `l10n.translate('...')` — hardcoded TR yok
- [ ] Actions: yalnızca iş için gerekli `IconButton` (örn. `Icons.refresh`) — dekoratif ikon yok
- [ ] Yeni AppBar stili / blur / CustomAppBar / Sliver “hero” yok

```dart
appBar: AppBar(
  flexibleSpace: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
      ),
    ),
  ),
  title: Text(
    l10n.translate('...'),
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
  ),
  elevation: 0,
),
```

---

## 3. Scaffold + gövde iskeleti

- [ ] `Scaffold(backgroundColor: Color(0xFFF8F9FD))`
- [ ] Üstte kısa yardımcı metin varsa: `Padding.fromLTRB(16, 16, 16, 8)`, `Colors.grey.shade700`, `fontSize: 14`
- [ ] Arama (varsa): yatay `16`, `filled: true`, `fillColor: Colors.white`, radius `12`, border `grey.shade300`
- [ ] Liste: `ListView.separated` + `separatorBuilder: SizedBox(height: 8)`  
      padding `EdgeInsets.fromLTRB(16, 8, 16, 24)`
- [ ] Loading: `Center(child: CircularProgressIndicator())` — özel shimmer/skeleton yok (referansta yoksa ekleme)

---

## 4. Boş state (empty) checklist

**Tercih (seçim/liste OPS):** `order_customer_selection` — sade metin.

- [ ] `Center` + `Text(l10n.translate(...))`
- [ ] Stil: `TextStyle(color: Colors.grey.shade500)` (isteğe bağlı `fontSize: 16`)
- [ ] Arama boş vs liste boş için **ayrı l10n key** (ör. `no_customer_cards` / `customer_not_found`)
- [ ] Illüstrasyon, Lottie, “modern empty card”, gradient boş kutu **yok**

**Alternatif (customer_list zaten böyleyse aynı modülde kal):**

- [ ] `Icons.people_outline` (veya mevcut ikon), `size: 60`, `Colors.grey.shade300`
- [ ] Altında l10n metin `grey.shade500` / `fontSize: 16`
- [ ] Yeni ikon seti veya illüstrasyon ekleme

```dart
// ✅ GOOD — sade boş state
Center(
  child: Text(
    l10n.translate(emptyKey),
    style: TextStyle(color: Colors.grey.shade500),
  ),
)
```

---

## 5. Liste satırı checklist

### A) Kartlı satır (yeni OPS ekranları — `order_customer_selection`)

- [ ] `Material(color: Colors.white, borderRadius: 14, elevation: 1, shadowColor: primary.withOpacity(0.08))`
- [ ] İçeride `ListTile`
- [ ] `contentPadding: symmetric(horizontal: 16, vertical: 8)`
- [ ] `leading`: `CircleAvatar(backgroundColor: primary.withOpacity(0.12))` + baş harf (`primary`, bold)
- [ ] `title`: `fontWeight: FontWeight.w600`
- [ ] `subtitle`: `grey.shade600`, `fontSize: 12`
- [ ] `trailing`: `Icons.chevron_right`
- [ ] Radius `20+`, yeni chip/badge şeridi, renkli sol border **yok**

### B) Düz satır (yalnızca mevcut customer_list ailesine ekleme)

- [ ] Yatay `20` / dikey `16` padding
- [ ] Avatar 48×48 daire + chevron `grey.shade400`
- [ ] Divider `indent: 80` (avatar sonrası)
- [ ] Bu stili **yeni** modüllere taşıma; yeni modül → stil A

---

## 6. Metin / l10n (UI uzmanı sınırı)

- [ ] Tüm kullanıcıya görünen string → `AppLocalization.of(context).translate('...')`
- [ ] Key `assets/translations/tr.json` + diğer diller (dil çevirmeni)
- [ ] SnackBar / guard mesajı: minimal metin; yeni tema rengi yok
- [ ] Hardcoded `"MÜŞTERİLER"`, `"Arama"` vb. yeni ekranda **yasak** (eski ekranda varsa dokunmadan bırak — ui-no-touch)

---

## 7. Yasaklar (onaysız)

| Yasak | Neden |
|-------|--------|
| Yeni renk / gradient / tipografi ölçeği | Redesign |
| Radius / spacing / elevation “iyileştirme” | Görsel dil kırılır |
| Yeni kart sistemi, hero, bottom sheet skin | ui-no-touch |
| Widget ağacını görsel amaçlı yeniden yazmak | Kapsam dışı |
| Login / dashboard / mevcut AppBar’ı yeniden tasarlamak | Merkez onay gerekir |
| “Güzelleştirme” commit’i | İş kuralı / l10n / bugfix dışı |

---

## 8. PR öncesi hızlı kontrol (UI uzmanı)

```text
[ ] Primary #375A7F ve Scaffold #F8F9FD mi?
[ ] AppBar gradient birebir referans mı?
[ ] Boş state sade metin (veya mevcut ikon+metin) mi? İllüstrasyon yok mu?
[ ] Liste satırı Material 14 + ListTile (stil A) mi?
[ ] Hardcoded UI metin yok mu?
[ ] Diff’te yalnızca zorunlu iş/l10n/akış; görsel “polish” yok mu?
```

```dart
// ❌ BAD
decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), ...)

// ✅ GOOD — mevcut radius/token kopyası
borderRadius: BorderRadius.circular(14) // liste kartı
borderRadius: BorderRadius.circular(12) // arama
```

---

## 9. Ajan çıktı formatı (bu rol)

- **Durum:** hazır / yarım / eksik  
- **Risk:** (kısa — örn. customer_list ile renk sapması)  
- **TODO:** 3–5 somut madde  
- **Dosyalar:** ilgili `view/*.dart` yolları  

**Bu oturum:** checklist dokümanı yazıldı · kod değişikliği yok · commit yok.
