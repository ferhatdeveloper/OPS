// Dosya Adı: weekly_route_weekday.dart
// Açıklama: Haftalık rota planı — DateTime.weekday (1=Pzt … 7=Paz) eşlemesi
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template weekly_route_weekday}
/// Haftanın günü (ISO: 1=Pazartesi … 7=Pazar) ve l10n anahtarları.
///
/// Kullanım örneği:
/// ```dart
/// final today = WeeklyRouteWeekday.fromDateTime(DateTime.now());
/// print(today.l10nKey); // field_sales.weekday_monday
/// ```
/// {@endtemplate}
class WeeklyRouteWeekday {
  /// [monday] … [sunday]: Dart [DateTime.weekday] değerleri
  static const int monday = DateTime.monday;
  static const int tuesday = DateTime.tuesday;
  static const int wednesday = DateTime.wednesday;
  static const int thursday = DateTime.thursday;
  static const int friday = DateTime.friday;
  static const int saturday = DateTime.saturday;
  static const int sunday = DateTime.sunday;

  /// Pazartesi→Pazar sırası (TabBar)
  static const List<int> allDays = <int>[
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
    sunday,
  ];

  /// [dayOfWeek]: 1–7
  final int dayOfWeek;

  /// {@macro weekly_route_weekday}
  const WeeklyRouteWeekday(this.dayOfWeek)
      : assert(dayOfWeek >= 1 && dayOfWeek <= 7);

  /// {@template weekly_route_weekday_from_datetime}
  /// [DateTime.weekday] ile oluşturur.
  ///
  /// Parametreler:
  /// - [date]: Kaynak tarih
  ///
  /// Dönüş değeri:
  /// - [WeeklyRouteWeekday]: Günün eşlemesi
  /// {@endtemplate}
  factory WeeklyRouteWeekday.fromDateTime(DateTime date) {
    return WeeklyRouteWeekday(date.weekday);
  }

  /// {@template weekly_route_weekday_try_parse}
  /// 1–7 dışı değeri reddeder (null).
  ///
  /// Parametreler:
  /// - [value]: Ham gün numarası
  ///
  /// Dönüş değeri:
  /// - [WeeklyRouteWeekday?]: Geçerliyse örnek
  /// {@endtemplate}
  static WeeklyRouteWeekday? tryParse(int? value) {
    if (value == null || value < 1 || value > 7) return null;
    return WeeklyRouteWeekday(value);
  }

  /// {@template weekly_route_weekday_index}
  /// TabBar indeksi (0=Pzt … 6=Paz).
  /// {@endtemplate}
  int get tabIndex => dayOfWeek - 1;

  /// {@template weekly_route_weekday_from_tab}
  /// TabBar indeksinden gün.
  ///
  /// Parametreler:
  /// - [index]: 0–6
  ///
  /// Dönüş değeri:
  /// - [WeeklyRouteWeekday]: Gün
  /// {@endtemplate}
  static WeeklyRouteWeekday fromTabIndex(int index) {
    final clamped = index.clamp(0, 6);
    return WeeklyRouteWeekday(clamped + 1);
  }

  /// {@template weekly_route_weekday_l10n_key}
  /// Kısa gün adı çeviri anahtarı.
  /// {@endtemplate}
  String get l10nKey {
    switch (dayOfWeek) {
      case monday:
        return 'field_sales.weekday_monday';
      case tuesday:
        return 'field_sales.weekday_tuesday';
      case wednesday:
        return 'field_sales.weekday_wednesday';
      case thursday:
        return 'field_sales.weekday_thursday';
      case friday:
        return 'field_sales.weekday_friday';
      case saturday:
        return 'field_sales.weekday_saturday';
      case sunday:
        return 'field_sales.weekday_sunday';
      default:
        return 'field_sales.weekday_monday';
    }
  }

  /// {@template weekly_route_weekday_route_id}
  /// Offline haftalık plan için kararlı rota kimliği.
  /// Personel verilirse plasiyer bazlı ayrı plan (`weekly-route-sp-…`).
  ///
  /// Parametreler:
  /// - [salespersonId]: users.id; boş/null = paylaşılan gün planı
  ///
  /// Dönüş değeri:
  /// - [String]: routes.id
  /// {@endtemplate}
  String stableRouteId({String? salespersonId}) {
    final sp = salespersonId?.trim() ?? '';
    if (sp.isEmpty) return 'weekly-route-dow-$dayOfWeek';
    final safe = sp.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return 'weekly-route-sp-$safe-dow-$dayOfWeek';
  }

  /// {@template weekly_route_weekday_default_route_name}
  /// SQLite `routes.name` için dahili etiket (UI l10n kullanır).
  /// {@endtemplate}
  String get defaultRouteName => 'Weekly DOW $dayOfWeek';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyRouteWeekday && other.dayOfWeek == dayOfWeek;

  @override
  int get hashCode => dayOfWeek.hashCode;
}
