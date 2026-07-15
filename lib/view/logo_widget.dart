import 'package:flutter/material.dart';

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
    );
  }
}

