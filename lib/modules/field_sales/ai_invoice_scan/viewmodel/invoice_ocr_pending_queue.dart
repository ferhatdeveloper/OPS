// Dosya Adı: invoice_ocr_pending_queue.dart
// Açıklama: Offline / key yok AI fatura OCR bekleyen kuyruk (yerel görüntü)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../model/invoice_scan_doc_type.dart';

/// {@template invoice_ocr_pending_item}
/// Bekleyen OCR işi meta (görüntü yolu; içerik loglanmaz).
/// {@endtemplate}
class InvoiceOcrPendingItem {
  /// [id]
  final String id;

  /// [imagePath]: Yerel dosya
  final String imagePath;

  /// [docType]
  final InvoiceScanDocType docType;

  /// [createdAtIso]
  final String createdAtIso;

  /// {@macro invoice_ocr_pending_item}
  const InvoiceOcrPendingItem({
    required this.id,
    required this.imagePath,
    required this.docType,
    required this.createdAtIso,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'docType': docType.storageValue,
        'createdAtIso': createdAtIso,
      };

  factory InvoiceOcrPendingItem.fromJson(Map<String, dynamic> json) {
    return InvoiceOcrPendingItem(
      id: (json['id'] ?? '').toString(),
      imagePath: (json['imagePath'] ?? '').toString(),
      docType: InvoiceScanDocTypeX.tryParse(json['docType']?.toString()),
      createdAtIso: (json['createdAtIso'] ?? '').toString(),
    );
  }
}

/// {@template invoice_ocr_pending_queue}
/// SharedPreferences + uygulama dizini; görüntü/base64 log yok.
/// {@endtemplate}
class InvoiceOcrPendingQueue {
  static const _prefsKey = 'ai_invoice_ocr_pending_v1';
  final Uuid _uuid;

  /// {@macro invoice_ocr_pending_queue}
  InvoiceOcrPendingQueue({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  /// Görüntüyü kaydet + kuyruğa ekle
  Future<InvoiceOcrPendingItem> enqueue({
    required Uint8List bytes,
    required InvoiceScanDocType docType,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/ai_invoice_ocr_pending');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final id = _uuid.v4();
    final path = '${folder.path}/$id.jpg';
    await File(path).writeAsBytes(bytes, flush: true);
    final item = InvoiceOcrPendingItem(
      id: id,
      imagePath: path,
      docType: docType,
      createdAtIso: DateTime.now().toIso8601String(),
    );
    final list = await listPending();
    list.add(item);
    await _save(list);
    return item;
  }

  /// Bekleyenler
  Future<List<InvoiceOcrPendingItem>> listPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => InvoiceOcrPendingItem.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .where((e) => e.id.isNotEmpty && e.imagePath.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Kaldır + dosya sil
  Future<void> remove(String id) async {
    final list = await listPending();
    InvoiceOcrPendingItem? found;
    final next = <InvoiceOcrPendingItem>[];
    for (final e in list) {
      if (e.id == id) {
        found = e;
      } else {
        next.add(e);
      }
    }
    await _save(next);
    if (found != null) {
      try {
        final f = File(found.imagePath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  Future<void> _save(List<InvoiceOcrPendingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
