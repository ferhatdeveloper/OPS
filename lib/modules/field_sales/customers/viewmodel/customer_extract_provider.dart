// Dosya Adı: customer_extract_provider.dart
// Açıklama: Cari ekstre dens hareket listesi Riverpod state
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/customer_extract_movement.dart';
import 'customer_extract_store.dart';

/// {@template customer_extract_state}
/// Ekstre listesi yükleme / satır / toplam durumu.
/// {@endtemplate}
class CustomerExtractState {
  /// [isLoading]: Yükleniyor mu
  final bool isLoading;

  /// [movements]: Filtrelenmiş hareketler
  final List<CustomerExtractMovement> movements;

  /// [error]: Hata metni (varsa)
  final String? error;

  /// {@macro customer_extract_state}
  const CustomerExtractState({
    this.isLoading = false,
    this.movements = const [],
    this.error,
  });

  /// {@template customer_extract_state_total_debit}
  /// Görünen satırların borç toplamı.
  /// {@endtemplate}
  double get totalDebit =>
      movements.fold(0.0, (sum, m) => sum + m.debit);

  /// {@template customer_extract_state_total_credit}
  /// Görünen satırların alacak toplamı.
  /// {@endtemplate}
  double get totalCredit =>
      movements.fold(0.0, (sum, m) => sum + m.credit);

  /// {@template customer_extract_state_copy_with}
  /// Immutable kopya.
  /// {@endtemplate}
  CustomerExtractState copyWith({
    bool? isLoading,
    List<CustomerExtractMovement>? movements,
    String? error,
  }) {
    return CustomerExtractState(
      isLoading: isLoading ?? this.isLoading,
      movements: movements ?? this.movements,
      error: error,
    );
  }
}

/// {@template customer_extract_notifier}
/// SQLite store üzerinden cari hareket yükler.
/// {@endtemplate}
class CustomerExtractNotifier extends StateNotifier<CustomerExtractState> {
  /// [_store]: SQLite erişim katmanı
  final CustomerExtractStore _store;

  /// {@macro customer_extract_notifier}
  CustomerExtractNotifier(this._store)
      : super(const CustomerExtractState());

  /// {@template customer_extract_notifier_load}
  /// Filtrelerle hareket listesini yeniler.
  ///
  /// Parametreler:
  /// - [customerId]: İsteğe bağlı cari
  /// - [start]: Başlangıç
  /// - [end]: Bitiş
  /// - [filter]: Borç/alacak filtresi
  /// - [search]: Arama metni
  /// {@endtemplate}
  Future<void> load({
    String? customerId,
    required DateTime start,
    required DateTime end,
    ExtractMovementFilter filter = ExtractMovementFilter.all,
    String search = '',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rows = await _store.query(
        customerId: customerId,
        start: start,
        end: end,
        filter: filter,
        search: search,
      );
      state = CustomerExtractState(movements: rows);
    } catch (e) {
      state = CustomerExtractState(
        movements: const [],
        error: e.toString(),
      );
    }
  }
}

/// [customerExtractStoreProvider]: Store DI noktası (test override)
final customerExtractStoreProvider = Provider<CustomerExtractStore>((ref) {
  return const CustomerExtractStore();
});

/// [customerExtractProvider]: Ekstre listesi notifier
final customerExtractProvider =
    StateNotifierProvider<CustomerExtractNotifier, CustomerExtractState>(
  (ref) => CustomerExtractNotifier(ref.watch(customerExtractStoreProvider)),
);
