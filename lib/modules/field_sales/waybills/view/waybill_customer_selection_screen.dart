// Dosya Adı: waybill_customer_selection_screen.dart
// Açıklama: İrsaliye girişi öncesi zorunlu cari seçim (OrderCustomerSelectionScreen reuse)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../orders/view/order_customer_selection_screen.dart';
import 'waybill_entry_screen.dart';
import 'waybill_retail_entry_screen.dart';

/// {@template waybill_customer_selection_screen}
/// Plasiyer irsaliye girmeden önce cari kart seçer.
/// UI: [OrderCustomerSelectionScreen] — hedef toptan veya perakende.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => const WaybillCustomerSelectionScreen(
///     waybillType: WaybillType.purchase,
///   ),
/// ));
/// ```
/// {@endtemplate}
class WaybillCustomerSelectionScreen extends ConsumerWidget {
  /// [title]: Toptan / satın alma giriş ekranı AppBar başlığı override
  final String? title;

  /// [waybillType]: Toptan satış veya satın alma fiş tipi
  final WaybillType waybillType;

  /// [isRetail]: true ise [WaybillRetailEntryScreen] açılır
  final bool isRetail;

  const WaybillCustomerSelectionScreen({
    Key? key,
    this.title,
    this.waybillType = WaybillType.wholesale,
    this.isRetail = false,
  }) : super(key: key);

  /// {@template emptyMessage}
  /// Boş DB / arama sonucu — sipariş seçimi ile aynı anahtarlar.
  /// {@endtemplate}
  static String emptyMessage(String query) =>
      OrderCustomerSelectionScreen.emptyMessage(query);

  /// {@template isValidCustomerId}
  /// Cari kart kimliğinin irsaliye için geçerli olup olmadığını kontrol eder.
  ///
  /// Parametreler:
  /// - [customerId]: Kontrol edilecek cari kimliği
  ///
  /// Dönüş değeri:
  /// - [bool]: Boş/whitespace değilse true
  /// {@endtemplate}
  static bool isValidCustomerId(String? customerId) {
    return customerId != null && customerId.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrderCustomerSelectionScreen(
      selectHintKey: 'field_sales.select_customer_first_waybill',
      onCustomerSelected: (ctx, customer) {
        if (!isValidCustomerId(customer.id)) return;
        if (isRetail) {
          Navigator.pushReplacement(
            ctx,
            MaterialPageRoute(
              builder: (_) => WaybillRetailEntryScreen(
                customerId: customer.id,
              ),
            ),
          );
          return;
        }
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(
            builder: (_) => WaybillEntryScreen(
              cariId: customer.id,
              title: title,
              waybillType: waybillType,
            ),
          ),
        );
      },
    );
  }
}
