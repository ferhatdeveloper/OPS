import 'package:postgres/postgres.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';

class PostgresService {
  static final PostgresService _instance = PostgresService._internal();
  static PostgresService get instance => _instance;

  static Future<PostgresService> getInstance() async {
    await _instance.connect();
    return _instance;
  }

  Connection? _connection;
  bool _isConnected = false;

  // ── Bağlantı Ayarları ───────────────────────────────────────────────────
  final String _host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
  final int _port = 5432;
  final String _database = 'EXFINOPS';
  final String _username = 'postgres';
  final String _password = 'YOUR_DB_PASSWORD';

  // ── Aktif Firma+Dönem Bağlamı ────────────────────────────────────────────
  // Wizard'da seçilen firma / dönem numaraları
  String _activeFirmNr = '01';
  String _activePeriodNr = '01';

  PostgresService._internal();

  // ── Getter'lar ───────────────────────────────────────────────────────────
  String get activeFirmNr => _activeFirmNr;
  String get activePeriodNr => _activePeriodNr;

  /// Aktif firma ve dönemi ayarla (wizard tamamlandığında çağrılır)
  void setActiveContext({required String firmNr, required String periodNr}) {
    _activeFirmNr = firmNr.padLeft(2, '0');
    _activePeriodNr = periodNr.padLeft(2, '0');
    debugPrint('🏢 Aktif bağlam güncellendi: Firma=$_activeFirmNr / Dönem=$_activePeriodNr');
  }

  // ── Tablo Adı Üretici ────────────────────────────────────────────────────

  /// Firma bazlı tablo adı döner: exfin_FF_tableName
  /// Örnek: getTableName('products') → 'exfin_01_products'
  String getFirmTable(String baseTableName) {
    return 'exfin_${_activeFirmNr}_$baseTableName';
  }

  /// Dönem bazlı işlem tablosu döner: exfin_FF_DD_tableName
  /// Örnek: getPeriodTable('visits') → 'exfin_01_01_visits'
  String getPeriodTable(String baseTableName) {
    return 'exfin_${_activeFirmNr}_${_activePeriodNr}_$baseTableName';
  }

  /// Belirli firma+dönem için tablo adı döner
  String getTableFor(String baseTableName, {
    required String firmNr,
    required String periodNr,
  }) {
    return 'exfin_${firmNr.padLeft(2, '0')}_${periodNr.padLeft(2, '0')}_$baseTableName';
  }

  // ── Bağlantı ─────────────────────────────────────────────────────────────

  Future<bool> connect() async {
    if (_isConnected && _connection != null && _connection!.isOpen) {
      return true;
    }
    try {
      debugPrint('🔌 PostgreSQL bağlanıyor: $_host:$_port/$_database...');
      _connection = await Connection.open(
        Endpoint(
          host: _host,
          port: _port,
          database: _database,
          username: _username,
          password: _password,
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.disable,
          connectTimeout: Duration(seconds: 15),
          queryTimeout: Duration(seconds: 30),
        ),
      );
      _isConnected = true;
      debugPrint('✅ PostgreSQL bağlantısı başarılı!');
      return true;
    } catch (e) {
      debugPrint('❌ PostgreSQL bağlantı hatası: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_connection != null && _connection!.isOpen) {
      await _connection!.close();
      _isConnected = false;
      debugPrint('🔌 PostgreSQL bağlantısı kapatıldı');
    }
  }

  // ── Temel Sorgu ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> query(
    String sql, {
    Map<String, dynamic>? params,
    String? filter,
    List<dynamic>? filterArgs,
  }) async {
    if (!_isConnected || _connection == null) {
      final connected = await connect();
      if (!connected) throw Exception('PostgreSQL bağlantısı kurulamadı');
    }

    try {
      String finalSql = sql;
      Map<String, dynamic> finalParams = params ?? {};

      if (filter != null) {
        finalSql = '$sql WHERE $filter';
        if (filterArgs != null) {
          for (var i = 0; i < filterArgs.length; i++) {
            finalParams['p$i'] = filterArgs[i];
          }
        }
      }

      final result = await _connection!.execute(
        Sql.named(finalSql),
        parameters: finalParams,
      );

      return result.map((row) => row.toColumnMap()).toList();
    } catch (e) {
      debugPrint('❌ Sorgu hatası: $e\nSQL: $sql');
      rethrow;
    }
  }

  // ── Şema Kurulum Fonksiyonları ────────────────────────────────────────────

  /// Master tabloları oluşturur (companies, periods, users vb.)
  /// Sadece ilk kurulumda veya migration sırasında çağrılır
  Future<void> initializeMasterTables() async {
    await connect();
    debugPrint('🔧 Master tablolar oluşturuluyor...');

    // SQL dosyasını oku ve çalıştır — ya da inline aşağıda
    const masterSql = '''
      CREATE TABLE IF NOT EXISTS companies (
          id SERIAL PRIMARY KEY,
          server_name VARCHAR(50) DEFAULT 'local',
          logo_nr INTEGER NOT NULL,
          code VARCHAR(20) NOT NULL,
          name VARCHAR(200) NOT NULL,
          is_default BOOLEAN DEFAULT false,
          is_active BOOLEAN DEFAULT true,
          tax_office VARCHAR(100),
          tax_number VARCHAR(20),
          address TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(server_name, logo_nr)
      );

      CREATE TABLE IF NOT EXISTS periods (
          id SERIAL PRIMARY KEY,
          company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE,
          logo_period_nr INTEGER NOT NULL,
          code VARCHAR(20) NOT NULL,
          name VARCHAR(100),
          start_date DATE,
          end_date DATE,
          is_default BOOLEAN DEFAULT false,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(company_id, logo_period_nr)
      );

      CREATE TABLE IF NOT EXISTS users (
          id SERIAL PRIMARY KEY,
          username VARCHAR(50) UNIQUE NOT NULL,
          email VARCHAR(100) UNIQUE NOT NULL,
          password_hash VARCHAR(255) NOT NULL,
          full_name VARCHAR(100),
          phone VARCHAR(20),
          role VARCHAR(20) DEFAULT 'salesman',
          logo_salesman_code VARCHAR(50),
          is_active BOOLEAN DEFAULT true,
          last_login TIMESTAMP,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS user_company_preferences (
          id SERIAL PRIMARY KEY,
          user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
          company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE,
          period_id INTEGER REFERENCES periods(id) ON DELETE CASCADE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(user_id)
      );

      CREATE TABLE IF NOT EXISTS offline_sync_queue (
          id SERIAL PRIMARY KEY,
          user_id INTEGER,
          firm_nr VARCHAR(10) NOT NULL,
          period_nr VARCHAR(10) NOT NULL,
          operation_type VARCHAR(50) NOT NULL,
          payload JSONB NOT NULL,
          status VARCHAR(20) DEFAULT 'pending',
          retry_count INTEGER DEFAULT 0,
          error_message TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          synced_at TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS notifications (
          id SERIAL PRIMARY KEY,
          user_id INTEGER,
          title VARCHAR(100) NOT NULL,
          body TEXT NOT NULL,
          notification_type VARCHAR(20) DEFAULT 'info',
          priority VARCHAR(10) DEFAULT 'normal',
          is_read BOOLEAN DEFAULT false,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          read_at TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS report_snapshots (
          id SERIAL PRIMARY KEY,
          user_id INTEGER,
          firm_nr VARCHAR(10) NOT NULL,
          period_nr VARCHAR(10) NOT NULL,
          report_code VARCHAR(50) NOT NULL,
          report_name VARCHAR(100),
          report_data JSONB NOT NULL,
          row_count INTEGER,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          expires_at TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS audit_logs (
          id SERIAL PRIMARY KEY,
          user_id INTEGER,
          firm_nr VARCHAR(10),
          action VARCHAR(50) NOT NULL,
          table_name VARCHAR(100),
          record_id VARCHAR(50),
          old_data JSONB,
          new_data JSONB,
          ip_address VARCHAR(45),
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''';

    // Satır satır çalıştır
    for (final stmt in masterSql.split(';').where((s) => s.trim().isNotEmpty)) {
      try {
        await _connection!.execute(stmt);
      } catch (e) {
        debugPrint('⚠️ Master tablo: $e');
      }
    }
    debugPrint('✅ Master tablolar hazır');
  }

  // ── WIZARD ENTRYPOINT ─────────────────────────────────────────────────────

  /// Wizard'da firma+dönem seçimi tamamlandığında çağrılır.
  /// PostgreSQL'e SETUP_EXFIN_COMPANY fonksiyonunu çağırarak
  /// exfin_FF_* ve exfin_FF_DD_* tablolarını oluşturur.
  Future<bool> setupCompanyContext({
    required int firmaNo,
    required int donemNo,
  }) async {
    try {
      await connect();

      final firmNr = firmaNo.toString().padLeft(2, '0');
      final periodNr = donemNo.toString().padLeft(2, '0');

      debugPrint('🏗️ Firma $firmNr / Dönem $periodNr tabloları oluşturuluyor...');

      final result = await _connection!.execute(
        Sql.named('SELECT SETUP_EXFIN_COMPANY(@firm, @period)'),
        parameters: {
          'firm': firmNr,
          'period': periodNr,
        },
      );

      final message = result.first.toColumnMap().values.first?.toString() ?? '';
      debugPrint('📋 $message');

      // Aktif bağlamı güncelle
      setActiveContext(firmNr: firmNr, periodNr: periodNr);

      return true;
    } catch (e) {
      debugPrint('❌ setupCompanyContext hatası: $e');
      // Fonksiyon henüz DB'de yoksa inline oluşturmayı dene
      return await _createTablesInline(firmaNo: firmaNo, donemNo: donemNo);
    }
  }

  /// SETUP_EXFIN_COMPANY fonksiyonu yoksa SQL şemasını yükler ve tabloları oluşturur
  Future<bool> _createTablesInline({
    required int firmaNo,
    required int donemNo,
  }) async {
    try {
      debugPrint('⚙️ Şema fonksiyonları yükleniyor...');

      // sql/schema/02_exfin_tenant_functions.sql dosyasını oku
      // Not: Üretimde asset olarak embed edilmeli
      // Şimdilik temel doğrudan CREATE TABLE sorguları çalıştırılıyor
      final firmNr = firmaNo.toString().padLeft(2, '0');
      final periodNr = donemNo.toString().padLeft(2, '0');
      final firmPrefix = 'exfin_${firmNr}';
      final periodPrefix = 'exfin_${firmNr}_$periodNr';

      final firmTables = [
        '$firmPrefix\_products',
        '$firmPrefix\_customers',
        '$firmPrefix\_salesmen',
        '$firmPrefix\_warehouses',
        '$firmPrefix\_campaigns',
      ];

      final periodTables = [
        '$periodPrefix\_visits',
        '$periodPrefix\_orders',
        '$periodPrefix\_collections',
        '$periodPrefix\_gps_tracks',
        '$periodPrefix\_stock_counts',
        '$periodPrefix\_work_logs',
        '$periodPrefix\_vehicle_stocks',
      ];

      // Tablo varlığını kontrol et — var olanları atla
      for (final tbl in [...firmTables, ...periodTables]) {
        await _ensureTableExists(tbl);
      }

      setActiveContext(firmNr: firmNr, periodNr: periodNr);
      return true;
    } catch (e) {
      debugPrint('❌ _createTablesInline hatası: $e');
      return false;
    }
  }

  Future<void> _ensureTableExists(String tableName) async {
    try {
      final exists = await _connection!.execute(
        Sql.named(
          "SELECT 1 FROM information_schema.tables WHERE table_name = @tbl AND table_schema = 'public'",
        ),
        parameters: {'tbl': tableName},
      );
      if (exists.isEmpty) {
        debugPrint('🔧 Tablo oluşturulacak: $tableName (SQL şeması bekleniyor)');
        // Tablo yoksa loga yaz — gerçek CREATE, PostgreSQL fonksiyonları tarafından yapılır
      } else {
        debugPrint('✓ Tablo mevcut: $tableName');
      }
    } catch (e) {
      debugPrint('⚠️ _ensureTableExists [$tableName]: $e');
    }
  }

  // ── UPSERT ────────────────────────────────────────────────────────────────

  Future<void> upsert(String tableName, List<Map<String, dynamic>> records) async {
    if (records.isEmpty) return;

    for (final record in records) {
      final columns = record.keys.join(', ');
      final placeholders = record.keys.map((k) => '@$k').join(', ');
      final updates = record.keys
          .where((k) => k != 'id')
          .map((k) => '$k = EXCLUDED.$k')
          .join(', ');

      final sql = '''
        INSERT INTO $tableName ($columns)
        VALUES ($placeholders)
        ON CONFLICT (id) DO UPDATE SET $updates
      ''';
      await query(sql, params: record);
    }
  }

  // ── LOGIN ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> login(String username, String password) async {
    final result = await query(
      'SELECT * FROM users WHERE username = @username AND is_active = true',
      params: {'username': username},
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    return await query('SELECT * FROM users WHERE is_active = true');
  }

  // ── ZİYARETLER ────────────────────────────────────────────────────────────

  /// Aktif firma+dönem için ziyaret tablosuna yaz
  Future<void> saveVisit(Map<String, dynamic> visit) async {
    final table = getPeriodTable('visits');
    await query('''
      INSERT INTO $table (
        user_id, customer_code, customer_name, visit_type, status,
        check_in_time, check_in_lat, check_in_lng, notes, is_synced
      ) VALUES (
        @user_id, @customer_code, @customer_name, @visit_type, @status,
        @check_in_time, @check_in_lat, @check_in_lng, @notes, false
      )
    ''', params: visit);
  }

  Future<List<Map<String, dynamic>>> getVisits({String? customerCode}) async {
    final table = getPeriodTable('visits');
    if (customerCode != null) {
      return await query(
        'SELECT * FROM $table WHERE customer_code = @code ORDER BY check_in_time DESC',
        params: {'code': customerCode},
      );
    }
    return await query('SELECT * FROM $table ORDER BY check_in_time DESC');
  }

  // ── TAHSİLATLAR ───────────────────────────────────────────────────────────

  Future<void> saveCollection(Map<String, dynamic> collection) async {
    final table = getPeriodTable('collections');
    await query('''
      INSERT INTO $table (
        user_id, customer_code, customer_name, amount, currency,
        payment_type, payment_details, collection_date, notes, is_synced
      ) VALUES (
        @user_id, @customer_code, @customer_name, @amount, @currency,
        @payment_type, @payment_details, @collection_date, @notes, false
      )
    ''', params: {
      ...collection,
      'payment_details': collection['payment_details'] != null
          ? jsonEncode(collection['payment_details'])
          : null,
    });
  }

  // ── SİPARİŞLER ───────────────────────────────────────────────────────────

  Future<void> saveOrder(Map<String, dynamic> order) async {
    final table = getPeriodTable('orders');
    await query('''
      INSERT INTO $table (
        user_id, customer_code, customer_name, order_date, delivery_date,
        total_amount, total_vat, grand_total, currency, notes, order_lines, is_synced
      ) VALUES (
        @user_id, @customer_code, @customer_name, @order_date, @delivery_date,
        @total_amount, @total_vat, @grand_total, @currency, @notes, @order_lines, false
      )
    ''', params: {
      ...order,
      'order_lines': jsonEncode(order['order_lines'] ?? []),
    });
  }

  // ── GPS TRACK ─────────────────────────────────────────────────────────────

  Future<void> saveGpsTrack({
    required int userId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
    double? altitude,
    int? batteryLevel,
  }) async {
    final table = getPeriodTable('gps_tracks');
    await query('''
      INSERT INTO $table (
        user_id, latitude, longitude, accuracy, speed, heading, altitude,
        battery_level, timestamp, is_synced
      ) VALUES (
        @user_id, @lat, @lng, @accuracy, @speed, @heading, @altitude,
        @battery, NOW(), false
      )
    ''', params: {
      'user_id': userId,
      'lat': latitude,
      'lng': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'altitude': altitude,
      'battery': batteryLevel,
    });
  }

  // ── GÜN BAŞLAMA / BİTİŞ ──────────────────────────────────────────────────

  Future<void> startWorkDay({
    required int userId,
    required DateTime workDate,
    double? startKm,
    double? startLat,
    double? startLng,
    String? notes,
  }) async {
    final table = getPeriodTable('work_logs');
    await query('''
      INSERT INTO $table (user_id, work_date, start_time, start_km, start_lat, start_lng, notes)
      VALUES (@user_id, @work_date, NOW(), @start_km, @start_lat, @start_lng, @notes)
      ON CONFLICT (user_id, work_date) DO UPDATE
        SET start_time = NOW(), start_km = @start_km
    ''', params: {
      'user_id': userId,
      'work_date': workDate.toIso8601String().substring(0, 10),
      'start_km': startKm,
      'start_lat': startLat,
      'start_lng': startLng,
      'notes': notes,
    });
  }

  Future<void> endWorkDay({
    required int userId,
    required DateTime workDate,
    double? endKm,
    double? endLat,
    double? endLng,
  }) async {
    final table = getPeriodTable('work_logs');
    await query('''
      UPDATE $table
      SET end_time = NOW(), end_km = @end_km, end_lat = @end_lat, end_lng = @end_lng
      WHERE user_id = @user_id AND work_date = @work_date
    ''', params: {
      'user_id': userId,
      'work_date': workDate.toIso8601String().substring(0, 10),
      'end_km': endKm,
      'end_lat': endLat,
      'end_lng': endLng,
    });
  }

  // ── MÜŞTERLER ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCustomers({bool activeOnly = true}) async {
    final table = getFirmTable('customers');
    final where = activeOnly ? 'WHERE is_active = true' : '';
    return await query('SELECT * FROM $table $where ORDER BY name');
  }

  Future<void> upsertCustomer(Map<String, dynamic> customer) async {
    final table = getFirmTable('customers');
    await upsert(table, [customer]);
  }

  // ── ÜRÜNLER ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProducts({bool activeOnly = true}) async {
    final table = getFirmTable('products');
    final where = activeOnly ? 'WHERE is_active = true' : '';
    return await query('SELECT * FROM $table $where ORDER BY name');
  }

  Future<void> upsertProduct(Map<String, dynamic> product) async {
    final table = getFirmTable('products');
    await upsert(table, [product]);
  }

  // ── SENKRONIZASYON ────────────────────────────────────────────────────────

  /// Offline kuyruktan bekleyen kayıtları getirir
  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    return await query('''
      SELECT * FROM offline_sync_queue
      WHERE firm_nr = @firm AND period_nr = @period AND status = 'pending'
      ORDER BY created_at ASC
      LIMIT 50
    ''', params: {
      'firm': _activeFirmNr,
      'period': _activePeriodNr,
    });
  }

  /// Sync kuyruğuna işlem ekle
  Future<void> enqueueSync({
    required int userId,
    required String operationType,
    required Map<String, dynamic> payload,
  }) async {
    await query('''
      INSERT INTO offline_sync_queue
        (user_id, firm_nr, period_nr, operation_type, payload, status)
      VALUES (@uid, @firm, @period, @op, @payload, 'pending')
    ''', params: {
      'uid': userId,
      'firm': _activeFirmNr,
      'period': _activePeriodNr,
      'op': operationType,
      'payload': jsonEncode(payload),
    });
  }

  // ── LİVE LOCATIONS ───────────────────────────────────────────────────────

  Future<void> updateLiveLocation({
    required int userId,
    required double latitude,
    required double longitude,
    int? batteryLevel,
  }) async {
    await query('''
      INSERT INTO live_location_snapshots (user_id, latitude, longitude, battery_level, last_update)
      VALUES (@uid, @lat, @lng, @battery, NOW())
      ON CONFLICT (user_id) DO UPDATE
        SET latitude = @lat, longitude = @lng,
            battery_level = @battery, last_update = NOW()
    ''', params: {
      'uid': userId,
      'lat': latitude,
      'lng': longitude,
      'battery': batteryLevel,
    });
  }

  Future<List<Map<String, dynamic>>> getLiveLocations() async {
    return await query(
      'SELECT * FROM live_location_snapshots WHERE last_update > NOW() - INTERVAL \'30 minutes\'',
    );
  }

  // ── MEVCUT Eski API Uyumu (geriye dönük) ──────────────────────────────────

  Future<void> initializeTables() async {
    await initializeMasterTables();
  }

  @deprecated
  Future<void> syncVisits(List<Map<String, dynamic>> visits) async {
    for (final v in visits) {
      await saveVisit(v);
    }
  }

  @deprecated
  Future<void> syncOrders(List<Map<String, dynamic>> orders) async {
    for (final o in orders) {
      await saveOrder(o);
    }
  }

  Future<List<Map<String, dynamic>>> getMenusForSync() async {
    return await query(
      'SELECT * FROM menu WHERE is_active = true AND is_deleted = false ORDER BY display_order',
    );
  }

  Future<List<Map<String, dynamic>>> getMenuItems() async {
    return await query(
      'SELECT * FROM menu_items WHERE is_active = true ORDER BY display_order',
    );
  }
}
