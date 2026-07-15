import 'package:flutter/material.dart';

/// Responsive Tasarım için gerekli yardımcı sınıf
/// Bootstrap mantığı ile benzer ekran boyutları kullanılmıştır
class ResponsiveUtils {
  /// Ekran boyutları
  static const double xs = 480; // Extra small screens (telefonlar)
  static const double sm =
      768; // Small screens (büyük telefonlar, küçük tabletler)
  static const double md = 992; // Medium screens (tabletler)
  static const double lg = 1200; // Large screens (masaüstü)
  static const double xl = 1400; // Extra large screens (büyük masaüstü)

  /// Ekran boyutuna göre responsive değerler
  static bool isExtraSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < xs;

  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= xs &&
      MediaQuery.of(context).size.width < sm;

  static bool isMediumScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= sm &&
      MediaQuery.of(context).size.width < md;

  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= md &&
      MediaQuery.of(context).size.width < lg;

  static bool isExtraLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= lg;

  /// Cihaz tipi kontrolü
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < sm;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= sm &&
      MediaQuery.of(context).size.width < lg;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= lg;

  /// Responsive değerleri elde etmek için yardımcı metotlar
  static double responsiveValue({
    required BuildContext context,
    required double xs,
    required double sm,
    required double md,
    required double lg,
    double? xl,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width < ResponsiveUtils.xs) return xs;
    if (width < ResponsiveUtils.sm) return sm;
    if (width < ResponsiveUtils.md) return md;
    if (width < ResponsiveUtils.lg) return lg;
    return xl ?? lg;
  }

  /// Font boyutları için responsive değerler
  static double fontSize(
    BuildContext context, {
    double xs = 12,
    double sm = 14,
    double md = 16,
    double lg = 18,
    double xl = 20,
  }) {
    return responsiveValue(
      context: context,
      xs: xs,
      sm: sm,
      md: md,
      lg: lg,
      xl: xl,
    );
  }

  /// Icon boyutları için responsive değerler
  static double iconSize(
    BuildContext context, {
    double xs = 16,
    double sm = 20,
    double md = 24,
    double lg = 28,
    double xl = 32,
  }) {
    return responsiveValue(
      context: context,
      xs: xs,
      sm: sm,
      md: md,
      lg: lg,
      xl: xl,
    );
  }

  /// Padding değerleri için responsive değerler
  static double padding(
    BuildContext context, {
    double xs = 8,
    double sm = 12,
    double md = 16,
    double lg = 20,
    double xl = 24,
  }) {
    return responsiveValue(
      context: context,
      xs: xs,
      sm: sm,
      md: md,
      lg: lg,
      xl: xl,
    );
  }

  /// Margin değerleri için responsive değerler
  static double margin(
    BuildContext context, {
    double xs = 8,
    double sm = 12,
    double md = 16,
    double lg = 20,
    double xl = 24,
  }) {
    return responsiveValue(
      context: context,
      xs: xs,
      sm: sm,
      md: md,
      lg: lg,
      xl: xl,
    );
  }

  /// Border radius değerleri için responsive değerler
  static double borderRadius(
    BuildContext context, {
    double xs = 4,
    double sm = 8,
    double md = 12,
    double lg = 16,
    double xl = 20,
  }) {
    return responsiveValue(
      context: context,
      xs: xs,
      sm: sm,
      md: md,
      lg: lg,
      xl: xl,
    );
  }

  /// Widget boyutları için responsive değerler
  static double widgetSize(
    BuildContext context, {
    double xs = 100,
    double sm = 120,
    double md = 150,
    double lg = 180,
    double xl = 200,
  }) {
    return responsiveValue(
      context: context,
      xs: xs,
      sm: sm,
      md: md,
      lg: lg,
      xl: xl,
    );
  }

  /// Grid yapısı için sütun sayısını belirleyen metot
  static int gridCrossAxisCount(
    BuildContext context, {
    int xs = 1,
    int sm = 2,
    int md = 3,
    int lg = 4,
    int xl = 5,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width < ResponsiveUtils.xs) return xs;
    if (width < ResponsiveUtils.sm) return sm;
    if (width < ResponsiveUtils.md) return md;
    if (width < ResponsiveUtils.lg) return lg;
    return xl;
  }

  /// Responsive yükseklik değeri
  static double height(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * (percentage / 100);
  }

  /// Responsive genişlik değeri
  static double width(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * (percentage / 100);
  }

  /// Responsive boşluk değeri
  static Widget verticalSpace(BuildContext context, double percentage) {
    return SizedBox(height: height(context, percentage));
  }

  /// Responsive boşluk değeri
  static Widget horizontalSpace(BuildContext context, double percentage) {
    return SizedBox(width: width(context, percentage));
  }
}

/// Bootstrap benzeri grid sistemi
/// Ekran genişliğine göre sütun yapısı
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int xsCrossAxisCount;
  final int smCrossAxisCount;
  final int mdCrossAxisCount;
  final int lgCrossAxisCount;
  final int xlCrossAxisCount;
  final EdgeInsets padding;
  final bool shrinkWrap;
  final bool isScrollable;
  final ScrollPhysics? physics;

  const ResponsiveGridView({
    Key? key,
    required this.children,
    this.spacing = 10,
    this.runSpacing = 10,
    this.xsCrossAxisCount = 1,
    this.smCrossAxisCount = 2,
    this.mdCrossAxisCount = 3,
    this.lgCrossAxisCount = 4,
    this.xlCrossAxisCount = 5,
    this.padding = const EdgeInsets.all(10),
    this.shrinkWrap = false,
    this.isScrollable = true,
    this.physics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveUtils.gridCrossAxisCount(
      context,
      xs: xsCrossAxisCount,
      sm: smCrossAxisCount,
      md: mdCrossAxisCount,
      lg: lgCrossAxisCount,
      xl: xlCrossAxisCount,
    );

    return GridView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics:
          isScrollable
              ? physics ?? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: 1,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Bootstrap benzeri Row sınıfı
/// Ekran genişliğine göre sayfa düzeni
class ResponsiveRow extends StatelessWidget {
  final List<ResponsiveColumn> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const ResponsiveRow({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }
}

/// Bootstrap benzeri Column sınıfı
/// Ekran genişliğine göre boyut ayarlaması
class ResponsiveColumn extends StatelessWidget {
  final Widget child;
  final int xs;
  final int sm;
  final int md;
  final int lg;
  final int xl;
  final int total;

  const ResponsiveColumn({
    Key? key,
    required this.child,
    this.xs = 12,
    this.sm = 6,
    this.md = 4,
    this.lg = 3,
    this.xl = 2,
    this.total = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ekran genişliğine göre flex değeri
    int flex;
    final width = MediaQuery.of(context).size.width;

    if (width < ResponsiveUtils.xs) {
      flex = xs;
    } else if (width < ResponsiveUtils.sm) {
      flex = sm;
    } else if (width < ResponsiveUtils.md) {
      flex = md;
    } else if (width < ResponsiveUtils.lg) {
      flex = lg;
    } else {
      flex = xl;
    }

    // Eğer flex 0 ise görünmez
    if (flex == 0) {
      return const SizedBox();
    }

    // Eğer flex total'e eşitse, tüm genişliği kapla
    if (flex == total) {
      return child;
    }

    // Bootstrap mantığına uygun şekilde sütun genişliği
    return Expanded(flex: flex, child: child);
  }
}

/// Responsive Container
/// Ekran boyutuna göre farklı padding, margin ve boyut değerleri
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? xsPadding;
  final EdgeInsetsGeometry? smPadding;
  final EdgeInsetsGeometry? mdPadding;
  final EdgeInsetsGeometry? lgPadding;
  final EdgeInsetsGeometry? xlPadding;
  final EdgeInsetsGeometry? xsMargin;
  final EdgeInsetsGeometry? smMargin;
  final EdgeInsetsGeometry? mdMargin;
  final EdgeInsetsGeometry? lgMargin;
  final EdgeInsetsGeometry? xlMargin;
  final double? width;
  final double? height;
  final Color? color;
  final Decoration? decoration;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.xsPadding,
    this.smPadding,
    this.mdPadding,
    this.lgPadding,
    this.xlPadding,
    this.xsMargin,
    this.smMargin,
    this.mdMargin,
    this.lgMargin,
    this.xlMargin,
    this.width,
    this.height,
    this.color,
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ekran genişliğine göre padding ve margin
    EdgeInsetsGeometry? padding;
    EdgeInsetsGeometry? margin;
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < ResponsiveUtils.xs) {
      padding = xsPadding;
      margin = xsMargin;
    } else if (screenWidth < ResponsiveUtils.sm) {
      padding = smPadding ?? xsPadding;
      margin = smMargin ?? xsMargin;
    } else if (screenWidth < ResponsiveUtils.md) {
      padding = mdPadding ?? smPadding ?? xsPadding;
      margin = mdMargin ?? smMargin ?? xsMargin;
    } else if (screenWidth < ResponsiveUtils.lg) {
      padding = lgPadding ?? mdPadding ?? smPadding ?? xsPadding;
      margin = lgMargin ?? mdMargin ?? smMargin ?? xsMargin;
    } else {
      padding = xlPadding ?? lgPadding ?? mdPadding ?? smPadding ?? xsPadding;
      margin = xlMargin ?? lgMargin ?? mdMargin ?? smMargin ?? xsMargin;
    }

    return Container(
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      color: color,
      decoration: decoration,
      child: child,
    );
  }
}

/// Responsive Visibility
/// Ekran boyutuna göre gösterme/gizleme
class ResponsiveVisibility extends StatelessWidget {
  final Widget child;
  final bool visibleOnXs;
  final bool visibleOnSm;
  final bool visibleOnMd;
  final bool visibleOnLg;
  final bool visibleOnXl;

  const ResponsiveVisibility({
    Key? key,
    required this.child,
    this.visibleOnXs = true,
    this.visibleOnSm = true,
    this.visibleOnMd = true,
    this.visibleOnLg = true,
    this.visibleOnXl = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ekran genişliğine göre görünürlük
    bool isVisible;
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < ResponsiveUtils.xs) {
      isVisible = visibleOnXs;
    } else if (screenWidth < ResponsiveUtils.sm) {
      isVisible = visibleOnSm;
    } else if (screenWidth < ResponsiveUtils.md) {
      isVisible = visibleOnMd;
    } else if (screenWidth < ResponsiveUtils.lg) {
      isVisible = visibleOnLg;
    } else {
      isVisible = visibleOnXl;
    }

    return isVisible ? child : const SizedBox();
  }
}
