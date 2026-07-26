// Dosya Adı: cash_card_seed.dart
// Açıklama: CashCardMaster → SQLite cash_cards seed satırları
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'cash_card_master.dart';

/// {@template cash_card_seed_row}
/// Tek kasa kartı seed satırı (kod + l10n + TR seed adı).
///
/// Kullanım örneği:
/// ```dart
/// const row = CashCardSeedRow(
///   id: 'cc_100_01_01',
///   code: '100 01 01',
///   nameKey: 'field_sales.cash_card_merkez_tl',
///   seedName: 'MERKEZ TL KASA',
/// );
/// ```
/// {@endtemplate}
class CashCardSeedRow {
  /// [id]: SQLite birincil anahtar
  final String id;

  /// [code]: Logo / MBT safe_code
  final String code;

  /// [nameKey]: Görünen ad l10n anahtarı
  final String nameKey;

  /// [seedName]: SQLite seed TR ünvan
  final String seedName;

  /// {@macro cash_card_seed_row}
  const CashCardSeedRow({
    required this.id,
    required this.code,
    required this.nameKey,
    required this.seedName,
  });
}

/// {@template cash_card_record}
/// SQLite `cash_cards` satır modeli.
///
/// Kullanım örneği:
/// ```dart
/// final r = CashCardRecord.fromMap(map);
/// ```
/// {@endtemplate}
class CashCardRecord {
  /// [id]: Birincil anahtar
  final String id;

  /// [code]: safe_code
  final String code;

  /// [name]: Yerel ünvan (seed TR veya sync)
  final String name;

  /// [nameKey]: l10n anahtarı
  final String nameKey;

  /// [isActive]: Aktif kasa
  final bool isActive;

  /// [isSynced]: Logo / merkez sync durumu
  final bool isSynced;

  /// [createdAt]: Oluşturma
  final String? createdAt;

  /// [updatedAt]: Güncelleme
  final String? updatedAt;

  /// {@macro cash_card_record}
  const CashCardRecord({
    required this.id,
    required this.code,
    required this.name,
    required this.nameKey,
    this.isActive = true,
    this.isSynced = false,
    this.createdAt,
    this.updatedAt,
  });

  /// {@template cash_card_record_from_map}
  /// SQLite map → kayıt.
  /// {@endtemplate}
  factory CashCardRecord.fromMap(Map<String, dynamic> map) {
    return CashCardRecord(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      nameKey: map['name_key']?.toString() ?? '',
      isActive: (map['is_active'] as num?)?.toInt() != 0,
      isSynced: (map['is_synced'] as num?)?.toInt() == 1,
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  /// {@template cash_card_record_to_map}
  /// SQLite insert / update map.
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'code': code,
      'name': name,
      'name_key': nameKey,
      'is_active': isActive ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// {@template cash_card_record_to_option}
  /// Dens seçici [CashCardOption] dönüşümü.
  /// {@endtemplate}
  CashCardOption toOption() => CashCardOption(code: code, l10nKey: nameKey);
}

/// {@template cash_card_seed}
/// Kasa kart master seed — tek kaynak [CashCardMaster].
///
/// Kullanım örneği:
/// ```dart
/// final maps = CashCardSeed.defaultMaps;
/// ```
/// {@endtemplate}
class CashCardSeed {
  CashCardSeed._();

  /// [tableName]: SQLite tablo adı
  static const String tableName = 'cash_cards';

  /// [seedCreatedAt]: Sabit seed zaman damgası
  static const String seedCreatedAt = '2026-07-26T00:00:00.000';

  /// Kod → TR seed ünvan (tr.json ile hizalı)
  static const Map<String, String> _seedNames = {
    '100 01 01': 'MERKEZ TL KASA',
    '100 01 02': 'MERKEZ USD KASA',
    '100 01 03': 'MERKEZ EURO KASA',
    '200 01 01': 'ŞUBE TL KASA',
  };

  /// {@template cash_card_seed_id_of}
  /// safe_code → SQLite id (`cc_100_01_01`).
  ///
  /// Parametreler:
  /// - [code]: Kasa kodu
  ///
  /// Dönüş değeri:
  /// - [String]: Birincil anahtar
  /// {@endtemplate}
  static String idOf(String code) => 'cc_${code.trim().replaceAll(' ', '_')}';

  /// Yer tutucu dens kasalar ([CashCardMaster.options] sırası).
  static List<CashCardSeedRow> get defaultRows {
    return CashCardMaster.options
        .map(
          (o) => CashCardSeedRow(
            id: idOf(o.code),
            code: o.code,
            nameKey: o.l10nKey,
            seedName: _seedNames[o.code] ?? o.code,
          ),
        )
        .toList(growable: false);
  }

  /// {@template cash_card_seed_by_code}
  /// Koda göre seed satırı.
  ///
  /// Parametreler:
  /// - [code]: safe_code
  ///
  /// Dönüş değeri:
  /// - [CashCardSeedRow?]: Eşleşen satır
  /// {@endtemplate}
  static CashCardSeedRow? byCode(String code) {
    final trimmed = code.trim();
    for (final row in defaultRows) {
      if (row.code == trimmed) return row;
    }
    return null;
  }

  /// {@template cash_card_seed_maps}
  /// SQLite insert için map listesi.
  ///
  /// Dönüş değeri:
  /// - [List]: `cash_cards` satır map’leri
  /// {@endtemplate}
  static List<Map<String, dynamic>> get defaultMaps {
    return defaultRows
        .map(
          (row) => <String, dynamic>{
            'id': row.id,
            'code': row.code,
            'name': row.seedName,
            'name_key': row.nameKey,
            'is_active': 1,
            'is_synced': 0,
            'created_at': seedCreatedAt,
            'updated_at': seedCreatedAt,
          },
        )
        .toList(growable: false);
  }
}
