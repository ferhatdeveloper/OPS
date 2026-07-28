// Dosya Adı: ai_openrouter_model_picker.dart
// Açıklama: OpenRouter dens model dropdown seçici
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/ai/openrouter_model_catalog.dart';
import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';

/// {@template ai_openrouter_model_picker}
/// OpenRouter model listesi — dens Dropdown; seçim [onSelected] ile akar.
/// {@endtemplate}
class AiOpenRouterModelPicker extends StatelessWidget {
  /// [models]: Yüklü modeller
  final List<OpenRouterModelInfo> models;

  /// [selectedId]: Mevcut model slug
  final String selectedId;

  /// [loading]: Liste yükleniyor
  final bool loading;

  /// [fromApi]: API’den mi geldi (hint için)
  final bool fromApi;

  /// [onSelected]: Model seçildi
  final ValueChanged<String> onSelected;

  /// [onRefresh]: Listeyi yenile
  final VoidCallback? onRefresh;

  /// {@macro ai_openrouter_model_picker}
  const AiOpenRouterModelPicker({
    Key? key,
    required this.models,
    required this.selectedId,
    required this.loading,
    required this.fromApi,
    required this.onSelected,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final ids = models.map((m) => m.id).toSet();
    final current = selectedId.trim();
    final valueInList = ids.contains(current) ? current : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.translate('ai.model_select'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onRefresh != null)
              SizedBox(
                height: 32,
                width: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  tooltip: l10n.translate('ai.model_list_refresh'),
                  onPressed: loading ? null : onRefresh,
                  icon: loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (loading && models.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l10n.translate('ai.model_list_loading'),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
          )
        else
          DropdownButtonFormField<String>(
            isDense: true,
            isExpanded: true,
            value: valueInList,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: const OutlineInputBorder(),
              hintText: l10n.translate('ai.model_select_hint'),
            ),
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            iconEnabledColor: FieldSalesDensAppBar.primaryColor,
            items: models
                .map(
                  (m) => DropdownMenuItem<String>(
                    value: m.id,
                    child: Text(
                      m.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                )
                .toList(),
            onChanged: loading
                ? null
                : (v) {
                    if (v != null && v.isNotEmpty) onSelected(v);
                  },
          ),
        if (!fromApi && !loading) ...[
          const SizedBox(height: 4),
          Text(
            l10n.translate('ai.model_list_fallback'),
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ],
    );
  }
}
