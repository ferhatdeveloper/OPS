// Dosya Adı: data_transfer_screen.dart
// Açıklama: Güncelleme dens triad — Gönder / Al / Ürün Resimleri (+ Aktarılıyor)
// Oluşturulma Tarihi: 2026-02-22
// Geliştirici: EXFIN OPS Team
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../core/services/logo_api_service.dart';
import '../../../../service/database_service.dart';
import '../../../../service/job_queue_service.dart';
import '../model/data_transfer_triad.dart';
import '../service/product_images_service.dart';
import 'logo_rest_settings_screen.dart';

/// {@template data_transfer_screen}
/// Güncelleme dens triad ekranı (Gönder / Al / Ürün Resimleri).
///
/// Kullanım örneği:
/// ```dart
/// const DataTransferScreen();
/// ```
/// {@endtemplate}
class DataTransferScreen extends StatefulWidget {
  /// {@macro data_transfer_screen}
  const DataTransferScreen({
    Key? key,
    this.productImagesService,
  }) : super(key: key);

  /// [productImagesService]: Ürün resmi servisi (test enjeksiyonu)
  final ProductImagesService? productImagesService;

  @override
  State<DataTransferScreen> createState() => _DataTransferScreenState();
}

class _DataTransferScreenState extends State<DataTransferScreen> {
  /// [isSyncing]: Senkron sürüyor mu
  bool isSyncing = false;

  /// [activeAction]: Aktif triad aksiyonu (null = yok)
  DataTransferAction? activeAction;

  /// [overallProgress]: Genel ilerleme 0–1
  double overallProgress = 0.0;

  /// [lastError]: Son hata metni
  String? lastError;

  /// [_sendEmptyMessageKey]: Gönder sonrası dens empty state anahtarı
  String? _sendEmptyMessageKey;

  /// Status kodları (UI'da çevrilir)
  static const String _stPending = 'pending';
  static const String _stTransferring = 'transferring';
  static const String _stDone = 'done';
  static const String _stError = 'error';
  static const String _stSkipped = 'skipped';

  /// [syncItems]: Aktarım satırları (titleKey + status kodu)
  late List<Map<String, dynamic>> syncItems;

  @override
  void initState() {
    super.initState();
    syncItems = _buildItems(DataTransferAction.receive);
  }

  /// {@template _build_items}
  /// Aksiyon için dens liste satırlarını üretir.
  /// {@endtemplate}
  List<Map<String, dynamic>> _buildItems(DataTransferAction action) {
    final defs = <String, Map<String, dynamic>>{
      'customers': {
        'key': 'customers',
        'titleKey': 'field_sales.customer_list',
        'icon': Icons.people,
      },
      'products': {
        'key': 'products',
        'titleKey': 'field_sales.product_list',
        'icon': Icons.shopping_bag,
      },
      'stock': {
        'key': 'stock',
        'titleKey': 'field_sales.stock',
        'icon': Icons.inventory,
      },
      'balances': {
        'key': 'balances',
        'titleKey': 'field_sales.balance',
        'icon': Icons.account_balance_wallet,
      },
      'upload': {
        'key': 'upload',
        'titleKey': 'field_sales.pending_documents_title',
        'icon': Icons.cloud_upload,
      },
      'product_images': {
        'key': 'product_images',
        'titleKey': 'field_sales.product_images',
        'icon': Icons.image,
      },
    };

    return DataTransferTriad.itemKeys(action).map((key) {
      final def = defs[key]!;
      return <String, dynamic>{
        ...def,
        'progress': 0.0,
        'status': _stPending,
      };
    }).toList();
  }

  /// {@template _status_label}
  /// Durum kodunu mevcut l10n key ile çevirir; yoksa ham kod.
  /// {@endtemplate}
  String _statusLabel(AppLocalization l10n, String status) {
    switch (status) {
      case _stTransferring:
        return l10n.translate(DataTransferTriad.transferringKey);
      case _stDone:
        return l10n.translate('field_sales.status_completed');
      case _stError:
        return l10n.translate('common.error');
      case _stPending:
        return l10n.translate('field_sales.status_pending');
      case _stSkipped:
        return l10n.translate('field_sales.status_skipped');
      default:
        return status;
    }
  }

  /// {@template _start_action}
  /// Dens triad aksiyonunu çalıştırır.
  /// {@endtemplate}
  Future<void> _startAction(DataTransferAction action) async {
    if (isSyncing) return;
    setState(() {
      isSyncing = true;
      activeAction = action;
      overallProgress = 0.0;
      lastError = null;
      _sendEmptyMessageKey = null;
      syncItems = _buildItems(action);
    });

    final logo = LogoApiService();
    if (action != DataTransferAction.productImages) {
      await logo.ensureReady();
    }

    for (int i = 0; i < syncItems.length; i++) {
      final item = syncItems[i];
      setState(() {
        item['status'] = _stTransferring;
        item['progress'] = 0.1;
      });

      try {
        switch (item['key']) {
          case 'customers':
            await _syncCustomers(logo, i);
            break;
          case 'products':
            await _syncProducts(logo, i);
            break;
          case 'stock':
            await _syncStock(logo, i);
            break;
          case 'balances':
            await _syncBalances(logo, i);
            break;
          case 'upload':
            await _uploadPending(i);
            break;
          case 'product_images':
            await _syncProductImages(i);
            break;
        }
        if (!mounted) return;
        setState(() {
          if (item['status'] != _stSkipped) {
            item['status'] = _stDone;
            item['progress'] = 1.0;
          }
          overallProgress = (i + 1) / syncItems.length;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          item['status'] = _stError;
          lastError = e.toString();
          overallProgress = (i + 1) / syncItems.length;
        });
      }
    }

    if (!mounted) return;
    setState(() {
      isSyncing = false;
      activeAction = null;
    });
  }

  Future<void> _syncCustomers(LogoApiService logo, int index) async {
    final l10n = AppLocalization.of(context);
    final result = await logo.getCustomers();
    if (!result.success) {
      throw Exception(
        result.error ??
            l10n.translate('field_sales.customers_download_failed'),
      );
    }
    final list = result.asMapList();
    final db = await (await DatabaseService.getInstance()).getDatabase();
    final now = DateTime.now().toIso8601String();
    var done = 0;
    for (final row in list) {
      final code = (row['CODE'] ?? row['code'] ?? row['LOGICALREF'] ?? '')
          .toString();
      if (code.isEmpty) continue;
      final name =
          (row['DEFINITION_'] ?? row['name'] ?? row['TITLE'] ?? code).toString();
      final existing = await db.query(
        'customers',
        where: 'id = ? OR code = ?',
        whereArgs: [code, code],
        limit: 1,
      );
      final data = {
        'id': existing.isNotEmpty ? existing.first['id'] : code,
        'code': code,
        'name': name,
        'tax_no': row['TAXNR'] ?? row['tax_number'] ?? row['tax_no'],
        'tax_office': row['TAXOFFICE'] ?? row['tax_office'],
        'address': row['ADDR1'] ?? row['address'],
        'il': row['CITY'] ?? row['city'] ?? row['il'],
        'phone': row['TELNRS1'] ?? row['phone'],
        'email': row['EMAILADDR'] ?? row['email'],
        'balance': (row['BALANCE'] ?? row['balance'] ?? 0) is num
            ? (row['BALANCE'] ?? row['balance'] as num).toDouble()
            : 0.0,
        'is_active': 1,
        'updated_at': now,
        'created_at': existing.isNotEmpty
            ? existing.first['created_at']
            : now,
      };
      try {
        await db.insert('customers', data);
      } catch (_) {
        await db.update(
          'customers',
          data,
          where: 'id = ?',
          whereArgs: [data['id']],
        );
      }
      done++;
      if (done % 20 == 0 && mounted) {
        setState(() {
          syncItems[index]['progress'] =
              (done / (list.isEmpty ? 1 : list.length)).clamp(0.1, 0.99);
        });
      }
    }
  }

  Future<void> _syncProducts(LogoApiService logo, int index) async {
    final l10n = AppLocalization.of(context);
    final result = await logo.getItems();
    if (!result.success) {
      throw Exception(
        result.error ??
            l10n.translate('field_sales.products_download_failed'),
      );
    }
    final list = result.asMapList();
    final db = await (await DatabaseService.getInstance()).getDatabase();
    final now = DateTime.now().toIso8601String();
    var done = 0;
    for (final row in list) {
      final code = (row['CODE'] ?? row['code'] ?? '').toString();
      if (code.isEmpty) continue;
      final name = (row['NAME'] ?? row['name'] ?? code).toString();
      final id = code;
      final data = {
        'id': id,
        'code': code,
        'name': name,
        'unit': row['UNIT'] ?? row['unit'] ?? 'AD',
        'price': (row['PRICE'] ?? row['price'] ?? 0) is num
            ? (row['PRICE'] ?? row['price'] as num).toDouble()
            : 0.0,
        'stock_quantity': (row['ONHAND'] ?? row['stock'] ?? row['STOCK_QTY'] ?? 0)
                is num
            ? ((row['ONHAND'] ?? row['stock'] ?? row['STOCK_QTY']) as num)
                .toDouble()
            : 0.0,
        'vat_rate': 20,
        'updated_at': now,
        'created_at': now,
      };
      try {
        await db.insert('products', data);
      } catch (_) {
        await db.update('products', data, where: 'id = ?', whereArgs: [id]);
      }
      done++;
      if (done % 20 == 0 && mounted) {
        setState(() {
          syncItems[index]['progress'] =
              (done / (list.isEmpty ? 1 : list.length)).clamp(0.1, 0.99);
        });
      }
    }
  }

  Future<void> _syncStock(LogoApiService logo, int index) async {
    final result = await logo.getInventoryReport();
    if (!result.success) {
      if (!mounted) return;
      setState(() => syncItems[index]['status'] = _stSkipped);
      return;
    }
    final list = result.asMapList();
    final db = await (await DatabaseService.getInstance()).getDatabase();
    for (final row in list) {
      final code = (row['CODE'] ?? row['code'] ?? row['item_code'] ?? '')
          .toString();
      if (code.isEmpty) continue;
      final qty = (row['ONHAND'] ?? row['stock'] ?? row['STOCK_QTY'] ?? 0);
      await db.update(
        'products',
        {
          'stock_quantity': qty is num ? qty.toDouble() : 0.0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'code = ? OR id = ?',
        whereArgs: [code, code],
      );
    }
  }

  Future<void> _syncBalances(LogoApiService logo, int index) async {
    final result = await logo.getBalances();
    if (!result.success) {
      if (!mounted) return;
      setState(() => syncItems[index]['status'] = _stSkipped);
      return;
    }
    final list = result.asMapList();
    final db = await (await DatabaseService.getInstance()).getDatabase();
    for (final row in list) {
      final code = (row['CODE'] ?? row['code'] ?? row['ARP_CODE'] ?? '')
          .toString();
      if (code.isEmpty) continue;
      final bal = row['BALANCE'] ?? row['balance'] ?? row['DEBIT'] ?? 0;
      await db.update(
        'customers',
        {
          'balance': bal is num ? bal.toDouble() : 0.0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'code = ? OR id = ?',
        whereArgs: [code, code],
      );
    }
  }

  Future<void> _uploadPending(int index) async {
    final l10n = AppLocalization.of(context);
    final pending = await JobQueueService().pendingCount();
    if (!mounted) return;

    // Kuyruk zaten boş — dens empty state, işlem yok
    if (pending == 0) {
      setState(() {
        syncItems[index]['status'] = _stSkipped;
        syncItems[index]['progress'] = 1.0;
        _sendEmptyMessageKey = DataTransferTriad.sendEmptyMessageKey(
          hadPending: false,
        );
      });
      return;
    }

    setState(() {
      syncItems[index]['status'] = _stTransferring;
      syncItems[index]['progress'] = 0.3;
    });
    await JobQueueService().processQueue();
    final left = await JobQueueService().pendingCount();
    if (left > 0) {
      throw Exception(
        l10n.translate(
          'field_sales.upload_queue_remaining',
          args: {'count': '$left'},
        ),
      );
    }
    if (!mounted) return;
    // Gönder sonrası kuyruk temiz — dens empty state
    setState(() {
      _sendEmptyMessageKey = DataTransferTriad.sendEmptyMessageKey(
        hadPending: true,
      );
    });
  }

  /// {@template _sync_product_images}
  /// Ürün resimleri: REST stub (+404 mock) → `products.image_url` güncelle.
  /// {@endtemplate}
  Future<void> _syncProductImages(int index) async {
    final l10n = AppLocalization.of(context);
    final service = widget.productImagesService ??
        ProductImagesServiceFactory.create();
    final result = await service.fetchImages();
    if (!result.success) {
      throw Exception(
        result.error ??
            l10n.translate(
              result.messageKey ??
                  'field_sales.product_images_download_failed',
            ),
      );
    }

    final images = result.images;
    if (images.isEmpty) {
      if (!mounted) return;
      setState(() {
        syncItems[index]['progress'] = 1.0;
        lastError = l10n.translate(
          result.messageKey ?? 'field_sales.product_images_none',
        );
      });
      return;
    }

    final db = await (await DatabaseService.getInstance()).getDatabase();
    final now = DateTime.now().toIso8601String();
    var updated = 0;
    var skipped = 0;
    for (var i = 0; i < images.length; i++) {
      final img = images[i];
      final changed = await db.update(
        'products',
        {
          'image_url': img.imageUrl,
          'updated_at': now,
        },
        where: 'code = ? OR id = ?',
        whereArgs: [img.productCode, img.productCode],
      );
      if (changed > 0) {
        updated++;
      } else {
        skipped++;
      }
      if ((i + 1) % 5 == 0 && mounted) {
        setState(() {
          syncItems[index]['progress'] =
              ((i + 1) / images.length).clamp(0.1, 0.99);
        });
      }
    }

    if (!mounted) return;
    final key = result.messageKey ??
        (result.usedMock
            ? 'field_sales.product_images_mock_done'
            : 'field_sales.product_images_sync_done');
    setState(() {
      syncItems[index]['progress'] = 1.0;
      lastError = l10n.translate(
        key,
        args: {
          'count': '$updated',
          'skipped': '$skipped',
        },
      );
    });
  }

  /// {@template _build_send_empty_state}
  /// Gönder sonrası / boş kuyruk dens empty state (sade metin).
  /// {@endtemplate}
  Widget _buildSendEmptyState(AppLocalization l10n) {
    final key = _sendEmptyMessageKey ?? DataTransferTriad.emptyQueueKey;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.translate(key),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// {@template _triad_button}
  /// Dens triad aksiyon butonu (mevcut stil token'ları).
  /// {@endtemplate}
  Widget _triadButton({
    required AppLocalization l10n,
    required DataTransferAction action,
    required IconData icon,
  }) {
    final isActive = isSyncing && activeAction == action;
    final label = isActive
        ? l10n.translate(DataTransferTriad.transferringKey)
        : l10n.translate(DataTransferTriad.labelKey(action));

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isSyncing ? null : () => _startAction(action),
        icon: Icon(isActive ? Icons.hourglass_top : icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF375A7F),
          padding: const EdgeInsets.symmetric(vertical: 10),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          l10n.translate('field_sales.data_transfer_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.translate('common.settings'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LogoRestSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF375A7F),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.translate('field_sales.overall_progress'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${(overallProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: overallProgress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                    minHeight: 10,
                  ),
                ),
                if (lastError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    lastError!,
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                _triadButton(
                  l10n: l10n,
                  action: DataTransferAction.send,
                  icon: Icons.cloud_upload,
                ),
                const SizedBox(height: 8),
                _triadButton(
                  l10n: l10n,
                  action: DataTransferAction.receive,
                  icon: Icons.cloud_download,
                ),
                const SizedBox(height: 8),
                _triadButton(
                  l10n: l10n,
                  action: DataTransferAction.productImages,
                  icon: Icons.image,
                ),
              ],
            ),
          ),
          Expanded(
            child: _sendEmptyMessageKey != null && !isSyncing
                ? _buildSendEmptyState(l10n)
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    cacheExtent: 500,
                    itemCount: syncItems.length,
                    itemBuilder: (context, index) {
                      final item = syncItems[index];
                      final status = item['status'] as String;
                      final done = status == _stDone;
                      final err = status == _stError;
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: done
                                ? Colors.green.shade100
                                : err
                                    ? Colors.red.shade100
                                    : const Color(0xFF375A7F).withOpacity(0.15),
                            child: Icon(
                              item['icon'] as IconData,
                              color: done
                                  ? Colors.green
                                  : err
                                      ? Colors.red
                                      : const Color(0xFF375A7F),
                            ),
                          ),
                          title: Text(
                            l10n.translate(item['titleKey'] as String),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_statusLabel(l10n, status)),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: (item['progress'] as num).toDouble(),
                                backgroundColor: Colors.grey.shade200,
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
    );
  }
}
