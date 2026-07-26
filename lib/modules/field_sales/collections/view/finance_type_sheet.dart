// Dosya Adı: finance_type_sheet.dart
// Açıklama: MBT Finans Yeni Hareket — 7 tip dens bottom sheet
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/finance_movement_type.dart';

/// {@template show_finance_type_sheet}
/// 7 tip (nakit/KK/çek/senet tahsilat + nakit/KK ödeme + virman) sheet.
///
/// Kullanım örneği:
/// ```dart
/// final t = await showFinanceTypeSheet(context);
/// ```
/// {@endtemplate}
Future<FinanceMovementType?> showFinanceTypeSheet(BuildContext context) {
  final l10n = AppLocalization.of(context);
  return showModalBottomSheet<FinanceMovementType>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.translate('field_sales.finance_type_select_title'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.translate('field_sales.finance_type_group_in'),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              ...FinanceMovementType.collectionTypes.map(
                (t) => _FinanceTypeTile(
                  type: t,
                  icon: _iconFor(t),
                  color: const Color(0xFF00A8E8),
                  onTap: () => Navigator.pop(ctx, t),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.translate('field_sales.finance_type_group_out'),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              ...FinanceMovementType.paymentTypes.map(
                (t) => _FinanceTypeTile(
                  type: t,
                  icon: _iconFor(t),
                  color: const Color(0xFF375A7F),
                  onTap: () => Navigator.pop(ctx, t),
                ),
              ),
              _FinanceTypeTile(
                type: FinanceMovementType.virman,
                icon: _iconFor(FinanceMovementType.virman),
                color: const Color(0xFF2C3E50),
                onTap: () => Navigator.pop(ctx, FinanceMovementType.virman),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// {@template finance_type_icon}
/// Tip ikonu (dens sheet).
/// {@endtemplate}
IconData _iconFor(FinanceMovementType type) {
  switch (type) {
    case FinanceMovementType.cashCollection:
    case FinanceMovementType.cashOut:
      return Icons.money;
    case FinanceMovementType.creditCardCollection:
    case FinanceMovementType.creditCardOut:
      return Icons.credit_card;
    case FinanceMovementType.checkCollection:
      return Icons.description_outlined;
    case FinanceMovementType.noteCollection:
      return Icons.note_alt_outlined;
    case FinanceMovementType.virman:
      return Icons.swap_horiz;
  }
}

/// {@template finance_type_tile}
/// Tek dens ListTile satırı.
/// {@endtemplate}
class _FinanceTypeTile extends StatelessWidget {
  /// [type]: Hareket tipi
  final FinanceMovementType type;

  /// [icon]: Sol ikon
  final IconData icon;

  /// [color]: İkon rengi
  final Color color;

  /// [onTap]: Seçim
  final VoidCallback onTap;

  const _FinanceTypeTile({
    required this.type,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        l10n.translate(type.titleL10nKey),
        style: const TextStyle(fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}

/// {@template finance_type_dens_selector}
/// Tahsilat 4 tip dens seçici (collection_entry üstü).
/// {@endtemplate}
class FinanceCollectionTypeDensSelector extends StatelessWidget {
  /// [value]: Seçili tip
  final FinanceMovementType value;

  /// [onChanged]: Tip değişince
  final ValueChanged<FinanceMovementType> onChanged;

  /// [enabled]: Değiştirilebilir mi
  final bool enabled;

  const FinanceCollectionTypeDensSelector({
    Key? key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final types = FinanceMovementType.collectionTypes;

    return Row(
      children: types.map((type) {
        final isSelected = value == type;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: enabled ? () => onChanged(type) : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00A8E8)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00A8E8)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _iconFor(type),
                      color: isSelected ? Colors.white : Colors.grey.shade500,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.translate(type.titleL10nKey),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.grey.shade700,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
