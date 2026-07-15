import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../model/customer_model.dart';
import '../viewmodel/customer_provider.dart';
import '../../../../core/localization/app_localization.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final CustomerModel? existingCustomer;

  const CustomerFormScreen({Key? key, this.existingCustomer}) : super(key: key);

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _taxOfficeController = TextEditingController();
  final _yetkiliController = TextEditingController();
  final _addressController = TextEditingController();
  final _adres2Controller = TextEditingController();
  final _ilController = TextEditingController();
  final _ilceController = TextEditingController();
  final _semtController = TextEditingController();
  final _ulkeController = TextEditingController();
  final _postaKoduController = TextEditingController();
  final _tcknController = TextEditingController();
  final _phoneController = TextEditingController();
  final _telefon2Controller = TextEditingController();
  final _faxController = TextEditingController();
  final _emailController = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingCustomer != null) {
      final c = widget.existingCustomer!;
      _nameController.text = c.name;
      _taxNumberController.text = c.taxNo ?? '';
      _taxOfficeController.text = c.taxOffice ?? '';
      _yetkiliController.text = c.yetkili ?? '';
      _addressController.text = c.address ?? '';
      _adres2Controller.text = c.adres2 ?? '';
      _ilController.text = c.il ?? '';
      _ilceController.text = c.ilce ?? '';
      _semtController.text = c.semt ?? '';
      _ulkeController.text = c.ulke ?? '';
      _postaKoduController.text = c.postaKodu ?? '';
      _tcknController.text = c.tckn ?? '';
      _phoneController.text = c.phone ?? '';
      _telefon2Controller.text = c.telefon2 ?? '';
      _faxController.text = c.fax ?? '';
      _emailController.text = c.email ?? '';
      _latitude = c.latitude;
      _longitude = c.longitude;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxNumberController.dispose();
    _taxOfficeController.dispose();
    _yetkiliController.dispose();
    _addressController.dispose();
    _adres2Controller.dispose();
    _ilController.dispose();
    _ilceController.dispose();
    _semtController.dispose();
    _ulkeController.dispose();
    _postaKoduController.dispose();
    _tcknController.dispose();
    _phoneController.dispose();
    _telefon2Controller.dispose();
    _faxController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw AppLocalization.of(context).translate('customer.location_services_disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw AppLocalization.of(context).translate('customer.location_permission_denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw AppLocalization.of(context).translate('customer.location_permission_denied_permanently');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      if (mounted) {
        final successMsg = AppLocalization.of(context).translate('customer.location_success');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$successMsg \${_latitude?.toStringAsFixed(4)}, \${_longitude?.toStringAsFixed(4)}'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isFetchingLocation = false);
    }
  }

  void _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    // Determine ID: either keep the existing one or generate a new timestamp-based fallback if offline
    final String idToSave = widget.existingCustomer?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final newCustomer = CustomerModel(
      id: idToSave,
      name: _nameController.text.trim(),
      taxNo: _taxNumberController.text.trim(),
      taxOffice: _taxOfficeController.text.trim(),
      yetkili: _yetkiliController.text.trim(),
      address: _addressController.text.trim(),
      adres2: _adres2Controller.text.trim(),
      il: _ilController.text.trim(),
      ilce: _ilceController.text.trim(),
      semt: _semtController.text.trim(),
      ulke: _ulkeController.text.trim(),
      postaKodu: _postaKoduController.text.trim(),
      tckn: _tcknController.text.trim(),
      phone: _phoneController.text.trim(),
      telefon2: _telefon2Controller.text.trim(),
      fax: _faxController.text.trim(),
      email: _emailController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      balance: widget.existingCustomer?.balance ?? 0.0,
      createdAt: widget.existingCustomer?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(customerProvider.notifier).saveCustomer(newCustomer);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalization.of(context).translate('customer.save_success')), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCustomer != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          isEditing 
              ? AppLocalization.of(context).translate('customer.edit_title') 
              : AppLocalization.of(context).translate('customer.new_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF375A7F), // Flat UI Primary Color
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildOutlinedField(AppLocalization.of(context).translate('customer.company_name'), _nameController, isRequired: true, icon: Icons.business),
                    Row(
                      children: [
                        Expanded(child: _buildOutlinedField(AppLocalization.of(context).translate('customer.tax_no'), _taxNumberController, icon: Icons.numbers, isNumber: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildOutlinedField(AppLocalization.of(context).translate('customer.tax_office'), _taxOfficeController)),
                      ],
                    ),
                    _buildOutlinedField(AppLocalization.of(context).translate('customer.authorized_person'), _yetkiliController, icon: Icons.person),
                    _buildOutlinedField(AppLocalization.of(context).translate('customer.address'), _addressController, icon: Icons.location_on, maxLines: 2),
                    _buildOutlinedField(AppLocalization.of(context).translate('customer.address2'), _adres2Controller, maxLines: 2),
                    Row(
                      children: [
                        Expanded(child: _buildOutlinedField(AppLocalization.of(context).translate('customer.city'), _ilController)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildOutlinedField(AppLocalization.of(context).translate('customer.district'), _ilceController)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _buildOutlinedField(AppLocalization.of(context).translate('customer.neighborhood'), _semtController)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildOutlinedField(AppLocalization.of(context).translate('customer.postal_code'), _postaKoduController, isNumber: true)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _buildOutlinedField(AppLocalization.of(context).translate('customer.country'), _ulkeController)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildOutlinedField(AppLocalization.of(context).translate('customer.tckn'), _tcknController, isNumber: true)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _buildOutlinedField(AppLocalization.of(context).translate('customer.phone'), _phoneController, icon: Icons.phone, isNumber: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildOutlinedField(AppLocalization.of(context).translate('customer.phone2'), _telefon2Controller, isNumber: true)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _buildOutlinedField(AppLocalization.of(context).translate('customer.email'), _emailController, icon: Icons.email)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildOutlinedField(AppLocalization.of(context).translate('customer.fax'), _faxController)),
                      ],
                    ),
                    const SizedBox(height: 80), // Padding for floating layout
                  ],
                ),
              ),
            ),
          ),
          _buildBottomActionRow(),
        ],
      ),
    );
  }

  Widget _buildOutlinedField(
    String label, 
    TextEditingController controller, {
    bool isRequired = false, 
    IconData? icon,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        validator: isRequired ? (value) => value == null || value.trim().isEmpty ? AppLocalization.of(context).translate('validation.required').replaceAll('{field}', label) : null : null,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
          prefixIcon: icon != null ? Icon(icon, color: Colors.blueGrey, size: 20) : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF375A7F), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: _isFetchingLocation ? null : _fetchLocation,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: _latitude != null ? Colors.green : const Color(0xFF375A7F), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  foregroundColor: _latitude != null ? Colors.green : const Color(0xFF375A7F),
                ),
                icon: _isFetchingLocation
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_latitude != null ? Icons.check_circle : Icons.location_on),
                label: Text(AppLocalization.of(context).translate('customer.get_location'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveCustomer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A8E8), // Primary Action Blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(
                  _isLoading ? AppLocalization.of(context).translate('common.saving') : AppLocalization.of(context).translate('common.save'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

