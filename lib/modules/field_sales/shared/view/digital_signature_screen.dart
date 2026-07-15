import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/widgets/signature_pad.dart';

enum SignatureType { order, invoice, visit }

class DigitalSignatureScreen extends ConsumerStatefulWidget {
  final String transactionId;
  final SignatureType type;
  final Function(String signatureData) onComplete;

  const DigitalSignatureScreen({
    super.key,
    required this.transactionId,
    required this.type,
    required this.onComplete,
  });

  @override
  ConsumerState<DigitalSignatureScreen> createState() => _DigitalSignatureScreenState();
}

class _DigitalSignatureScreenState extends ConsumerState<DigitalSignatureScreen> {
  List<Offset?> _signaturePoints = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(l10n.translate('field_sales.digital_signature')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(l10n),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.translate('field_sales.digital_signature_hint'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  child: SignaturePadWidget(
                    onSigned: (points) {
                      setState(() {
                        _signaturePoints = points;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (_signaturePoints.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _signaturePoints = [];
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Temizle'),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _signaturePoints.isEmpty ? null : _handleComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A8E8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      l10n.translate('field_sales.complete_visit_and_sign'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SafeArea(child: SizedBox(height: 10)),
        ],
      ),
    );
  }

  String _getTitle(AppLocalization l10n) {
    switch (widget.type) {
      case SignatureType.order:
        return 'Sipariş Onayı';
      case SignatureType.invoice:
        return 'Fatura Onayı';
      case SignatureType.visit:
        return l10n.translate('field_sales.finish_visit');
    }
  }

  void _handleComplete() {
    final signatureData = jsonEncode(
      _signaturePoints
          .map((p) => p == null ? null : {'x': p.dx, 'y': p.dy})
          .toList(),
    );
    widget.onComplete(signatureData);
  }
}
