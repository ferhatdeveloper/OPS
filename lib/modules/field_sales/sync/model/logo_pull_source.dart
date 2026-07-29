// Dosya Adı: logo_pull_source.dart
// Açıklama: Logo'dan indirilebilen veri türleri ve bağlantı yetenek kataloğu
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

/// {@template logo_pull_source}
/// Güncelleme ekranında ayrı ayrı indirilebilen Logo veri türü.
///
/// İlk dokuz değer MBT "Veri Güncelleme → alınacak" satırlarının birebir
/// karşılığıdır. Kalan değerler ExfinApi middleware listesi ve tek başına
/// çekilebilen Tiger alt kaynakları için korunur (kalıcılık anahtarları
/// değişmediği için eski indirme geçmişi kaybolmaz).
/// {@endtemplate}
enum LogoPullSource {
  /// MBT 1 — STOK BİLGİLERİ; Tiger `items` → `products`
  products,

  /// MBT 2 — CARİ BİLGİLERİ; Tiger `Arps` → `customers`
  customers,

  /// MBT 3 — KASA BİLGİLERİ; Tiger `safeDeposits` → `cash_cards`
  cash,

  /// MBT 4 — BANKA BİLGİLERİ; Tiger `banks` → `bank_cards`
  banks,

  /// MBT 5 — DÖVİZ BİLGİLERİ; yerel kur tablosu yoksa "yakında" döner
  currency,

  /// MBT 6 — GENEL BİLGİLER; ambar + plasiyer + birim set (composite)
  general,

  /// MBT 7 — VARYANT BİLGİLERİ; şema yok → yakında
  variants,

  /// MBT 8 — ROTA BİLGİLERİ; merkez (PostgREST) kaynaklı → yakında
  routes,

  /// MBT 9 — DUYURULAR; merkez (PostgREST) kaynaklı → yakında
  announcements,

  /// Stok miktarı — ExfinApi envanter raporu
  stock,

  /// Cari bakiye — ExfinApi bakiye uç noktası
  balances,

  /// Depo / lokasyon — Tiger `locationCodes` (GENEL bileşeni)
  warehouses,

  /// Plasiyer kartları — Tiger `salesmen` (GENEL bileşeni)
  salesmen,

  /// Satış siparişleri — Tiger `salesOrders`; MBT alınacak listesinde yok
  orders,
}

/// {@template logo_pull_source_catalog}
/// [LogoPullSource] için l10n anahtarı, kalıcılık anahtarı ve bağlantı
/// yeteneği eşlemesi.
///
/// Kullanım örneği:
/// ```dart
/// final sources = LogoPullSourceCatalog.forMode(tigerEnabled: true);
/// ```
/// {@endtemplate}
class LogoPullSourceCatalog {
  LogoPullSourceCatalog._();

  /// [unsupportedKey]: Seçili bağlantıda desteklenmeyen kaynak l10n anahtarı
  static const String unsupportedKey = 'field_sales.logo_pull_unsupported';

  /// [comingSoonKey]: Henüz kaynağa bağlanmamış satırın l10n anahtarı
  static const String comingSoonKey = 'field_sales.logo_pull_coming_soon';

  /// [centerSourceKey]: Merkez (PostgREST) kaynaklı satırın l10n anahtarı
  static const String centerSourceKey = 'field_sales.logo_pull_center_source';

  /// [_titleKeys]: Kaynak → satır başlığı l10n anahtarı (MBT dili)
  static const Map<LogoPullSource, String> _titleKeys = {
    LogoPullSource.products: 'field_sales.logo_pull_mbt_stock',
    LogoPullSource.customers: 'field_sales.logo_pull_mbt_customers',
    LogoPullSource.cash: 'field_sales.logo_pull_mbt_cash',
    LogoPullSource.banks: 'field_sales.logo_pull_mbt_banks',
    LogoPullSource.currency: 'field_sales.logo_pull_mbt_currency',
    LogoPullSource.general: 'field_sales.logo_pull_mbt_general',
    LogoPullSource.variants: 'field_sales.logo_pull_mbt_variants',
    LogoPullSource.routes: 'field_sales.logo_pull_mbt_routes',
    LogoPullSource.announcements: 'field_sales.logo_pull_mbt_announcements',
    LogoPullSource.stock: 'field_sales.stock',
    LogoPullSource.balances: 'field_sales.balance',
    LogoPullSource.warehouses: 'field_sales.logo_pull_warehouses',
    LogoPullSource.salesmen: 'field_sales.logo_pull_salesmen',
    LogoPullSource.orders: 'field_sales.logo_pull_orders',
  };

  /// [_exfinTitleKeys]: ExfinApi listesinde korunan eski satır başlıkları
  static const Map<LogoPullSource, String> _exfinTitleKeys = {
    LogoPullSource.products: 'field_sales.product_list',
    LogoPullSource.customers: 'field_sales.customer_list',
  };

  /// [_storageKeys]: Kaynak → prefs / satır anahtarı
  static const Map<LogoPullSource, String> _storageKeys = {
    LogoPullSource.products: 'products',
    LogoPullSource.customers: 'customers',
    LogoPullSource.cash: 'cash',
    LogoPullSource.banks: 'banks',
    LogoPullSource.currency: 'currency',
    LogoPullSource.general: 'general',
    LogoPullSource.variants: 'variants',
    LogoPullSource.routes: 'routes',
    LogoPullSource.announcements: 'announcements',
    LogoPullSource.stock: 'stock',
    LogoPullSource.balances: 'balances',
    LogoPullSource.warehouses: 'warehouses',
    LogoPullSource.salesmen: 'salesmen',
    LogoPullSource.orders: 'orders',
  };

  /// [tigerSources]: MBT "alınacak veriler" ekranındaki dokuz satır
  static const List<LogoPullSource> tigerSources = [
    LogoPullSource.products,
    LogoPullSource.customers,
    LogoPullSource.cash,
    LogoPullSource.banks,
    LogoPullSource.currency,
    LogoPullSource.general,
    LogoPullSource.variants,
    LogoPullSource.routes,
    LogoPullSource.announcements,
  ];

  /// [exfinSources]: ExfinApi middleware üzerinden çekilebilen sıra
  static const List<LogoPullSource> exfinSources = [
    LogoPullSource.customers,
    LogoPullSource.products,
    LogoPullSource.stock,
    LogoPullSource.balances,
  ];

  /// [_tigerPullCapable]: `LogoTigerPullSync.pullAll` ile gerçekten çekilenler
  ///
  /// Ekran listesinden (MBT dokuz satır) ayrıdır: sipariş, ambar ve plasiyer
  /// tek başına çekilebilir kalır; GENEL satırı bu alt kaynakları birleştirir.
  static const Set<LogoPullSource> _tigerPullCapable = {
    LogoPullSource.products,
    LogoPullSource.customers,
    LogoPullSource.cash,
    LogoPullSource.banks,
    LogoPullSource.currency,
    LogoPullSource.general,
    LogoPullSource.warehouses,
    LogoPullSource.salesmen,
    LogoPullSource.orders,
  };

  /// [_comingSoonSources]: Kaynağı henüz bağlanmamış satırlar
  static const Set<LogoPullSource> _comingSoonSources = {
    LogoPullSource.variants,
    LogoPullSource.routes,
    LogoPullSource.announcements,
  };

  /// [_centerSources]: Logo değil, merkez (PostgREST) kaynaklı satırlar
  static const Set<LogoPullSource> _centerSources = {
    LogoPullSource.routes,
    LogoPullSource.announcements,
  };

  /// {@template logo_pull_source_catalog_for_mode}
  /// Aktif bağlantı türüne göre indirilebilir kaynak listesi.
  ///
  /// Parametreler:
  /// - [tigerEnabled]: Tiger Objects REST modu açık mı
  ///
  /// Dönüş değeri:
  /// - [List]: Ekranda gösterilecek sıralı kaynak listesi
  /// {@endtemplate}
  static List<LogoPullSource> forMode({required bool tigerEnabled}) {
    return tigerEnabled ? tigerSources : exfinSources;
  }

  /// {@template logo_pull_source_catalog_title_key}
  /// Kaynağın satır başlığı l10n anahtarı.
  ///
  /// Parametreler:
  /// - [source]: Veri türü
  /// - [tigerEnabled]: Tiger modunda MBT başlığı, ExfinApi modunda eski başlık
  ///
  /// Dönüş değeri:
  /// - [String]: `field_sales.` ile başlayan çeviri anahtarı
  /// {@endtemplate}
  static String titleKey(
    LogoPullSource source, {
    bool tigerEnabled = true,
  }) {
    if (!tigerEnabled) {
      final legacy = _exfinTitleKeys[source];
      if (legacy != null) return legacy;
    }
    return _titleKeys[source]!;
  }

  /// Kaynağın kalıcılık / satır anahtarı.
  static String storageKey(LogoPullSource source) => _storageKeys[source]!;

  /// {@template logo_pull_source_catalog_from_storage_key}
  /// Kalıcılık anahtarını kaynağa çevirir.
  ///
  /// Parametreler:
  /// - [key]: Saklanan kaynak anahtarı
  ///
  /// Dönüş değeri:
  /// - [LogoPullSource]: Eşleşen kaynak; tanınmıyorsa `null`
  /// {@endtemplate}
  static LogoPullSource? fromStorageKey(String key) {
    final normalized = key.trim();
    if (normalized.isEmpty) return null;
    for (final entry in _storageKeys.entries) {
      if (entry.value == normalized) return entry.key;
    }
    return null;
  }

  /// Kaynak Tiger Objects REST ile çekilebilir mi?
  static bool supportsTiger(LogoPullSource source) =>
      _tigerPullCapable.contains(source);

  /// Kaynak ExfinApi middleware ile çekilebilir mi?
  static bool supportsExfin(LogoPullSource source) =>
      exfinSources.contains(source);

  /// Kaynak henüz hiçbir uç noktaya bağlanmadı mı? (uydurma endpoint yok)
  static bool isComingSoon(LogoPullSource source) =>
      _comingSoonSources.contains(source);

  /// Kaynak Logo değil, merkez (PostgREST) tarafından mı beslenecek?
  static bool isCenterSource(LogoPullSource source) =>
      _centerSources.contains(source);

  /// {@template logo_pull_source_catalog_pending_message_key}
  /// Çekilemeyen satır için gösterilecek bilgilendirme anahtarı.
  ///
  /// Parametreler:
  /// - [source]: Veri türü
  ///
  /// Dönüş değeri:
  /// - [String]: Merkez kaynaklıysa [centerSourceKey], değilse [comingSoonKey]
  /// {@endtemplate}
  static String pendingMessageKey(LogoPullSource source) =>
      isCenterSource(source) ? centerSourceKey : comingSoonKey;
}
