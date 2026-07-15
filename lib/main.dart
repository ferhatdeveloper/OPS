import 'package:flutter/material.dart';
import 'view/logo_widget.dart';
import 'core/utils/color_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'view/login_screen.dart';
import 'service/theme_service.dart';
import 'service/language_service.dart';
import 'service/database_service.dart';
import 'core/localization/app_localization.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'service/storage_service.dart';
import 'core/database/database_path_manager.dart';
import 'core/sync/sync_manager.dart';
import 'core/sync/sync_config.dart';
import 'core/services/logo_api_service.dart';
import 'core/providers/loading_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/init/navigation/routes.dart';
import 'view/settings/sync_log_screen.dart';
import 'core/database/migrations/SqlQuerys.dart';
import 'core/services/postgre_service.dart';
import 'modules/field_sales/vehicles/view/vehicle_loading_screen.dart';
import 'modules/field_sales/vehicles/view/vehicle_stock_screen.dart';
import 'modules/field_sales/vehicles/view/vehicle_eod_screen.dart';
import 'modules/field_sales/maps/view/map_screen.dart';
import 'modules/field_sales/collections/view/collection_entry_screen.dart';
import 'modules/field_sales/invoices/view/invoice_entry_screen.dart';
import 'modules/field_sales/invoices/view/invoice_list_screen.dart';
import 'modules/field_sales/orders/view/order_entry_screen.dart';
import 'modules/field_sales/reports/view/dashboard_screen.dart';
import 'modules/field_sales/routes/view/route_plan_screen.dart';
import 'modules/field_sales/customers/view/customer_list_screen.dart';
import 'service/location_service.dart';

// EXFIN Splash Renkleri
const Color _splashDarkBlue = Color.fromARGB(255, 5, 79, 153);
const Color _splashLightBlue = Color(0xFF3498DB);
const Color _splashRed = Color(0xFFFF0000);

// Loglama fonksiyonu
void debugLog(String message) {
  print('EXFIN-DEBUG: $message');
}

/// {@template splash_screen}
/// Uygulama başlatılırken gösterilen splash ekranı
///
/// Kullanım örneği:
/// ```dart
/// const SplashScreen(
///   message: 'Uygulama başlatılıyor...',
/// )
/// ```
/// {@endtemplate}
class SplashScreen extends ConsumerWidget {
  /// {@macro splash_screen}
  const SplashScreen({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingState = ref.watch(loadingProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Stack(
          children: [
            // Blur circles — same as login screen
            Positioned(
              top: 20,
              left: -20,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    ColorUtils.withAlpha(_splashDarkBlue, 0.25),
                    ColorUtils.withAlpha(_splashDarkBlue, 0.0),
                  ]),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.1,
              left: screenWidth * 0.2,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    ColorUtils.withAlpha(_splashLightBlue, 0.25),
                    ColorUtils.withAlpha(_splashLightBlue, 0.0),
                  ]),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.25,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    ColorUtils.withAlpha(_splashLightBlue, 0.20),
                    ColorUtils.withAlpha(_splashLightBlue, 0.0),
                  ]),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.15,
              right: -20,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    ColorUtils.withAlpha(_splashRed, 0.15),
                    ColorUtils.withAlpha(_splashRed, 0.0),
                  ]),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.35,
              right: 0,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    ColorUtils.withAlpha(_splashDarkBlue, 0.20),
                    ColorUtils.withAlpha(_splashDarkBlue, 0.0),
                  ]),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  // Logo — same as login
                  const ExfinLogo(height: 110),
                  const SizedBox(height: 16),
                  // Slogan — same as login
                  Text(
                    'Operasyon Yönetim Sistemi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode
                          ? Colors.white70
                          : _splashDarkBlue.withOpacity(0.8),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(flex: 3),
                  // Progress section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      children: [
                        Text(
                          loadingState.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.white70
                                : _splashDarkBlue.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: loadingState.progress,
                            minHeight: 5,
                            backgroundColor:
                                _splashDarkBlue.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _splashLightBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(loadingState.progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.white54
                                : _splashDarkBlue.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set status bar icons to be visible on light backgrounds.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // transparent status bar
      statusBarIconBrightness: Brightness.dark, // dark icons for Android
      statusBarBrightness: Brightness.light, // dark icons for iOS
    ),
  );
  
  debugLog('WidgetsFlutterBinding initialized');

  // Initialize background location service
  await LocationService.initializeBackgroundService();
  debugLog('Background location service initialized');

  // Web dışı platformlarda FFI başlat
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final container = ProviderContainer();
  final loadingNotifier = container.read(loadingProvider.notifier);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SplashScreen(
        message: 'Uygulama başlatılıyor...',
      ),
    ),
  );

  try {
    debugLog('EXFIN-DEBUG: Native platform detected');
    loadingNotifier.updateMessage('Platform kontrolü yapılıyor...');

    // Sadece Windows'ta pencere yöneticisi başlat (web hariç)
    if (!kIsWeb && Platform.isWindows) {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1280, 720),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }

    loadingNotifier.updateMessage('Ayarlar yükleniyor...');
    loadingNotifier.updateProgress(0.2);
    await StorageService.getInstance();

    loadingNotifier.updateMessage('Veritabanı bağlantısı kuruluyor...');
    loadingNotifier.updateProgress(0.3);
    // Supabase yerine yerel PostgreSQL servisini başlatıyoruz
    await PostgreService.getInstance();
    debugLog('EXFIN-DEBUG: Yerel PostgreSQL başlatıldı');

    // Web platformunda SQLite kullanılmaz
    if (!kIsWeb) {
      loadingNotifier.updateMessage('Veritabanı kontrol ediliyor...');
      loadingNotifier.updateProgress(0.4);
      final dbPath = await DatabasePathManager.getDatabasePath();
      final dbExists = await DatabasePathManager.databaseExists();
      debugLog('EXFIN-DEBUG: Veritabanı mevcut mu: $dbExists');
      if (!dbExists) {
        loadingNotifier.updateMessage('Veritabanı oluşturuluyor...');
        loadingNotifier.updateProgress(0.5);
        debugLog('EXFIN-DEBUG: Veritabanı oluşturuluyor...');
        final db = await openDatabase(
          dbPath,
          version: 1,
          onCreate: (db, version) async {
            debugLog(
                'EXFIN-DEBUG: Senkronizasyon meta tablosu oluşturuluyor...');
            await db.execute(SqlQuerys.createSyncMetadataTable);
          },
        );
        loadingNotifier.updateMessage('Senkronizasyon yapılandırılıyor...');
        loadingNotifier.updateProgress(0.6);
        await SyncManager().initialize(
          database: db,
          config: SyncConfig.defaultConfig,
        );
      }
    }

    loadingNotifier.updateMessage('Veritabanı başlatılıyor...');
    loadingNotifier.updateProgress(0.7);
    await DatabaseService.getInstance();
    debugLog('EXFIN-DEBUG: Initializing database and default companies');



    loadingNotifier.updateMessage('Dil ayarları yükleniyor...');
    loadingNotifier.updateProgress(0.8);
    debugLog('EXFIN-DEBUG: Initializing language service');
    await LanguageService.initializeLanguageTables();
    
    // Yüklenen dili provider'a set et
    final savedLanguage = await LanguageService.getLanguagePreference();
    container.read(localeProvider.notifier).setLocale(Locale(savedLanguage));
    debugLog('EXFIN-DEBUG: Saved language loaded: $savedLanguage');

    loadingNotifier.updateMessage('Menü sistemi yükleniyor...');
    loadingNotifier.updateProgress(0.9);


    
    loadingNotifier.updateMessage('LOGO API servisi başlatılıyor...');
    LogoApiService().init();
    // Config SharedPreferences'tan arka planda yüklenir (init içinde loadConfig)

    loadingNotifier.updateMessage('Senkronizasyon başlatılıyor...');
    if (kDebugMode) {
      print('EXFIN-DEBUG: Sync manager initialized');
    }
    // SyncManager zaten initialize edildi, otomatik senkronizasyon aktif

    loadingNotifier.updateMessage('Uygulama başlatıldı!');
    loadingNotifier.updateProgress(1.0);
    await Future.delayed(const Duration(seconds: 1));

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    );
    debugLog('EXFIN-DEBUG: App started with ProviderScope');
  } catch (e) {
    if (kDebugMode) {
      print('EXFIN-DEBUG: Error initializing services: $e');
    }
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Uygulama başlatılırken bir hata oluştu',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugLog("MyApp build method called");

    // Provider'dan tema ve dil tercihlerini al
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    debugLog("Current theme mode: $themeMode");
    debugLog("Current locale from provider: ${locale.toString()}");

    // Dil yönünü belirle (RTL veya LTR)
    final isRtl = AppLocalization.isRtl(locale.languageCode);
    final textDirection = isRtl ? TextDirection.rtl : TextDirection.ltr;

    debugLog("Text direction: ${isRtl ? 'RTL' : 'LTR'}");

    // RTL dilleri için onErrorBuilder'ı yapılandır
    ErrorWidgetBuilder originalErrorBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (details.exception.toString().contains(
            'No MaterialLocalizations found',
          )) {
        // Özellikle bu hata için özel bir işleyici
        debugLog(
          "MaterialLocalizations hatası yakalandı, sabitlenmiş widget kullanılıyor",
        );
        return const SizedBox.shrink(); // Sessizce hatayı gizle
      }
      // Diğer tüm hatalar için orijinal builder'ı kullan
      return originalErrorBuilder(details);
    };

    // Basitleştirilmiş MaterialApp yapısı - önce GlobalWidgetsLocalizations
    return MaterialApp(
      title: 'EXFIN OPS',
      locale: locale,
      debugShowCheckedModeBanner: false,

      // Delegeleri doğru sırayla ekleyin (önce WidgetsLocalizations olmalı)
      localizationsDelegates: const [
        // Önce widget localization, sonra material ve cupertino
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // Özel lokalizasyon delegesi en son sırada
        AppLocalizationDelegate(),
      ],

      // Desteklenen diller
      supportedLocales: AppLocalization.supportedLocales(),

      // Dil çözümleme callback'i
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        debugLog(
          "Locale resolution: deviceLocale=$deviceLocale, using locale=$locale",
        );
        // Her zaman seçilen locale'i kullan, device locale'i değil
        return locale;
      },

      // Tema ayarları
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF375A7F),
          secondary: const Color(0xFF00A8E8),
          background: const Color(0xFFF2F3F5),
          surface: Colors.white,
          error: const Color(0xFFe74c3c),
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F3F5),
      ),

      // Koyu tema
      darkTheme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFBB86FC),
          secondary: const Color(0xFF03DAC6),
          background: const Color(0xFF121212),
          surface: const Color(0xFF1E1E1E),
          error: const Color(0xFFCF6679),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),

      // Tema modu
      themeMode: themeMode,

      // UI yapılandırıcı
      builder: (context, child) {
        debugLog("MaterialApp builder called");
        // Directionality ile sar (RTL desteği için)
        return Directionality(
          textDirection: textDirection,
          child: child ?? const SizedBox.shrink(),
        );
      },

      // Rota tanımlamaları
      routes: {
        '/login': (context) => const LoginScreen(),
        AppRoutes.systemLogs: (context) => const SyncLogScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/field-sales/collections') {
          final customerId = settings.arguments as String?;
          if (customerId != null) {
            return MaterialPageRoute(builder: (context) => CollectionEntryScreen(customerId: customerId));
          }
        }
        if (settings.name == '/field-sales/orders') {
          final customerId = settings.arguments as String?;
          if (customerId != null) {
            return MaterialPageRoute(builder: (context) => OrderEntryScreen(customerId: customerId));
          }
        }
        if (settings.name == '/field-sales/invoices') {
          final customerId = settings.arguments as String?;
          if (customerId != null) {
            return MaterialPageRoute(builder: (context) => InvoiceListScreen(customerId: customerId));
          }
        }
        if (settings.name == '/field-sales/invoices/new') {
          final customerId = settings.arguments as String?;
          if (customerId != null) {
            return MaterialPageRoute(builder: (context) => InvoiceEntryScreen(customerId: customerId));
          }
        }
        if (settings.name == '/field-sales/vehicle-loading') {
          return MaterialPageRoute(builder: (context) => const VehicleLoadingScreen());
        }
        if (settings.name == '/field-sales/vehicle-stock') {
          return MaterialPageRoute(builder: (context) => const VehicleStockSummaryScreen());
        }
        if (settings.name == '/field-sales/vehicle-eod') {
          return MaterialPageRoute(builder: (context) => const EndOfDayScreen());
        }
        if (settings.name == '/field-sales/map') {
          return MaterialPageRoute(builder: (context) => const MapScreen());
        }
        if (settings.name == '/field-sales/dashboard') {
          return MaterialPageRoute(builder: (context) => const DashboardScreen());
        }
        if (settings.name == '/field-sales/routes/plan') {
          return MaterialPageRoute(builder: (context) => const RoutePlanScreen());
        }
        if (settings.name == '/field-sales/customers') {
          return MaterialPageRoute(builder: (context) => const CustomerListScreen());
        }
        return null;
      },

      // Başlangıç ekranı
      home: const LoginScreen(),
    );
  }
}
