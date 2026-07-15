// Dosya Adı: company_management.dart
// Açıklama: Admin paneli için firma yönetimi ekranı (ekle, listele, sil, güncelle)
// Oluşturulma Tarihi: 2024-03-22
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-22

import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import 'package:intl/intl.dart';

/// {@template CompanyManagement}
/// Firma yönetimi ekranı: firmaları listeleme, ekleme, silme ve güncelleme
/// Ayrıca firma seçilince dönem ekleme ve listeleme alanı içerir
///
/// Kullanım örneği:
/// ```dart
/// CompanyManagement()
/// ```
/// {@endtemplate}
class CompanyManagement extends StatefulWidget {
  const CompanyManagement({Key? key}) : super(key: key);

  @override
  State<CompanyManagement> createState() => _CompanyManagementState();
}

class _CompanyManagementState extends State<CompanyManagement> {
  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _companyNoController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isActive = true;
  String? _editingId;

  // Dönem yönetimi
  String? _selectedCompanyNo;
  List<Map<String, dynamic>> _periods = [];
  final _periodFormKey = GlobalKey<FormState>();
  final TextEditingController _periodNameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _periodIsActive = true;
  String? _editingPeriodId;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    setState(() => _isLoading = true);
    final supabase = await SupabaseService.getInstance();
    final companies = await supabase.query('company', orderBy: 'created_at');
    setState(() {
      _companies = companies;
      _isLoading = false;
    });
  }

  Future<void> _addOrUpdateCompany() async {
    if (!_formKey.currentState!.validate()) return;
    final supabase = await SupabaseService.getInstance();
    if (_editingId == null) {
      // Ekle
      final newCompany = {
        'name': _nameController.text,
        'company_no': _companyNoController.text,
        'description': _descController.text,
        'is_active': _isActive,
      };
      await supabase.insert('company', newCompany);
    } else {
      // Güncelle
      await supabase.update(
        'company',
        {
          'name': _nameController.text,
          'company_no': _companyNoController.text,
          'description': _descController.text,
          'is_active': _isActive,
        },
        _editingId!,
      );
    }
    _nameController.clear();
    _companyNoController.clear();
    _descController.clear();
    _isActive = true;
    _editingId = null;
    await _fetchCompanies();
  }

  Future<void> _deleteCompany(int index) async {
    final supabase = await SupabaseService.getInstance();
    final companyId = _companies[index]['id'];
    await supabase.delete('company', companyId.toString());
    await _fetchCompanies();
    if (_selectedCompanyNo == _companies[index]['company_no']) {
      setState(() {
        _selectedCompanyNo = null;
        _periods = [];
      });
    }
  }

  void _startEdit(int index) {
    final company = _companies[index];
    _nameController.text = company['name'] ?? '';
    _companyNoController.text = company['company_no'] ?? '';
    _descController.text = company['description'] ?? '';
    _isActive = company['is_active'] ?? true;
    _editingId = company['id']?.toString();
    setState(() {});
  }

  /// Seçili firmanın company_no'su ile dönemleri getirir
  Future<void> _fetchPeriods(String companyNo) async {
    final supabase = await SupabaseService.getInstance();
    final response = await supabase.client
        .from('company_period')
        .select()
        .eq('company_no', companyNo)
        .order('start_date');
    setState(() {
      _periods = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _addOrUpdatePeriod() async {
    if (!_periodFormKey.currentState!.validate() || _selectedCompanyNo == null)
      return;
    final supabase = await SupabaseService.getInstance();
    if (_editingPeriodId == null) {
      // Ekle
      final newPeriod = {
        'company_no': _selectedCompanyNo,
        'period_name': _periodNameController.text,
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
        'end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
        'is_active': _periodIsActive,
      };
      await supabase.insert('company_period', newPeriod);
    } else {
      // Güncelle
      await supabase.update(
        'company_period',
        {
          'period_name': _periodNameController.text,
          'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
          'end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
          'is_active': _periodIsActive,
        },
        _editingPeriodId!,
      );
    }
    _periodNameController.clear();
    _startDate = null;
    _endDate = null;
    _periodIsActive = true;
    _editingPeriodId = null;
    await _fetchPeriods(_selectedCompanyNo!);
  }

  void _startEditPeriod(int index) {
    final period = _periods[index];
    _periodNameController.text = period['period_name'] ?? '';
    _startDate = DateTime.tryParse(period['start_date'] ?? '');
    _endDate = DateTime.tryParse(period['end_date'] ?? '');
    _periodIsActive = period['is_active'] ?? true;
    _editingPeriodId = period['id']?.toString();
    setState(() {});
  }

  Future<void> _deletePeriod(int index) async {
    final supabase = await SupabaseService.getInstance();
    final periodId = _periods[index]['id'];
    await supabase.delete('company_period', periodId.toString());
    await _fetchPeriods(_selectedCompanyNo!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firma Yönetimi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Firma ekleme/güncelleme formu
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 180,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Firma Adı',
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Boş bırakılamaz'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              controller: _companyNoController,
                              decoration: const InputDecoration(
                                labelText: 'Firma No',
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Firma No zorunlu'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 200,
                            child: TextFormField(
                              controller: _descController,
                              decoration: const InputDecoration(
                                labelText: 'Açıklama',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            children: [
                              Checkbox(
                                value: _isActive,
                                onChanged: (v) {
                                  setState(() => _isActive = v ?? true);
                                },
                              ),
                              const Text('Aktif')
                            ],
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _addOrUpdateCompany,
                            child:
                                Text(_editingId == null ? 'Ekle' : 'Güncelle'),
                          ),
                          if (_editingId != null)
                            TextButton(
                              onPressed: () {
                                _nameController.clear();
                                _companyNoController.clear();
                                _descController.clear();
                                _isActive = true;
                                _editingId = null;
                                setState(() {});
                              },
                              child: const Text('İptal'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Firma listesi
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 600,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _companies.length,
                        itemBuilder: (context, index) {
                          final company = _companies[index];
                          final selected =
                              _selectedCompanyNo == company['company_no'];
                          return Card(
                            color: selected ? Colors.blue.shade50 : null,
                            child: ListTile(
                              leading: SizedBox(
                                width: 80,
                                child: Text('ID: ${company['id']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              title: Text(
                                '${company['name'] ?? ''} (No: ${company['company_no'] ?? '-'})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                company['description'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _startEdit(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteCompany(index),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      selected
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () async {
                                      setState(() {
                                        _selectedCompanyNo = selected
                                            ? null
                                            : company['company_no'];
                                        _periods = [];
                                      });
                                      if (!selected) {
                                        await _fetchPeriods(
                                            company['company_no']);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.info,
                                        color: Colors.blue),
                                    tooltip: 'Detaylar',
                                    onPressed: () {
                                      final companyNo = int.tryParse(
                                          company['company_no'].toString());
                                      if (companyNo == null) return;
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            CompanyDetailsPanel(
                                          companyNo: companyNo,
                                          companyName: company['name'],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Dönem ekleme ve listeleme (firma seçiliyse)
                if (_selectedCompanyNo != null)
                  Container(
                    color: Colors.grey.shade100,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Firma Dönemleri',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Form(
                          key: _periodFormKey,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _periodNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Dönem Adı',
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Boş bırakılamaz'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() => _startDate = picked);
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Başlangıç Tarihi',
                                    ),
                                    child: Text(_startDate == null
                                        ? 'Seçiniz'
                                        : DateFormat('yyyy-MM-dd')
                                            .format(_startDate!)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _endDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() => _endDate = picked);
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Bitiş Tarihi',
                                    ),
                                    child: Text(_endDate == null
                                        ? 'Seçiniz'
                                        : DateFormat('yyyy-MM-dd')
                                            .format(_endDate!)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _periodIsActive,
                                    onChanged: (v) {
                                      setState(
                                          () => _periodIsActive = v ?? true);
                                    },
                                  ),
                                  const Text('Aktif')
                                ],
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _addOrUpdatePeriod,
                                child: Text(_editingPeriodId == null
                                    ? 'Ekle'
                                    : 'Güncelle'),
                              ),
                              if (_editingPeriodId != null)
                                TextButton(
                                  onPressed: () {
                                    _periodNameController.clear();
                                    _startDate = null;
                                    _endDate = null;
                                    _periodIsActive = true;
                                    _editingPeriodId = null;
                                    setState(() {});
                                  },
                                  child: const Text('İptal'),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_periods.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Bu firmaya ait dönem yok.',
                                style: TextStyle(color: Colors.grey)),
                          ),
                        if (_periods.isNotEmpty)
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              itemCount: _periods.length,
                              itemBuilder: (context, index) {
                                final period = _periods[index];
                                return Card(
                                  child: ListTile(
                                    leading: Text('ID: ${period['id']}'),
                                    title: Text(period['period_name'] ?? ''),
                                    subtitle: Text(
                                        'Başlangıç: ${period['start_date']}  Bitiş: ${period['end_date']}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () =>
                                              _startEditPeriod(index),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _deletePeriod(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class CompanyDetailsPanel extends StatefulWidget {
  final int companyNo;
  final String companyName;
  const CompanyDetailsPanel(
      {required this.companyNo, required this.companyName, Key? key})
      : super(key: key);

  @override
  State<CompanyDetailsPanel> createState() => _CompanyDetailsPanelState();
}

class _CompanyDetailsPanelState extends State<CompanyDetailsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = [
    'Bölümler',
    'İşyerleri',
    'Fabrikalar',
    'Ambarlar'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${widget.companyName} Detayları',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            TabBar(
              controller: _tabController,
              labelColor: Colors.blue[800],
              unselectedLabelColor: Colors.blue[200],
              indicatorColor: Colors.blue,
              indicatorWeight: 3,
              tabs: _tabs.map((e) => Tab(text: e)).toList(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  DepartmentTab(companyNo: widget.companyNo),
                  WorkplaceTab(companyNo: widget.companyNo),
                  FactoryTab(companyNo: widget.companyNo),
                  WarehouseTab(companyNo: widget.companyNo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DepartmentTab extends CrudTabBase {
  DepartmentTab({required int companyNo, Key? key})
      : super(
            companyNo: companyNo,
            table: 'departments',
            label: 'Bölüm',
            key: key);
}

class WorkplaceTab extends CrudTabBase {
  WorkplaceTab({required int companyNo, Key? key})
      : super(
            companyNo: companyNo,
            table: 'workplaces',
            label: 'İşyeri',
            key: key);
}

class FactoryTab extends CrudTabBase {
  FactoryTab({required int companyNo, Key? key})
      : super(
            companyNo: companyNo,
            table: 'factories',
            label: 'Fabrika',
            key: key);
}

class WarehouseTab extends CrudTabBase {
  WarehouseTab({required int companyNo, Key? key})
      : super(
            companyNo: companyNo,
            table: 'warehouses',
            label: 'Ambar',
            key: key);
}

abstract class CrudTabBase extends StatefulWidget {
  final int companyNo;
  final String table;
  final String label;
  const CrudTabBase(
      {required this.companyNo,
      required this.table,
      required this.label,
      Key? key})
      : super(key: key);

  @override
  CrudTabBaseState createState() => CrudTabBaseState();
}

class CrudTabBaseState extends State<CrudTabBase> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _loading = true);
    final supabase = await SupabaseService.getInstance();
    final int companyNo = widget.companyNo;
    final data = await supabase.query(
      widget.table,
      filter: 'company_no',
      filterArgs: [companyNo],
    );
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  Future<void> _addItem() async {
    if (_nameController.text.trim().isEmpty) return;
    final supabase = await SupabaseService.getInstance();
    await supabase.insert(widget.table, {
      'company_no': widget.companyNo,
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'is_active': true,
    });
    _nameController.clear();
    _descController.clear();
    await _fetchItems();
  }

  Future<void> _deleteItem(dynamic id) async {
    final intId = int.tryParse(id.toString());
    if (intId == null) return;
    final supabase = await SupabaseService.getInstance();
    await supabase.delete(widget.table, intId.toString());
    await _fetchItems();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: '${widget.label} Adı'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Açıklama'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.green),
              onPressed: _addItem,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return ListTile(
                title: Text(item['name'] ?? ''),
                subtitle: Text(item['description'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      tooltip: 'Düzenle',
                      onPressed: () async {
                        final nameController =
                            TextEditingController(text: item['name'] ?? '');
                        final descController = TextEditingController(
                            text: item['description'] ?? '');
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('${widget.label} Düzenle'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                      labelText: '${widget.label} Adı'),
                                ),
                                TextField(
                                  controller: descController,
                                  decoration: const InputDecoration(
                                      labelText: 'Açıklama'),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('İptal'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final supabase =
                                      await SupabaseService.getInstance();
                                  await supabase.update(
                                    widget.table,
                                    {
                                      'name': nameController.text.trim(),
                                      'description': descController.text.trim(),
                                    },
                                    item['id'].toString(),
                                  );
                                  Navigator.pop(context, true);
                                },
                                child: const Text('Kaydet'),
                              ),
                            ],
                          ),
                        );
                        if (result == true) {
                          await _fetchItems();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteItem(item['id']),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
