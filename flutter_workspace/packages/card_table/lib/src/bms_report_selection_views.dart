import 'dart:async';

import 'package:flutter/material.dart';

import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_report_configuration.dart';

class BmsReportTYConfigView extends StatelessWidget {
  const BmsReportTYConfigView({super.key, required this.loader});
  final BmsLoader loader;
  @override
  Widget build(BuildContext context) =>
      _ReportSelection(loader: loader, departments: true);
}

class BmsSealPrdConfigView extends StatelessWidget {
  const BmsSealPrdConfigView({super.key, required this.loader});
  final BmsLoader loader;
  @override
  Widget build(BuildContext context) =>
      _ReportSelection(loader: loader, departments: false);
}

class _ReportSelection extends StatefulWidget {
  const _ReportSelection({required this.loader, required this.departments});
  final BmsLoader loader;
  final bool departments;
  @override
  State<_ReportSelection> createState() => _ReportSelectionState();
}

class _ReportSelectionState extends State<_ReportSelection> {
  final _search = TextEditingController();
  final _selected = <int>{};
  List<Map<String, Object?>> _options = [], _configured = [], _categories = [];
  int _one = 0,
      _two = 0,
      _appliedOne = 0,
      _appliedTwo = 0,
      _page = 1,
      _version = 0;
  String _appliedSearch = '';
  String? _error;
  bool _reading = false,
      _writing = false,
      _ready = false,
      _more = false,
      _expired = false;
  Object? _openedToken;
  BmsReportConfigurationLoader? get _api =>
      widget.loader is BmsReportConfigurationLoader
      ? widget.loader as BmsReportConfigurationLoader
      : null;
  bool get _busy => _reading || _writing;
  Set<int> get _configuredIds => _configured.map(_id).toSet();

  @override
  void initState() {
    super.initState();
    _openedToken = _api?.configurationContext;
    unawaited(_load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static int _id(Map row) {
    final value = int.tryParse('${row['id']}');
    if (value == null || value < 0 || value > 9007199254740991) {
      throw const FormatException('编号无法识别');
    }
    return value;
  }

  static List<Map<String, Object?>> _rows(Object? value) {
    if (value == null) return [];
    if (value is! List || value.any((r) => r is! Map)) {
      throw const FormatException('列表无法识别');
    }
    final rows = [
      for (final row in value) Map<String, Object?>.from(row as Map),
    ];
    for (final row in rows) {
      _id(row);
    }
    return rows;
  }

  static void _validateTree(
    List<Map<String, Object?>> rows,
    String children, [
    int depth = 0,
    Set<int>? seen,
  ]) {
    if (depth > 32) throw const FormatException('分类层级无法识别');
    final ids = seen ?? <int>{};
    for (final row in rows) {
      if (!ids.add(_id(row))) throw const FormatException('列表编号重复');
      // Product category levels have independent ID namespaces.
      _validateTree(
        _rows(row[children]),
        children,
        depth + 1,
        children == 'subs' ? ids : null,
      );
    }
  }

  bool _current(Object? token, [int? version]) =>
      mounted &&
      !_expired &&
      token != null &&
      token == _api?.configurationContext &&
      (version == null || version == _version);
  bool _checkSession() {
    if (_current(_openedToken)) return true;
    _expired = true;
    if (mounted) {
      setState(() {
        _ready = false;
        _error = '登录或连接状态已改变，请重新打开配置页';
      });
    }
    return false;
  }

  Future<Map<String, Object?>?> _read(
    BmsReportConfigurationRequest request,
    int version,
  ) async {
    final result = await _api!.requestReportConfiguration(request);
    if (!_current(_openedToken, version)) return null;
    if (result.failureOrNull case final failure?) {
      setState(() => _error = failure.safeMessage);
      return null;
    }
    return result.valueOrNull;
  }

  Future<void> _load() async {
    if (!_checkSession() || _writing) return;
    final version = ++_version;
    setState(() {
      _reading = true;
      _ready = false;
      _error = null;
    });
    try {
      final data = await _read(
        BmsReportConfigurationRequest(
          widget.departments
              ? BmsReportConfigurationOperation.departmentTabs
              : BmsReportConfigurationOperation.waiterProducts,
        ),
        version,
      );
      if (data == null) return;
      _configured = _rows(data['records']);
      if (widget.departments) {
        final tree = await _read(
          const BmsReportConfigurationRequest(
            BmsReportConfigurationOperation.deptTree,
          ),
          version,
        );
        if (tree == null) return;
        final options = _rows(tree['depts']);
        _validateTree(options, 'subs');
        _options = options;
      } else {
        _appliedSearch = _search.text.trim();
        _appliedOne = _one;
        _appliedTwo = _two;
        final products = await _read(_productQuery(1), version);
        if (products == null) return;
        final options = _rows(products['prds']);
        final categories = _rows(products['cates']);
        _validateTree(categories, 'ss');
        if (_one != 0 && !categories.any((r) => _id(r) == _one)) {
          throw const FormatException('分类已变化，请重置筛选');
        }
        if (_two != 0 &&
            !categories
                .where((r) => _id(r) == _one)
                .expand((r) => _rows(r['ss']))
                .any((r) => _id(r) == _two)) {
          throw const FormatException('分类已变化，请重置筛选');
        }
        _options = options;
        _categories = categories;
        _page = 1;
        _more = _options.length >= 20;
      }
      if (_current(_openedToken, version)) {
        setState(() {
          _ready = true;
          _selected.clear();
        });
      }
    } on Object {
      if (_current(_openedToken, version)) {
        setState(() => _error = '配置数据无法读取，请重试');
      }
    } finally {
      if (mounted && version == _version) setState(() => _reading = false);
    }
  }

  BmsReportConfigurationRequest _productQuery(int page) =>
      BmsReportConfigurationRequest(
        BmsReportConfigurationOperation.waiterProductItems,
        parameters: {
          'name': _appliedSearch,
          'page_num': page,
          'page_size': 20,
          'init': page == 1 ? 1 : 2,
          'one_cate_id': _appliedOne,
          'two_cate_id': _appliedTwo,
        },
      );
  Future<void> _nextPage() async {
    if (_busy || !_ready || !_more || !_checkSession()) return;
    final version = ++_version;
    setState(() {
      _reading = true;
      _error = null;
    });
    try {
      final data = await _read(_productQuery(_page + 1), version);
      if (data == null) return;
      final rows = _rows(data['prds']);
      if (_current(_openedToken, version)) {
        setState(() {
          final existing = _options.map(_id).toSet();
          _options.addAll(rows.where((r) => !existing.contains(_id(r))));
          _page++;
          _more = rows.length >= 20;
        });
      }
    } on Object {
      if (_current(_openedToken, version)) {
        setState(() => _error = '商品列表无法读取，请重试');
      }
    } finally {
      if (mounted && version == _version) setState(() => _reading = false);
    }
  }

  Future<void> _write(BmsReportConfigurationRequest request) async {
    if (_busy || !_ready || !_checkSession()) return;
    setState(() {
      _writing = true;
      _error = null;
    });
    var success = false;
    try {
      final result = await _api!.requestReportConfiguration(request);
      if (!_checkSession()) return;
      if (result.failureOrNull case final failure?) {
        setState(() => _error = failure.safeMessage);
      } else {
        success = true;
      }
    } on Object {
      if (mounted) setState(() => _error = '保存配置失败，请重试');
    } finally {
      if (mounted) setState(() => _writing = false);
    }
    if (success && mounted) await _load();
  }

  Future<void> _add() async {
    if (_selected.isEmpty) {
      setState(() => _error = '请先选择需要添加的项目');
      return;
    }
    await _write(
      BmsReportConfigurationRequest(
        widget.departments
            ? BmsReportConfigurationOperation.addDepartmentTabs
            : BmsReportConfigurationOperation.addWaiterProducts,
        parameters: {
          widget.departments ? 'dept_ids' : 'prd_ids': _displayIds(_options)
              .where(_selected.contains)
              .toList(),
        },
      ),
    );
  }

  Iterable<int> _displayIds(List<Map<String, Object?>> rows) sync* {
    for (final row in rows) {
      yield _id(row);
      if (widget.departments) yield* _displayIds(_rows(row['subs']));
    }
  }

  Future<void> _delete(Map<String, Object?> row) async {
    if (_busy || !_ready || !_checkSession()) return;
    final id = _id(row);
    final token = _openedToken;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除配置'),
        content: Text('确认删除“${row['n'] ?? ''}”？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !_current(token) || !_checkSession()) return;
    await _write(
      BmsReportConfigurationRequest(
        widget.departments
            ? BmsReportConfigurationOperation.deleteDepartmentTab
            : BmsReportConfigurationOperation.deleteWaiterProduct,
        parameters: {widget.departments ? 'dept_id' : 'prd_id': id},
      ),
    );
  }

  Iterable<Widget> _candidateRows(
    List<Map<String, Object?>> rows, [
    int depth = 0,
  ]) sync* {
    for (final (index, row) in rows.indexed) {
      final id = _id(row);
      yield Padding(
        padding: EdgeInsets.only(left: (depth > 4 ? 4 : depth) * 16.0),
        child: CheckboxListTile(
          key: Key('report-option-$id'),
          title: Text(
            '${widget.departments ? '' : '${index + 1}. '}${row['n'] ?? ''}',
          ),
          subtitle: widget.departments
              ? null
              : Text(
                  '${row['on'] ?? ''} / ${row['tn'] ?? ''} · ￥${row['price'] ?? ''}',
                ),
          value: _selected.contains(id),
          onChanged: _busy || !_ready || _configuredIds.contains(id)
              ? null
              : (selected) => setState(() {
                  if (selected == true) {
                    _selected.add(id);
                  } else {
                    _selected.remove(id);
                  }
                }),
        ),
      );
      if (widget.departments && depth < 32) {
        yield* _candidateRows(_rows(row['subs']), depth + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final second = <Map<String, Object?>>[
      for (final category in _categories)
        if (_id(category) == _one) ..._rows(category['ss']),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(widget.departments ? '鸡尾酒导出配置' : '销售商品统计设置')),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.departments
                        ? '勾选需要单独统计的部门加入 sheet 列表；父部门汇总其子部门，子部门可独立配置。未配置部门汇总到“其他”。'
                        : '选择需要在收银系统统计售卖情况的商品。',
                  ),
                  if (!widget.departments) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: 160,
                          child: DropdownButtonFormField<int>(
                            key: ValueKey('report-one-$_one'),
                            initialValue: _one,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(
                                value: 0,
                                child: Text('全部一级分类'),
                              ),
                              for (final row in _categories)
                                if (_id(row) > 0)
                                  DropdownMenuItem(
                                    value: _id(row),
                                    child: Text('${row['n']}'),
                                  ),
                            ],
                            onChanged: _busy
                                ? null
                                : (id) => setState(() {
                                    _one = id ?? 0;
                                    _two = 0;
                                  }),
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: DropdownButtonFormField<int>(
                            key: ValueKey('report-two-$_one-$_two'),
                            initialValue: _two,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(
                                value: 0,
                                child: Text('全部二级分类'),
                              ),
                              for (final row in second)
                                if (_id(row) > 0)
                                  DropdownMenuItem(
                                    value: _id(row),
                                    child: Text('${row['n']}'),
                                  ),
                            ],
                            onChanged: _busy
                                ? null
                                : (id) => setState(() => _two = id ?? 0),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      key: const Key('report-search'),
                      controller: _search,
                      enabled: !_busy,
                      decoration: const InputDecoration(labelText: '商品名称/拼音'),
                    ),
                  ],
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: _busy ? null : _load,
                        child: Text(widget.departments ? '刷新' : '查询'),
                      ),
                      if (!widget.departments)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  setState(() {
                                    _one = 0;
                                    _two = 0;
                                    _search.clear();
                                  });
                                  unawaited(_load());
                                },
                          child: const Text('重置'),
                        ),
                      FilledButton(
                        key: const Key('report-add'),
                        onPressed: _busy || !_ready ? null : _add,
                        child: Text(
                          widget.departments ? '加入sheet列表' : '添加选中商品',
                        ),
                      ),
                    ],
                  ),
                  if (!widget.departments)
                    CheckboxListTile(
                      title: const Text('全选可添加商品'),
                      value:
                          _options.any(
                            (r) => !_configuredIds.contains(_id(r)),
                          ) &&
                          _options
                              .where((r) => !_configuredIds.contains(_id(r)))
                              .every((r) => _selected.contains(_id(r))),
                      onChanged: _busy || !_ready
                          ? null
                          : (selected) => setState(() {
                              _selected.clear();
                              if (selected == true) {
                                _selected.addAll(
                                  _options
                                      .map(_id)
                                      .where(
                                        (id) => !_configuredIds.contains(id),
                                      ),
                                );
                              }
                            }),
                    ),
                  ..._candidateRows(_options),
                  if (_ready && _options.isEmpty) const Text('暂无可选数据'),
                  if (!widget.departments && _more)
                    TextButton(
                      key: const Key('report-more'),
                      onPressed: _busy ? null : _nextPage,
                      child: const Text('加载更多'),
                    ),
                  const Divider(),
                  Text(
                    widget.departments ? 'sheet列表' : '已配置商品',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final (index, row) in _configured.indexed)
                    ListTile(
                      leading: Text('${index + 1}'),
                      title: Text('${row['n'] ?? ''}'),
                      subtitle: widget.departments
                          ? null
                          : Text(
                              '${row['on'] ?? ''} / ${row['tn'] ?? ''} · ￥${row['price'] ?? ''}',
                            ),
                      trailing: IconButton(
                        key: Key('report-delete-${_id(row)}'),
                        tooltip: '删除配置',
                        onPressed: _busy || !_ready ? null : () => _delete(row),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  if (_ready && _configured.isEmpty) const Text('暂无已配置数据'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
