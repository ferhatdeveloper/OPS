import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../modules/field_sales/products/view/product_catalog_screen.dart';
import '../service/theme_service.dart';
import '../modules/field_sales/shared/widgets/company_branding_logo.dart';
import '../modules/field_sales/reports/view/report_logo_settings_screen.dart';
import '../modules/field_sales/settings/view/appearance_settings_screen.dart';
import '../core/utils/color_utils.dart';
import '../core/auth/app_user_role.dart';
import '../core/auth/role_home_menu_filter.dart';
import '../core/auth/session_role_resolver.dart';
import '../core/constants/menu_constants.dart' hide MenuItemData;
import '../modules/field_sales/home/view/role_home_hub_body.dart';
import '../modules/field_sales/ai/view/ai_voice_chat_screen.dart';
import '../service/language_service.dart';
import '../core/localization/app_localization.dart';
import '../core/widgets/app_version_label.dart';
import '../service/menu_service.dart';
import '../service/database_service.dart';
import '../service/auth_service.dart';
import '../core/providers/loading_provider.dart';
import 'dart:async';
import '../view/settings/sync_log_screen.dart';
import '../modules/field_sales/reports/view/dashboard_screen.dart';
import '../modules/field_sales/routes/view/route_plan_screen.dart';
import '../modules/field_sales/routes/view/weekly_route_plan_screen.dart';
import '../modules/field_sales/customers/view/customer_list_screen.dart';
import '../modules/field_sales/customers/view/customer_form_screen.dart';
import '../modules/field_sales/reports/view/logo_reports_screen.dart';
import '../modules/field_sales/vehicles/view/vehicle_loading_screen.dart';
import '../modules/field_sales/vehicles/view/vehicle_stock_screen.dart';
import '../modules/field_sales/vehicles/view/vehicle_eod_screen.dart';
import '../modules/field_sales/maps/view/map_screen.dart';
import '../modules/field_sales/collections/view/collection_entry_screen.dart';
import '../modules/field_sales/collections/view/collection_customer_selection_screen.dart';
import '../modules/field_sales/collections/view/payment_entry_screen.dart';
import '../modules/field_sales/collections/view/virman_screen.dart';
import '../modules/field_sales/collections/view/finance_type_sheet.dart';
import '../modules/field_sales/collections/view/credit_card_collection_screen.dart';
import '../modules/field_sales/collections/view/promissory_note_screen.dart';
import '../modules/field_sales/collections/model/finance_movement_type.dart';
import '../modules/field_sales/collections/viewmodel/collection_provider.dart';
import '../modules/field_sales/invoices/view/invoice_list_screen.dart';
import '../modules/field_sales/invoices/view/invoice_entry_screen.dart';
import '../modules/field_sales/invoices/view/invoice_customer_selection_screen.dart';
import '../modules/field_sales/invoices/viewmodel/invoice_provider.dart';
import '../modules/field_sales/orders/view/order_entry_screen.dart';
import '../modules/field_sales/orders/view/order_customer_selection_screen.dart';
import '../modules/field_sales/orders/view/order_approval_screen.dart';
import '../modules/field_sales/orders/view/order_type_sheet.dart';
import '../modules/field_sales/orders/model/order_model.dart';
import '../modules/field_sales/routes/viewmodel/visit_provider.dart';
import '../modules/field_sales/orders/viewmodel/order_provider.dart';
import '../modules/field_sales/yonetici/view/admin_kpi_summary_screen.dart';
import '../core/init/navigation/routes.dart';

import '../modules/manager/reports/view/manager_reports_dashboard.dart';
import '../modules/manager/reports/view/period_comparison_report.dart';
import '../modules/manager/reports/view/advanced_analysis_screen.dart';
import '../modules/field_sales/currency/view/currency_rates_screen.dart';
import '../modules/field_sales/sync/view/data_transfer_screen.dart';
import '../modules/field_sales/sync/view/logo_rest_settings_screen.dart';
import '../modules/field_sales/companies/view/company_list_screen.dart';
import '../modules/field_sales/stock/view/barcode_scanner_screen.dart';
import '../modules/ai/view/ai_assistant_screen.dart';
import '../modules/inventory/view/warehouse_management_screen.dart';
import '../modules/inventory/view/stock_count_screen.dart';
import '../modules/field_sales/stock/view/price_check_screen.dart';
import '../modules/field_sales/other/view/day_status_screen.dart';
import '../modules/field_sales/other/viewmodel/day_sales_gate.dart';
import '../modules/field_sales/other/viewmodel/day_status_store.dart';
import '../modules/field_sales/other/widgets/day_status_dens_chip.dart';
import '../modules/field_sales/companies/widgets/active_company_dens_chip.dart';
import '../modules/field_sales/stock/widgets/active_warehouse_dens_chip.dart';
import '../core/tenant/widgets/tenant_dens_chip.dart';
import '../modules/field_sales/eod/view/day_open_screen.dart';
import '../modules/field_sales/eod/view/pending_transfer_guard_dialog.dart';
import '../modules/field_sales/eod/viewmodel/pending_transfer_gate.dart';
import '../modules/field_sales/eod/viewmodel/pending_transfer_guard.dart';
import '../modules/field_sales/invoices/view/invoices_untransferred_screen.dart';
import '../modules/field_sales/stock/view/warehouse_receipt_screen.dart';
import '../modules/manager/reports/view/target_assignment_screen.dart';
import '../modules/manager/reports/view/leaderboard_screen.dart';
import '../modules/field_sales/sync/view/pending_transfers_screen.dart';
import '../modules/field_sales/sync/view/slip_defaults_screen.dart';
import '../modules/field_sales/other/view/gallery_screen.dart';
import '../modules/field_sales/gamification/view/gamification_dashboard.dart';
import '../modules/field_sales/announcements/view/announcements_screen.dart';
import '../modules/field_sales/favorites/view/favorites_screen.dart';

/// MBT dolu kalp rengi (RGB ≈ 247,170,35)
const Color _kFavoriteHeartColor = Color(0xFFF7AA23);

class MobileDashboard extends ConsumerStatefulWidget {
  final String username;
  const MobileDashboard({Key? key, required this.username}) : super(key: key);

  @override
  ConsumerState<MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends ConsumerState<MobileDashboard> {
  final String currentDate = DateFormat('dd.MM.yyyy').format(DateTime.now());
  int _currentIndex = 0;
  int? _expandedMenuIndex; // Track which menu is expanded
  bool _isSyncing = true; // Sync durumu takibi
  String _selectedPeriod = 'daily'; // daily, weekly, monthly
  late PageController _pageController;

  /// Oturumdan çözülen rol
  AppUserRole _sessionRole = AppUserRole.unknown;

  // Define locale variable
  late Locale locale;

  /// Efektif rol (oturum)
  AppUserRole get _effectiveRole => _sessionRole;

  /// Alt bar seçili indeks (0–4; AI=3 sayfa değil push)
  static const int _navAiIndex = 3;

  int get _bottomNavSelectedIndex {
    if (_currentIndex >= _navAiIndex) return _currentIndex + 1;
    return _currentIndex;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    // Force portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Seed mock data for Field Sales module
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DatabaseService.getInstance().then((db) async {
        await db.seedFieldSalesMockData();
        // Sync with Postgres (Pull & Push)
        await db.syncMenusFromPostgres();
        await db.syncVisitsToPostgres();
        await db.syncOrdersToPostgres();
        await AnnouncementsScreen.refreshDensCache();
        await _loadSessionRole();

        if (mounted) {
           setState(() {}); // Refresh UI after seeding
        }
      });
    });
    _initializeLanguage();
    _startForceLogoutListener();
    _syncMenuPermissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionRole() async {
    final role = await const SessionRoleResolver().resolve();
    if (!mounted) return;
    setState(() {
      _sessionRole = role;
    });
  }

  /// Alt bar sekmesi; AI → sohbet route.
  void _onBottomNavTap(int index) {
    if (index == _navAiIndex) {
      Navigator.pushNamed(
        context,
        AiVoiceChatScreen.routeName,
        arguments: widget.username,
      );
      return;
    }
    final page = index > _navAiIndex ? index - 1 : index;
    _pageController.jumpToPage(page);
    setState(() => _currentIndex = page);
  }

  Future<void> _syncMenuPermissions() async {
    if (!mounted) return;
    setState(() => _isSyncing = true);
    
    try {
      final db = await DatabaseService.getInstance();
      // final session = await db.getUserSession();
      // Session olsun olmasın mock verileri ekleyelim (fallback id'ler ile)
      await db.seedFieldSalesMockData();
      
      // Menü servisini tamamen sıfırla ve yeniden yükle
      await MenuService.reloadAll();
    } catch (e) {
      debugPrint('${AppLocalization.of(context).translate('mobile_dashboard.menu_load_error')} $e');
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _initializeLanguage() async {
    final languageCode = await LanguageService.getLanguagePreference();

    Locale newLocale;
    if (languageCode.contains('-')) {
      final parts = languageCode.split('-');
      newLocale = Locale(parts[0], parts[1].toUpperCase());
    } else {
      newLocale = Locale(languageCode);
    }

    // Provider'ı güncelle
    if (mounted) {
      ref.read(localeProvider.notifier).setLocale(newLocale);
      setState(() {
        locale = newLocale;
      });
    }
  }

  /// {@template mobile_dashboard_show_language_picker}
  /// Dens dil seçici (login LanguageService listesi).
  /// {@endtemplate}
  void _showLanguagePickerDens(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          titlePadding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          title: Text(
            l10n.translate('mobile_dashboard.language'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: 280,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(
                shrinkWrap: true,
                children: LanguageService.supportedLanguages.map((lang) {
                  final isSelected =
                      ref.watch(localeProvider).languageCode == lang.code;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Material(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : (isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          if (isSelected) {
                            Navigator.pop(dialogContext);
                            return;
                          }
                          ref
                              .read(localeProvider.notifier)
                              .setLocale(Locale(lang.code));
                          await LanguageService.setLanguagePreference(
                            lang.code,
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: _dashboardLanguageFlag(lang.code),
                          title: Text(
                            lang.localName,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? colorScheme.primary
                                  : (isDarkMode
                                      ? Colors.white
                                      : Colors.black87),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: colorScheme.primary,
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  /// {@template mobile_dashboard_language_flag}
  /// Dil koduna göre küçük bayrak / globe.
  /// {@endtemplate}
  Widget _dashboardLanguageFlag(String code) {
    const size = 22.0;
    String? asset;
    switch (code) {
      case 'tr':
        asset = 'assets/flags/tr.png';
        break;
      case 'en':
        asset = 'assets/flags/gb.png';
        break;
      case 'ar':
        asset = 'assets/flags/sa.png';
        break;
      case 'ku':
      case 'ckb':
        asset = 'assets/flags/iq.png';
        break;
      case 'de':
        asset = 'assets/flags/de.png';
        break;
      case 'fa':
        asset = 'assets/flags/ir.png';
        break;
      case 'ru':
        asset = 'assets/flags/ru.png';
        break;
      case 'fr':
        asset = 'assets/flags/fr.png';
        break;
      case 'es':
        asset = 'assets/flags/es.png';
        break;
      case 'zh':
        asset = 'assets/flags/cn.png';
        break;
    }
    if (asset == null) {
      return Icon(Icons.language, size: size, color: Colors.blueGrey);
    }
    return Image.asset(
      asset,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.language, size: size, color: Colors.blueGrey),
    );
  }

  Future<void> _startForceLogoutListener() async {
    final db = await DatabaseService.getInstance();
    final session = await db.getUserSession();
    final userId = session?['id'];
    if (userId != null) {
      AuthService.startForceLogoutListener(context, ref, userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ForceLogoutState>(forceLogoutProvider, (prev, next) {
      if (next.isActive && next.onResult != null) {
        int secondsLeft = 15;
        Timer? timer;
        bool callbackCalled = false;
        void safeCallback(bool accepted) {
          if (!callbackCalled) {
            callbackCalled = true;
            next.onResult!(accepted);
            ref.read(forceLogoutProvider.notifier).hide();
          }
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
                  if (secondsLeft > 0) {
                    setState(() => secondsLeft--);
                  } else {
                    timer?.cancel();
                    Navigator.of(context, rootNavigator: true).pop();
                    safeCallback(true);
                  }
                });
                return AlertDialog(
                  title: Text(AppLocalization.of(context).translate('auth.takeover_request_title')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(next.message ?? ''),
                      const SizedBox(height: 16),
                      Text(AppLocalization.of(context).translate('auth.countdown_seconds', args: {'seconds': secondsLeft.toString()}),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        timer?.cancel();
                        Navigator.of(context, rootNavigator: true).pop();
                        safeCallback(false);
                      },
                      child: Text(AppLocalization.of(context).translate('common.reject')),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        timer?.cancel();
                        Navigator.of(context, rootNavigator: true).pop();
                        safeCallback(true);
                      },
                      child: Text(AppLocalization.of(context).translate('common.accept')),
                    ),
                  ],
                );
              },
            );
          },
        );
      }
    });

    // Update locale when it changes
    locale = ref.watch(localeProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final pages = [
      _buildHomeScreen(context),
      _buildMenuScreen(context),
      const DashboardScreen(),
      _buildSettingsScreen(context),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        body: _isSyncing
            ? const Center(child: CircularProgressIndicator())
            : PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: pages,
              ),
        bottomNavigationBar: _buildBottomBar(isDarkMode, colorScheme),
      ),
    );
  }

  /// Ana / Menü / Rapor / AI / Ayarlar — AI push, diğerleri PageView.
  Widget _buildBottomBar(bool isDarkMode, ColorScheme colorScheme) {
    return BottomNavigationBar(
      currentIndex: _bottomNavSelectedIndex,
      onTap: _onBottomNavTap,
      backgroundColor: isDarkMode ? const Color(0xFF1F1B24) : Colors.white,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_rounded),
          label: AppLocalization.of(context).translate('mobile_dashboard.home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.menu),
          label: AppLocalization.of(context).translate('mobile_dashboard.menu'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.bar_chart_rounded),
          label: AppLocalization.of(context)
              .translate('mobile_dashboard.report'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.auto_awesome_rounded),
          label: AppLocalization.of(context)
              .translate('mobile_dashboard.ai_chat'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings),
          label: AppLocalization.of(context)
              .translate('mobile_dashboard.settings'),
        ),
      ],
    );
  }

  Widget _buildHomeScreen(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final role = _effectiveRole;

    // Yönlendirme (switch-case) eşleşmelerinin doğru çalışması için her zaman
    // 'tr' (orijinal) dil kodundaki modülleri yükle. Arayüz katmanında çevrilir.
    // Permission ∩ rol: oturum userId/companyNo ile can_view filtresi.
    return FutureBuilder<Map<String, dynamic>?>(
      future: DatabaseService.getInstance().then((db) => db.getUserSession()),
      builder: (context, sessionSnapshot) {
        if (sessionSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final session = sessionSnapshot.data;
        final userId = session?['id'] as String?;
        final companyNo = session == null
            ? null
            : int.tryParse(session['company_no']?.toString() ?? '') ?? 1;

        return FutureBuilder<List<ModuleCardData>>(
          future: MenuService.getMobileModuleCards(
            languageCode: 'tr',
            userId: userId,
            companyNo: companyNo,
          ),
          builder: (context, snapshot) {
        // Yükleniyor durumunda
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Hata durumunda
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              '${AppLocalization.of(context).translate('mobile_dashboard.menu_load_error')}\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          );
        }

        // Veriler yüklendiyse — rol filtresi ∩ permission (zaten MenuService’de)
        final moduleCards = _filterModuleCardsForRole(
          snapshot.data!,
          role,
        );

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Welcome Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Image.asset(
                              'assets/images/OPS_cropped.png',
                              height: 26, // Reduced size for better balance
                              fit: BoxFit.contain,
                              errorBuilder: (context, _, __) {
                                return Text(
                                  AppLocalization.of(context).translate(
                                    'branding.app_logo_missing',
                                  ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalization.of(
                                context,
                              ).translate('mobile_dashboard.hello'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.username.toUpperCase(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? ColorUtils.withAlpha(
                                              colorScheme.surface,
                                              0.5,
                                            )
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      currentDate,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const DayStatusDensChip(),
                                  const SizedBox(width: 5),
                                  const TenantDensChip(),
                                  const SizedBox(width: 5),
                                  const ActiveCompanyDensChip(),
                                  const SizedBox(width: 5),
                                  const ActiveWarehouseDensChip(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Tema değiştirme butonu
                                Container(
                                  margin: const EdgeInsetsDirectional.only(
                                    end: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? colorScheme.surface
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _getShadow(
                                      isDarkMode,
                                      blurRadius: 8,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        ref
                                            .read(themeModeProvider.notifier)
                                            .toggleThemeMode();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Icon(
                                          isDarkMode
                                              ? Icons.light_mode
                                              : Icons.dark_mode,
                                          color: colorScheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Dil seçici
                                Container(
                                  margin: const EdgeInsetsDirectional.only(
                                    end: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? colorScheme.surface
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _getShadow(
                                      isDarkMode,
                                      blurRadius: 8,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Tooltip(
                                      message: AppLocalization.of(context)
                                          .translate(
                                        'mobile_dashboard.language',
                                      ),
                                      child: InkWell(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        onTap: () =>
                                            _showLanguagePickerDens(context),
                                        child: Padding(
                                          padding: const EdgeInsets.all(6.0),
                                          child: Icon(
                                            Icons.language,
                                            color: colorScheme.primary,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Sık kullanılanlar butonu
                                Container(
                                  margin: const EdgeInsetsDirectional.only(
                                    end: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? colorScheme.surface
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _getShadow(
                                      isDarkMode,
                                      blurRadius: 8,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () =>
                                          _showFavoritesSheet(context),
                                      onLongPress: () =>
                                          _showFavoriteMenuDialog(context),
                                      child: const Padding(
                                        padding: EdgeInsets.all(6.0),
                                        child: Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Oyunlaştırma (Trophy) butonu
                                Container(
                                  margin: const EdgeInsetsDirectional.only(
                                    end: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? colorScheme.surface
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _getShadow(
                                      isDarkMode,
                                      blurRadius: 8,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const GamificationDashboardScreen(),
                                          ),
                                        );
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(6.0),
                                        child: Icon(
                                          Icons.emoji_events_outlined,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Bildirimler butonu
                                Container(
                                  margin: const EdgeInsetsDirectional.only(
                                    end: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? colorScheme.surface
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _getShadow(
                                      isDarkMode,
                                      blurRadius: 8,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppLocalization.of(context)
                                                  .translate(
                                                'mobile_dashboard.notifications_coming_soon',
                                              ),
                                            ),
                                            behavior:
                                                SnackBarBehavior.floating,
                                            backgroundColor:
                                                colorScheme.primary,
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Icon(
                                          Icons.notifications_outlined,
                                          color: colorScheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Çıkış butonu
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? colorScheme.surface
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _getShadow(
                                      isDarkMode,
                                      blurRadius: 8,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => _handleLogout(context),
                                      child: const Padding(
                                        padding: EdgeInsets.all(6.0),
                                        child: Icon(
                                          Icons.logout,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const CompanyBrandingLogo(
                              height: 22,
                              showFallback: false,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<List<FavoriteItemData>>(
                      future: MenuService.getMobileFavoriteItems(),
                      builder: (context, favSnapshot) {
                        if (favSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 90,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final favoriteItems = favSnapshot.hasData
                            ? favSnapshot.data!
                            : <FavoriteItemData>[];

                        if (favoriteItems.isEmpty) {
                          return Container(
                            height: 90,
                            alignment: Alignment.center,
                            child: Text(
                              AppLocalization.of(
                                context,
                              ).translate('mobile_dashboard.no_favorites'),
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalization.of(
                                context,
                              ).translate('mobile_dashboard.favorites'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 90,
                              child: ListView(
                                physics: const BouncingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                children: favoriteItems
                                    .map(
                                      (item) => _buildFavoriteItem(
                                        context,
                                        item.title,
                                        item.icon,
                                        route: item.route,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildDailySummary(context),
                    const SizedBox(height: 20),
                    // _buildGamificationHeaderCard(context),
                  ],
                ),
              ),
            ),

            if (role.usesRoleHomeHub)
              SliverToBoxAdapter(
                child: RoleHomeHubBody(role: role),
              ),

            // Main modules
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.90,
                ),
                delegate: SliverChildListDelegate(
                  () {
                    final favorilerTitle = AppLocalization.of(context)
                        .translate('dashboard.favoriler');
                    final duyurularTitle = AppLocalization.of(context)
                        .translate('dashboard.duyurular');
                    final cards = List<ModuleCardData>.from(moduleCards);
                    final hasFavoriler = cards.any(
                      (c) => _isFavoritesModuleTitle(c.title, favorilerTitle),
                    );
                    if (!hasFavoriler) {
                      cards.insert(
                        0,
                        ModuleCardData(
                          title: 'Favoriler',
                          subtitle: '',
                          icon: Icons.star,
                        ),
                      );
                    }
                    return cards.map((moduleCard) {
                      final isFavoriler = _isFavoritesModuleTitle(
                        moduleCard.title,
                        favorilerTitle,
                      );
                      final isDuyurular = _isModuleTitleMatch(
                        moduleCard.title,
                        localized: duyurularTitle,
                        legacyTr: const ['Duyurular'],
                        uuids: const [
                          'fs_announcements',
                          'field_sales.menu.fs_announcements',
                        ],
                      );
                      final isDoviz = _isModuleTitleMatch(
                        moduleCard.title,
                        legacyTr: const ['Döviz'],
                        uuids: const [
                          'fs_currency',
                          'field_sales.menu.fs_currency',
                        ],
                      );
                      final isSirketler = _isModuleTitleMatch(
                        moduleCard.title,
                        legacyTr: const ['Şirketler'],
                        uuids: const [
                          'fs_companies',
                          'field_sales.menu.fs_companies',
                        ],
                      );
                      return _buildModuleCard(
                        context,
                        moduleCard.title,
                        moduleCard.subtitle,
                        moduleCard.icon,
                        menuId: moduleCard.id,
                        isFavorite: moduleCard.isFavorite,
                        showFavoriteHeart: !isFavoriler,
                        // Duyurular: alt menü değil dens satır adedi (MBT badge).
                        badgeCount: isDuyurular
                            ? AnnouncementsScreen.densCount
                            : null,
                        submenus:
                            isDuyurular ||
                                    isFavoriler ||
                                    isDoviz ||
                                    isSirketler
                                ? const []
                                : moduleCard.submenus,
                        onTap: isFavoriler
                            ? () => _showFavoritesSheet(context)
                            : isDuyurular
                                ? () => Navigator.pushNamed(
                                      context,
                                      AnnouncementsScreen.routeName,
                                    )
                                : isDoviz
                                    ? () => Navigator.pushNamed(
                                          context,
                                          CurrencyRatesScreen.routeName,
                                        )
                                    : isSirketler
                                        ? () => Navigator.pushNamed(
                                              context,
                                              CompanyListScreen.routeName,
                                            )
                                        : null,
                      );
                    }).toList();
                  }(),
                ),
              ),
            ),
          ],
        );
          },
        );
      },
    );
  }

  Widget _buildMenuScreen(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Dil kodunu al
    final languageCode = locale.languageCode;

    return FutureBuilder<Map<String, dynamic>?>(
      future: DatabaseService.getInstance().then((db) => db.getUserSession()),
      builder: (context, sessionSnapshot) {
        if (sessionSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!sessionSnapshot.hasData || sessionSnapshot.data == null) {
          return Center(child: Text(AppLocalization.of(context).translate('mobile_dashboard.session_not_found')));
        }
        final userId = sessionSnapshot.data!['id'] as String;
        final companyNo = int.tryParse(sessionSnapshot.data!['company_no'].toString()) ?? 1;
        return FutureBuilder<List<MenuItemData>>(
          future: MenuService.getMainMenuItemsByUserAndCompany(
            userId: userId,
            companyNo: companyNo,
            languageCode: 'tr', // Rota eşleşmeleri için orijinal TR tutulur
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text(
                  '${AppLocalization.of(context).translate('mobile_dashboard.menu_load_error')}\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              );
            }
            final menuItems = _filterMenuItemsForRole(
              snapshot.data!,
              _effectiveRole,
            );
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Menu header
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalization.of(
                                context,
                              ).translate('mobile_dashboard.modules'),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? colorScheme.surface
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isDarkMode
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          spreadRadius: 0,
                                        ),
                                      ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    // Gelecekte arama işlevi eklenebilir
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalization.of(context).translate(
                                            'mobile_dashboard.search_coming_soon',
                                          ),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: colorScheme.primary,
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.search,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Favorites section
                        Text(
                          AppLocalization.of(
                            context,
                          ).translate('mobile_dashboard.favorites'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<List<FavoriteItemData>>(
                          future: MenuService.getMobileFavoriteItems(),
                          builder: (context, favSnapshot) {
                            if (favSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                height: 100,
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            final favoriteItems = favSnapshot.hasData
                                ? favSnapshot.data!
                                : <FavoriteItemData>[];
                            if (favoriteItems.isEmpty) {
                              return Container(
                                height: 100,
                                alignment: Alignment.center,
                                child: Text(
                                  AppLocalization.of(
                                    context,
                                  ).translate('mobile_dashboard.no_favorites'),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }
                            return SizedBox(
                              height: 100,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: favoriteItems
                                    .map(
                                      (item) => _buildFavoriteItem(
                                        context,
                                        item.title,
                                        item.icon,
                                        route: item.route,
                                      ),
                                    )
                                    .toList(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Menu items with expandable submenus
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = menuItems[index];
                      final bool isExpanded = _expandedMenuIndex == index;
                      return Column(
                        children: [
                          _buildMenuItemWithExpansion(
                            context,
                            item.title,
                            item.icon,
                            isExpanded: isExpanded,
                            onTap: () {
                              setState(() {
                                _expandedMenuIndex = isExpanded ? null : index;
                              });
                            },
                          ),
                          // Show submenus if expanded
                          if (isExpanded)
                            FutureBuilder<List<SubMenuItemData>>(
                              future:
                                  MenuService.getSubMenuItemsByUserAndCompany(
                                userId: userId,
                                companyNo: companyNo,
                                parentId: item.id,
                                languageCode: 'tr', // Rota eşleşmeleri için orijinal TR tutulur
                              ),
                              builder: (context, subSnapshot) {
                                if (subSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                final subMenus = _filterSubMenusForRole(
                                  subSnapshot.data ?? [],
                                  parentUuid: item.uuid,
                                  role: _effectiveRole,
                                );
                                return _buildSubMenus(
                                  context,
                                  subMenus,
                                  colorScheme,
                                  isDarkMode,
                                );
                              },
                            ),
                        ],
                      );
                    }, childCount: menuItems.length),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMenuItemWithExpansion(
    BuildContext context,
    String title,
    IconData icon, {
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = ColorUtils.getColorForIcon(icon);

    // Doğrudan title değişkenini çeviri için kullan
    String dashboardKey = 'dashboard.' + _getTranslationKeyForSubmenu(title);
    String translatedTitle = AppLocalization.of(context).translate(dashboardKey);

    // Çeviri bulunamazsa orijinal başlığı kullan
    if (translatedTitle == dashboardKey) {
      translatedTitle = title;
    }

    // Bu menü öğesinin sık kullanılanlarda olup olmadığını kontrol et
    final isFavorite = FutureBuilder<bool>(
      future: _isMenuItemFavorite(title),
      builder: (context, snapshot) {
        final isFav = snapshot.data ?? false;
        return IconButton(
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? _kFavoriteHeartColor : Colors.grey,
            size: 20,
          ),
          onPressed: () => _toggleFavoriteMenuItem(title, icon, !isFav),
          tooltip: isFav
              ? AppLocalization.of(
                  context,
                ).translate('mobile_dashboard.remove_from_favorites')
              : AppLocalization.of(
                  context,
                ).translate('mobile_dashboard.add_to_favorites'),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        );
      },
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? baseColor
              : isDarkMode
                  ? Colors.transparent
                  : Colors.grey[200]!,
          width: isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: _getShadow(isDarkMode),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Icon with color from ColorUtils
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorUtils.withAlpha(baseColor, 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: baseColor, size: 22),
                ),
                const SizedBox(width: 16),
                // Title with counter badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translatedTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // Favorite star icon
                isFavorite,
                const SizedBox(width: 8),
                // Badge showing submenu count
                FutureBuilder<int>(
                  future: _getSubmenuCount(title),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ColorUtils.withAlpha(baseColor, 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: baseColor,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Expand/collapse icon
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: isExpanded
                        ? baseColor
                        : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Belirli bir menü öğesinin kaç alt menüye sahip olduğunu döndürür
  Future<int> _getSubmenuCount(String title) async {
    try {
      final mainMenus = await MenuService.getMainMenuItems();
      final menuItem = mainMenus.firstWhere(
        (item) => item.title == title,
        orElse: () => MenuItemData(
          id: 0,
          title: '',
          icon: Icons.circle,
          submenus: [],
          isFavorite: false,
        ),
      );
      return menuItem.submenus.length;
    } catch (e) {
      print('Alt menü sayısı alınırken hata: $e');
      return 0;
    }
  }

  // Menü öğesinin sık kullanılan olup olmadığını kontrol eder
  Future<bool> _isMenuItemFavorite(String title) async {
    try {
      final favoriteItems = await MenuService.getFavoriteMenuItems();
      return favoriteItems.any((item) => item.title == title);
    } catch (e) {
      print('Sık kullanılan kontrolü yapılırken hata: $e');
      return false;
    }
  }

  // Menü öğesini sık kullanılanlara ekler/çıkarır
  Future<void> _toggleFavoriteMenuItem(
    String title,
    IconData icon,
    bool shouldAdd,
  ) async {
    try {
      // İlgili menü öğesinin ID'sini bulalım
      final mainMenus = await MenuService.getMainMenuItems();
      final menuItem = mainMenus.firstWhere(
        (item) => item.title == title,
        orElse: () => MenuItemData(
          id: 0,
          title: '',
          icon: Icons.circle,
          submenus: [],
          isFavorite: false,
        ),
      );

      if (menuItem.id > 0) {
        // Sık kullanılan durumunu güncelle
        await MenuService.toggleFavoriteMenuItem(menuItem.id, shouldAdd);

        // UI'ı güncellemek için state'i değiştir
        setState(() {});

        // Kullanıcıya bilgi ver
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                shouldAdd
                    ? AppLocalization.of(context).translate('mobile_dashboard.favorites_added', args: {'title': menuItem.title})
                    : AppLocalization.of(context).translate('mobile_dashboard.favorites_removed', args: {'title': menuItem.title}),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      print('Sık kullanılan durumu değiştirilirken hata: $e');
      // Hata durumunda kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalization.of(context).translate('common.error')}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSubMenus(
    BuildContext context,
    List<SubMenuItemData> subMenus,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15, left: 24, right: 4),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        children: subMenus.map((subItem) {
          final subMenu = subItem.title;
          final submenuIcon = _getIconForSubmenu(subMenu);
          final baseColor = ColorUtils.getColorForIcon(submenuIcon);

          // Submenu çevirisi için anahtar adı oluştur
          String translationKey =
              'submodules.' + _getTranslationKeyForSubmenu(subMenu);
          String translatedSubMenu = AppLocalization.of(
            context,
          ).translate(translationKey);
          
          // Çeviri bulunamazsa orjinal metni kullan
          if (translatedSubMenu == translationKey) {
            translatedSubMenu = subMenu;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? ColorUtils.withAlpha(baseColor, 0.08)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDarkMode ? Colors.white10 : Colors.grey.shade100,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openModule(
                  context,
                  subMenu,
                  route: subItem.route,
                ),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: ColorUtils.withAlpha(baseColor, 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(submenuIcon, size: 16, color: baseColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          translatedSubMenu,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                          ),
                        ),
                      ),
                      // Favori kalp simgesi
                      FutureBuilder<bool>(
                        future: _isSubmenuItemFavorite(subMenu),
                        builder: (context, snapshot) {
                          final isFavorite = snapshot.data ?? false;
                          return IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite
                                  ? _kFavoriteHeartColor
                                  : Colors.grey,
                              size: 18,
                            ),
                            onPressed: () => _toggleFavoriteSubmenuItem(
                              subMenu,
                              submenuIcon,
                              !isFavorite,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Alt menü öğesinin sık kullanılan olup olmadığını kontrol eder
  Future<bool> _isSubmenuItemFavorite(String title) async {
    try {
      // Dil kodunu al
      final languageCode = locale.languageCode;

      final favoriteItems = await MenuService.getFavoriteMenuItems(
        languageCode: languageCode,
      );
      return favoriteItems.any((item) => item.title == title);
    } catch (e) {
      print('Alt menü sık kullanılan kontrolü yapılırken hata: $e');
      return false;
    }
  }

  // Alt menü öğesini sık kullanılanlara ekler/çıkarır
  Future<void> _toggleFavoriteSubmenuItem(
    String title,
    IconData icon,
    bool shouldAdd,
  ) async {
    try {
      // Veritabanında ilgili alt menü öğesini bulalım
      final db = await DatabaseService.getInstance();
      final items = await db.getMenuItemByTitle(title);

      if (items.isNotEmpty) {
        final menuItem = items.first;
        final menuId = menuItem['id'] as int;

        // Sık kullanılan durumunu güncelle
        await MenuService.toggleFavoriteMenuItem(menuId, shouldAdd);

        // UI'ı güncellemek için state'i değiştir
        setState(() {});

        // Kullanıcıya bilgi ver
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                shouldAdd
                    ? AppLocalization.of(context).translate('mobile_dashboard.favorites_added', args: {'title': title})
                    : AppLocalization.of(context).translate('mobile_dashboard.favorites_removed', args: {'title': title}),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      print('Alt menü sık kullanılan durumu değiştirilirken hata: $e');
      // Hata durumunda kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalization.of(context).translate('common.error')}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Submenu çevirisi için anahtar adı oluşturan yardımcı fonksiyon
  String _getTranslationKeyForSubmenu(String submenu) {
    // Türkçe submenu adını çeviri anahtarına dönüştür
    // Büyük İ/Ş/Ğ/Ü/Ö/Ç dahil — toLowerCase locale farklarında key kaçmasın
    String key = submenu
        .replaceAll('İ', 'i')
        .replaceAll('I', 'i')
        .replaceAll('Ş', 's')
        .replaceAll('Ğ', 'g')
        .replaceAll('Ü', 'u')
        .replaceAll('Ö', 'o')
        .replaceAll('Ç', 'c')
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[\u0307]'), '') // combining dot (İ→i̇)
        .replaceAll(RegExp(r'[\s/_]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return key;
  }

  // Helper method to get icon for specific submenu item - synchronized with side_menu.dart
  IconData _getIconForSubmenu(String submenuTitle) {
    switch (submenuTitle) {
      case 'Müşteriler':
        return Icons.people;
      case 'Tedarikçiler':
        return Icons.business;
      case 'Malzemeler':
        return Icons.inventory_2;
      case 'Stok Durumu':
        return Icons.assessment;
      case 'Ambarlar':
        return Icons.store;
      case 'Gelen Teklifler':
      case 'Verilen Teklifler':
        return Icons.description;
      case 'Satış Siparişleri':
        return Icons.shopping_cart;
      case 'Satınalma Siparişleri':
        return Icons.shopping_bag;
      case 'Satış Faturaları':
      case 'Alış Faturaları':
        return Icons.receipt_long;
      case 'İrsaliyeler':
        return Icons.local_shipping;
      case 'Kasa İşlemleri':
        return Icons.account_balance;
      case 'Tahsilatlar':
      case 'Ödemeler':
      case 'Nakit/KK Ödeme':
      case 'Nakit Ödeme':
      case 'Kredi Kartı ile Ödeme':
        return Icons.payments;

      // Additional icons for mobile that weren't in desktop version
      case 'Firmalar':
      case 'Cari Kart Tanımları':
        return Icons.business;
      case 'Personel':
        return Icons.person;
      case 'Satış Temsilcileri':
        return Icons.groups;
      case 'Cari Hesap Hareketleri':
      case 'Cari Hesap Ekstreleri':
        return Icons.receipt_long;
      case 'Vade Analizi':
        return Icons.date_range;
      case 'Mutabakat Mektupları':
        return Icons.mail_outline;
      case 'Malzeme Tanımları':
        return Icons.inventory_2;
      case 'Hizmet Tanımları':
        return Icons.miscellaneous_services;
      case 'Stok Hareketleri':
        return Icons.move_down;
      case 'Stok Sayım İşlemleri':
        return Icons.checklist;
      case 'Ambar Transfer İşlemleri':
        return Icons.swap_horiz;
      case 'Mal Alım İrsaliyeleri':
      case 'Mal Satış İrsaliyeleri':
        return Icons.description;
      case 'Kasa Tanımları':
        return Icons.account_balance_wallet;
      case 'Tahsilat Fişleri':
        return Icons.download;
      case 'Ödeme Fişleri':
        return Icons.upload;
      case 'Virman Fişleri':
      case 'Virman Fişi':
        return Icons.swap_vert;
      case 'Banka Hesap Tanımları':
      case 'Banka İşlemleri':
        return Icons.account_balance;
      case 'Havale/EFT İşlemleri':
        return Icons.swap_horizontal_circle;
      case 'Kredi Kartı İşlemleri':
      case 'POS Tanımları':
        return Icons.credit_card;
      case 'Çek Girişi':
      case 'Firma Çekleri':
      case 'Müşteri Çekleri':
        return Icons.note;
      case 'Senet Girişi':
      case 'Firma Senetleri':
      case 'Müşteri Senetleri':
        return Icons.description;
      case 'Satınalma Faturaları':
      case 'Satın Alma':
        return Icons.shopping_basket;
      case 'İskonto Tanımları':
      case 'Kampanya Tanımları':
        return Icons.discount;

      // e-Dönüşüm related icons
      case 'e-Fatura':
      case 'e-Fatura Durum':
      case 'e-Arşiv Fatura':
        return Icons.receipt;
      case 'e-İrsaliye':
        return Icons.local_shipping;
      case 'e-Defter':
        return Icons.auto_stories;

      // Muhasebe related icons
      case 'Hesap Planı':
        return Icons.menu_book;
      case 'Muhasebe Fişleri':
        return Icons.file_copy;
      case 'Yevmiye Defteri':
      case 'Kebir Defteri':
        return Icons.book;
      case 'Mizan':
        return Icons.balance;
      case 'Finansal Tablolar':
      case 'Gelir Tablosu':
      case 'Bilanço':
        return Icons.table_chart; // Raporlama related icons
      case 'Finansal Raporlar':
      case 'Satış Raporları':
        return Icons.bar_chart;
      case 'Dashboard':
      case 'Saha Panosu':
      case 'Grafik Analizleri':
        return Icons.insights;
      case 'Bugünkü Rotam':
      case 'Rota Haritası':
      case 'Rota Optimizasyonu':
        return Icons.directions_car;
      case 'Haftalık Rota Planı':
      case 'field_sales.stubs.weekly_route_plan':
        return Icons.calendar_view_week;
      case 'Canlı Konum':
      case 'submodules.canli_konum':
        return Icons.my_location;
      case 'Araç Kamera İzleme':
      case 'submodules.arac_kamera_izleme':
        return Icons.videocam;
      case 'Araç Kamera Ayarları':
      case 'field_sales.stubs.vehicle_camera_settings':
        return Icons.video_settings;
      case 'Offline Harita İndir':
      case 'field_sales.stubs.offline_map_download':
        return Icons.download_for_offline;
      case 'Uygulama İçi Yol Tarifi':
      case 'field_sales.stubs.in_app_route_map':
        return Icons.route;
      case 'Yapay Zeka Asistanı':
        return Icons.smart_toy;
      case 'Yakındaki Müşteriler':
        return Icons.map;
      case 'Müşteri Listesi':
        return Icons.list_alt;

      // Mobile Dashboard 14 Grid Icons (Based on Logo Gap Analysis)
      case 'Favoriler':
        return Icons.star;
      case 'Yönetici':
        return Icons.manage_accounts;
      case 'Cari':
        return Icons.person;
      case 'Fatura':
        return Icons.receipt;
      case 'İrsaliye':
        return Icons.description;
      case 'Sipariş':
        return Icons.shopping_cart;
      case 'Teslimat':
        return Icons.local_shipping;
      case 'Ziyaret':
        return Icons.location_on;
      case 'Finans':
        return Icons.monetization_on;
      case 'Stok':
        return Icons.qr_code_scanner;
      case 'Raporlar':
        return Icons.bar_chart;
      case 'Döviz':
        return Icons.currency_exchange;
      case 'Şirketler':
        return Icons.business;
      case 'Güncelleme':
        return Icons.sync;
      case 'Duyurular':
        return Icons.campaign;
      case 'Diğer':
      case 'dashboard.diger':
      case 'submodules.diger':
        return Icons.more_horiz;

      default:
        return Icons.circle;
    }
  }

  /// {@template _buildFinanceContent}
  /// Finans 7 tip sheet sonrası: virman / ödeme / tahsilat (cari-önce).
  /// {@endtemplate}
  Widget _buildFinanceContent(FinanceMovementType type) {
    if (type == FinanceMovementType.virman) {
      return const VirmanScreen();
    }
    final activeVisit = ref.read(visitProvider).activeVisit;
    final visitCustomerId = activeVisit?.customerId;
    final hasCustomer =
        CollectionNotifier.isValidCustomerId(visitCustomerId);

    if (hasCustomer) {
      switch (type) {
        case FinanceMovementType.creditCardCollection:
          return CreditCardCollectionScreen(customerId: visitCustomerId);
        case FinanceMovementType.noteCollection:
          return PromissoryNoteScreen(customerId: visitCustomerId);
        case FinanceMovementType.cashOut:
        case FinanceMovementType.creditCardOut:
          return PaymentEntryScreen(
            customerId: visitCustomerId!,
            initialPaymentType: type.apiCode,
          );
        case FinanceMovementType.cashCollection:
        case FinanceMovementType.checkCollection:
          return CollectionEntryScreen(
            customerId: visitCustomerId!,
            initialPaymentType: type.apiCode,
          );
        case FinanceMovementType.virman:
          return const VirmanScreen();
      }
    }

    final purpose = switch (type.kind) {
      FinanceMovementKind.payment => CollectionSelectionPurpose.payment,
      FinanceMovementKind.collection =>
        type == FinanceMovementType.creditCardCollection
            ? CollectionSelectionPurpose.creditCard
            : type == FinanceMovementType.noteCollection
                ? CollectionSelectionPurpose.promissory
                : CollectionSelectionPurpose.collection,
      FinanceMovementKind.virman => CollectionSelectionPurpose.collection,
    };

    return CollectionCustomerSelectionScreen(
      purpose: purpose,
      initialPaymentType: type.apiCode,
    );
  }

  /// {@template _buildOrderContent}
  /// Sipariş Satış/Alış: aktif ziyaret carisi veya cari seçim ekranı.
  /// Alışta ziyaret müşterisi kullanılmaz — tedarikçi seçimi zorunlu.
  /// {@endtemplate}
  Widget _buildOrderContent(OrderType type) {
    if (type == OrderType.purchase) {
      return const OrderCustomerSelectionScreen(
        orderType: OrderType.purchase,
      );
    }
    final activeVisit = ref.read(visitProvider).activeVisit;
    final visitCustomerId = activeVisit?.customerId;
    if (OrderNotifier.isValidCustomerId(visitCustomerId)) {
      return OrderEntryScreen(
        customerId: visitCustomerId!,
        orderType: type,
      );
    }
    return OrderCustomerSelectionScreen(orderType: type);
  }

  // Helper method to open module based on title - synchronized with side_menu.dart
  Future<void> _openModule(
    BuildContext context,
    String moduleName, {
    String? route,
  }) async {
    // Seed route varsa named navigation tercih et (title-switch fallback).
    final seedRoute = (route ?? '').trim();

    // MBT: mesai başlamadan sipariş/fatura/irsaliye/tahsilat engeli.
    if (DaySalesGate.requiresOpenDay(
      moduleName: moduleName,
      route: seedRoute,
    )) {
      final dayOpen = await const DayStatusStore().isDayOpen();
      if (!dayOpen) {
        if (!context.mounted) return;
        _blockSalesUntilDayOpen(context);
        return;
      }
    }

    if (seedRoute.isNotEmpty) {
      final visitCustomerId = ref.read(visitProvider).activeVisit?.customerId;
      final args = AppRoutes.argumentsForSeedRoute(
        seedRoute,
        visitCustomerId: visitCustomerId,
      );
      Navigator.pushNamed(context, seedRoute, arguments: args);
      return;
    }

    Widget content;

    // Handle based on main categories and their submenus - same as side_menu.dart
    switch (moduleName) {
      // STOK/MALZEME related pages — MBT Detay = ürün katalogu
      case 'Malzeme Tanımları':
      case 'Malzeme Kartı Ekle':
      case 'Malzemeler':
        content = const ProductCatalogScreen();
        break;
      case 'Stok Durumu':
      case 'Stok Hareketleri':
      case 'Stok Değerleme Raporları':
      case 'Envanter Raporları':
        content = const ProductCatalogScreen();
        break;
      case 'Depo Yönetimi':
      case 'Depolar Arası Transfer':
      case 'Depo Sayım':
        content = const WarehouseManagementScreen();
        break;
      case 'Sayım Fişleri':
      case 'Sayım İşlemleri':
      case 'Sayım Raporu':
        content = const StockCountScreen();
        break;

      // CARİ HESAP related pages
      case 'Cari Kart Tanımları':
      case 'Müşteriler':
      case 'Tedarikçiler':
      case 'Personel':
      case 'Cari Hesap Hareketleri':
      case 'Cari Hesap Ekstreleri':
      case 'Cari Kart Listesi':
        content = const CustomerListScreen();
        break;

      // SİSTEM related pages
      case 'Sistem Logları':
        content = SyncLogScreen();
        break;

      // SAHA SATIŞ related pages
      case 'Saha Panosu':
        content = const DashboardScreen();
        break;
      case 'Bugünkü Rotam':
        content = const RoutePlanScreen();
        break;
      case 'Haftalık Rota Planı':
        content = const WeeklyRoutePlanScreen();
        break;
      case 'Müşteri Listesi':
        content = const CustomerListScreen();
        break;
      case 'Günlük Ciro Raporu':
      case 'Ziyaret Analizi':
        content = const LogoReportsScreen();
        break;
      case 'Araç Yükleme':
        content = const VehicleLoadingScreen();
        break;
      case 'Araç Stokları':
        content = const VehicleStockSummaryScreen();
        break;
      case 'Gün Sonu Kapanış':
        content = const EndOfDayScreen();
        break;
      case 'Yakındaki Müşteriler':
      case 'Rota Haritası':
        content = const MapScreen();
        break;
      case 'Tahsilat Girişi':
      case 'Yeni Hareket':
        // MBT: tip sheet (7) → cari-önce / virman
        final picked = await showFinanceTypeSheet(context);
        if (picked == null || !context.mounted) return;
        content = _buildFinanceContent(picked);
        break;
      case 'Nakit/KK Ödeme':
      case 'Nakit Ödeme':
      case 'Kredi Kartı ile Ödeme':
        final activePayVisit = ref.read(visitProvider).activeVisit;
        final payCustId = activePayVisit?.customerId;
        if (CollectionNotifier.isValidCustomerId(payCustId)) {
          content = PaymentEntryScreen(customerId: payCustId!);
        } else {
          content = const CollectionCustomerSelectionScreen(
            purpose: CollectionSelectionPurpose.payment,
          );
        }
        break;
      case 'Virman Fişi':
      case 'Virman Fişleri':
        content = const VirmanScreen();
        break;
      case 'Satış':
      case 'Sipariş Satış':
        content = _buildOrderContent(OrderType.sales);
        break;
      case 'Alış':
      case 'Sipariş Alış':
        content = _buildOrderContent(OrderType.purchase);
        break;
      case 'Sipariş Girişi':
        final pickedType = await showOrderTypeSheet(context);
        if (pickedType == null || !context.mounted) return;
        content = _buildOrderContent(pickedType);
        break;
      case 'Sipariş Onaylama':
        content = const OrderApprovalScreen();
        break;
      case 'Satış Faturası':
        // Plasiyer akışı: önce cari seç → sonra fatura (sipariş ile aynı).
        final activeVisitInv = ref.read(visitProvider).activeVisit;
        final visitCustInv = activeVisitInv?.customerId;
        if (InvoiceNotifier.isValidCustomerId(visitCustInv)) {
          content = InvoiceEntryScreen(customerId: visitCustInv!);
        } else {
          content = const InvoiceCustomerSelectionScreen();
        }
        break;
      case 'Toptan Satış':
        final activeVisitWs = ref.read(visitProvider).activeVisit;
        final visitCustWs = activeVisitWs?.customerId;
        if (InvoiceNotifier.isValidCustomerId(visitCustWs)) {
          content = InvoiceEntryScreen(
            customerId: visitCustWs!,
            title: 'Toptan Satış Faturası',
            invoiceType: 'Toptan Satış Faturası (8)',
          );
        } else {
          content = const InvoiceCustomerSelectionScreen(
            title: 'Toptan Satış Faturası',
            invoiceType: 'Toptan Satış Faturası (8)',
          );
        }
        break;
      case 'Toptan Satış İade':
        final activeVisitRet = ref.read(visitProvider).activeVisit;
        final visitCustRet = activeVisitRet?.customerId;
        if (InvoiceNotifier.isValidCustomerId(visitCustRet)) {
          content = InvoiceEntryScreen(
            customerId: visitCustRet!,
            title: 'Toptan Satış İade Faturası',
            invoiceType: 'Satış İade Faturası (3)',
          );
        } else {
          content = const InvoiceCustomerSelectionScreen(
            title: 'Toptan Satış İade Faturası',
            invoiceType: 'Satış İade Faturası (3)',
          );
        }
        break;
      case 'Satın Alma':
        // Fatura Satın Alma fallback (seed route yoksa).
        // İrsaliye Satın Alma seed route ile açılır.
        final activeVisitPur = ref.read(visitProvider).activeVisit;
        final visitCustPur = activeVisitPur?.customerId;
        if (InvoiceNotifier.isValidCustomerId(visitCustPur)) {
          content = InvoiceEntryScreen(
            customerId: visitCustPur!,
            title: 'Satın Alma',
            invoiceType: 'field_sales.purchase_invoice',
          );
        } else {
          content = const InvoiceCustomerSelectionScreen(
            title: 'Satın Alma',
            invoiceType: 'field_sales.purchase_invoice',
          );
        }
        break;
      case 'Geçmiş Satışlar':
      case 'Fatura Listesi':
        content = const InvoiceListScreen(customerId: '');
        break;
      case 'Yapay Zeka Asistanı':
        content = const AIAssistantScreen();
        break;
      case 'Cari Raporu':
      case 'Cari':
        content = const LogoReportsScreen();
        break;
      case 'Dönem Karşılaştırma':
        content = const PeriodComparisonReportScreen();
        break;
      case 'Yönetici Özet':
        content = const AdminKpiSummaryScreen();
        break;
      case 'Yönetici Raporları':
        content = const ManagerReportsDashboard();
        break;
      case 'Detay': // Stock detail — MBT ürün katalogu
        content = const ProductCatalogScreen();
        break;
      case 'Döviz Kuru':
      case 'Döviz Kurları':
        content = const CurrencyRatesScreen();
        break;
      case 'Veri Transferi':
      case 'Veri Güncelleme':
        content = const DataTransferScreen();
        break;
      case 'Logo REST Ayarları':
      case 'Logo API Ayarları':
        content = const LogoRestSettingsScreen();
        break;
      case 'Mobil Şirket Listesi':
        content = const CompanyListScreen();
        break;
      case 'Barkod Ekle':
        content = const BarcodeScannerScreen();
        break;
      case 'Fiyat Gör':
        content = const PriceCheckScreen();
        break;
      case 'Yeni Müşteri Ekle':
        content = const CustomerFormScreen();
        break;
      case 'Mağaza / Bölge Analizi':
      case 'Envanter ve Stok Raporu':
        content = const AdvancedAnalysisScreen();
        break;
      case 'Güne Başlama Bitirme':
        content = const DayStatusScreen();
        break;
      case 'Ambar Fişi':
        content = const WarehouseReceiptScreen();
        break;
      case 'Hedef Atama':
        content = const TargetAssignmentScreen();
        break;
      case 'Hedef Sıralaması':
        content = const LeaderboardScreen();
        break;

      case 'Bekleyen Faturalar':
      case 'Transfer Edilmeyen Faturalar':
      case 'Bekleyen Siparişler':
      case 'Bekleyen İrsaliyeler':
      case 'Transfer Edilmeyen İrsaliyeler':
      case 'Transfer Edilmeyen Tahsilatlar':
      case 'Transfer Edilmemiş Fişler':
        content = const PendingTransfersScreen();
        break;

      case 'Fiş Ön Değerleri':
        content = const SlipDefaultsScreen();
        break;

      case 'Duyurular':
        content = const AnnouncementsScreen();
        break;

      case 'Ayarlar':
        setState(() {
          _currentIndex = 3;
        });
        _pageController.jumpToPage(3);
        return;

      case 'Resimler':
        content = const GalleryScreen();
        break;

      // Default for any other pages
      default:
        content = _buildPlaceholderWrapper(
          context,
          moduleName,
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction_rounded,
                  size: 64,
                  color: Colors.grey[500],
                ),
                const SizedBox(height: 24),
                Text(
                  moduleName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalization.of(context).translate('mobile_dashboard.module_under_development'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(AppLocalization.of(context).translate('common.back')),
                ),
              ],
            ),
          ),
        );
        break;
    }

    // Yeni sayfaya geçiş yap - İçerik zaten kendi Scaffold'una sahipse direkt gönder
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => content),
    );
  }

  /// {@template _openOrderFlow}
  /// Aktif ziyaret carisi varsa [OrderEntryScreen], yoksa cari seçim.
  /// Alış siparişinde her zaman tedarikçi seçimi açılır.
  ///
  /// Parametreler:
  /// - [orderType]: Satış / Alış
  ///
  /// Dönüş değeri:
  /// - [Widget]: Açılacak sipariş ekranı
  /// {@endtemplate}
  Widget _openOrderFlow(OrderType orderType) {
    if (orderType == OrderType.purchase) {
      return const OrderCustomerSelectionScreen(
        orderType: OrderType.purchase,
      );
    }
    final activeVisit = ref.read(visitProvider).activeVisit;
    final visitCustomerId = activeVisit?.customerId;
    if (OrderNotifier.isValidCustomerId(visitCustomerId)) {
      return OrderEntryScreen(
        customerId: visitCustomerId!,
        orderType: orderType,
      );
    }
    return OrderCustomerSelectionScreen(orderType: orderType);
  }

  /// {@template _openOrderWithTypeSheet}
  /// Legacy «Sipariş Girişi»: tip sheet → cari/entry.
  ///
  /// Parametreler:
  /// - [context]: Navigasyon bağlamı
  /// {@endtemplate}
  Future<void> _openOrderWithTypeSheet(BuildContext context) async {
    final type = await showOrderTypeSheet(context);
    if (type == null || !context.mounted) return;
    final content = _openOrderFlow(type);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => content),
    );
  }

  /// Mesai kapalı: SnackBar uyarısı + Güne Başlama ekranına yönlendir.
  void _blockSalesUntilDayOpen(BuildContext context) {
    final l10n = AppLocalization.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.translate('field_sales.day_gate_required')),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pushNamed(context, DayOpenScreen.routeName);
  }

  // Yardımcı metod: Henüz geliştirme aşamasındaki modüller için standart bir Scaffold sağlar
  Widget _buildPlaceholderWrapper(BuildContext context, String moduleName, Widget body) {
    return Scaffold(
      appBar: AppBar(
        title: Text(moduleName),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }

  Widget _buildFavoriteItem(
    BuildContext context,
    String title,
    IconData icon, {
    String route = '',
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = ColorUtils.getColorForIcon(icon);

    // Try different translation namespaces
    String dashboardKey = 'dashboard.' + _getTranslationKeyForSubmenu(title);
    String translatedTitle = AppLocalization.of(context).translate(dashboardKey);

    if (translatedTitle == dashboardKey) {
      String submodulesKey = 'submodules.' + _getTranslationKeyForSubmenu(title);
      translatedTitle = AppLocalization.of(context).translate(submodulesKey);
      
      if (translatedTitle == submodulesKey) {
        translatedTitle = title;
      }
    }

    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color:
            isDarkMode ? ColorUtils.withAlpha(baseColor, 0.15) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorUtils.withAlpha(baseColor, isDarkMode ? 0.3 : 0.5),
          width: 1.0,
        ),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: ColorUtils.withAlpha(Colors.black, 0.05),
                  blurRadius: 5,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openModule(context, title, route: route),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ColorUtils.withAlpha(baseColor, 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: baseColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                translatedTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.grey[850],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get shadow styles consistent across the app
  List<BoxShadow> _getShadow(
    bool isDarkMode, {
    double blurRadius = 8,
    double spreadRadius = 0,
  }) {
    return ColorUtils.getShadow(
      isDarkMode: isDarkMode,
      blurRadius: blurRadius,
      spreadRadius: spreadRadius,
    );
  }

  // Show submenu grid for module cards
  void _showModuleSubmenuDialog(
    BuildContext context,
    String title,
    IconData icon,
    List<ModuleSubmenuItem> submenus,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = ColorUtils.getColorForIcon(icon);
    final gradientColors = ColorUtils.getGradientColorsForIcon(icon);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, sheetSetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ColorUtils.withAlpha(baseColor, 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        AppLocalization.of(context).translate(title),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(sheetContext),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: submenus.length,
                    itemBuilder: (context, index) {
                      final submenuItem = submenus[index];
                      final submenuTitle = submenuItem.title;
                      final submenuIcon = _getIconForSubmenu(submenuTitle);
                      return FutureBuilder<bool>(
                        future: _isSubmenuItemFavorite(submenuTitle),
                        builder: (context, favSnap) {
                          final isFav = favSnap.data ?? false;
                          return InkWell(
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _openModule(
                                context,
                                submenuTitle,
                                route: submenuItem.route,
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? ColorUtils.withAlpha(baseColor, 0.15)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: ColorUtils.withAlpha(
                                    baseColor,
                                    isDarkMode ? 0.3 : 0.5,
                                  ),
                                  width: 1.0,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      4,
                                      14,
                                      4,
                                      4,
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 30,
                                          height: 30,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: ColorUtils.withAlpha(
                                              baseColor,
                                              0.2,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            submenuIcon,
                                            color: baseColor,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: Builder(
                                              builder: (context) {
                                                final translationKey =
                                                    'submodules.' +
                                                        _getTranslationKeyForSubmenu(
                                                          submenuTitle,
                                                        );
                                                String translatedTitle =
                                                    AppLocalization.of(
                                                  context,
                                                ).translate(translationKey);

                                                if (translatedTitle ==
                                                    translationKey) {
                                                  translatedTitle =
                                                      submenuTitle;
                                                }

                                                return Text(
                                                  translatedTitle,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    height: 1.15,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.grey[800],
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () async {
                                        await _toggleFavoriteSubmenuItem(
                                          submenuTitle,
                                          submenuIcon,
                                          !isFav,
                                        );
                                        sheetSetState(() {});
                                        if (mounted) setState(() {});
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          isFav
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 14,
                                          color: isFav
                                              ? _kFavoriteHeartColor
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    List<ModuleSubmenuItem>? submenus,
    int menuId = 0,
    bool isFavorite = false,
    bool showFavoriteHeart = true,
    /// Opsiyonel sayaç (ör. Duyurular dens adedi). Verilirse alt menü
    /// uzunluğu yerine bu değer badge'de gösterilir.
    int? badgeCount,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = ColorUtils.getColorForIcon(icon);
    final hasSubmenus = submenus != null && submenus.isNotEmpty;
    final int? displayBadge =
        badgeCount ?? (hasSubmenus ? submenus!.length : null);

    // Önce SQLite key / fs_* çözümle; sonra legacy dashboard.* fallback
    final l10n = AppLocalization.of(context);
    String translatedTitle =
        MenuService.resolveStoredMenuTitle(title, l10n: l10n);
    final stillRawKey = translatedTitle.contains('.') ||
        translatedTitle.startsWith('fs_') ||
        translatedTitle.startsWith('sub_');
    if (stillRawKey) {
      final dashboardKey =
          'dashboard.' + _getTranslationKeyForSubmenu(title);
      final viaDash = l10n.translate(dashboardKey);
      if (viaDash != dashboardKey) {
        translatedTitle = viaDash;
      }
    }
    String translatedSubtitle = l10n.translate(subtitle);
    if (translatedSubtitle == subtitle) {
      translatedSubtitle = subtitle;
    }

    return InkWell(
      onTap: onTap ??
          () {
            if (hasSubmenus) {
              _showModuleSubmenuDialog(context, title, icon, submenus);
            }
          },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDarkMode ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ColorUtils.withAlpha(baseColor, 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: baseColor, size: 20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  translatedTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  translatedSubtitle,
                  style: TextStyle(
                    fontSize: 8,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (displayBadge != null && displayBadge > 0)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorUtils.withAlpha(baseColor, 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$displayBadge',
                    style: TextStyle(
                      color: baseColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (showFavoriteHeart)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggleFavoriteByMenuId(
                    menuId: menuId,
                    title: title,
                    icon: icon,
                    shouldAdd: !isFavorite,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 14,
                      color: isFavorite
                          ? _kFavoriteHeartColor
                          : (isDarkMode ? Colors.grey[400] : Colors.grey[500]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsScreen(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            AppLocalization.of(context).translate('mobile_dashboard.settings'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Tema değiştirme (açık / koyu)
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: isDarkMode ? colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _getShadow(isDarkMode),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ref.read(themeModeProvider.notifier).toggleThemeMode();
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ColorUtils.withAlpha(
                            colorScheme.primary,
                            0.15,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.light_mode,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalization.of(
                                context,
                              ).translate('settings.theme'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              isDarkMode 
                                ? AppLocalization.of(context).translate('settings.dark_theme') 
                                : AppLocalization.of(context).translate('settings.light_theme'),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Font büyüklüğü + tema rengi
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: isDarkMode ? colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _getShadow(isDarkMode),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppearanceSettingsScreen.routeName,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ColorUtils.withAlpha(
                            colorScheme.primary,
                            0.15,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.text_fields,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalization.of(context)
                                  .translate('settings.appearance'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              AppLocalization.of(context)
                                  .translate('settings.appearance_desc'),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Rapor PDF logosu
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: isDarkMode ? colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _getShadow(isDarkMode),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    ReportLogoSettingsScreen.routeName,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ColorUtils.withAlpha(
                            colorScheme.primary,
                            0.15,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.image_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalization.of(context)
                                  .translate('settings.report_logo'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              AppLocalization.of(context)
                                  .translate('settings.report_logo_desc'),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Slip Defaults (Fiş Ön Değerleri) / Printer Settings
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: isDarkMode ? colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _getShadow(isDarkMode),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _openModule(context, 'Fiş Ön Değerleri');
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ColorUtils.withAlpha(
                            colorScheme.secondary,
                            0.15,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.print_outlined,
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalization.of(context).translate('settings.slip_defaults'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              AppLocalization.of(context).translate('settings.printer_settings_desc'),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),
          const AppVersionLabel(),
          const SizedBox(height: 8),

          // Logout butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: Text(
                AppLocalization.of(context).translate('settings.logout'),
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _handleLogout(context),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Logout işlemini gerçekleştir
  Future<void> _handleLogout(BuildContext context) async {
    final pendingGuard = const PendingTransferGuard();
    final decision = await pendingGuard.evaluate(
      PendingTransferAction.logout,
    );
    if (!context.mounted) return;

    if (decision.shouldInterrupt) {
      final pendingResult = await showPendingTransferGuardDialog(
        context: context,
        decision: decision,
      );
      if (!context.mounted) return;
      switch (pendingResult) {
        case PendingTransferDialogResult.openList:
          await Navigator.pushNamed(
            context,
            InvoicesUntransferredScreen.routeName,
          );
          return;
        case PendingTransferDialogResult.cancel:
          return;
        case PendingTransferDialogResult.forceProceed:
          break;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalization.of(context).translate('settings.logout_confirm_title')),
        content: Text(AppLocalization.of(context).translate('settings.logout_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalization.of(context).translate('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // AuthService kullanarak çıkış yap
              AuthService.logout(context);
            },
            child: Text(AppLocalization.of(context).translate('common.yes'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Favoriler kartı mı? (kalp yok; sheet açar)
  /// Rol → ana sayfa modül kartları.
  List<ModuleCardData> _filterModuleCardsForRole(
    List<ModuleCardData> cards,
    AppUserRole role,
  ) {
    final filtered = RoleHomeMenuFilter.filterByMainUuid(
      role: role,
      items: cards,
      uuidOf: (c) => c.uuid,
    );
    return filtered
        .map(
          (c) => ModuleCardData(
            id: c.id,
            uuid: c.uuid,
            title: c.title,
            subtitle: c.subtitle,
            icon: c.icon,
            isFavorite: c.isFavorite,
            submenus: c.submenus
                .where(
                  (s) => RoleHomeMenuFilter.allowsSubMenuUuid(
                    role: role,
                    parentUuid: c.uuid,
                    subUuid: s.uuid,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  /// Rol → menü sekmesi ana öğeleri.
  List<MenuItemData> _filterMenuItemsForRole(
    List<MenuItemData> items,
    AppUserRole role,
  ) {
    return RoleHomeMenuFilter.filterByMainUuid(
      role: role,
      items: items,
      uuidOf: (m) => m.uuid,
    );
  }

  /// Rol → alt menü listesi.
  List<SubMenuItemData> _filterSubMenusForRole(
    List<SubMenuItemData> items, {
    required String parentUuid,
    required AppUserRole role,
  }) {
    if (role.seesFullMenu) return items;
    return items
        .where(
          (s) => RoleHomeMenuFilter.allowsSubMenuUuid(
            role: role,
            parentUuid: parentUuid,
            subUuid: s.uuid,
          ),
        )
        .toList();
  }

  bool _isFavoritesModuleTitle(String title, [String? localizedFavoriler]) {
    final raw = title.trim();
    final t = raw.toLowerCase();
    if (t == 'favoriler' || t == 'favorites') return true;
    if (t == 'fs_favorites' || t.endsWith('.fs_favorites')) return true;
    if (localizedFavoriler != null &&
        raw == localizedFavoriler.trim()) {
      return true;
    }
    return false;
  }

  /// {@template mobile_dashboard_is_module_title_match}
  /// Çözülmüş / legacy TR / uuid-as-title eşlemesi.
  /// {@endtemplate}
  bool _isModuleTitleMatch(
    String title, {
    String? localized,
    List<String> legacyTr = const [],
    List<String> uuids = const [],
  }) {
    final raw = title.trim();
    if (localized != null && raw == localized.trim()) return true;
    for (final t in legacyTr) {
      if (raw == t) return true;
    }
    final lower = raw.toLowerCase();
    for (final u in uuids) {
      if (lower == u.toLowerCase() || lower.endsWith('.${u.toLowerCase()}')) {
        return true;
      }
    }
    return false;
  }

  /// Menu id ile favori ekle/çıkar (kart köşesi kalp)
  Future<void> _toggleFavoriteByMenuId({
    required int menuId,
    required String title,
    required IconData icon,
    required bool shouldAdd,
  }) async {
    try {
      var id = menuId;
      if (id <= 0) {
        final db = await DatabaseService.getInstance();
        final items = await db.getMenuItemByTitle(title);
        if (items.isEmpty) return;
        id = items.first['id'] as int;
      }
      await MenuService.toggleFavoriteMenuItem(id, shouldAdd);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shouldAdd
                ? AppLocalization.of(context).translate(
                    'mobile_dashboard.favorites_added',
                    args: {'title': title},
                  )
                : AppLocalization.of(context).translate(
                    'mobile_dashboard.favorites_removed',
                    args: {'title': title},
                  ),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalization.of(context).translate('common.error')}: $e',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// MBT: yalnızca favori modülleri gösteren dens bottom sheet
  void _showFavoritesSheet(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, sheetSetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalization.of(context)
                                .translate('mobile_dashboard.favorites'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: AppLocalization.of(context)
                              .translate('mobile_dashboard.favorites'),
                          icon: Icon(
                            Icons.open_in_new,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            Navigator.pushNamed(
                              context,
                              FavoritesScreen.routeName,
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(sheetContext),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: FutureBuilder<List<FavoriteItemData>>(
                      future: MenuService.getMobileFavoriteItems(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final items = snapshot.data ?? <FavoriteItemData>[];
                        if (items.isEmpty) {
                          return Center(
                            child: Text(
                              AppLocalization.of(context).translate(
                                'mobile_dashboard.no_favorites',
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          );
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.all(10),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.90,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final baseColor =
                                ColorUtils.getColorForIcon(item.icon);
                            String label = MenuService.resolveStoredMenuTitle(
                              item.title,
                              l10n: AppLocalization.of(context),
                            );
                            final stillRaw = label.contains('.') ||
                                label.startsWith('fs_') ||
                                label.startsWith('sub_');
                            if (stillRaw) {
                              if (item.title.contains('.')) {
                                label = AppLocalization.of(context)
                                    .translate(item.title);
                                if (label == item.title) {
                                  label = item.title.split('.').last;
                                }
                              } else {
                                String dashKey = 'dashboard.' +
                                    _getTranslationKeyForSubmenu(item.title);
                                label = AppLocalization.of(context)
                                    .translate(dashKey);
                                if (label == dashKey) {
                                  final subKey = 'submodules.' +
                                      _getTranslationKeyForSubmenu(item.title);
                                  label = AppLocalization.of(context)
                                      .translate(subKey);
                                  if (label == subKey) label = item.title;
                                }
                              }
                            }
                            return InkWell(
                              onTap: () async {
                                Navigator.pop(sheetContext);
                                var route = item.route;
                                if (route.trim().isEmpty) {
                                  try {
                                    final subs =
                                        await MenuService.getSubMenuItems(
                                      item.title,
                                    );
                                    if (subs.isNotEmpty) {
                                      route = subs.first.route;
                                    }
                                  } catch (_) {}
                                }
                                if (!mounted) return;
                                _openModule(
                                  context,
                                  item.title,
                                  route: route,
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? ColorUtils.withAlpha(baseColor, 0.15)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: ColorUtils.withAlpha(
                                      baseColor,
                                      isDarkMode ? 0.3 : 0.5,
                                    ),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          item.icon,
                                          color: baseColor,
                                          size: 22,
                                        ),
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          child: Text(
                                            label,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () async {
                                          await _toggleFavoriteByMenuId(
                                            menuId: 0,
                                            title: item.title,
                                            icon: item.icon,
                                            shouldAdd: false,
                                          );
                                          sheetSetState(() {});
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.favorite,
                                            size: 14,
                                            color: _kFavoriteHeartColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Sık kullanılanlar düzenleme dialog'unu göster
  void _showFavoriteMenuDialog(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Mevcut sık kullanılanları al
    final currentFavorites = await MenuService.getFavoriteMenuItems();

    // Tüm menü öğelerini al
    final mainMenuItems = await MenuService.getMainMenuItems();

    // Alt menü öğelerini topla
    final allMenuItems = <MenuItemWithSubmenus>{};

    // Ana menüleri listeye ekle
    for (var menu in mainMenuItems) {
      allMenuItems.add(
        MenuItemWithSubmenus(
          id: menu.id,
          title: menu.title,
          icon: menu.icon,
          isFavorite: menu.isFavorite,
          submenus: menu.submenus,
        ),
      );

      // Alt menüleri de ekle
      final subMenuData = await MenuService.getSubMenuItems(menu.title);
      for (var subMenu in subMenuData) {
        // Veritabanında alt menüye ait ID'yi bul
        final db = await DatabaseService.getInstance();
        final items = await db.getMenuItemByTitle(subMenu.title);
        if (items.isNotEmpty) {
          final item = items.first;
          final menuId = item['id'] as int;
          final isFav = item['is_favorite'] != null && item['is_favorite'] == 1;

          allMenuItems.add(
            MenuItemWithSubmenus(
              id: menuId,
              title: subMenu.title,
              icon: subMenu.icon,
              isFavorite: isFav,
              parentTitle: menu.title,
            ),
          );
        }
      }
    }

    // Seçilen menü ID'lerini tut
    final selectedMenuIds = <int>[];
    for (var fav in currentFavorites) {
      selectedMenuIds.add(fav.id);
    }

    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor:
                isDarkMode ? const Color(0xFF1F1B24) : Colors.white,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog başlığı
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalization.of(
                          context,
                        ).translate('mobile_dashboard.edit_favorites'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context, false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bilgi metni
                  Text(
                    AppLocalization.of(
                      context,
                    ).translate('mobile_dashboard.select_favorites'),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Menü listesi
                  Expanded(
                    child: ListView.builder(
                      itemCount: allMenuItems.length,
                      itemBuilder: (context, index) {
                        final menuItem = allMenuItems.elementAt(index);
                        final bool isSelected = selectedMenuIds.contains(
                          menuItem.id,
                        );

                        // Ana menü başlığı
                        if (menuItem.parentTitle == null) {
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: 4.0,
                                  ),
                                  child: Text(
                                    menuItem.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const Divider(height: 1),
                              ],
                            ),
                          );
                        }

                        // Alt menü öğesi
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ColorUtils.withAlpha(
                                    colorScheme.primary,
                                    isDarkMode ? 0.2 : 0.1,
                                  )
                                : isDarkMode
                                    ? Colors.grey[800]!.withOpacity(0.3)
                                    : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: colorScheme.primary,
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              dialogSetState(() {
                                if (value == true) {
                                  if (!selectedMenuIds.contains(
                                    menuItem.id,
                                  )) {
                                    selectedMenuIds.add(menuItem.id);
                                  }
                                } else {
                                  selectedMenuIds.remove(menuItem.id);
                                }
                              });
                            },
                            title: Text(
                              menuItem.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              menuItem.parentTitle ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            secondary: Icon(
                              menuItem.icon,
                              color: isSelected
                                  ? colorScheme.primary
                                  : (isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[700]),
                            ),
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            activeColor: colorScheme.primary,
                            checkColor: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),

                  // Kaydet butonu
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Seçilen menüleri güncelle
                        await MenuService.updateFavoriteMenuItems(
                          selectedMenuIds,
                        );

                        // Önbelleği temizle
                        MenuService.clearCache();

                        // Dialog'u kapat
                        if (context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalization.of(
                          context,
                        ).translate('common.save'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((result) {
      // Dialog kapandıktan sonra UI'ı yenile
      if (result == true) {
        // Tüm widget'ı yeniden oluştur
        setState(() {
          // Durum değişikliği ile yeniden çizim tetiklenir
        });

        // Hemen yenilenmezse küçük bir gecikme ekleyelim
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {});
          }
        });
      }
    });
  }

  Widget _buildDailySummary(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _getShadow(isDarkMode, blurRadius: 10),
        gradient: isDarkMode ? null : LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppLocalization.of(context).translate('mobile_dashboard.$_selectedPeriod')} ${AppLocalization.of(context).translate('mobile_dashboard.summary')}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              Icon(Icons.trending_up, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          // Period Selection
          Row(
            children: [
              _buildPeriodChip(context, 'daily'),
              const SizedBox(width: 8),
              _buildPeriodChip(context, 'weekly'),
              const SizedBox(width: 8),
              _buildPeriodChip(context, 'monthly'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryItem(
                context, 
                ' 2.345', 
                l10n.translate('mobile_dashboard.summary_sales'), 
                Icons.shopping_bag_outlined, 
                Colors.blue
              ),
              const SizedBox(width: 12),
              _buildSummaryItem(
                context, 
                '12/15', 
                l10n.translate('mobile_dashboard.summary_visits'), 
                Icons.location_on_outlined, 
                Colors.orange
              ),
              const SizedBox(width: 12),
              _buildSummaryItem(
                context, 
                ' 1.200', 
                l10n.translate('mobile_dashboard.summary_collections'), 
                Icons.payments_outlined, 
                Colors.green
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Target Progress Bar
          _buildTargetProgress(context),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(BuildContext context, String period) {
    final isActive = _selectedPeriod == period;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive 
              ? colorScheme.primary 
              : (isDarkMode ? Colors.grey[850] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          AppLocalization.of(context).translate('mobile_dashboard.$period'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive 
                ? Colors.white 
                : (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildTargetProgress(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Mock target data based on period
    double progress = 0.75;
    if (_selectedPeriod == 'weekly') progress = 0.60;
    if (_selectedPeriod == 'monthly') progress = 0.45;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalization.of(context).translate('mobile_dashboard.target_achievement'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              '%${(progress * 100).toInt()}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, 
    String value, 
    String label, 
    IconData icon, 
    Color color
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Menü öğesi sınıfı
class MenuItemWithSubmenus {
  final int id;
  final String title;
  final IconData icon;
  final bool isFavorite;
  final List<String>? submenus;
  final String? parentTitle;

  MenuItemWithSubmenus({
    required this.id,
    required this.title,
    required this.icon,
    required this.isFavorite,
    this.submenus,
    this.parentTitle,
  });
}
