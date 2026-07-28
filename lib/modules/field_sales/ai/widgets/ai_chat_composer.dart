// Dosya Adı: ai_chat_composer.dart
// Açıklama: AI sohbet floating composer — metin + mic odaklı
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_theme.dart';

/// {@template ai_chat_composer}
/// Alt floating composer: ekler + yuvarlak giriş + mic CTA.
/// {@endtemplate}
class AiChatComposer extends StatelessWidget {
  /// [controller]: Metin
  final TextEditingController controller;

  /// [focusNode]: Focus
  final FocusNode focusNode;

  /// [hintText]: Hint
  final String hintText;

  /// [cameraTooltip]: Kamera
  final String cameraTooltip;

  /// [galleryTooltip]: Galeri
  final String galleryTooltip;

  /// [sendTooltip]: Gönder
  final String sendTooltip;

  /// [micTooltip]: Mic
  final String micTooltip;

  /// [enabled]: Busy değil
  final bool enabled;

  /// [listening]: STT
  final bool listening;

  /// [speaking]: TTS
  final bool speaking;

  /// [voiceFocused]: Ses seviyesi yeterli
  final bool voiceFocused;

  /// [onSend]: Gönder
  final VoidCallback? onSend;

  /// [onMic]: Mic
  final VoidCallback? onMic;

  /// [onCamera]: Kamera
  final VoidCallback? onCamera;

  /// [onGallery]: Galeri
  final VoidCallback? onGallery;

  /// [primary]: Marka
  final Color primary;

  /// {@macro ai_chat_composer}
  const AiChatComposer({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.cameraTooltip,
    required this.galleryTooltip,
    required this.sendTooltip,
    required this.micTooltip,
    required this.enabled,
    required this.listening,
    required this.speaking,
    required this.onSend,
    required this.onMic,
    required this.onCamera,
    required this.onGallery,
    this.voiceFocused = false,
    this.primary = FieldSalesDensAppBar.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final surface = FieldSalesDensTheme.surface(context);
    final border = FieldSalesDensTheme.border(context);
    final onBody = FieldSalesDensTheme.title(context);
    final onMuted = FieldSalesDensTheme.muted(context);
    final bodyBg = FieldSalesDensTheme.bodyBackground(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: bodyBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: listening
                    ? primary.withValues(alpha: 0.55)
                    : border,
                width: listening ? 1.5 : 1,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 4, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _CircleIcon(
                  icon: Icons.photo_camera_outlined,
                  tooltip: cameraTooltip,
                  color: onMuted,
                  onTap: enabled ? onCamera : null,
                ),
                _CircleIcon(
                  icon: Icons.image_outlined,
                  tooltip: galleryTooltip,
                  color: onMuted,
                  onTap: enabled ? onGallery : null,
                ),
                Expanded(
                  child: TextField(
                    key: const Key('ai_chat_text_field'),
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 4,
                    style: TextStyle(fontSize: 15, color: onBody, height: 1.3),
                    textInputAction: TextInputAction.send,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    onSubmitted: (_) {
                      if (enabled) onSend?.call();
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: hintText,
                      hintStyle: TextStyle(fontSize: 15, color: onMuted),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                _CircleIcon(
                  key: const Key('ai_chat_send'),
                  icon: Icons.arrow_upward_rounded,
                  tooltip: sendTooltip,
                  color: primary,
                  filled: true,
                  onTap: enabled ? onSend : null,
                ),
                const SizedBox(width: 2),
                _MicButton(
                  key: const Key('ai_chat_mic'),
                  tooltip: micTooltip,
                  listening: listening,
                  speaking: speaking,
                  voiceFocused: voiceFocused,
                  primary: primary,
                  onTap: enabled ? onMic : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;
  final bool filled;

  const _CircleIcon({
    Key? key,
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.filled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: key,
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: filled ? 18 : 20),
      color: filled ? Colors.white : color,
      style: filled
          ? IconButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            )
          : IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
      splashRadius: 18,
    );
  }
}

class _MicButton extends StatelessWidget {
  final String tooltip;
  final bool listening;
  final bool speaking;
  final bool voiceFocused;
  final Color primary;
  final VoidCallback? onTap;

  const _MicButton({
    Key? key,
    required this.tooltip,
    required this.listening,
    required this.speaking,
    required this.voiceFocused,
    required this.primary,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final active = listening || speaking;
    final bg = active
        ? (voiceFocused || speaking
            ? primary
            : primary.withValues(alpha: 0.55))
        : primary.withValues(alpha: 0.12);
    final fg = active ? Colors.white : primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 1, right: 2),
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          key: key,
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                listening || speaking ? Icons.mic : Icons.mic_none_rounded,
                color: fg,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
