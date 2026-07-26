// Dosya Adı: data_transfer_triad.dart
// Açıklama: Güncelleme dens triad aksiyonları (Gönder / Al / Ürün Resimleri)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template data_transfer_action}
/// MBT Güncelleme triad aksiyonu.
/// {@endtemplate}
enum DataTransferAction {
  /// Cihazdakileri Gönder
  send,

  /// Sunucudan Al
  receive,

  /// Ürün Resimleri
  productImages,
}

/// {@template data_transfer_triad}
/// Dens triad: hangi aksiyon hangi sync satırlarını çalıştırır.
///
/// Kullanım örneği:
/// ```dart
/// final keys = DataTransferTriad.itemKeys(DataTransferAction.send);
/// // ['upload']
/// ```
/// {@endtemplate}
class DataTransferTriad {
  DataTransferTriad._();

  /// [transferringKey]: Aktarılıyor durumu l10n anahtarı
  static const String transferringKey = 'field_sales.transferring';

  /// [emptyQueueKey]: Gönder başında kuyruk zaten boş
  static const String emptyQueueKey = 'field_sales.no_documents_to_transfer';

  /// [sendQueueClearedKey]: Gönder sonrası kuyruk temizlendi
  static const String sendQueueClearedKey = 'field_sales.send_queue_cleared';

  /// {@template data_transfer_triad_label_key}
  /// Aksiyon buton etiketi l10n anahtarı.
  ///
  /// Parametreler:
  /// - [action]: Triad aksiyonu
  ///
  /// Dönüş değeri:
  /// - [String]: `field_sales.*` çeviri anahtarı
  /// {@endtemplate}
  static String labelKey(DataTransferAction action) {
    switch (action) {
      case DataTransferAction.send:
        return 'field_sales.send_from_device';
      case DataTransferAction.receive:
        return 'field_sales.receive_from_server';
      case DataTransferAction.productImages:
        return 'field_sales.product_images';
    }
  }

  /// {@template data_transfer_triad_send_empty_message_key}
  /// Gönder boş kuyruk dens empty state l10n anahtarı.
  ///
  /// Parametreler:
  /// - [hadPending]: Gönder öncesi kuyrukta belge var mıydı
  ///
  /// Dönüş değeri:
  /// - [String]: `field_sales.*` çeviri anahtarı
  /// {@endtemplate}
  static String sendEmptyMessageKey({required bool hadPending}) {
    return hadPending ? sendQueueClearedKey : emptyQueueKey;
  }

  /// {@template data_transfer_triad_item_keys}
  /// Aksiyonun çalıştıracağı sync satır anahtarları (sıralı).
  ///
  /// Parametreler:
  /// - [action]: Triad aksiyonu
  ///
  /// Dönüş değeri:
  /// - [List]: sync item `key` listesi
  /// {@endtemplate}
  static List<String> itemKeys(DataTransferAction action) {
    switch (action) {
      case DataTransferAction.send:
        return const ['upload'];
      case DataTransferAction.receive:
        return const ['customers', 'products', 'stock', 'balances'];
      case DataTransferAction.productImages:
        return const ['product_images'];
    }
  }
}
