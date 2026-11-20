import 'dart:async';

import 'package:card_table/src/cashier_voucher_records.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:foundation/foundation.dart';

typedef CashierVoucherLoad =
    Future<Result<List<CashierVoucherRecord>>> Function(CashierVoucherQuery);
typedef CashierVoucherCancel = Future<Result<void>> Function(
  String,
  bool Function(),
);
typedef CashierVoucherExport = Future<Result<String>> Function(
  CashierVoucherQuery,
  bool Function(),
);

final class CashierVoucherRecordsScreen extends StatefulWidget {
  const CashierVoucherRecordsScreen({
    required this.canOperate,
    required this.load,
    required this.cancel,
    required this.export,
    super.key,
  });
  final ValueListenable<bool> canOperate;
  final CashierVoucherLoad load;
  final CashierVoucherCancel cancel;
  final CashierVoucherExport export;
  @override
  State<CashierVoucherRecordsScreen> createState() =>
      _CashierVoucherRecordsScreenState();
}

class _CashierVoucherRecordsScreenState
    extends State<CashierVoucherRecordsScreen> {
  final _keyword = TextEditingController();
  final _uncertain = <String>{};
  List<CashierVoucherRecord> _rows = [];
  int _type = 0, _epoch = 0, _version = 0;
  bool _loading = false, _writing = false, _exporting = false, _closed = false;
  String? _message;
  bool get _allowed => !_closed && widget.canOperate.value;
  bool get _busy => _loading || _writing || _exporting;
  CashierVoucherQuery get _query =>
      CashierVoucherQuery(typeId: _type, keyword: _keyword.text);
  bool _current(int epoch) => mounted && _allowed && epoch == _epoch;
  void _update(VoidCallback change) {
    change();
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    widget.canOperate.addListener(_access);
    unawaited(_load());
  }

  void _access() {
    if (!_allowed) {
      _epoch++;
      _version++;
      if (mounted) {
        _update(() {
          _rows = [];
          _loading = false;
          _message = '连接或权限已变化，请重新查询';
        });
      }
    } else {
      unawaited(_load());
    }
  }

  @override
  void didUpdateWidget(CashierVoucherRecordsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.canOperate, oldWidget.canOperate)) {
      oldWidget.canOperate.removeListener(_access);
      widget.canOperate.addListener(_access);
      _epoch++;
      _version++;
      _rows = [];
      unawaited(_load());
    }
  }

  void _close() {
    _closed = true;
    _epoch++;
    _version++;
  }

  @override
  void dispose() {
    _close();
    widget.canOperate.removeListener(_access);
    _keyword.dispose();
    super.dispose();
  }

  Future<void> _load({bool verified = false}) async {
    if (!_allowed) return;
    final epoch = _epoch, version = ++_version;
    final query = _query;
    _update(() {
      _loading = true;
      _message = null;
    });
    try {
      final result = await widget.load(query);
      if (!_current(epoch) || version != _version) return;
      setState(() {
        _rows = result.valueOrNull ?? [];
        _message = result.failureOrNull?.safeMessage;
        if (verified && result.failureOrNull == null) _uncertain.clear();
        if (_message == null && _uncertain.isNotEmpty) {
          _message = '退券结果尚未确认，请点击查询核实，勿重复退券';
        }
      });
    } on Object {
      if (_current(epoch) && version == _version) {
        setState(() => _message = '读取卡券记录失败');
      }
    } finally {
      if (mounted && version == _version) setState(() => _loading = false);
    }
  }

  Future<void> _cancel(CashierVoucherRecord row) async {
    if (!_allowed || _busy || !row.canCancel || _uncertain.contains(row.id)) {
      return;
    }
    final epoch = _epoch;
    final query = _query;
    final fingerprint = row.fingerprint;
    var submitted = false;
    bool current() =>
        _current(epoch) &&
        _rows.any(
          (r) => r.id == row.id && r.canCancel && r.fingerprint == fingerprint,
        );
    setState(() => _writing = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('退券确认'),
          content: Text(
            '确定执行退券？\n${row.cells['卡券名称'] ?? ''} ${row.cells['卡券券码'] ?? ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      if (confirmed != true || !current()) return;
      // Re-read authoritative eligibility rather than trusting the old button.
      final latest = await widget.load(query);
      if (!current()) return;
      if (latest.failureOrNull case final failure?) {
        setState(() => _message = failure.safeMessage);
        return;
      }
      final rows = latest.valueOrNull!;
      final matches = rows.where((r) => r.id == row.id).toList();
      setState(() => _rows = rows);
      if (matches.length != 1 ||
          !matches.single.canCancel ||
          matches.single.fingerprint != fingerprint) {
        setState(() => _message = '卡券记录已变化，请重新查询核实');
        return;
      }
      // Reserve before the async write: losing the session while waiting is
      // not evidence the server did not perform the refund.
      _uncertain.add(row.id);
      submitted = true;
      final result = await widget.cancel(row.id, current);
      if (!_current(epoch)) return;
      if (result.failureOrNull case final failure?) {
        setState(() {
          if (failure.kind != FailureKind.business) {
            _uncertain.add(row.id);
            _message = '退券结果尚未确认，请点击查询核实，勿重复退券';
          } else {
            _uncertain.remove(row.id);
            _message = failure.safeMessage;
          }
        });
      } else {
        _uncertain.remove(row.id);
        await _load();
        if (_current(epoch)) setState(() => _message = '退券成功');
      }
    } on Object {
      if (_current(epoch)) {
        setState(() {
          if (submitted) {
            _message = '退券结果尚未确认，请点击查询核实，勿重复退券';
          } else {
            _message = '读取卡券记录失败，请重新查询';
          }
        });
      }
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  Future<void> _export() async {
    if (!_allowed || _busy) return;
    final epoch = _epoch;
    final query = _query;
    setState(() => _exporting = true);
    try {
      final result = await widget.export(query, () => _current(epoch));
      if (_current(epoch)) {
        setState(
          () => _message =
              result.failureOrNull?.safeMessage ?? '已导出：${result.valueOrNull}',
        );
      }
    } on Object {
      if (_current(epoch)) setState(() => _message = '导出失败');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) _close();
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('当日卡券核销记录表')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<int>(
                    initialValue: _type,
                    key: ValueKey('voucher-type-$_type'),
                    decoration: const InputDecoration(labelText: '卡券类型'),
                    items: [
                      for (final item in const {
                        0: '全部',
                        12: '抖音',
                        22: '美团',
                        32: '推广',
                      }.entries)
                        DropdownMenuItem(
                          value: item.key,
                          child: Text(item.value),
                        ),
                    ],
                    onChanged: _allowed && !_busy
                        ? (v) => setState(() => _type = v!)
                        : null,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _keyword,
                    enabled: _allowed && !_busy,
                    decoration: const InputDecoration(labelText: '输入券码模糊搜索'),
                  ),
                ),
                FilledButton(
                  onPressed: _allowed && !_busy
                      ? () => _load(verified: true)
                      : null,
                  child: const Text('查询'),
                ),
                TextButton(
                  onPressed: _allowed && !_busy
                      ? () {
                          setState(() {
                            _type = 0;
                            _keyword.clear();
                          });
                          unawaited(_load(verified: true));
                        }
                      : null,
                  child: const Text('重置'),
                ),
                TextButton(
                  onPressed: _allowed && !_busy ? _export : null,
                  child: const Text('导出Excel'),
                ),
              ],
            ),
          ),
          if (_message != null) Text(_message!),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                ? const Center(child: Text('暂无数据'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        dataRowMinHeight: 48,
                        dataRowMaxHeight: double.infinity,
                        columns: [
                          const DataColumn(label: Text('序号')),
                          for (final column in CashierVoucherRecord.columns)
                            DataColumn(label: Text(column)),
                          const DataColumn(label: Text('操作')),
                        ],
                        rows: [
                          for (final (index, row) in _rows.indexed)
                            DataRow(
                              cells: [
                                DataCell(Text('${index + 1}')),
                                for (final column
                                    in CashierVoucherRecord.columns)
                                  DataCell(Text(row.cells[column] ?? '')),
                                DataCell(
                                  row.canCancel
                                      ? TextButton(
                                          onPressed:
                                              _allowed &&
                                                  !_busy &&
                                                  !_uncertain.contains(row.id)
                                              ? () => _cancel(row)
                                              : null,
                                          child: const Text('退券'),
                                        )
                                      : const Text('—'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}
