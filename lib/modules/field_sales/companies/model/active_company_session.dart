// Dosya Adı: active_company_session.dart
// Açıklama: Aktif firma/dönem oturum kaydı (MBT AppBar 001_01 bağlamı)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template active_company_session}
/// Seçili firma + dönem oturum bilgisi.
///
/// Kullanım örneği:
/// ```dart
/// const session = ActiveCompanySession(
///   companyId: 'mbt_001',
///   companyName: 'MBT',
///   companyNo: '001',
///   periodNo: '01',
/// );
/// print(session.appBarLabel); // MBT ( 001_01 )
/// ```
/// {@endtemplate}
class ActiveCompanySession {
  /// [companyId]: companies.id
  final String companyId;

  /// [companyName]: Firma adı
  final String companyName;

  /// [companyNo]: Firma No (ör. 001)
  final String companyNo;

  /// [periodNo]: Dönem No (ör. 01)
  final String periodNo;

  /// [startDate]: Dönem başlangıç (opsiyonel görüntü)
  final String startDate;

  /// [endDate]: Dönem bitiş (opsiyonel görüntü)
  final String endDate;

  /// {@macro active_company_session}
  const ActiveCompanySession({
    required this.companyId,
    required this.companyName,
    required this.companyNo,
    required this.periodNo,
    this.startDate = '',
    this.endDate = '',
  });

  /// Boş / henüz seçilmemiş oturum
  static const ActiveCompanySession empty = ActiveCompanySession(
    companyId: '',
    companyName: '',
    companyNo: '',
    periodNo: '',
  );

  /// [isEmpty]: Firma veya dönem seçili değil
  bool get isEmpty => companyNo.isEmpty || periodNo.isEmpty;

  /// [isNotEmpty]: Geçerli firma+dönem var
  bool get isNotEmpty => !isEmpty;

  /// MBT AppBar biçimi: `MBT ( 001_01 )`
  String get appBarLabel {
    if (isEmpty) return companyName;
    final name = companyName.isEmpty ? companyNo : companyName;
    return '$name ( ${companyNo}_$periodNo )';
  }

  /// Dens chip kısa biçim: `001_01` (dashboard kalabalığı azaltır)
  String get densChipLabel {
    if (isEmpty) return companyName;
    return '${companyNo}_$periodNo';
  }

  /// {@template active_company_session_copy_with}
  /// Kısmi güncelleme.
  /// {@endtemplate}
  ActiveCompanySession copyWith({
    String? companyId,
    String? companyName,
    String? companyNo,
    String? periodNo,
    String? startDate,
    String? endDate,
  }) {
    return ActiveCompanySession(
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      companyNo: companyNo ?? this.companyNo,
      periodNo: periodNo ?? this.periodNo,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActiveCompanySession &&
        other.companyId == companyId &&
        other.companyName == companyName &&
        other.companyNo == companyNo &&
        other.periodNo == periodNo &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(
        companyId,
        companyName,
        companyNo,
        periodNo,
        startDate,
        endDate,
      );
}
