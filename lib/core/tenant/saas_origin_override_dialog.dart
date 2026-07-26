// Dosya Adı: saas_origin_override_dialog.dart
// Açıklama: Login gelişmiş SaaS PostgREST kök override dialogu
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../localization/app_localization.dart';
import 'postgrest_tenant_defaults.dart';
import 'tenant_connection_resolver.dart';
import 'tenant_store.dart';

/// {@template show_saas_origin_override_dialog}
/// Gizli / ayar menüsünden SaaS kök URL override diyalogu.
///
/// Kullanım örneği:
/// ```dart
/// await showSaasOriginOverrideDialog(context);
/// ```
/// {@endtemplate}
Future<bool> showSaasOriginOverrideDialog(BuildContext context) async {
  final store = const TenantStore();
  final currentOverride = await store.loadSaasOriginOverride();
  final controller = TextEditingController(
    text: currentOverride.isEmpty
        ? PostgrestTenantDefaults.saasOrigin
        : currentOverride,
  );

  try {
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalization.of(ctx);
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final inputFillColor = isDark ? Colors.grey[850] : Colors.white;
        final inputTextColor = isDark ? Colors.white : Colors.black87;
        final inputHintColor = isDark ? Colors.white70 : Colors.grey[600];
        String? errorText;

        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: Theme.of(ctx).cardColor,
              title: Text(
                l10n.translate('auth.saas_origin_title'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF054F99),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('auth.saas_origin_hint'),
                      style: TextStyle(
                        fontSize: 13,
                        color: inputHintColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      style: TextStyle(color: inputTextColor),
                      textCapitalization: TextCapitalization.none,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText:
                            l10n.translate('auth.saas_origin_label'),
                        hintText: PostgrestTenantDefaults.saasOrigin,
                        prefixIcon: const Icon(Icons.dns_outlined),
                        filled: true,
                        fillColor: inputFillColor,
                        labelStyle: TextStyle(color: inputTextColor),
                        hintStyle: TextStyle(color: inputHintColor),
                        errorText: errorText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await store.saveSaasOrigin('');
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  },
                  child: Text(l10n.translate('auth.saas_origin_reset')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.translate('common.cancel')),
                ),
                TextButton(
                  onPressed: () async {
                    final raw = controller.text.trim();
                    final err = _validateSaasOrigin(raw, l10n);
                    if (err != null) {
                      setLocal(() => errorText = err);
                      return;
                    }
                    final normalized =
                        TenantConnectionResolver.normalizeBaseUrl(raw);
                    final isDefault = normalized ==
                        PostgrestTenantDefaults.saasOrigin;
                    await store.saveSaasOrigin(
                      isDefault ? '' : normalized,
                    );
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  },
                  child: Text(l10n.translate('common.save')),
                ),
              ],
            );
          },
        );
      },
    );
    return saved == true;
  } finally {
    controller.dispose();
  }
}

/// Origin URL doğrulaması (http/https + host).
String? _validateSaasOrigin(String raw, AppLocalization l10n) {
  if (raw.trim().isEmpty) {
    return l10n.translate('auth.saas_origin_invalid');
  }
  final uri = Uri.tryParse(raw.trim());
  if (uri == null ||
      !uri.hasScheme ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty) {
    return l10n.translate('auth.saas_origin_invalid');
  }
  return null;
}
