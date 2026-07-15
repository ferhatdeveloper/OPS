import 'package:flutter/material.dart';

// Use the same color constant from dashboard screen
const Color exfinDarkBlue = Color.fromARGB(255, 5, 79, 153);

/// Display a company information dialog with details
void showCompanyInfoDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: exfinDarkBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOGO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Firma Bilgileri',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Company info
                const Column(
                  children: [
                    CompanyInfoRow(label: 'Firma Adı', value: 'LOGO Yazılım'),
                    CompanyInfoRow(
                      label: 'Lisans Türü',
                      value: '3-MARKET 2025',
                    ),
                    CompanyInfoRow(
                      label: 'Lisans Dönemi',
                      value: '01.01.2025 - 31.12.2025',
                    ),
                    CompanyInfoRow(label: 'Kullanıcı Sayısı', value: '3'),
                    CompanyInfoRow(label: 'Versiyon', value: '1.00.0'),
                    CompanyInfoRow(
                      label: 'Veritabanı',
                      value: 'MS SQL SERVER - EXFINERP.DB',
                    ),
                    CompanyInfoRow(label: 'Son Yedekleme', value: '18.05.2025'),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: exfinDarkBlue,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Kapat',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

/// Widget for displaying a company information row
class CompanyInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const CompanyInfoRow({Key? key, required this.label, required this.value})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
