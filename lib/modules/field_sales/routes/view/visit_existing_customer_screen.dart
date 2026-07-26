// Dosya Adı: visit_existing_customer_screen.dart
// Açıklama: Mevcut cari seçimi ve ziyaret check-in stub ekranı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';
import '../../customers/viewmodel/customer_provider.dart';
import '../../customers/model/customer_model.dart';
import 'visit_form_screen.dart';

/// {@template visit_existing_customer_screen}
/// MBT “Mevcut Cari Hesap”: cari kart seç → check-in stub.
///
/// Rota: [VisitExistingCustomerScreen.routeName]
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, VisitExistingCustomerScreen.routeName);
/// ```
/// {@endtemplate}
class VisitExistingCustomerScreen extends ConsumerStatefulWidget {
  /// {@template routeName}
  /// Named route: `/field-sales/visit-existing`
  /// {@endtemplate}
  static const String routeName = '/field-sales/visit-existing';

  const VisitExistingCustomerScreen({Key? key}) : super(key: key);

  /// {@template emptyMessage}
  /// Boş DB / arama sonucu için çeviri anahtarı.
  /// {@endtemplate}
  static String emptyMessage(String query) {
    return query.trim().isEmpty
        ? 'field_sales.no_customer_cards'
        : 'field_sales.customer_not_found';
  }

  @override
  ConsumerState<VisitExistingCustomerScreen> createState() =>
      _VisitExistingCustomerScreenState();
}

class _VisitExistingCustomerScreenState
    extends ConsumerState<VisitExistingCustomerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  CustomerModel? _selectedCustomer;
  bool _checkInStubDone = false;

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

  /// {@template _selectCustomer}
  /// Cari kartı seçer; check-in stub paneline geçer.
  ///
  /// Parametreler:
  /// - [customer]: Seçilen cari kart
  /// {@endtemplate}
  void _selectCustomer(CustomerModel customer) {
    if (customer.id.trim().isEmpty) return;
    setState(() {
      _selectedCustomer = customer;
      _checkInStubDone = false;
    });
  }

  /// {@template _stubCheckIn}
  /// Check-in stub; ardından MBT ziyaret formuna geçer.
  /// {@endtemplate}
  void _stubCheckIn(AppLocalization l10n) {
    final customer = _selectedCustomer;
    if (customer == null || customer.id.trim().isEmpty) return;

    setState(() => _checkInStubDone = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${l10n.translate('field_sales.visit_started')}: '
          '${customer.name}',
        ),
      ),
    );
    Navigator.pushNamed(
      context,
      VisitFormScreen.routeName,
      arguments: customer.id,
    );
  }

  /// {@template _clearSelection}
  /// Seçimi temizler; listeye döner.
  /// {@endtemplate}
  void _clearSelection() {
    setState(() {
      _selectedCustomer = null;
      _checkInStubDone = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);
    final l10n = AppLocalization.of(context);
    const Color primary = Color(0xFF375A7F);
    final selected = _selectedCustomer;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          l10n.translate('field_sales.stubs.visit_existing_customer'),
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
      body: selected != null
          ? _buildCheckInStub(l10n, primary, selected)
          : _buildCustomerList(l10n, primary, state),
    );
  }

  /// {@template _buildCustomerList}
  /// Cari arama + seçim listesi.
  /// {@endtemplate}
  Widget _buildCustomerList(
    AppLocalization l10n,
    Color primary,
    CustomerState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.translate('field_sales.customer_selection'),
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.none,
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
                        ref.read(customerProvider.notifier).fetchCustomers();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
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
                          VisitExistingCustomerScreen.emptyMessage(_query),
                        ),
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: state.customers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final customer = state.customers[index];
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
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
                              backgroundColor: primary.withOpacity(0.12),
                              child: Text(
                                customer.name.isNotEmpty
                                    ? customer.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Color(0xFF375A7F),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              customer.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
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
                            onTap: () => _selectCustomer(customer),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  /// {@template _buildCheckInStub}
  /// Seçilen cari için check-in stub paneli (GPS/geofence yok).
  /// {@endtemplate}
  Widget _buildCheckInStub(
    AppLocalization l10n,
    Color primary,
    CustomerModel customer,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _clearSelection,
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.translate('field_sales.customer_selection')),
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
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
                vertical: 6,
              ),
              leading: CircleAvatar(
                backgroundColor: primary.withOpacity(0.12),
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Color(0xFF375A7F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                customer.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                customer.displayCodeOrTax,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.translate('field_sales.check_in'),
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _checkInStubDone ? null : () => _stubCheckIn(l10n),
            icon: const Icon(Icons.login),
            label: Text(l10n.translate('field_sales.check_in')),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          if (_checkInStubDone) ...[
            const SizedBox(height: 16),
            Text(
              l10n.translate('field_sales.active_visit_status'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
