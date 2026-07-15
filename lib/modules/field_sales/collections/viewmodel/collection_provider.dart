import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/collection_model.dart';
import '../../../../service/database_service.dart';

class CollectionState {
  final bool isLoading;
  final String? error;

  CollectionState({this.isLoading = false, this.error});
}

class CollectionNotifier extends StateNotifier<CollectionState> {
  CollectionNotifier() : super(CollectionState());

  Future<bool> saveCollection({
    required String customerId,
    required double amount,
    required String paymentType,
    String? notes,
    String? bankName,
    String? branchName,
    String? checkNumber,
    DateTime? dueDate,
  }) async {
    state = CollectionState(isLoading: true);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();

      final collection = CollectionModel(
        id: const Uuid().v4(),
        customerId: customerId,
        amount: amount,
        paymentType: paymentType,
        collectionDate: DateTime.now(),
        notes: notes,
        bankName: bankName,
        branchName: branchName,
        checkNumber: checkNumber,
        dueDate: dueDate,
      );

      final now = DateTime.now().toIso8601String();
      final collectionMap = collection.toMap();
      collectionMap['approval_status'] = 1; // Approved
      collectionMap['created_at'] = now;
      collectionMap['updated_at'] = now;

      await sqliteDb.insert('collections', collectionMap);
      state = CollectionState(isLoading: false);
      return true;
    } catch (e) {
      state = CollectionState(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final collectionProvider = StateNotifierProvider<CollectionNotifier, CollectionState>((ref) {
  return CollectionNotifier();
});
