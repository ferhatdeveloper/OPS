import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view/widgets/tab_page.dart';

class DashboardState {
  final List<TabPage> tabs;
  final int currentTabIndex;
  final List<int> shortcutOrder;
  final bool isCustomizing;

  const DashboardState({
    this.tabs = const [],
    this.currentTabIndex = -1,
    this.shortcutOrder = const [],
    this.isCustomizing = false,
  });

  DashboardState copyWith({
    List<TabPage>? tabs,
    int? currentTabIndex,
    List<int>? shortcutOrder,
    bool? isCustomizing,
  }) {
    return DashboardState(
      tabs: tabs ?? this.tabs,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      shortcutOrder: shortcutOrder ?? this.shortcutOrder,
      isCustomizing: isCustomizing ?? this.isCustomizing,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(const DashboardState());

  void addTab(TabPage page) {
    // Check if tab already exists
    final existingIndex = state.tabs.indexWhere((tab) => tab.id == page.id);

    if (existingIndex >= 0) {
      // Tab exists, just switch to it
      state = state.copyWith(currentTabIndex: existingIndex);
    } else {
      // Add new tab and switch to it
      final newTabs = [...state.tabs, page];
      state = state.copyWith(
        tabs: newTabs,
        currentTabIndex: newTabs.length - 1,
      );
    }
  }

  void closeTab(int index) {
    if (index < 0 || index >= state.tabs.length) return;

    final newTabs = [...state.tabs];
    newTabs.removeAt(index);

    // Adjust current tab index if needed
    int newIndex = state.currentTabIndex;
    if (newTabs.isEmpty) {
      newIndex = -1;
    } else if (index == state.currentTabIndex) {
      newIndex = index > 0 ? index - 1 : 0;
    } else if (index < state.currentTabIndex) {
      newIndex = state.currentTabIndex - 1;
    }

    state = state.copyWith(tabs: newTabs, currentTabIndex: newIndex);
  }

  void switchToTab(int index) {
    if (index >= 0 && index < state.tabs.length) {
      state = state.copyWith(currentTabIndex: index);
    }
  }

  void reorderShortcuts(List<int> newOrder) {
    state = state.copyWith(shortcutOrder: newOrder);
  }

  void toggleCustomizeMode() {
    state = state.copyWith(isCustomizing: !state.isCustomizing);
  }

  void closeAllTabs() {
    // Close all tabs and reset current tab index
    state = state.copyWith(tabs: [], currentTabIndex: -1);
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      return DashboardNotifier();
    });
