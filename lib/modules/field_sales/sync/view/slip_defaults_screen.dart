import 'package:flutter/material.dart';
import '../../../../service/print_settings_service.dart';
import '../../../../service/bluetooth_print_service.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../../../../view/widgets/template_preview_card.dart';

class SlipDefaultsScreen extends StatefulWidget {
  const SlipDefaultsScreen({Key? key}) : super(key: key);

  @override
  State<SlipDefaultsScreen> createState() => _SlipDefaultsScreenState();
}

class _SlipDefaultsScreenState extends State<SlipDefaultsScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedWarehouse = 'Merkez Depo (01)';
  String? _selectedSeries = 'SF (Satış Faturası)';
  String? _selectedVat = '20';

  // Printer Settings
  String? _selectedPrinterAddress;
  String? _selectedLabelPrinterAddress;
  bool _showPreview = true;
  List<BluetoothDevice> _pairedDevices = [];
  bool _isLoadingDevices = false;
  bool _isTestPrinting = false;
  bool _isLabelTestPrinting = false;

  int _paperWidth = 58;
  bool _autoPrint = false;
  final _footerController = TextEditingController();
  final _feedbackUrlController = TextEditingController();
  
  String _selectedSlipTemplate = 'standard';
  String _selectedLabelTemplate = 'product_small';

  final List<String> _warehouses = ['Merkez Depo (01)', 'Araç Depo - 34ABC123 (02)', 'İade Deposu (04)'];
  final List<String> _series = ['SF (Satış Faturası)', 'PR (Perakende)', 'IA (İade)', 'VS (Saha Satış)'];
  final List<String> _vatRates = ['0', '1', '10', '20'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBluetoothDevices();
  }

  @override
  void dispose() {
    _footerController.dispose();
    _feedbackUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await PrintSettingsService().getDefaultPrinter();
    final labelSettings = await PrintSettingsService().getLabelPrinter();
    final showPreview = await PrintSettingsService().getShowPreview();
    final paperWidth = await PrintSettingsService().getPaperWidth();
    final autoPrint = await PrintSettingsService().getAutoPrint();
    final footer = await PrintSettingsService().getFooterMessage();
    final feedback = await PrintSettingsService().getFeedbackUrl();
    final slipTemplate = await PrintSettingsService().getDefaultSlipTemplate();
    final labelTemplate = await PrintSettingsService().getDefaultLabelTemplate();

    setState(() {
      _selectedPrinterAddress = settings['address'];
      _selectedLabelPrinterAddress = labelSettings['address'];
      _showPreview = showPreview;
      _paperWidth = paperWidth;
      _autoPrint = autoPrint;
      _footerController.text = footer;
      _feedbackUrlController.text = feedback;
      _selectedSlipTemplate = slipTemplate;
      _selectedLabelTemplate = labelTemplate;
    });
  }

  Future<void> _loadBluetoothDevices() async {
    setState(() => _isLoadingDevices = true);
    try {
      final devices = await BluetoothPrintService().getPairedDevices();
      setState(() {
        _pairedDevices = devices;
        _isLoadingDevices = false;
      });
    } catch (e) {
      setState(() => _isLoadingDevices = false);
    }
  }

  void _saveDefaults() async {
    if (_formKey.currentState!.validate()) {
      // Save Printer Settings
      if (_selectedPrinterAddress != null) {
        final selectedDevice = _pairedDevices.firstWhere(
          (d) => d.address == _selectedPrinterAddress,
          orElse: () => BluetoothDevice(null, null),
        );
        await PrintSettingsService().setDefaultPrinter(selectedDevice.name, selectedDevice.address);
      } else {
        await PrintSettingsService().setDefaultPrinter(null, null);
      }
      
      await PrintSettingsService().setShowPreview(_showPreview);
      await PrintSettingsService().setPaperWidth(_paperWidth);
      await PrintSettingsService().setAutoPrint(_autoPrint);
      await PrintSettingsService().setFooterMessage(_footerController.text);
      await PrintSettingsService().setFeedbackUrl(_feedbackUrlController.text);
      await PrintSettingsService().setDefaultSlipTemplate(_selectedSlipTemplate);
      await PrintSettingsService().setDefaultLabelTemplate(_selectedLabelTemplate);

      // Save Label Printer Settings
      if (_selectedLabelPrinterAddress != null) {
        final selectedDevice = _pairedDevices.firstWhere(
          (d) => d.address == _selectedLabelPrinterAddress,
          orElse: () => BluetoothDevice(null, null),
        );
        await PrintSettingsService().setLabelPrinter(selectedDevice.name, selectedDevice.address);
      } else {
        await PrintSettingsService().setLabelPrinter(null, null);
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ayarlar başarıyla kaydedildi.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _handleTestPrint() async {
    if (_selectedPrinterAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce bir yazıcı seçin.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isTestPrinting = true);
    try {
      final selectedDevice = _pairedDevices.firstWhere(
        (d) => d.address == _selectedPrinterAddress,
      );

      final printService = BluetoothPrintService();
      
      // Check connection
      bool? isConnected = await printService.isConnected();
      if (isConnected != true) {
        await printService.connect(selectedDevice);
      }

      await printService.printTest();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test çıktısı gönderildi.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yazdırma hatası: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isTestPrinting = false);
    }
  }

  Future<void> _handleLabelTestPrint() async {
    if (_selectedLabelPrinterAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce bir etiket yazıcısı seçin.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLabelTestPrinting = true);
    try {
      final selectedDevice = _pairedDevices.firstWhere(
        (d) => d.address == _selectedLabelPrinterAddress,
      );

      final printService = BluetoothPrintService();
      
      // Check connection
      bool? isConnected = await printService.isConnected();
      if (isConnected != true) {
        await printService.connect(selectedDevice);
      }

      await printService.printLabel("ÖRNEK ÜRÜN ETİKETİ", "BRC-10023", "1.250,00");
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test etiketi gönderildi.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yazdırma hatası: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLabelTestPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: const Text('Fiş Ön Değerleri', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saha satış işlemlerinde (Fatura, Sipariş, İrsaliye) kullanılacak varsayılan ERP ayarlarını buradan belirleyebilirsiniz.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),

              Text('Varsayılan Depo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              _buildDropdown(_selectedWarehouse, _warehouses, (v) => setState(() => _selectedWarehouse = v)),
              
              const SizedBox(height: 20),
              Text('Varsayılan Fiş Serisi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              _buildDropdown(_selectedSeries, _series, (v) => setState(() => _selectedSeries = v)),
              
              const SizedBox(height: 20),
              Text('Varsayılan KDV Oranı (%)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              _buildDropdown(_selectedVat, _vatRates, (v) => setState(() => _selectedVat = v)),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                   Text('Fiş Tasarımı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    TemplatePreviewCard(
                      title: 'Standart Fiş',
                      templateId: 'standard',
                      isSelected: _selectedSlipTemplate == 'standard',
                      onTap: () => setState(() => _selectedSlipTemplate = 'standard'),
                    ),
                    TemplatePreviewCard(
                      title: 'Minimal Fiş',
                      templateId: 'minimal',
                      isSelected: _selectedSlipTemplate == 'minimal',
                      onTap: () => setState(() => _selectedSlipTemplate = 'minimal'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                   const Icon(Icons.print, color: Color(0xFF00A8E8)),
                   const SizedBox(width: 8),
                   Text('Yazıcı Ayarları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
                ],
              ),
              const SizedBox(height: 16),
              
              Text('Varsayılan Bluetooth Yazıcı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              _isLoadingDevices 
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _selectedPrinterAddress,
                    hint: const Text('Yazıcı Seçin'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('Seçilmedi')),
                      ..._pairedDevices.map((d) => DropdownMenuItem(value: d.address, child: Text(d.name ?? 'Bilinmeyen'))).toList(),
                    ],
                    onChanged: (v) => setState(() => _selectedPrinterAddress = v),
                  ),
              const SizedBox(height: 16),
              
              SwitchListTile(
                 title: const Text('Yazdırma Ön İzleme Yapılsın mı?', style: TextStyle(fontWeight: FontWeight.bold)),
                 subtitle: const Text('Kapatıldığında varsayılan yazıcıdan direkt yazdırılır.'),
                 value: _showPreview,
                 activeColor: const Color(0xFF00A8E8),
                 contentPadding: EdgeInsets.zero,
                 onChanged: (v) => setState(() => _showPreview = v),
              ),

              const SizedBox(height: 16),
              if (_selectedPrinterAddress != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isTestPrinting ? null : _handleTestPrint,
                    icon: _isTestPrinting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.print),
                    label: const Text('SLİP TEST ÇIKTISI AL'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                   Text('Etiket Tasarımı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    TemplatePreviewCard(
                      title: 'Ürün Etiketi (50x30)',
                      templateId: 'product_small',
                      isSelected: _selectedLabelTemplate == 'product_small',
                      onTap: () => setState(() => _selectedLabelTemplate = 'product_small'),
                    ),
                    TemplatePreviewCard(
                      title: 'Raf Etiketi (80x40)',
                      templateId: 'shelf_large',
                      isSelected: _selectedLabelTemplate == 'shelf_large',
                      onTap: () => setState(() => _selectedLabelTemplate = 'shelf_large'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                   const Icon(Icons.label, color: Color(0xFF00A8E8)),
                   const SizedBox(width: 8),
                   Text('Etiket Yazıcısı Ayarları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
                ],
              ),
              const SizedBox(height: 16),
              
              Text('Varsayılan Etiket Yazıcısı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              _isLoadingDevices 
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _selectedLabelPrinterAddress,
                    hint: const Text('Etiket Yazıcısı Seçin'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('Seçilmedi')),
                      ..._pairedDevices.map((d) => DropdownMenuItem(value: d.address, child: Text(d.name ?? 'Bilinmeyen'))).toList(),
                    ],
                    onChanged: (v) => setState(() => _selectedLabelPrinterAddress = v),
                  ),
              const SizedBox(height: 16),
              if (_selectedLabelPrinterAddress != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLabelTestPrinting ? null : _handleLabelTestPrint,
                    icon: _isLabelTestPrinting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.label),
                    label: const Text('ETİKET TEST ÇIKTISI AL'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                   const Icon(Icons.settings_suggest, color: Color(0xFF00A8E8)),
                   const SizedBox(width: 8),
                   Text('Gelişmiş Yazdırma Ayarları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
                ],
              ),
              const SizedBox(height: 16),

              Text('Kağıt Genişliği', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _paperWidth,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
                items: const [
                  DropdownMenuItem(value: 58, child: Text('58 mm (Standart)')),
                  DropdownMenuItem(value: 80, child: Text('80 mm (Geniş)')),
                ],
                onChanged: (v) => setState(() => _paperWidth = v ?? 58),
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                 title: const Text('Otomatik Yazdır', style: TextStyle(fontWeight: FontWeight.bold)),
                 subtitle: const Text('Fatura/Sipariş kaydedildiğinde otomatik çıktı al.'),
                 value: _autoPrint,
                 activeColor: const Color(0xFF00A8E8),
                 contentPadding: EdgeInsets.zero,
                 onChanged: (v) => setState(() => _autoPrint = v),
              ),
              const SizedBox(height: 16),

              Text('Fiş Altı Mesajı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _footerController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Örn: Bizi tercih ettiğiniz için teşekkürler!',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
              const SizedBox(height: 16),

              Text('Değerlendirme (Feedback) URL / QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _feedbackUrlController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Örn: https://exfinerp.com/feedback',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveDefaults,
                  icon: const Icon(Icons.save),
                  label: const Text('KAYDET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF375A7F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String? value, List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
      items: items.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
      onChanged: onChanged,
    );
  }
}
