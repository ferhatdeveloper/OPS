enum ApprovalStatus {
  pending,
  approved,
  rejected,
  draft,
  synced,
  error;

  /// Database/JSON value
  String get value => name;

  /// Whether this record is ready to be synced to the server
  bool get isReadyForSync => this == ApprovalStatus.pending || this == ApprovalStatus.error;

  static ApprovalStatus fromValue(String? value) {
    return ApprovalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ApprovalStatus.pending,
    );
  }
}
