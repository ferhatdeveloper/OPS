class RegionalConfig {
  /// Toggle this to true for Iraq region specific behavior
  static const bool isIraqRegion = true;

  /// Whether e-invoice features (TR specific) should be visible
  static bool get showEInvoice => !isIraqRegion;

  /// Default currency symbol for the region
  static String get currencySymbol => isIraqRegion ? 'ID' : 'TL';
}
