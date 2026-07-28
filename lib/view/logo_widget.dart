import 'package:flutter/material.dart';

import '../core/localization/app_localization.dart';

class ExfinLogo extends StatelessWidget {
  final double height;
  final bool showText; // Geriye dönük uyumluluk için, metin logonun içinde.

  const ExfinLogo({Key? key, this.height = 60.0, this.showText = true})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/OPS_cropped.png', // Saydam boşlukları alınmış versiyon
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        final l10n = AppLocalization.of(context);
        return Text(
          l10n.translate('branding.app_logo_missing'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: height * 0.18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        );
      },
    );
  }
}
