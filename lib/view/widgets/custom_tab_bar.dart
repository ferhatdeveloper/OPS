import 'package:flutter/material.dart';
import 'tab_page.dart';
import '../../core/utils/color_utils.dart';

class CustomTabBar extends StatelessWidget {
  final List<TabPage> tabs;
  final int currentIndex;
  final Function(int) onTabSelected;
  final Function(int) onTabClosed;

  const CustomTabBar({
    Key? key,
    required this.tabs,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onTabClosed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: ColorUtils.withAlpha(Colors.black, 0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child:
          tabs.isEmpty
              ? Center(
                child: Text(
                  'Açık sayfa bulunmamaktadır',
                  style: TextStyle(color: Colors.grey),
                ),
              )
              : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                itemBuilder: (context, index) {
                  final isActive = index == currentIndex;
                  return _TabItem(
                    title: tabs[index].title,
                    icon: tabs[index].icon,
                    isActive: isActive,
                    closable: tabs[index].closable,
                    onTap: () => onTabSelected(index),
                    onClose: () => onTabClosed(index),
                  );
                },
              ),
    );
  }
}

class _TabItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final bool closable;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabItem({
    Key? key,
    required this.title,
    required this.icon,
    required this.isActive,
    required this.closable,
    required this.onTap,
    required this.onClose,
  }) : super(key: key);

  @override
  _TabItemState createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color:
                widget.isActive
                    ? Colors.white
                    : ColorUtils.withAlpha(Colors.grey, 0.1),
            border: Border(
              bottom: BorderSide(
                color:
                    widget.isActive ? theme.primaryColor : Colors.transparent,
                width: 2,
              ),
              right: BorderSide(
                color: ColorUtils.withAlpha(Colors.grey, 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isActive ? theme.primaryColor : Colors.grey,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w400,
                    color:
                        widget.isActive
                            ? theme.primaryColor
                            : Colors.grey.shade700,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (widget.closable) ...[
                const SizedBox(width: 8),
                if (widget.isActive || _isHovered)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        widget.onClose();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color:
                              _isHovered
                                  ? ColorUtils.withAlpha(Colors.grey, 0.2)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: _isHovered ? Colors.black54 : Colors.grey,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
