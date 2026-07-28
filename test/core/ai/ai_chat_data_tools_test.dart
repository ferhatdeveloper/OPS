// Dosya Adı: ai_chat_data_tools_test.dart
// Açıklama: SQLite-öncelikli sohbet veri araçları birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/ai/features/ai_chat_data_tools.dart';
import 'package:exfin_ops/core/ai/features/ai_chat_sqlite_runner.dart';
import 'package:exfin_ops/core/ai/features/postgrest_query_spec.dart';
import 'package:exfin_ops/core/ai/voice/ai_tts_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AiChatDataToolkit.selectTools', () {
    test('cari → customers', () {
      expect(
        AiChatDataToolkit.selectTools('ABC carisinin bakiyesi'),
        contains(AiChatDataToolId.customers),
      );
    });

    test('sipariş → orders', () {
      expect(
        AiChatDataToolkit.selectTools('Bugünkü siparişler'),
        contains(AiChatDataToolId.orders),
      );
    });

    test('stok → products', () {
      expect(
        AiChatDataToolkit.selectTools('Bu ürünün stoğu ne'),
        contains(AiChatDataToolId.products),
      );
    });

    test('genel özet → çoklu araç', () {
      final t = AiChatDataToolkit.selectTools('Bugünkü özet');
      expect(t, contains(AiChatDataToolId.orders));
      expect(t, contains(AiChatDataToolId.visits));
    });
  });

  group('AiChatSqliteRunner + gather SQLite-only', () {
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(
        'file:ai_chat_seed_${DateTime.now().microsecondsSinceEpoch}?mode=memory&cache=private',
        options: OpenDatabaseOptions(
          singleInstance: false,
          version: 1,
          onCreate: (db, _) async {
            await db.execute('''
CREATE TABLE customers (
  id TEXT PRIMARY KEY, code TEXT, name TEXT, balance REAL,
  city TEXT, is_active INTEGER, phone TEXT
)''');
            await db.execute('''
CREATE TABLE orders (
  id TEXT PRIMARY KEY, customer_id TEXT, order_date TEXT,
  total_amount REAL, status TEXT, created_at TEXT
)''');
            await db.execute('''
CREATE TABLE products (
  id TEXT PRIMARY KEY, code TEXT, name TEXT, unit TEXT,
  price REAL, stock_quantity REAL, category TEXT
)''');
            await db.execute('''
CREATE TABLE visits (
  id TEXT PRIMARY KEY, customer_id TEXT, visit_date TEXT,
  status TEXT, created_at TEXT
)''');
            await db.execute('''
CREATE TABLE collections (
  id TEXT PRIMARY KEY, customer_id TEXT, amount REAL,
  payment_type TEXT, collection_date TEXT, created_at TEXT
)''');
            await db.insert('customers', {
              'id': 'c1',
              'code': 'C001',
              'name': 'Lovan Market',
              'balance': 1500.5,
              'city': 'İstanbul',
              'is_active': 1,
              'phone': '05321234567',
            });
            await db.insert('orders', {
              'id': 'o1',
              'customer_id': 'c1',
              'order_date': '2026-07-28',
              'total_amount': 420.0,
              'status': 'open',
              'created_at': '2026-07-28T10:00:00',
            });
            await db.insert('products', {
              'id': 'p1',
              'code': 'P100',
              'name': 'Su 1L',
              'unit': 'AD',
              'price': 10,
              'stock_quantity': 55,
              'category': 'İçecek',
            });
          },
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('sqlite runner customers ilike', () async {
      final r = await AiChatSqliteRunner(db: db).run(
        const PostgrestQuerySpec(
          table: 'customers',
          select: ['code', 'name', 'balance'],
          filters: [
            PostgrestQueryFilter(
              column: 'name',
              op: PostgrestFilterOp.ilike,
              value: '%Lovan%',
            ),
          ],
          limit: 10,
        ),
      );
      expect(r.ok, isTrue);
      expect(r.rows, hasLength(1));
      expect(r.rows.first['code'], 'C001');
    });

    test('gather merkez yokken yerel satır döner', () async {
      final toolkit = AiChatDataToolkit(
        dbFactory: () async => db,
      );
      final bundle = await toolkit.gather('Lovan cari bakiyesi');
      expect(bundle.usedLocal, isTrue);
      expect(bundle.centerUnavailable, isTrue);
      expect(bundle.sourceNoteKey, 'ai.chat_local_only_note');
      final block = bundle.toPromptBlock();
      expect(block, contains('Lovan'));
      expect(block, contains('1500'));
      expect(block, isNot(contains('05321234567')));
    });

    test('boş DB → no invent prompt', () async {
      final empty = await databaseFactoryFfi.openDatabase(
        'file:ai_chat_empty_${DateTime.now().microsecondsSinceEpoch}?mode=memory&cache=private',
        options: OpenDatabaseOptions(
          singleInstance: false,
          version: 1,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE customers (id TEXT, code TEXT, name TEXT, '
              'balance REAL, city TEXT, is_active INTEGER)',
            );
            await db.execute(
              'CREATE TABLE orders (id TEXT, customer_id TEXT, order_date TEXT, '
              'total_amount REAL, status TEXT, created_at TEXT)',
            );
            await db.execute(
              'CREATE TABLE products (id TEXT, code TEXT, name TEXT, unit TEXT, '
              'price REAL, stock_quantity REAL, category TEXT)',
            );
            await db.execute(
              'CREATE TABLE visits (id TEXT, customer_id TEXT, visit_date TEXT, '
              'status TEXT, created_at TEXT)',
            );
            await db.execute(
              'CREATE TABLE collections (id TEXT, customer_id TEXT, amount REAL, '
              'payment_type TEXT, collection_date TEXT, created_at TEXT)',
            );
          },
        ),
      );
      final toolkit = AiChatDataToolkit(dbFactory: () async => empty);
      final bundle = await toolkit.gather('Stok durumu');
      expect(bundle.usedLocal, isFalse);
      expect(bundle.toPromptBlock(), contains('bulunamadı'));
      await empty.close();
    });
  });

  group('FlutterAiTtsEngine.sanitizeForSpeech', () {
    test('markdown temizler', () {
      final s = FlutterAiTtsEngine.sanitizeForSpeech(
        '**Merhaba** `kod` [link](http://x)',
      );
      expect(s, contains('Merhaba'));
      expect(s, isNot(contains('**')));
      expect(s, isNot(contains('http')));
    });
  });
}
