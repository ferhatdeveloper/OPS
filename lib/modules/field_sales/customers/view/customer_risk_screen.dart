// Dosya Adı: customer_risk_screen.dart
// Açıklama: Müşteri risk dens ekranı (MBT CARİ → risk/limit alanları)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localization.dart';
import '../widgets/customer_risk_mbt_fields.dart';

/// {@template customer_risk_screen}
/// Müşteri risk / limit dens formu (MBT parity stub).
/// Route: `/field-sales/customer-risk`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, CustomerRiskScreen.routeName);
/// // veya
/// CustomerRiskScreen(
///   customerCode: '120.01',
///   customerName: 'Demo Cari',
///   balance: 1500,
///   riskLimit: 10000,
/// );
/// ```
/// {@endtemplate}
class CustomerRiskScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/customer-risk`
  static const String routeName = '/field-sales/customer-risk';

  /// [customerId]: Seçili cari kimliği (opsiyonel)
  final String? customerId;

  /// [customerCode]: Cari kodu (opsiyonel stub)
  final String? customerCode;

  /// [customerName]: Cari ünvanı (opsiyonel stub)
  final String? customerName;

  /// [balance]: Cari bakiye (borç pozitif)
  final double balance;

  /// [riskLimit]: Risk / kredi limiti (0 = tanımsız stub)
  final double riskLimit;

  /// [agingDebt]: Yaşlandırılmış borç
  final double agingDebt;

  /// {@macro customer_risk_screen}
  const CustomerRiskScreen({
    Key? key,
    this.customerId,
    this.customerCode,
    this.customerName,
    this.balance = 0,
    this.riskLimit = 0,
    this.agingDebt = 0,
  }) : super(key: key);

  /// {@template customer_risk_available_limit}
  /// Kullanılabilir limit = max(0, riskLimit − max(0, balance)).
  /// Limit 0 ise tanımsız → 0 döner.
  /// {@endtemplate}
  static double availableLimit({
    required double riskLimit,
    required double balance,
  }) {
    if (riskLimit <= 0) return 0;
    final used = balance > 0 ? balance : 0.0;
    final left = riskLimit - used;
    return left > 0 ? left : 0;
  }

  /// {@template customer_risk_is_exceeded}
  /// Bakiye risk limitini aşıyor mu (limit > 0 iken).
  /// {@endtemplate}
  static bool isLimitExceeded({
    required double riskLimit,
    required double balance,
  }) {
    if (riskLimit <= 0) return false;
    return balance > riskLimit;
  }

  @override
  State<CustomerRiskScreen> createState() => _CustomerRiskScreenState();
}

class _CustomerRiskScreenState extends State<CustomerRiskScreen> {
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _riskLimitController;
  late final TextEditingController _balanceController;
  late final TextEditingController _availableController;
  late final TextEditingController _agingController;

  static final NumberFormat _money = NumberFormat('#,##0.00', 'tr_TR');

  @override
  void initState() {
    super.initState();
    final available = CustomerRiskScreen.availableLimit(
      riskLimit: widget.riskLimit,
      balance: widget.balance,
    );
    _codeController = TextEditingController(
      text: widget.customerCode?.trim() ?? '',
    );
    _nameController = TextEditingController(
      text: widget.customerName?.trim() ?? '',
    );
    _riskLimitController = TextEditingController(
      text: _money.format(widget.riskLimit),
    );
    _balanceController = TextEditingController(
      text: _money.format(widget.balance),
    );
    _availableController = TextEditingController(
      text: _money.format(available),
    );
    _agingController = TextEditingController(
      text: _money.format(widget.agingDebt),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _riskLimitController.dispose();
    _balanceController.dispose();
    _availableController.dispose();
    _agingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.customer_risk');
    final exceeded = CustomerRiskScreen.isLimitExceeded(
      riskLimit: widget.riskLimit,
      balance: widget.balance,
    );
    final statusLabel = l10n.translate(
      exceeded
          ? 'field_sales.risk_status_exceeded'
          : 'field_sales.risk_status_ok',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.translate('field_sales.risk_form_hint'),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            CustomerRiskMbtFields(
              codeController: _codeController,
              nameController: _nameController,
              riskLimitController: _riskLimitController,
              balanceController: _balanceController,
              availableController: _availableController,
              agingController: _agingController,
              statusLabel: statusLabel,
            ),
          ],
        ),
      ),
    );
  }
}
