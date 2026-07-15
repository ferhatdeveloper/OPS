# EXFINERP Modüller Dizini

Bu dizin EXFINERP projesinin modüler yapısını içerir. Her modül bağımsız olarak geliştirilebilir ve test edilebilir.

## Dizin Yapısı

```
Modules/
├── docs/                    # Modül dokümantasyonları
│   ├── module_development_guide.md
│   └── modules.md
├── scripts/                 # Modül yönetim scriptleri
│   └── create_module.dart
├── templates/              # Modül şablonları
└── README.md
```

## Modül Oluşturma

Yeni bir modül oluşturmak için:

```bash
cd scripts
dart create_module.dart modul_adi
```

## Modül Geliştirme

Modül geliştirme sürecinde aşağıdaki dokümanlara başvurun:

1. [Modül Geliştirme Kılavuzu](docs/module_development_guide.md)
2. [Modül Listesi ve Durumları](docs/modules.md)

## Modül Yapısı

Her modül aşağıdaki standart yapıyı takip etmelidir:

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

## Modül Bağımlılıkları

- Her modül `core_module`'e bağımlı olabilir
- Modüller arası bağımlılıklar interface'ler üzerinden olmalıdır
- Çevrimsel bağımlılıklar yasaktır

## Geliştirme Kuralları

1. Her modül kendi içinde bağımsız çalışabilmelidir
2. Modüller arası iletişim Event Bus veya interface'ler üzerinden yapılmalıdır
3. Her modül için kapsamlı test yazılmalıdır
4. Dokümantasyon güncel tutulmalıdır
5. Örnek kullanımlar eklenmelidir

## Modül Yayınlama

1. Semantic versioning kullanın
2. CHANGELOG.md güncelleyin
3. README.md'yi güncelleyin
4. Testleri çalıştırın
5. Tag oluşturun

## Yardım ve Destek

Modül geliştirme sürecinde yardıma ihtiyacınız olursa:

1. Dokümantasyonu inceleyin
2. Örnek modülleri referans alın
3. Ekip liderinize danışın 