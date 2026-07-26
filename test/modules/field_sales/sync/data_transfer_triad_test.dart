// Dosya Adı: data_transfer_triad_test.dart
// Açıklama: Güncelleme dens triad (Gönder/Al/Ürün) aksiyon→satır eşlemesi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/sync/model/data_transfer_triad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataTransferTriad', () {
    test('gönder yalnız upload satırı çalıştırır', () {
      expect(
        DataTransferTriad.itemKeys(DataTransferAction.send),
        ['upload'],
      );
    });

    test('al master data satırlarını çalıştırır', () {
      expect(
        DataTransferTriad.itemKeys(DataTransferAction.receive),
        ['customers', 'products', 'stock', 'balances'],
      );
    });

    test('ürün resimleri yalnız images satırı çalıştırır', () {
      expect(
        DataTransferTriad.itemKeys(DataTransferAction.productImages),
        ['product_images'],
      );
    });

    test('aksiyon etiket anahtarları MBT triad kopyasıdır', () {
      expect(
        DataTransferTriad.labelKey(DataTransferAction.send),
        'field_sales.send_from_device',
      );
      expect(
        DataTransferTriad.labelKey(DataTransferAction.receive),
        'field_sales.receive_from_server',
      );
      expect(
        DataTransferTriad.labelKey(DataTransferAction.productImages),
        'field_sales.product_images',
      );
      expect(
        DataTransferTriad.transferringKey,
        'field_sales.transferring',
      );
    });

    test('gönder boş kuyruk empty state anahtarları', () {
      expect(
        DataTransferTriad.sendEmptyMessageKey(hadPending: false),
        DataTransferTriad.emptyQueueKey,
      );
      expect(
        DataTransferTriad.sendEmptyMessageKey(hadPending: true),
        DataTransferTriad.sendQueueClearedKey,
      );
      expect(
        DataTransferTriad.emptyQueueKey,
        'field_sales.no_documents_to_transfer',
      );
      expect(
        DataTransferTriad.sendQueueClearedKey,
        'field_sales.send_queue_cleared',
      );
    });
  });
}
