// Dosya Adı: collection_provider.dart
// Açıklama: Tahsilat kaydı state yönetimi ve cari zorunluluk guard'ı
// Oluşturulma Tarihi: 2024-01-01
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/collection_model.dart';
import '../model/finance_movement_type.dart';
import '../../customers/viewmodel/customer_extract_store.dart';
import '../../../../service/database_service.dart';
import '../../../../service/job_queue_service.dart';
import '../../../../core/services/logo_payload_mapper.dart';

/// {@template collection_state}
/// Tahsilat ekranı yükleme / hata durumu.
/// {@endtemplate}
class CollectionState {
  /// [isLoading]: Kayıt işlemi sürüyor mu
  final bool isLoading;

  /// [error]: L10n anahtarı veya hata metni
  final String? error;

  CollectionState({this.isLoading = false, this.error});
}

/// {@template collection_notifier}
/// Tahsilat kaydı; boş cari kimliği ile kayıt engellenir.
/// {@endtemplate}
class CollectionNotifier extends StateNotifier<CollectionState> {
  CollectionNotifier() : super(CollectionState());

  /// {@template isValidCustomerId}
  /// Cari kimliğinin boş / yalnızca boşluk olmadığını doğrular.
  ///
  /// Parametreler:
  /// - [customerId]: Kontrol edilecek cari kimliği
  ///
  /// Dönüş değeri:
  /// - [bool]: Geçerliyse true
  /// {@endtemplate}
  static bool isValidCustomerId(String? customerId) {
    return customerId != null && customerId.trim().isNotEmpty;
  }

  /// {@template saveCollection}
  /// Tahsilatı yerel DB'ye yazar ve Logo job kuyruğuna ekler.
  ///
  /// Parametreler:
  /// - [customerId]: Zorunlu cari kart kimliği
  /// - [amount]: Tahsilat tutarı
  /// - [paymentType]: Ödeme tipi (Cash, Check, ...)
  /// - [cashCode]: Kasa kodu (Logo safe_code)
  /// - [documentNo]: Evrak no
  /// - [currencyCode]: İşlem dövizi
  /// - [salespersonCode]: Plasiyer
  /// - [specialCode1]: Özelkod 1
  /// - [endorsement]: Ciro (çek)
  /// - [originalDebtor]: Asıl borçlu (çek)
  /// - [workplace]: İşyeri (çek)
  /// - [accountNumber]: Hesap no (çek)
  ///
  /// Dönüş değeri:
  /// - [bool]: Başarılıysa true
  /// {@endtemplate}
  Future<bool> saveCollection({
    required String customerId,
    required double amount,
    required String paymentType,
    String? notes,
    String? bankName,
    String? branchName,
    String? checkNumber,
    DateTime? dueDate,
    String? cashCode,
    String? safeCode,
    String? documentNo,
    String? currencyCode,
    String? salespersonCode,
    String? specialCode1,
    String? endorsement,
    String? originalDebtor,
    String? workplace,
    String? accountNumber,
  }) async {
    if (!isValidCustomerId(customerId)) {
      state = CollectionState(
        error: 'field_sales.collection_save_requires_customer',
      );
      return false;
    }

    state = CollectionState(isLoading: true);
    try {
      final trimmedCustomerId = customerId.trim();
      final resolvedCash = _firstNonEmpty([cashCode, safeCode]);
      final db = await DatabaseService.getInstance();
      await db.ensureCollectionsTableSchema();
      final sqliteDb = await db.getDatabase();

      final normalizedType =
          FinanceMovementType.normalizeApiCode(paymentType);
      final isCheck = FinanceMovementType.fromStorage(normalizedType).isCheck;
      final collection = CollectionModel(
        id: const Uuid().v4(),
        customerId: trimmedCustomerId,
        amount: amount,
        paymentType: normalizedType,
        collectionDate: DateTime.now(),
        notes: notes,
        bankName: _trimOrNull(bankName),
        branchName: _trimOrNull(branchName),
        checkNumber: _trimOrNull(checkNumber),
        dueDate: dueDate,
        cashCode: resolvedCash,
        documentNo: _trimOrNull(documentNo),
        currencyCode: _trimOrNull(currencyCode),
        salespersonCode: _trimOrNull(salespersonCode),
        specialCode1: _trimOrNull(specialCode1),
        endorsement: _trimOrNull(endorsement),
        originalDebtor: _trimOrNull(originalDebtor),
        workplace: _trimOrNull(workplace),
        accountNumber: _trimOrNull(accountNumber),
        checkStatus: isCheck ? 'collection' : null,
      );

      final now = DateTime.now().toIso8601String();
      final collectionMap = collection.toMap();
      collectionMap['approval_status'] = 1; // Approved
      collectionMap['created_at'] = now;
      collectionMap['updated_at'] = now;

      final movement = CustomerExtractStore.movementFromCollection(
        collectionId: collection.id,
        customerId: trimmedCustomerId,
        collectionDate: collection.collectionDate,
        amount: amount,
        paymentType: normalizedType,
        documentNo: collection.documentNo,
        notes: notes,
      );

      await sqliteDb.transaction((txn) async {
        await txn.insert('collections', collectionMap);
        if (movement != null) {
          await const CustomerExtractStore().insert(
            movement,
            executor: txn,
          );
        }
      });

      String customerCode = trimmedCustomerId;
      String? customerName;
      final customerRows = await sqliteDb.query(
        'customers',
        where: 'id = ?',
        whereArgs: [trimmedCustomerId],
        limit: 1,
      );
      if (customerRows.isNotEmpty) {
        final c = customerRows.first;
        customerCode = (c['code'] ?? c['tax_no'] ?? c['id']).toString();
        customerName = c['name']?.toString();
      }

      await JobQueueService().enqueue(
        entityType: 'collection',
        entityId: collection.id,
        payload: LogoPayloadMapper.collectionFromLocal(
          customerCode: customerCode,
          amount: amount,
          paymentType: normalizedType,
          safeCode: resolvedCash,
          description: notes,
          customerName: customerName,
          documentNo: documentNo,
          currencyCode: currencyCode,
          salesmanCode: salespersonCode,
          specialCode1: specialCode1,
          bankName: bankName,
          branchName: branchName,
          checkNumber: checkNumber,
          dueDate: dueDate,
          endorsement: endorsement,
          originalDebtor: originalDebtor,
          workplace: workplace,
          accountNumber: accountNumber,
        ),
        priority: 2,
      );

      state = CollectionState(isLoading: false);
      return true;
    } catch (e) {
      state = CollectionState(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// {@template saveWireTransfer}
  /// Havale/EFT dens kaydı — SQLite `collections` + kuyruk (`payment_type=wire`).
  /// Cari ve banka/hesap kodu zorunludur.
  ///
  /// Parametreler:
  /// - [customerId]: Cari kart kimliği
  /// - [amount]: Tutar (> 0)
  /// - [bankCode]: Banka / hesap kodu (Logo safe_code)
  /// - [bankName]: Banka ünvanı
  /// - [accountNumber]: IBAN / hesap no
  /// - [documentNo]: Evrak no
  /// - [notes]: Açıklama
  ///
  /// Dönüş değeri:
  /// - [bool]: Başarılıysa true
  /// {@endtemplate}
  Future<bool> saveWireTransfer({
    required String customerId,
    required double amount,
    String? bankCode,
    String? bankName,
    String? accountNumber,
    String? documentNo,
    String? notes,
  }) async {
    if (!isValidCustomerId(customerId)) {
      state = CollectionState(
        error: 'field_sales.wire_requires_customer',
      );
      return false;
    }
    if (amount <= 0) {
      state = CollectionState(
        error: 'field_sales.payment_invalid_amount',
      );
      return false;
    }
    final code = _trimOrNull(bankCode);
    if (code == null) {
      state = CollectionState(
        error: 'field_sales.wire_requires_bank_code',
      );
      return false;
    }

    return saveCollection(
      customerId: customerId,
      amount: amount,
      paymentType: FinanceMovementType.wireApiCode,
      notes: notes,
      bankName: bankName,
      accountNumber: accountNumber,
      documentNo: documentNo,
      cashCode: code,
    );
  }

  /// {@template saveVirman}
  /// Virman fişini yerel DB'ye yazar ve kuyruğa `payment_type=virman` ekler.
  /// Cari zorunlu değildir; kaynak/hedef kasa kodları zorunludur.
  ///
  /// Parametreler:
  /// - [fromSafeCode]: Kaynak kasa kodu
  /// - [toSafeCode]: Hedef kasa kodu
  /// - [amount]: Virman tutarı (> 0)
  /// - [notes]: Açıklama
  ///
  /// Dönüş değeri:
  /// - [bool]: Başarılıysa true
  /// {@endtemplate}
  Future<bool> saveVirman({
    required String fromSafeCode,
    required String toSafeCode,
    required double amount,
    String? notes,
  }) async {
    final from = fromSafeCode.trim();
    final to = toSafeCode.trim();
    if (from.isEmpty || to.isEmpty) {
      state = CollectionState(
        error: 'field_sales.virman_requires_accounts',
      );
      return false;
    }
    if (from == to) {
      state = CollectionState(
        error: 'field_sales.virman_same_account',
      );
      return false;
    }
    if (amount <= 0) {
      state = CollectionState(
        error: 'field_sales.payment_invalid_amount',
      );
      return false;
    }

    state = CollectionState(isLoading: true);
    try {
      final db = await DatabaseService.getInstance();
      await db.ensureCollectionsTableSchema();
      final sqliteDb = await db.getDatabase();

      final collection = CollectionModel(
        id: const Uuid().v4(),
        customerId: '',
        amount: amount,
        paymentType: FinanceMovementType.virman.apiCode,
        collectionDate: DateTime.now(),
        notes: _trimOrNull(notes),
        cashCode: from,
        targetCashCode: to,
      );

      final now = DateTime.now().toIso8601String();
      final collectionMap = collection.toMap();
      collectionMap['approval_status'] = 1;
      collectionMap['created_at'] = now;
      collectionMap['updated_at'] = now;
      // Virman: cari yok — boş string yerine null (FK çakışması önlenir)
      collectionMap['customer_id'] = null;

      await sqliteDb.insert('collections', collectionMap);

      await JobQueueService().enqueue(
        entityType: 'collection',
        entityId: collection.id,
        payload: LogoPayloadMapper.virmanFromLocal(
          amount: amount,
          fromSafeCode: from,
          toSafeCode: to,
          description: notes,
        ),
        priority: 2,
      );

      state = CollectionState(isLoading: false);
      return true;
    } catch (e) {
      state = CollectionState(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// {@template _trim_or_null}
  /// Boş string'i null'a çevirir.
  /// {@endtemplate}
  static String? _trimOrNull(String? value) {
    if (value == null) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  /// {@template _first_non_empty}
  /// İlk dolu değeri döner.
  /// {@endtemplate}
  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      final t = _trimOrNull(v);
      if (t != null) return t;
    }
    return null;
  }
}

final collectionProvider =
    StateNotifierProvider<CollectionNotifier, CollectionState>((ref) {
  return CollectionNotifier();
});
