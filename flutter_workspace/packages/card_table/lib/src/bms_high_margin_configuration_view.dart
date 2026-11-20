import 'dart:async';

import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_report_configuration.dart';
import 'package:flutter/material.dart';

typedef _Operation = BmsReportConfigurationOperation;
int _id(Object? value) {
  final id = int.tryParse('$value');
  if (id == null || id < 0 || id > 9007199254740991) {
    throw const FormatException('商品分类数据无效');
  }
  return id;
}

List<Map<String, Object?>> _rows(Object? value) {
  if (value == null) return [];
  if (value is! List || value.any((e) => e is! Map)) {
    throw const FormatException('商品配置数据无法识别');
  }
  return [for (final row in value) Map<String, Object?>.from(row as Map)];
}

class _Product {
  _Product(Map<String, Object?> row)
    : id = _id(row['id']),
      name = '${row['n'] ?? ''}',
      one = '${row['on'] ?? ''}',
      two = '${row['tn'] ?? ''}',
      price = '${row['p'] ?? ''}',
      type = '${row['pt'] ?? ''}',
      invalid = row['s'] == '无效' {
    if (id == 0 || name.isEmpty) throw const FormatException('商品数据无效');
  }
  final int id;
  final String name, one, two, price, type;
  final bool invalid;
}

List<_Product> _products(Object? raw) {
  final products = _rows(raw).map(_Product.new).toList();
  if (products.map((e) => e.id).toSet().length != products.length) {
    throw const FormatException('商品数据重复，请重新查询');
  }
  return products;
}

Future<Map<String, Object?>> _request(
  BmsReportConfigurationLoader loader,
  _Operation operation, [
  Map<String, Object?> parameters = const {},
]) async {
  final result = await loader.requestReportConfiguration(
    BmsReportConfigurationRequest(operation, parameters: parameters),
  );
  if (result.failureOrNull case final failure?) {
    throw FormatException(failure.safeMessage);
  }
  final data = result.valueOrNull;
  if (data == null) throw const FormatException('商品配置数据无法识别');
  return data;
}

String _message(Object error) =>
    error is FormatException ? error.message : '请求失败，请重试';

/// Actual Vue miniProgressConfig: service staff high-margin reporting products.
class BmsMiniProgressConfigView extends StatefulWidget {
  const BmsMiniProgressConfigView({required this.loader, super.key});
  final BmsLoader loader;
  @override
  State<BmsMiniProgressConfigView> createState() =>
      _BmsMiniProgressConfigViewState();
}

class _BmsMiniProgressConfigViewState extends State<BmsMiniProgressConfigView> {
  final _keyword = TextEditingController();
  final _selected = <int>{};
  List<_Product> _items = [];
  bool _loading = false, _writing = false;
  int _version = 0;
  Object? _dataContext;
  String? _error;
  BmsReportConfigurationLoader? get _loader =>
      widget.loader is BmsReportConfigurationLoader
      ? widget.loader as BmsReportConfigurationLoader
      : null;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant BmsMiniProgressConfigView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.loader, widget.loader)) unawaited(_load());
  }

  @override
  void dispose() {
    _version++;
    _keyword.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_writing) return;
    final version = ++_version, loader = _loader;
    final token = loader?.configurationContext;
    setState(() {
      _loading = true;
      _error = null;
      _selected.clear();
      _items = [];
      _dataContext = null;
    });
    try {
      if (loader == null) throw const FormatException('高毛利商品配置服务未接入');
      if (token == null) throw const FormatException('登录或连接尚未就绪，请重新查询');
      final data = await _request(loader, _Operation.highMarginProducts, {
        'key': _keyword.text.trim(),
      });
      if (!mounted || version != _version) return;
      if (token != loader.configurationContext) {
        throw const FormatException('登录或连接状态已变化，请重新查询');
      }
      final items = _products(data['records']);
      setState(() {
        _items = items;
        _dataContext = token;
      });
    } on Object catch (error) {
      if (mounted && version == _version) {
        setState(() => _error = _message(error));
      }
    } finally {
      if (mounted && version == _version) setState(() => _loading = false);
    }
  }

  bool _current(BmsReportConfigurationLoader loader, Object? token) =>
      mounted &&
      identical(loader, _loader) &&
      token != null &&
      token == loader.configurationContext;
  Future<void> _add() async {
    final loader = _loader, token = _dataContext;
    if (loader == null || !_current(loader, token)) {
      setState(() => _error = '登录或连接状态已变化，请重新查询');
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddProducts(loader: loader, token: token!),
    );
    if (!_current(loader, token) || saved != true) return;
    await _load();
  }

  Future<void> _delete() async {
    if (_writing || _loading) return;
    if (_selected.isEmpty) {
      setState(() => _error = '请选择需要删除的商品');
      return;
    }
    final loader = _loader, token = _dataContext;
    if (loader == null || !_current(loader, token)) {
      setState(() => _error = '登录或连接状态已变化，请重新查询');
      return;
    }
    final ids = List<int>.unmodifiable(_selected);
    setState(() {
      _writing = true;
      _error = null;
    });
    var success = false;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('删除高毛利商品配置'),
          content: Text('确认从配置中删除已选 ${ids.length} 个商品？不会删除商品档案。'),
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
      if (confirmed != true || !_current(loader, token)) return;
      await _request(loader, _Operation.deleteHighMarginProducts, {'ids': ids});
      if (!_current(loader, token)) return;
      success = true;
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _writing = false);
    }
    if (success) await _load();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                key: const Key('high-margin-search'),
                controller: _keyword,
                enabled: !_writing,
                decoration: const InputDecoration(
                  labelText: '商品名称/首字母',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _load(),
              ),
            ),
            FilledButton(
              onPressed: _writing ? null : _load,
              child: const Text('查询'),
            ),
            OutlinedButton(
              onPressed: _writing
                  ? null
                  : () {
                      _keyword.clear();
                      unawaited(_load());
                    },
              child: const Text('重置'),
            ),
            FilledButton(
              key: const Key('high-margin-add'),
              onPressed: _loading || _writing || _dataContext == null
                  ? null
                  : _add,
              child: const Text('新增'),
            ),
            OutlinedButton(
              key: const Key('high-margin-delete'),
              onPressed: _loading || _writing ? null : _delete,
              child: const Text('删除'),
            ),
            const Text('配置高毛利商品'),
          ],
        ),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? Center(child: Text(_error == null ? '暂无数据' : '查询未成功'))
            : _productTable(
                _items,
                _selected,
                onSelect: _writing
                    ? null
                    : (id, selected) => setState(() {
                        selected ? _selected.add(id) : _selected.remove(id);
                      }),
                onAll: _writing
                    ? null
                    : (all) => setState(() {
                        _selected.clear();
                        if (all) _selected.addAll(_items.map((e) => e.id));
                      }),
                showPrice: true,
              ),
      ),
    ],
  );
}

Widget _productTable(
  List<_Product> items,
  Set<int> selected, {
  required void Function(int, bool)? onSelect,
  required void Function(bool)? onAll,
  Set<int> disabled = const {},
  bool showPrice = false,
}) => SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: SingleChildScrollView(
    child: DataTable(
      onSelectAll: onAll == null ? null : (value) => onAll(value == true),
      columns: [
        for (final label in [
          '序号',
          '商品名称',
          '一级分类',
          '二级分类',
          if (showPrice) '单价',
          '商品类型',
        ])
          DataColumn(label: Text(label)),
      ],
      rows: [
        for (var i = 0; i < items.length; i++)
          DataRow(
            key: ValueKey('high-margin-row-${items[i].id}'),
            selected: selected.contains(items[i].id),
            onSelectChanged: onSelect == null || disabled.contains(items[i].id)
                ? null
                : (value) => onSelect(items[i].id, value == true),
            color: items[i].invalid
                ? WidgetStateProperty.all(Colors.grey.withAlpha(45))
                : null,
            cells: [
              DataCell(Text('${i + 1}')),
              DataCell(Text(items[i].name)),
              DataCell(Text(items[i].one)),
              DataCell(Text(items[i].two)),
              if (showPrice) DataCell(Text(items[i].price)),
              DataCell(Text(items[i].type)),
            ],
          ),
      ],
    ),
  ),
);

class _AddProducts extends StatefulWidget {
  const _AddProducts({required this.loader, required this.token});
  final BmsReportConfigurationLoader loader;
  final Object token;
  @override
  State<_AddProducts> createState() => _AddProductsState();
}

class _AddProductsState extends State<_AddProducts> {
  final _keyword = TextEditingController();
  List<Map<String, Object?>> _categories = [];
  List<_Product> _items = [];
  Set<int> _already = {};
  final _selected = <int>{};
  int _one = 0, _two = 0, _page = 0, _version = 0;
  int _appliedOne = 0, _appliedTwo = 0;
  String _appliedName = '';
  bool _loading = false,
      _writing = false,
      _done = false,
      _ready = false,
      _invalid = false;
  String? _error;
  bool get _current {
    if (!mounted || _invalid) return false;
    if (widget.token != widget.loader.configurationContext) {
      _invalid = true;
      return false;
    }
    return true;
  }

  void _fail(Object error) {
    if (mounted) setState(() => _error = _message(error));
  }

  bool _check() {
    if (_current) return true;
    _fail(const FormatException('登录或连接状态已变化，请关闭后重新打开'));
    return false;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _invalid = true;
    _version++;
    _keyword.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    if (!_check()) return;
    setState(() => _loading = true);
    try {
      final data = await _request(
        widget.loader,
        _Operation.highMarginProducts,
        {'key': ''},
      );
      if (!_check()) return;
      setState(() {
        _already = _products(data['records']).map((e) => e.id).toSet();
        _ready = true;
        _loading = false;
      });
      await _load(true);
    } on Object catch (error) {
      _fail(error);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _load(bool reset) async {
    if (_writing || !_ready || !_check() || (!reset && (_loading || _done))) {
      return;
    }
    final version = ++_version, page = reset ? 1 : _page + 1;
    if (reset) {
      _appliedOne = _one;
      _appliedTwo = _two;
      _appliedName = _keyword.text.trim();
    }
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items = [];
        _selected.clear();
        _done = false;
      }
    });
    try {
      final data = await _request(
        widget.loader,
        _Operation.highMarginProductItems,
        {
          'name': _appliedName,
          'page_num': page,
          'page_size': 20,
          'init': reset ? 1 : 2,
          'one_cate_id': _appliedOne,
          'two_cate_id': _appliedTwo,
        },
      );
      if (!_check() || version != _version) return;
      final products = _products(data['prds']);
      if (reset) {
        final categories = _rows(data['cates']);
        for (final category in categories) {
          _id(category['id']);
          if (category['n'] is! String) throw const FormatException('分类数据无效');
          for (final child in _rows(category['ss'])) {
            _id(child['id']);
            if (child['n'] is! String) throw const FormatException('分类数据无效');
          }
        }
        _categories = categories;
        if (_one != 0 && !categories.any((c) => _id(c['id']) == _one)) {
          _one = 0;
          _two = 0;
        }
      }
      final existing = reset ? <int>{} : _items.map((e) => e.id).toSet();
      setState(() {
        _items = [
          if (!reset) ..._items,
          ...products.where((e) => !existing.contains(e.id)),
        ];
        _page = page;
        _done = products.length < 20;
      });
    } on Object catch (error) {
      if (mounted && version == _version) _fail(error);
    } finally {
      if (mounted && version == _version) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_writing || _loading || !_check()) return;
    if (_selected.isEmpty) {
      _fail(const FormatException('请选择需要添加的商品'));
      return;
    }
    setState(() {
      _writing = true;
      _error = null;
    });
    final route = ModalRoute.of(context), navigator = Navigator.of(context);
    try {
      final data = await _request(
        widget.loader,
        _Operation.highMarginProducts,
        {'key': ''},
      );
      if (!_check()) return;
      final latest = _products(data['records']).map((e) => e.id).toSet();
      if (_selected.any(latest.contains)) {
        setState(() {
          _already = latest;
          _selected.removeAll(latest);
        });
        throw const FormatException('部分商品已被配置，请确认剩余选择后重试');
      }
      if (!_check()) return;
      await _request(widget.loader, _Operation.addHighMarginProducts, {
        'ids': List<int>.unmodifiable(_selected),
      });
      if (!_check()) return;
      if (route?.isActive == true) navigator.removeRoute(route!, true);
    } on Object catch (error) {
      _fail(error);
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final oneOptions = _categories.where((c) => _id(c['id']) != 0).toList();
    final parent = _categories.where((c) => _id(c['id']) == _one).firstOrNull;
    final twoOptions = parent == null
        ? <Map<String, Object?>>[]
        : _rows(parent['ss']).where((c) => _id(c['id']) != 0).toList();
    return PopScope<bool>(
      onPopInvokedWithResult: (popped, _) {
        if (popped) _invalid = true;
      },
      child: AlertDialog(
        insetPadding: const EdgeInsets.all(12),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('添加高毛利商品'),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        content: SizedBox(
          width: 850,
          height: 520,
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('high-margin-one-$_one'),
                      initialValue: _one,
                      decoration: const InputDecoration(labelText: '一级分类'),
                      items: [
                        const DropdownMenuItem(value: 0, child: Text('全部')),
                        for (final c in oneOptions)
                          DropdownMenuItem(
                            value: _id(c['id']),
                            child: Text(
                              '${c['n']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      isExpanded: true,
                      onChanged: _writing
                          ? null
                          : (v) => setState(() {
                              _one = v!;
                              _two = 0;
                            }),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('high-margin-two-$_two'),
                      initialValue: twoOptions.any((c) => _id(c['id']) == _two)
                          ? _two
                          : 0,
                      decoration: const InputDecoration(labelText: '二级分类'),
                      items: [
                        const DropdownMenuItem(value: 0, child: Text('全部')),
                        for (final c in twoOptions)
                          DropdownMenuItem(
                            value: _id(c['id']),
                            child: Text(
                              '${c['n']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      isExpanded: true,
                      onChanged: _writing
                          ? null
                          : (v) => setState(() => _two = v!),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      key: const Key('high-margin-candidate-search'),
                      controller: _keyword,
                      enabled: !_writing,
                      decoration: const InputDecoration(labelText: '商品名称或拼音字母'),
                      onSubmitted: (_) => _load(true),
                    ),
                  ),
                  TextButton(
                    onPressed: _writing || !_ready ? null : () => _load(true),
                    child: const Text('查询候选'),
                  ),
                  TextButton(
                    onPressed: _writing
                        ? null
                        : () {
                            _keyword.clear();
                            setState(() {
                              _one = 0;
                              _two = 0;
                            });
                            _ready
                                ? unawaited(_load(true))
                                : unawaited(_initialize());
                          },
                    child: const Text('重置候选'),
                  ),
                ],
              ),
              Expanded(
                child: _items.isEmpty
                    ? Center(
                        child: Text(
                          _loading
                              ? '加载中…'
                              : _error == null
                              ? '暂无数据'
                              : '查询未成功',
                        ),
                      )
                    : _productTable(
                        _items,
                        _selected,
                        disabled: _already,
                        onSelect: _writing || _loading
                            ? null
                            : (id, selected) => setState(() {
                                selected
                                    ? _selected.add(id)
                                    : _selected.remove(id);
                              }),
                        onAll: _writing || _loading
                            ? null
                            : (all) => setState(() {
                                _selected.clear();
                                if (all) {
                                  _selected.addAll(
                                    _items
                                        .where((e) => !_already.contains(e.id))
                                        .map((e) => e.id),
                                  );
                                }
                              }),
                      ),
              ),
              TextButton(
                onPressed: _loading || _writing || _done || !_ready
                    ? null
                    : () => _load(false),
                child: Text(
                  _done
                      ? '没有更多了'
                      : _loading
                      ? '加载中…'
                      : '加载更多',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _invalid = true;
              Navigator.pop(context, false);
            },
            child: const Text('关闭'),
          ),
          FilledButton(
            key: const Key('high-margin-confirm-add'),
            onPressed: _writing || _loading || !_ready || _invalid
                ? null
                : _save,
            child: const Text('确定添加'),
          ),
        ],
      ),
    );
  }
}
