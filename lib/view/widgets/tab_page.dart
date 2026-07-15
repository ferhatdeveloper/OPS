import 'package:flutter/material.dart';
import '../../service/language_service.dart';

class TabPage {
  final String title;
  final IconData icon;
  final Widget content;
  final bool closable;
  final String id;

  TabPage({
    required this.title,
    required this.icon,
    required this.content,
    this.closable = true,
    String? id,
  }) : this.id = id ?? title.toLowerCase().replaceAll(' ', '_');
}

class TabPageView extends StatelessWidget {
  final TabPage page;

  const TabPageView({Key? key, required this.page}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16), child: page.content);
  }
}

class EmptyTabContent extends StatelessWidget {
  final String title;

  const EmptyTabContent({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tab_unselected, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          TranslatedText(
            '$title içeriği yükleniyor...',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          SizedBox(height: 24),
          CircularProgressIndicator(),
        ],
      ),
    );
  }
}
