import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/settings_service.dart';
import '../service/storage_service.dart';
import '../service/storage_monitor.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _baseUrlController = TextEditingController();
  final _printerUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _timeoutController = TextEditingController();
  bool _useHttps = true;
  bool _isLoading = false;
  bool _isTesting = false;
  Map<String, Map<String, dynamic>>? _testResults;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsService = ref.read(settingsServiceProvider);
    final apiConfig = await settingsService.getApiConfig();

    setState(() {
      _baseUrlController.text = apiConfig['base_url'] as String;
      _printerUrlController.text = (apiConfig['printer_url'] as String?) ?? '';
      _apiKeyController.text = (apiConfig['api_key'] as String?) ?? '';
      _timeoutController.text = '${apiConfig['timeout'] ?? 30}';
      _useHttps = apiConfig['use_https'] == 1;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.updateApiConfig(
      baseUrl: _baseUrlController.text,
      printerUrl: _printerUrlController.text.isEmpty
          ? null
          : _printerUrlController.text,
      apiKey: _apiKeyController.text.isEmpty ? null : _apiKeyController.text,
      timeout: int.tryParse(_timeoutController.text) ?? 30,
      useHttps: _useHttps,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }

  Future<void> _testUrls() async {
    setState(() {
      _isTesting = true;
      _testResults = null;
    });

    try {
      final settingsService = ref.read(settingsServiceProvider);
      // First save the current settings
      await settingsService.updateApiConfig(
        baseUrl: _baseUrlController.text,
        printerUrl: _printerUrlController.text.isEmpty
            ? null
            : _printerUrlController.text,
        apiKey: _apiKeyController.text.isEmpty ? null : _apiKeyController.text,
        timeout: int.tryParse(_timeoutController.text) ?? 30,
        useHttps: _useHttps,
      );

      // Then test the connections
      final results = await settingsService.testApiConnections();

      setState(() {
        _testResults = results;
        _isTesting = false;
      });

      if (!mounted) return;

      // Show a simple success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL test completed'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isTesting = false;
      });

      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build test results widget
  Widget _buildTestResultsWidget() {
    if (_testResults == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Test Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Base URL test result
            if (_testResults!.containsKey('baseUrl')) ...[
              Text(
                'Base URL: ${_useHttps ? 'https://' : 'http://'}${_baseUrlController.text}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStatusIndicator(_testResults!['baseUrl']!),
              const SizedBox(height: 16),
            ],

            // Printer URL test result (if available)
            if (_testResults!.containsKey('printerUrl')) ...[
              Text(
                'Printer URL: ${_useHttps ? 'https://' : 'http://'}${_printerUrlController.text}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStatusIndicator(_testResults!['printerUrl']!),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  // Build status indicator widget
  Widget _buildStatusIndicator(Map<String, dynamic> result) {
    final bool success = result['success'] as bool;
    final String message = result['message'] as String;
    final String? body = result['body'] as String?;
    final Map<String, dynamic>? portInfo =
        result['port'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: success ? Colors.green[800] : Colors.red[800],
                ),
              ),
            ),
          ],
        ),

        // Show port status if available
        if (portInfo != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                portInfo['isOpen']
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: portInfo['isOpen'] ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Port ${portInfo['number']}: ${portInfo['isOpen'] ? 'Açık' : 'Kapalı'}',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      portInfo['isOpen'] ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],

        // Show response body if available
        if (body != null && body.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            width: double.infinity,
            child: Text(
              body,
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'API Configuration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _baseUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Base URL',
                              border: OutlineInputBorder(),
                              helperText:
                                  'API base URL without http/https prefix',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _printerUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Printer URL (Optional)',
                              border: OutlineInputBorder(),
                              helperText: 'Printer service URL',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _apiKeyController,
                            decoration: const InputDecoration(
                              labelText: 'API Key (Optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _timeoutController,
                            decoration: const InputDecoration(
                              labelText: 'Timeout (seconds)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Switch(
                                value: _useHttps,
                                onChanged: (value) {
                                  setState(() {
                                    _useHttps = value;
                                  });
                                },
                              ),
                              const Text('Use HTTPS'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons row with Save and Test
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save Settings'),
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: _isTesting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.network_check),
                        label: const Text('Test URLs'),
                        onPressed: _isTesting ? null : _testUrls,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          backgroundColor: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),

                  // Test Results section
                  const SizedBox(height: 20),
                  if (_testResults != null) _buildTestResultsWidget(),

                  const SizedBox(height: 20),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Storage Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          StorageInfoWidget(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class StorageInfoWidget extends StatefulWidget {
  @override
  _StorageInfoWidgetState createState() => _StorageInfoWidgetState();
}

class _StorageInfoWidgetState extends State<StorageInfoWidget> {
  bool _showDiagnostics = false;
  bool _runningDiagnostic = false;
  String? _diagnosticResults;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StorageInfo>(
      future: _getStorageInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final storageInfo = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              storageInfo?.storageType ?? 'Unknown storage type',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Storage Path: ${storageInfo?.storagePath ?? 'Unknown'}',
              style: const TextStyle(fontSize: 14),
            ),
            if (storageInfo?.availableSpace != null) ...[
              const SizedBox(height: 4),
              Text(
                'Available Space: ${storageInfo!.availableSpace!.toStringAsFixed(2)} MB',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Health Status: ', style: const TextStyle(fontSize: 14)),
                Icon(
                  storageInfo?.isHealthy ?? false
                      ? Icons.check_circle
                      : Icons.error,
                  color: storageInfo?.isHealthy ?? false
                      ? Colors.green
                      : Colors.red,
                  size: 16,
                ),
                Text(
                  storageInfo?.isHealthy ?? false
                      ? ' Healthy'
                      : ' Issues Detected',
                  style: TextStyle(
                    fontSize: 14,
                    color: storageInfo?.isHealthy ?? false
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Your API configuration settings and user data are saved persistently '
              'using the appropriate storage method for your platform.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Diagnostic button
            ElevatedButton.icon(
              icon: const Icon(Icons.health_and_safety),
              label: Text(
                _showDiagnostics
                    ? 'Hide Diagnostics'
                    : 'Run Storage Diagnostics',
              ),
              onPressed: _runningDiagnostic
                  ? null
                  : () async {
                      if (_showDiagnostics) {
                        setState(() {
                          _showDiagnostics = false;
                          _diagnosticResults = null;
                        });
                      } else {
                        setState(() {
                          _runningDiagnostic = true;
                          _showDiagnostics = true;
                        });

                        // Run diagnostics using StorageMonitor
                        final storageService =
                            await StorageService.getInstance();
                        final storageMonitor = StorageMonitor(storageService);

                        try {
                          // Run comprehensive diagnostics
                          final diagnosticResult =
                              await storageMonitor.runDiagnostics();

                          setState(() {
                            _diagnosticResults =
                                'Storage Diagnostic Results:\n\n'
                                        '- Status: ${diagnosticResult.success ? '✅ Success' : '❌ Failed'}\n'
                                        '- Time Taken: ${diagnosticResult.timeTakenMs}ms\n' +
                                    (diagnosticResult.writeTimeMs != null
                                        ? '- Write Time: ${diagnosticResult.writeTimeMs}ms\n'
                                        : '') +
                                    (diagnosticResult.readTimeMs != null
                                        ? '- Read Time: ${diagnosticResult.readTimeMs}ms\n'
                                        : '') +
                                    (diagnosticResult.performanceRating != null
                                        ? '- Performance: ${diagnosticResult.performanceRating}\n'
                                        : '') +
                                    '\nMessage: ${diagnosticResult.message}';
                            _runningDiagnostic = false;
                          });

                          // Clean up test data
                          await storageMonitor.cleanupTestData();
                        } catch (e) {
                          setState(() {
                            _diagnosticResults =
                                'Diagnostic Error: ${e.toString()}';
                            _runningDiagnostic = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _showDiagnostics ? Colors.orange : null,
              ),
            ),

            // Diagnostic results
            if (_showDiagnostics) ...[
              const SizedBox(height: 16),
              if (_runningDiagnostic)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Running diagnostics...'),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    _diagnosticResults ?? 'No diagnostic data available',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Future<StorageInfo> _getStorageInfo() async {
    try {
      final storageService = await StorageService.getInstance();
      final storageMonitor = StorageMonitor(storageService);
      return await storageMonitor.getStorageInfo();
    } catch (e) {
      print('Error getting storage info: $e');
      // Return fallback info on error
      return StorageInfo(
        storageType: 'Unknown storage type',
        storagePath: 'Path unavailable',
        availableSpace: null,
        isHealthy: false,
      );
    }
  }
}
