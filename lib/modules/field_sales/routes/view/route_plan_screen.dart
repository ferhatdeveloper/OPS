import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/visit_open_redirect.dart';
import '../viewmodel/visit_provider.dart';
import '../../merchandising/viewmodel/merchandising_provider.dart';
import '../../merchandising/view/audit_form_screen.dart';
import '../../../../core/localization/app_localization.dart';
import 'visit_form_screen.dart';
import 'route_map_screen.dart';
import '../../merchandising/view/competitor_survey_screen.dart';
import '../../shared/view/field_sales_dens_theme.dart';
class RoutePlanScreen extends ConsumerStatefulWidget {
  const RoutePlanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RoutePlanScreen> createState() => _RoutePlanScreenState();
}

class _RoutePlanScreenState extends ConsumerState<RoutePlanScreen> {
  @override
  void initState() {
    super.initState();
    // Initial fetch is handled by provider constructor but we can refresh here
    Future.microtask(() => ref.read(visitProvider.notifier).fetchRoutes());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visitProvider);
    final l10n = AppLocalization.of(context);

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
          l10n.translate('field_sales.route_plan'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              if (state.routeCustomers.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => RouteMapScreen(customers: state.routeCustomers)),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(visitProvider.notifier).fetchRoutes(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Text(
                    state.error!.contains('.')
                        ? l10n.translate(state.error!)
                        : state.error!,
                  ),
                )
              : _buildContent(context, state, l10n),
    );
  }

  Widget _buildContent(BuildContext context, VisitState state, AppLocalization l10n) {
    return Column(
      children: [
        if (state.activeVisit != null) _buildActiveVisitCard(context, state, l10n),
        Expanded(
          child: state.availableRoutes.isEmpty
              ? _buildEmptyState(l10n)
              : _buildCustomerList(context, state, l10n),
        ),
      ],
    );
  }

  Widget _buildActiveVisitCard(BuildContext context, VisitState state, AppLocalization l10n) {
    final visit = state.activeVisit!;
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FieldSalesDensTheme.surface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A8E8).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on, color: Color(0xFF00A8E8)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.translate('field_sales.active_visit_status'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(l10n.translate('field_sales.active'), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildActionButton(context, Icons.assignment_turned_in, l10n.translate('field_sales.audit'), Colors.orange, () => _showAuditFormSelection(context, visit.id))),
                const SizedBox(width: 8),
                Expanded(child: _buildActionButton(context, Icons.note_alt, l10n.translate('field_sales.visit_note'), Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (c) => VisitFormScreen(customerId: visit.customerId))))),
                const SizedBox(width: 8),
                Expanded(child: _buildActionButton(context, Icons.payments, l10n.translate('field_sales.collection'), Colors.green, () => Navigator.pushNamed(context, '/field-sales/collections', arguments: visit.customerId))),
                const SizedBox(width: 8),
                Expanded(child: _buildActionButton(context, Icons.add_shopping_cart, l10n.translate('field_sales.order'), const Color(0xFF375A7F), () => Navigator.pushNamed(context, '/field-sales/orders', arguments: visit.customerId))),
                const SizedBox(width: 8),
                Expanded(child: _buildActionButton(context, Icons.analytics_outlined, "Rakip", Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (c) => CompetitorSurveyScreen(visitId: visit.id))))),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _showCheckOutDialog(context, l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.exit_to_app),
                label: Text(
                  l10n.translate('field_sales.complete_visit'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showAuditFormSelection(BuildContext context, String visitId) {
    final state = ref.read(merchandisingProvider);
    
    if (state.availableForms.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalization.of(context).translate('common.info')),
          content: Text(AppLocalization.of(context).translate('field_sales.no_audit_form')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalization.of(context).translate('common.ok')),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalization.of(context).translate('field_sales.select_audit_form'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...state.availableForms.map((form) => ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: const Icon(Icons.description_outlined, color: Color(0xFF00A8E8)),
              title: Text(form.name),
              subtitle: form.description != null ? Text(form.description!) : null,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuditFormScreen(
                      formId: form.id,
                      visitId: visitId,
                    ),
                  ),
                );
              },
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalization l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            l10n.translate('field_sales.no_route_today'),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(BuildContext context, VisitState state, AppLocalization l10n) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: state.routeCustomers.length,
      itemBuilder: (context, index) {
        final rc = state.routeCustomers[index];
        final isVisited = state.completedCustomerIds.contains(rc.customerId);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: FieldSalesDensTheme.surface(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: state.activeVisit == null ? () => _handleCheckIn(rc.customerId, l10n) : null,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isVisited
                            ? Colors.green.shade50
                            : FieldSalesDensTheme.bodyBackground(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isVisited ? Colors.green.shade200 : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isVisited ? Colors.green.shade700 : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rc.customerName ?? l10n.translate('field_sales.unknown_customer'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  rc.customerAddress ?? l10n.translate('field_sales.address_not_specified'),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (rc.isMandatory)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l10n.translate('field_sales.mandatory'),
                                style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (state.activeVisit == null)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A8E8).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.login, color: Color(0xFF00A8E8), size: 18),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleCheckIn(String customerId, AppLocalization l10n) async {
    final success = await ref.read(visitProvider.notifier).checkIn(customerId);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.translate('field_sales.visit_started'))));
    } else {
      final redirected = await redirectToOpenVisitIfNeeded(
        context: context,
        ref: ref,
        l10n: l10n,
      );
      if (redirected || !mounted) return;
      final err = ref.read(visitProvider).error;
      if (err != null) {
        final message = err.contains('.') ? l10n.translate(err) : err;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  void _showCheckOutDialog(BuildContext context, AppLocalization l10n) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(l10n.translate('field_sales.check_out'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(
            hintText: l10n.translate('field_sales.visit_notes'),
            filled: true,
            fillColor: FieldSalesDensTheme.surface(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('common.cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await ref.read(visitProvider.notifier).checkOut(notesController.text);
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.translate('field_sales.visit_completed'))));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A8E8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.translate('common.ok')),
          ),
        ],
      ),
    );
  }
}

