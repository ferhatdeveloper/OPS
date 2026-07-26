// Dosya Adı: invoice_customer_selection_screen.dart
// Açıklama: Fatura girişi öncesi zorunlu cari seçim (OrderCustomerSelectionScreen reuse)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../orders/view/order_customer_selection_screen.dart';
import 'invoice_entry_screen.dart';

/// {@template invoice_customer_selection_screen}
/// Plasiyer fatura girmeden önce cari kart seçer.
/// UI: [OrderCustomerSelectionScreen] — yalnızca hedef ekran fatura.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => const InvoiceCustomerSelectionScreen(),
/// ));
/// ```
/// {@endtemplate}
class InvoiceCustomerSelectionScreen extends ConsumerWidget {
  /// [title]: Fatura giriş ekranı AppBar başlığı
  final String title;

  /// [invoiceType]: LOGO / iş kuralı fatura tipi
  final String invoiceType;

  const InvoiceCustomerSelectionScreen({
    Key? key,
    this.title = 'Satış Faturası',
    this.invoiceType = 'Sıcak Satış (Van Sales)',
  }) : super(key: key);

  /// {@template emptyMessage}
  /// Boş DB / arama sonucu — sipariş seçimi ile aynı anahtarlar.
  /// {@endtemplate}
  static String emptyMessage(String query) =>
      OrderCustomerSelectionScreen.emptyMessage(query);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrderCustomerSelectionScreen(
      selectHintKey: 'field_sales.select_customer_first_invoice',
      onCustomerSelected: (ctx, customer) {
        if (customer.id.trim().isEmpty) return;
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(
            builder: (_) => InvoiceEntryScreen(
              customerId: customer.id,
              title: title,
              invoiceType: invoiceType,
            ),
          ),
        );
      },
    );
  }
}
