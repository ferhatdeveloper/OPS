import 'package:flutter/material.dart';
import '../../view/widgets/tab_page.dart';

/// Bu sınıf, dashboard'dan açılan modül sekmelerinin içerik yönetimi için kullanılır.
class ModuleContentBuilder {
  /// Modül adına göre uygun içerik bileşeni döndürür
  static Widget buildModuleContent(String moduleName, IconData moduleIcon) {
    switch (moduleName) {
      // Diğer modüller buraya eklenecek
      // case 'Satış & Dağıtım':
      //   return const SalesMainScreen();

      default:
        // Henüz uygulanmamış modüller için boş içerik
        return EmptyTabContent(title: moduleName);
    }
  }

  /// Modül adına göre uygun TabPage nesnesi oluşturur
  static TabPage createModuleTab(String moduleName, IconData moduleIcon) {
    return TabPage(
      title: moduleName,
      icon: moduleIcon,
      content: buildModuleContent(moduleName, moduleIcon),
    );
  }
}
