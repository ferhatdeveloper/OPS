// Dosya Adı: conflict_strategy.dart
// Açıklama: Senkronizasyon çakışma çözüm stratejileri
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS

/// {@template conflict_strategy}
/// Senkronizasyon çakışma çözüm stratejileri.
/// {@endtemplate}
enum ConflictStrategy {
  /// Sunucudaki veri her zaman kazanır
  serverWins,
  
  /// Kliandaki veri her zaman kazanır
  clientWins,
  
  /// Son güncelleme tarihi daha yeni olan kazanır
  lastWriteWins,
  
  /// Çakışma durumunda manuel müdahale bekler
  manual,
}

extension ConflictStrategyExtension on ConflictStrategy {
  String get name {
    switch (this) {
      case ConflictStrategy.serverWins:
        return 'Sunucu Kazanır';
      case ConflictStrategy.clientWins:
        return 'Cihaz Kazanır';
      case ConflictStrategy.lastWriteWins:
        return 'Son Yazan Kazanır';
      case ConflictStrategy.manual:
        return 'Manuel Çözüm';
    }
  }

  static ConflictStrategy fromString(String value) {
    switch (value.toLowerCase()) {
      case 'serverwins':
        return ConflictStrategy.serverWins;
      case 'clientwins':
        return ConflictStrategy.clientWins;
      case 'lastwritewins':
        return ConflictStrategy.lastWriteWins;
      case 'manual':
        return ConflictStrategy.manual;
      default:
        return ConflictStrategy.lastWriteWins;
    }
  }
}
