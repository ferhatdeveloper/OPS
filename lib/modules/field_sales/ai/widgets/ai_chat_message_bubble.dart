// Dosya Adı: ai_chat_message_bubble.dart
// Açıklama: AI sohbet balonları — avatar + asimetrik kart
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/ai/features/ai_chat_reply_sanitizer.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_theme.dart';

/// {@template ai_chat_user_bubble}
/// Kullanıcı balonu — primary, sağ hizalı.
/// {@endtemplate}
class AiChatUserBubble extends StatelessWidget {
  /// [text]: Mesaj
  final String text;

  /// [hasImage]: Görsel var mı
  final bool hasImage;

  /// [imageLabel]: Görsel etiketi
  final String? imageLabel;

  /// [timeLabel]: Saat
  final String? timeLabel;

  /// [isPartial]: STT partial (soluk)
  final bool isPartial;

  /// [primary]: Marka
  final Color primary;

  /// {@macro ai_chat_user_bubble}
  const AiChatUserBubble({
    Key? key,
    required this.text,
    this.hasImage = false,
    this.imageLabel,
    this.timeLabel,
    this.isPartial = false,
    this.primary = FieldSalesDensAppBar.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width * 0.78;
    final display = hasImage && text.isNotEmpty
        ? text
        : (hasImage ? (imageLabel ?? text) : text);

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, top: 2),
        constraints: BoxConstraints(maxWidth: maxW),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Opacity(
              opacity: isPartial ? 0.72 : 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(18),
                    topEnd: Radius.circular(18),
                    bottomStart: Radius.circular(18),
                    bottomEnd: Radius.circular(6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasImage) ...[
                      const Icon(
                        Icons.image_outlined,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        display,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.38,
                          fontWeight: FontWeight.w500,
                          fontStyle:
                              isPartial ? FontStyle.italic : FontStyle.normal,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (timeLabel != null && timeLabel!.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 4, end: 4),
                child: Text(
                  timeLabel!,
                  style: TextStyle(
                    fontSize: 10,
                    color: FieldSalesDensTheme.muted(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// {@template ai_chat_assistant_bubble}
/// Asistan balonu — avatar + surface kart.
/// {@endtemplate}
class AiChatAssistantBubble extends StatelessWidget {
  /// [text]: Yanıt
  final String text;

  /// [timeLabel]: Saat
  final String? timeLabel;

  /// [footerLabel]: Alt etiket
  final String? footerLabel;

  /// [pdfSlot]: PDF kartı
  final Widget? pdfSlot;

  /// [actions]: Aksiyon ikonları
  final List<Widget> actions;

  /// [primary]: Avatar rengi
  final Color primary;

  /// {@macro ai_chat_assistant_bubble}
  const AiChatAssistantBubble({
    Key? key,
    required this.text,
    this.timeLabel,
    this.footerLabel,
    this.pdfSlot,
    this.actions = const [],
    this.primary = FieldSalesDensAppBar.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final surface = FieldSalesDensTheme.surface(context);
    final border = FieldSalesDensTheme.border(context);
    final titleColor = FieldSalesDensTheme.title(context);
    final muted = FieldSalesDensTheme.muted(context);
    final maxW = MediaQuery.of(context).size.width * 0.9;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, top: 2),
        constraints: BoxConstraints(maxWidth: maxW),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsetsDirectional.only(end: 8, top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: primary.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: primary,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: const BorderRadiusDirectional.only(
                        topStart: Radius.circular(6),
                        topEnd: Radius.circular(18),
                        bottomStart: Radius.circular(18),
                        bottomEnd: Radius.circular(18),
                      ),
                      border: Border.all(color: border),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AiMarkdownText(
                          text: AiChatReplySanitizer.forDisplay(text),
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.42,
                            fontWeight: FontWeight.w500,
                            color: titleColor,
                          ),
                        ),
                        if (pdfSlot != null) ...[
                          const SizedBox(height: 10),
                          pdfSlot!,
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ...actions,
                            const Spacer(),
                            if (footerLabel != null)
                              Text(
                                footerLabel!,
                                style: TextStyle(fontSize: 10, color: muted),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (timeLabel != null && timeLabel!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: 4,
                        start: 4,
                      ),
                      child: Text(
                        timeLabel!,
                        style: TextStyle(fontSize: 10, color: muted),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Basit **kalın** markdown — ham `**` göstermez.
class _AiMarkdownText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _AiMarkdownText({
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;
      final bold = i.isOdd;
      spans.add(
        TextSpan(
          text: part,
          style: bold
              ? style.copyWith(fontWeight: FontWeight.w700)
              : style,
        ),
      );
    }
    if (spans.isEmpty) {
      return Text(text, style: style);
    }
    return Text.rich(TextSpan(children: spans));
  }
}
