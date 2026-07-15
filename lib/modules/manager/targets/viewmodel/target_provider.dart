import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/target_model.dart';
import '../../../../service/storage_service.dart';

final targetProvider = StateNotifierProvider<TargetNotifier, TargetState>((ref) {
  return TargetNotifier();
});

class TargetState {
  final List<TargetModel> targets;
  final bool isLoading;
  final String? error;

  TargetState({this.targets = const [], this.isLoading = false, this.error});

  TargetState copyWith({List<TargetModel>? targets, bool? isLoading, String? error}) {
    return TargetState(
      targets: targets ?? this.targets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TargetNotifier extends StateNotifier<TargetState> {
  StorageService? _storageService;

  TargetNotifier() : super(TargetState()) {
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    _storageService = await StorageService.getInstance();
    loadTargets();
  }

  Future<void> loadTargets() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (_storageService != null && await _storageService!.hasSQLiteSupport()) {
        final db = await _storageService!.getDatabase();
        final results = await db.query('targets', orderBy: 'created_at DESC');
        final targets = results.map((map) => TargetModel.fromMap(map)).toList();
        
        // Populate mock targets if empty for demonstration
        if (targets.isEmpty) {
           final defaultTargets = [
              TargetModel(id: const Uuid().v4(), userId: 'Ahmet Yılmaz', targetAmount: 250000, achievedAmount: 180000, period: 'Aralık', type: 'Sales', createdAt: DateTime.now().toIso8601String()),
              TargetModel(id: const Uuid().v4(), userId: 'Mehmet Kaya', targetAmount: 300000, achievedAmount: 320000, period: 'Aralık', type: 'Sales', createdAt: DateTime.now().toIso8601String()),
              TargetModel(id: const Uuid().v4(), userId: 'Ayşe Demir', targetAmount: 200000, achievedAmount: 150000, period: 'Aralık', type: 'Sales', createdAt: DateTime.now().toIso8601String()),
              TargetModel(id: const Uuid().v4(), userId: 'Ali Can', targetAmount: 100000, achievedAmount: 90000, period: 'Aralık', type: 'Collection', createdAt: DateTime.now().toIso8601String()),
           ];
           for(var t in defaultTargets) { await db.insert('targets', t.toMap()); }
           state = state.copyWith(targets: defaultTargets, isLoading: false);
           return;
        }
        
        state = state.copyWith(targets: targets, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Local DB not supported');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addTarget(TargetModel target) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (_storageService != null && await _storageService!.hasSQLiteSupport()) {
        final db = await _storageService!.getDatabase();
        await db.insert('targets', target.toMap());
        
        // Refresh exactly from DB to maintain sorted order
        await loadTargets();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteTarget(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (_storageService != null && await _storageService!.hasSQLiteSupport()) {
        final db = await _storageService!.getDatabase();
        await db.delete('targets', where: 'id = ?', whereArgs: [id]);
        
        state = state.copyWith(
          targets: state.targets.where((element) => element.id != id).toList(),
          isLoading: false
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
