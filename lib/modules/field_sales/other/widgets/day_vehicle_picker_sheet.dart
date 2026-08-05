// Dosya Adı: day_vehicle_picker_sheet.dart
// Açıklama: Güne başlama dens kayıtlı araç seçici (arama + liste)
// Oluşturulma Tarihi: 2026-08-04
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-04

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_theme.dart';
import '../../vehicles/model/vehicle_model.dart';
import '../../vehicles/viewmodel/vehicle_card_store.dart';

/// {@template show_day_vehicle_picker}
/// Kayıtlı araç seçici bottom sheet.
///
/// Parametreler:
/// - [context]: BuildContext
/// - [store]: Test enjeksiyonu (opsiyonel)
/// - [loadVehicles]: Liste yükleyici override
///
/// Dönüş değeri:
/// - [VehicleModel?]: Seçilen araç veya null
/// {@endtemplate}
Future<VehicleModel?> showDayVehiclePicker(
  BuildContext context, {
  VehicleCardStore? store,
  Future<List<VehicleModel>> Function()? loadVehicles,
}) {
  return showModalBottomSheet<VehicleModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: FieldSalesDensTheme.bodyBackground(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      return FractionallySizedBox(
        heightFactor: 0.72,
        child: DayVehiclePickerSheet(
          store: store ?? VehicleCardStore(),
          loadVehicles: loadVehicles,
        ),
      );
    },
  );
}

/// {@template day_vehicle_picker_sheet}
/// Arama + dens araç listesi; dokununca plaka seçilir.
/// {@endtemplate}
class DayVehiclePickerSheet extends StatefulWidget {
  /// [store]: Araç kart depoları
  final VehicleCardStore store;

  /// [loadVehicles]: Test inject
  final Future<List<VehicleModel>> Function()? loadVehicles;

  /// {@macro day_vehicle_picker_sheet}
  const DayVehiclePickerSheet({
    Key? key,
    required this.store,
    this.loadVehicles,
  }) : super(key: key);

  @override
  State<DayVehiclePickerSheet> createState() => _DayVehiclePickerSheetState();
}

class _DayVehiclePickerSheetState extends State<DayVehiclePickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  List<VehicleModel> _all = const [];
  List<VehicleModel> _filtered = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilter);
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loader = widget.loadVehicles ?? widget.store.listActive;
      final vehicles = await loader();
      if (!mounted) return;
      setState(() {
        _all = vehicles;
        _filtered = vehicles;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = filterVehiclesByQuery(_all, _searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final primary = const Color(0xFF375A7F);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(
            color: primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.translate('field_sales.day_vehicle_select_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 13),
            textInputAction: TextInputAction.search,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.translate('field_sales.day_vehicle_search_hint'),
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              filled: true,
              fillColor: FieldSalesDensTheme.surface(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ),
        Expanded(child: _buildBody(l10n)),
      ],
    );
  }

  Widget _buildBody(AppLocalization l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          l10n.translate('field_sales.day_vehicle_empty'),
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final v = _filtered[index];
        final subtitle = (v.name ?? '').trim();
        return Material(
          color: FieldSalesDensTheme.surface(context),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.of(context).pop(v),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 20,
                    color: FieldSalesDensTheme.muted(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.plate,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: FieldSalesDensTheme.title(context),
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: FieldSalesDensTheme.muted(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
