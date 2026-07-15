import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print(
      'Modül adı belirtilmedi. Kullanım: dart create_module.dart modul_adi',
    );
    exit(1);
  }

  final moduleName = args[0];
  final moduleDir = 'modules/$moduleName';

  // Modül dizin yapısını oluştur
  await createDirectoryStructure(moduleDir);

  // Temel dosyaları oluştur
  await createBaseFiles(moduleDir, moduleName);

  print('$moduleName modülü başarıyla oluşturuldu!');
  print('Kontrol listesi:');
  print('1. pubspec.yaml dosyasını düzenleyin');
  print('2. README.md dosyasını güncelleyin');
  print('3. Örnek kullanımları example/ dizinine ekleyin');
  print('4. Test dosyalarını oluşturun');
}

Future<void> createDirectoryStructure(String moduleDir) async {
  final directories = [
    '$moduleDir/lib/src/models',
    '$moduleDir/lib/src/repositories',
    '$moduleDir/lib/src/services',
    '$moduleDir/lib/src/providers',
    '$moduleDir/lib/src/views',
    '$moduleDir/lib/src/widgets',
    '$moduleDir/test',
    '$moduleDir/example',
  ];

  for (var dir in directories) {
    await Directory(dir).create(recursive: true);
    print('Dizin oluşturuldu: $dir');
  }
}

Future<void> createBaseFiles(String moduleDir, String moduleName) async {
  // pubspec.yaml
  await File('$moduleDir/pubspec.yaml').writeAsString('''
name: ${moduleName}_module
description: EXFINERP ${moduleName} modülü
version: 0.0.1
publish_to: none

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  core_module:
    path: ../core
  riverpod: ^2.4.9
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  flutter_lints: ^3.0.1
''');

  // README.md
  await File('$moduleDir/README.md').writeAsString('''
# ${moduleName}_module

EXFINERP ${moduleName} modülü

## Özellikler

- Özellik 1
- Özellik 2
- Özellik 3

## Kurulum

\`\`\`yaml
dependencies:
  ${moduleName}_module:
    path: ../modules/${moduleName}
\`\`\`

## Kullanım

\`\`\`dart
void main() {
  ${moduleName}Module.initialize(
    config: ${moduleName}Config(
      // konfigürasyon
    ),
  );
}
\`\`\`

## Test

\`\`\`bash
flutter test
\`\`\`

## Lisans

Bu modül EXFINERP projesinin parçasıdır ve lisans koşullarına tabidir.
''');

  // CHANGELOG.md
  await File('$moduleDir/CHANGELOG.md').writeAsString('''
# Changelog

## [0.0.1] - ${DateTime.now().toString().split(' ')[0]}

### Eklenen
- İlk sürüm
''');

  // Ana modül dosyası
  await File('$moduleDir/lib/${moduleName}_module.dart').writeAsString('''
library ${moduleName}_module;

import 'package:flutter/material.dart';
import 'package:core_module/core_module.dart';
import 'src/config.dart';

export 'src/config.dart';
export 'src/models/models.dart';
export 'src/providers/providers.dart';
export 'src/views/views.dart';

class ${moduleName}Module {
  static bool _initialized = false;

  static void initialize({
    required ${moduleName}Config config,
  }) {
    if (_initialized) {
      throw Exception('${moduleName}Module zaten initialize edilmiş');
    }

    // Modül başlatma işlemleri
    _initialized = true;
  }

  static bool get isInitialized => _initialized;
}
''');

  // Konfigürasyon dosyası
  await File('$moduleDir/lib/src/config.dart').writeAsString('''
class ${moduleName}Config {
  const ${moduleName}Config({
    // Konfigürasyon parametreleri
  });
}
''');

  // Model export dosyası
  await File('$moduleDir/lib/src/models/models.dart').writeAsString('''
// Model exportları buraya
''');

  // Provider export dosyası
  await File('$moduleDir/lib/src/providers/providers.dart').writeAsString('''
// Provider exportları buraya
''');

  // View export dosyası
  await File('$moduleDir/lib/src/views/views.dart').writeAsString('''
// View exportları buraya
''');

  // Örnek kullanım
  await File('$moduleDir/example/main.dart').writeAsString('''
import 'package:flutter/material.dart';
import 'package:${moduleName}_module/${moduleName}_module.dart';

void main() {
  ${moduleName}Module.initialize(
    config: ${moduleName}Config(),
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${moduleName} Module Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('${moduleName} Module Example'),
        ),
      ),
    );
  }
}
''');

  // Test dosyası
  await File('$moduleDir/test/${moduleName}_test.dart').writeAsString('''
import 'package:flutter_test/flutter_test.dart';
import 'package:${moduleName}_module/${moduleName}_module.dart';

void main() {
  group('${moduleName}Module', () {
    test('initialize çalışıyor', () {
      expect(
        () => ${moduleName}Module.initialize(config: ${moduleName}Config()),
        returnsNormally,
      );
    });

    test('tekrar initialize edilemiyor', () {
      expect(
        () => ${moduleName}Module.initialize(config: ${moduleName}Config()),
        throwsException,
      );
    });
  });
}
''');
}
 