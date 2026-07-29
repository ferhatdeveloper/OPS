// Dosya Adı: logo_pull_source.dart
// Açıklama: Logo'dan indirilebilen veri türleri ve bağlantı yetenek kataloğu
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

/// {@template logo_pull_source}
/// Güncelleme ekranında ayrı ayrı indirilebilen Logo veri türü.
///
/// Katalog yalnızca mevcut istemcilerin gerçekten desteklediği kaynakları
/// içerir: Tiger Objects REST için `items`, `Arps`, `locationCodes`,
/// `salesmen`, `salesOrders`; ExfinApi middleware için cari, ürün, stok ve
/// bakiye uç noktaları.
/// {@endtemplate}
enum LogoPullSource {
  /// Cari kartlar — Tiger `Arps` / ExfinApi `customers`
  customers,

  /// Ürün kartları — Tiger `items` / ExfinApi `items`
  products,

  /// Stok miktarı — ExfinApi envanter raporu
  stock,

  /// Cari bakiye — ExfinApi bakiye uç noktası
  balances,

  /// Depo / lokasyon — Tiger `locationCodes`
  warehouses,

  /// Plasiyer kartları — Tiger `salesmen`
  salesmen,

  /// Satış siparişleri — Tiger `salesOrders`
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

  /// [_titleKeys]: Kaynak → satır başlığı l10n anahtarı
  static const Map<LogoPullSource, String> _titleKeys = {
    LogoPullSource.customers: 'field_sales.customer_list',
    LogoPullSource.products: 'field_sales.product_list',
    LogoPullSource.stock: 'field_sales.stock',
    LogoPullSource.balances: 'field_sales.balance',
    LogoPullSource.warehouses: 'field_sales.logo_pull_warehouses',
    LogoPullSource.salesmen: 'field_sales.logo_pull_salesmen',
    LogoPullSource.orders: 'field_sales.logo_pull_orders',
  };

  /// [_storageKeys]: Kaynak → prefs / satır anahtarı
  static const Map<LogoPullSource, String> _storageKeys = {
    LogoPullSource.customers: 'customers',
    LogoPullSource.products: 'products',
    LogoPullSource.stock: 'stock',
    LogoPullSource.balances: 'balances',
    LogoPullSource.warehouses: 'warehouses',
    LogoPullSource.salesmen: 'salesmen',
    LogoPullSource.orders: 'orders',
  };

  /// [tigerSources]: `LogoTigerPullSync.pullAll` bayraklarıyla eşleşen sıra
  static const List<LogoPullSource> tigerSources = [
    LogoPullSource.customers,
    LogoPullSource.products,
    LogoPullSource.warehouses,
    LogoPullSource.salesmen,
    LogoPullSource.orders,
  ];

  /// [exfinSources]: ExfinApi middleware üzerinden çekilebilen sıra
  static const List<LogoPullSource> exfinSources = [
    LogoPullSource.customers,
    LogoPullSource.products,
    LogoPullSource.stock,
    LogoPullSource.balances,
  ];

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

  /// Kaynağın satır başlığı l10n anahtarı.
  static String titleKey(LogoPullSource source) => _titleKeys[source]!;

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
      tigerSources.contains(source);

  /// Kaynak ExfinApi middleware ile çekilebilir mi?
  static bool supportsExfin(LogoPullSource source) =>
      exfinSources.contains(source);
}
