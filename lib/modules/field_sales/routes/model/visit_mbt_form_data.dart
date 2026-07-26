// Dosya Adı: visit_mbt_form_data.dart
// Açıklama: MBT ziyaret formu alan seti (not / sonuç / tamamla)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template visit_mbt_form_data}
/// MBT ziyaret formu değerleri.
///
/// Kullanım örneği:
/// ```dart
/// final data = VisitMbtFormData(
///   visitReason: 'ROUTINE',
///   notes: 'Görüşme notu',
///   outcome: 'Sipariş Alındı',
/// );
/// final notes = data.toPersistedNotes();
/// ```
/// {@endtemplate}
class VisitMbtFormData {
  /// [code]: Cari KOD (salt okunur özet)
  final String code;

  /// [title]: ÜNVAN
  final String title;

  /// [address]: ADRES
  final String address;

  /// [city]: İL
  final String city;

  /// [district]: İLÇE
  final String district;

  /// [country]: ÜLKE
  final String country;

  /// [visitReason]: ZIYARET SEBEBI — VisitReasonMaster stabil kodu
  final String visitReason;

  /// [customerType]: MÜŞTERI TIPI
  final String customerType;

  /// [department]: BÖLÜM
  final String department;

  /// [contactPerson]: İLGILI KIŞI
  final String contactPerson;

  /// [projectCode]: PROJE KODU
  final String projectCode;

  /// [referencePerson]: REFERANS KIŞI
  final String referencePerson;

  /// [attachments]: EKLER (gerçek path veya stub:// URI listesi)
  final String attachments;

  /// [notes]: Ziyaret notu
  final String notes;

  /// [outcome]: Ziyaret sonucu
  final String outcome;

  /// {@macro visit_mbt_form_data}
  const VisitMbtFormData({
    this.code = '',
    this.title = '',
    this.address = '',
    this.city = '',
    this.district = '',
    this.country = '',
    this.visitReason = '',
    this.customerType = '',
    this.department = '',
    this.contactPerson = '',
    this.projectCode = '',
    this.referencePerson = '',
    this.attachments = '',
    this.notes = '',
    this.outcome = '',
  });

  /// {@template visit_mbt_form_data_has_reason}
  /// Ziyaret sebebi seçilmiş mi.
  /// {@endtemplate}
  bool get hasReason => visitReason.trim().isNotEmpty;

  /// {@template visit_mbt_form_data_has_notes}
  /// Not alanı dolu mu.
  /// {@endtemplate}
  bool get hasNotes => notes.trim().isNotEmpty;

  /// {@template visit_mbt_form_data_to_persisted_notes}
  /// SQLite `visits.notes` için tek metin özeti.
  ///
  /// Dönüş değeri:
  /// - [String]: Satır satır MBT alan özeti
  /// {@endtemplate}
  String toPersistedNotes() {
    final lines = <String>[
      if (outcome.trim().isNotEmpty) 'SONUC: ${outcome.trim()}',
      if (visitReason.trim().isNotEmpty) 'SEBEP: ${visitReason.trim()}',
      if (customerType.trim().isNotEmpty) 'MUSTERI_TIPI: ${customerType.trim()}',
      if (department.trim().isNotEmpty) 'BOLUM: ${department.trim()}',
      if (contactPerson.trim().isNotEmpty)
        'ILGILI: ${contactPerson.trim()}',
      if (projectCode.trim().isNotEmpty) 'PROJE: ${projectCode.trim()}',
      if (referencePerson.trim().isNotEmpty)
        'REFERANS: ${referencePerson.trim()}',
      if (attachments.trim().isNotEmpty) 'EKLER: ${attachments.trim()}',
      if (notes.trim().isNotEmpty) 'NOT: ${notes.trim()}',
    ];
    return lines.join('\n');
  }
}
