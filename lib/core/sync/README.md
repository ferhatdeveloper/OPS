# Veri Senkronizasyon Modülü

Bu modül, EXFINERP uygulamasında SQLite ve Supabase arasında veri senkronizasyonunu sağlar.

## Özellikler

- **Otomatik Senkronizasyon**: Belirli aralıklarla otomatik senkronizasyon
- **Manuel Senkronizasyon**: Kullanıcı tarafından başlatılabilen senkronizasyon
- **Onay Sistemi**: Veri değişikliklerinin onaylanması gereken sistem
- **Yedekleme**: Senkronizasyon öncesi otomatik yedekleme
- **Hata Yönetimi**: Kapsamlı hata yakalama ve raporlama
- **Realtime Sync**: Supabase realtime özellikleri ile anlık senkronizasyon

## Dosya Yapısı

```
lib/core/sync/
├── sync_manager.dart          # Ana senkronizasyon yöneticisi
├── sync_service.dart          # Senkronizasyon servisi
├── schema_manager.dart        # Veritabanı şema yönetimi
├── backup_manager.dart        # Yedekleme yönetimi
├── sync_config.dart           # Senkronizasyon konfigürasyonu
├── sync_result.dart           # Senkronizasyon sonuçları
├── approval_status.dart       # Onay durumu enum'ları
└── README.md                  # Bu dosya
```

## Kullanım

### Temel Kullanım

```dart
import 'package:exfinerp/core/sync/sync_manager.dart';
import 'package:exfinerp/core/sync/sync_config.dart';

// SyncManager'ı başlat
await SyncManager().initialize(
  database: database,
  supabase: supabaseClient,
  config: SyncConfig.defaultConfig,
);

// Manuel senkronizasyon
final result = await SyncManager().syncAll();

// Belirli tablo senkronizasyonu
final result = await SyncManager().syncTable('users');
```

### Konfigürasyon

```dart
final config = SyncConfig(
  autoSyncEnabled: true,
  syncIntervalSeconds: 300, // 5 dakika
  maxRetryAttempts: 3,
  backupEnabled: true,
  encryptionEnabled: false,
  syncableTables: ['users', 'products', 'orders'],
);
```

### Onay Sistemi

```dart
// Veri ekleme (onay bekler)
await db.insert('users', {
  'name': 'John Doe',
  'email': 'john@example.com',
  'approval_status': ApprovalStatus.pending.value,
  'is_synced': 0,
});

// Onaylama
await db.update('users', {
  'approval_status': ApprovalStatus.approved.value,
}, where: 'id = ?', whereArgs: [userId]);
```

## Onay Durumları

- `0` - Beklemede (Pending)
- `1` - Onaylandı (Approved)
- `2` - Senkronize Edildi (Synced)
- `3` - Reddedildi (Rejected)
- `4` - Hata (Error)

## Senkronizasyon Akışı

1. **Yerel Değişiklikler**: Kullanıcı veri ekler/düzenler
2. **Onay**: Veri onaylanır (approval_status = 1)
3. **Yükleme**: Onaylanmış veriler Supabase'e yüklenir
4. **İndirme**: Supabase'den yeni veriler indirilir
5. **Güncelleme**: Yerel veritabanı güncellenir

## Hata Yönetimi

```dart
try {
  final result = await SyncManager().syncAll();
  if (result.success) {
    print('Senkronizasyon başarılı');
  } else {
    print('Senkronizasyon hatası: ${result.errorMessage}');
  }
} catch (e) {
  print('Beklenmeyen hata: $e');
}
```

## Yedekleme

Modül otomatik olarak senkronizasyon öncesi yedekleme yapar:

- SQLite veritabanı yedeği
- Supabase veritabanı yedeği
- Yedek dosyaları sıkıştırılmış format

## Güvenlik

- Tüm veri transferleri HTTPS üzerinden
- Supabase Row Level Security (RLS) aktif
- Veri şifreleme desteği
- Audit logging

## Performans

- Batch işlemler
- Lazy loading
- Connection pooling
- Optimized queries

## Sorun Giderme

### Yaygın Hatalar

1. **Bağlantı Hatası**: İnternet bağlantısını kontrol edin
2. **Yetki Hatası**: Supabase API anahtarlarını kontrol edin
3. **Şema Hatası**: Veritabanı şemasını kontrol edin
4. **Disk Alanı**: Yeterli disk alanı olduğundan emin olun

### Loglar

Senkronizasyon logları şu konumlarda bulunur:
- Uygulama logları: `logs/sync.log`
- Hata logları: `logs/error.log`
- Debug logları: `logs/debug.log`

## Geliştirme

### Yeni Tablo Ekleme

```dart
// Tablo oluştur ve senkronize et
await SyncManager().createAndSyncTable('new_table', [
  'name TEXT NOT NULL',
  'description TEXT',
  'price REAL',
]);
```

### Özel Konfigürasyon

```dart
final customConfig = SyncConfig(
  autoSyncEnabled: true,
  syncIntervalSeconds: 60,
  maxRetryAttempts: 5,
  conflictStrategy: 'lastWriteWins',
  backupEnabled: true,
  encryptionEnabled: true,
  auditLogEnabled: true,
  batchSize: 50,
  timeoutSeconds: 60,
  syncableTables: ['custom_table'],
);
```

## Lisans

Bu modül EXFINERP projesi kapsamında geliştirilmiştir. 