// Dosya Adı: partial_delivery_provider.dart
// Açıklama: Kısmi teslimat Kaydet → SQLite + sync_queue provider iskeleti
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../service/database_service.dart';
import '../model/partial_delivery_model.dart';
import 'partial_delivery_repository.dart';

/// {@template partial_delivery_state}
/// Kısmi teslimat kayıt ekranı durumu.
/// {@endtemplate}
class PartialDeliveryState {
  /// [isLoading]: Kayıt sürüyor mu
  final bool isLoading;

  /// [error]: L10n hata anahtarı
  final String? error;

  /// [lastSavedId]: Son kaydedilen fiş kimliği
  final String? lastSavedId;

  /// {@macro partial_delivery_state}
  const PartialDeliveryState({
    this.isLoading = false,
    this.error,
    this.lastSavedId,
  });

  /// {@template partial_delivery_state_copy_with}
  /// İmmutable kopya.
  /// {@endtemplate}
  PartialDeliveryState copyWith({
    bool? isLoading,
    String? error,
    String? lastSavedId,
    bool clearError = false,
  }) {
    return PartialDeliveryState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastSavedId: lastSavedId ?? this.lastSavedId,
    );
  }
}

/// {@template partial_delivery_notifier}
/// Dens form Kaydet → yerel SQLite + sync_queue iskeleti.
///
/// Kullanım örneği:
/// ```dart
/// final ok = await ref.read(partialDeliveryProvider.notifier).save(
///   workplace: 'A',
///   factory: 'B',
///   warehouse: 'C',
///   deliveryDate: DateTime.now(),
///   lines: const [],
/// );
/// ```
/// {@endtemplate}
class PartialDeliveryNotifier extends StateNotifier<PartialDeliveryState> {
  /// [repository]: SQLite yazım katmanı
  final PartialDeliveryRepository repository;

  /// [_dbOverride]: Test için enjekte edilen DB
  final Future<Database> Function()? _dbOverride;

  /// {@macro partial_delivery_notifier}
  PartialDeliveryNotifier({
    this.repository = const PartialDeliveryRepository(),
    Future<Database> Function()? dbOverride,
  })  : _dbOverride = dbOverride,
        super(const PartialDeliveryState());

  /// {@template partial_delivery_validate_lines}
  /// Satır listesi boşsa l10n hata anahtarı döner.
  ///
  /// Parametreler:
  /// - [lines]: Dens satırları
  ///
  /// Dönüş değeri:
  /// - [String?]: Hata anahtarı veya null
  /// {@endtemplate}
  static String? validateLines(List<PartialDeliveryLine> lines) {
    if (lines.isEmpty) {
      return 'field_sales.partial_delivery.requires_lines';
    }
    return null;
  }

  /// {@template partial_delivery_save}
  /// Kaydı SQLite'a yazar ve sync_queue'ya ekler.
  ///
  /// Parametreler:
  /// - [workplace]: İşyeri
  /// - [factory]: Fabrika
  /// - [warehouse]: Ambar
  /// - [deliveryDate]: Tarih
  /// - [lines]: Satırlar
  ///
  /// Dönüş değeri:
  /// - [bool]: Başarılıysa true
  /// {@endtemplate}
  Future<bool> save({
    String? workplace,
    String? factory,
    String? warehouse,
    required DateTime deliveryDate,
    required List<PartialDeliveryLine> lines,
  }) async {
    final guard = validateLines(lines);
    if (guard != null) {
      state = state.copyWith(error: guard, isLoading: false);
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final Database db = _dbOverride != null
          ? await _dbOverride!()
          : await (await DatabaseService.getInstance()).getDatabase();

      await repository.ensureSchema(db);

      final id = const Uuid().v4();
      final now = DateTime.now();
      final record = PartialDeliveryRecord(
        id: id,
        workplace: workplace,
        factory: factory,
        warehouse: warehouse,
        deliveryDate: deliveryDate,
        lines: lines,
        status: 'Pending',
        isSynced: false,
        createdAt: now,
        updatedAt: now,
      );

      await repository.insert(db, record);
      await repository.enqueueSyncQueue(
        db,
        entityId: id,
        payload: record.toQueuePayload(),
      );

      state = state.copyWith(
        isLoading: false,
        lastSavedId: id,
        clearError: true,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'field_sales.partial_delivery.save_failed',
      );
      return false;
    }
  }
}

/// [partialDeliveryProvider]: Kısmi teslimat Kaydet state
final partialDeliveryProvider =
    StateNotifierProvider<PartialDeliveryNotifier, PartialDeliveryState>(
  (ref) => PartialDeliveryNotifier(),
);
