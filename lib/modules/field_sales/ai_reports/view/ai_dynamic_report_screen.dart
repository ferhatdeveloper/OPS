// Dosya Adı: ai_dynamic_report_screen.dart
// Açıklama: AI dinamik rapor dens — doğal dil → PostgREST spec → onay → kaydet
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/ai/features/ai_report_proposal_service.dart';
import '../../../../core/ai/features/postgrest_query_runner.dart';
import '../../../../core/ai/features/postgrest_query_spec.dart';
import '../../../../core/auth/app_user_role.dart';
import '../../../../core/auth/session_role_resolver.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../favorites/viewmodel/menu_favorites_store.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../model/ai_dynamic_report_definition.dart';
import '../viewmodel/ai_dynamic_report_store.dart';

/// {@template ai_dynamic_report_screen}
/// Yetkili kullanıcı AI ile PostgREST rapor önerisi oluşturur.
/// Route: `/field-sales/ai-reports`
///
/// Güvenlik: AI ham SQL üretse bile execute edilmez; yalnız allowlist
/// PostgREST GET spec onay sonrası çalışır.
/// {@endtemplate}
class AiDynamicReportScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/ai-reports';

  /// Test inject
  final AiReportProposalService? proposalService;

  /// Test inject
  final AiDynamicReportStore? store;

  /// Test inject
  final PostgrestQueryRunner? runner;

  /// {@macro ai_dynamic_report_screen}
  const AiDynamicReportScreen({
    Key? key,
    this.proposalService,
    this.store,
    this.runner,
  }) : super(key: key);

  @override
  State<AiDynamicReportScreen> createState() => _AiDynamicReportScreenState();
}

class _AiDynamicReportScreenState extends State<AiDynamicReportScreen> {
  late final AiReportProposalService _proposal =
      widget.proposalService ?? AiReportProposalService();
  late final AiDynamicReportStore _store =
      widget.store ?? AiDynamicReportStore();
  late final PostgrestQueryRunner _runner =
      widget.runner ?? PostgrestQueryRunner();

  final _prompt = TextEditingController();
  List<AiDynamicReportDefinition> _saved = const [];
  AiReportProposal? _pending;
  List<Map<String, dynamic>>? _previewRows;
  bool _busy = false;
  bool _allowed = false;
  String? _statusKey;
  String? _localNoteKey;
  String? _localFilterNoteKey;
  bool _usedLocalPreview = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  String _t(String key) => AppLocalization.of(context).translate(key);

  bool _isDenyKey(String key) {
    return key == 'field_sales.ai_reports.err_table' ||
        key == 'field_sales.ai_reports.err_sanitize' ||
        key == 'field_sales.ai_reports.err_sql_forbidden' ||
        key == 'field_sales.ai_reports.err_rpc' ||
        key == 'field_sales.ai_reports.err_select';
  }

  Future<void> _bootstrap() async {
    final role = await const SessionRoleResolver().resolve();
    final allowed =
        role == AppUserRole.admin ||
        role == AppUserRole.supervisor ||
        role == AppUserRole.unknown;
    if (!mounted) return;
    setState(() => _allowed = allowed);
    if (allowed) {
      await _reloadSaved();
    }
  }

  Future<void> _reloadSaved() async {
    final list = await _store.listAll();
    if (!mounted) return;
    setState(() => _saved = list);
  }

  Future<void> _propose() async {
    final text = _prompt.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _statusKey = null;
      _pending = null;
      _previewRows = null;
      _localNoteKey = null;
      _localFilterNoteKey = null;
      _usedLocalPreview = false;
    });
    final r = await _proposal.propose(text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!r.isOk) {
        _statusKey = r.l10nKey ?? 'ai.request_failed';
      } else {
        _pending = r.proposal;
      }
    });
  }

  Future<void> _preview() async {
    final p = _pending;
    if (p == null || _busy) return;
    setState(() {
      _busy = true;
      _statusKey = null;
      _localNoteKey = null;
      _localFilterNoteKey = null;
      _usedLocalPreview = false;
    });
    final r = await _runner.run(p.query, reportTitle: p.title);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!r.ok) {
        _statusKey = r.errorKey ?? 'field_sales.ai_reports.err_http';
        _previewRows = null;
      } else {
        _previewRows = r.rows;
        _usedLocalPreview = r.usedLocal;
        _localNoteKey = r.noteKey;
        _localFilterNoteKey = r.localFilterNoteKey;
      }
    });
  }

  Future<void> _confirmSave({required bool favorite}) async {
    final p = _pending;
    if (p == null || _busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('field_sales.ai_reports.confirm_title')),
        content: Text(
          '${p.title}\n'
          '${_t('field_sales.ai_reports.confirm_body')}\n'
          '${p.query.table} · ${p.query.select.join(', ')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('field_sales.ai_reports.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t('field_sales.ai_reports.confirm_save')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final def = await _store.saveProposal(
      proposal: p,
      addFavoriteShortcut: favorite,
    );
    if (favorite) {
      try {
        final svc = await DatabaseService.getInstance();
        final db = await svc.getDatabase();
        await MenuFavoritesStore(db).add('sub_rep_ai_dynamic');
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _pending = null;
      _previewRows = null;
      _statusKey = 'field_sales.ai_reports.saved';
    });
    await _reloadSaved();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${def.title} · ${_t(_statusKey!)}')),
    );
  }

  Future<void> _runSaved(AiDynamicReportDefinition def) async {
    setState(() {
      _busy = true;
      _statusKey = null;
      _localNoteKey = null;
      _localFilterNoteKey = null;
      _usedLocalPreview = false;
      _pending = AiReportProposal(
        title: def.title,
        titleKey: def.titleKey,
        query: def.query,
        columns: def.columns,
      );
    });
    final r = await _runner.run(def.query, reportTitle: def.title);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!r.ok) {
        _statusKey = r.errorKey ?? 'field_sales.ai_reports.err_http';
        _previewRows = null;
      } else {
        _previewRows = r.rows;
        _usedLocalPreview = r.usedLocal;
        _localNoteKey = r.noteKey;
        _localFilterNoteKey = r.localFilterNoteKey;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _t('field_sales.stubs.ai_dynamic_report');
    if (!_allowed) {
      return Scaffold(
        appBar: FieldSalesDensAppBar(title: title),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
          child: Text(
            _t('field_sales.ai_reports.admin_only'),
            style: const TextStyle(fontSize: 13),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: FieldSalesDensAppBar(title: title),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: TextField(
              controller: _prompt,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                isDense: true,
                hintText: _t('field_sales.ai_reports.prompt_hint'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _propose(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
            child: SizedBox(
              height: 40,
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _propose,
                child: Text(
                  _busy
                      ? _t('ai.analyzing')
                      : _t('field_sales.ai_reports.propose'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
          if (_statusKey != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  child: Text(
                    _isDenyKey(_statusKey!)
                        ? '${_t(_statusKey!)}\n'
                            '${_t('field_sales.ai_reports.err_denied_hint')}'
                        : _t(_statusKey!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          if (_pending != null) _buildProposalCard(),
          if (_usedLocalPreview && _localNoteKey != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FieldSalesDensChip(
                  label: _t(_localNoteKey!),
                  selected: true,
                  onTap: null,
                  fontSize: 11,
                ),
              ),
            ),
          if (_localFilterNoteKey != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _t(_localFilterNoteKey!),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          if (_previewRows != null) _buildPreview(),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                _t('field_sales.ai_reports.saved_list'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: _saved.isEmpty
                ? Center(
                    child: Text(
                      _t('field_sales.ai_reports.empty'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    itemCount: _saved.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final d = _saved[i];
                      return InkWell(
                        onTap: _busy ? null : () => _runSaved(d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: FieldSalesDensAppBar.primaryColor
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${d.query.table} · ${d.query.select.join(', ')}',
                                style: const TextStyle(fontSize: 11),
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

  Widget _buildProposalCard() {
    final p = _pending!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: FieldSalesDensAppBar.primaryColor.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              'GET /${p.query.table}?select=${p.query.select.join(',')}',
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                OutlinedButton(
                  onPressed: _busy ? null : _preview,
                  child: Text(
                    _t('field_sales.ai_reports.preview'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                FilledButton(
                  onPressed: _busy ? null : () => _confirmSave(favorite: false),
                  child: Text(
                    _t('field_sales.ai_reports.confirm_save'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                OutlinedButton(
                  onPressed:
                      _busy ? null : () => _confirmSave(favorite: true),
                  child: Text(
                    _t('field_sales.ai_reports.save_favorite'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final rows = _previewRows!;
    final cols = _pending?.columns ??
        (rows.isEmpty
            ? <AiReportLayoutColumn>[]
            : rows.first.keys
                .map((k) => AiReportLayoutColumn(id: k, labelKey: k))
                .toList());
    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
        itemCount: rows.length.clamp(0, 50),
        separatorBuilder: (_, __) => const SizedBox(height: 2),
        itemBuilder: (context, i) {
          final row = rows[i];
          final text = cols
              .map((c) => '${c.id}:${row[c.id] ?? ''}')
              .join(' · ');
          return Text(text, style: const TextStyle(fontSize: 11));
        },
      ),
    );
  }
}
