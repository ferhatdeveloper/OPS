# SAHA SATIŞ ELAMANI (PLASIYER) TODO LİSTESİ

Bu liste, bir saha satış temsilcisinin gün içindeki operasyonlarını LOGO ERP ve sektörel standartlara uygun şekilde yönetebilmesi için gereken adımları içerir.

## 1. GÜNE BAŞLARKEN (HAZIRLIK)
- [ ] **Güne Başla:** Uygulama üzerinden "Mesai Başlat" ve GPS konumunu paylaş.
- [ ] **Veri Senkronizasyonu:** Güncel stok, fiyat ve müşteri bakiyelerini merkezden çek (Sync).
- [ ] **Araç Yükleme Kontrolü:** Araçtaki fiziksel stok ile uygulamadaki araç stoğunu karşılaştır ve onayla.
- [ ] **Rota İnceleme:** Günlük rut planını ve harita üzerindeki ziyaret sıralamasını gözden geçir.

## 2. SAHA OPERASYONLARI (ZİYARET)
- [ ] **Müşteri Check-In:** Müşteri konumuna varıldığında ziyareti başlat (GPS kontrollü).
- [ ] **Cari Durum Kontrolü:** Müşterinin açık hesap risk durumunu, vadesi geçmiş borçlarını ve son alımlarını incele.
- [ ] **Raf Denetimi (Merchandising):** Ürünlerin raftaki bulunurluğunu, fiyat doğruluğunu ve rakip durumunu fotoğrafla/kaydet.
- [ ] **İşlem Tipi Seçimi:**
    - [ ] **Soğuk Satış (Pre-Sales):** Sipariş al ve merkeze gönder.
    - [ ] **Sıcak Satış (Van Sales):** İrsaliye veya Fatura kes, araçtan teslimet.
    - [ ] **İade İşlemi:** Varsa iade ürünleri kontrol et ve iade irsaliyesi oluştur.
- [ ] **Tahsilat:** Ödeme al (Nakit, Çek, Senet veya Kredi Kartı) ve tahsilat makbuzu kes.
- [ ] **Ziyaret Notları:** Görüşme sonucunu, bir sonraki ziyaret için notları ve varsa şikayetleri kaydet.
- [ ] **Müşteri Check-Out:** Ziyareti sonlandır ve bir sonraki müşteriye navigasyonu başlat.

## 3. GÜN SONU (RAPORLAMA VE KAPANIŞ)
- [ ] **Gün Sonu Mutabakatı:** Toplam satış (Sipariş/Fatura) ve toplam tahsilat rakamlarını kontrol et.
- [ ] **Kasa Teslimi:** Alınan nakit, çek ve senetlerin dökümünü merkeze bildir/teslim et.
- [ ] **Araç Stok Mutabakatı:** Kalan araç stoğunu doğrula, varsa eksik/hasarlı ürünleri bildir.
- [ ] **Veri Gönderimi:** Gün içinde yapılan tüm işlemlerin merkeze (LOGO ERP) başarıyla gönderildiğinden emin ol.
- [ ] **Günü Kapat:** "Mesai Bitir" butonuna basarak günlük raporu onayına gönder.

---
> [!NOTE]
> Bu liste, EXFINOPS saha satış uygulamasının geliştirme aşamasında referans olarak kullanılacaktır.
