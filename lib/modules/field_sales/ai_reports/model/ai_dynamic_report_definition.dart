// Dosya Adı: ai_dynamic_report_definition.dart
// Açıklama: Yerel AI dinamik rapor tanımı (PostgREST spec + layout)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import '../../../../core/ai/features/postgrest_query_spec.dart';

/// {@template ai_dynamic_report_definition}
/// Onay sonrası yerel saklanan rapor.
/// `query_json` = PostgREST GET spec — **ham SQL değil**.
/// {@endtemplate}
class AiDynamicReportDefinition {
  /// [id]
  final String id;

  /// [title]
  final String title;

  /// [titleKey]
  final String? titleKey;

  /// [query]: PostgREST spec
  final PostgrestQuerySpec query;

  /// [columns]
  final List<AiReportLayoutColumn> columns;

  /// [createdAt]
  final String createdAt;

  /// [createdBy]
  final String? createdBy;

  /// [isFavoriteShortcut]
  final bool isFavoriteShortcut;

  /// {@macro ai_dynamic_report_definition}
  const AiDynamicReportDefinition({
    required this.id,
    required this.title,
    this.titleKey,
    required this.query,
    required this.columns,
    required this.createdAt,
    this.createdBy,
    this.isFavoriteShortcut = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'title_key': titleKey,
        'query_json': jsonEncode(query.toJson()),
        'layout_json': jsonEncode(columns.map((c) => c.toJson()).toList()),
        'created_at': createdAt,
        'created_by': createdBy,
        'is_favorite_shortcut': isFavoriteShortcut ? 1 : 0,
        'is_synced': 0,
        'is_deleted': 0,
      };

  factory AiDynamicReportDefinition.fromMap(Map<String, dynamic> map) {
    PostgrestQuerySpec query = const PostgrestQuerySpec(table: '', select: []);
    try {
      final q = jsonDecode((map['query_json'] ?? '{}').toString());
      if (q is Map) {
        query = PostgrestQuerySpec.fromJson(Map<String, dynamic>.from(q));
      }
    } catch (_) {}
    final columns = <AiReportLayoutColumn>[];
    try {
      final c = jsonDecode((map['layout_json'] ?? '[]').toString());
      if (c is List) {
        for (final e in c) {
          if (e is Map) {
            columns.add(
              AiReportLayoutColumn.fromJson(Map<String, dynamic>.from(e)),
            );
          }
        }
      }
    } catch (_) {}
    return AiDynamicReportDefinition(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      titleKey: map['title_key']?.toString(),
      query: query,
      columns: columns,
      createdAt: (map['created_at'] ?? '').toString(),
      createdBy: map['created_by']?.toString(),
      isFavoriteShortcut: (map['is_favorite_shortcut'] as num?)?.toInt() == 1,
    );
  }

  factory AiDynamicReportDefinition.fromProposal({
    required String id,
    required AiReportProposal proposal,
    String? createdBy,
    bool isFavoriteShortcut = false,
  }) {
    return AiDynamicReportDefinition(
      id: id,
      title: proposal.title,
      titleKey: proposal.titleKey,
      query: proposal.query,
      columns: proposal.columns,
      createdAt: DateTime.now().toIso8601String(),
      createdBy: createdBy,
      isFavoriteShortcut: isFavoriteShortcut,
    );
  }
}
