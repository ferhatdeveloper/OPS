// Dosya Adı: appearance_settings_record.dart
// Açıklama: Font büyüklüğü + tema rengi görünüm ayarları modeli
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

import '../../shared/view/field_sales_dens_app_bar.dart';

/// {@template appearance_settings_record}
/// Uygulama görünüm ayarları (font büyüklüğü + primary renk).
///
/// Kullanım örneği:
/// ```dart
/// const record = AppearanceSettingsRecord();
/// final scale = record.textScaleFactor;
/// ```
/// {@endtemplate}
class AppearanceSettingsRecord {
  /// [minFontSize]: Slider alt sınır
  static const double minFontSize = 8;

  /// [maxFontSize]: Slider üst sınır
  static const double maxFontSize = 20;

  /// [defaultFontSize]: Varsayılan / ölçek referansı
  static const double defaultFontSize = 14;

  /// [defaultPrimaryColor]: Mevcut dens primary (375A7F)
  static const Color defaultPrimaryColor = FieldSalesDensAppBar.primaryColor;

  /// [defaultPrimaryColorValue]: Varsayılan primary ARGB
  static const int defaultPrimaryColorValue = 0xFF375A7F;

  /// [fontSize]: Mantıksal font büyüklüğü (8–20)
  final double fontSize;

  /// [primaryColorValue]: ARGB primary renk
  final int primaryColorValue;

  /// {@macro appearance_settings_record}
  const AppearanceSettingsRecord({
    this.fontSize = defaultFontSize,
    this.primaryColorValue = defaultPrimaryColorValue,
  });

  /// [primaryColor]: Theme / accent rengi
  Color get primaryColor => Color(primaryColorValue);

  /// [textScaleFactor]: MediaQuery textScaler çarpanı
  double get textScaleFactor => fontSize / defaultFontSize;

  /// {@template appearance_settings_record_clamp_font}
  /// Font değerini min/max aralığına sıkıştırır.
  ///
  /// Parametreler:
  /// - [value]: Ham font değeri
  ///
  /// Dönüş değeri:
  /// - [double]: Sıkıştırılmış değer
  /// {@endtemplate}
  static double clampFontSize(double value) {
    return value.clamp(minFontSize, maxFontSize).toDouble();
  }

  /// {@template appearance_settings_record_copy_with}
  /// Kopya oluşturur.
  /// {@endtemplate}
  AppearanceSettingsRecord copyWith({
    double? fontSize,
    int? primaryColorValue,
  }) {
    return AppearanceSettingsRecord(
      fontSize: fontSize ?? this.fontSize,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppearanceSettingsRecord &&
        other.fontSize == fontSize &&
        other.primaryColorValue == primaryColorValue;
  }

  @override
  int get hashCode => Object.hash(fontSize, primaryColorValue);
}
