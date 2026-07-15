import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';

class WarehouseManagementScreen extends ConsumerStatefulWidget {
  const WarehouseManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WarehouseManagementScreen> createState() => _WarehouseManagementScreenState();
}

class _WarehouseManagementScreenState extends ConsumerState<WarehouseManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalization.of(context).translate('inventory.warehouse_management')),
        backgroundColor: const Color(0xFF8B7CC7),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warehouse, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppLocalization.of(context).translate('inventory.warehouse_management_module'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalization.of(context).translate('inventory.warehouse_management_desc'),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
