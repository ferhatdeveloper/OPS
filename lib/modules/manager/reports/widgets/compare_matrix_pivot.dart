// Dosya Adı: compare_matrix_pivot.dart
// Açıklama: Esnek matris dens pivot tablo (yatay kaydırma)
// Oluşturulma Tarihi: 2026-08-04
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-04

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/compare_matrix_models.dart';

/// {@template compare_matrix_pivot}
/// Satır × sütun dens matris tablosu.
///
/// Kullanım örneği:
/// ```dart
/// CompareMatrixPivot(result: result)
/// ```
/// {@endtemplate}
class CompareMatrixPivot extends StatelessWidget {
  /// [result]: Matris
  final CompareMatrixResult result;

  /// {@macro compare_matrix_pivot}
  const CompareMatrixPivot({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    if (result.rowKeys.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.translate('advanced.period_compare_empty'),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      );
    }

    const colW = 72.0;
    const rowHdr = 100.0;
    final tableW = rowHdr + result.colKeys.length * colW;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableW,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    SizedBox(
                      width: rowHdr,
                      child: Text(
                        l10n.translate('advanced.metric'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    for (final c in result.colLabels)
                      SizedBox(
                        width: colW,
                        child: Text(
                          c,
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              for (var i = 0; i < result.rowKeys.length; i++) ...[
                if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: rowHdr,
                        child: Text(
                          result.rowLabels[i],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      for (final col in result.colKeys)
                        SizedBox(
                          width: colW,
                          child: Text(
                            result
                                .valueAt(result.rowKeys[i], col)
                                .toStringAsFixed(0),
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
