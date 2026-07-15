class TargetModel {
  final String id;
  final String userId;
  final double targetAmount;
  final double achievedAmount;
  final String period;
  final String type;
  final String? createdAt;
  final String? updatedAt;
  final bool isSynced;

  TargetModel({
    required this.id,
    required this.userId,
    required this.targetAmount,
    this.achievedAmount = 0.0,
    required this.period,
    required this.type,
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
  });

  factory TargetModel.fromMap(Map<String, dynamic> map) {
    return TargetModel(
      id: map['id'],
      userId: map['user_id'],
      targetAmount: map['target_amount'] ?? 0.0,
      achievedAmount: map['achieved_amount'] ?? 0.0,
      period: map['period'],
      type: map['type'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      isSynced: map['is_synced'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'target_amount': targetAmount,
      'achieved_amount': achievedAmount,
      'period': period,
      'type': type,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_synced': isSynced ? 1 : 0,
    };
  }
}
