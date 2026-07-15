import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';

class CreateMaterialScreen extends ConsumerStatefulWidget {
  const CreateMaterialScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateMaterialScreen> createState() =>
      _CreateMaterialScreenState();
}

class _CreateMaterialScreenState extends ConsumerState<CreateMaterialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _description2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _description2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalization.of(context).translate('inventory.create_material_card')),
        backgroundColor: const Color(0xFF8B7CC7),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: AppLocalization.of(context).translate('inventory.general_info')),
            Tab(text: AppLocalization.of(context).translate('inventory.general_info_2')),
            Tab(text: AppLocalization.of(context).translate('inventory.tracking_sorting')),
            Tab(text: AppLocalization.of(context).translate('inventory.units')),
            Tab(text: AppLocalization.of(context).translate('inventory.alternatives')),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: AppLocalization.of(context).translate('inventory.material_code'),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalization.of(context).translate('inventory.code_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: AppLocalization.of(context).translate('inventory.description')),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description2Controller,
                    decoration: InputDecoration(labelText: AppLocalization.of(context).translate('inventory.description_2')),
                  ),
                ],
              ),
            ),
            Center(child: Text(AppLocalization.of(context).translate('inventory.content_will_be_added'))),
            Center(child: Text(AppLocalization.of(context).translate('inventory.content_will_be_added'))),
            Center(child: Text(AppLocalization.of(context).translate('inventory.content_will_be_added'))),
            Center(child: Text(AppLocalization.of(context).translate('inventory.content_will_be_added'))),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalization.of(context).translate('common.cancel')),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B7CC7),
              ),
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  // Save logic here
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalization.of(context).translate('inventory.material_saved'))),
                  );
                }
              },
              child: Text(AppLocalization.of(context).translate('common.save')),
            ),
          ],
        ),
      ),
    );
  }
}
