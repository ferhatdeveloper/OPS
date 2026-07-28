// Dosya Adı: report_saved_view.dart
// Açıklama: Rapor dizayn / pivot adlı görünüm kaydı (SharedPreferences)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'report_layout.dart';

/// {@template report_saved_view_kind}
/// Kayıtlı görünüm türü — layout veya pivot alan seçimi.
/// {@endtemplate}
enum ReportSavedViewKind {
  /// Tam [ReportLayout] anlık görüntüsü
  layout,

  /// Pivot satır / sütun / ölçü alanları
  pivot,
}

/// {@template report_saved_view}
/// Rapor başına adlandırılmış dizayn veya pivot görünümü.
///
/// Kullanım örneği:
/// ```dart
/// final view = ReportSavedView.pivot(
///   id: 'v1',
///   name: 'Plasiyer × Tutar',
///   rowFieldId: 'salesperson',
///   valueFieldId: 'amount',
/// );
/// ```
/// {@endtemplate}
class ReportSavedView {
  /// [id]: Benzersiz kimlik
  final String id;

  /// [name]: Kullanıcı etiketi
  final String name;

  /// [kind]: Layout veya pivot
  final ReportSavedViewKind kind;

  /// [layout]: Layout görünümünde JSON
  final ReportLayout? layout;

  /// [rowFieldId]: Pivot satır alanı
  final String? rowFieldId;

  /// [columnFieldId]: Pivot sütun alanı
  final String? columnFieldId;

  /// [valueFieldId]: Pivot ölçü alanı
  final String? valueFieldId;

  /// [updatedAt]: ISO kayıt zamanı
  final String? updatedAt;

  /// {@macro report_saved_view}
  const ReportSavedView({
    required this.id,
    required this.name,
    required this.kind,
    this.layout,
    this.rowFieldId,
    this.columnFieldId,
    this.valueFieldId,
    this.updatedAt,
  });

  /// Pivot görünümü fabrikası.
  factory ReportSavedView.pivot({
    required String id,
    required String name,
    required String rowFieldId,
    String? columnFieldId,
    required String valueFieldId,
    String? updatedAt,
  }) {
    return ReportSavedView(
      id: id,
      name: name,
      kind: ReportSavedViewKind.pivot,
      rowFieldId: rowFieldId,
      columnFieldId: columnFieldId,
      valueFieldId: valueFieldId,
      updatedAt: updatedAt,
    );
  }

  /// Layout görünümü fabrikası.
  factory ReportSavedView.layout({
    required String id,
    required String name,
    required ReportLayout layout,
    String? updatedAt,
  }) {
    return ReportSavedView(
      id: id,
      name: name,
      kind: ReportSavedViewKind.layout,
      layout: layout,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        if (layout != null) 'layout': layout!.toJson(),
        if (rowFieldId != null) 'row_field_id': rowFieldId,
        if (columnFieldId != null) 'column_field_id': columnFieldId,
        if (valueFieldId != null) 'value_field_id': valueFieldId,
        if (updatedAt != null) 'updated_at': updatedAt,
      };

  static ReportSavedView? fromJson(Map<String, dynamic> map) {
    final id = map['id']?.toString() ?? '';
    final name = map['name']?.toString() ?? '';
    if (id.isEmpty || name.isEmpty) return null;
    final kindRaw = map['kind']?.toString() ?? 'layout';
    final kind = kindRaw == 'pivot'
        ? ReportSavedViewKind.pivot
        : ReportSavedViewKind.layout;
    ReportLayout? layout;
    final layoutMap = map['layout'];
    if (layoutMap is Map<String, dynamic>) {
      layout = ReportLayout.fromJson(layoutMap);
    } else if (layoutMap is Map) {
      layout = ReportLayout.fromJson(Map<String, dynamic>.from(layoutMap));
    }
    return ReportSavedView(
      id: id,
      name: name,
      kind: kind,
      layout: layout,
      rowFieldId: map['row_field_id']?.toString(),
      columnFieldId: map['column_field_id']?.toString(),
      valueFieldId: map['value_field_id']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }
}
