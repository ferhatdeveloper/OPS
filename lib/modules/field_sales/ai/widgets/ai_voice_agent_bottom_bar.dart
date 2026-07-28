// Dosya Adı: ai_voice_agent_bottom_bar.dart
// Açıklama: Dens AI sohbet kısayol ikonu (opsiyonel; ana bar BottomNavigationBar)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../view/ai_voice_chat_screen.dart';

/// {@template ai_voice_agent_bottom_bar}
/// Dens AI ikonu — BottomNavigationBar yerine tam bar değiştirmez.
///
/// Kullanım örneği:
/// ```dart
/// AiVoiceAgentBottomBar()
/// ```
/// {@endtemplate}
class AiVoiceAgentBottomBar extends StatelessWidget {
  /// [onPressed]: Test inject; null → named route push
  final VoidCallback? onPressed;

  /// [displayName]: Selamlama adı
  final String? displayName;

  /// {@macro ai_voice_agent_bottom_bar}
  const AiVoiceAgentBottomBar({
    Key? key,
    this.onPressed,
    this.displayName,
  }) : super(key: key);

  /// [iconSize]: dens ikon boyutu
  static const double iconSize = 22;

  void _openChat(BuildContext context) {
    if (onPressed != null) {
      onPressed!();
      return;
    }
    Navigator.pushNamed(
      context,
      AiVoiceChatScreen.routeName,
      arguments: displayName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final label = l10n.translate('mobile_dashboard.ai_chat');
    final primary = FieldSalesDensAppBar.primaryColor;

    return Material(
      color: Colors.transparent,
      child: IconButton(
        key: const Key('ai_voice_agent_cta'),
        tooltip: label,
        onPressed: () => _openChat(context),
        icon: Icon(
          Icons.auto_awesome_rounded,
          color: primary,
          size: iconSize,
        ),
      ),
    );
  }
}
