// Dosya Adı: app_navigator.dart
// Açıklama: Servis katmanından diyalog / named route için kök Navigator key
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

/// {@template app_navigator}
/// MaterialApp `navigatorKey` — bildirim / geofence gibi context-dışı
/// katmanlardan sayfa ve diyalog açmak için.
///
/// Kullanım örneği:
/// ```dart
/// AppNavigator.state?.pushNamed('/field-sales/visit-form', arguments: id);
/// ```
/// {@endtemplate}
class AppNavigator {
  /// [key]: Kök NavigatorState anahtarı
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  /// [context]: Aktif navigator context (yoksa null)
  static BuildContext? get context => key.currentContext;

  /// [state]: Aktif NavigatorState (yoksa null)
  static NavigatorState? get state => key.currentState;
}
