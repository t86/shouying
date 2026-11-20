import 'dart:async';

import 'package:card_table/src/erp_loader.dart';
import 'package:card_table/src/erp_models.dart';
import 'package:card_table/src/wine_export_saver.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

typedef ErpReportSave = Future<Result<String>> Function(
  ProtocolBinaryFile file, {
  bool Function()? canSave,
});

class ErpMatLibNowView extends ErpReportView {
  const ErpMatLibNowView({
    required super.loader,
    super.canOperate,
    super.saveExport,
    super.key,
  }) : super(kind: ErpReportKind.materialNow);
}

class ErpMatLibView extends ErpReportView {
  const ErpMatLibView({
    required super.loader,
    super.canOperate,
    super.saveExport,
    super.key,
  }) : super(kind: ErpReportKind.materialInventory);
}

class ErpInLibRepView extends ErpReportView {
  const ErpInLibRepView({
    required super.loader,
    super.canOperate,
    super.saveExport,
    super.key,
  }) : super(kind: ErpReportKind.inRecords);
}

class ErpOutLibRepView extends ErpReportView {
  const ErpOutLibRepView({
    required super.loader,
    super.canOperate,
    super.saveExport,
    super.key,
  }) : super(kind: ErpReportKind.outRecords);
}

class ErpInLibAllRepView extends ErpReportView {
  const ErpInLibAllRepView({
    required super.loader,
    super.canOperate,
    super.saveExport,
    super.key,
  }) : super(kind: ErpReportKind.inSummary);
}

class ErpOutLibAllRepView extends ErpReportView {
  const ErpOutLibAllRepView({
    required super.loader,
    super.canOperate,
    super.saveExport,
    super.key,
  }) : super(kind: ErpReportKind.outSummary);
}

class ErpWarehousePsiView extends ErpReportView {
  const ErpWarehousePsiView({
    required super.loader,
    super.canOperate,
    super.saveExport,
    super.key,
  }) : super(kind: ErpReportKind.storePsi);
}

class ErpEmptyInLibRepView extends ErpReportView {
  const ErpEmptyInLibRepView({
    required super.loader,
    super.canOperate,
    super.saveExport,
    super.key,
  }) : super(kind: ErpReportKind.emptyIn);
}

class ErpEmptyOutLibRepView extends ErpReportView {
  const ErpEmptyOutLibRepView({
    required super.loader,
    super.canOperate,
    super.saveExport,
    super.key,
  }) : super(kind: ErpReportKind.emptyOut);
}

/// The server produces each spreadsheet from the same query as its report.
class ErpReportView extends StatefulWidget {
  const ErpReportView({
    required this.loader,
    required this.kind,
    this.canOperate,
    this.saveExport = saveWineExport,
    super.key,
  });
  final ErpLoader loader;
  final ErpReportKind kind;
  final bool Function()? canOperate;
  final ErpReportSave saveExport;
  @override
  State<ErpReportView> createState() => _ErpReportState();
}

class _ErpReportState extends State<ErpReportView> {
  final _keyword = TextEditingController(), _waiter = TextEditingController();
  String _start = '', _end = '';
  int _store = 0,
      _type = 0,
      _one = 0,
      _two = 0,
      _supplier = 0,
      _page = 1,
      _total = 0,
      _epoch = 0;
  bool _loading = false, _exporting = false, _active = true;
  Object? _scope;
  String? _message;
  List<Map<String, Object?>> _rows = [];
  ErpReportParams _options = const ErpReportParams();
  ErpReportLoader? get _loader => widget.loader is ErpReportLoader
      ? widget.loader as ErpReportLoader
      : null;
  bool get _busy => _loading || _exporting;
  bool get _current =>
      mounted &&
      _active &&
      _scope != null &&
      _scope == _loader?.reportContext &&
      (widget.canOperate?.call() ?? false) &&
      (ModalRoute.of(context)?.isCurrent ?? false);
  String _day(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  void _defaults() {
    final now = DateTime.now();
    _end = _day(now);
    _start = _day(
      widget.kind == ErpReportKind.materialInventory ||
              widget.kind == ErpReportKind.storePsi
          ? now
          : now.subtract(const Duration(days: 7)),
    );
    _store = _type = _one = _two = _supplier = 0;
    _page = 1;
    _keyword.clear();
    _waiter.clear();
  }

  ErpReportQuery get _query => ErpReportQuery(
    kind: widget.kind,
    startDay: _start,
    endDay: _end,
    storeId: _store,
    keyword: _keyword.text,
    recordType: _type,
    oneCateId: _one,
    twoCateId: _two,
    supplierId: _supplier,
    waiterKey: _waiter.text,
    page: _page,
  );
  @override
  void initState() {
    super.initState();
    _scope = _loader?.reportContext;
    _defaults();
    unawaited(Future<void>.microtask(_load));
  }

  @override
  void didUpdateWidget(covariant ErpReportView old) {
    super.didUpdateWidget(old);
    if (old.kind != widget.kind || _scope != _loader?.reportContext) {
      _epoch++;
      _scope = _loader?.reportContext;
      _rows = [];
      _options = const ErpReportParams();
      _total = 0;
      _loading = false;
      _exporting = false;
      _defaults();
      unawaited(Future<void>.microtask(_load));
    }
  }

  @override
  void dispose() {
    _active = false;
    _epoch++;
    _keyword.dispose();
    _waiter.dispose();
    super.dispose();
  }

  void _show(String message) {
    if (_current) setState(() => _message = message);
  }

  Future<void> _load() async {
    if (_busy) return;
    if (!_current) {
      if (mounted) setState(() => _message = '连接或报表权限不可用，请重新打开');
      return;
    }
    final token = ++_epoch, query = _query;
    bool current() => _current && token == _epoch;
    setState(() {
      _loading = true;
      _message = null;
      _rows = [];
      _total = 0;
    });
    try {
      query.toWire();
      if (!widget.kind.emptyBottle &&
          widget.kind != ErpReportKind.materialNow) {
        final options = await _loader!.loadReportOptions(canDispatch: current);
        if (!current()) return;
        if (options.failureOrNull case final failure?) throw failure;
        _options = options.valueOrNull!;
      }
      final result = await _loader!.loadReport(query, canDispatch: current);
      if (!current()) return;
      if (result.failureOrNull case final failure?) throw failure;
      final page = result.valueOrNull!;
      setState(() {
        _rows = page.rows;
        _total = page.total;
        if (widget.kind == ErpReportKind.materialNow) _options = page.options;
      });
    } on Object catch (error) {
      if (current()) {
        _show(
          error is AppFailure
              ? error.safeMessage
              : error is FormatException
              ? error.message
              : '报表读取失败，请重试',
        );
      }
    } finally {
      if (mounted && token == _epoch) setState(() => _loading = false);
    }
  }

  Future<void> _export() async {
    if (_busy || !_current) return;
    final token = ++_epoch, query = _query, scope = _scope;
    final permission = widget.canOperate;
    bool current() =>
        _current &&
        token == _epoch &&
        scope == _loader?.reportContext &&
        (permission?.call() ?? false);
    setState(() {
      _exporting = true;
      _message = null;
    });
    try {
      query.toWire(export: true);
      final result = await _loader!.exportReport(query, canDispatch: current);
      if (!current()) return;
      if (result.failureOrNull case final failure?) throw failure;
      final saved = await widget.saveExport(
        result.valueOrNull!,
        canSave: current,
      );
      if (!current()) return;
      if (saved.failureOrNull case final failure?) throw failure;
      _show('已保存：${saved.valueOrNull}');
    } on Object catch (error) {
      if (current()) {
        _show(
          error is AppFailure
              ? error.safeMessage
              : error is FormatException
              ? error.message
              : '导出失败，请重试',
        );
      }
    } finally {
      if (mounted && token == _epoch) setState(() => _exporting = false);
    }
  }

  Future<void> _pick(bool start) async {
    final scope = _scope;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(start ? _start : _end),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!_current || scope != _scope || date == null) return;
    setState(() {
      if (start) {
        _start = _day(date);
      } else {
        _end = _day(date);
      }
      _page = 1;
    });
  }

  Widget _select(
    String label,
    int value,
    List<Map<String, String>> options,
    void Function(int) changed,
  ) => SizedBox(
    width: 150,
    child: DropdownButtonFormField<int>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: [
        const DropdownMenuItem(value: 0, child: Text('全部')),
        for (final row in options)
          if (int.tryParse(row['id'] ?? '') case final int id when id > 0)
            DropdownMenuItem(value: id, child: Text(row['n'] ?? '')),
      ],
      onChanged: _busy
          ? null
          : (v) => setState(() {
              changed(v!);
              _page = 1;
            }),
    ),
  );
  List<Map<String, String>> get _recordTypes =>
      (widget.kind == ErpReportKind.inRecords ||
                  widget.kind == ErpReportKind.inSummary
              ? const {1: '采购入库', 3: '调拨入库', 7: '其他入库'}
              : const {
                  11: '销售出库',
                  3: '调拨出库',
                  17: '其他出库',
                  62: '报损出库',
                  72: '供应商回收',
                })
          .entries
          .map((e) => {'id': '${e.key}', 'n': e.value})
          .toList();
  @override
  Widget build(BuildContext context) {
    final kind = widget.kind, columns = _columns[kind]!;
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _active = false;
          _epoch++;
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(kind.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (kind != ErpReportKind.materialNow) ...[
                  if (kind != ErpReportKind.materialInventory &&
                      kind != ErpReportKind.storePsi)
                    for (final days in [7, 30, 90])
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () {
                                setState(() {
                                  _start = _day(
                                    DateTime.now().subtract(
                                      Duration(days: days),
                                    ),
                                  );
                                  _end = _day(DateTime.now());
                                  _page = 1;
                                });
                                unawaited(_load());
                              },
                        child: Text('近$days天'),
                      ),
                  TextButton(
                    key: const Key('erp-report-start'),
                    onPressed: _busy ? null : () => _pick(true),
                    child: Text(
                      '${kind == ErpReportKind.storePsi ? '日期' : '开始日期'}：$_start',
                    ),
                  ),
                  if (kind != ErpReportKind.storePsi)
                    TextButton(
                      key: const Key('erp-report-end'),
                      onPressed: _busy ? null : () => _pick(false),
                      child: Text('结束日期：$_end'),
                    ),
                ],
                if (!kind.emptyBottle)
                  _select(
                    '仓库',
                    _store,
                    _options.storeOptions,
                    (v) => _store = v,
                  ),
                if (kind.classified) ...[
                  _select('订单类型', _type, _recordTypes, (v) => _type = v),
                  _select('一级分类', _one, _options.cateOptions, (v) {
                    _one = v;
                    _two = 0;
                  }),
                  _select(
                    '二级分类',
                    _two,
                    _options.twoCateOptions['$_one'] ?? [],
                    (v) => _two = v,
                  ),
                ],
                if (kind == ErpReportKind.inRecords)
                  _select(
                    '供应商',
                    _supplier,
                    _options.supplierOptions,
                    (v) => _supplier = v,
                  ),
                if (kind == ErpReportKind.emptyIn)
                  SizedBox(
                    width: 160,
                    child: TextField(
                      key: const Key('erp-report-waiter'),
                      controller: _waiter,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        labelText: '服务员关键词',
                        isDense: true,
                      ),
                      onChanged: (_) => _page = 1,
                    ),
                  ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    key: const Key('erp-report-keyword'),
                    controller: _keyword,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: '物料名称或简写',
                      isDense: true,
                    ),
                    onChanged: (_) => _page = 1,
                    onSubmitted: (_) => unawaited(_load()),
                  ),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () {
                          _page = 1;
                          unawaited(_load());
                        },
                  child: const Text('查询'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () {
                          setState(_defaults);
                          unawaited(_load());
                        },
                  child: const Text('重置'),
                ),
                FilledButton.icon(
                  onPressed: _busy || !_current ? null : _export,
                  icon: const Icon(Icons.download),
                  label: const Text('导出Excel'),
                ),
              ],
            ),
            if (_busy) const LinearProgressIndicator(),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_message!),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _rows.isEmpty
                  ? const Center(child: Text('暂无数据'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: [
                            for (final column in columns)
                              DataColumn(label: Text(column.$2)),
                          ],
                          rows: [
                            for (var i = 0; i < _rows.length; i++)
                              DataRow(
                                cells: [
                                  for (final column in columns)
                                    DataCell(
                                      Text(
                                        column.$1 == '#'
                                            ? '${i + 1}'
                                            : '${_rows[i][column.$1] ?? ''}',
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
            if (kind.paginated)
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
      ),
    );
  }
}

// Source field order; numeric text and monetary units are preserved.
const _columns = <ErpReportKind, List<(String, String)>>{
  ErpReportKind.materialNow: [
    ('#', '序号'),
    ('sn', '仓库'),
    ('n', '物料名称'),
    ('un', '单位'),
    ('moc', '一级分类'),
    ('mtc', '二级分类'),
    ('c', '库存数量'),
    ('rc', '预扣库存数'),
    ('p', '实时加权单价'),
    ('a', '成本金额小计'),
  ],
  ErpReportKind.materialInventory: [
    ('#', '序号'),
    ('sn', '仓库'),
    ('n', '物料名称'),
    ('un', '单位'),
    ('moc', '一级分类'),
    ('mtc', '二级分类'),
    ('pc', '上期结存数量'),
    ('pa', '上期结存金额'),
    ('ic', '入库数量'),
    ('ia', '入库金额'),
    ('oc', '出库数量'),
    ('oa', '出库成本金额'),
    ('os', '出库销售金额'),
    ('c', '本期结存数量'),
    ('p', '本期加权单价'),
    ('a', '本期结存金额'),
  ],
  ErpReportKind.inRecords: [
    ('#', '序号'),
    ('ist', '入库日期'),
    ('rt', '订单类型'),
    ('isn', '入库仓库'),
    ('n', '物料名称'),
    ('sn', '供应商'),
    ('c', '入库单号'),
    ('moc', '一级分类'),
    ('mtc', '二级分类'),
    ('ot', '操作类型'),
    ('un', '入库单位'),
    ('ic', '入库数量'),
    ('ip', '入库单价'),
    ('ia', '入库小计'),
    ('ion', '入库操作人'),
    ('r', '备注'),
  ],
  ErpReportKind.outRecords: [
    ('#', '序号'),
    ('ost', '出库日期'),
    ('rt', '订单类型'),
    ('osn', '出库仓库'),
    ('n', '物料名称'),
    ('isn', '入库仓库'),
    ('c', '出库单号'),
    ('moc', '一级分类'),
    ('mtc', '二级分类'),
    ('ot', '出库类型'),
    ('un', '出库单位'),
    ('oc', '出库数量'),
    ('op', '出库成本单价'),
    ('oa', '出库成本小计'),
    ('sp', '出库单价'),
    ('sa', '出库小计'),
    ('oon', '出库操作人'),
    ('r', '备注'),
  ],
  ErpReportKind.inSummary: [
    ('#', '序号'),
    ('rt', '订单类型'),
    ('isn', '入库仓库'),
    ('n', '物料名称'),
    ('moc', '一级分类'),
    ('mtc', '二级分类'),
    ('un', '入库单位'),
    ('ic', '入库数量'),
    ('ia', '入库小计'),
  ],
  ErpReportKind.outSummary: [
    ('#', '序号'),
    ('rt', '订单类型'),
    ('osn', '出库仓库'),
    ('n', '物料名称'),
    ('moc', '一级分类'),
    ('mtc', '二级分类'),
    ('un', '出库单位'),
    ('oc', '出库数量'),
    ('oa', '出库成本小计'),
    ('sa', '出库小计'),
  ],
  ErpReportKind.storePsi: [
    ('#', '序号'),
    ('s', '仓库'),
    ('m', '物料名称'),
    ('u', '单位'),
    ('pc', '期初数量'),
    ('ibc', '采购'),
    ('ioi', '调拨(入)'),
    ('icg', '充公'),
    ('ipy', '盘盈'),
    ('iqt', '其他(入)'),
    ('ic', '入库合计'),
    ('os', '销售'),
    ('oo', '调拨(出)'),
    ('oqt', '其他(出)'),
    ('opk', '盘亏'),
    ('obs', '报损'),
    ('og', '供应商回收数量'),
    ('oc', '出库合计'),
    ('nc', '结存数量'),
  ],
  ErpReportKind.emptyIn: [
    ('t', '入库日期'),
    ('id', '入库单号'),
    ('w', '服务员'),
    ('m', '空瓶名称'),
    ('n', '操作类型'),
    ('c', '入库数量'),
    ('o', '入库操作人'),
    ('r', '备注'),
  ],
  ErpReportKind.emptyOut: [
    ('t', '出库日期'),
    ('id', '出库单号'),
    ('m', '空瓶名称'),
    ('n', '操作类型'),
    ('c', '出库数量'),
    ('o', '出库操作人'),
  ],
};
