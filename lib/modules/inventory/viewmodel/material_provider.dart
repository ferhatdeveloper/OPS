import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/material_model.dart';

// Provider state that holds the materials list and loading state
class MaterialState {
  final List<MaterialItem> items;
  final bool isLoading;
  final String? error;

  MaterialState({this.items = const [], this.isLoading = false, this.error});

  MaterialState copyWith({
    List<MaterialItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return MaterialState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Provider notifier that manages the materials state
class MaterialNotifier extends StateNotifier<MaterialState> {
  MaterialNotifier() : super(MaterialState()) {
    fetchMaterials();
  }

  // Fetch materials from the API/database
  Future<void> fetchMaterials() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));

      // In a real app, this would be an API call
      final items = MaterialItem.getSampleItems();

      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Malzemeler yüklenirken hata oluştu: ${e.toString()}',
      );
    }
  }

  // Add a new material
  Future<void> addMaterial(MaterialItem material) async {
    // In a real app, this would make an API call
    // For now, just update the state
    final updatedItems = [...state.items, material];
    state = state.copyWith(items: updatedItems);
  }

  // Update an existing material
  Future<void> updateMaterial(MaterialItem updatedMaterial) async {
    // In a real app, this would make an API call
    final updatedItems =
        state.items
            .map(
              (item) =>
                  item.code == updatedMaterial.code ? updatedMaterial : item,
            )
            .toList();

    state = state.copyWith(items: updatedItems);
  }

  // Delete a material
  Future<void> deleteMaterial(String code) async {
    // In a real app, this would make an API call
    final updatedItems =
        state.items.where((item) => item.code != code).toList();
    state = state.copyWith(items: updatedItems);
  }
}

// Create the provider
final materialProvider = StateNotifierProvider<MaterialNotifier, MaterialState>(
  (ref) {
    return MaterialNotifier();
  },
);
