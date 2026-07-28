// Dosya Adı: barcode_scanner_screen.dart
// Açıklama: Eski stub kamera UI → gerçek dens barkod lookup sarmalayıcı
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../barcode/view/barcode_scan_screen.dart';

/// {@template barcode_scanner_screen}
/// Geriye uyumlu alias: Stok menü / dashboard “Barkod Ekle”.
/// Gerçek kamera + SQLite ürün lookup [BarcodeScanScreen] üzerindedir.
///
/// Kullanım örneği:
/// ```dart
/// const BarcodeScannerScreen();
/// ```
/// {@endtemplate}
class BarcodeScannerScreen extends StatelessWidget {
  /// {@macro barcode_scanner_screen}
  const BarcodeScannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BarcodeScanScreen(
      selectionMode: false,
      autoScanOnOpen: true,
    );
  }
}
