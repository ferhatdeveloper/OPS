// Dosya Adı: stock_slip_dens_form.dart
// Açıklama: MBT stok fişi dens form iskeleti (İşyeri·Fabrika·Ambar · Kaynak→Hedef)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template stock_slip_line_placeholder}
/// Dens satır iskeleti için yer tutucu kalem.
/// {@endtemplate}
class StockSlipLinePlaceholder {
  /// [code]: Ürün kodu (görünen)
  final String code;

  /// [name]: Ürün adı
  final String name;

  /// [qty]: Miktar metni
  final String qty;

  /// [productId]: Katalog ürün id (Kaydet / stok için; yoksa [code])
  final String? productId;

  /// [unit]: Birim (varsayılan Adet)
  final String? unit;

  const StockSlipLinePlaceholder({
    required this.code,
    required this.name,
    required this.qty,
    this.productId,
    this.unit,
  });
}

/// {@template stock_slip_location}
/// MBT İşyeri · Fabrika · Ambar seçim değerleri.
/// {@endtemplate}
class StockSlipLocation {
  /// [workplace]: İşyeri
  final String? workplace;

  /// [factory]: Fabrika
  final String? factory;

  /// [warehouse]: Ambar
  final String? warehouse;

  const StockSlipLocation({
    this.workplace,
    this.factory,
    this.warehouse,
  });

  /// {@template stock_slip_location_copy_with}
  /// Seçili alanları günceller.
  /// {@endtemplate}
  StockSlipLocation copyWith({
    String? workplace,
    String? factory,
    String? warehouse,
  }) {
    return StockSlipLocation(
      workplace: workplace ?? this.workplace,
      factory: factory ?? this.factory,
      warehouse: warehouse ?? this.warehouse,
    );
  }
}

/// {@template stock_slip_dens_form}
/// Stok fişi dens iskeleti: depo/konum, tarih ve satır listesi.
///
/// Kullanım örneği:
/// ```dart
/// StockSlipDensForm(
///   warehouse: 'Merkez Depo',
///   warehouses: const ['Merkez Depo'],
///   date: DateTime.now(),
///   onWarehouseChanged: (_) {},
///   onDateTap: () {},
///   lines: const [],
/// )
/// ```
/// {@endtemplate}
class StockSlipDensForm extends StatelessWidget {
  /// [warehouse]: Seçili depo (eski tek-ambar modu)
  final String? warehouse;

  /// [warehouses]: Depo / ambar seçenekleri
  final List<String> warehouses;

  /// [date]: Fiş tarihi
  final DateTime date;

  /// [onWarehouseChanged]: Depo değişince (eski mod)
  final ValueChanged<String?>? onWarehouseChanged;

  /// [onDateTap]: Tarih seçici aç
  final VoidCallback onDateTap;

  /// [lines]: Görünür satır iskeleti (boş olabilir)
  final List<StockSlipLinePlaceholder> lines;

  /// [onAddLine]: Satır ekle (iskelet — opsiyonel)
  final VoidCallback? onAddLine;

  /// [secondWarehouse]: Hedef depo (eski transfer modu)
  final String? secondWarehouse;

  /// [secondWarehouseLabelKey]: Hedef depo etiketi
  final String? secondWarehouseLabelKey;

  /// [onSecondWarehouseChanged]: Hedef depo değişince
  final ValueChanged<String?>? onSecondWarehouseChanged;

  /// [workplaces]: İşyeri seçenekleri
  final List<String> workplaces;

  /// [factories]: Fabrika seçenekleri
  final List<String> factories;

  /// [location]: Tek konum (Sayım / Üretim — İşyeri·Fabrika·Ambar)
  final StockSlipLocation? location;

  /// [onLocationChanged]: Tek konum değişince
  final ValueChanged<StockSlipLocation>? onLocationChanged;

  /// [sourceLocation]: Ambar fişi KAYNAK
  final StockSlipLocation? sourceLocation;

  /// [onSourceLocationChanged]: Kaynak değişince
  final ValueChanged<StockSlipLocation>? onSourceLocationChanged;

  /// [targetLocation]: Ambar fişi HEDEF
  final StockSlipLocation? targetLocation;

  /// [onTargetLocationChanged]: Hedef değişince
  final ValueChanged<StockSlipLocation>? onTargetLocationChanged;

  const StockSlipDensForm({
    Key? key,
    this.warehouse,
    required this.warehouses,
    required this.date,
    this.onWarehouseChanged,
    required this.onDateTap,
    required this.lines,
    this.onAddLine,
    this.secondWarehouse,
    this.secondWarehouseLabelKey,
    this.onSecondWarehouseChanged,
    this.workplaces = const [],
    this.factories = const [],
    this.location,
    this.onLocationChanged,
    this.sourceLocation,
    this.onSourceLocationChanged,
    this.targetLocation,
    this.onTargetLocationChanged,
  }) : super(key: key);

  bool get _useSourceTarget =>
      onSourceLocationChanged != null && onTargetLocationChanged != null;

  bool get _useLocationTriplet =>
      !_useSourceTarget && onLocationChanged != null;

  InputDecoration _denseDecoration(BuildContext context, String? label) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      filled: true,
      fillColor: FieldSalesDensTheme.surface(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _locationDropdowns({
    required BuildContext context,
    required AppLocalization l10n,
    required StockSlipLocation value,
    required ValueChanged<StockSlipLocation> onChanged,
  }) {
    final wp = workplaces.isNotEmpty
        ? workplaces
        : [
            l10n.translate('field_sales.stock_slip.workplace_sample'),
          ];
    final fac = factories.isNotEmpty
        ? factories
        : [
            l10n.translate('field_sales.stock_slip.factory_sample'),
          ];
    final wh = warehouses.isNotEmpty
        ? warehouses
        : [
            l10n.translate('field_sales.stock_slip.warehouse_center'),
          ];

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: value.workplace ?? wp.first,
          isDense: true,
          decoration: _denseDecoration(context, 
            l10n.translate('field_sales.stock_slip.workplace'),
          ),
          items: wp
              .map(
                (w) => DropdownMenuItem(
                  value: w,
                  child: Text(w, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: (v) => onChanged(value.copyWith(workplace: v)),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.factory ?? fac.first,
          isDense: true,
          decoration: _denseDecoration(context, 
            l10n.translate('field_sales.stock_slip.factory'),
          ),
          items: fac
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text(f, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: (v) => onChanged(value.copyWith(factory: v)),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.warehouse ?? wh.first,
          isDense: true,
          decoration: _denseDecoration(context, 
            l10n.translate('field_sales.stock_slip.ambar'),
          ),
          items: wh
              .map(
                (w) => DropdownMenuItem(
                  value: w,
                  child: Text(w, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: (v) => onChanged(value.copyWith(warehouse: v)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final dateText = DateFormat('dd.MM.yyyy').format(date);
    final showSecond = onSecondWarehouseChanged != null && !_useSourceTarget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FieldSalesDensTheme.surface(context),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(
            children: [
              if (_useSourceTarget) ...[
                _sectionTitle(
                  l10n.translate('field_sales.stock_slip.source'),
                ),
                _locationDropdowns(
                  context: context,
                  l10n: l10n,
                  value: sourceLocation ?? const StockSlipLocation(),
                  onChanged: onSourceLocationChanged!,
                ),
                const SizedBox(height: 12),
                _sectionTitle(
                  l10n.translate('field_sales.stock_slip.target'),
                ),
                _locationDropdowns(
                  context: context,
                  l10n: l10n,
                  value: targetLocation ?? const StockSlipLocation(),
                  onChanged: onTargetLocationChanged!,
                ),
              ] else if (_useLocationTriplet) ...[
                _locationDropdowns(
                  context: context,
                  l10n: l10n,
                  value: location ?? const StockSlipLocation(),
                  onChanged: onLocationChanged!,
                ),
              ] else ...[
                DropdownButtonFormField<String>(
                  value: warehouse,
                  isDense: true,
                  decoration: _denseDecoration(context, 
                    l10n.translate('field_sales.stock_slip.warehouse'),
                  ),
                  items: warehouses
                      .map(
                        (w) => DropdownMenuItem(
                          value: w,
                          child: Text(w, style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
                  onChanged: onWarehouseChanged,
                ),
                if (showSecond) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: secondWarehouse,
                    isDense: true,
                    decoration: _denseDecoration(context, 
                      l10n.translate(
                        secondWarehouseLabelKey ??
                            'field_sales.stock_slip.target_warehouse',
                      ),
                    ),
                    items: warehouses
                        .map(
                          (w) => DropdownMenuItem(
                            value: w,
                            child: Text(
                              w,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onSecondWarehouseChanged,
                  ),
                ],
              ],
              const SizedBox(height: 8),
              InkWell(
                onTap: onDateTap,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: _denseDecoration(context, 
                    l10n.translate('field_sales.stock_slip.date'),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          dateText,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.translate('field_sales.stock_slip.lines'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAddLine,
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  l10n.translate('field_sales.stock_slip.add_line'),
                  style: const TextStyle(fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00A8E8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: lines.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate('field_sales.stock_slip.lines_empty'),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: lines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: FieldSalesDensTheme.surface(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${l10n.translate('field_sales.stock_slip.code')}: ${line.code}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            line.qty,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            l10n.translate('field_sales.stock_slip.skeleton_hint'),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
