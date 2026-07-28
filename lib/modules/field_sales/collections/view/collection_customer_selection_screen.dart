// Dosya Adı: collection_customer_selection_screen.dart
// Açıklama: Tahsilat girişi öncesi zorunlu cari (müşteri) seçim ekranı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';
import '../../customers/viewmodel/customer_provider.dart';
import '../../customers/model/customer_model.dart';
import '../model/finance_movement_type.dart';
import '../viewmodel/collection_provider.dart';
import 'collection_entry_screen.dart';
import 'credit_card_collection_screen.dart';
import 'payment_entry_screen.dart';
import 'promissory_note_screen.dart';
import 'wire_transfer_screen.dart';
import '../../shared/view/field_sales_dens_theme.dart';

/// {@template collection_selection_purpose}
/// Cari seçim sonrası açılacak finans ekranı.
/// {@endtemplate}
enum CollectionSelectionPurpose {
  /// Tahsilat girişi (mevcut akış)
  collection,

  /// Nakit / KK ödeme (payment out)
  payment,

  /// Kredi kartı tahsilat dens formu
  creditCard,

  /// Senet tahsilat dens formu
  promissory,

  /// Havale/EFT dens formu
  wireTransfer,
}

/// {@template collection_customer_selection_screen}
/// Plasiyer tahsilat/ödeme girmeden önce cari kart seçer.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => const CollectionCustomerSelectionScreen(),
/// ));
/// ```
/// {@endtemplate}
class CollectionCustomerSelectionScreen extends ConsumerStatefulWidget {
  /// [purpose]: Seçim sonrası hedef (varsayılan: tahsilat)
  final CollectionSelectionPurpose purpose;

  /// [initialPaymentType]: Tahsilat tipini entry'ye taşı (opsiyonel)
  final String? initialPaymentType;

  /// {@macro collection_customer_selection_screen}
  const CollectionCustomerSelectionScreen({
    Key? key,
    this.purpose = CollectionSelectionPurpose.collection,
    this.initialPaymentType,
  }) : super(key: key);

  /// {@template emptyMessage}
  /// Boş DB / arama sonucu için çeviri anahtarı.
  /// {@endtemplate}
  static String emptyMessage(String query) {
    return query.trim().isEmpty
        ? 'field_sales.no_customer_cards'
        : 'field_sales.customer_not_found';
  }

  @override
  ConsumerState<CollectionCustomerSelectionScreen> createState() =>
      _CollectionCustomerSelectionScreenState();
}

class _CollectionCustomerSelectionScreenState
    extends ConsumerState<CollectionCustomerSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerProvider.notifier).fetchCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// {@template _openEntry}
  /// Seçilen cari ile tahsilat veya ödeme giriş ekranını açar.
  ///
  /// Parametreler:
  /// - [customer]: Seçilen cari kart
  /// {@endtemplate}
  void _openEntry(CustomerModel customer) {
    if (!CollectionNotifier.isValidCustomerId(customer.id)) return;
    final rawType = widget.initialPaymentType;
    final resolved = rawType != null && rawType.trim().isNotEmpty
        ? FinanceMovementType.fromStorage(rawType)
        : null;
    final Widget next;
    if (resolved != null &&
        widget.purpose != CollectionSelectionPurpose.creditCard &&
        widget.purpose != CollectionSelectionPurpose.promissory &&
        widget.purpose != CollectionSelectionPurpose.wireTransfer) {
      next = _entryForType(customer.id, resolved);
    } else {
      switch (widget.purpose) {
        case CollectionSelectionPurpose.payment:
          next = PaymentEntryScreen(
            customerId: customer.id,
            initialPaymentType: widget.initialPaymentType,
          );
          break;
        case CollectionSelectionPurpose.creditCard:
          next = CreditCardCollectionScreen(customerId: customer.id);
          break;
        case CollectionSelectionPurpose.promissory:
          next = PromissoryNoteScreen(customerId: customer.id);
          break;
        case CollectionSelectionPurpose.wireTransfer:
          next = WireTransferScreen(customerId: customer.id);
          break;
        case CollectionSelectionPurpose.collection:
          next = CollectionEntryScreen(
            customerId: customer.id,
            initialPaymentType: widget.initialPaymentType,
          );
          break;
      }
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => next),
    );
  }

  /// {@template _entryForType}
  /// Finans 7 tip → entry widget.
  /// {@endtemplate}
  Widget _entryForType(String customerId, FinanceMovementType type) {
    switch (type) {
      case FinanceMovementType.creditCardCollection:
        return CreditCardCollectionScreen(customerId: customerId);
      case FinanceMovementType.noteCollection:
        return PromissoryNoteScreen(customerId: customerId);
      case FinanceMovementType.cashOut:
      case FinanceMovementType.creditCardOut:
        return PaymentEntryScreen(
          customerId: customerId,
          initialPaymentType: type.apiCode,
        );
      case FinanceMovementType.cashCollection:
      case FinanceMovementType.checkCollection:
        return CollectionEntryScreen(
          customerId: customerId,
          initialPaymentType: type.apiCode,
        );
      case FinanceMovementType.virman:
        return CollectionEntryScreen(
          customerId: customerId,
          initialPaymentType: FinanceMovementType.cashCollection.apiCode,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);
    final l10n = AppLocalization.of(context);
    const Color primary = Color(0xFF375A7F);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          l10n.translate('field_sales.customer_selection'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(customerProvider.notifier).fetchCustomers(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.translate(
                widget.purpose == CollectionSelectionPurpose.payment
                    ? 'field_sales.select_customer_first_payment'
                    : 'field_sales.select_customer_first_collection',
              ),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() => _query = value);
                ref.read(customerProvider.notifier).searchCustomers(value);
              },
              decoration: InputDecoration(
                hintText: l10n.translate(
                  'field_sales.search_customer_code_hint',
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                          ref
                              .read(customerProvider.notifier)
                              .fetchCustomers();
                        },
                      )
                    : null,
                filled: true,
                fillColor: FieldSalesDensTheme.surface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : !state.hasSelectableCustomers
                    ? Center(
                        child: Text(
                          l10n.translate(
                            CollectionCustomerSelectionScreen.emptyMessage(
                              _query,
                            ),
                          ),
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: state.customers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final customer = state.customers[index];
                          return Material(
                            color: FieldSalesDensTheme.surface(context),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: primary.withOpacity(0.12),
                                child: Text(
                                  customer.name.isNotEmpty
                                      ? customer.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              title: Text(
                                customer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                customer.displayCodeOrTax,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openEntry(customer),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
