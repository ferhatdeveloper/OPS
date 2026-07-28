// Dosya Adı: visit_existing_customer_screen.dart
// Açıklama: Mevcut cari seçimi ve gerçek ziyaret check-in (SQLite)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';
import '../../customers/viewmodel/customer_provider.dart';
import '../../customers/model/customer_model.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../viewmodel/visit_open_redirect.dart';
import '../viewmodel/visit_provider.dart';
import 'visit_form_screen.dart';
import '../../shared/view/field_sales_dens_theme.dart';

/// {@template visit_existing_customer_screen}
/// MBT “Mevcut Cari Hesap”: cari kart seç → gerçek check-in → ziyaret formu.
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
  bool _checkInBusy = false;

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
  /// Cari kartı seçer; check-in paneline geçer.
  ///
  /// Parametreler:
  /// - [customer]: Seçilen cari kart
  /// {@endtemplate}
  void _selectCustomer(CustomerModel customer) {
    if (customer.id.trim().isEmpty) return;
    setState(() => _selectedCustomer = customer);
  }

  /// {@template _performCheckIn}
  /// `visitProvider.checkIn` → SQLite Open ziyaret; ardından MBT form.
  /// {@endtemplate}
  Future<void> _performCheckIn(AppLocalization l10n) async {
    final customer = _selectedCustomer;
    if (customer == null || customer.id.trim().isEmpty) return;
    if (_checkInBusy) return;

    setState(() => _checkInBusy = true);
    final success =
        await ref.read(visitProvider.notifier).checkIn(customer.id);
    if (!mounted) return;
    setState(() => _checkInBusy = false);

    if (!success) {
      final redirected = await redirectToOpenVisitIfNeeded(
        context: context,
        ref: ref,
        l10n: l10n,
      );
      if (redirected || !mounted) return;
      final err = ref.read(visitProvider).error;
      final msg = (err != null && err.isNotEmpty)
          ? l10n.translate(err)
          : l10n.translate('field_sales.visit_check_in_failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      return;
    }

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
    setState(() => _selectedCustomer = null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);
    final visitState = ref.watch(visitProvider);
    final l10n = AppLocalization.of(context);
    const Color primary = Color(0xFF375A7F);
    final selected = _selectedCustomer;

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.stubs.visit_existing_customer'),
        useGradient: true,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.refresh,
            onPressed: () =>
                ref.read(customerProvider.notifier).fetchCustomers(),
          ),
        ],
      ),
      body: selected != null
          ? _buildCheckInPanel(
              l10n,
              primary,
              selected,
              visitState.isLoading || _checkInBusy,
            )
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
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
          child: Text(
            l10n.translate('field_sales.customer_selection'),
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 13),
            textInputAction: TextInputAction.search,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.none,
            onChanged: (value) {
              setState(() => _query = value);
              ref.read(customerProvider.notifier).searchCustomers(value);
            },
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              hintText: l10n.translate(
                'field_sales.search_customer_code_hint',
              ),
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                        ref.read(customerProvider.notifier).fetchCustomers();
                      },
                    )
                  : null,
              filled: true,
              fillColor: FieldSalesDensTheme.surface(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : !state.hasSelectableCustomers
                  ? Center(
                      child: Text(
                        l10n.translate(
                          VisitExistingCustomerScreen.emptyMessage(_query),
                        ),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                      itemCount: state.customers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
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
                              horizontal: 10,
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
                                  color: Color(0xFF375A7F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            title: Text(
                              customer.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              customer.displayCodeOrTax,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                            onTap: () => _selectCustomer(customer),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  /// {@template _buildCheckInPanel}
  /// Seçilen cari için gerçek check-in paneli.
  /// {@endtemplate}
  Widget _buildCheckInPanel(
    AppLocalization l10n,
    Color primary,
    CustomerModel customer,
    bool busy,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: busy ? null : _clearSelection,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(l10n.translate('field_sales.customer_selection')),
            ),
          ),
          const SizedBox(height: 4),
          Material(
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
                horizontal: 10,
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
                    color: Color(0xFF375A7F),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              title: Text(
                customer.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                customer.displayCodeOrTax,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.translate('field_sales.check_in'),
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: busy ? null : () => _performCheckIn(l10n),
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login, size: 18),
              label: Text(l10n.translate('field_sales.check_in')),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
