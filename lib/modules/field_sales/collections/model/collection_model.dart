class CollectionModel {
  final String id;
  final String customerId;
  final double amount;
  final String paymentType; // 'Cash', 'CreditCard', 'Check'
  final DateTime collectionDate;
  final String? notes;
  final String? bankName;
  final String? branchName;
  final String? checkNumber;
  final DateTime? dueDate;
  final bool isSynced;
  final DateTime? createdAt;

  CollectionModel({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.paymentType,
    required this.collectionDate,
    this.notes,
    this.bankName,
    this.branchName,
    this.checkNumber,
    this.dueDate,
    this.isSynced = false,
    this.createdAt,
  });

  factory CollectionModel.fromMap(Map<String, dynamic> map) {
    return CollectionModel(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentType: map['payment_type'] as String,
      collectionDate: DateTime.parse(map['collection_date']),
      notes: map['notes'] as String?,
      bankName: map['bank_name'] as String?,
      branchName: map['branch_name'] as String?,
      checkNumber: map['check_number'] as String?,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      isSynced: (map['is_synced'] as int?) == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'amount': amount,
      'payment_type': paymentType,
      'collection_date': collectionDate.toIso8601String(),
      'notes': notes,
      'bank_name': bankName,
      'branch_name': branchName,
      'check_number': checkNumber,
      'due_date': dueDate?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}
