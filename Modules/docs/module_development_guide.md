# EXFINERP Modül Geliştirme Kılavuzu

## İçindekiler
1. [Giriş](#giriş)
2. [Modül Yapısı](#modül-yapısı)
3. [Modül Geliştirme Kuralları](#modül-geliştirme-kuralları)
4. [Modül Entegrasyonu](#modül-entegrasyonu)
5. [Modül Bağımlılıkları](#modül-bağımlılıkları)
6. [Test ve Dokümantasyon](#test-ve-dokümantasyon)
7. [Örnek Modül Yapısı](#örnek-modül-yapısı)

## Giriş

EXFINERP modüler bir yapıda geliştirilmektedir. Bu yapı sayesinde:
- Ekip üyeleri farklı modüller üzerinde paralel çalışabilir
- Modüller bağımsız olarak test edilebilir
- Modüller farklı projelerde tekrar kullanılabilir
- Bakım ve güncellemeler daha kolay yapılabilir

## Modül Yapısı

Her modül aşağıdaki yapıyı takip etmelidir:

```
module_name/
├── lib/
│   ├── src/
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── services/
│   │   ├── providers/
│   │   ├── views/
│   │   └── widgets/
│   ├── module_name.dart
│   └── config.dart
├── test/
├── example/
├── pubspec.yaml
└── README.md
```

## Modül Geliştirme Kuralları

### 1. Bağımsızlık İlkesi
- Her modül kendi içinde bağımsız çalışabilmelidir
- Core modülü dışında başka modüllere sıkı bağımlılık olmamalıdır
- Modüller arası iletişim interface'ler üzerinden yapılmalıdır

### 2. Versiyon Yönetimi
- Semantic Versioning (MAJOR.MINOR.PATCH) kullanılmalıdır
- Her değişiklik CHANGELOG.md'de dokümante edilmelidir
- Breaking change'ler MAJOR versiyon artışı gerektirir

### 3. Dependency Injection
- Modül servisleri Riverpod üzerinden sağlanmalıdır
- Bağımlılıklar constructor injection ile yönetilmelidir
- Test edilebilirlik için mock'lanabilir yapıda olmalıdır

### 4. Hata Yönetimi
- Modüle özel exception sınıfları tanımlanmalıdır
- Hata durumları dokümante edilmelidir
- Hata mesajları çoklu dil desteğine uygun olmalıdır

## Modül Entegrasyonu

### Modülü Projeye Ekleme

1. pubspec.yaml'a modülü ekleyin:
```yaml
dependencies:
  module_name:
    path: ../modules/module_name
    # veya
    git:
      url: https://github.com/username/module_name.git
      ref: v1.0.0
```

2. Modülü initialize edin:
```dart
void main() {
  ModuleName.initialize(
    config: ModuleConfig(
      // modül konfigürasyonu
    ),
  );
}
```

### Modüller Arası İletişim

1. Event Bus Kullanımı:
```dart
// Event yayınlama
ModuleEventBus.publish(ModuleEvent());

// Event dinleme
ModuleEventBus.subscribe<ModuleEvent>((event) {
  // event işleme
});
```

2. Shared State Yönetimi:
```dart
// State provider tanımlama
final moduleStateProvider = StateNotifierProvider<ModuleState>((ref) => ModuleState());

// State kullanımı
ref.watch(moduleStateProvider);
```

## Modül Bağımlılıkları

### Core Modülü
- Tüm modüllerin kullanabileceği ortak fonksiyonlar
- Temel UI bileşenleri
- Network katmanı
- Yerel depolama
- Yetkilendirme

### Modül Bağımlılık Kuralları
1. Modüller sadece core modülüne bağımlı olabilir
2. Modüller arası bağımlılıklar interface'ler üzerinden olmalıdır
3. Çevrimsel bağımlılıklar yasaktır

## Test ve Dokümantasyon

### Test Gereksinimleri
- Unit test coverage minimum %80 olmalıdır
- Widget testleri yazılmalıdır
- Integration testler eklenmelidir
- Performance testleri yapılmalıdır

### Dokümantasyon
- API dokümantasyonu güncel tutulmalıdır
- Örnek kullanımlar example/ klasöründe olmalıdır
- README.md kurulum ve kullanım bilgilerini içermelidir

## Örnek Modül Yapısı

### Finans Modülü Örneği

```
finance_module/
├── lib/
│   ├── src/
│   │   ├── models/
│   │   │   ├── transaction.dart
│   │   │   └── account.dart
│   │   ├── repositories/
│   │   │   └── finance_repository.dart
│   │   ├── services/
│   │   │   └── finance_service.dart
│   │   ├── providers/
│   │   │   └── finance_providers.dart
│   │   └── views/
│   │       └── finance_dashboard.dart
│   ├── finance_module.dart
│   └── config.dart
├── test/
│   └── finance_test.dart
├── example/
│   └── main.dart
├── pubspec.yaml
└── README.md
```

### Modül Kullanım Örneği

```dart
// Modülü initialize etme
void main() {
  FinanceModule.initialize(
    config: FinanceConfig(
      apiUrl: 'https://api.example.com',
      cacheEnabled: true,
    ),
  );
}

// Modül widget'larını kullanma
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FinanceDashboard(),
    );
  }
}

// Modül servislerini kullanma
final financeService = ref.watch(financeServiceProvider);
final transactions = await financeService.getTransactions();
```

## Modül Geliştirme Kontrol Listesi

- [ ] Modül yapısı standartlara uygun
- [ ] Bağımlılıklar minimum seviyede
- [ ] Testler yazılmış ve çalışıyor
- [ ] Dokümantasyon güncel
- [ ] Örnek kullanımlar mevcut
- [ ] CHANGELOG.md oluşturulmuş
- [ ] README.md detaylı ve güncel
- [ ] Performans testleri yapılmış
- [ ] Hata yönetimi uygulanmış
- [ ] Çoklu dil desteği eklenmiş 