import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shortcut_icon.dart';
import '../../viewmodel/dashboard_provider.dart';
import '../../core/localization/app_localization.dart';

class ShortcutData {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  ShortcutData({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class ShortcutGrid extends ConsumerWidget {
  final List<ShortcutData> shortcuts;
  final int crossAxisCount;
  final double spacing;
  final VoidCallback? onFavoritesEdit;

  const ShortcutGrid({
    Key? key,
    required this.shortcuts,
    this.crossAxisCount = 4,
    this.spacing = 16.0,
    this.onFavoritesEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final dashboardNotifier = ref.read(dashboardProvider.notifier);

    // Default order if not set
    final order =
        dashboardState.shortcutOrder.isEmpty
            ? List.generate(shortcuts.length, (i) => i)
            : dashboardState.shortcutOrder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and customize button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalization.of(
                  context,
                ).translate('mobile_dashboard.modules'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Row(
                children: [
                  // Sık kullanılanları düzenleme butonu
                  if (onFavoritesEdit != null)
                    TextButton.icon(
                      icon: const Icon(Icons.star, size: 18),
                      label: const Text(
                        'Sık Kullanılanlar',
                        style: TextStyle(fontSize: 14),
                      ),
                      onPressed: onFavoritesEdit,
                    ),
                  const SizedBox(width: 8),
                  // Sıralama düzenleme butonu
                  TextButton.icon(
                    icon: Icon(
                      dashboardState.isCustomizing ? Icons.check : Icons.edit,
                      size: 18,
                    ),
                    label: Text(
                      dashboardState.isCustomizing
                          ? AppLocalization.of(
                            context,
                          ).translate('common.complete')
                          : AppLocalization.of(
                            context,
                          ).translate('common.edit'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    onPressed: () {
                      dashboardNotifier.toggleCustomizeMode();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Grid view with reorderable shortcuts
        Expanded(
          child:
              dashboardState.isCustomizing
                  ? ReorderableGridView.count(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    padding: EdgeInsets.all(spacing),
                    onReorder: (oldIndex, newIndex) {
                      // Update the order in the provider
                      final newOrder = List<int>.from(order);
                      final item = newOrder.removeAt(oldIndex);
                      newOrder.insert(newIndex, item);
                      dashboardNotifier.reorderShortcuts(newOrder);
                    },
                    children: [
                      for (int i = 0; i < shortcuts.length; i++)
                        KeyedSubtree(
                          key: ValueKey('shortcut_${order[i]}'),
                          child: ShortcutIcon(
                            title: shortcuts[order[i]].title,
                            icon: shortcuts[order[i]].icon,
                            backgroundColor: shortcuts[order[i]].color,
                            onTap: shortcuts[order[i]].onTap,
                            isDraggable: true,
                            order: i,
                          ),
                        ),
                    ],
                  )
                  : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                    ),
                    padding: EdgeInsets.all(spacing),
                    itemCount: shortcuts.length,
                    itemBuilder: (context, index) {
                      final orderIndex = order[index];
                      return ShortcutIcon(
                        title: shortcuts[orderIndex].title,
                        icon: shortcuts[orderIndex].icon,
                        backgroundColor: shortcuts[orderIndex].color,
                        onTap: shortcuts[orderIndex].onTap,
                        isDraggable: false,
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

// Custom ReorderableGridView implementation
class ReorderableGridView extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsets padding;
  final Function(int oldIndex, int newIndex) onReorder;

  const ReorderableGridView.count({
    Key? key,
    required this.children,
    required this.crossAxisCount,
    this.mainAxisSpacing = 10.0,
    this.crossAxisSpacing = 10.0,
    this.padding = EdgeInsets.zero,
    required this.onReorder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      buildDefaultDragHandles: false,
      onReorder: onReorder,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final double animValue = Curves.easeInOut.transform(
              animation.value,
            );
            final double scale = 0.95 + (animValue * 0.05);
            return Transform.scale(scale: scale, child: child);
          },
          child: child,
        );
      },
      children: [
        for (int i = 0; i < children.length; i++)
          ReorderableDragStartListener(
            index: i,
            key: ValueKey('reorderable_$i'),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate grid dimensions
                final itemWidth =
                    (constraints.maxWidth -
                        ((crossAxisCount - 1) * crossAxisSpacing)) /
                    crossAxisCount;
                final itemsPerRow = (constraints.maxWidth / itemWidth).floor();
                final itemsInPreviousRows = (i ~/ itemsPerRow) * itemsPerRow;
                final column = i - itemsInPreviousRows;

                return Padding(
                  padding: EdgeInsets.only(
                    left: column == 0 ? 0 : crossAxisSpacing,
                    top: i < itemsPerRow ? 0 : mainAxisSpacing,
                  ),
                  child: SizedBox(width: itemWidth, child: children[i]),
                );
              },
            ),
          ),
      ],
    );
  }
}
