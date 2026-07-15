// Dosya Adı: company_select_dialog.dart
// Açıklama: Modern firma seçim dialogu (dil seçim popup'ı gibi)
// Oluşturulma Tarihi: 2024-04-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-04-27

import 'package:flutter/material.dart';

Future<String?> showCompanySelectDialog(BuildContext context, List<Map<String, dynamic>> companies, String? selectedCompanyNo) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Firma Seçimi'),
        content: SizedBox(
          width: 320,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              final isSelected = company['company_no'] == selectedCompanyNo;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Material(
                  color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    leading: const Icon(Icons.business, color: Colors.blue),
                    title: Text(company['name'] ?? ''),
                    subtitle: company['detail'] != null && company['detail'].toString().isNotEmpty
                        ? Text(company['detail'])
                        : null,
                    selected: isSelected,
                    selectedTileColor: Colors.blue.shade50,
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () => Navigator.of(context).pop(company['company_no']),
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

Future<Map<String, dynamic>?> showPeriodSelectDialog(BuildContext context, List<Map<String, dynamic>> periods, Map<String, dynamic>? selectedPeriod) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Dönem Seçimi'),
        content: SizedBox(
          width: 340,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: periods.length,
            itemBuilder: (context, index) {
              final period = periods[index];
              final isSelected = selectedPeriod != null &&
                period['id'] == selectedPeriod['id'];
              final dateRange = '${period['start_date'] ?? ''} - ${period['end_date'] ?? ''}';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Material(
                  color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    leading: const Icon(Icons.business, color: Colors.blue),
                    title: Text(period['company_name'] ?? ''),
                    subtitle: Text(dateRange),
                    selected: isSelected,
                    selectedTileColor: Colors.blue.shade50,
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () => Navigator.of(context).pop(period),
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );
} 