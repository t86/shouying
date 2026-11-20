import 'dart:async';

import 'package:card_table/src/business_route_observer.dart';
import 'package:card_table/src/cashier_profit_loss.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:foundation/foundation.dart';

typedef CashierProfitLossLoad =
    Future<Result<List<CashierProfitLossRecord>>> Function();
typedef CashierProfitLossSubmit = Future<Result<void>> Function(
  CashierProfitLossDraft,
  bool Function(),
);

final class CashierProfitLossScreen extends StatefulWidget {
  const CashierProfitLossScreen({
    required this.catalog,
    required this.canOperate,
    required this.load,
    required this.submit,
    super.key,
  });
  final ValueListenable<CashierProfitLossCatalog> catalog;
  final ValueListenable<bool> canOperate;
  final CashierProfitLossLoad load;
  final CashierProfitLossSubmit submit;
  @override
  State<CashierProfitLossScreen> createState() =>
      _CashierProfitLossScreenState();
}

class _CashierProfitLossScreenState extends State<CashierProfitLossScreen> {
  List<CashierProfitLossRecord> _records = [];
  bool _busy = false, _editing = false, _closed = false;
  String? _error;
  int _version = 0, _epoch = 0;
  bool get _allowed => !_closed && widget.canOperate.value;
  @override
  void initState() {
    super.initState();
    widget.canOperate.addListener(_access);
    unawaited(_load());
  }

  void _access() {
    // Invalidate requests synchronously, including false/true pulses in one frame.
    _version++;
    if (!_allowed) {
      _epoch++;
    }
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_load());
      });
      return;
    }
    unawaited(_load());
  }

  Future<void> _load() async {
    final version = ++_version;
    if (!mounted) return;
    if (!_allowed) {
      setState(() {
        _records = [];
        _busy = false;
        _error = '连接或权限已变化，请重新打开';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.load();
      if (!mounted || version != _version || !_allowed) return;
      setState(() {
        _records = result.valueOrNull ?? [];
        _error = result.failureOrNull?.safeMessage;
      });
    } on Object {
      if (mounted && version == _version && _allowed) {
        setState(() => _error = '读取盘盈盘亏记录失败');
      }
    } finally {
      if (mounted && version == _version) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    if (_editing || !_allowed) return;
    _editing = true;
    final epoch = _epoch;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        settings: const RouteSettings(
          name: BusinessRouteObserver.childRouteName,
        ),
        builder: (_) => _ProfitLossEditor(
          catalog: widget.catalog,
          canOperate: widget.canOperate,
          submit: widget.submit,
          ownerCurrent: () => mounted && _allowed && epoch == _epoch,
        ),
      ),
    );
    _editing = false;
    if (result == true && mounted && _allowed && epoch == _epoch) await _load();
  }

  @override
  void dispose() {
    _closed = true;
    _epoch++;
    _version++;
    widget.canOperate.removeListener(_access);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) {
        _closed = true;
        _epoch++;
        _version++;
      }
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('盘盈盘亏')),
      body: Column(
        children: [
          Wrap(
            spacing: 12,
            children: [
              FilledButton(
                onPressed: _allowed ? _edit : null,
                child: const Text('添加盘盈盘亏单'),
              ),
              TextButton(
                onPressed: _allowed && !_busy ? _load : null,
                child: const Text('刷新'),
              ),
            ],
          ),
          if (_error != null) Text(_error!),
          Expanded(
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (_records.isEmpty) const Center(child: Text('暂无记录')),
                      for (final record in _records)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '出品库：${record.library}　操作人：${record.operatorName}　操作时间：${record.time}',
                                ),
                                for (final (index, row)
                                    in record.entries.indexed)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      '${index + 1}. ${row.name}　${row.firstCategory} / ${row.secondCategory}　盘盈：${row.profit}　盘亏：${row.loss}',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

class _ProfitLossEditor extends StatefulWidget {
  const _ProfitLossEditor({
    required this.catalog,
    required this.canOperate,
    required this.submit,
    required this.ownerCurrent,
  });
  final ValueListenable<CashierProfitLossCatalog> catalog;
  final ValueListenable<bool> canOperate;
  final CashierProfitLossSubmit submit;
  final bool Function() ownerCurrent;
  @override
  State<_ProfitLossEditor> createState() => _ProfitLossEditorState();
}

class _ProfitRow {
  _ProfitRow(this.id);
  final int id;
  String? productId;
  final profit = TextEditingController(), loss = TextEditingController();
  void dispose() {
    profit.dispose();
    loss.dispose();
  }
}

class _ProfitLossEditorState extends State<_ProfitLossEditor> {
  late final CashierProfitLossCatalog _catalog;
  final _rows = <_ProfitRow>[];
  int _nextId = 0, _epoch = 0;
  String? _library, _error;
  final _search = TextEditingController();
  bool _expired = false, _closed = false, _busy = false, _uncertain = false;
  bool get _valid =>
      mounted &&
      !_closed &&
      !_expired &&
      widget.canOperate.value &&
      widget.ownerCurrent();
  @override
  void initState() {
    super.initState();
    _catalog = widget.catalog.value;
    _resetRows();
    widget.catalog.addListener(_metadataChanged);
    widget.canOperate.addListener(_accessChanged);
  }

  void _resetRows() {
    _search.clear();
    for (final row in _rows) {
      row.dispose();
    }
    _rows.clear();
    _nextId = 0;
    _rows.addAll(List.generate(3, (_) => _ProfitRow(_nextId++)));
  }

  void _metadataChanged() {
    if (!mounted) return;
    _expired = true;
    _epoch++;
    _busy = false;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  void _accessChanged() {
    if (!widget.canOperate.value) _metadataChanged();
  }

  void _close() {
    _closed = true;
    _epoch++;
  }

  @override
  void dispose() {
    _close();
    widget.catalog.removeListener(_metadataChanged);
    widget.canOperate.removeListener(_accessChanged);
    _search.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  int? _count(String text) =>
      text.trim().isEmpty ? 0 : int.tryParse(text.trim());
  Future<void> _submit() async {
    if (!_valid || _busy || _uncertain) return;
    final selected = _rows.where((r) => r.productId != null).toList();
    if (_library == null ||
        !_catalog.libraries.containsKey(_library) ||
        selected.isEmpty) {
      setState(() => _error = '请选择出品库和商品');
      return;
    }
    final products = _catalog.productsByLibrary[_library] ?? [];
    final entries = <CashierProfitLossEntry>[];
    for (final row in selected) {
      final profit = _count(row.profit.text), loss = _count(row.loss.text);
      if (profit == null ||
          loss == null ||
          profit.abs() > 9007199254740991 ||
          loss.abs() > 9007199254740991 ||
          !products.any((p) => p.id == row.productId)) {
        setState(() => _error = '请选择有效商品，盘盈盘亏数量须为整数');
        return;
      }
      entries.add(
        CashierProfitLossEntry(
          productId: row.productId!,
          profit: profit,
          loss: loss,
        ),
      );
    }
    final epoch = _epoch;
    bool current() => _valid && epoch == _epoch;
    final draft = CashierProfitLossDraft(
      libraryId: _library!,
      entries: List.unmodifiable(entries),
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    Result<void> result;
    try {
      result = await widget.submit(draft, current);
    } on Object {
      result = const FailureResult(
        AppFailure(
          kind: FailureKind.unknown,
          code: 'profit_loss.unknown',
          safeMessage: '结果尚未确认',
        ),
      );
    }
    if (!mounted || !current()) return;
    final failure = result.failureOrNull;
    if (failure == null) {
      final route = ModalRoute.of(context);
      _close();
      if (route != null) Navigator.of(context).removeRoute(route, true);
      return;
    }
    setState(() {
      _busy = false;
      _uncertain = failure.kind != FailureKind.business;
      _error = _uncertain
          ? '操作结果尚未确认，请核实服务端记录后重新打开，勿重复提交'
          : failure.safeMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final editable = _valid && !_busy && !_uncertain;
    final products = _catalog.productsByLibrary[_library] ?? [];
    return PopScope<bool>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('添加盘盈盘亏单')),
        body: Column(
          children: [
            if (_expired) const Text('出品库、商品或权限已变化，请返回重新打开'),
            if (_error != null) Text(_error!),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<String>(
                    key: const ValueKey('profit-library'),
                    initialValue: _library,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '出品库'),
                    items: [
                      for (final entry in _catalog.libraries.entries)
                        DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                    ],
                    onChanged: !editable
                        ? null
                        : (value) => setState(() {
                            _library = value;
                            _resetRows();
                          }),
                  ),
                  TextField(
                    key: const ValueKey('profit-product-search'),
                    controller: _search,
                    enabled: editable,
                    decoration: const InputDecoration(labelText: '搜索商品'),
                    onChanged: (_) => setState(() {}),
                  ),
                  for (final row in _rows)
                    Card(
                      key: ValueKey('profit-row-${row.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text('${_rows.indexOf(row) + 1}'),
                                const Spacer(),
                                IconButton(
                                  key: ValueKey('profit-add-${row.id}'),
                                  tooltip: '增加一行',
                                  onPressed: editable
                                      ? () => setState(
                                          () =>
                                              _rows.add(_ProfitRow(_nextId++)),
                                        )
                                      : null,
                                  icon: const Icon(Icons.add),
                                ),
                                IconButton(
                                  key: ValueKey('profit-remove-${row.id}'),
                                  tooltip: '删除此行',
                                  onPressed: editable && _rows.length > 1
                                      ? () => setState(() {
                                          _rows.remove(row);
                                          row.dispose();
                                        })
                                      : null,
                                  icon: const Icon(Icons.remove),
                                ),
                              ],
                            ),
                            DropdownButtonFormField<String>(
                              key: ValueKey('profit-product-${row.id}'),
                              initialValue: row.productId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: '商品',
                              ),
                              items: [
                                for (final product in products)
                                  if (product.id == row.productId ||
                                      product.name.toLowerCase().contains(
                                        _search.text.trim().toLowerCase(),
                                      ))
                                    DropdownMenuItem(
                                      value: product.id,
                                      child: Text(product.name),
                                    ),
                              ],
                              onChanged: editable
                                  ? (value) =>
                                        setState(() => row.productId = value)
                                  : null,
                            ),
                            for (final product in products.where(
                              (p) => p.id == row.productId,
                            ))
                              Text(
                                '${product.firstCategory} / ${product.secondCategory}',
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    key: ValueKey('profit-count-${row.id}'),
                                    controller: row.profit,
                                    enabled: editable,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          signed: true,
                                        ),
                                    decoration: const InputDecoration(
                                      labelText: '盘盈数量（空为0）',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    key: ValueKey('loss-count-${row.id}'),
                                    controller: row.loss,
                                    enabled: editable,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          signed: true,
                                        ),
                                    decoration: const InputDecoration(
                                      labelText: '盘亏数量（空为0）',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: editable ? _submit : null,
                    child: Text(_busy ? '提交中…' : '确定'),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
