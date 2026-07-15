import 'package:flutter/material.dart';
import '../localization/app_localization.dart';

/// Dil yönü desteği eklemek için kullanılan yardımcı widget
class DirectionalText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;
  final TextWidthBasis? textWidthBasis;

  const DirectionalText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
    this.textWidthBasis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mevcut dil yönünü kullan
    final textDirection = Directionality.of(context);

    return Text(
      text,
      style: style,
      textAlign:
          textAlign ??
          (textDirection == TextDirection.rtl
              ? TextAlign.right
              : TextAlign.left),
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textWidthBasis: textWidthBasis,
      textDirection: textDirection,
    );
  }
}

/// Otomatik dil çevirisi ve dil yönü desteği sağlayan widget
class DirectionalLocalizedText extends StatelessWidget {
  final String textKey;
  final Map<String, String>? args;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;
  final TextWidthBasis? textWidthBasis;

  const DirectionalLocalizedText(
    this.textKey, {
    Key? key,
    this.args,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
    this.textWidthBasis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Çeviri yap
    final String translatedText = AppLocalization.of(
      context,
    ).translate(textKey, args: args);

    // Çevrilen metni DirectionalText ile göster
    return DirectionalText(
      translatedText,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textWidthBasis: textWidthBasis,
    );
  }
}

/// Form alanları için RTL desteği sağlayan TextFormField
class DirectionalTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final InputBorder? border;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final bool readOnly;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  const DirectionalTextFormField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.border,
    this.keyboardType,
    this.onTap,
    this.readOnly = false,
    this.focusNode,
    this.onChanged,
    this.onFieldSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mevcut dil yönünü kullan
    final textDirection = Directionality.of(context);

    return TextFormField(
      controller: controller,
      textDirection: textDirection,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: border ?? const OutlineInputBorder(),
        // ErrorText kullanmak yerine validator'u olduğu gibi bırak
        alignLabelWithHint: true,
      ),
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      onTap: onTap,
      readOnly: readOnly,
      focusNode: focusNode,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      textAlign:
          textDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left,
    );
  }
}

/// Hata durumlarında loglama yapan yardımcı metod
void debugLog(String message) {
  print('DIRECTIONAL-WIDGET: $message');
}
