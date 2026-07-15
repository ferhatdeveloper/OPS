/// EXFINOPS PostgreSQL Şema Yükleyici
/// Kullanım: dart run tools/setup_db.dart [firm_nr] [period_nr]
/// Örnek:    dart run tools/setup_db.dart 1 1

import 'dart:io';
import 'package:postgres/postgres.dart';

void main(List<String> args) async {
  final firmNr = args.isNotEmpty ? args[0].padLeft(2, '0') : '01';
  final periodNr = args.length > 1 ? args[1].padLeft(2, '0') : '01';

  print('🔌 EXFINOPS PostgreSQL Şema Kurulumu');
  print('   Firma: $firmNr | Dönem: $periodNr');
  print('─' * 50);

  final connection = await Connection.open(
    Endpoint(
      host: '127.0.0.1',
      port: 5432,
      database: 'EXFINOPS',
      username: 'postgres',
      password: 'YOUR_DB_PASSWORD',
    ),
    settings: const ConnectionSettings(
      sslMode: SslMode.disable,
      connectTimeout: Duration(seconds: 10),
    ),
  );

  print('✅ Bağlantı başarılı!');

  // 1. SQL şema dosyasını oku
  final schemaFile = File('sql/schema/02_exfin_tenant_functions.sql');
  if (!schemaFile.existsSync()) {
    print('❌ Şema dosyası bulunamadı: ${schemaFile.path}');
    exit(1);
  }

  final schemaSql = schemaFile.readAsStringSync();

  // 2. Şema fonksiyonlarını yükle
  print('\n📦 Şema fonksiyonları yükleniyor...');
  
  // CREATE EXTENSION, CREATE TABLE ve CREATE FUNCTION bloklarını ayrıştır
  // Fonksiyon tanımları $$ ile sınırlı olduğundan özel ayrıştırma gerekir
  final statements = _splitSqlStatements(schemaSql);
  
  int success = 0, failed = 0;
  for (final stmt in statements) {
    final trimmed = stmt.trim();
    if (trimmed.isEmpty || trimmed.startsWith('--')) continue;
    try {
      await connection.execute(trimmed);
      success++;
      // Kısa tanımlayıcı yazdır
      if (trimmed.toUpperCase().contains('CREATE TABLE')) {
        final match = RegExp(r'CREATE TABLE IF NOT EXISTS (\w+)', caseSensitive: false).firstMatch(trimmed);
        if (match != null) print('  ✓ Tablo: ${match.group(1)}');
      } else if (trimmed.toUpperCase().contains('CREATE OR REPLACE FUNCTION')) {
        final match = RegExp(r'CREATE OR REPLACE FUNCTION (\w+)', caseSensitive: false).firstMatch(trimmed);
        if (match != null) print('  ✓ Fonksiyon: ${match.group(1)}');
      }
    } catch (e) {
      failed++;
      final preview = trimmed.length > 60 ? trimmed.substring(0, 60) : trimmed;
      print('  ⚠️  [$preview...]: ${e.toString().split('\n').first}');
    }
  }

  print('\n📊 Sonuç: $success başarılı, $failed uyarı/hata');

  // 3. SETUP_EXFIN_COMPANY fonksiyonunu çağır
  print('\n🏗️  Firma+Dönem tabloları oluşturuluyor...');
  try {
    final result = await connection.execute(
      Sql.named("SELECT SETUP_EXFIN_COMPANY(@firm, @period)"),
      parameters: {'firm': firmNr, 'period': periodNr},
    );
    final msg = result.first.toColumnMap().values.first?.toString() ?? '';
    print(msg);
  } catch (e) {
    print('❌ SETUP_EXFIN_COMPANY hatası: $e');
    exit(1);
  }

  // 4. Oluşturulan tabloları listele
  print('\n📋 EXFINOPS tabloları:');
  final tables = await connection.execute(
    "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE 'exfin_%' ORDER BY table_name",
  );
  for (final row in tables) {
    print('  • ${row.toColumnMap()['table_name']}');
  }

  await connection.close();
  print('\n✅ Kurulum tamamlandı!');
}

/// \$\$...\$\$ bloklarını koruyarak SQL ifadelerini ayırır
List<String> _splitSqlStatements(String sql) {
  final statements = <String>[];
  final buffer = StringBuffer();
  bool insideDollarBlock = false;
  
  final lines = sql.split('\n');
  for (final line in lines) {
    buffer.writeln(line);
    
    // $$ bloğu başlangıç/bitiş kontrolü
    final dollarCount = '\$\$'.allMatches(line).length;
    if (dollarCount.isOdd) {
      insideDollarBlock = !insideDollarBlock;
    }
    
    // Noktalı virgül — blok içinde değilse statement sonu
    if (!insideDollarBlock && line.trimRight().endsWith(';')) {
      statements.add(buffer.toString());
      buffer.clear();
    }
  }
  
  if (buffer.isNotEmpty) {
    statements.add(buffer.toString());
  }
  
  return statements;
}
