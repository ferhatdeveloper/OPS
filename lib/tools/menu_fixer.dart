import '../core/services/supabase_service.dart';
import 'package:sqflite/sqflite.dart';
import '../service/storage_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';

/// Eksik menüleri veritabanına eklemek ve güncellemek için araç
class MenuFixer {
  static Future<void> fixMenus(BuildContext context) async {
    try {
      final storage = await StorageService.getInstance();
      if (!await storage.hasSQLiteSupport()) return;
      final db = await storage.getDatabase();

      // Local menu tablosu boşsa Supabase'den çek
      final localMenus = await db.query('menu');
      if (localMenus.isEmpty) {
        final supabase = await SupabaseService.getInstance();
        final supabaseMenus = await supabase.query('menu');
        if (supabaseMenus.isNotEmpty) {
          final batch = db.batch();
          for (final menu in supabaseMenus) {
            batch.insert('menu', menu,
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
          await batch.commit(noResult: true);
          print('Supabase menüleri local veritabanına aktarıldı.');
        }
        return;
      }

      // Localde veri varsa: değişenleri güncelle, yeni eklenenleri ekle
      final supabase = await SupabaseService.getInstance();
      final supabaseMenus = await supabase.query('menu');
      for (final remoteMenu in supabaseMenus) {
        final local = await db
            .query('menu', where: 'uuid = ?', whereArgs: [remoteMenu['uuid']]);
        if (local.isEmpty) {
          // Yeni eklenen
          await db.insert('menu', remoteMenu);
        } else {
          // Güncellenen var mı kontrol et
          final localUpdated = local.first['updated_at'];
          final remoteUpdated = remoteMenu['updated_at'];
          if (remoteUpdated != null &&
              localUpdated != null &&
              remoteUpdated != localUpdated) {
            await db.update('menu', remoteMenu,
                where: 'uuid = ?', whereArgs: [remoteMenu['uuid']]);
          }
        }
      }
      print('Supabase menüleri ile local menü güncellendi.');
    } on SocketException catch (_) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Bağlantı Hatası'),
          content: const Text(
              'Sunucuya ulaşılamadı. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                fixMenus(context); // Tekrar dene
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Diğer hatalar için mevcut hata yönetimi
      print('Menü güncellenirken hata: $e');
    }
  }
}
