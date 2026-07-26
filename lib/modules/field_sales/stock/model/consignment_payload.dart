// Dosya Adı: consignment_payload.dart
// Açıklama: Konsinye fişi → Logo / sync_queue payload üretici
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template consignment_line_data}
/// Kuyruk satırı için hafif kalem verisi (UI placeholder'dan bağımsız).
/// {@endtemplate}
class ConsignmentLineData {
  /// [code]: Ürün kodu
  final String code;

  /// [name]: Ürün adı
  final String name;

  /// [qty]: Miktar metni
  final String qty;

  const ConsignmentLineData({
    required this.code,
    required this.name,
    required this.qty,
  });
}

/// {@template consignment_payload}
/// Konsinye dens fişinin kuyruk payload sabitleri ve builder'ı.
///
/// Kullanım örneği:
/// ```dart
/// final map = ConsignmentPayload.build(
///   id: 'uuid',
///   workplace: 'Merkez',
///   factory: 'F01',
///   warehouse: 'Merkez Depo',
///   date: DateTime(2026, 7, 26),
///   lines: const [],
/// );
/// ```
/// {@endtemplate}
class ConsignmentPayload {
  ConsignmentPayload._();

  /// [entityType]: [JobQueueService] `entity_type` değeri
  static const String entityType = 'consignment';

  /// [slipType]: Yerel fiş tipi (≠ fatura TYPE 8)
  static const String slipType = 'consignment';

  /// [queueType]: ExfinApi / Logo kanal anahtarı
  static const String queueType = 'consignment';

  /// {@template consignment_payload_build}
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
    required List<ConsignmentLineData> lines,
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
