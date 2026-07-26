// Dosya Adı: favorites_screen.dart
// Açıklama: Favoriler ekranı — yalnızca kalp ile işaretlenen menü öğeleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/constants/menu_constants.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../service/database_service.dart';
import '../../../../service/menu_service.dart';

/// MBT dolu kalp rengi (RGB ≈ 247,170,35)
const Color _kFavoriteHeartColor = Color(0xFFF7AA23);

/// {@template favorites_screen}
/// Favoriler için dens ekran (MBT FAVORİLER sheet/kısayol).
/// Route: `/field-sales/favorites`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, FavoritesScreen.routeName);
/// ```
/// {@endtemplate}
class FavoritesScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/favorites`
  static const String routeName = '/field-sales/favorites';

  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<FavoriteItemData>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = MenuService.getMobileFavoriteItems();
  }

  /// {@template _reload}
  /// Favori listesini önbellekten temizleyip yeniden yükler.
  /// {@endtemplate}
  void _reload() {
    setState(() {
      _favoritesFuture = MenuService.getMobileFavoriteItems();
    });
  }

  /// {@template _removeFavorite}
  /// Favoriden çıkarır ve listeyi yeniler.
  ///
  /// Parametreler:
  /// - [title]: Menü başlığı
  /// {@endtemplate}
  Future<void> _removeFavorite(String title) async {
    try {
      final db = await DatabaseService.getInstance();
      final items = await db.getMenuItemByTitle(title);
      if (items.isEmpty) return;
      final id = items.first['id'] as int;
      await MenuService.toggleFavoriteMenuItem(id, false);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalization.of(context).translate(
              'mobile_dashboard.favorites_removed',
              args: {'title': title},
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      // sessiz — UI yenilenmez
    }
  }

  /// {@template _openFavorite}
  /// Favori öğesini route veya title ile açar.
  ///
  /// Parametreler:
  /// - [item]: Favori satırı
  /// {@endtemplate}
  Future<void> _openFavorite(FavoriteItemData item) async {
    final route = item.route.trim();
    if (route.isNotEmpty) {
      Navigator.pushNamed(context, route);
      return;
    }
    // Ana menü favorisi: ilk alt menü route'unu dene
    try {
      final subs = await MenuService.getSubMenuItems(item.title);
      if (subs.isNotEmpty && subs.first.route.trim().isNotEmpty) {
        if (!mounted) return;
        Navigator.pushNamed(context, subs.first.route);
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalization.of(context).translate(
            'mobile_dashboard.module_under_development',
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _labelFor(BuildContext context, String title) {
    final dashKey =
        'dashboard.${title.toLowerCase().replaceAll(' ', '_')}';
    var label = AppLocalization.of(context).translate(dashKey);
    if (label == dashKey) {
      final subKey =
          'submodules.${title.toLowerCase().replaceAll(' ', '_')}';
      label = AppLocalization.of(context).translate(subKey);
      if (label == subKey) label = title;
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('mobile_dashboard.favorites');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<FavoriteItemData>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? <FavoriteItemData>[];
          if (items.isEmpty) {
            return Center(
              child: Text(
                l10n.translate('mobile_dashboard.no_favorites'),
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.90,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final baseColor = ColorUtils.getColorForIcon(item.icon);
              final label = _labelFor(context, item.title);
              return InkWell(
                onTap: () => _openFavorite(item),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? ColorUtils.withAlpha(baseColor, 0.15)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ColorUtils.withAlpha(baseColor, 0.45),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, color: baseColor, size: 22),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _removeFavorite(item.title),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.favorite,
                              size: 14,
                              color: _kFavoriteHeartColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
