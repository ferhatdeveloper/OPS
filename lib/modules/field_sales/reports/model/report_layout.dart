// Dosya Adı: report_layout.dart
// Açıklama: Rapor dizayn şeması (header · sütun · group/totals · footer)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'report_layout_column.dart';
import 'report_layout_page_size.dart';

/// {@template report_layout}
/// In-app rapor dizaynı — DevExpress `.repx` yerine JSON şema.
///
/// Kullanım örneği:
/// ```dart
/// final layout = ReportLayout(
///   reportId: 'cari_extre',
///   titleKey: 'field_sales.mbt_reports.cari_extre',
///   columns: const [],
/// );
/// final visible = layout.visibleColumns;
/// ```
/// {@endtemplate}
class ReportLayout {
  /// [schemaVersion]: Şema sürümü (ileride migrate)
  static const int schemaVersion = 1;

  /// [reportId]: Katalog id (`MbtReportDefinition.id`)
  final String reportId;

  /// [titleKey]: Başlık l10n (katalog ile aynı olabilir)
  final String titleKey;

  /// [pageSize]: Sayfa boyutu
  final ReportLayoutPageSize pageSize;

  /// [showHeader]: Üst bilgi (başlık + dönem + cari)
  final bool showHeader;

  /// [showFooter]: Alt bilgi (sayfa no vb.)
  final bool showFooter;

  /// [showTotals]: Görünür toplam sütunları için alt satır
  final bool showTotals;

  /// [dense]: Dens satır aralığı (PDF / liste)
  final bool dense;

  /// [groupByColumnId]: Gruplama sütunu (opsiyonel)
  final String? groupByColumnId;

  /// [columns]: Sıralı sütun listesi
  final List<ReportLayoutColumn> columns;

  /// [locale]: PDF / başlık dil kodu (tr, en, ar, …).
  /// null veya boş → ayarlar varsayılanı → uygulama dili.
  final String? locale;

  /// {@macro report_layout}
  const ReportLayout({
    required this.reportId,
    required this.titleKey,
    this.pageSize = ReportLayoutPageSize.a4,
    this.showHeader = true,
    this.showFooter = true,
    this.showTotals = false,
    this.dense = true,
    this.groupByColumnId,
    required this.columns,
    this.locale,
  });

  /// {@template report_layout_visible_columns}
  /// Yalnızca görünür sütunlar (sıra korunur).
  ///
  /// Dönüş değeri:
  /// - [List<ReportLayoutColumn>]: Görünür sütunlar
  /// {@endtemplate}
  List<ReportLayoutColumn> get visibleColumns =>
      columns.where((c) => c.visible).toList(growable: false);

  /// {@template report_layout_toggle_column}
  /// Sütun görünürlüğünü değiştirir.
  ///
  /// Parametreler:
  /// - [columnId]: Hedef sütun
  /// - [visible]: Yeni durum (null → tersine çevir)
  ///
  /// Dönüş değeri:
  /// - [ReportLayout]: Yeni layout
  /// {@endtemplate}
  ReportLayout toggleColumn(String columnId, {bool? visible}) {
    final next = columns
        .map((c) {
          if (c.id != columnId) return c;
          return c.copyWith(visible: visible ?? !c.visible);
        })
        .toList(growable: false);
    return copyWith(columns: next);
  }

  /// {@template report_layout_reorder_columns}
  /// Sütun sırasını değiştirir (eski index → yeni index).
  ///
  /// Parametreler:
  /// - [oldIndex]: Kaynak
  /// - [newIndex]: Hedef (ReorderableListView semantiği)
  ///
  /// Dönüş değeri:
  /// - [ReportLayout]: Yeni layout
  /// {@endtemplate}
  ReportLayout reorderColumns(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= columns.length) return this;
    var target = newIndex;
    if (oldIndex < target) target -= 1;
    if (target < 0 || target >= columns.length) return this;
    final list = List<ReportLayoutColumn>.from(columns);
    final item = list.removeAt(oldIndex);
    list.insert(target, item);
    return copyWith(columns: list);
  }

  /// {@template report_layout_copy_with}
  /// Kopya.
  /// {@endtemplate}
  ReportLayout copyWith({
    String? reportId,
    String? titleKey,
    ReportLayoutPageSize? pageSize,
    bool? showHeader,
    bool? showFooter,
    bool? showTotals,
    bool? dense,
    String? groupByColumnId,
    bool clearGroupBy = false,
    List<ReportLayoutColumn>? columns,
    String? locale,
    bool clearLocale = false,
  }) {
    return ReportLayout(
      reportId: reportId ?? this.reportId,
      titleKey: titleKey ?? this.titleKey,
      pageSize: pageSize ?? this.pageSize,
      showHeader: showHeader ?? this.showHeader,
      showFooter: showFooter ?? this.showFooter,
      showTotals: showTotals ?? this.showTotals,
      dense: dense ?? this.dense,
      groupByColumnId:
          clearGroupBy ? null : (groupByColumnId ?? this.groupByColumnId),
      columns: columns ?? this.columns,
      locale: clearLocale ? null : (locale ?? this.locale),
    );
  }

  /// {@template report_layout_to_json}
  /// SQLite / SharedPreferences JSON.
  /// {@endtemplate}
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'reportId': reportId,
        'titleKey': titleKey,
        'pageSize': pageSize.storageKey,
        'showHeader': showHeader,
        'showFooter': showFooter,
        'showTotals': showTotals,
        'dense': dense,
        'groupByColumnId': groupByColumnId,
        'locale': locale,
        'columns': columns.map((c) => c.toJson()).toList(growable: false),
      };

  /// {@template report_layout_from_json}
  /// JSON → layout.
  /// {@endtemplate}
  factory ReportLayout.fromJson(Map<String, dynamic> json) {
    final rawCols = json['columns'];
    final cols = <ReportLayoutColumn>[];
    if (rawCols is List) {
      for (final item in rawCols) {
        if (item is Map<String, dynamic>) {
          cols.add(ReportLayoutColumn.fromJson(item));
        } else if (item is Map) {
          cols.add(
            ReportLayoutColumn.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    final rawLocale = json['locale'] as String?;
    final localeTrimmed = rawLocale?.trim();
    return ReportLayout(
      reportId: json['reportId'] as String? ?? '',
      titleKey: json['titleKey'] as String? ?? '',
      pageSize: ReportLayoutPageSizeX.parse(json['pageSize'] as String?),
      showHeader: json['showHeader'] as bool? ?? true,
      showFooter: json['showFooter'] as bool? ?? true,
      showTotals: json['showTotals'] as bool? ?? false,
      dense: json['dense'] as bool? ?? true,
      groupByColumnId: json['groupByColumnId'] as String?,
      columns: cols,
      locale: (localeTrimmed == null || localeTrimmed.isEmpty)
          ? null
          : localeTrimmed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! ReportLayout) return false;
    if (other.reportId != reportId ||
        other.titleKey != titleKey ||
        other.pageSize != pageSize ||
        other.showHeader != showHeader ||
        other.showFooter != showFooter ||
        other.showTotals != showTotals ||
        other.dense != dense ||
        other.groupByColumnId != groupByColumnId ||
        other.locale != locale ||
        other.columns.length != columns.length) {
      return false;
    }
    for (var i = 0; i < columns.length; i++) {
      if (columns[i] != other.columns[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        reportId,
        titleKey,
        pageSize,
        showHeader,
        showFooter,
        showTotals,
        dense,
        groupByColumnId,
        locale,
        Object.hashAll(columns),
      );
}
