import 'package:flutter/material.dart';

/// A utility class for color operations
class ColorUtils {
  /// Creates a color with opacity without using withOpacity
  /// This avoids performance issues associated with withOpacity
  static Color withAlpha(Color color, double opacity) {
    // Ensure opacity is between 0 and 1
    opacity = opacity.clamp(0.0, 1.0);

    // Convert opacity to int (0-255)
    final int alpha = (opacity * 255).round();

    // Return new color with modified alpha
    return Color.fromARGB(alpha, color.red, color.green, color.blue);
  }

  /// Predefined transparent colors
  static const Color blackWithOpacity1 = Color(0x1A000000); // 10% black
  static const Color blackWithOpacity05 = Color(0x0D000000); // 5% black
  static const Color blackWithOpacity2 = Color(0x33000000); // 20% black
  static const Color blackWithOpacity3 = Color(0x4D000000); // 30% black

  static const Color whiteWithOpacity05 = Color(0x0DFFFFFF); // 5% white
  static const Color whiteWithOpacity1 = Color(0x1AFFFFFF); // 10% white
  static const Color whiteWithOpacity2 = Color(0x33FFFFFF); // 20% white
  static const Color whiteWithOpacity6 = Color(0x99FFFFFF); // 60% white
  static const Color whiteWithOpacity7 = Color(0xB3FFFFFF); // 70% white
  static const Color whiteWithOpacity85 = Color(0xD9FFFFFF); // 85% white
  static const Color whiteWithOpacity9 = Color(0xE6FFFFFF); // 90% white

  /// Helper method to update shadow color
  static List<BoxShadow> getShadow({
    bool isDarkMode = false,
    double blurRadius = 10,
    double spreadRadius = 0,
    bool isLight = true,
  }) {
    if (isDarkMode && isLight) {
      return [];
    }

    return [
      BoxShadow(
        color: isDarkMode ? blackWithOpacity2 : blackWithOpacity05,
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
      ),
    ];
  }

  /// Retrieve a color based on the icon type to ensure consistency
  static Color getColorForIcon(IconData icon) {
    if (icon == Icons.shopping_cart ||
        icon == Icons.shopping_basket ||
        icon == Icons.point_of_sale) {
      return const Color(0xFF3498DB); // Blue for shopping related icons
    } else if (icon == Icons.receipt ||
        icon == Icons.receipt_long ||
        icon == Icons.document_scanner) {
      return const Color(0xFF9B59B6); // Purple for receipt related icons
    } else if (icon == Icons.payments ||
        icon == Icons.monetization_on ||
        icon == Icons.credit_score) {
      return const Color(0xFF2ECC71); // Green for payment related icons
    } else if (icon == Icons.account_balance ||
        icon == Icons.account_balance_wallet) {
      return const Color(0xFF7E57C2); // Deep purple for finance related icons
    } else if (icon == Icons.inventory || icon == Icons.inventory_2) {
      return const Color(0xFF4FC3F7); // Light blue for inventory related icons
    } else if (icon == Icons.person || icon == Icons.people) {
      return const Color(0xFFE99356); // Orange for people related icons
    } else if (icon == Icons.star) {
      return const Color(0xFFFFB74D); // Amber for favorites
    } else if (icon == Icons.assessment ||
        icon == Icons.bar_chart ||
        icon == Icons.insights) {
      return const Color(0xFF81C784); // Light green for reporting
    } else if (icon == Icons.app_registration) {
      return const Color(0xFF5D4037); // Brown for registration/main records
    } else if (icon == Icons.auto_stories) {
      return const Color(0xFF00ACC1); // Cyan for accounting
      return const Color(0xFFF06292); // Pink for checks/promissory notes
    } else if (icon == Icons.settings || icon == Icons.manage_accounts) {
      return const Color(0xFF78909C); // Blue grey for system settings
    } else if (icon == Icons.location_on) {
      return const Color(0xFFE53935); // Red for Visit/Location
    } else if (icon == Icons.qr_code_scanner || icon == Icons.qr_code) {
      return const Color(0xFF00897B); // Teal for Stock/Barcode
    } else if (icon == Icons.currency_exchange) {
      return const Color(0xFFFBC02D); // Yellow for Currency
    } else if (icon == Icons.sync) {
      return const Color(0xFF1E88E5); // Blue for Sync
    } else if (icon == Icons.more_horiz) {
      return const Color(0xFF8D6E63); // Brown for Other
    }

    // Default color if no match
    return const Color(0xFF607D8B); // Blue grey as default
  }

  /// Get gradient colors based on icon for more visually appealing backgrounds
  static List<Color> getGradientColorsForIcon(IconData icon) {
    final baseColor = getColorForIcon(icon);

    // Create gradient with lighter and darker versions of base color
    return [
      _lightenColor(baseColor, 0.2),
      baseColor,
      _darkenColor(baseColor, 0.1),
    ];
  }

  /// Make a color lighter by a factor (0-1)
  static Color _lightenColor(Color color, double factor) {
    final int red = color.red;
    final int green = color.green;
    final int blue = color.blue;

    final int newRed = (red + ((255 - red) * factor)).round().clamp(0, 255);
    final int newGreen = (green + ((255 - green) * factor)).round().clamp(
      0,
      255,
    );
    final int newBlue = (blue + ((255 - blue) * factor)).round().clamp(0, 255);

    return Color.fromARGB(color.alpha, newRed, newGreen, newBlue);
  }

  /// Make a color darker by a factor (0-1)
  static Color _darkenColor(Color color, double factor) {
    final int red = color.red;
    final int green = color.green;
    final int blue = color.blue;

    final int newRed = (red * (1 - factor)).round().clamp(0, 255);
    final int newGreen = (green * (1 - factor)).round().clamp(0, 255);
    final int newBlue = (blue * (1 - factor)).round().clamp(0, 255);

    return Color.fromARGB(color.alpha, newRed, newGreen, newBlue);
  }
}
