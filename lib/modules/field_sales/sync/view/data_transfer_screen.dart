// Dosya Adı: data_transfer_screen.dart
// Açıklama: Güncelleme dens triad — Gönder / Al / Ürün Resimleri (+ Aktarılıyor)
// Oluşturulma Tarihi: 2026-02-22
// Geliştirici: EXFIN OPS Team
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../core/logo/logo_connection_health.dart';
import '../../../../core/logo/logo_tiger.dart';
import '../../../../core/services/logo_api_service.dart';
import '../../../../service/database_service.dart';
import '../../../../service/job_queue_service.dart';
import '../model/data_transfer_triad.dart';
import '../model/logo_pull_source.dart';
import '../service/logo_pull_source_runner.dart';
import '../service/logo_pull_state_store.dart';
import '../service/product_images_service.dart';
import 'logo_connection_status_icon.dart';
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
    this.pullRunner,
    this.pullStateStore,
    this.tigerEnabledOverride,
    this.healthChecker,
  }) : super(key: key);

  /// [productImagesService]: Ürün resmi servisi (test enjeksiyonu)
  final ProductImagesService? productImagesService;

  /// [pullRunner]: Kaynak bazlı Logo indirme koşucusu (test enjeksiyonu)
  final LogoPullSourceRunner? pullRunner;

  /// [pullStateStore]: Satır durumu deposu (test enjeksiyonu)
  final LogoPullStateStore? pullStateStore;

  /// [tigerEnabledOverride]: Tiger REST modu (test enjeksiyonu)
  final bool? tigerEnabledOverride;

  /// [healthChecker]: Bağlantı sağlık denetleyicisi (test enjeksiyonu)
  final LogoConnectionHealthChecker? healthChecker;

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

  /// [_tigerEnabled]: Tiger Objects REST modu açık mı
  bool _tigerEnabled = false;

  /// [_pullStateStore]: Kaynak bazlı son indirme durumu
  late final LogoPullStateStore _pullStateStore;

  /// [_pullRunner]: Tek kaynak indirme koşucusu
  late final LogoPullSourceRunner _pullRunner;

  /// [_pullStates]: Kaynak → son indirme durumu
  Map<LogoPullSource, LogoPullSourceState> _pullStates = {};

  /// [_busyRowIndex]: Tek satır indirilirken aktif satır
  int? _busyRowIndex;

  /// [_sourceIcons]: Kaynak → satır ikonu (mevcut görsel dil)
  static const Map<LogoPullSource, IconData> _sourceIcons = {
    LogoPullSource.customers: Icons.people,
    LogoPullSource.products: Icons.shopping_bag,
    LogoPullSource.stock: Icons.inventory,
    LogoPullSource.balances: Icons.account_balance_wallet,
    LogoPullSource.warehouses: Icons.warehouse,
    LogoPullSource.salesmen: Icons.badge,
    LogoPullSource.orders: Icons.receipt_long,
  };

  @override
  void initState() {
    super.initState();
    _pullStateStore = widget.pullStateStore ?? const LogoPullStateStore();
    _pullRunner =
        widget.pullRunner ?? LogoPullSourceRunner(stateStore: _pullStateStore);
    syncItems = _buildItems(DataTransferAction.receive);
    _bootstrap();
  }

  /// {@template _bootstrap}
  /// Bağlantı modunu ve kaynak bazlı son indirme durumlarını yükler.
  /// {@endtemplate}
  Future<void> _bootstrap() async {
    var enabled = widget.tigerEnabledOverride ?? false;
    if (widget.tigerEnabledOverride == null) {
      try {
        enabled = await LogoTigerSettingsStore().isEnabled();
      } catch (e) {
        debugPrint('DataTransferScreen tiger modu okunamadı: $e');
      }
    }
    Map<LogoPullSource, LogoPullSourceState> states = {};
    try {
      states = await _pullStateStore.loadAll();
    } catch (e) {
      debugPrint('DataTransferScreen indirme durumu okunamadı: $e');
    }
    if (!mounted) return;
    setState(() {
      _tigerEnabled = enabled;
      _pullStates = states;
      syncItems = _buildItems(activeAction ?? DataTransferAction.receive);
    });
  }

  /// {@template _build_items}
  /// Aksiyon için dens liste satırlarını üretir.
  ///
  /// "Al" aksiyonunda her Logo veri türü ayrı satır olur; satırlar aktif
  /// bağlantı türünün gerçekten desteklediği kaynaklardan üretilir.
  /// {@endtemplate}
  List<Map<String, dynamic>> _buildItems(DataTransferAction action) {
    if (action == DataTransferAction.receive) {
      return LogoPullSourceCatalog.forMode(tigerEnabled: _tigerEnabled)
          .map(_buildSourceItem)
          .toList();
    }

    final defs = <String, Map<String, dynamic>>{
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

    return DataTransferTriad.itemKeys(action)
        .where(defs.containsKey)
        .map((key) {
      final def = defs[key]!;
      return <String, dynamic>{
        ...def,
        'source': null,
        'progress': 0.0,
        'status': _stPending,
        'count': null,
        'lastAt': null,
      };
    }).toList();
  }

  /// {@template _build_source_item}
  /// Tek Logo veri türü için satır haritası üretir (durum + son güncelleme).
  /// {@endtemplate}
  Map<String, dynamic> _buildSourceItem(LogoPullSource source) {
    final state = _pullStates[source];
    return <String, dynamic>{
      'key': LogoPullSourceCatalog.storageKey(source),
      'source': source,
      'titleKey': LogoPullSourceCatalog.titleKey(source),
      'icon': _sourceIcons[source] ?? Icons.cloud_download,
      'progress': 0.0,
      'status': _stPending,
      'count': state?.recordCount,
      'lastAt': state?.lastSuccessAt,
    };
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
    final useTiger = _tigerEnabled;

    // Tiger REST açıkken Al → her veri türü sırayla, satır bazlı durum ile
    if (useTiger && action == DataTransferAction.receive) {
      await _runTigerReceive();
      return;
    }

    if (action != DataTransferAction.productImages) {
      if (useTiger) {
        await LogoTigerRestClient().ensureReady();
      } else {
        await logo.ensureReady();
      }
    }

    for (int i = 0; i < syncItems.length; i++) {
      final item = syncItems[i];
      final source = item['source'] as LogoPullSource?;
      setState(() {
        item['status'] = _stTransferring;
        item['progress'] = 0.1;
      });

      try {
        final count = await _runLegacyItem(logo, i);
        if (!mounted) return;
        final skipped = item['status'] == _stSkipped;
        setState(() {
          if (!skipped) {
            item['status'] = _stDone;
            item['progress'] = 1.0;
            if (count != null) {
              item['count'] = count;
              item['lastAt'] = DateTime.now().toUtc();
            }
          }
          overallProgress = (i + 1) / syncItems.length;
        });
        if (!skipped && source != null) {
          await _recordState(source, ok: true, count: count);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          item['status'] = _stError;
          lastError = e.toString();
          overallProgress = (i + 1) / syncItems.length;
        });
        if (source != null) {
          await _recordState(source, ok: false, error: e.toString());
        }
      }
    }

    if (!mounted) return;
    setState(() {
      isSyncing = false;
      activeAction = null;
    });
  }

  /// {@template _run_legacy_item}
  /// ExfinApi middleware satırını çalıştırır.
  ///
  /// Parametreler:
  /// - [logo]: ExfinApi servis örneği
  /// - [index]: Satır indeksi
  ///
  /// Dönüş değeri:
  /// - [int]: İşlenen kayıt sayısı; sayılamıyor / atlandıysa `null`
  /// {@endtemplate}
  Future<int?> _runLegacyItem(LogoApiService logo, int index) async {
    switch (syncItems[index]['key']) {
      case 'customers':
        return _syncCustomers(logo, index);
      case 'products':
        return _syncProducts(logo, index);
      case 'stock':
        return _syncStock(logo, index);
      case 'balances':
        return _syncBalances(logo, index);
      case 'upload':
        await _uploadPending(index);
        return null;
      case 'product_images':
        await _syncProductImages(index);
        return null;
    }
    return null;
  }

  /// {@template _run_tiger_receive}
  /// Tiger REST modunda her veri türünü sırayla indirir.
  ///
  /// Genel ilerleme satır sayısına göre ilerler; bir satırın hatası diğer
  /// satırları durdurmaz.
  /// {@endtemplate}
  Future<void> _runTigerReceive() async {
    for (int i = 0; i < syncItems.length; i++) {
      final source = syncItems[i]['source'] as LogoPullSource?;
      if (source == null) continue;
      if (!mounted) return;
      setState(() {
        syncItems[i]['status'] = _stTransferring;
        syncItems[i]['progress'] = 0.2;
      });

      final outcome = await _pullRunner.run(source);
      if (!mounted) return;
      setState(() {
        _applyOutcome(i, outcome);
        overallProgress = (i + 1) / syncItems.length;
      });
    }

    if (!mounted) return;
    setState(() {
      isSyncing = false;
      activeAction = null;
    });
  }

  /// {@template _download_one}
  /// Tek veri türünü kendi başına indirir (satır aksiyonu).
  /// {@endtemplate}
  Future<void> _downloadOne(int index) async {
    if (isSyncing) return;
    final source = syncItems[index]['source'] as LogoPullSource?;
    if (source == null) return;

    setState(() {
      isSyncing = true;
      activeAction = DataTransferAction.receive;
      _busyRowIndex = index;
      lastError = null;
      _sendEmptyMessageKey = null;
      syncItems[index]['status'] = _stTransferring;
      syncItems[index]['progress'] = 0.2;
    });

    try {
      if (_tigerEnabled && LogoPullSourceCatalog.supportsTiger(source)) {
        final outcome = await _pullRunner.run(source);
        if (!mounted) return;
        setState(() => _applyOutcome(index, outcome));
      } else {
        final logo = LogoApiService();
        await logo.ensureReady();
        final count = await _runLegacyItem(logo, index);
        if (!mounted) return;
        final skipped = syncItems[index]['status'] == _stSkipped;
        setState(() {
          if (!skipped) {
            syncItems[index]['status'] = _stDone;
            syncItems[index]['progress'] = 1.0;
            if (count != null) {
              syncItems[index]['count'] = count;
              syncItems[index]['lastAt'] = DateTime.now().toUtc();
            }
          }
        });
        if (!skipped) {
          await _recordState(source, ok: true, count: count);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        syncItems[index]['status'] = _stError;
        syncItems[index]['progress'] = 1.0;
        lastError = e.toString();
      });
      await _recordState(source, ok: false, error: e.toString());
    } finally {
      if (mounted) {
        setState(() {
          isSyncing = false;
          activeAction = null;
          _busyRowIndex = null;
        });
      }
    }
  }

  /// {@template _apply_outcome}
  /// Koşucu sonucunu satıra yazar (setState içinde çağrılır).
  /// {@endtemplate}
  void _applyOutcome(int index, LogoPullOutcome outcome) {
    final l10n = AppLocalization.of(context);
    final item = syncItems[index];
    item['status'] = outcome.ok ? _stDone : _stError;
    item['progress'] = 1.0;
    if (outcome.ok) {
      item['count'] = outcome.upserted;
      item['lastAt'] = DateTime.now().toUtc();
    } else {
      final key = outcome.errorKey;
      lastError = key != null
          ? l10n.translate(key)
          : (outcome.error ?? outcome.message ?? '');
    }
  }

  /// {@template _record_state}
  /// ExfinApi satırının son durumunu kalıcı depoya yazar.
  /// {@endtemplate}
  Future<void> _recordState(
    LogoPullSource source, {
    required bool ok,
    int? count,
    String? error,
  }) async {
    try {
      await _pullStateStore.record(
        source,
        ok: ok,
        recordCount: count,
        error: error,
      );
    } catch (e) {
      debugPrint('DataTransferScreen indirme durumu yazılamadı: $e');
    }
  }

  /// Cari indirir; yazılan kayıt sayısını döndürür.
  Future<int> _syncCustomers(LogoApiService logo, int index) async {
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
    return done;
  }

  /// Ürün indirir; yazılan kayıt sayısını döndürür.
  Future<int> _syncProducts(LogoApiService logo, int index) async {
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
    return done;
  }

  /// Stok günceller; kaynak yoksa satır atlanır (`null`).
  Future<int?> _syncStock(LogoApiService logo, int index) async {
    final result = await logo.getInventoryReport();
    if (!result.success) {
      if (!mounted) return null;
      setState(() => syncItems[index]['status'] = _stSkipped);
      return null;
    }
    final list = result.asMapList();
    final db = await (await DatabaseService.getInstance()).getDatabase();
    var updated = 0;
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
      updated++;
    }
    return updated;
  }

  /// Bakiye günceller; kaynak yoksa satır atlanır (`null`).
  Future<int?> _syncBalances(LogoApiService logo, int index) async {
    final result = await logo.getBalances();
    if (!result.success) {
      if (!mounted) return null;
      setState(() => syncItems[index]['status'] = _stSkipped);
      return null;
    }
    final list = result.asMapList();
    final db = await (await DatabaseService.getInstance()).getDatabase();
    var updated = 0;
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
      updated++;
    }
    return updated;
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

  /// {@template _row_status_line}
  /// Satır durumu + kayıt sayısı metni.
  /// {@endtemplate}
  String _rowStatusLine(AppLocalization l10n, Map<String, dynamic> item) {
    final status = _statusLabel(l10n, item['status'] as String);
    final count = item['count'];
    if (count is! int) return status;
    final countLabel = l10n.translate(
      'field_sales.logo_pull_record_count',
      args: {'count': '$count'},
    );
    return '$status · $countLabel';
  }

  /// {@template _row_last_update_line}
  /// Satırın son başarılı güncelleme zamanı metni.
  /// {@endtemplate}
  String _rowLastUpdateLine(AppLocalization l10n, Map<String, dynamic> item) {
    final lastAt = item['lastAt'];
    if (lastAt is! DateTime) {
      return l10n.translate('field_sales.logo_pull_never');
    }
    return l10n.translate(
      'field_sales.logo_pull_last_update',
      args: {
        'time': DateFormat('dd.MM.yyyy HH:mm').format(lastAt.toLocal()),
      },
    );
  }

  /// {@template _row_action}
  /// Satır bazlı indirme aksiyonu (yalnızca Logo veri türü satırları).
  /// {@endtemplate}
  Widget? _rowAction(
    AppLocalization l10n,
    Map<String, dynamic> item,
    int index,
  ) {
    if (item['source'] is! LogoPullSource) return null;
    if (_busyRowIndex == index) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return IconButton(
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      tooltip: l10n.translate('field_sales.logo_pull_download_one'),
      icon: const Icon(Icons.cloud_download_outlined),
      onPressed: isSyncing ? null : () => _downloadOne(index),
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
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: AppBar(
        title: Text(
          l10n.translate('field_sales.data_transfer_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          LogoConnectionStatusIcon(checker: widget.healthChecker),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.translate('common.settings'),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LogoRestSettingsScreen(),
                ),
              );
              if (mounted) await _bootstrap();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
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
                              Text(_rowStatusLine(l10n, item)),
                              Text(
                                _rowLastUpdateLine(l10n, item),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: (item['progress'] as num).toDouble(),
                                backgroundColor: Colors.grey.shade200,
                              ),
                            ],
                          ),
                          trailing: _rowAction(l10n, item, index),
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
