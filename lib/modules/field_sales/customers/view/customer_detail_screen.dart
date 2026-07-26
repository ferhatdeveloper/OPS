// Dosya Adı: customer_detail_screen.dart
// Açıklama: Cari detay hub — FATURA / İRSALİYE / SİPARİŞ / ZİYARET / FİNANS
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/init/navigation/routes.dart';
import '../../../../core/localization/app_localization.dart';
import '../../routes/view/visit_form_screen.dart';
import '../../orders/model/order_model.dart';
import '../../orders/view/order_type_sheet.dart';
import '../model/customer_model.dart';

/// {@template customer_detail_hub_action}
/// MBT cari detay hub kısayolu: named route + l10n + ikon.
/// {@endtemplate}
class CustomerDetailHubAction {
  /// [routeName]: pushNamed hedefi
  final String routeName;

  /// [l10nKey]: `field_sales.customer_detail_hub_*`
  final String l10nKey;

  /// [icon]: Dense flat aksiyon ikonu
  final IconData icon;

  const CustomerDetailHubAction({
    required this.routeName,
    required this.l10nKey,
    required this.icon,
  });
}

/// {@template customer_detail_screen}
/// Cari kart detayı; hub’dan belge/ziyaret/finans named route’lara
/// `cariId` argument ile açılır (cari-önce guard ile uyumlu).
/// {@endtemplate}
class CustomerDetailScreen extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailScreen({Key? key, required this.customer})
      : super(key: key);

  /// MBT: FATURA · İRSALİYE · SİPARİŞ · ZİYARET · FİNANS
  static const List<CustomerDetailHubAction> hubActions =
      <CustomerDetailHubAction>[
    CustomerDetailHubAction(
      routeName: AppRoutes.fieldSalesInvoicesNew,
      l10nKey: 'field_sales.customer_detail_hub_invoice',
      icon: Icons.receipt_long_outlined,
    ),
    CustomerDetailHubAction(
      routeName: AppRoutes.fieldSalesWaybillWholesale,
      l10nKey: 'field_sales.customer_detail_hub_waybill',
      icon: Icons.local_shipping_outlined,
    ),
    CustomerDetailHubAction(
      routeName: AppRoutes.fieldSalesOrders,
      l10nKey: 'field_sales.customer_detail_hub_order',
      icon: Icons.add_shopping_cart_outlined,
    ),
    CustomerDetailHubAction(
      routeName: VisitFormScreen.routeName,
      l10nKey: 'field_sales.customer_detail_hub_visit',
      icon: Icons.place_outlined,
    ),
    CustomerDetailHubAction(
      routeName: AppRoutes.fieldSalesCollections,
      l10nKey: 'field_sales.customer_detail_hub_finance',
      icon: Icons.account_balance_wallet_outlined,
    ),
  ];

  /// {@template hubCariIdArg}
  /// Named route `arguments` için trim’li cariId; geçersizse null.
  /// {@endtemplate}
  static String? hubCariIdArg(String? customerId) {
    final id = customerId?.trim() ?? '';
    return id.isEmpty ? null : id;
  }

  /// {@template _openHubAction}
  /// Cari-önce named route’a `cariId` ile pushNamed.
  /// {@endtemplate}
  void _openHubAction(BuildContext context, CustomerDetailHubAction action) {
    final cariId = hubCariIdArg(customer.id);
    if (cariId == null) {
      final l10n = AppLocalization.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.order_requires_customer')),
        ),
      );
      return;
    }
    if (action.routeName == AppRoutes.fieldSalesOrders) {
      showOrderTypeSheet(context).then((type) {
        if (type == null || !context.mounted) return;
        final route = type == OrderType.purchase
            ? AppRoutes.fieldSalesOrdersPurchase
            : AppRoutes.fieldSalesOrdersSales;
        Navigator.pushNamed(context, route, arguments: cariId);
      });
      return;
    }
    Navigator.pushNamed(context, action.routeName, arguments: cariId);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2691E5);
    final l10n = AppLocalization.of(context);

    // Bakiye formatlaması (Mockup'taki ₺ X.XXX,XX görünümü)
    final currencyFormatter =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final formattedBalance = currencyFormatter.format(customer.balance);

    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Üst Bar ve Geri Tuşu
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Açıklama Metni (Mockup 3. sayfa)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Müşterilerinizin takibi cebinizde. Mobil cihazınızdan anlık olarak e-fatura, e-arşiv ve e-irsaliye düzenleyin!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Beyaz Kart Alanı
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Üst İkon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.group,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Firma Adı
                      Text(
                        customer.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C3E50),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // E-Fatura Etiketi
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "E-Fatura",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Adres ve İletişim Bilgileri (Mockup stili gri, alt alta)
                      Text(
                        customer.address?.toUpperCase() ??
                            "ADRES BELİRTİLMEMİŞ",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "---------------------------------",
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${customer.taxNo ?? '-'} • ${customer.taxOffice ?? '-'}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${customer.phone ?? '-'} •",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Uyarı Kutusu (Mavi)
                      if (customer.email == null || customer.email!.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: primaryBlue, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Müşterinin e-posta adresi bulunmamaktadır. Lütfen bu mesaja tıklayarak giriş yapınız.",
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Peşin Satış Toggle (Temsili)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Peşin Satış",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            Switch(
                              value: false,
                              onChanged: (val) {},
                              activeColor: primaryBlue,
                            ),
                          ],
                        ),
                      ),

                      // Alt Menü Seçenekleri (Hareketler, Mutabakat, Yenile)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildIconTextAction(Icons.list_alt, "Hareketler"),
                            _buildIconTextAction(
                              Icons.handshake_outlined,
                              "Mutabakat",
                            ),
                            _buildIconTextAction(Icons.refresh, "Yenile"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Risk ve Bakiye Kartları (3'lü Grid)
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              "Bakiye",
                              formattedBalance,
                              formattedBalance,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInfoCard("Risk Limiti", "~", "₺0,00"),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInfoCard("Yaş. Borç", "₺0,00", "₺0,00"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // MBT hub: FATURA / İRSALİYE / SİPARİŞ / ZİYARET / FİNANS
                      Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        spacing: 4,
                        runSpacing: 8,
                        children: [
                          for (final action in hubActions)
                            _buildCircularAction(
                              action.icon,
                              l10n.translate(action.l10nKey),
                              onTap: () => _openHubAction(context, action),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconTextAction(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value1, String value2) {
    const Color primaryBlue = Color(0xFF2691E5);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value1,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value2,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularAction(
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: Center(
                child: Icon(icon, color: Colors.grey.shade600, size: 22),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
