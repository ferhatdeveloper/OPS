// Dosya Adı: admin_panel_screen.dart
// Açıklama: Modern, kart tabanlı ve sekmeli admin paneli (AppBar, SideMenu, responsive, widget alanı)
// Oluşturulma Tarihi: 2024-03-22
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-06-09

import 'package:flutter/material.dart';
import 'menu_management.dart';
import 'company_management.dart';
import 'user_authorization.dart';
import 'sync_operations.dart';
import 'terminal_operations.dart';
import 'device_approval_screen.dart';

const Color exfinDarkBlue = Color.fromARGB(255, 5, 79, 153);
const Color surfaceColor = Color(0xFFF9FAFB);
const Color menuBackgroundColor = Color(0xFF4A6583);

/// {@template AdminPanelScreen}
/// Modern, kart tabanlı ve sekmeli admin paneli (AppBar, SideMenu, responsive, widget alanı)
///
/// Kullanım örneği:
/// ```dart
/// AdminPanelScreen()
/// ```
/// {@endtemplate}
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _selectedTab = 0;
  bool _isMenuExpanded = true;
  bool _isMenuVisible = true;

  static const List<String> _tabTitles = [
    'Menü Yönetimi',
    'Firma Yönetimi',
    'Kullanıcı İşlemleri',
    'Senkronizasyon',
    'Terminal',
    'Cihaz Onaylama',
  ];

  static const List<IconData> _tabIcons = [
    Icons.menu,
    Icons.business,
    Icons.supervisor_account,
    Icons.sync,
    Icons.terminal,
    Icons.device_unknown,
  ];

  static final List<Widget> _tabPages = [
    MenuManagement(),
    CompanyManagement(),
    UserAuthorization(),
    SyncOperations(),
    TerminalOperations(),
    DeviceApprovalScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1200;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: exfinDarkBlue,
        title: const Row(
          children: [
            Text(
              'EXFİN ERP',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(width: 5),
            Text(
              '| Admin Panel',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
        leadingWidth: 48,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              _isMenuVisible ? Icons.menu_open : Icons.menu,
              color: Colors.white,
            ),
            onPressed: () {
              if (isDesktop) {
                setState(() {
                  _isMenuVisible = !_isMenuVisible;
                  if (_isMenuVisible) {
                    _isMenuExpanded = true;
                  }
                });
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
            tooltip: _isMenuVisible ? 'Menüyü Gizle' : 'Menüyü Göster',
            padding: EdgeInsets.zero,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Çıkış Yap',
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Row(
        children: [
          if (_isMenuVisible && isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isMenuExpanded ? 220 : 70,
              color: menuBackgroundColor,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Icon(Icons.admin_panel_settings,
                      size: 40, color: Colors.white),
                  const SizedBox(height: 8),
                  if (_isMenuExpanded)
                    const Text('Admin',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _tabTitles.length,
                      itemBuilder: (context, i) {
                        final selected = _selectedTab == i;
                        return ListTile(
                          leading: Icon(_tabIcons[i],
                              color: selected ? Colors.white : Colors.white70),
                          title: _isMenuExpanded
                              ? Text(_tabTitles[i],
                                  style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.white70))
                              : null,
                          selected: selected,
                          selectedTileColor: Colors.white24,
                          onTap: () {
                            setState(() => _selectedTab = i);
                          },
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          minLeadingWidth: 32,
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                        _isMenuExpanded
                            ? Icons.chevron_left
                            : Icons.chevron_right,
                        color: Colors.white),
                    onPressed: () {
                      setState(() => _isMenuExpanded = !_isMenuExpanded);
                    },
                    tooltip:
                        _isMenuExpanded ? 'Menüyü Daralt' : 'Menüyü Genişlet',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          if (!_isMenuVisible || !isDesktop) const SizedBox.shrink(),
          Expanded(
            child: Container(
              color: surfaceColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sekme başlığı ve istatistik kartları
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Icon(_tabIcons[_selectedTab],
                            color: exfinDarkBlue, size: 28),
                        const SizedBox(width: 12),
                        Text(_tabTitles[_selectedTab],
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF222B45))),
                        const Spacer(),
                        if (isDesktop)
                          Row(
                            children: [
                              _buildStatCard('Kullanıcı', '5'),
                              const SizedBox(width: 12),
                              _buildStatCard('Yetki', '3'),
                              const SizedBox(width: 12),
                              _buildStatCard('Firma', '1'),
                              const SizedBox(width: 12),
                              _buildStatCard('Cihaz', '8'),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Sekme içeriği
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(24),
                      child: _tabPages[_selectedTab],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? Container(
              color: const Color(0xFF3A3A3A),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Spacer(),
                  const Expanded(
                    child: Text(
                      'Copyright © 2020 EXFİN YAZILIM | Admin Panel | 1.00.0',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            )
          : null,
      drawer: !isDesktop
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: exfinDarkBlue,
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.admin_panel_settings,
                            size: 40, color: Colors.white),
                        SizedBox(height: 8),
                        Text('Admin',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ],
                    ),
                  ),
                  ...List.generate(_tabTitles.length, (i) {
                    final selected = _selectedTab == i;
                    return ListTile(
                      leading: Icon(_tabIcons[i],
                          color: selected ? exfinDarkBlue : Colors.black54),
                      title: Text(_tabTitles[i],
                          style: TextStyle(
                              color:
                                  selected ? exfinDarkBlue : Colors.black87)),
                      selected: selected,
                      onTap: () {
                        setState(() {
                          _selectedTab = i;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            )
          : null,
    );
  }

  /// [baslik]: Kart başlığı, [deger]: Kart değeri
  Widget _buildStatCard(String baslik, String deger) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(baslik,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(deger,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
