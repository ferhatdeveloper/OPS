// Dosya Adı: admin_password_dialog.dart
// Açıklama: Admin paneline giriş için şifre doğrulama dialogu
// Oluşturulma Tarihi: 2024-03-22
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-22

import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';

/// {@template AdminPasswordDialog}
/// Admin paneline giriş için şifre doğrulama dialogu
///
/// Kullanım örneği:
/// ```dart
/// final result = await showAdminPasswordDialog(context);
/// if (result == true) { /* admin paneline geç */ }
/// ```
/// {@endtemplate}
Future<bool?> showAdminPasswordDialog(BuildContext context) async {
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;
  String? errorText;

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Admin Paneli Girişi'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Lütfen yönetici şifresini giriniz.'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        errorText: errorText,
                      ),
                      onSubmitted: (_) async {
                        setState(() => isLoading = true);
                        final result =
                            await _validatePassword(_controller.text);
                        setState(() => isLoading = false);
                        if (result) {
                          Navigator.of(context).pop(true);
                        } else {
                          setState(() => errorText = 'Hatalı şifre!');
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('İptal'),
                  ),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            setState(() {
                              isLoading = true;
                              errorText = null;
                            });
                            final result =
                                await _validatePassword(_controller.text);
                            setState(() => isLoading = false);
                            if (result) {
                              Navigator.of(context).pop(true);
                            } else {
                              setState(() => errorText = 'Hatalı şifre!');
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Giriş'),
                  ),
                ],
              );
            },
          );
        },
      ) ??
      false;
}

Future<bool> _validatePassword(String input) async {
  final supabase = await SupabaseService.getInstance();
  final superPass = await supabase.getSuperPass();
  return input == (superPass ?? '1');
}
