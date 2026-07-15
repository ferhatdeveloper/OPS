class AuditFormModel {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final List<AuditFormFieldModel> fields;

  AuditFormModel({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.fields = const [],
  });

  factory AuditFormModel.fromMap(Map<String, dynamic> map, List<AuditFormFieldModel> fields) {
    return AuditFormModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      fields: fields,
    );
  }
}

class AuditFormFieldModel {
  final String id;
  final String formId;
  final String fieldName;
  final String fieldType; // 'text', 'number', 'photo', 'select'
  final List<String> options;
  final bool isRequired;
  final int sortOrder;

  final String? conditionalFieldId;
  final String? conditionalValue;
  final Map<String, dynamic>? metadata;

  AuditFormFieldModel({
    required this.id,
    required this.formId,
    required this.fieldName,
    required this.fieldType,
    this.options = const [],
    this.isRequired = false,
    required this.sortOrder,
    this.conditionalFieldId,
    this.conditionalValue,
    this.metadata,
  });

  factory AuditFormFieldModel.fromMap(Map<String, dynamic> map) {
    return AuditFormFieldModel(
      id: map['id'] as String,
      formId: map['form_id'] as String,
      fieldName: map['field_name'] as String,
      fieldType: map['field_type'] as String,
      options: map['options'] != null ? (map['options'] as String).split(',') : [],
      isRequired: (map['is_required'] as int?) == 1,
      sortOrder: (map['sort_order'] as num).toInt(),
      conditionalFieldId: map['conditional_field_id'] as String?,
      conditionalValue: map['conditional_value'] as String?,
    );
  }
}

class VisitAuditModel {
  final String id;
  final String visitId;
  final String formId;
  final DateTime completedAt;
  final bool isSynced;
  final Map<String, String> answers; // fieldId -> value

  VisitAuditModel({
    required this.id,
    required this.visitId,
    required this.formId,
    required this.completedAt,
    this.isSynced = false,
    this.answers = const {},
  });
}
