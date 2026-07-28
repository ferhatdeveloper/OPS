// Dosya Adı: report_layout_column.dart
// Açıklama: Rapor dizayn sütun tanımı (göster/gizle · sıra · hizalama)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template report_layout_column_align}
/// Sütun hizalaması.
/// {@endtemplate}
enum ReportLayoutColumnAlign {
  /// Sol
  left,

  /// Orta
  center,

  /// Sağ (tutar / bakiye)
  right,
}

/// {@template report_layout_column_align_x}
/// Align serileştirme.
/// {@endtemplate}
extension ReportLayoutColumnAlignX on ReportLayoutColumnAlign {
  /// [storageKey]: JSON
  String get storageKey {
    switch (this) {
      case ReportLayoutColumnAlign.left:
        return 'left';
      case ReportLayoutColumnAlign.center:
        return 'center';
      case ReportLayoutColumnAlign.right:
        return 'right';
    }
  }

  /// {@template report_layout_column_align_parse}
  /// Parse; bilinmeyen → left.
  /// {@endtemplate}
  static ReportLayoutColumnAlign parse(String? raw) {
    switch (raw) {
      case 'center':
        return ReportLayoutColumnAlign.center;
      case 'right':
        return ReportLayoutColumnAlign.right;
      case 'left':
      default:
        return ReportLayoutColumnAlign.left;
    }
  }
}

/// {@template report_layout_column}
/// Tek sütun — id stabil; başlık l10n key.
///
/// Kullanım örneği:
/// ```dart
/// const ReportLayoutColumn(
///   id: 'debit',
///   titleKey: 'field_sales.mbt_reports.col_debit',
///   visible: true,
///   flex: 1,
///   align: ReportLayoutColumnAlign.right,
///   includeInTotals: true,
/// );
/// ```
/// {@endtemplate}
class ReportLayoutColumn {
  /// [id]: Stabil sütun kimliği (veri map anahtarı)
  final String id;

  /// [titleKey]: Başlık l10n
  final String titleKey;

  /// [visible]: Görüntüle / PDF’te göster
  final bool visible;

  /// [flex]: Genişlik ağırlığı (dens satır)
  final int flex;

  /// [align]: Hizalama
  final ReportLayoutColumnAlign align;

  /// [includeInTotals]: Alt toplam satırına dahil
  final bool includeInTotals;

  /// {@macro report_layout_column}
  const ReportLayoutColumn({
    required this.id,
    required this.titleKey,
    this.visible = true,
    this.flex = 1,
    this.align = ReportLayoutColumnAlign.left,
    this.includeInTotals = false,
  });

  /// {@template report_layout_column_copy_with}
  /// Kopya (toggle / reorder sonrası).
  /// {@endtemplate}
  ReportLayoutColumn copyWith({
    String? id,
    String? titleKey,
    bool? visible,
    int? flex,
    ReportLayoutColumnAlign? align,
    bool? includeInTotals,
  }) {
    return ReportLayoutColumn(
      id: id ?? this.id,
      titleKey: titleKey ?? this.titleKey,
      visible: visible ?? this.visible,
      flex: flex ?? this.flex,
      align: align ?? this.align,
      includeInTotals: includeInTotals ?? this.includeInTotals,
    );
  }

  /// {@template report_layout_column_to_json}
  /// JSON map.
  /// {@endtemplate}
  Map<String, dynamic> toJson() => {
        'id': id,
        'titleKey': titleKey,
        'visible': visible,
        'flex': flex,
        'align': align.storageKey,
        'includeInTotals': includeInTotals,
      };

  /// {@template report_layout_column_from_json}
  /// JSON → sütun.
  /// {@endtemplate}
  factory ReportLayoutColumn.fromJson(Map<String, dynamic> json) {
    return ReportLayoutColumn(
      id: json['id'] as String? ?? '',
      titleKey: json['titleKey'] as String? ?? '',
      visible: json['visible'] as bool? ?? true,
      flex: (json['flex'] as num?)?.toInt() ?? 1,
      align: ReportLayoutColumnAlignX.parse(json['align'] as String?),
      includeInTotals: json['includeInTotals'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReportLayoutColumn &&
        other.id == id &&
        other.titleKey == titleKey &&
        other.visible == visible &&
        other.flex == flex &&
        other.align == align &&
        other.includeInTotals == includeInTotals;
  }

  @override
  int get hashCode => Object.hash(
        id,
        titleKey,
        visible,
        flex,
        align,
        includeInTotals,
      );
}
