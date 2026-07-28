// Dosya Adı: field_sales_dens_theme.dart
// Açıklama: Dens body kontrast — koyu temada okunabilirlik (palet redesign yok)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

/// {@template field_sales_dens_theme}
/// Dens ekranlarda light/dark okunabilirlik yardımcıları.
///
/// Light'ta mevcut dens slate (2C3E50) korunur; dark'ta
/// [ColorScheme.onSurface] / [onSurfaceVariant] kullanılır.
///
/// Kullanım örneği:
/// ```dart
/// Text('Başlık', style: TextStyle(color: FieldSalesDensTheme.title(context)));
/// ```
/// {@endtemplate}
class FieldSalesDensTheme {
  FieldSalesDensTheme._();

  /// Light dens başlık / satır rengi (mevcut dil)
  static const Color lightTitle = Color(0xFF2C3E50);

  /// Light dens soft body arka plan (mevcut dil)
  static const Color lightBodyBg = Color(0xFFF8F9FD);

  /// {@template field_sales_dens_theme_body_background}
  /// Scaffold body arka planı — dark'ta tema scaffold.
  ///
  /// Dönüş değeri:
  /// - [Color]: Tema uyumlu body arka plan
  /// {@endtemplate}
  static Color bodyBackground(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) {
      return theme.scaffoldBackgroundColor;
    }
    return lightBodyBg;
  }

  /// {@template field_sales_dens_theme_title}
  /// Ana metin / liste başlık rengi.
  ///
  /// Dönüş değeri:
  /// - [Color]: Light → 2C3E50, dark → onSurface
  /// {@endtemplate}
  static Color title(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) {
      return theme.colorScheme.onSurface;
    }
    return lightTitle;
  }

  /// {@template field_sales_dens_theme_muted}
  /// İkincil / hint metin rengi.
  ///
  /// Dönüş değeri:
  /// - [Color]: onSurfaceVariant veya light grey
  /// {@endtemplate}
  static Color muted(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) {
      return theme.colorScheme.onSurfaceVariant;
    }
    return Colors.grey.shade600;
  }

  /// {@template field_sales_dens_theme_surface}
  /// Kart / bubble / filter şerit yüzeyi.
  ///
  /// Dönüş değeri:
  /// - [Color]: colorScheme.surface (dark) veya beyaz (light)
  /// {@endtemplate}
  static Color surface(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) {
      return theme.colorScheme.surface;
    }
    return Colors.white;
  }

  /// {@template field_sales_dens_theme_border}
  /// İnce kenarlık.
  ///
  /// Dönüş değeri:
  /// - [Color]: Tema uyumlu border
  /// {@endtemplate}
  static Color border(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) {
      return theme.colorScheme.onSurface.withValues(alpha: 0.18);
    }
    return Colors.black12;
  }
}
