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
import '../modules/admin_panel/admin_password_dialog.dart'
    show showAdminPasswordDialog;

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

class LoginScreen extends ConsumerWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                            // Removed the SizedBox height to reduce gap
                            SizedBox(
                              width: isSmallScreen ? 300 : 400, // Constrain slogan width to match logo
                              child: Text(
                                'Operasyon Yönetim Sistemi',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16, // Matching larger logo scale
                                  fontWeight: FontWeight.w500, // Slightly bolder for readability 
                                  color: isDarkMode ? Colors.white70 : exfinDarkBlue.withOpacity(0.8),
                                  letterSpacing: 0.2, // Less letter spacing
                                ),
                              ),
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
                            ExfinLoginForm(exfinRed: exfinRed, ref: ref),
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

  const ExfinLoginForm({Key? key, required this.exfinRed, required this.ref})
      : super(key: key);

  @override
  State<ExfinLoginForm> createState() => _ExfinLoginFormState();
}

class _ExfinLoginFormState extends State<ExfinLoginForm> {
  final _formKey = GlobalKey<FormState>();
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

  // Firma değişkeni
  Company? _selectedCompany;
  List<Company> _companies = [];
  StreamSubscription<List<Map<String, dynamic>>>? _companyStreamSub;

  @override
  void initState() {
    super.initState();
    _initializeDbAndLoad();
    _usernameController.addListener(_onUsernameChanged);
    // İlk açılışta kullanıcı adı varsa stream başlat
    if (_usernameController.text.trim().isNotEmpty) {
      _subscribeToCompanyStreamByUsername(_usernameController.text.trim());
    }
  }

  void _onUsernameChanged() {
    final username = _usernameController.text.trim();
    if (username.isNotEmpty) {
      _subscribeToCompanyStreamByUsername(username);
    } else {
      _companyStreamSub?.cancel();
      setState(() {
        _companies = [];
        _selectedCompany = null;
      });
    }
  }

  void _subscribeToCompanyStreamByUsername(String username) {
    debugPrint('[FİRMA STREAM] Kullanıcı adı ile filtre: $username');
    _companyStreamSub?.cancel();
    
    // Supabase iptal edildi. Local/Mock DB üzerinden firma listesi döndürülüyor.
    final companies = [
      Company(
        id: '${username}_1',
        name: 'EXFIN-ERP Demo Firma',
        companyNo: '1',
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
    _loadSavedCredentials();
    _cihazOnayKontrol();
  }

  // Kaydedilen firma bilgisini yükle
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
        
        // Wait a short duration to ensure companies are loaded from stream, then auto-login
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
            _handleLogin();
          }
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

    // Form tasarımını başlat
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            validator: (value) => (value == null || value.isEmpty)
                ? AppLocalization.of(context).translate('auth.username_required')
                : null,
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
            validator: (value) =>
                (value == null || value.isEmpty) ? AppLocalization.of(context).translate('auth.password_required') : null,
          ),
          const SizedBox(height: 8),

          // Firma seçim butonu (şifrenin altına taşındı)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCompanySelectionDialog(context),
              icon: Icon(
                Icons.business,
                color: Colors.blueGrey,
              ),
              label: Text(
                _selectedCompany?.name ?? AppLocalization.of(context).translate('auth.select_company'),
                style: TextStyle(
                  color: isDark ? Colors.white : textColorPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
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

          // Bağlan butonu
          Container(
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
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: (_isLoading && _loginCountdown == 0)
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
                      child: _loginCountdown > 0
                          ? Text(
                              AppLocalization.of(context).translate('auth.seconds_left_to_takeover', args: {'seconds': _loginCountdown.toString()}),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : const DirectionalLocalizedText(
                              'auth.connect',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                    ),
            ),
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
    
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      // DEMO GİRİŞ KONTROLÜ
      if (username.toLowerCase() == 'demo' && password == 'demo') {
        setState(() => _isLoading = true);
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
        _showMaxUserDialog(context);
        return;
      }

      if (_selectedCompany == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.of(context).translate('auth.please_select_company'))),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });
      try {
        final dbService = await DatabaseService.getInstance();
        if (_rememberMe) {
          await dbService.saveCredentials(username, password);
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
              SnackBar(
                  content: Text(loginResult?['error'] ?? AppLocalization.of(context).translate('auth.login_failed'))),
            );
            return;
          }
          await dbService.setUserSession({
            'id': loginResult['user_id'],
            'username': loginResult['username'],
            'role': loginResult['role'],
            'email': loginResult['email'],
            'full_name': loginResult['full_name'],
            'session_id': loginResult['session_id'],
            'company_no': _selectedCompany!.companyNo,
          });
          if (mounted) {
            MenuFixer.fixMenus(context);
            final isMobile = !kIsWeb &&
                (Theme.of(context).platform == TargetPlatform.android ||
                 Theme.of(context).platform == TargetPlatform.iOS);
            if (isMobile) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MobileDashboard(username: 'Kullanıcı')),
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
                    SnackBar(
                        content:
                            Text(retryResult?['error'] ?? AppLocalization.of(context).translate('auth.login_failed'))),
                  );
                  return;
                }
                await dbService.setUserSession({
                  'id': retryResult['user_id'],
                  'username': retryResult['username'],
                  'role': retryResult['role'],
                  'email': retryResult['email'],
                  'full_name': retryResult['full_name'],
                  'session_id': retryResult['session_id'],
                  'company_no': _selectedCompany!.companyNo,
                });
                if (mounted) {
                        MenuFixer.fixMenus(context);
                        final isMobile = !kIsWeb &&
                            (Theme.of(context).platform == TargetPlatform.android ||
                             Theme.of(context).platform == TargetPlatform.iOS);
                        if (isMobile) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => MobileDashboard(username: retryResult['username'] ?? 'Kullanıcı')),
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const DashboardScreen()),
                          );
                        }
                      }
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
                SnackBar(
                    content: Text(retryResult?['error'] ?? 'Giriş başarısız')),
              );
              return;
            }
            await dbService.setUserSession({
              'id': retryResult['user_id'],
              'username': retryResult['username'],
              'role': retryResult['role'],
              'email': retryResult['email'],
              'full_name': retryResult['full_name'],
              'session_id': retryResult['session_id'],
              'company_no': _selectedCompany!.companyNo,
            });
              if (mounted) {
                MenuFixer.fixMenus(context);
                final isMobile = !kIsWeb &&
                    (Theme.of(context).platform == TargetPlatform.android ||
                     Theme.of(context).platform == TargetPlatform.iOS);
                if (isMobile) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MobileDashboard(username: retryResult['username'] ?? 'Kullanıcı')),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  );
                }
              }
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
            SnackBar(content: Text(loginResult?['error'] ?? AppLocalization.of(context).translate('auth.login_failed'))),
          );
          return;
        }
        // Kullanıcı session bilgisini kaydet
        await dbService.setUserSession({
          'id': loginResult['user_id'],
          'username': loginResult['username'],
          'role': loginResult['role'],
          'email': loginResult['email'],
          'full_name': loginResult['full_name'],
          'session_id': loginResult['session_id'],
          'company_no': _selectedCompany!.companyNo,
        });
          if (mounted) {
            setState(() {
              _loginCountdown = 0;
            });
            _loginCountdownTimer?.cancel();
            MenuFixer.fixMenus(context);
            final isMobile = !kIsWeb &&
                (Theme.of(context).platform == TargetPlatform.android ||
                 Theme.of(context).platform == TargetPlatform.iOS);
            if (isMobile) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MobileDashboard(username: loginResult['username'] ?? 'Kullanıcı')),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            }
          }
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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onCompanySelected(Company company) async {
    setState(() {
      _selectedCompany = company;
    });
    final companyNo = company.companyNo;
    debugPrint('[FİRMA SEÇİMİ] Seçilen company_no: $companyNo');
    final dbService = await DatabaseService.getInstance();
    await dbService.updateCompanySelection(company.id);
    // Gerekirse companyNo ile başka işlemler yapılabilir
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
