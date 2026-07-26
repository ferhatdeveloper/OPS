// Dosya Adı: favorites_module_card_test.dart
// Açıklama: ModuleCardData favori alanları + FavoritesScreen route smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/core/constants/menu_constants.dart';
import 'package:exfin_ops/modules/field_sales/favorites/view/favorites_screen.dart';

void main() {
  test('ModuleCardData isFavorite ve id varsayılanları', () {
    const card = ModuleCardData(
      title: 'Cari',
      subtitle: '',
      icon: Icons.person,
    );
    expect(card.id, 0);
    expect(card.isFavorite, isFalse);

    const fav = ModuleCardData(
      id: 42,
      title: 'Döviz',
      subtitle: '',
      icon: Icons.currency_exchange,
      isFavorite: true,
    );
    expect(fav.id, 42);
    expect(fav.isFavorite, isTrue);
  });

  test('FavoritesScreen.routeName MBT path', () {
    expect(FavoritesScreen.routeName, '/field-sales/favorites');
  });
}
