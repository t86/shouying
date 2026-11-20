import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
import 'package:card_table/src/erp_loader.dart';
import 'package:card_table/src/erp_in_views.dart' show ErpStockEntryDialog;
import 'package:card_table/src/erp_sout_workflow.dart';
import 'package:card_table/src/erp_sout_pdf.dart';

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
const _types = {
  0: '全部',
  11: '销售出库',
  17: '其他出库',
  52: '盘亏出库',
  62: '报损出库',
  72: '供应商回收',
};

class ErpAnotherOutLibView extends StatefulWidget {
  const ErpAnotherOutLibView({
    super.key,
    required this.loader,
    this.onPrintDocument,
  });
  final ErpLoader loader;
  final ErpSoutPrint? onPrintDocument;
  @override
  State<ErpAnotherOutLibView> createState() => _ErpAnotherOutLibState();
}

class _ErpAnotherOutLibState extends State<ErpAnotherOutLibView> {
  final _remark = TextEditingController();
  List<Map<String, Object?>> _rows = [];
  final _selected = <String>{}, _uncertain = <String>{};
  late String _begin, _end;
  Object? _session;
  int _page = 1, _total = 0, _type = 0, _days = 7, _request = 0;
  bool _busy = false, _dialog = false;
  String? _error;
  ErpSoutWorkflowLoader? get _workflow => widget.loader is ErpSoutWorkflowLoader
      ? widget.loader as ErpSoutWorkflowLoader
      : null;
  bool get _current =>
      mounted && _session != null && _session == _workflow?.soutContext;
  @override
  void initState() {
    super.initState();
    _session = _workflow?.soutContext;
    _dates(7);
    unawaited(_load());
  }

  @override
  void dispose() {
    _request++;
    _remark.dispose();
    super.dispose();
  }

  void _dates(int days) {
    final now = DateTime.now();
    _begin = _day(DateTime(now.year, now.month, now.day - days));
    _end = _day(now);
    _days = days;
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _busy = true;
      _error = null;
      _rows = [];
      _selected.clear();
      _total = 0;
    });
    try {
      if (_workflow == null) {
        final result = await widget.loader.loadSoutList(
          beginDay: _begin,
          endDay: _end,
        );
        if (!mounted || request != _request) return;
        setState(() {
          _rows = [
            for (final r in result.valueOrNull ?? [])
              {
                'id': r.id,
                'cd': r.code,
                'sn': r.storeName,
                'st': r.billDay,
                'en': r.operName,
                'r': r.memo,
              },
          ];
          _error = result.failureOrNull?.safeMessage ?? '此连接未提供完整其他出库操作';
        });
        return;
      }
      if (!_current) throw '登录或连接已变化，请重新打开';
      final result = await _workflow!.loadOtherOutPage(
        beginDay: _begin,
        endDay: _end,
        recordType: _type,
        remark: _remark.text.trim(),
        page: _page,
      );
      if (!_current || request != _request) return;
      if (result.failureOrNull case final f?) throw f.safeMessage;
      setState(() {
        _rows = result.valueOrNull!.rows;
        _total = result.valueOrNull!.total;
        _selected.clear();
      });
    } on Object catch (e) {
      if (mounted && request == _request) {
        setState(() => _error = e is String ? e : '读取失败，请重试');
      }
    } finally {
      if (mounted && request == _request) setState(() => _busy = false);
    }
  }

  String? _one() {
    if (_selected.length != 1) {
      setState(() => _error = '请选择且仅选择一个出库单');
      return null;
    }
    final id = _selected.single;
    if (!_rows.any((r) => '${r['id']}' == id && '${r['hc']}' != '2')) {
      setState(() => _error = '该单已红冲或不在当前查询中，请重新查询');
      return null;
    }
    return id;
  }

  Future<bool> _freshEligible(String id) async {
    if (!_current) return false;
    final result = await _workflow!.loadOtherOutPage(
      beginDay: _begin,
      endDay: _end,
      recordType: _type,
      remark: _remark.text.trim(),
      page: _page,
    );
    if (!_current) return false;
    final allowed =
        result.failureOrNull == null &&
        result.valueOrNull!.rows.any(
          (r) => '${r['id']}' == id && '${r['hc']}' != '2',
        );
    if (!allowed) {
      setState(
        () => _error = result.failureOrNull?.safeMessage ?? '该单已红冲或状态已变化，请重新查询',
      );
    }
    return allowed;
  }

  Future<void> _create({bool copy = false}) async {
    if (_busy || _dialog) return;
    final id = copy ? _one() : null;
    if (copy && id == null) return;
    if (copy && !_current) {
      setState(() => _error = '登录或连接已变化，请重新打开');
      return;
    }
    _dialog = true;
    if (copy && !await _freshEligible(id!)) {
      _dialog = false;
      return;
    }
    if (!mounted) {
      _dialog = false;
      return;
    }
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ErpStockEntryDialog(
        loader: widget.loader,
        outgoing: true,
        copySourceId: id,
      ),
    );
    _dialog = false;
    if (mounted && result == true) await _load();
  }

  Future<void> _detail(String id, {bool reverse = false}) async {
    if (_busy || _dialog) return;
    if (!_current) {
      setState(() => _error = '登录或连接已变化，请重新打开');
      return;
    }
    _dialog = true;
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SoutDocumentDialog(
        loader: _workflow!,
        token: _session,
        id: id,
        reverse: reverse,
        eligible: () => _freshEligible(id),
        isCurrent: () => _current,
        onPrintDocument: widget.onPrintDocument,
      ),
    );
    _dialog = false;
    if (mounted) await _load();
  }

  Future<void> _whole() async {
    if (_busy || _dialog) return;
    final id = _one();
    if (id == null) return;
    if (_uncertain.contains(id)) {
      setState(() => _error = '该单操作结果不确定，请核实后重新进入');
      return;
    }
    _dialog = true;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('红冲整单'),
        content: const Text('将按原系统对所选单据执行整单红冲（反审核）。确认继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定红冲'),
          ),
        ],
      ),
    );
    _dialog = false;
    if (!mounted || yes != true) return;
    if (!_current) {
      setState(() => _error = '登录或连接已变化，请重新打开');
      return;
    }
    setState(() => _busy = true);
    try {
      if (!await _freshEligible(id)) return;
      final result = await _workflow!.reverseOtherOutWhole(id);
      if (!_current) return;
      if (result.failureOrNull case final f?) {
        if (f.kind != FailureKind.business) _uncertain.add(id);
        setState(
          () => _error = _uncertain.contains(id)
              ? '结果不确定，请查询核实，勿重复红冲'
              : f.safeMessage,
        );
      } else {
        await _load();
        if (mounted) setState(() => _error = '红冲整单成功');
      }
    } on Object {
      if (mounted) {
        setState(() {
          _uncertain.add(id);
          _error = '结果不确定，请查询核实，勿重复红冲';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(bool begin) async {
    final result = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(begin ? _begin : _end),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (begin) {
        _begin = _day(result);
      } else {
        _end = _day(result);
      }
      _days = 0;
    });
  }

  void _query() {
    if (_begin.compareTo(_end) > 0) {
      setState(() => _error = '开始日期不能晚于结束日期');
      return;
    }
    _page = 1;
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Text('其他出库', style: Theme.of(context).textTheme.titleLarge),
            FilledButton(
              onPressed: _busy ? null : () => _create(),
              child: const Text('新建其他出库单'),
            ),
            OutlinedButton(
              onPressed: _busy ? null : () => _create(copy: true),
              child: const Text('类似创建'),
            ),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () {
                      final id = _one();
                      if (id != null) unawaited(_detail(id, reverse: true));
                    },
              child: const Text('红冲'),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _whole,
              child: const Text('红冲整单'),
            ),
          ],
        ),
        Wrap(
          spacing: 6,
          children: [
            for (final days in [7, 30, 90])
              ChoiceChip(
                label: Text('近$days天'),
                selected: _days == days,
                onSelected: _busy
                    ? null
                    : (v) {
                        if (v) {
                          setState(() {
                            _dates(days);
                            _page = 1;
                          });
                          unawaited(_load());
                        }
                      },
              ),
            TextButton(
              onPressed: _busy ? null : () => _pick(true),
              child: Text(_begin),
            ),
            TextButton(
              onPressed: _busy ? null : () => _pick(false),
              child: Text(_end),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<int>(
                initialValue: _type,
                key: ValueKey(_type),
                decoration: const InputDecoration(labelText: '出库类型'),
                items: [
                  for (final t in _types.entries)
                    DropdownMenuItem(value: t.key, child: Text(t.value)),
                ],
                onChanged: _busy ? null : (v) => setState(() => _type = v!),
              ),
            ),
            SizedBox(
              width: 180,
              child: TextField(
                key: const Key('sout-remark'),
                controller: _remark,
                decoration: const InputDecoration(labelText: '备注模糊查询'),
                onSubmitted: (_) => _query(),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : _query,
              child: const Text('查询'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      setState(() {
                        _dates(7);
                        _type = 0;
                        _page = 1;
                        _remark.clear();
                      });
                      unawaited(_load());
                    },
              child: const Text('重置'),
            ),
          ],
        ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        if (_busy) const LinearProgressIndicator(),
        Expanded(
          child: _rows.isEmpty
              ? const Center(child: Text('暂无出库单'))
              : ListView(
                  children: [
                    for (final row in _rows)
                      Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              title: Text('${row['cd'] ?? ''}'),
                              subtitle: Text(
                                '${row['rt'] ?? ''} · ${row['sn'] ?? ''}',
                              ),
                              value: _selected.contains('${row['id']}'),
                              onChanged: _busy || '${row['hc']}' == '2'
                                  ? null
                                  : (v) => setState(() {
                                      v == true
                                          ? _selected.add('${row['id']}')
                                          : _selected.remove('${row['id']}');
                                    }),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                '出库成本：${row['ta'] ?? ''}　出库总额：${row['sa'] ?? ''}\n备注：${row['r'] ?? ''}\n出库时间：${row['st'] ?? ''}\n操作人：${row['en'] ?? ''}',
                              ),
                            ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _detail('${row['id']}'),
                              child: const Text('查看详情'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: '上一页',
              onPressed: _busy || _page <= 1
                  ? null
                  : () {
                      _page--;
                      unawaited(_load());
                    },
              icon: const Icon(Icons.chevron_left),
            ),
            Text('第 $_page 页 · 共 $_total 条'),
            IconButton(
              tooltip: '下一页',
              onPressed: _busy || _page * 20 >= _total
                  ? null
                  : () {
                      _page++;
                      unawaited(_load());
                    },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SoutDocumentDialog extends StatefulWidget {
  const _SoutDocumentDialog({
    required this.loader,
    required this.token,
    required this.id,
    required this.reverse,
    required this.eligible,
    required this.isCurrent,
    this.onPrintDocument,
  });
  final ErpSoutWorkflowLoader loader;
  final Object? token;
  final String id;
  final bool reverse;
  final Future<bool> Function() eligible;
  final bool Function() isCurrent;
  final ErpSoutPrint? onPrintDocument;
  @override
  State<_SoutDocumentDialog> createState() => _SoutDocumentState();
}

class _SoutDocumentState extends State<_SoutDocumentDialog> {
  ErpSoutDocument? _doc;
  final _counts = <int, TextEditingController>{};
  bool _busy = false, _active = true, _uncertain = false;
  bool _printUncertain = false;
  String? _error;
  bool get _current =>
      mounted &&
      _active &&
      widget.token != null &&
      widget.token == widget.loader.soutContext;
  bool get _printCurrent =>
      _current &&
      widget.isCurrent() &&
      ModalRoute.of(context)?.isCurrent == true;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _active = false;
    for (final c in _counts.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      if (!_current) throw '登录或连接已变化';
      final result = await widget.loader.loadOtherOutDocument(
        widget.id,
        widget.reverse
            ? ErpSoutDocumentMode.reversal
            : ErpSoutDocumentMode.view,
      );
      if (!_current) return;
      if (result.failureOrNull case final f?) throw f.safeMessage;
      setState(() {
        _doc = result.valueOrNull;
        for (final r in _doc!.lines) {
          _counts[int.parse('${r['id']}')] = TextEditingController(text: '0');
        }
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = e is String ? e : '明细读取失败');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || _uncertain || !_current || _doc == null) return;
    final counts = <int, double>{};
    for (final row in _doc!.lines) {
      final id = int.parse('${row['id']}'),
          count = double.tryParse(_counts[id]!.text),
          maximum = double.tryParse('${row['c']}');
      if (count == null ||
          !count.isFinite ||
          count < 0 ||
          maximum == null ||
          !maximum.isFinite ||
          count > maximum) {
        setState(() => _error = '红冲数量必须在 0 和原数量之间');
        return;
      }
      if (count > 0) counts[id] = count;
    }
    if (counts.isEmpty) {
      setState(() => _error = '请填写实际红冲数量');
      return;
    }
    setState(() => _busy = true);
    var writeStarted = false;
    try {
      if (!await widget.eligible()) {
        if (_current) setState(() => _error = '该单已红冲或状态无法确认，请重新查询');
        return;
      }
      if (!_current) return;
      final fresh = await widget.loader.loadOtherOutDocument(
        widget.id,
        ErpSoutDocumentMode.reversal,
      );
      if (!_current) return;
      if (fresh.failureOrNull case final f?) throw f.safeMessage;
      final limits = {
        for (final row in fresh.valueOrNull!.lines)
          int.parse('${row['id']}'): double.tryParse('${row['c']}'),
      };
      if (counts.entries.any(
        (e) =>
            limits[e.key] == null ||
            !limits[e.key]!.isFinite ||
            e.value > limits[e.key]!,
      )) {
        throw '可红冲数量已变化，请重新打开';
      }
      if (!_current) return;
      writeStarted = true;
      final result = await widget.loader.reverseOtherOutLines(counts);
      if (!_current) return;
      if (result.failureOrNull case final f?) {
        _uncertain = f.kind != FailureKind.business;
        throw _uncertain ? '结果不确定，请查询核实，勿重复红冲' : f.safeMessage;
      }
      if (mounted) {
        final route = ModalRoute.of(context);
        if (route?.isActive == true) {
          Navigator.of(context).removeRoute(route!, true);
        }
      }
    } on Object catch (e) {
      if (writeStarted && e is! String) _uncertain = true;
      if (mounted) {
        setState(
          () => _error = _uncertain
              ? '结果不确定，请查询核实，勿重复红冲'
              : e is String
              ? e
              : '红冲失败，请查询核实',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() async {
    final original = _doc;
    final print = widget.onPrintDocument;
    if (_busy ||
        _printUncertain ||
        !_printCurrent ||
        widget.reverse ||
        original == null ||
        !canPrintErpSout(original) ||
        print == null) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    var dispatchStarted = false;
    try {
      final result = await widget.loader.loadOtherOutDocument(
        widget.id,
        ErpSoutDocumentMode.view,
      );
      if (!_printCurrent || !identical(_doc, original)) return;
      if (result.failureOrNull case final failure?) throw failure.safeMessage;
      final fresh = result.valueOrNull;
      if (fresh == null || !canPrintErpSout(fresh)) {
        throw '单据状态已变化，请重新打开详情';
      }
      setState(() => _doc = fresh);
      final bytes = await buildErpSoutPdf(fresh);
      bool canDispatch() =>
          _printCurrent && identical(_doc, fresh) && canPrintErpSout(fresh);
      if (!canDispatch()) return;
      dispatchStarted = true;
      final printed = await print(bytes, '其他出库单.pdf', canDispatch);
      // Keep duplicate protection on this original detail even while covered;
      // never display its late result on a different route.
      if (_current && identical(_doc, fresh)) {
        _printUncertain =
            printed.failureOrNull?.code == 'device.pdf_result_unknown';
      }
      if (!canDispatch()) return;
      if (printed.failureOrNull case final failure?) {
        _printUncertain = failure.code == 'device.pdf_result_unknown';
        setState(
          () => _error = _printUncertain
              ? '打印输出结果不确定，请核实，勿重复打印'
              : failure.code == 'device.pdf_not_accepted'
              ? '打印已取消或未完成，可重试'
              : failure.safeMessage,
        );
      } else {
        setState(() => _error = '已提交系统打印');
      }
    } on Object catch (error) {
      if (_current) _printUncertain = dispatchStarted;
      if (!_printCurrent) return;
      setState(
        () => _error = _printUncertain
            ? '打印输出结果不确定，请核实，勿重复打印'
            : error is String
            ? error
            : '生成打印文档失败，请重试',
      );
    } finally {
      if (mounted && _active) setState(() => _busy = false);
    }
  }

  String _preview(Map<String, Object?> row) {
    final original = double.tryParse('${row['c']}'),
        count = double.tryParse(_counts[int.parse('${row['id']}')]!.text),
        cost = double.tryParse('${row['a']}'),
        amount = double.tryParse('${row['sa']}');
    if (original == null ||
        count == null ||
        cost == null ||
        amount == null ||
        ![original, count, cost, amount].every((v) => v.isFinite) ||
        original <= 0 ||
        count < 0 ||
        count > original) {
      return '请输入有效数量以查看红冲小计';
    }
    return '红冲后数量：${original - count} · 成本小计：${(cost / original * count).toStringAsFixed(2)} · 红冲小计：${(amount / original * count).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final data = _doc?.data ?? {};
    return PopScope<bool>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _active = false;
      },
      child: AlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.reverse ? '分项红冲' : '出库详情'),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '单号：${data['code'] ?? ''}\n仓库：${data['store_name'] ?? ''}\n类型：${data['record_type'] ?? ''}\n出库时间：${data['store_time'] ?? ''}\n操作人：${data['oper_emp_name'] ?? ''}\n成本：${data['total_amt'] ?? ''} · 总额：${data['sell_total_amt'] ?? ''}\n备注：${data['remark'] ?? ''}',
                ),
                for (final row in _doc?.lines ?? <Map<String, Object?>>[])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${row['n']} · ${row['moc'] ?? ''}/${row['mtc'] ?? ''} · ${row['un'] ?? ''}\n数量：${row['c']} · 成本：${row['a'] ?? ''} · 金额：${row['sa'] ?? ''}',
                        ),
                        if (widget.reverse)
                          TextField(
                            key: Key('sout-hc-${row['id']}'),
                            controller: _counts[int.parse('${row['id']}')],
                            enabled: !_busy && !_uncertain,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: '红冲数量',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        if (widget.reverse) Text(_preview(row)),
                      ],
                    ),
                  ),
                if (!widget.reverse && data['hc_dtls'] is List) ...[
                  const Text('红冲记录'),
                  for (final row in (data['hc_dtls'] as List).whereType<Map>())
                    Text(
                      '${row['n'] ?? ''} · ${row['un'] ?? ''}\n操作人：${row['oen'] ?? ''} · 时间：${row['ot'] ?? ''}\n红冲数量：${row['c'] ?? ''} · 红冲前：${row['bc'] ?? ''} · 红冲后：${row['ac'] ?? ''}\n成本小计：${row['a'] ?? ''} · 红冲小计：${row['sa'] ?? ''}',
                    ),
                ],
                if (_busy) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _active = false;
              Navigator.pop(context, false);
            },
            child: const Text('关闭'),
          ),
          if (widget.reverse)
            FilledButton(
              onPressed: _busy || _doc == null || _uncertain ? null : _submit,
              child: const Text('确认分项红冲'),
            ),
          if (!widget.reverse && _doc != null && canPrintErpSout(_doc!))
            FilledButton(
              onPressed:
                  _busy || _printUncertain || widget.onPrintDocument == null
                  ? null
                  : _print,
              child: const Text('打印'),
            ),
        ],
      ),
    );
  }
}
