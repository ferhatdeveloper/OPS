// Dosya Adı: auto_login_bootstrap.dart
// Açıklama: Uygulama açılışında beni hatırla → dashboard veya login
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/auth/remember_me_store.dart';
import '../core/tenant/postgrest_tenant_service.dart';
import '../modules/field_sales/companies/viewmodel/active_company_store.dart';
import '../modules/field_sales/stock/viewmodel/active_warehouse_store.dart';
import '../service/auth_service.dart';
import '../service/database_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'mobile_dashboard.dart';

/// {@template auto_login_bootstrap}
/// Splash sonrası home: geçerli remember-me oturumu varsa dashboard,
/// yoksa [LoginScreen]. UI redesign yok — yalnızca yönlendirme.
///
/// Kullanım örneği:
/// ```dart
/// home: const AutoLoginBootstrap(),
/// ```
/// {@endtemplate}
class AutoLoginBootstrap extends StatefulWidget {
  /// [rememberMeStore]: Test enjeksiyonu
  final RememberMeStore rememberMeStore;

  /// {@macro auto_login_bootstrap}
  const AutoLoginBootstrap({
    super.key,
    this.rememberMeStore = const RememberMeStore(),
  });

  @override
  State<AutoLoginBootstrap> createState() => _AutoLoginBootstrapState();
}

class _AutoLoginBootstrapState extends State<AutoLoginBootstrap> {
  Widget? _child;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final store = widget.rememberMeStore;
      if (await store.canAutoLogin()) {
        final session = await store.load();
        if (session != null && session.isValid) {
          await _restoreContext(session.tenantCode);
          final db = await DatabaseService.getInstance();
          var userSession = await db.getUserSession();
          if (userSession == null ||
              (userSession['session_id']?.toString() ?? '').isEmpty) {
            await db.setUserSession(session.toUserSessionMap());
            userSession = session.toUserSessionMap();
          }
          await db.saveAuthToken(session.sessionToken);
          AuthService.restoreSession(
            username: session.username,
            sessionId: session.sessionToken,
          );
          if (!mounted) return;
          final isMobile = !kIsWeb &&
              (Theme.of(context).platform == TargetPlatform.android ||
                  Theme.of(context).platform == TargetPlatform.iOS);
          final uname = session.username.isNotEmpty
              ? session.username
              : (userSession['username']?.toString() ?? 'Kullanıcı');
          setState(() {
            _child = isMobile
                ? MobileDashboard(username: uname)
                : const DashboardScreen();
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('AutoLoginBootstrap: $e');
      try {
        await widget.rememberMeStore.clear();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _child = const LoginScreen());
  }

  Future<void> _restoreContext(String tenantCode) async {
    try {
      await const ActiveCompanyStore().load();
      await const ActiveWarehouseStore().load();
    } catch (e) {
      debugPrint('AutoLoginBootstrap context stores: $e');
    }
    try {
      await PostgrestTenantService().restoreActiveContext();
      if (tenantCode.trim().isEmpty) {
        debugPrint('AutoLoginBootstrap: tenant kodu boş (prefs yedek)');
      }
    } catch (e) {
      debugPrint('AutoLoginBootstrap tenant: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_child != null) return _child!;
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
