import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logo_widget.dart';
import 'dashboard_screen.dart';
import 'mobile_dashboard.dart';
import '../tools/menu_fixer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'numeric_keyboard.dart';
import '../service/database_service.dart';

import '../core/utils/color_utils.dart';
import '../core/localization/app_localization.dart';
import '../core/utils/directional_text.dart';
import '../modules/admin_panel/admin_panel_screen.dart';
import 'settings_screen.dart';
import 'settings/sync_management_screen.dart';
import 'device_registration_screen.dart';
import '../core/services/device_service.dart';
import '../core/services/device_registration_service.dart';
import 'dart:async';
import '../service/auth_service.dart';
import '../service/theme_service.dart';

import '../service/language_service.dart';
import '../core/tenant/postgrest_tenant_service.dart';
import '../core/tenant/postgrest_http_client.dart';
import '../core/tenant/postgrest_master_sync.dart';
import '../core/logo/logo_tiger_startup_pull.dart';
import '../core/tenant/postgrest_table_names.dart';
import '../core/tenant/saas_origin_override_dialog.dart';
import '../core/tenant/tenant_store.dart';
import '../service/postgres_service.dart';
import 'widgets/login_tenant_code_chip.dart';
import '../modules/field_sales/companies/model/active_company_session.dart';
import '../modules/field_sales/companies/viewmodel/active_company_store.dart';
import '../modules/field_sales/stock/model/active_warehouse_session.dart';
import '../modules/field_sales/stock/model/warehouse_master_seed.dart';
import '../modules/field_sales/stock/viewmodel/active_warehouse_store.dart';
import '../core/auth/remember_me_session.dart';
import '../core/auth/remember_me_store.dart';
import '../modules/admin_panel/admin_password_dialog.dart'
    show showAdminPasswordDialog;
import 'package:http/http.dart' as http;

export 'login_screen.dart' show showForceLogoutDialog;

// Firma modeli eklendi
class Company {
  final String id;
  final String name;
  final String? companyNo;
  final String? description;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;
  bool isSelected;

  Company({
    required this.id,
    required this.name,
    this.companyNo,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.isSelected = false,
  });
}

// EXFIN Renkleri
const Color exfinDarkBlue = Color.fromARGB(255, 5, 79, 153); // Koyu lacivert
const Color exfinRed = Color(0xFFFF0000); // Tam kırmızı renk
const Color exfinLightBlue = Color(0xFF3498DB); // Açık mavi
// Yeni modern renkler
const Color surfaceColor = Color(0xFFF9FAFB);
const Color textColorPrimary = Color(0xFF1F2937);
const Color textColorSecondary = Color(0xFF6B7280);

// Dışarıda tanımlanan debug loglama fonksiyonu
void debugLog(String message) {
  print('EXFIN-LOGIN: $message');
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  /// Form ↔ yarım ay (tema) yanı dens kiracı butonu köprüsü
  final ValueNotifier<LoginTenantChipData> _tenantChip =
      ValueNotifier(const LoginTenantChipData());

  /// Formun kayıt ettiği Değiştir / düzenle aksiyonu
  VoidCallback? _tenantHeaderAction;

  @override
  void dispose() {
    _tenantChip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // 1. Top Left Small Blue Blur
          Positioned(
            top: 20,
            left: -20,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ColorUtils.withAlpha(exfinDarkBlue, 0.25),
                    ColorUtils.withAlpha(exfinDarkBlue, 0.0),
                  ],
                ),
              ),
            ),
          ),
          
          // 2. Center Top Light Blue Blur (Behind Logo)
          Positioned(
            top: screenHeight * 0.1,
            left: screenWidth * 0.2,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ColorUtils.withAlpha(exfinLightBlue, 0.25),
                    ColorUtils.withAlpha(exfinLightBlue, 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 3. Middle Left Light Blue Blur
          Positioned(
            top: screenHeight * 0.25,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ColorUtils.withAlpha(exfinLightBlue, 0.20),
                    ColorUtils.withAlpha(exfinLightBlue, 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 4. Center Right Red Blur (Behind Logo Area)
          Positioned(
            top: screenHeight * 0.15,
            right: -20,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ColorUtils.withAlpha(exfinRed, 0.15),
                    ColorUtils.withAlpha(exfinRed, 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 5. Middle Right Blue Blur
          Positioned(
            top: screenHeight * 0.35,
            right: 0,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ColorUtils.withAlpha(exfinDarkBlue, 0.20),
                    ColorUtils.withAlpha(exfinDarkBlue, 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 6. Center Burst Very Light Blue Blur
          Positioned(
            top: screenHeight * 0.05,
            left: screenWidth * 0.1,
            child: Container(
              width: screenWidth * 0.8,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(150),
                gradient: RadialGradient(
                  colors: [
                    ColorUtils.withAlpha(exfinLightBlue, 0.15),
                    ColorUtils.withAlpha(exfinLightBlue, 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    children: [
                      // Logo & Slogan section
                      Container(
                        margin: EdgeInsets.only(
                          top: isSmallScreen ? 10 : 20,
                          bottom: 10, // Minimal gap before the card
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ExfinLogo(height: isSmallScreen ? 80 : 120), // Adjusted size for cropped logo
                            AnimatedLoginSlogan(
                              isDarkMode: isDarkMode,
                              isSmallScreen: isSmallScreen,
                            ),
                          ],
                        ),
                      ),

                      // Login card
                      Container(
                        width: isSmallScreen ? double.infinity : 400,
                        constraints: const BoxConstraints(maxWidth: 450),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode 
                                  ? Colors.transparent 
                                  : ColorUtils.withAlpha(Colors.black, 0.06),
                              blurRadius: 40,
                              spreadRadius: 0,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Welcome text ve simgeler bir arada:
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(children: [
                                  // Bina + minimal kiracı kodu (üst ikon çubuğu)
                                  ValueListenableBuilder<LoginTenantChipData>(
                                    valueListenable: _tenantChip,
                                    builder: (context, data, _) {
                                      if (!data.visible) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        child: LoginTenantCodeChip(
                                          tenantCode: data.tenantCode,
                                          busy: data.busy,
                                          onPressed: () =>
                                              _tenantHeaderAction?.call(),
                                        ),
                                      );
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: IconButton(
                                      icon: Icon(
                                        isDarkMode
                                            ? Icons.brightness_7
                                            : Icons.brightness_2,
                                        size: 24,
                                        color: exfinDarkBlue,
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(themeModeProvider.notifier)
                                            .toggleThemeMode();
                                      },
                                      tooltip: isDarkMode
                                          ? 'Aydınlık Mod'
                                          : 'Karanlık Mod',
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: IconButton(
                                      icon: Icon(Icons.language,
                                          size: 24, color: exfinDarkBlue),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: Theme.of(context).cardColor,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18)),
                                            title: Center(
                                              child: Text(
                                                'Dil',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  color: isDarkMode ? Colors.white : exfinDarkBlue,
                                                ),
                                              ),
                                            ),
                                            content: SizedBox(
                                              width: 280,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: LanguageService
                                                    .supportedLanguages
                                                    .map((lang) {
                                                  final isSelected = ref
                                                          .watch(localeProvider)
                                                          .languageCode ==
                                                      lang.code;
                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 4.0),
                                                    child: Material(
                                                      color: isSelected
                                                          ? exfinDarkBlue
                                                              .withOpacity(0.08)
                                                          : isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        onTap: () async {
                                                          if (!isSelected) {
                                                            ref
                                                                .read(localeProvider
                                                                    .notifier)
                                                                .setLocale(
                                                                    Locale(lang
                                                                        .code));
                                                            await LanguageService
                                                                .setLanguagePreference(
                                                                    lang.code);
                                                            Navigator.pop(
                                                                context);
                                                          }
                                                        },
                                                        child: ListTile(
                                                          leading: _buildFlag(
                                                              lang.code),
                                                          title: Text(
                                                            lang.localName,
                                                            style: TextStyle(
                                                              color: isSelected
                                                                  ? exfinDarkBlue
                                                                  : (isDarkMode ? Colors.white : Colors.black87),
                                                              fontWeight: isSelected
                                                                  ? FontWeight
                                                                      .bold
                                                                  : FontWeight
                                                                      .normal,
                                                            ),
                                                          ),
                                                          trailing: isSelected
                                                              ? Icon(
                                                                  Icons
                                                                      .check_circle,
                                                                  color:
                                                                      exfinDarkBlue)
                                                              : null,
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      8),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
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
                                      tooltip: 'Ayarlar',
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: IconButton(
                                      icon: Icon(Icons.settings,
                                          size: 24, color: exfinDarkBlue),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: Theme.of(context).cardColor,
                                            shape:
                                                const RoundedRectangleBorder(),
                                            title: Center(
                                              child: Text(
                                                'Ayarlar',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDarkMode ? Colors.white : exfinDarkBlue,
                                                ),
                                              ),
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.zero,
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              const SettingsScreen(),
                                                        ),
                                                      );
                                                    },
                                                    child: ListTile(
                                                      leading: const Icon(
                                                          Icons.cloud,
                                                          color: Colors
                                                              .blueAccent),
                                                      title: const Text(
                                                          'Sunucu Ayarları'),
                                                      trailing: const Icon(
                                                          Icons.chevron_right),
                                                    ),
                                                  ),
                                                ),
                                                const Divider(height: 1),
                                                Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.zero,
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              const SyncManagementScreen(),
                                                        ),
                                                      );
                                                    },
                                                    child: ListTile(
                                                      leading: const Icon(
                                                          Icons.sync,
                                                          color: Colors.teal),
                                                      title: const Text(
                                                          'Veri Senkronizasyonu'),
                                                      trailing: const Icon(
                                                          Icons.chevron_right),
                                                    ),
                                                  ),
                                                ),
                                                const Divider(height: 1),
                                                Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.zero,
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              DeviceRegistrationScreen(),
                                                        ),
                                                      );
                                                    },
                                                    child: ListTile(
                                                      leading: const Icon(
                                                          Icons.verified_user,
                                                          color: Colors.green),
                                                      title: const Text(
                                                          'Cihaz Kayıt İşlemi'),
                                                      trailing: const Icon(
                                                          Icons.chevron_right),
                                                    ),
                                                  ),
                                                ),
                                                const Divider(height: 1),
                                                Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.zero,
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      // TODO(Ferhat NAS): Printer/Kamera ayar ekranı eklenecek
                                                    },
                                                    child: ListTile(
                                                      leading: const Icon(
                                                          Icons.print,
                                                          color: Colors
                                                              .deepPurple),
                                                      title: const Text(
                                                          'Printer/Kamera'),
                                                      trailing: const Icon(
                                                          Icons.chevron_right),
                                                    ),
                                                  ),
                                                ),
                                                const Divider(height: 1),
                                                Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.zero,
                                                    onTap: () async {
                                                      Navigator.pop(context);
                                                      final ok =
                                                          await showSaasOriginOverrideDialog(
                                                        context,
                                                      );
                                                      if (ok && context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              AppLocalization.of(
                                                                context,
                                                              ).translate(
                                                                'auth.saas_origin_saved',
                                                              ),
                                                            ),
                                                            duration:
                                                                const Duration(
                                                              seconds: 2,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: ListTile(
                                                      leading: const Icon(
                                                        Icons.dns_outlined,
                                                        color: Colors.indigo,
                                                      ),
                                                      title: Text(
                                                        AppLocalization.of(
                                                          context,
                                                        ).translate(
                                                          'auth.saas_origin_menu',
                                                        ),
                                                      ),
                                                      trailing: const Icon(
                                                        Icons.chevron_right,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const Divider(height: 1),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8.0),
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: TextButton(
                                                      style:
                                                          TextButton.styleFrom(
                                                        foregroundColor:
                                                            Colors.red,
                                                        backgroundColor: Colors
                                                            .red
                                                            .withOpacity(0.08),
                                                        shape:
                                                            const RoundedRectangleBorder(),
                                                      ),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child:
                                                          const Text('VAZGEÇ'),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      tooltip: 'Ayarlar',
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: IconButton(
                                      icon: Icon(Icons.admin_panel_settings,
                                          size: 24, color: exfinDarkBlue),
                                      onPressed: () async {
                                        final result =
                                            await showAdminPasswordDialog(
                                                context);
                                        if (result == true) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const AdminPanelScreen()),
                                          );
                                        }
                                      },
                                      tooltip: 'Admin Paneli',
                                    ),
                                  ),
                                ]),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DirectionalLocalizedText(
                              'auth.login_to_account',
                              style: TextStyle(
                                fontSize: 14,
                                color: textColorSecondary,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Login form
                            ExfinLoginForm(
                              exfinRed: exfinRed,
                              ref: ref,
                              tenantChip: _tenantChip,
                              onRegisterHeaderAction: (action) {
                                _tenantHeaderAction = action;
                              },
                            ),
                          ],
                        ),
                      ),

                      // Footer
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExfinLoginForm extends StatefulWidget {
  final Color exfinRed;
  final WidgetRef ref;

  /// Yarım ay yanı dens kiracı butonu durumu
  final ValueNotifier<LoginTenantChipData>? tenantChip;

  /// Header butonuna Değiştir aksiyonunu kaydet
  final void Function(VoidCallback action)? onRegisterHeaderAction;

  const ExfinLoginForm({
    Key? key,
    required this.exfinRed,
    required this.ref,
    this.tenantChip,
    this.onRegisterHeaderAction,
  }) : super(key: key);

  @override
  State<ExfinLoginForm> createState() => _ExfinLoginFormState();
}

class _ExfinLoginFormState extends State<ExfinLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _tenantCodeController = TextEditingController();
  final _tenantFocusNode = FocusNode();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showKeyboard = false;
  bool _cihazOnayli = false;
  bool _cihazKontrolEdildi = false;
  String? _cihazSeriNo;
  bool _maxUserLimit = false;
  bool _forceLogout = true;
  bool _debugRefreshing = false;
  bool _isForceLoginRetry = false;
  int _loginCountdown = 0;
  Timer? _loginCountdownTimer;

  /// Kayıtlı kiracı varsa kilitli (RetailEX: Değiştir ile açılır)
  bool _tenantLocked = false;

  /// Prefs kiracı yüklemesi bitti mi
  bool _tenantLoadDone = false;

  /// Kiracı Bağlan tamamlandı → login formu açılır
  bool _tenantGatePassed = false;

  /// Kiracı bağlanırken (firma/dönem çekimi)
  bool _tenantConnecting = false;

  // Firma değişkeni
  Company? _selectedCompany;
  List<Company> _companies = [];
  StreamSubscription<List<Map<String, dynamic>>>? _companyStreamSub;
  String _selectedPeriodNo = '01';
  String _selectedPeriodStart = '';
  String _selectedPeriodEnd = '';
  List<PostgrestPeriodRow> _periods = const [];
  PostgrestPeriodRow? _selectedPeriod;
  List<WarehouseMasterSeedRow> _warehouses = WarehouseMasterSeed.defaultRows;
  WarehouseMasterSeedRow? _selectedWarehouse;
  http.Client? _httpClient;

  @override
  void initState() {
    super.initState();
    widget.onRegisterHeaderAction?.call(_onHeaderTenantTap);
    _initializeDbAndLoad();
    _usernameController.addListener(_onUsernameChanged);
    // İlk açılışta kullanıcı adı varsa stream başlat
    if (_usernameController.text.trim().isNotEmpty) {
      _subscribeToCompanyStreamByUsername(_usernameController.text.trim());
    }
  }

  /// Header bina chip: kayıtlıysa Değiştir+dialog; değilse kod girişi dialog.
  void _onHeaderTenantTap() {
    if (_isLoading || _tenantConnecting) return;
    if (_tenantGatePassed &&
        _tenantCodeController.text.trim().isNotEmpty) {
      unawaited(_onChangeTenant());
    } else {
      unawaited(_openTenantEditDialog());
    }
  }

  /// Parent ValueNotifier ile yarım ay yanı butonu senkronu.
  void _syncTenantChip() {
    widget.tenantChip?.value = LoginTenantChipData(
      tenantCode: _tenantCodeController.text,
      gatePassed: _tenantGatePassed,
      loadDone: _tenantLoadDone,
      busy: _tenantConnecting,
    );
  }

  void _onUsernameChanged() {
    final username = _usernameController.text.trim();
    if (username.isNotEmpty) {
      _subscribeToCompanyStreamByUsername(username);
    } else if (_tenantCodeController.text.trim().isNotEmpty) {
      _loadFirmsFromPostgrest();
    } else {
      _companyStreamSub?.cancel();
      setState(() {
        _companies = [];
        _selectedCompany = null;
      });
    }
  }

  http.Client get _client {
    return _httpClient ??= http.Client();
  }

  /// Kiracı PostgREST `/firms` (+ kullanıcı firm_nr yedek).
  Future<void> _loadFirmsFromPostgrest({
    String? preferFirmNr,
    List<String> allowedFirmNrs = const [],
  }) async {
    final tenant = _tenantCodeController.text.trim();
    if (tenant.isEmpty) return;
    try {
      final apply = await PostgrestTenantService(
        httpClient: _client,
      ).applyTenantCode(tenant);
      if (!apply.ok) return;

      final sync = PostgrestMasterSync(
        client: PostgrestHttpClient(httpClient: _client),
      );
      final firms = await sync.fetchFirms(
        preferFirmNr: preferFirmNr,
        allowedFirmNrs: allowedFirmNrs,
      );
      if (!mounted) return;
      if (firms.isEmpty) {
        // Ağ yok / boş: demo satırı bırakma — kullanıcıya seçim için
        // sentetik yoksa mevcut mock'a düşme.
        return;
      }
      final companies = firms
          .map(
            (f) => Company(
              id: f.id,
              name: f.name,
              companyNo: f.firmNr,
              description: 'firm_nr=${f.firmNr}',
              isActive: f.isActive,
            ),
          )
          .toList();
      setState(() {
        _companies = companies;
        _selectedCompany = companies.isNotEmpty ? companies.first : null;
      });
      if (_selectedCompany != null) {
        await _loadPeriodForSelectedCompany();
        await _loadWarehouses();
      }
    } catch (e) {
      debugPrint('Firma listesi PostgREST: $e');
    }
  }

  Future<void> _loadPeriodForSelectedCompany() async {
    final company = _selectedCompany;
    if (company == null) return;
    try {
      final sync = PostgrestMasterSync(
        client: PostgrestHttpClient(httpClient: _client),
      );
      final firm = PostgrestFirmRow(
        id: company.id,
        firmNr: PostgrestTableNames.padFirm(company.companyNo ?? ''),
        name: company.name,
      );
      final periods = await sync.fetchPeriodsForFirm(firm);
      final picked = sync.pickDefaultPeriod(periods);
      if (!mounted) return;
      setState(() {
        _periods = periods;
        _selectedPeriod = picked;
        _selectedPeriodNo = picked.nr;
        _selectedPeriodStart = picked.begDate;
        _selectedPeriodEnd = picked.endDate;
      });
    } catch (e) {
      debugPrint('Dönem yükleme: $e');
      if (!mounted) return;
      final fallback = PostgrestPeriodRow.fallback(company.id);
      setState(() {
        _periods = [fallback];
        _selectedPeriod = fallback;
        _selectedPeriodNo = '01';
        _selectedPeriodStart = '';
        _selectedPeriodEnd = '';
      });
    }
  }

  String _periodChoiceLabel(PostgrestPeriodRow p) {
    final range = [
      if (p.begDate.trim().isNotEmpty) p.begDate.trim(),
      if (p.endDate.trim().isNotEmpty) p.endDate.trim(),
    ].join(' — ');
    if (range.isEmpty) {
      return AppLocalization.of(context)
          .translate('auth.period_nr_label', args: {'nr': p.nr});
    }
    return '${p.nr} · $range';
  }

  String _warehouseChoiceLabel(WarehouseMasterSeedRow w) {
    // API store: nameKey api.store.* → seedName; seed MRK/ARC/IAD → l10n
    if (w.nameKey.startsWith('api.store.')) {
      return '${w.code} · ${w.seedName}';
    }
    final name = AppLocalization.of(context).translate(w.nameKey);
    final display = name == w.nameKey ? w.seedName : name;
    return '${w.code} · $display';
  }

  void _subscribeToCompanyStreamByUsername(String username) {
    debugPrint('[FİRMA STREAM] Kullanıcı adı ile filtre: $username');
    _companyStreamSub?.cancel();
    // Tenant doluysa PostgREST firms; değilse eski mock (offline demo)
    if (_tenantCodeController.text.trim().isNotEmpty) {
      _loadFirmsFromPostgrest();
      return;
    }
    final companies = [
      Company(
        id: '${username}_1',
        name: 'EXFIN-ERP Demo Firma',
        companyNo: '001',
        description: 'Mock Demo Firma',
        isActive: true,
        createdAt: null,
        updatedAt: null,
        isSelected: false,
      )
    ];

    setState(() {
      _companies = companies;
      _selectedCompany = companies.isNotEmpty ? companies.first : null;
      _isLoading = false;
    });
  }

  Future<void> _initializeDbAndLoad() async {
    final dbService = await DatabaseService.getInstance();
    await dbService.initialize();
    await dbService.ensureWarehousesSchema();
    await _loadSavedTenantCode();
    await _loadWarehouses();
    await _loadSavedWarehouse();
    _loadSavedCredentials();
    _cihazOnayKontrol();
  }

  /// Ambar/mağaza: kiracı aktifse PostgREST `/stores`, yoksa yerel seed.
  Future<void> _loadWarehouses() async {
    final rawFirm = (_selectedCompany?.companyNo ?? '').trim();
    final firmNr =
        rawFirm.isEmpty ? '' : PostgrestTableNames.padFirm(rawFirm);
    final restReady =
        PostgresService.instance.activeRemoteRestUrl.trim().isNotEmpty;

    if (restReady) {
      try {
        final sync = PostgrestMasterSync();
        var stores = await sync.fetchStores(
          firmNr: firmNr.isEmpty ? null : firmNr,
        );
        if (firmNr.isNotEmpty) {
          stores = stores.where((s) => s.firmNr == firmNr).toList();
        }
        if (stores.isNotEmpty) {
          await sync.syncStoresToSqlite(stores);
          if (!mounted) return;
          final rows = stores.map((s) => s.toWarehouseSeedRow()).toList();
          final picked = sync.pickDefaultStore(stores);
          final selectedCode = picked?.code;
          WarehouseMasterSeedRow? selected;
          if (selectedCode != null) {
            for (final r in rows) {
              if (r.code == selectedCode) {
                selected = r;
                break;
              }
            }
          }
          selected ??= rows.first;
          setState(() {
            _warehouses = rows;
            final stillValid = _selectedWarehouse != null &&
                rows.any((r) => r.code == _selectedWarehouse!.code);
            _selectedWarehouse = stillValid ? _selectedWarehouse : selected;
          });
          return;
        }
        debugPrint('PostgREST /stores boş — seed kullanılmayacak (tenant).');
        if (!mounted) return;
        setState(() {
          _warehouses = const [];
          _selectedWarehouse = null;
        });
        return;
      } catch (e) {
        debugPrint('Ambar PostgREST: $e');
      }
    }

    try {
      final dbService = await DatabaseService.getInstance();
      await dbService.ensureWarehousesSchema();
      final db = await dbService.getDatabase();
      final maps = await db.query(WarehouseMasterSeed.tableName);
      if (!mounted) return;
      if (maps.isEmpty) {
        setState(() {
          _warehouses = WarehouseMasterSeed.defaultRows;
          _selectedWarehouse ??= WarehouseMasterSeed.byCode('ARC') ??
              WarehouseMasterSeed.defaultRows.first;
        });
        return;
      }
      final rows = <WarehouseMasterSeedRow>[];
      for (final m in maps) {
        final code = (m['code'] ?? '').toString();
        final seed = WarehouseMasterSeed.byCode(code);
        final rawName = (m['name'] ?? seed?.seedName ?? code).toString();
        rows.add(
          WarehouseMasterSeedRow(
            id: (m['id'] ?? seed?.id ?? code).toString(),
            code: code,
            type: (m['type'] ?? seed?.type ?? '').toString(),
            nameKey: seed?.nameKey ?? 'api.store.$code',
            seedName: rawName,
          ),
        );
      }
      setState(() {
        _warehouses = rows;
        _selectedWarehouse ??= rows.isNotEmpty ? rows.first : null;
      });
    } catch (e) {
      debugPrint('Ambar listesi: $e');
      if (!mounted) return;
      setState(() {
        _warehouses = WarehouseMasterSeed.defaultRows;
        _selectedWarehouse ??= WarehouseMasterSeed.byCode('ARC');
      });
    }
  }

  Future<void> _loadSavedWarehouse() async {
    try {
      final saved = await const ActiveWarehouseStore().load();
      if (!mounted || saved.isEmpty) return;
      WarehouseMasterSeedRow? match;
      for (final w in _warehouses) {
        if (w.code == saved.code) {
          match = w;
          break;
        }
      }
      match ??= WarehouseMasterSeed.byCode(saved.code);
      if (match != null) {
        setState(() => _selectedWarehouse = match);
      }
    } catch (e) {
      debugPrint('Kayıtlı ambar: $e');
    }
  }

  /// Son kiracı kodunu prefs'ten yükler (PostgREST bağlamını restore eder).
  /// Form her zaman kullanıcı adı/şifre gösterir; kiracı üst chip’te.
  Future<void> _loadSavedTenantCode() async {
    try {
      final ctx = await PostgrestTenantService().restoreActiveContext();
      if (!mounted) return;
      String code = '';
      if (ctx != null && ctx.tenantCode.isNotEmpty) {
        code = ctx.tenantCode;
      } else {
        final store = const TenantStore();
        final loaded = await store.load();
        if (!mounted) return;
        if (loaded.tenantCode.isNotEmpty) {
          code = loaded.tenantCode;
        }
      }
      if (!mounted) return;
      setState(() {
        _tenantCodeController.text = code;
        _tenantLocked = false;
        _tenantGatePassed = false;
        _tenantLoadDone = true;
      });
      _syncTenantChip();
      // Kayıtlı kiracı → otomatik bağlan (üst satır yok; değiştir = yarım ay yanı)
      if (code.trim().isNotEmpty) {
        await _connectTenantAndFetch();
      }
    } catch (e) {
      debugPrint('Kiracı kodu yüklenemedi: $e');
      if (mounted) {
        setState(() {
          _tenantLocked = false;
          _tenantGatePassed = false;
          _tenantLoadDone = true;
        });
        _syncTenantChip();
      }
    }
  }

  /// RetailEX parity: kayıtlı kiracıyı bırakıp yeniden girişi açar.
  Future<void> _onChangeTenant() async {
    await const TenantStore().clear();
    PostgresService.instance.clearActiveTenantContext();
    if (!mounted) return;
    setState(() {
      _tenantLocked = false;
      _tenantGatePassed = false;
      _tenantCodeController.clear();
      _companies = [];
      _selectedCompany = null;
      _periods = const [];
      _selectedPeriod = null;
      _selectedPeriodNo = '01';
      _selectedPeriodStart = '';
      _selectedPeriodEnd = '';
    });
    _syncTenantChip();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_openTenantEditDialog());
    });
  }

  /// {@template open_tenant_edit_dialog}
  /// Kompakt kiracı satırından dens dialog: kod gir + Bağlan.
  /// Büyük form TextField yerine kullanılır.
  /// {@endtemplate}
  Future<void> _openTenantEditDialog() async {
    if (!mounted || _isLoading || _tenantConnecting) return;

    final editController = TextEditingController(
      text: _tenantCodeController.text,
    );
    final editFocus = FocusNode();

    try {
      final code = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final l10n = AppLocalization.of(ctx);
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final inputFillColor = isDark ? Colors.grey[850] : Colors.white;
          final inputTextColor = isDark ? Colors.white : Colors.black87;
          final inputHintColor = isDark ? Colors.white70 : Colors.grey[600];

          return AlertDialog(
            backgroundColor: Theme.of(ctx).cardColor,
            title: Text(
              l10n.translate('auth.tenant_edit_title'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF054F99),
              ),
            ),
            content: TextField(
              controller: editController,
              focusNode: editFocus,
              autofocus: true,
              style: TextStyle(color: inputTextColor, fontSize: 14),
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                labelText: l10n.translate('auth.tenant_code'),
                hintText: l10n.translate('auth.enter_tenant_first'),
                prefixIcon: GestureDetector(
                  onLongPress: () async {
                    final ok = await showSaasOriginOverrideDialog(ctx);
                    if (ok && ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.translate('auth.saas_origin_saved'),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Tooltip(
                    message: l10n.translate(
                      'auth.saas_origin_long_press_hint',
                    ),
                    child: const Icon(Icons.apartment, size: 20),
                  ),
                ),
                filled: true,
                fillColor: inputFillColor,
                labelStyle:
                    TextStyle(color: inputTextColor, fontSize: 13),
                hintStyle:
                    TextStyle(color: inputHintColor, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (v) {
                final t = v.trim();
                if (t.isNotEmpty) Navigator.of(ctx).pop(t);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.translate('common.cancel')),
              ),
              OutlinedButton(
                onPressed: () {
                  final t = editController.text.trim();
                  if (t.isEmpty) return;
                  Navigator.of(ctx).pop(t);
                },
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  l10n.translate('auth.connect'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted || code == null || code.trim().isEmpty) return;
      _tenantCodeController.text = code.trim();
      await _connectTenantAndFetch();
    } finally {
      editController.dispose();
      editFocus.dispose();
    }
  }

  /// Kiracı Bağlan: URL çözümle + firma/dönem/ambar çek → login formu.
  Future<void> _connectTenantAndFetch() async {
    final code = _tenantCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalization.of(context).translate('auth.enter_tenant_first'),
          ),
        ),
      );
      return;
    }

    setState(() {
      _tenantConnecting = true;
      _isLoading = true;
    });
    _syncTenantChip();

    try {
      final tenantResult = await PostgrestTenantService(httpClient: _client)
          .applyTenantCode(code);
      if (!mounted) return;

      if (!tenantResult.ok || tenantResult.context == null) {
        final key = tenantResult.errorKey ?? 'auth.tenant_resolve_failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.of(context).translate(key))),
        );
        setState(() {
          _tenantConnecting = false;
          _isLoading = false;
          _tenantGatePassed = false;
        });
        _syncTenantChip();
        return;
      }

      if (tenantResult.usedOfflineCache) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context)
                  .translate('auth.tenant_offline_using_last'),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Web: tarayıcı CORS engeli → gate açmadan net hata
      final corsBlocked = await _probePostgrestReachable();
      if (!mounted) return;
      if (corsBlocked != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context).translate(corsBlocked),
            ),
            duration: const Duration(seconds: 6),
          ),
        );
        setState(() {
          _tenantConnecting = false;
          _isLoading = false;
          _tenantGatePassed = false;
        });
        _syncTenantChip();
        return;
      }

      await _loadFirmsFromPostgrest();
      await _loadWarehouses();
      await _loadSavedWarehouse();
      if (!mounted) return;

      setState(() {
        _tenantCodeController.text = tenantResult.context!.tenantCode;
        _tenantLocked = true;
        _tenantGatePassed = true;
        _tenantConnecting = false;
        _isLoading = false;
      });
      _syncTenantChip();
    } catch (e) {
      debugPrint('Kiracı bağlan: $e');
      if (!mounted) return;
      final err = e.toString().toLowerCase();
      final key = (kIsWeb &&
              (err.contains('failed to fetch') ||
                  err.contains('xmlhttprequest') ||
                  err.contains('cors')))
          ? 'auth.postgrest_web_cors'
          : 'auth.postgrest_network_error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalization.of(context).translate(key)),
          duration: const Duration(seconds: 6),
        ),
      );
      setState(() {
        _tenantConnecting = false;
        _isLoading = false;
        _tenantGatePassed = false;
      });
      _syncTenantChip();
    }
  }

  /// PostgREST erişim probe. Dönüş: hata l10n anahtarı veya null (OK).
  Future<String?> _probePostgrestReachable() async {
    final url = PostgresService.instance.activeRemoteRestUrl.trim();
    if (url.isEmpty) return 'auth.postgrest_network_error';
    try {
      await PostgrestHttpClient(httpClient: _client).getRows(
        '/firms',
        query: const {
          'select': 'id',
          'limit': '1',
        },
      );
      return null;
    } catch (e) {
      debugPrint('PostgREST probe: $e');
      final err = e.toString().toLowerCase();
      if (kIsWeb &&
          (err.contains('failed to fetch') ||
              err.contains('xmlhttprequest') ||
              err.contains('clientexception'))) {
        return 'auth.postgrest_web_cors';
      }
      // HTTP 4xx/5xx → sunucu cevap verdi (CORS değil); gate devam
      if (e is PostgrestHttpException && e.statusCode > 0) {
        return null;
      }
      return 'auth.postgrest_network_error';
    }
  }

  /// Kiracı uygulandıktan sonra kilitle (RetailEX kayıtlı görünüm).
  void _lockTenantAfterApply(String code) {
    final c = code.trim();
    if (c.isEmpty) return;
    setState(() {
      _tenantCodeController.text = c;
      _tenantLocked = true;
    });
  }

  // Kaydedilen firma bilgisini yükle (form doldurma; auto-login bootstrap'ta)
  Future<void> _loadSavedCredentials() async {
    final dbService = await DatabaseService.getInstance();
    final hasRememberedCredentials = await dbService.hasRememberedCredentials();

    if (hasRememberedCredentials) {
      final username = await dbService.getSavedUsername();
      final password = await dbService.getSavedPassword();

      if (username != null && username.isNotEmpty) {
        setState(() {
          _usernameController.text = username;
          if (password != null && password.isNotEmpty) {
            _passwordController.text = password;
          }
          _rememberMe = true;
        });
      }
    }
  }

  Future<void> _cihazOnayKontrol() async {
    // Hash değerini al (cihaz kayıt ekranında kullanılan aynı değer)
    final id = await DeviceService.getHashedDeviceSerial();
    setState(() {
      _cihazSeriNo = id;
    });
    if (id != null) {
      final onayli = await DeviceRegistrationService.isDeviceAllowed(id);
      setState(() {
        _cihazOnayli = onayli;
        _cihazKontrolEdildi = true;
      });
    } else {
      setState(() {
        _cihazOnayli = false;
        _cihazKontrolEdildi = true;
      });
    }
  }

  /// Dens birincil aksiyon (Bağlan / Giriş) — mevcut gradient stil.
  Widget _buildPrimaryActionButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required bool showSpinner,
    required String labelKey,
    String? countdownText,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [exfinDarkBlue, exfinLightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: exfinDarkBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        child: showSpinner
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: countdownText != null
                    ? Text(
                        countdownText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : DirectionalLocalizedText(
                        labelKey,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugLog("ExfinLoginForm build method called");

    // Locale bilgisini al
    final locale = Localizations.localeOf(context);
    debugLog("Current locale in form: ${locale.toString()}");

    // Localizations kontrolü
    final hasMaterialLocalizations = Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        ) !=
        null;
    debugLog("Has MaterialLocalizations: $hasMaterialLocalizations");

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputFillColor = isDark ? Colors.grey[850] : Colors.white;
    final inputTextColor = isDark ? Colors.white : Colors.black87;
    final inputHintColor = isDark ? Colors.white70 : Colors.grey[600];

    // Kayıtlı değil: dens kiracı alanı. Kayıtlı: formda satır yok
    // (üstte bina + T: kod chip).
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_tenantLoadDone)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (!_tenantGatePassed) ...[
            TextFormField(
              controller: _tenantCodeController,
              focusNode: _tenantFocusNode,
              style: TextStyle(fontSize: 13, color: inputTextColor),
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              enabled: !_isLoading && !_tenantConnecting,
              onChanged: (_) => _syncTenantChip(),
              onFieldSubmitted: (_) {
                if (!_tenantConnecting) {
                  unawaited(_connectTenantAndFetch());
                }
              },
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                labelText: AppLocalization.of(context)
                    .translate('auth.tenant_code'),
                hintText: AppLocalization.of(context)
                    .translate('auth.enter_tenant_first'),
                prefixIcon: const Icon(Icons.apartment, size: 20),
                filled: true,
                fillColor: inputFillColor,
                labelStyle: TextStyle(fontSize: 13, color: inputTextColor),
                hintStyle: TextStyle(fontSize: 12, color: inputHintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalization.of(context)
                      .translate('auth.enter_tenant_first');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildPrimaryActionButton(
              context: context,
              onPressed: (_isLoading || _tenantConnecting)
                  ? null
                  : () => unawaited(_connectTenantAndFetch()),
              showSpinner: _tenantConnecting,
              labelKey: 'auth.connect',
            ),
          ] else ...[
          // Kullanıcı adı alanı:
          TextFormField(
            controller: _usernameController,
            style: TextStyle(color: inputTextColor),
            textDirection: Directionality.of(context),
            decoration: InputDecoration(
              labelText: AppLocalization.of(context).translate('auth.username'),
              hintText: AppLocalization.of(context).translate('auth.enter_username'),
              prefixIcon: const Icon(Icons.person),
              filled: true,
              fillColor: inputFillColor,
              labelStyle: TextStyle(color: inputTextColor),
              hintStyle: TextStyle(color: inputHintColor),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (value) {
              return (value == null || value.isEmpty)
                  ? AppLocalization.of(context)
                      .translate('auth.username_required')
                  : null;
            },
          ),
          const SizedBox(height: 16),

          // Şifre alanı:
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: inputTextColor),
            textDirection: Directionality.of(context),
            decoration: InputDecoration(
              labelText: AppLocalization.of(context).translate('auth.password'),
              hintText: AppLocalization.of(context).translate('auth.enter_password'),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard, size: 20),
                    onPressed: () {
                      _showNumericKeyboard(context);
                    },
                    tooltip: AppLocalization.of(context).translate('auth.numeric_keyboard'),
                  ),
                  IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ],
              ),
              filled: true,
              fillColor: inputFillColor,
              labelStyle: TextStyle(color: inputTextColor),
              hintStyle: TextStyle(color: inputHintColor),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (value) {
              return (value == null || value.isEmpty)
                  ? AppLocalization.of(context)
                      .translate('auth.password_required')
                  : null;
            },
          ),
          const SizedBox(height: 8),

          // Firma + dönem tek dens alan (ortak çerçeve)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: () => _showCompanySelectionDialog(context),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.business,
                              size: 16,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _selectedCompany?.name ??
                                    AppLocalization.of(context)
                                        .translate('auth.select_company'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white
                                      : textColorPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                  ),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: _selectedCompany == null
                          ? null
                          : () => _showPeriodSelectionDialog(context),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range,
                              size: 16,
                              color: _selectedCompany == null
                                  ? Colors.blueGrey.withValues(alpha: 0.4)
                                  : Colors.blueGrey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _selectedPeriod != null
                                    ? _periodChoiceLabel(_selectedPeriod!)
                                    : AppLocalization.of(context)
                                        .translate('auth.select_period'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _selectedCompany == null
                                      ? (isDark
                                          ? Colors.white38
                                          : Colors.black38)
                                      : (isDark
                                          ? Colors.white
                                          : textColorPrimary),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ambar seçimi
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showWarehouseSelectionDialog(context),
              icon: const Icon(
                Icons.warehouse_outlined,
                color: Colors.blueGrey,
              ),
              label: Text(
                _selectedWarehouse != null
                    ? _warehouseChoiceLabel(_selectedWarehouse!)
                    : AppLocalization.of(context)
                        .translate('auth.select_warehouse'),
                style: TextStyle(
                  color: isDark ? Colors.white : textColorPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: isDark ? Colors.grey[850] : Colors.white,
              ),
            ),
          ),

          // Beni Hatırla ve Login Kontrol switch'leri aynı satırda
          Row(
            children: [
              // Beni Hatırla
              Expanded(
                child: Row(
                  children: [
                    Switch(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalization.of(context).translate('auth.remember_me'),
                        style: TextStyle(color: textColorSecondary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
              // Login Kontrol
              Expanded(
                child: Row(
                  children: [
                    Switch(
                      value: _forceLogout,
                      onChanged: (value) {
                        setState(() {
                          _forceLogout = value;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(AppLocalization.of(context).translate('auth.login_control'),
                          style: TextStyle(color: textColorSecondary)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Giriş butonu
          _buildPrimaryActionButton(
            context: context,
            onPressed: _isLoading ? null : _handleLogin,
            showSpinner: _isLoading && _loginCountdown == 0,
            labelKey: 'common.login',
            countdownText: _loginCountdown > 0
                ? AppLocalization.of(context).translate(
                    'auth.seconds_left_to_takeover',
                    args: {'seconds': _loginCountdown.toString()},
                  )
                : null,
          ),

          if (_cihazKontrolEdildi && !_cihazOnayli)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalization.of(context).translate('auth.device_not_allowed_message'),
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Debug bilgisi
                  GestureDetector(
                    onTap: _debugRefreshing
                        ? null
                        : () {
                            // Debug alanına tıklandığında cihaz kontrolünü yenile
                            setState(() {
                              _debugRefreshing = true;
                            });
                            _cihazOnayKontrol().then((_) {
                              setState(() {
                                _debugRefreshing = false;
                              });
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text(AppLocalization.of(context).translate('auth.refreshing_device_check')),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _debugRefreshing
                            ? (isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50)
                            : (isDark ? Colors.grey[850] : Colors.grey.shade100),
                        border: Border.all(
                          color: _debugRefreshing
                              ? (isDark ? Colors.blue.shade700 : Colors.blue.shade300)
                              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          width: _debugRefreshing ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: _debugRefreshing
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(AppLocalization.of(context).translate('auth.debug_info'),
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                              const SizedBox(width: 8),
                              if (_debugRefreshing) ...[
                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.blue.shade400 : Colors.blue.shade600))),
                              ] else ...[
                                Icon(Icons.refresh, size: 16, color: isDark ? Colors.blue.shade400 : Colors.blue),
                              ],
                              const SizedBox(width: 4),
                              Text(
                                AppLocalization.of(context).translate(_debugRefreshing ? 'auth.refreshing' : 'auth.click_to_refresh'),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: _debugRefreshing
                                        ? (isDark ? Colors.blue.shade400 : Colors.blue.shade600)
                                        : (isDark ? Colors.blue.shade300 : Colors.blue),
                                    fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${AppLocalization.of(context).translate('auth.device_hash')} ${_cihazSeriNo ?? AppLocalization.of(context).translate('common.error')}'),
                          Text('${AppLocalization.of(context).translate('auth.checked')} $_cihazKontrolEdildi'),
                          Text('${AppLocalization.of(context).translate('auth.approved')} $_cihazOnayli'),
                          if (_cihazSeriNo != null) ...[
                            const SizedBox(height: 4),
                            Text(
                                '${AppLocalization.of(context).translate('auth.last_check')} ${DateTime.now().toString().substring(11, 19)}'),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Numeric keyboard (conditionally shown)
          if (_showKeyboard)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: ColorUtils.withAlpha(Colors.grey, 0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: NumericKeyboard(
                controller: _passwordController,
                initialValue: _passwordController.text,
                onKeyPressed: (value) {
                  // Value is already handled by the widget
                },
                onDone: () {
                  setState(() {
                    _showKeyboard = false;
                  });
                },
                onClear: () {
                  // Clearing is handled by the widget
                },
              ),
            ),
          ], // kayıtlı kiracı login formu
        ],
      ),
    );
  }

  // Firma seçim dialog metodu eklendi
  void _showCompanySelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CompanySelectionDialog(
        companies: _companies,
        selectedCompany: _selectedCompany,
        onCompanySelected: _onCompanySelected,
      ),
    );
  }

  void _showPeriodSelectionDialog(BuildContext context) {
    final items = _periods.isEmpty
        ? [
            _selectedPeriod ??
                PostgrestPeriodRow.fallback(_selectedCompany?.id ?? ''),
          ]
        : _periods;
    showDialog(
      context: context,
      builder: (ctx) => _LoginListChoiceDialog(
        title: AppLocalization.of(context).translate('auth.period_selection'),
        items: items
            .map(
              (p) => _LoginChoiceItem(
                id: p.id.isNotEmpty ? p.id : p.nr,
                label: _periodChoiceLabel(p),
              ),
            )
            .toList(),
        selectedId: _selectedPeriod?.id.isNotEmpty == true
            ? _selectedPeriod!.id
            : _selectedPeriod?.nr,
        onSelected: (id) {
          PostgrestPeriodRow? match;
          for (final p in items) {
            if (p.id == id || p.nr == id) {
              match = p;
              break;
            }
          }
          if (match == null) return;
          final selected = match;
          setState(() {
            _selectedPeriod = selected;
            _selectedPeriodNo = selected.nr;
            _selectedPeriodStart = selected.begDate;
            _selectedPeriodEnd = selected.endDate;
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _showWarehouseSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _LoginListChoiceDialog(
        title: AppLocalization.of(context).translate('auth.warehouse_selection'),
        items: _warehouses
            .map(
              (w) => _LoginChoiceItem(
                id: w.code,
                label: _warehouseChoiceLabel(w),
              ),
            )
            .toList(),
        selectedId: _selectedWarehouse?.code,
        onSelected: (id) {
          WarehouseMasterSeedRow? match;
          for (final w in _warehouses) {
            if (w.code == id) {
              match = w;
              break;
            }
          }
          if (match == null) return;
          setState(() => _selectedWarehouse = match);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _showNumericKeyboard(BuildContext context) {
    setState(() {
      _showKeyboard = true;
    });
  }

  Future<void> _handleLogin() async {
    // Cihaz kaydı pas geçiliyor
    // if (!_cihazKontrolEdildi) return;
    // if (!_cihazOnayli) {
    //   _showDeviceNotAllowedDialog(context);
    //   return;
    // }

    if (!_tenantGatePassed) {
      await _openTenantEditDialog();
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      final tenantCode = _tenantCodeController.text.trim();
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      if (tenantCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context)
                  .translate('auth.enter_tenant_first'),
            ),
          ),
        );
        unawaited(_openTenantEditDialog());
        return;
      }

      setState(() => _isLoading = true);
      final tenantResult =
          await PostgrestTenantService(httpClient: _client)
              .applyTenantCode(tenantCode);
      if (!mounted) return;

      if (!tenantResult.ok || tenantResult.context == null) {
        setState(() => _isLoading = false);
        final key = tenantResult.errorKey ?? 'auth.tenant_resolve_failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalization.of(context).translate(key)),
          ),
        );
        return;
      }

      _lockTenantAfterApply(tenantResult.context!.tenantCode);

      if (tenantResult.usedOfflineCache && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context)
                  .translate('auth.tenant_offline_using_last'),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Firma listesi henüz yoksa PostgREST'ten çek
      if (_companies.isEmpty) {
        await _loadFirmsFromPostgrest();
        if (!mounted) return;
      }

      // DEMO GİRİŞ KONTROLÜ
      if (username.toLowerCase() == 'demo' && password == 'demo') {
        await Future.delayed(const Duration(seconds: 1)); // Simülasyon
        
        final dbService = await DatabaseService.getInstance();
        await dbService.setUserSession({
          'id': 'demo-id',
          'username': 'demo',
          'role': 'admin',
          'email': 'demo@exfinerp.com',
          'full_name': 'Demo User',
          'session_id': 'demo-session',
          'company_no': 'DEMO',
        });
        
        // Tasarım testi için demo girişinde mock verileri veritabanına bas
        await dbService.seedFieldSalesMockData();
        
        setState(() => _isLoading = false);
        if (mounted) {
          MenuFixer.fixMenus(context);
          final isMobile = !kIsWeb &&
              (Theme.of(context).platform == TargetPlatform.android ||
               Theme.of(context).platform == TargetPlatform.iOS);
          if (isMobile) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MobileDashboard(username: _usernameController.text.trim())),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        }
        return;
      }

      if (_maxUserLimit) {
        setState(() => _isLoading = false);
        _showMaxUserDialog(context);
        return;
      }

      if (_selectedCompany == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.of(context).translate('auth.please_select_company'))),
        );
        return;
      }
      if (_selectedPeriod == null && _selectedPeriodNo.trim().isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context)
                  .translate('auth.please_select_period'),
            ),
          ),
        );
        return;
      }
      if (_selectedWarehouse == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context)
                  .translate('auth.please_select_warehouse'),
            ),
          ),
        );
        return;
      }
      try {
        final dbService = await DatabaseService.getInstance();
        if (_rememberMe) {
          await dbService.saveSelectedCompanyId(_selectedCompany!.id);
        } else {
          await dbService.clearCredentials();
        }
        bool autoAccepted = false;

        // Supabase kapatıldığı için oturum kontrolünü atlıyoruz
        final user = {'is_logged_in': false};

        if (user['is_logged_in'] == false) {
          // Oturum zaten kapalı, force logout olmadan doğrudan giriş yap
          setState(() => _isLoading = true);
          final loginResult = await AuthService.loginWithUsernameAndPassword(
            username: username,
            password: password,
            forceLogout: false,
            onForceLogoutDialog: (_) {},
            onForceLogoutAccepted: () {},
            onForceLogoutRejected: () {},
          );
          setState(() => _isLoading = false);
          if (loginResult == null || loginResult['error'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_loginErrorText(loginResult))),
            );
            return;
          }
          await _finishSuccessfulLogin(loginResult);
          return;
        }
        // Sayaç başlat
        setState(() {
          _loginCountdown = 15;
        });
        _loginCountdownTimer?.cancel();
        _loginCountdownTimer =
            Timer.periodic(const Duration(seconds: 1), (timer) async {
          if (_loginCountdown > 0) {
            setState(() {
              _loginCountdown--;
            });
          } else {
            timer.cancel();
            // Otomatik devralma: force_logout_response = 'accepted'
            if (_isLoading && !autoAccepted) {
              autoAccepted = true;
              
              if (Navigator.canPop(context))
                Navigator.of(context, rootNavigator: true).pop();
              setState(() {
                _loginCountdown = 0;
              });
            }
          }
        });
        final loginResult = await AuthService.loginWithUsernameAndPassword(
          username: username,
          password: password,
          forceLogout: _forceLogout && !_isForceLoginRetry,
          onForceLogoutDialog: (msg) async {
            await showForceLogoutDialog(context, username, (accepted) async {
              _loginCountdownTimer?.cancel();
              setState(() {
                _loginCountdown = 0;
              });
              if (accepted) {
                setState(() => _isLoading = true);
                final retryResult =
                    await AuthService.loginWithUsernameAndPassword(
                  username: username,
                  password: password,
                  forceLogout: false,
                  onForceLogoutDialog: (
                    _,
                  ) {},
                  onForceLogoutAccepted: () {},
                  onForceLogoutRejected: () {},
                );
                setState(() => _isLoading = false);
                if (retryResult == null || retryResult['error'] != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_loginErrorText(retryResult))),
                  );
                  return;
                }
                await _finishSuccessfulLogin(retryResult);
              } else {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalization.of(context).translate('auth.takeover_denied'))),
                );
              }
            });
          },
          onForceLogoutAccepted: () async {
            setState(() => _isLoading = true);
            final retryResult = await AuthService.loginWithUsernameAndPassword(
              username: username,
              password: password,
              forceLogout: false,
              onForceLogoutDialog: (
                _,
              ) {},
              onForceLogoutAccepted: () {},
              onForceLogoutRejected: () {},
            );
            setState(() => _isLoading = false);
            if (retryResult == null || retryResult['error'] != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_loginErrorText(retryResult))),
              );
              return;
            }
            await _finishSuccessfulLogin(retryResult);
          },
          onForceLogoutRejected: () {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalization.of(context).translate('auth.takeover_denied'))),
            );
          },
        );
        if ((loginResult == null && (_forceLogout && !_isForceLoginRetry)) ||
            (loginResult == null && _isForceLoginRetry)) {
          // Bekleme ve callback'ler ile akış devam edecek
          return;
        }
        if (loginResult == null || loginResult['error'] != null) {
          setState(() => _isLoading = false);
          setState(() {
            _loginCountdown = 0;
          });
          _loginCountdownTimer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_loginErrorText(loginResult))),
          );
          return;
        }
        await _finishSuccessfulLogin(loginResult);
      } catch (e) {
        setState(() => _isLoading = false);
        setState(() {
          _loginCountdown = 0;
        });
        _loginCountdownTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalization.of(context).translate('auth.login_error', args: {'error': e.toString()})}')),
        );
      }
    }
  }

  void _showDeviceNotAllowedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(AppLocalization.of(context).translate('auth.device_not_allowed_title'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(AppLocalization.of(context).translate('auth.device_not_allowed_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalization.of(context).translate('common.ok')),
          ),
        ],
      ),
    );
  }

  void _showMaxUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(AppLocalization.of(context).translate('auth.user_limit_exceeded_title'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(AppLocalization.of(context).translate('auth.user_limit_exceeded_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalization.of(context).translate('common.ok')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _companyStreamSub?.cancel();
    _httpClient?.close();
    _tenantFocusNode.dispose();
    _tenantCodeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  List<String> _parseAllowedFirmNrs(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  String _loginErrorText(Map<String, dynamic>? loginResult) {
    final key = (loginResult?['error_key'] ?? loginResult?['error'] ?? '')
        .toString();
    if (key.startsWith('auth.')) {
      return AppLocalization.of(context).translate(key);
    }
    if (key.isNotEmpty) return key;
    return AppLocalization.of(context).translate('auth.login_failed');
  }

  /// Başarılı giriş: firma/dönem bağlamı + master sync + session + navigate.
  Future<void> _finishSuccessfulLogin(Map<String, dynamic> loginResult) async {
    final dbService = await DatabaseService.getInstance();
    final preferFirm = (loginResult['firm_nr'] ?? '').toString();
    final allowed = _parseAllowedFirmNrs(loginResult['allowed_firm_nrs']);

    if (preferFirm.isNotEmpty || allowed.isNotEmpty) {
      await _loadFirmsFromPostgrest(
        preferFirmNr: preferFirm,
        allowedFirmNrs: allowed,
      );
      final selectedNr = PostgrestTableNames.padFirm(
        _selectedCompany?.companyNo ?? '',
      );
      final allowedSet = <String>{
        if (preferFirm.isNotEmpty)
          PostgrestTableNames.padFirm(preferFirm),
        ...allowed.map(PostgrestTableNames.padFirm),
      };
      if (allowedSet.isNotEmpty && !allowedSet.contains(selectedNr)) {
        Company? match;
        for (final c in _companies) {
          final nr = PostgrestTableNames.padFirm(c.companyNo ?? '');
          if (allowedSet.contains(nr)) {
            match = c;
            break;
          }
        }
        if (match != null) {
          setState(() => _selectedCompany = match);
          await _loadPeriodForSelectedCompany();
        }
      }
    }

    final company = _selectedCompany;
    if (company == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context)
                  .translate('auth.please_select_company'),
            ),
          ),
        );
      }
      return;
    }

    final firmNr = PostgrestTableNames.padFirm(company.companyNo ?? '001');
    final periodNo = (_selectedPeriod?.nr ?? _selectedPeriodNo).trim().isEmpty
        ? '01'
        : (_selectedPeriod?.nr ?? _selectedPeriodNo);
    await const ActiveCompanyStore().save(
      ActiveCompanySession(
        companyId: company.id,
        companyName: company.name,
        companyNo: firmNr,
        periodNo: periodNo,
        startDate: _selectedPeriod?.begDate ?? _selectedPeriodStart,
        endDate: _selectedPeriod?.endDate ?? _selectedPeriodEnd,
      ),
    );

    final wh = _selectedWarehouse;
    if (wh != null) {
      final whName = AppLocalization.of(context).translate(wh.nameKey);
      await const ActiveWarehouseStore().save(
        ActiveWarehouseSession(
          code: wh.code,
          name: whName == wh.nameKey ? wh.seedName : whName,
          type: wh.type,
        ),
      );
    }

    try {
      final sync = PostgrestMasterSync(
        client: PostgrestHttpClient(httpClient: _client),
      );
      await sync.syncCustomersAndProducts();
      await sync.syncPermissionGroupsOptional();
    } catch (e) {
      debugPrint('Login master sync: $e');
    }

    // Logo henüz çekilmediyse arka planda master pull (spam/gate stateStore).
    unawaited(LogoTigerStartupPull().runIfNeeded());

    await dbService.setUserSession({
      'id': loginResult['user_id'],
      'username': loginResult['username'],
      'role': loginResult['role'],
      'email': loginResult['email'],
      'full_name': loginResult['full_name'],
      'session_id': loginResult['session_id'],
      'company_no': firmNr,
      'period_no': periodNo,
      'warehouse_code': wh?.code ?? '',
    });

    final sessionId = (loginResult['session_id'] ?? '').toString();
    if (sessionId.isNotEmpty) {
      await dbService.saveAuthToken(sessionId);
    }

    if (_rememberMe) {
      final uname =
          (loginResult['username'] ?? _usernameController.text).toString();
      final pwd = _passwordController.text;
      await const RememberMeStore().save(
        RememberMeSession(
          sessionToken: sessionId,
          username: uname,
          userId: (loginResult['user_id'] ?? '').toString(),
          role: (loginResult['role'] ?? '').toString(),
          email: (loginResult['email'] ?? '').toString(),
          fullName: (loginResult['full_name'] ?? '').toString(),
          tenantCode: _tenantCodeController.text.trim(),
        ),
        plainPassword: pwd,
      );
      await dbService.saveCredentials(uname, pwd);
    } else {
      await dbService.clearCredentials();
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loginCountdown = 0;
    });
    _loginCountdownTimer?.cancel();
    MenuFixer.fixMenus(context);
    final isMobile = !kIsWeb &&
        (Theme.of(context).platform == TargetPlatform.android ||
            Theme.of(context).platform == TargetPlatform.iOS);
    final uname = (loginResult['username'] ?? 'Kullanıcı').toString();
    if (isMobile) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MobileDashboard(username: uname),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  void _onCompanySelected(Company company) async {
    setState(() {
      _selectedCompany = company;
    });
    final companyNo = company.companyNo;
    debugPrint('[FİRMA SEÇİMİ] Seçilen company_no: $companyNo');
    final dbService = await DatabaseService.getInstance();
    await dbService.updateCompanySelection(company.id);
    await _loadPeriodForSelectedCompany();
    await _loadWarehouses();
    await _loadSavedWarehouse();
  }
}
/// Login dens liste seçimi (dönem / ambar).
class _LoginChoiceItem {
  final String id;
  final String label;

  const _LoginChoiceItem({required this.id, required this.label});
}

class _LoginListChoiceDialog extends StatelessWidget {
  final String title;
  final List<_LoginChoiceItem> items;
  final String? selectedId;
  final void Function(String id) onSelected;

  const _LoginListChoiceDialog({
    required this.title,
    required this.items,
    required this.onSelected,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      content: Container(
        width: 360,
        constraints: const BoxConstraints(maxHeight: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColorPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            Flexible(
              child: items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        AppLocalization.of(context)
                            .translate('auth.no_period'),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final selected = item.id == selectedId;
                        return ListTile(
                          dense: true,
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(Icons.check, color: exfinDarkBlue)
                              : null,
                          onTap: () => onSelected(item.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// CompanySelectionDialog widget'ını ultra modern, flat ve minimal yapıyorum
class CompanySelectionDialog extends StatefulWidget {
  final List<Company> companies;
  final Company? selectedCompany;
  final Function(Company) onCompanySelected;

  const CompanySelectionDialog({
    Key? key,
    required this.companies,
    this.selectedCompany,
    required this.onCompanySelected,
  }) : super(key: key);

  @override
  State<CompanySelectionDialog> createState() => _CompanySelectionDialogState();
}

class _CompanySelectionDialogState extends State<CompanySelectionDialog> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      content: Container(
        width: 360,
        constraints: const BoxConstraints(maxHeight: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Minimal flat başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Firma Seçimi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColorPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

            // Arama kutusu - flat ve minimal
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Firma Ara',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (_) => setState(() {}),
              ),
            ),

            // Firma listesi - flat design
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                itemCount: _filteredCompanies.length,
                shrinkWrap: true,
                separatorBuilder: (context, index) => Divider(
                  height: 2,
                  thickness: 1,
                  color: Colors.grey.shade100,
                  indent: 10,
                  endIndent: 10,
                ),
                itemBuilder: (context, index) {
                  final company = _filteredCompanies[index];
                  final isSelected = company.id == widget.selectedCompany?.id;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Doğrudan ana widget'a geri bildir
                        widget.onCompanySelected(company);
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            // Renkli nokta (flat tasarıma uygun)
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.blueGrey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Firma bilgileri
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    company.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: isSelected
                                          ? Colors.blueGrey
                                          : textColorPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    company.description ?? '',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Seçim işareti (flat tasarım)
                            if (isSelected)
                              Icon(
                                Icons.check,
                                color: Colors.blueGrey,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Arama filtrelemesi
  List<Company> get _filteredCompanies {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return widget.companies;

    return widget.companies
        .where(
          (company) =>
              company.name.toLowerCase().contains(query) ||
              (company.description?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }
}

Future<void> showForceLogoutDialog(BuildContext context, String username,
    void Function(bool accepted) onResult) async {
  int secondsLeft = 15;
  late StateSetter setStateDialog;
  Timer? timer;
  bool callbackCalled = false;

  void safeCallback(bool accepted) async {
    if (!callbackCalled) {
      callbackCalled = true;
      // Eğer reddedildiyse Supabase'e bildir
      if (!accepted) {
        final client = Supabase.instance.client;
        await client
            .from('users')
            .update({'force_logout_response': 'rejected'})
            .eq('username', username)
            .eq('is_logged_in', true);
      }
      onResult(accepted);
    }
  }

  timer = Timer.periodic(const Duration(seconds: 1), (t) {
    if (secondsLeft > 0) {
      setStateDialog(() => secondsLeft--);
    } else {
      t.cancel();
      Navigator.of(context, rootNavigator: true).pop();
      safeCallback(true); // Otomatik kabul
    }
  });

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return WillPopScope(
        onWillPop: () async {
          timer?.cancel();
          safeCallback(true); // X ile kapatılırsa otomatik kabul
          return true;
        },
        child: StatefulBuilder(
          builder: (context, setState) {
            setStateDialog = setState;
            return AlertDialog(
              title: Text(AppLocalization.of(context).translate('auth.takeover_request_title')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalization.of(context).translate('auth.takeover_request_desc')),
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
        ),
      );
    },
  );
}

/// {@template animated_login_slogan}
/// Login sloganını mevcut dil + İngilizce (veya TR↔EN) arasında
/// soft fade/slide ile döngüleyen widget.
///
/// Kullanım örneği:
/// ```dart
/// AnimatedLoginSlogan(isDarkMode: false, isSmallScreen: true)
/// ```
/// {@endtemplate}
class AnimatedLoginSlogan extends StatefulWidget {
  /// [isDarkMode]: Karanlık tema durumu
  final bool isDarkMode;

  /// [isSmallScreen]: Dar ekran düzeni
  final bool isSmallScreen;

  /// {@macro animated_login_slogan}
  const AnimatedLoginSlogan({
    Key? key,
    required this.isDarkMode,
    required this.isSmallScreen,
  }) : super(key: key);

  @override
  State<AnimatedLoginSlogan> createState() => _AnimatedLoginSloganState();
}

class _AnimatedLoginSloganState extends State<AnimatedLoginSlogan> {
  static const Duration _switchInterval = Duration(seconds: 4);
  static const Duration _fadeDuration = Duration(milliseconds: 650);
  static const String _fallbackTr = 'Operasyon Yönetim Sistemi';
  static const String _fallbackEn = 'Operations Management System';

  /// [_index]: Gösterilen slogan indeksi
  int _index = 0;

  /// [_slogans]: Döngüdeki slogan metinleri
  List<String> _slogans = const [_fallbackTr, _fallbackEn];

  /// [_timer]: Dil değiştirme zamanlayıcısı
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuildSloganPair();
    _timer ??= Timer.periodic(_switchInterval, (_) {
      if (!mounted || _slogans.length < 2) return;
      setState(() => _index = (_index + 1) % _slogans.length);
    });
  }

  /// {@template rebuild_slogan_pair}
  /// Mevcut locale'e göre birincil + ikincil slogan çiftini kurar.
  /// {@endtemplate}
  void _rebuildSloganPair() {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    final localized = AppLocalization.of(context).translate('auth.slogan');
    final primary = (localized.isEmpty || localized == 'auth.slogan')
        ? (code == 'en' ? _fallbackEn : _fallbackTr)
        : localized;

    final List<String> next;
    if (code == 'en') {
      next = [primary, _fallbackTr];
    } else if (code == 'tr') {
      next = [primary, _fallbackEn];
    } else {
      next = primary == _fallbackEn
          ? [_fallbackEn, _fallbackTr]
          : [primary, _fallbackEn];
    }

    if (!_listEquals(next, _slogans)) {
      _slogans = next;
      _index = 0;
    }
  }

  /// {@template list_equals}
  /// İki string listesinin eşitliğini kontrol eder.
  /// {@endtemplate}
  bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _slogans[_index % _slogans.length];
    return SizedBox(
      width: widget.isSmallScreen ? 300 : 400,
      height: 28,
      child: AnimatedSwitcher(
        duration: _fadeDuration,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: Text(
          text,
          key: ValueKey<String>(text),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: widget.isDarkMode
                ? Colors.white70
                : exfinDarkBlue.withOpacity(0.8),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// Bayrak widget'ı
Widget _buildFlag(String code) {
  switch (code) {
    case 'tr':
      return Image.asset('assets/flags/tr.png', width: 28, height: 28);
    case 'en':
      return Image.asset('assets/flags/gb.png', width: 28, height: 28);
    case 'ar':
      return Image.asset('assets/flags/sa.png', width: 28, height: 28);
    case 'ar-iq':
    case 'ku':
    case 'ckb':
      return Image.asset('assets/flags/iq.png', width: 28, height: 28);
    case 'de':
      return Image.asset('assets/flags/de.png', width: 28, height: 28);
    case 'fa':
      return Image.asset('assets/flags/ir.png', width: 28, height: 28);
    case 'ru':
      return Image.asset('assets/flags/ru.png', width: 28, height: 28);
    default:
      return Icon(Icons.language, color: exfinDarkBlue, size: 28);
  }
}

class Supabase { static dynamic instance; }
class MockSupabase { static dynamic instance; }
