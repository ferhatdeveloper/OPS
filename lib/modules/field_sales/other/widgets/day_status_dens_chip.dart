// Dosya Adı: day_status_dens_chip.dart
// Açıklama: Dashboard mesai açık/kapalı dens durum chip’i (DayStatusStore)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../core/utils/color_utils.dart';
import '../view/day_status_screen.dart';
import '../viewmodel/day_status_store.dart';

/// {@template day_status_dens_chip}
/// Dashboard’da mesai açık/kapalı dens chip.
/// [DayStatusStore.isDayOpen] okur; tıklanınca gün durumu ekranına gider.
///
/// Kullanım örneği:
/// ```dart
/// const DayStatusDensChip()
/// ```
/// {@endtemplate}
class DayStatusDensChip extends StatefulWidget {
  /// [store]: Test/enjeksiyon için isteğe bağlı store
  final DayStatusStore store;

  /// {@macro day_status_dens_chip}
  const DayStatusDensChip({
    Key? key,
    this.store = const DayStatusStore(),
  }) : super(key: key);

  /// {@template day_status_dens_chip_label_key}
  /// Mesai durumuna göre l10n anahtarı.
  ///
  /// Parametreler:
  /// - [isDayOpen]: Mesai açık mı
  ///
  /// Dönüş değeri:
  /// - [String]: `field_sales.day_status_open` veya `_closed`
  /// {@endtemplate}
  static String labelKey(bool isDayOpen) {
    return isDayOpen
        ? 'field_sales.day_status_open'
        : 'field_sales.day_status_closed';
  }

  @override
  State<DayStatusDensChip> createState() => _DayStatusDensChipState();
}

class _DayStatusDensChipState extends State<DayStatusDensChip> {
  /// [_isDayOpen]: null = yükleniyor
  bool? _isDayOpen;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// {@template day_status_dens_chip_reload}
  /// DayStatusStore’dan mesai durumunu yeniler.
  /// {@endtemplate}
  Future<void> _reload() async {
    final open = await widget.store.isDayOpen();
    if (!mounted) return;
    setState(() => _isDayOpen = open);
  }

  /// {@template day_status_dens_chip_open_screen}
  /// Gün durumu ekranına gider; dönüşte chip’i yeniler.
  /// {@endtemplate}
  Future<void> _openDayStatus() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const DayStatusScreen(),
      ),
    );
    if (!mounted) return;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDayOpen == null) {
      return const SizedBox.shrink();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalization.of(context);
    final label = l10n.translate(DayStatusDensChip.labelKey(_isDayOpen!));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openDayStatus,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: isDarkMode
                ? ColorUtils.withAlpha(colorScheme.surface, 0.5)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}
