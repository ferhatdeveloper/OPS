import 'package:flutter/material.dart';
import '../../core/utils/color_utils.dart';

class NavigationTreeItem {
  final String title;
  final IconData icon;
  final List<NavigationTreeItem>? children;
  final VoidCallback? onTap;

  NavigationTreeItem({
    required this.title,
    required this.icon,
    this.children,
    this.onTap,
  });
}

class NavigationTree extends StatefulWidget {
  final List<NavigationTreeItem> items;
  final Function(NavigationTreeItem) onItemSelected;
  final String title;
  final Color backgroundColor;
  final Color selectedColor;
  final Color textColor;

  const NavigationTree({
    Key? key,
    required this.items,
    required this.onItemSelected,
    required this.title,
    this.backgroundColor = const Color(0xFFF0F0F0),
    this.selectedColor = const Color(0xFF0066CC),
    this.textColor = const Color(0xFF333333),
  }) : super(key: key);

  @override
  NavigationTreeState createState() => NavigationTreeState();
}

class NavigationTreeState extends State<NavigationTree> {
  int? expandedIndex;
  int? selectedIndex;
  int? selectedChildIndex;
  NavigationTreeItem? selectedItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tree header
          Container(
            color: const Color(0xFF054F99), // ExfinDarkBlue
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.account_tree, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Tree body
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final hasChildren =
                    item.children != null && item.children!.isNotEmpty;
                final isExpanded = expandedIndex == index;
                final isSelected =
                    selectedIndex == index && selectedChildIndex == null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Parent item
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (hasChildren) {
                            expandedIndex = isExpanded ? null : index;
                            selectedIndex = index;
                            selectedChildIndex = null;
                          } else {
                            selectedIndex = index;
                            selectedChildIndex = null;
                            selectedItem = item;
                            widget.onItemSelected(item);
                          }
                        });
                        if (item.onTap != null) {
                          item.onTap!();
                        }
                      },
                      child: Container(
                        color:
                            isSelected
                                ? ColorUtils.withAlpha(widget.selectedColor, 0.1)
                                : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            if (hasChildren)
                              Icon(
                                isExpanded
                                    ? Icons.arrow_drop_down
                                    : Icons.arrow_right,
                                size: 18,
                                color: widget.textColor,
                              )
                            else
                              const SizedBox(width: 18),
                            Icon(
                              item.icon,
                              size: 16,
                              color:
                                  isSelected
                                      ? widget.selectedColor
                                      : widget.textColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      isSelected
                                          ? widget.selectedColor
                                          : widget.textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Children items
                    if (isExpanded && hasChildren)
                      ...List.generate(item.children!.length, (childIndex) {
                        final childItem = item.children![childIndex];
                        final isChildSelected =
                            selectedIndex == index &&
                            selectedChildIndex == childIndex;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                              selectedChildIndex = childIndex;
                              selectedItem = childItem;
                              widget.onItemSelected(childItem);
                            });
                            if (childItem.onTap != null) {
                              childItem.onTap!();
                            }
                          },
                          child: Container(
                            color:
                                isChildSelected
                                    ? ColorUtils.withAlpha(widget.selectedColor, 0.1)
                                    : null,
                            padding: const EdgeInsets.only(
                              left: 40,
                              right: 16,
                              top: 10,
                              bottom: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  childItem.icon,
                                  size: 14,
                                  color:
                                      isChildSelected
                                          ? widget.selectedColor
                                          : widget.textColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    childItem.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          isChildSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color:
                                          isChildSelected
                                              ? widget.selectedColor
                                              : widget.textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
