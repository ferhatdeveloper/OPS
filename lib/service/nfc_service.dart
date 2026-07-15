import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:exfin_ops/service/database_service.dart';

class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  bool _isScanning = false;

  /// Start scanning for NFC tags
  /// Returns the customer_id mapped to the tag, or null if not found
  Future<void> startScanning({
    required Function(String customerId) onCustomerFound,
    required Function(String error) onError,
  }) async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      onError('NFC is not supported or disabled on this device.');
      return;
    }

    _isScanning = true;
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          // Extract Tag ID
          final String tagId = _extractTagId(tag);
          debugPrint('NFC Tag Discovered: $tagId');

          // Lookup customer in DB
          final customerId = await _lookupCustomerByTag(tagId);
          
          if (customerId != null) {
            onCustomerFound(customerId);
          } else {
            onError('Müşteri kaydı bulunamadı (Tag: $tagId)');
          }
          
          await NfcManager.instance.stopSession();
          _isScanning = false;
        } catch (e) {
          onError('NFC Error: $e');
        }
      },
      onError: (e) async {
        onError('NFC Session Error: $e');
        _isScanning = false;
      }
    );
  }

  Future<void> stopScanning() async {
    if (_isScanning) {
      await NfcManager.instance.stopSession();
      _isScanning = false;
    }
  }

  String _extractTagId(NfcTag tag) {
    // Tag ID extraction varies by platform and tag type
    // This is a simplified version; in production we'd handle NDEF/IsoDep/NfcA etc.
    final List<int> id = tag.data['id'] ?? [];
    if (id.isEmpty) {
      // Fallback: check platform specific data
      final nfca = NfcTagId.fromMap(tag.data['nfca']);
      if (nfca != null) return nfca.identifier;
    }
    return id.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
  }

  Future<String?> _lookupCustomerByTag(String tagId) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    
    final results = await db.query(
      'customers',
      columns: ['id'],
      where: 'nfc_tag_id = ?',
      whereArgs: [tagId],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first['id'] as String;
    }
    return null;
  }
}

class NfcTagId {
  final String identifier;
  NfcTagId(this.identifier);
  
  static NfcTagId? fromMap(Map<dynamic, dynamic>? data) {
    if (data == null) return null;
    final List<int> id = data['identifier'] ?? [];
    return NfcTagId(id.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase());
  }
}
