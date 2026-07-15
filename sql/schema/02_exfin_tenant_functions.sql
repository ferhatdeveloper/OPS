-- =====================================================
-- EXFIN OPS - Firma & Dönem Bazlı Tablo Fonksiyonları
-- =====================================================
-- Kullanım: Wizard'da firma+dönem seçildiğinde çağrılır
-- 
-- Tablo isimlendirme: exfin_FF_tablename (firma kartları)
--                    exfin_FF_DD_tablename (dönem işlemleri)
--
-- Örnek:
--   SELECT CREATE_EXFIN_FIRM_TABLES('01');
--   SELECT CREATE_EXFIN_PERIOD_TABLES('01', '01');
-- =====================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- MASTER (SABİT) TABLOLAR
-- Firma/dönem bağımsız — uygulama genelinde tek
-- =====================================================

CREATE TABLE IF NOT EXISTS companies (
    id SERIAL PRIMARY KEY,
    server_name VARCHAR(50) DEFAULT 'local',
    logo_nr INTEGER NOT NULL,         -- Logo firma numarası (FF)
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
    logo_period_nr INTEGER NOT NULL,  -- Logo dönem numarası (DD)
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

-- Sistem geneli ayarlar
CREATE TABLE IF NOT EXISTS system_settings (
    id SERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_type VARCHAR(20) DEFAULT 'string',
    description TEXT,
    updated_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bildirimler
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    body TEXT NOT NULL,
    notification_type VARCHAR(20) DEFAULT 'info',
    priority VARCHAR(10) DEFAULT 'normal',
    is_read BOOLEAN DEFAULT false,
    action_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP
);

-- Offline sync kuyruğu (tüm firmalar için tek tablo, firm_nr kolonuyla ayrılır)
CREATE TABLE IF NOT EXISTS offline_sync_queue (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    firm_nr VARCHAR(10) NOT NULL,
    period_nr VARCHAR(10) NOT NULL,
    operation_type VARCHAR(50) NOT NULL,  -- 'visit', 'order', 'collection', 'gps'
    payload JSONB NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    retry_count INTEGER DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_sync_queue_firm ON offline_sync_queue(firm_nr, period_nr, status);

-- Rapor snapshot (tüm firmalar için)
CREATE TABLE IF NOT EXISTS report_snapshots (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    firm_nr VARCHAR(10) NOT NULL,
    period_nr VARCHAR(10) NOT NULL,
    report_code VARCHAR(50) NOT NULL,
    report_name VARCHAR(100),
    report_data JSONB NOT NULL,
    row_count INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Audit log
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    firm_nr VARCHAR(10),
    action VARCHAR(50) NOT NULL,
    table_name VARCHAR(100),
    record_id VARCHAR(50),
    old_data JSONB,
    new_data JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- FONKSİYON 1: CREATE_EXFIN_FIRM_TABLES
-- Firma bazlı kartlar — müşteri, ürün, satış temsilcisi
-- Tablo adı: exfin_FF_products, exfin_FF_customers, exfin_FF_salesmen
-- =====================================================
CREATE OR REPLACE FUNCTION CREATE_EXFIN_FIRM_TABLES(p_firm_nr VARCHAR)
RETURNS void AS $$
DECLARE
    v_prefix TEXT;
BEGIN
    v_prefix := 'exfin_' || LPAD(p_firm_nr, 2, '0');

    RAISE NOTICE 'CREATE_EXFIN_FIRM_TABLES: Firma % için tablolar oluşturuluyor (prefix: %)...', p_firm_nr, v_prefix;

    -- ── Ürünler (Malzeme Kartı) ──────────────────────────────────────────
    EXECUTE format($q$
        CREATE TABLE IF NOT EXISTS %I (
            id          SERIAL PRIMARY KEY,
            ref_id      INTEGER UNIQUE,           -- Logo LOGICALREF (ITEMS)
            code        VARCHAR(50) UNIQUE,
            barcode     VARCHAR(50),
            name        VARCHAR(200) NOT NULL,
            unit        VARCHAR(20) DEFAULT 'ADET',
            vat_rate    DECIMAL(5,2) DEFAULT 18,
            price       DECIMAL(15,4) DEFAULT 0,
            cost        DECIMAL(15,4) DEFAULT 0,
            stock       DECIMAL(15,3) DEFAULT 0,
            category    VARCHAR(100),
            group_code  VARCHAR(50),
            special_code_1 VARCHAR(50),
            special_code_2 VARCHAR(50),
            image_url   TEXT,
            is_active   BOOLEAN DEFAULT true,
            last_sync   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    $q$, v_prefix || '_products');

    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (ref_id)',
        'idx_' || v_prefix || '_products_ref', v_prefix || '_products');
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (code)',
        'idx_' || v_prefix || '_products_code', v_prefix || '_products');
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (barcode)',
        'idx_' || v_prefix || '_products_barcode', v_prefix || '_products');

    -- ── Müşteriler (Cari Kart) ───────────────────────────────────────────
    EXECUTE format($q$
        CREATE TABLE IF NOT EXISTS %I (
            id          SERIAL PRIMARY KEY,
            ref_id      INTEGER UNIQUE,           -- Logo LOGICALREF (CLCARD)
            code        VARCHAR(50) UNIQUE NOT NULL,
            name        VARCHAR(200) NOT NULL,
            tax_office  VARCHAR(100),
            tax_number  VARCHAR(20),
            address     TEXT,
            city        VARCHAR(100),
            district    VARCHAR(100),
            phone       VARCHAR(50),
            email       VARCHAR(100),
            latitude    DECIMAL(10,8),
            longitude   DECIMAL(11,8),
            balance     DECIMAL(15,2) DEFAULT 0,
            credit_limit DECIMAL(15,2) DEFAULT 0,
            special_code VARCHAR(50),
            group_code  VARCHAR(50),
            nfc_tag_id  VARCHAR(100),
            is_active   BOOLEAN DEFAULT true,
            last_sync   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    $q$, v_prefix || '_customers');

    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (ref_id)',
        'idx_' || v_prefix || '_customers_ref', v_prefix || '_customers');
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (code)',
        'idx_' || v_prefix || '_customers_code', v_prefix || '_customers');

    -- ── Satış Temsilcileri ───────────────────────────────────────────────
    EXECUTE format($q$
        CREATE TABLE IF NOT EXISTS %I (
            id          SERIAL PRIMARY KEY,
            ref_id      INTEGER UNIQUE,           -- Logo LOGICALREF (SLSCLNS)
            code        VARCHAR(50) UNIQUE,
            name        VARCHAR(100),
            email       VARCHAR(100),
            phone       VARCHAR(20),
            is_active   BOOLEAN DEFAULT true,
            created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    $q$, v_prefix || '_salesmen');

    -- ── Depolar ──────────────────────────────────────────────────────────
    EXECUTE format($q$
        CREATE TABLE IF NOT EXISTS %I (
            id          SERIAL PRIMARY KEY,
            ref_id      INTEGER UNIQUE,           -- Logo LOGICALREF (CAPPARA)
            code        VARCHAR(50) UNIQUE NOT NULL,
            name        VARCHAR(100),
            is_active   BOOLEAN DEFAULT true,
            created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    $q$, v_prefix || '_warehouses');

    -- ── Kampanyalar ──────────────────────────────────────────────────────
    EXECUTE format($q$
        CREATE TABLE IF NOT EXISTS %I (
            id              SERIAL PRIMARY KEY,
            ref_id          INTEGER,
            code            VARCHAR(50),
            name            VARCHAR(200),
            campaign_type   VARCHAR(50) NOT NULL,   -- 'discount', 'gift', 'buy_x_get_y'
            discount_value  DECIMAL(15,2),
            start_date      DATE,
            end_date        DATE,
            priority        INTEGER DEFAULT 0,
            conditions      JSONB,
            is_active       BOOLEAN DEFAULT true,
            created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(code)
        );
    $q$, v_prefix || '_campaigns');

    RAISE NOTICE 'CREATE_EXFIN_FIRM_TABLES: Firma % için tablolar başarıyla oluşturuldu.', p_firm_nr;
END;
$$ LANGUAGE plpgsql;


-- =====================================================
-- FONKSİYON 2: CREATE_EXFIN_PERIOD_TABLES
-- Dönem bazlı işlem tabloları
-- Tablo adı: exfin_FF_DD_visits, exfin_FF_DD_orders vb.
-- =====================================================
CREATE OR REPLACE FUNCTION CREATE_EXFIN_PERIOD_TABLES(p_firm_nr VARCHAR, p_period_nr VARCHAR)
RETURNS void AS $$
DECLARE
    v_prefix     TEXT;
    v_firm_pfx   TEXT;
BEGIN
    v_firm_pfx := 'exfin_' || LPAD(p_firm_nr, 2, '0');
    v_prefix   := v_firm_pfx || '_' || LPAD(p_period_nr, 2, '0');

    RAISE NOTICE 'CREATE_EXFIN_PERIOD_TABLES: Firma % Dönem % için işlem tabloları oluşturuluyor (prefix: %)...',
        p_firm_nr, p_period_nr, v_prefix;

    -- ── Müşteri Ziyaretleri ──────────────────────────────────────────────
    EXECUTE format($q$
        CREATE TABLE IF NOT EXISTS %I (
            id              SERIAL PRIMARY KEY,
            user_id         INTEGER REFERENCES users(id),
            customer_ref    INTEGER,                   -- exfin_FF_customers.ref_id
            customer_code   VARCHAR(50) NOT NULL,
            customer_name   VARCHAR(200),
            visit_type      VARCHAR(20) DEFAULT 'routine',  -- routine, order, collection
            status          VARCHAR(20) DEFAULT 'planned',  -- planned, checked_in, completed
            planned_date    TIMESTAMP,
            check_in_time   TIMESTAMP,
            check_out_time  TIMESTAMP,
            check_in_lat    DECIMAL(10,8),
            check_in_lng    DECIMAL(11,8),
            check_out_lat   DECIMAL(10,8),
            check_out_lng   DECIMAL(11,8),
            notes           TEXT,
            photos          JSONB,
            is_synced       BOOLEAN DEFAULT false,
            synced_at       TIMESTAMP,
            created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    $q$, v_prefix || '_visits');

    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (user_id, check_in_time DESC)',
        'idx_' || v_prefix || '_visits_user', v_prefix || '_visits');
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (customer_code)',
        'idx_' || v_prefix || '_visits_cust', v_prefix || '_visits');

    -- ── Offline Siparişler ───────────────────────────────────────────────
    EXECUTE format($q$
        CREATE TABLE IF NOT EXISTS %I (
            id              SERIAL PRIMARY KEY,
            user_id         INTEGER REFERENCES users(id),
            customer_code   VARCHAR(50) NOT NULL,
            customer_name   VARCHAR(200),
            order_date      TIMESTAMP NOT NULL,
            delivery_date   TIMESTAMP,
            total_amount    DECIMAL(15,2) DEFAULT 0,
            total_vat       DECIMAL(15,2) DEFAULT 0,
            grand_total     DECIMAL(15,2) DEFAULT 0,
            currency        VARCHAR(3) DEFAULT 'TRY',
            notes           TEXT,
            order_lines     JSONB NOT NULL,            -- Fatura satırları
            is_synced       BOOLEAN DEFAULT false,
            logo_ref        INTEGER,                   -- Logo'dan dönen LOGICALREF
            synced_at       TIMESTAMP,
            created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    $q$, v_prefix || '_orders');

    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (user_id, is_synced)',
        'idx_' || v_prefix || '_orders_sync', v_prefix || '_orders');

    -- ── Offline Tahsilatlar ──────────────────────────────────────────────
    EXECUTE format($q$
        CREATE TABLE IF NOT EXISTS %I (
            id              SERIAL PRIMARY KEY,
            user_id         INTEGER REFERENCES users(id),
            customer_code   VARCHAR(50) NOT NULL,
            customer_name   VARCHAR(200),
            amount          DECIMAL(15,2) NOT NULL,
            currency        VARCHAR(3) DEFAULT 'TRY',
            payment_type    VARCHAR(20) NOT NULL,   -- cash, credit_card, bank_transfer, check
            payment_details JSONB,                   -- Çek/kart detayları
            collection_date TIMESTAMP NOT NULL,
            notes           TEXT,
            receipt_photo   TEXT,
            is_synced       BOOLEAN DEFAULT false,
            logo_ref        INTEGER,
            synced_at       TIMESTAMP,
            created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    $q$, v_prefix || '_collections');

    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (user_id, is_synced)',
        'idx_' || v_prefix || '_collections_sync', v_prefix || '_collections');

    -- ── GPS Takip ────────────────────────────────────────────────────────
    EXECUTE format($q$
        CREATE TABLE IF NOT EXISTS %I (
            id          SERIAL PRIMARY KEY,
            user_id     INTEGER REFERENCES users(id),
            latitude    DECIMAL(10,8) NOT NULL,
            longitude   DECIMAL(11,8) NOT NULL,
            accuracy    DECIMAL(5,2),
            speed       DECIMAL(5,2),
            heading     DECIMAL(5,2),
            altitude    DECIMAL(7,2),
            battery_level INTEGER,
            timestamp   TIMESTAMP NOT NULL,
            is_synced   BOOLEAN DEFAULT false,
            created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    $q$, v_prefix || '_gps_tracks');

    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (user_id, timestamp DESC)',
        'idx_' || v_prefix || '_gps_user', v_prefix || '_gps_tracks');

    -- ── Stok Sayım ───────────────────────────────────────────────────────
    EXECUTE format($q$
        CREATE TABLE IF NOT EXISTS %I (
            id              SERIAL PRIMARY KEY,
            user_id         INTEGER REFERENCES users(id),
            warehouse_code  VARCHAR(50),
            count_date      TIMESTAMP NOT NULL,
            count_lines     JSONB NOT NULL,
            notes           TEXT,
            is_synced       BOOLEAN DEFAULT false,
            logo_ref        INTEGER,
            synced_at       TIMESTAMP,
            created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    $q$, v_prefix || '_stock_counts');

    -- ── Gün Başlama/Bitiş Kayıtları ──────────────────────────────────────
    EXECUTE format($q$
        CREATE TABLE IF NOT EXISTS %I (
            id              SERIAL PRIMARY KEY,
            user_id         INTEGER REFERENCES users(id),
            work_date       DATE NOT NULL,
            start_time      TIMESTAMP,
            end_time        TIMESTAMP,
            start_km        DECIMAL(10,2),
            end_km          DECIMAL(10,2),
            start_lat       DECIMAL(10,8),
            start_lng       DECIMAL(11,8),
            end_lat         DECIMAL(10,8),
            end_lng         DECIMAL(11,8),
            notes           TEXT,
            is_synced       BOOLEAN DEFAULT false,
            created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(user_id, work_date)
        );
    $q$, v_prefix || '_work_logs');

    -- ── Araç Stok Yükleme ────────────────────────────────────────────────
    EXECUTE format($q$
        CREATE TABLE IF NOT EXISTS %I (
            id              SERIAL PRIMARY KEY,
            user_id         INTEGER REFERENCES users(id),
            vehicle_plate   VARCHAR(20),
            load_date       DATE NOT NULL,
            product_ref     INTEGER,
            product_code    VARCHAR(50),
            product_name    VARCHAR(200),
            loaded_qty      DECIMAL(15,3) DEFAULT 0,
            sold_qty        DECIMAL(15,3) DEFAULT 0,
            returned_qty    DECIMAL(15,3) DEFAULT 0,
            remaining_qty   DECIMAL(15,3) DEFAULT 0,
            is_synced       BOOLEAN DEFAULT false,
            created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    $q$, v_prefix || '_vehicle_stocks');

    RAISE NOTICE 'CREATE_EXFIN_PERIOD_TABLES: Firma % Dönem % için tablolar başarıyla oluşturuldu.', p_firm_nr, p_period_nr;
END;
$$ LANGUAGE plpgsql;


-- =====================================================
-- FONKSİYON 3: SETUP_EXFIN_COMPANY
-- Wizard'da çağrılır — firma+dönem tabloları tek seferde oluşturur
-- =====================================================
CREATE OR REPLACE FUNCTION SETUP_EXFIN_COMPANY(p_firm_nr VARCHAR, p_period_nr VARCHAR)
RETURNS TEXT AS $$
BEGIN
    PERFORM CREATE_EXFIN_FIRM_TABLES(p_firm_nr);
    PERFORM CREATE_EXFIN_PERIOD_TABLES(p_firm_nr, p_period_nr);

    RETURN format('✅ Firma %s / Dönem %s için tüm tablolar oluşturuldu.
  Kart tabloları  : exfin_%s_products, exfin_%s_customers, exfin_%s_salesmen
  İşlem tabloları : exfin_%s_%s_visits, _orders, _collections, _gps_tracks, _work_logs, _vehicle_stocks',
        LPAD(p_firm_nr, 2, '0'), LPAD(p_period_nr, 2, '0'),
        LPAD(p_firm_nr, 2, '0'), LPAD(p_firm_nr, 2, '0'), LPAD(p_firm_nr, 2, '0'),
        LPAD(p_firm_nr, 2, '0'), LPAD(p_period_nr, 2, '0'));
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Kurulum tamamlandı
-- Test için: SELECT SETUP_EXFIN_COMPANY('1', '1');
-- =====================================================
