import 'package:flutter/material.dart';
import '../../view/widgets/navigation_tree.dart';
import '../../core/utils/color_utils.dart';

class ModuleScreenLayout extends StatefulWidget {
  final String moduleTitle;
  final Widget? filterBar;
  final Widget? contentHeader;
  final Widget mainContent;
  final List<NavigationTreeItem> navigationItems;
  final bool showNavigationBar;
  final bool showFilterBar;

  const ModuleScreenLayout({
    Key? key,
    required this.moduleTitle,
    this.filterBar,
    this.contentHeader,
    required this.mainContent,
    required this.navigationItems,
    this.showNavigationBar = true,
    this.showFilterBar = true,
  }) : super(key: key);

  @override
  ModuleScreenLayoutState createState() => ModuleScreenLayoutState();
}

class ModuleScreenLayoutState extends State<ModuleScreenLayout> {
  bool isNavigationCollapsed = false;
  NavigationTreeItem? selectedItem;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 900;

    return Scaffold(
      body: Column(
        children: [
          // Module Header - Logo stilinde mavi başlık çubuğu
          Container(
            height: 40,
            color: const Color(0xFF054F99),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  widget.moduleTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                // Toolbar butonları - Logo stilinde
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  tooltip: 'Yeni',
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                  tooltip: 'Düzenle',
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                  tooltip: 'Sil',
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Yenile',
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                VerticalDivider(color: ColorUtils.withAlpha(Colors.white, 0.3), width: 1),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.print, color: Colors.white, size: 20),
                  tooltip: 'Yazdır',
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Dışa Aktar',
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Filter Bar - Logo stilinde gri filtreleme çubuğu
          if (widget.showFilterBar && widget.filterBar != null)
            Container(
              height: 50,
              color: const Color(0xFFF0F0F0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: widget.filterBar!,
            ),

          // Content & Navigation
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Navigation tree - Logo stilinde sol ağaç menüsü
                if (widget.showNavigationBar && !isSmallScreen)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isNavigationCollapsed ? 50 : 220,
                    child:
                        isNavigationCollapsed
                            ? _buildCollapsedNavigation()
                            : NavigationTree(
                              title: 'Gezinti',
                              items: widget.navigationItems,
                              onItemSelected: (item) {
                                setState(() {
                                  selectedItem = item;
                                });
                              },
                            ),
                  ),

                // Collapse/expand button
                if (widget.showNavigationBar && !isSmallScreen)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isNavigationCollapsed = !isNavigationCollapsed;
                      });
                    },
                    child: Container(
                      width: 20,
                      color: const Color(0xFFE0E0E0),
                      child: Center(
                        child: Icon(
                          isNavigationCollapsed
                              ? Icons.chevron_right
                              : Icons.chevron_left,
                          size: 20,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),

                // Main content area
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Optional content header - Logo stilinde başlık
                        if (widget.contentHeader != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: const Color(0xFFE5E5E5),
                            child: widget.contentHeader!,
                          ),

                        // Main content - Tablo/grid
                        Expanded(child: widget.mainContent),

                        // Status bar - Logo stilinde
                        Container(
                          height: 24,
                          color: const Color(0xFFE5E5E5),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const Text(
                                'Toplam',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: const Text(
                                  '0',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'kayıt',
                                style: TextStyle(fontSize: 12),
                              ),
                              const Spacer(),
                              const Text(
                                'Hazır',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedNavigation() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF054F99),
            height: 42,
            width: double.infinity,
            child: const Center(
              child: Icon(Icons.account_tree, color: Colors.white, size: 18),
            ),
          ),
          // Icons only
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: widget.navigationItems.length,
              itemBuilder: (context, index) {
                final item = widget.navigationItems[index];
                return Tooltip(
                  message: item.title,
                  child: InkWell(
                    onTap: item.onTap,
                    child: Container(
                      height: 42,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Icon(
                        item.icon,
                        size: 18,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
