import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';

/// {@template PostgreService}
/// Yerel PostgreSQL veritabanı işlemlerini yöneten servis sınıfı.
/// SupabaseService ile benzer bir arayüz sunarak geçişi kolaylaştırır.
/// {@endtemplate}
class PostgreService {
  static PostgreService? _instance;
  Pool? _pool;

  PostgreService._internal();

  // Dummy methods for legacy Supabase logic
  Future<String> getSuperPass() async => '1';
  Future<void> updateUserPassword(String id, String pass) async {}
  dynamic get client => null;

  /// Servis örneğini döndürür
  static Future<PostgreService> getInstance() async {
    _instance ??= PostgreService._internal();
    await _instance!._initializePool();
    return _instance!;
  }

  /// PostgreSQL bağlantı havuzunu başlatır
  Future<void> _initializePool() async {
    if (_pool != null && _pool!.isOpen) return;

    // Sadece Masaüstü (Windows/Linux/macOS) veya Web üzerinde PostgreSQL bağlantısı kur
    final isDesktop = !kIsWeb && 
        (defaultTargetPlatform == TargetPlatform.windows || 
         defaultTargetPlatform == TargetPlatform.linux || 
         defaultTargetPlatform == TargetPlatform.macOS);

    if (!isDesktop && !kIsWeb) {
      if (kDebugMode) {
        print('ℹ️ PostgreService: Mobil platformda PostgreSQL bağlantısı atlanıyor.');
      }
      return;
    }

    try {
      _pool = Pool.withEndpoints(
        [
          Endpoint(
            host: 'localhost',
            database: 'postgres',
            username: 'postgres',
            password: 'YOUR_DB_PASSWORD',
            port: 5432,
          ),
        ],
        settings: const PoolSettings(
          sslMode: SslMode.disable,
          maxConnectionCount: 5,
        ),
      );
      
      if (kDebugMode) {
        print('✅ Yerel PostgreSQL bağlantı havuzu başarıyla kuruldu.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ PostgreSQL bağlantı havuzu hatası: $e');
      }
      // Mobil cihazda hata fırlatma, sadece logla (bağlantı kurulamayabilir)
      if (isDesktop || kIsWeb) {
        rethrow;
      }
    }
  }

  /// Havuzu döndürür
  Pool get pool => _pool!;

  /// Veri sorgular (SELECT)
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? filter,
    List<Object?>? filterArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (_pool == null) return [];

    String sql = 'SELECT * FROM "$table"';
    
    if (filter != null) {
      sql += ' WHERE $filter';
    }
    
    if (orderBy != null) {
      sql += ' ORDER BY $orderBy';
    }
    
    if (limit != null) {
      sql += ' LIMIT $limit';
    }
    
    if (offset != null) {
      sql += ' OFFSET $offset';
    }

    try {
      final result = await _pool!.execute(
        Sql.named(sql),
        parameters: filterArgs != null ? _mapToNamed(filterArgs) : null,
      );
      
      return result.map((row) => row.toColumnMap()).toList();
    } catch (e) {
      if (kDebugMode) print('❌ Sorgu hatası ($table): $e');
      rethrow;
    }
  }

  /// Veri ekler (INSERT)
  Future<Map<String, dynamic>> insert(String table, Map<String, dynamic> data) async {
    final columns = data.keys.map((c) => '"$c"').join(', ');
    final placeholders = data.keys.map((c) => '@$c').join(', ');
    final sql = 'INSERT INTO "$table" ($columns) VALUES ($placeholders) RETURNING *';

    try {
      final result = await _pool!.execute(
        Sql.named(sql),
        parameters: data,
      );
      return result.first.toColumnMap();
    } catch (e) {
      if (kDebugMode) print('❌ Kayıt hatası ($table): $e');
      rethrow;
    }
  }

  /// Veri günceller (UPDATE)
  Future<Map<String, dynamic>> update(
    String table,
    Map<String, dynamic> data,
    String id,
  ) async {
    final setClause = data.keys.map((c) => '"$c" = @$c').join(', ');
    final sql = 'UPDATE "$table" SET $setClause WHERE id = @update_id RETURNING *';

    try {
      final parameters = Map<String, dynamic>.from(data);
      parameters['update_id'] = id;
      
      final result = await _pool!.execute(
        Sql.named(sql),
        parameters: parameters,
      );
      return result.first.toColumnMap();
    } catch (e) {
      if (kDebugMode) print('❌ Güncelleme hatası ($table): $e');
      rethrow;
    }
  }

  /// Veri siler (DELETE)
  Future<void> delete(String table, String id) async {
    final sql = 'DELETE FROM "$table" WHERE id = @id';

    try {
      await _pool!.execute(
        Sql.named(sql),
        parameters: {'id': id},
      );
    } catch (e) {
      if (kDebugMode) print('❌ Silme hatası ($table): $e');
      rethrow;
    }
  }

  /// Toplu Ekle/Güncelle (UPSERT)
  Future<void> upsert(String table, List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return;
    
    // Optimised Batch Upsert (ON CONFLICT)
    final firstRecord = data.first;
    final columns = firstRecord.keys.map((c) => '"$c"').join(', ');
    final updateClause = firstRecord.keys
        .where((c) => c != 'id')
        .map((c) => '"$c" = EXCLUDED."$c"')
        .join(', ');

    // Multi-row INSERT
    try {
      await _pool!.withConnection((conn) async {
        await conn.runTx((session) async {
          for (final record in data) {
            final placeholders = record.keys.map((c) => '@$c').join(', ');
            final sql = '''
              INSERT INTO "$table" ($columns) 
              VALUES ($placeholders) 
              ON CONFLICT (id) DO UPDATE SET $updateClause
            ''';
            await session.execute(Sql.named(sql), parameters: record);
          }
        });
      });
    } catch (e) {
      if (kDebugMode) print('❌ Batch Upsert hatası ($table): $e');
      rethrow;
    }
  }

  /// SQL sorgusu çalıştırır
  Future<Result> execute(String sql, {Map<String, dynamic>? parameters}) async {
    return await _pool!.execute(Sql.named(sql), parameters: parameters);
  }

  /// Helper: Liste argümanlarını isimlendirilmiş parametrelere çevirir (Basit filtreler için)
  Map<String, dynamic> _mapToNamed(List<Object?> args) {
    // Bu kısım daha karmaşık filtre yapıları için geliştirilebilir.
    // Şu an için sadece ilk parametreyi p0 olarak kabul edelim (Supabase query wrapper'ına benzer).
    final Map<String, dynamic> map = {};
    for (int i = 0; i < args.length; i++) {
        map['p$i'] = args[i];
    }
    return map;
  }

  /// Bağlantıyı kapatır
  Future<void> dispose() async {
    await _pool?.close();
    _pool = null;
  }
}
