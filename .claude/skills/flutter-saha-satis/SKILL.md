---
name: flutter-saha-satis
description: Use when developing any module for the EXFINERP field sales (saha satış) application - covers architecture patterns, database schema, offline-first sync, Riverpod state management, and Flutter best practices specific to this project
---

# Flutter Saha Satış Geliştirme Skill

## Proje Genel Bakış

**Teknoloji:** Flutter 3.x + Riverpod + SQLite (sqflite) + Supabase
**Mimari:** Clean Architecture + Modular
**Platform:** Android, iOS, Windows
**Konum:** `c:\Users\FERHAT\Desktop\EXFINERP`

## Temel Mimari Kurallar

### Modül Yapısı
```
lib/modules/{module_name}/
├── data/
│   ├── models/          # Freezed data classes
│   ├── repositories/    # Data access layer
│   └── datasources/     # Local (SQLite) + Remote (Supabase)
├── domain/
│   ├── entities/        # Business objects
│   └── usecases/        # Business logic
└── presentation/
    ├── screens/         # UI screens
    ├── widgets/         # Reusable widgets
    └── providers/       # Riverpod providers
```

### Offline-First Pattern
```dart
// ALWAYS save to SQLite first, then sync to Supabase
Future<void> saveOrder(Order order) async {
  // 1. Yerel DB'ye kaydet
  await localDb.insert('orders', order.toMap());

  // 2. Sync kuyruğuna ekle
  await syncQueue.add(SyncItem(
    table: 'orders',
    id: order.id,
    operation: SyncOperation.insert,
  ));

  // 3. Bağlantı varsa hemen sync dene
  if (await connectivity.hasConnection) {
    syncManager.syncPending();
  }
}
```

### Riverpod Provider Pattern
```dart
// State notifier for complex state
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier(ref.read(orderRepositoryProvider));
});

// Simple async provider
final customersProvider = FutureProvider<List<Customer>>((ref) {
  return ref.read(customerRepositoryProvider).getAll();
});
```

## Veritabanı Kuralları

### SQL Query Ekleme
Tüm SQL sorguları `lib/core/database/migrations/SqlQuerys.dart` dosyasına eklenmeli.

```dart
// SqlQuerys.dart içinde
static const String createCustomers = '''
  CREATE TABLE IF NOT EXISTS customers (
    id TEXT PRIMARY KEY,
    company_id TEXT NOT NULL,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    tax_number TEXT,
    credit_limit REAL DEFAULT 0,
    is_synced INTEGER DEFAULT 0,
    created_at TEXT,
    updated_at TEXT
  )
''';
```

### Migration Pattern
Yeni tablo eklerken migration versiyonunu artır:
```dart
// database_service.dart onCreate/onUpgrade
case 2:
  await db.execute(SqlQuerys.createCustomers);
  await db.execute(SqlQuerys.createProducts);
  break;
```

## Standart Alanlar (Tüm tablolarda)
```sql
id TEXT PRIMARY KEY,          -- UUID
company_id TEXT NOT NULL,     -- Firma ID (çoklu firma desteği)
is_synced INTEGER DEFAULT 0,  -- 0=bekliyor, 1=synced
is_deleted INTEGER DEFAULT 0, -- Soft delete
created_at TEXT,              -- ISO 8601
updated_at TEXT               -- ISO 8601
```

## Temel Servis Kullanımı

### DatabaseService
```dart
final db = await DatabaseService.instance.database;
await db.insert('table', data);
await db.query('table', where: 'company_id = ?', whereArgs: [companyId]);
```

### SyncManager
```dart
// Sync tetikleme
SyncManager.instance.syncPending();
// Sync durumu dinleme
SyncManager.instance.syncStatus.stream.listen((status) { ... });
```

## Yeni Modül Oluşturma Adımları

1. `lib/modules/{module_name}/` klasör yapısını oluştur
2. `SqlQuerys.dart`'a tablo sorgularını ekle
3. `database_service.dart`'a migration ekle
4. Model sınıfı oluştur (Freezed kullan)
5. Repository oluştur (local + remote datasource)
6. Riverpod provider oluştur
7. Screen ve widget'ları oluştur
8. `lib/core/init/navigation/routes.dart`'a route ekle
9. Menu'ye ekle (admin panel üzerinden)

## Sık Kullanılan Widget'lar

```dart
// Müşteri listesi kartı
CustomerCard(customer: customer, onTap: () => navigateToDetail(customer));

// Ürün arama
ProductSearchBar(onProductSelected: (product) { ... });

// Senkronizasyon durumu
SyncStatusBadge(); // Ana AppBar'da kullan

// Çevrimdışı banner
if (!isOnline) OfflineBanner();
```

## Test Yazma Kuralları

```dart
// Her servis için test yaz
group('CustomerService', () {
  test('should save customer to local DB', () async {
    final service = CustomerService(mockDb);
    await service.save(testCustomer);
    verify(mockDb.insert('customers', any)).called(1);
  });
});

// Test dosyası yeri: test/modules/customers/customer_service_test.dart
```

## Yaygın Hatalar ve Çözümler

| Hata | Çözüm |
|------|-------|
| SQLite `company_id` null | Company seçimi yapılmadan erişim; login flow'u kontrol et |
| Sync çakışması | SyncManager conflict resolution stratejisini kontrol et |
| Riverpod provider dispose | `ref.keepAlive()` veya `autoDispose` kaldır |
| Android GPS izni | `permission_handler` ile izin iste, `AndroidManifest.xml` kontrol et |

## Referans Dosyalar

- `lib/main.dart` - App giriş noktası
- `lib/core/sync/sync_manager.dart` - Sync motoru
- `lib/core/database/migrations/SqlQuerys.dart` - Tüm SQL
- `lib/service/database_service.dart` - DB operasyonları
- `SAHA_SATIS_PRD.md` - Tam proje gereksinimleri
