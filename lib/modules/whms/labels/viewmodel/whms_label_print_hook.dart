// Dosya Adı: whms_label_print_hook.dart
// Açıklama: Etiket şablon → BluetoothPrintService.printLabel köprüsü
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../../../../service/bluetooth_print_service.dart';
import '../model/whms_label_template.dart';

/// {@template whms_label_print_hook}
/// Mevcut saha `BluetoothPrintService.printLabel` kancası.
/// Bağlı yazıcı yoksa sessizce no-op (servis davranışı).
///
/// Kullanım örneği:
/// ```dart
/// await WhmsLabelPrintHook().printTemplate(template);
/// ```
/// {@endtemplate}
class WhmsLabelPrintHook {
  /// [printService]: Test enjeksiyonu
  final BluetoothPrintService? printService;

  /// {@macro whms_label_print_hook}
  const WhmsLabelPrintHook({this.printService});

  /// Şablon örnek alanlarıyla etiket basar.
  ///
  /// Parametreler:
  /// - [template]: Aktif etiket şablonu
  ///
  /// Dönüş değeri:
  /// - [bool]: true ise çağrı tamamlandı (bağlı değilse de true / no-op)
  Future<bool> printTemplate(WhmsLabelTemplate template) async {
    final svc = printService ?? BluetoothPrintService();
    final name = (template.sampleProductName ?? '').trim().isEmpty
        ? template.name
        : template.sampleProductName!.trim();
    final code = (template.sampleProductCode ?? '').trim().isEmpty
        ? template.code
        : template.sampleProductCode!.trim();
    final price = (template.samplePrice ?? '').trim().isEmpty
        ? '0,00'
        : template.samplePrice!.trim();
    await svc.printLabel(
      name,
      code,
      price,
      labelType: template.printLabelType,
    );
    return true;
  }
}
