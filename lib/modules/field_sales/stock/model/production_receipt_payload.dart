// Dosya Adı: production_receipt_payload.dart
// Açıklama: Üretimden giriş fişi → Logo / sync_queue payload üretici
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template production_receipt_line_data}
/// Kuyruk satırı için hafif kalem verisi (UI placeholder'dan bağımsız).
/// {@endtemplate}
class ProductionReceiptLineData {
  /// [code]: Ürün kodu
  final String code;

  /// [name]: Ürün adı
  final String name;

  /// [qty]: Miktar metni
  final String qty;

  const ProductionReceiptLineData({
    required this.code,
    required this.name,
    required this.qty,
  });
}

/// {@template production_receipt_payload}
/// Üretimden giriş dens fişinin kuyruk payload sabitleri ve builder'ı.
///
/// Kullanım örneği:
/// ```dart
/// final map = ProductionReceiptPayload.build(
///   id: 'uuid',
///   workplace: 'Merkez',
///   factory: 'F01',
///   warehouse: 'Merkez Depo',
///   date: DateTime(2026, 7, 26),
///   lines: const [],
/// );
/// ```
/// {@endtemplate}
class ProductionReceiptPayload {
  ProductionReceiptPayload._();

  /// [entityType]: [JobQueueService] `entity_type` değeri
  static const String entityType = 'production_receipt';

  /// [slipType]: Yerel fiş tipi (≠ fatura TYPE 8)
  static const String slipType = 'production_in';

  /// [queueType]: ExfinApi / Logo kanal anahtarı (TRCODE firma şeması)
  static const String queueType = 'production_receipt';

  /// {@template production_receipt_payload_build}
  /// Dens form alanlarından sync_queue payload üretir.
  ///
  /// Parametreler:
  /// - [id]: Yerel fiş kimliği
  /// - [workplace]: İşyeri
  /// - [factory]: Fabrika
  /// - [warehouse]: Ambar
  /// - [date]: Fiş tarihi
  /// - [lines]: Kalem satırları
  ///
  /// Dönüş değeri:
  /// - [Map]: Kuyruk JSON gövdesi
  /// {@endtemplate}
  static Map<String, dynamic> build({
    required String id,
    String? workplace,
    String? factory,
    String? warehouse,
    required DateTime date,
    required List<ProductionReceiptLineData> lines,
  }) {
    return {
      'id': id,
      'entity': entityType,
      'type': queueType,
      'slip_type': slipType,
      'workplace': workplace,
      'factory': factory,
      'warehouse': warehouse,
      'warehouse_code': warehouse,
      'date': date.toIso8601String(),
      'lines': lines
          .map(
            (line) => <String, dynamic>{
              'product_code': line.code,
              'product_name': line.name,
              'quantity': double.tryParse(line.qty.replaceAll(',', '.')) ?? 0,
              'qty_text': line.qty,
            },
          )
          .toList(),
    };
  }
}
