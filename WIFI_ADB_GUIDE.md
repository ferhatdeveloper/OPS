# WiFi ADB Bağlantı Rehberi

Bu rehber, Android cihazınızı kablosuz olarak ADB'ye bağlamak ve Flutter uygulamalarını WiFi üzerinden çalıştırmak için gerekli adımları içerir.

## 1. Otomatik Bağlantı (mDNS - En Kolay Yöntem)
Eğer cihazınızda Kablosuz Hata Ayıklama açıksa ve bilgisayarınızla aynı ağdaysanız, cihaz bazen otomatik olarak keşfedilebilir.

**Komutlar:**
```bash
# Servisleri tara
adb mdns services

# Çıkan IP ve port ile bağlan (Örn: 192.168.1.4:5555)
adb connect <cihaz-ip>:5555
```

## 2. Android 11+ (Eşleştirme Kodu ile)
Bu yöntem en güvenli ve modern yöntemdir.

1. **Ayarlar > Geliştirici Seçenekleri > Kablosuz Hata Ayıklama**'yı açın.
2. **Cihazı eşleştirme koduyla eşle**'ye dokunun.
3. Bilgisayarda şu komutu çalıştırın:
   ```bash
   adb pair <ip-adresi>:<eşleştirme-portu>
   ```
4. Eşleştirme kodunu girin.
5. Eşleşme tamamlandığında, ana ekrandaki "IP adresi ve port" bilgisiyle bağlanın:
   ```bash
   adb connect <ip-adresi>:<bağlantı-portu>
   ```

## 3. Eski Yöntem (USB Gerektirir)
Android 10 ve altı veya diğer yöntemler çalışmadığında:

1. Cihazı USB ile bağlayın.
2. Bilgisayarda şu komutu çalıştırın:
   ```bash
   adb tcpip 5555
   ```
3. USB kablosunu çıkarın.
4. Cihazın IP adresini bulun (Ayarlar > Tablet/Telefon Hakkında > Durum).
5. Bağlanın:
   ```bash
   adb connect <cihaz-ip>:5555
   ```

## Faydalı Komutlar
- `adb devices`: Bağlı cihazları listeler.
- `adb kill-server`: ADB sunucusunu durdurur (bağlantı sorunlarında kullanın).
- `adb start-server`: ADB sunucusunu başlatır.
- `flutter run -d <cihaz-id>`: Belirli bir cihazda uygulamayı çalıştırır.
