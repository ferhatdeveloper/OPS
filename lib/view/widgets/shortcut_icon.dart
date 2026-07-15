import 'package:flutter/material.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/responsive_utils.dart';

/// A custom widget for displaying shortcut icons in the dashboard
class ShortcutIcon extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDraggable;
  final int order;

  const ShortcutIcon({
    Key? key,
    required this.title,
    required this.icon,
    required this.backgroundColor,
    this.iconColor = Colors.white,
    required this.onTap,
    this.isDraggable = true,
    this.order = 0,
  }) : super(key: key);

  @override
  State<ShortcutIcon> createState() => _ShortcutIconState();
}

class _ShortcutIconState extends State<ShortcutIcon>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ResponsiveUtils kullanarak responsive değerler
    final double iconSize = ResponsiveUtils.iconSize(
      context,
      xs: 16,
      sm: 20,
      md: 24,
      lg: 28,
      xl: 32,
    );
    final double fontSize = ResponsiveUtils.fontSize(
      context,
      xs: 10,
      sm: 11,
      md: 12,
      lg: 14,
      xl: 16,
    );
    final double padding = ResponsiveUtils.padding(
      context,
      xs: 8,
      sm: 10,
      md: 12,
      lg: 14,
      xl: 16,
    );
    final double widgetSize = ResponsiveUtils.widgetSize(
      context,
      xs: 100,
      sm: 120,
      md: 140,
      lg: 160,
      xl: 180,
    );

    final shortcutWidget = MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Card(
          elevation: _isHovered ? 6 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.borderRadius(context),
            ),
            side: BorderSide(
              color: ColorUtils.withAlpha(widget.backgroundColor, 0.3),
              width: 1,
            ),
          ),
          shadowColor: ColorUtils.withAlpha(widget.backgroundColor, 0.4),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.borderRadius(context),
            ),
            splashColor: ColorUtils.withAlpha(widget.backgroundColor, 0.2),
            hoverColor: ColorUtils.withAlpha(widget.backgroundColor, 0.1),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: padding,
                horizontal: padding * 0.8,
              ),
              child: Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Smaller icon with modern glass effect
                    Container(
                      padding: EdgeInsets.all(padding),
                      decoration: BoxDecoration(
                        color:
                            ColorUtils.withAlpha(widget.backgroundColor, 0.12),
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.borderRadius(
                            context,
                            xs: 8,
                            sm: 10,
                            md: 12,
                            lg: 14,
                            xl: 16,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ColorUtils.withAlpha(
                              widget.backgroundColor,
                              0.1,
                            ),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                        border: Border.all(
                          color: ColorUtils.withAlpha(
                            widget.backgroundColor,
                            0.4,
                          ),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        size: iconSize,
                        color: widget.backgroundColor,
                      ),
                    ),
                    SizedBox(height: padding * 0.7),
                    // Title with modern styling
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Return draggable widget if needed
    return widget.isDraggable
        ? Draggable<ShortcutIcon>(
            data: widget,
            feedback: SizedBox(
              width: widgetSize,
              height: widgetSize,
              child: shortcutWidget,
            ),
            childWhenDragging: Opacity(opacity: 0.5, child: shortcutWidget),
            child: shortcutWidget,
          )
        : shortcutWidget;
  }
}

/// A more advanced version that matches the custom icons in the screenshot
class ModernShortcutIcon extends StatefulWidget {
  final String title;
  final Widget icon;
  final Color backgroundColor;
  final VoidCallback onTap;
  final bool isDraggable;
  final int order;

  const ModernShortcutIcon({
    Key? key,
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
    this.isDraggable = true,
    this.order = 0,
  }) : super(key: key);

  @override
  State<ModernShortcutIcon> createState() => _ModernShortcutIconState();
}

class _ModernShortcutIconState extends State<ModernShortcutIcon>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ResponsiveUtils kullanarak responsive değerler
    final double fontSize = ResponsiveUtils.fontSize(
      context,
      xs: 10,
      sm: 11,
      md: 12,
      lg: 14,
      xl: 16,
    );
    final double padding = ResponsiveUtils.padding(
      context,
      xs: 8,
      sm: 10,
      md: 12,
      lg: 14,
      xl: 16,
    );
    final double widgetSize = ResponsiveUtils.widgetSize(
      context,
      xs: 100,
      sm: 120,
      md: 140,
      lg: 160,
      xl: 180,
    );

    final iconWidget = MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Card(
          elevation: _isHovered ? 6 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.borderRadius(context),
            ),
          ),
          shadowColor: ColorUtils.withAlpha(widget.backgroundColor, 0.4),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.borderRadius(context),
            ),
            splashColor: ColorUtils.withAlpha(widget.backgroundColor, 0.2),
            hoverColor: ColorUtils.withAlpha(widget.backgroundColor, 0.1),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.icon,
                  SizedBox(height: padding * 0.7),
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding * 0.4),
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                          color: ColorUtils.withAlpha(Colors.black, 0.8),
                          letterSpacing: 0.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return widget.isDraggable
        ? Draggable<ModernShortcutIcon>(
            data: widget,
            feedback: SizedBox(
              width: widgetSize,
              height: widgetSize,
              child: iconWidget,
            ),
            childWhenDragging: Opacity(opacity: 0.5, child: iconWidget),
            child: iconWidget,
          )
        : iconWidget;
  }
}

/// Custom icon for inventory/materials
class InventoryIcon extends StatelessWidget {
  final Color backgroundColor;
  final double size;

  const InventoryIcon({Key? key, required this.backgroundColor, this.size = 50})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ResponsiveUtils kullanarak container boyutu
    final double responsiveSize = size == 50
        ? ResponsiveUtils.widgetSize(
            context,
            xs: 35,
            sm: 40,
            md: 45,
            lg: 50,
            xl: 55,
          )
        : size;

    return Container(
      width: responsiveSize,
      height: responsiveSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(responsiveSize * 0.24),
        boxShadow: [
          BoxShadow(
            color: ColorUtils.withAlpha(backgroundColor, 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.inventory_2,
            size: responsiveSize * 0.6,
            color: Colors.white,
          ),
          Positioned(
            top: responsiveSize * 0.2,
            right: responsiveSize * 0.2,
            child: Icon(
              Icons.add,
              size: responsiveSize * 0.3,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom icon for sales module
class SalesIcon extends StatelessWidget {
  final Color backgroundColor;
  final double size;

  const SalesIcon({Key? key, required this.backgroundColor, this.size = 50})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ResponsiveUtils kullanarak container boyutu
    final double responsiveSize = size == 50
        ? ResponsiveUtils.widgetSize(
            context,
            xs: 35,
            sm: 40,
            md: 45,
            lg: 50,
            xl: 55,
          )
        : size;

    return Container(
      width: responsiveSize,
      height: responsiveSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(responsiveSize * 0.24),
        boxShadow: [
          BoxShadow(
            color: ColorUtils.withAlpha(backgroundColor, 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.receipt, size: responsiveSize * 0.6, color: Colors.white),
          Positioned(
            bottom: responsiveSize * 0.15,
            right: responsiveSize * 0.15,
            child: Icon(
              Icons.attach_money,
              size: responsiveSize * 0.3,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom icon for cash register module
class CashRegisterIcon extends StatelessWidget {
  final Color backgroundColor;
  final double size;

  const CashRegisterIcon({
    Key? key,
    required this.backgroundColor,
    this.size = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ResponsiveUtils kullanarak container boyutu
    final double responsiveSize = size == 50
        ? ResponsiveUtils.widgetSize(
            context,
            xs: 35,
            sm: 40,
            md: 45,
            lg: 50,
            xl: 55,
          )
        : size;

    return Container(
      width: responsiveSize,
      height: responsiveSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(responsiveSize * 0.24),
        boxShadow: [
          BoxShadow(
            color: ColorUtils.withAlpha(backgroundColor, 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.account_balance,
            size: responsiveSize * 0.6,
            color: Colors.white,
          ),
          Positioned(
            bottom: responsiveSize * 0.15,
            right: responsiveSize * 0.15,
            child: Icon(
              Icons.trending_up,
              size: responsiveSize * 0.3,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
