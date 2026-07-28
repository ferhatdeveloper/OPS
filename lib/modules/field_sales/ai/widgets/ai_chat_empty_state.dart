// Dosya Adı: ai_chat_empty_state.dart
// Açıklama: AI sohbet boş durum — markalı hero + öneri chip’leri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_theme.dart';

/// {@template ai_chat_suggestion}
/// Empty-state öneri chip modeli.
/// {@endtemplate}
class AiChatSuggestion {
  /// [label]: Chip etiketi
  final String label;

  /// [sendText]: Gönderilecek metin
  final String sendText;

  /// [icon]: Opsiyonel ikon
  final IconData? icon;

  /// {@macro ai_chat_suggestion}
  const AiChatSuggestion({
    required this.label,
    required this.sendText,
    this.icon,
  });
}

/// {@template ai_chat_empty_state}
/// Markalı empty state — soft orb + karşılama + öneriler (Gemini kopyası değil).
/// {@endtemplate}
class AiChatEmptyState extends StatelessWidget {
  /// [greeting]: Karşılama
  final String greeting;

  /// [subtitle]: Alt başlık
  final String subtitle;

  /// [suggestions]: Öneri chip’leri
  final List<AiChatSuggestion> suggestions;

  /// [onSuggestion]: Chip tap
  final ValueChanged<String> onSuggestion;

  /// [primary]: Marka rengi
  final Color primary;

  /// {@macro ai_chat_empty_state}
  const AiChatEmptyState({
    Key? key,
    required this.greeting,
    required this.subtitle,
    required this.suggestions,
    required this.onSuggestion,
    this.primary = FieldSalesDensAppBar.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final titleColor = FieldSalesDensTheme.title(context);
    final muted = FieldSalesDensTheme.muted(context);
    final surface = FieldSalesDensTheme.surface(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Soft brand orb
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primary.withValues(alpha: isDark ? 0.35 : 0.22),
                      primary.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: surface,
                      border: Border.all(
                        color: primary.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 26,
                      color: primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                greeting,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: muted,
                ),
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 22),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in suggestions)
                      _SuggestionChip(
                        label: s.label,
                        icon: s.icon,
                        primary: primary,
                        surface: surface,
                        onTap: () => onSuggestion(s.sendText),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color primary;
  final Color surface;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.primary,
    required this.surface,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: primary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
