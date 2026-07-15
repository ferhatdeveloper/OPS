import 'package:flutter/material.dart';
import '../../../../core/localization/app_localization.dart';
import '../model/customer_model.dart';
import 'package:intl/intl.dart';

class CustomerDetailScreen extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailScreen({Key? key, required this.customer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2691E5);

    // Bakiye formatlaması (Mockup'taki ₺ X.XXX,XX görünümü)
    final currencyFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final formattedBalance = currencyFormatter.format(customer.balance);

    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Üst Bar ve Geri Tuşu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Üst İkon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.group,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 12),

                      // E-Fatura Etiketi
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
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
                      const SizedBox(height: 16),

                      // Adres ve İletişim Bilgileri (Mockup stili gri, alt alta)
                      Text(
                        customer.address?.toUpperCase() ?? "ADRES BELİRTİLMEMİŞ",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "---------------------------------",
                        style: TextStyle(color: Colors.grey.shade300, letterSpacing: 2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${customer.taxNo ?? '-'} • ${customer.taxOffice ?? '-'}",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${customer.phone ?? '-'} •",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),

                      // Uyarı Kutusu (Mavi)
                      if (customer.email == null || customer.email!.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: primaryBlue, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Müşterinin e-posta adresi bulunmamaktadır. Lütfen bu mesaja tıklayarak giriş yapınız.",
                                  style: TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Peşin Satış Toggle (Temsili)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Peşin Satış", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildIconTextAction(Icons.list_alt, "Hareketler"),
                            _buildIconTextAction(Icons.handshake_outlined, "Mutabakat"),
                            _buildIconTextAction(Icons.refresh, "Yenile"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Risk ve Bakiye Kartları (3'lü Grid)
                      Row(
                        children: [
                          Expanded(child: _buildInfoCard("Bakiye", formattedBalance, formattedBalance)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildInfoCard("Risk Limiti", "~", "₺0,00")),
                          const SizedBox(width: 8),
                          Expanded(child: _buildInfoCard("Yaş. Borç", "₺0,00", "₺0,00")),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Hızlı İşlem Butonları (Yuvarlak 4'lü)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCircularAction(Icons.add, "SİPARİŞ"),
                          _buildCircularAction(Icons.wallet, "TAHSİLAT"),
                          _buildCircularAction(Icons.add_circle_outline, "BİRE BİR"),
                          _buildCircularAction(Icons.help_outline, "ZİYARET"),
                        ],
                      ),
                      const SizedBox(height: 16),
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
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500),
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
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value1,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
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

  Widget _buildCircularAction(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
          ),
          child: Center(
            child: Icon(icon, color: Colors.grey.shade600, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5),
        ),
      ],
    );
  }
}
