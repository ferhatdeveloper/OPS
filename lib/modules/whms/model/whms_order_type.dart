// Dosya Adı: whms_order_type.dart
// Açıklama: WHMS emir tipi enum (DEYS/Logo WMS P0 matrisi)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template whms_order_type}
/// Merkez depo emir tipi — blueprint P0 checklist.
///
/// Wire (SQLite / JSON): `mal_kabul`, `putaway`, `pick`, `sevk`,
/// `transfer`, `sayim`, `load`.
///
/// Kullanım örneği:
/// ```dart
/// final t = WhmsOrderType.malKabul;
/// print(t.wireName); // mal_kabul
/// ```
/// {@endtemplate}
enum WhmsOrderType {
  /// Mal kabul (satınalma girişi)
  malKabul,

  /// Yerleştirme (putaway)
  putaway,

  /// Toplama (pick)
  pick,

  /// Sevk / satış çıkış
  sevk,

  /// Ambar transferi
  transfer,

  /// Sayım
  sayim,

  /// Araç yükleme (OPS van köprüsü)
  load;

  /// SQLite / JSON wire kodu (snake_case).
  String get wireName {
    switch (this) {
      case WhmsOrderType.malKabul:
        return 'mal_kabul';
      case WhmsOrderType.putaway:
        return 'putaway';
      case WhmsOrderType.pick:
        return 'pick';
      case WhmsOrderType.sevk:
        return 'sevk';
      case WhmsOrderType.transfer:
        return 'transfer';
      case WhmsOrderType.sayim:
        return 'sayim';
      case WhmsOrderType.load:
        return 'load';
    }
  }

  /// [wireName] ile aynı — geriye uyumluluk.
  String get storageCode => wireName;

  /// l10n key (G ajanı çevirecek) — sabit string ID.
  String get l10nKey => 'whms.orders.type_$wireName';

  /// [malKabul] / [putaway] için satırda `location_code` zorunlu mu.
  bool get requiresLocation =>
      this == WhmsOrderType.malKabul || this == WhmsOrderType.putaway;

  /// Kod → enum; bilinmeyen → [malKabul].
  static WhmsOrderType fromWire(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    for (final t in WhmsOrderType.values) {
      if (t.wireName == v) return t;
    }
    if (v == 'mal kabul' || v == 'receipt') {
      return WhmsOrderType.malKabul;
    }
    if (v == 'ship' || v == 'shipment') {
      return WhmsOrderType.sevk;
    }
    if (v == 'count' || v == 'stock_count') {
      return WhmsOrderType.sayim;
    }
    return WhmsOrderType.malKabul;
  }

  /// [fromWire] alias.
  static WhmsOrderType fromStorageCode(String? raw) => fromWire(raw);

  /// Bilinen kod mu.
  static bool isKnown(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    return WhmsOrderType.values.any((t) => t.wireName == v);
  }
}
