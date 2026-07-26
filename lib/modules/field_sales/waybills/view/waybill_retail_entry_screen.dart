// Dosya Adı: waybill_retail_entry_screen.dart
// Açıklama: Perakende irsaliye giriş stub ekranı (MBT İRSALİYE) — cari zorunlu
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../../../core/localization/app_localization.dart';
import 'waybill_customer_selection_screen.dart';

/// {@template waybill_retail_entry_screen}
/// Perakende irsaliye girişi için stub ekran.
/// Route: `/field-sales/waybill-retail`
/// Boş [customerId] engellenir → [WaybillCustomerSelectionScreen].
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   WaybillRetailEntryScreen.routeName,
///   arguments: customerId,
/// );
/// ```
/// {@endtemplate}
class WaybillRetailEntryScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/waybill-retail`
  static const String routeName = '/field-sales/waybill-retail';

  /// [customerId]: İrsaliyenin bağlanacağı cari kart kimliği (zorunlu)
  final String customerId;

  const WaybillRetailEntryScreen({
    Key? key,
    required this.customerId,
  }) : super(key: key);

  @override
  State<WaybillRetailEntryScreen> createState() =>
      _WaybillRetailEntryScreenState();
}

class _WaybillRetailEntryScreenState extends State<WaybillRetailEntryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!WaybillCustomerSelectionScreen.isValidCustomerId(
        widget.customerId,
      )) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context).translate(
                'field_sales.waybill_requires_customer',
              ),
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const WaybillCustomerSelectionScreen(
              isRetail: true,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.waybill_retail_entry');

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
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }
}
