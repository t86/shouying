import 'dart:async';

import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_report_configuration.dart';
import 'package:flutter/material.dart';

typedef _Op = BmsReportConfigurationOperation;

List<Map<String, Object?>> _rows(Object? value, {String? owner}) {
  if (value == null) return [];
  if (value is! List || value.any((e) => e is! Map)) throw '配置数据无法识别';
  final rows = [for (final e in value) Map<String, Object?>.from(e as Map)];
  if (owner != null &&
      rows.any((row) => (int.tryParse('${row[owner]}') ?? -1) < 0)) {
    throw '配置归属数据缺失，请重新读取';
  }
  if (rows.any((r) => _id(r['id']) <= 0) ||
      rows.map((r) => _id(r['id'])).toSet().length != rows.length) {
    throw '配置编号无效';
  }
  return rows;
}

int _id(Object? value) => int.tryParse('$value') ?? 0;
String _text(Map<String, Object?> row, String key) => '${row[key] ?? ''}';
Object? _token(BmsLoader loader) => loader is BmsReportConfigurationLoader
    ? (loader as BmsReportConfigurationLoader).configurationContext
    : null;
Future<Map<String, Object?>> _request(
  BmsLoader loader,
  Object? token,
  _Op op,
  Map<String, Object?> parameters,
  bool Function() active,
) async {
  if (!active() || token == null || token != _token(loader)) {
    throw '登录或连接已变化，请重新打开页面';
  }
  final result = await (loader as BmsReportConfigurationLoader)
      .requestReportConfiguration(
        BmsReportConfigurationRequest(op, parameters: parameters),
      );
  if (!active() || token != _token(loader)) throw '登录或连接已变化，请重新打开页面';
  if (result.failureOrNull case final f?) throw f.safeMessage;
  return result.valueOrNull ?? {};
}

String _error(Object error) => error is String ? error : '请求失败，请重试';
bool _validName(String value) =>
    value.trim().isNotEmpty &&
    value.codeUnits.fold<int>(0, (n, c) => n + (c > 127 || c == 94 ? 2 : 1)) <=
        20;

class BmsStatisticalGroupConfigView extends StatelessWidget {
  const BmsStatisticalGroupConfigView({super.key, required this.loader});
  final BmsLoader loader;
  @override
  Widget build(BuildContext context) =>
      _ConfigurationPage(loader: loader, channels: false);
}

class BmsChannelGroupConfigView extends StatelessWidget {
  const BmsChannelGroupConfigView({super.key, required this.loader});
  final BmsLoader loader;
  @override
  Widget build(BuildContext context) =>
      _ConfigurationPage(loader: loader, channels: true);
}

class _ConfigurationPage extends StatefulWidget {
  const _ConfigurationPage({required this.loader, required this.channels});
  final BmsLoader loader;
  final bool channels;
  @override
  State<_ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<_ConfigurationPage> {
  late final Object? _session;
  List<Map<String, Object?>> _items = [];
  final _selected = <int>{};
  bool _busy = false, _dialog = false;
  String? _message;
  int _serial = 0;
  @override
  void initState() {
    super.initState();
    _session = _token(widget.loader);
    unawaited(_load());
  }

  @override
  void dispose() {
    _serial++;
    super.dispose();
  }

  Future<void> _load() async {
    final serial = ++_serial;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final data = await _request(
        widget.loader,
        _session,
        widget.channels ? _Op.channels : _Op.statistics,
        {},
        () => mounted && serial == _serial,
      );
      final rows = _rows(data['records']);
      if (!mounted || serial != _serial) return;
      setState(() {
        _items = rows;
        _selected.clear();
      });
    } on Object catch (e) {
      if (mounted && serial == _serial) setState(() => _message = _error(e));
    } finally {
      if (mounted && serial == _serial) setState(() => _busy = false);
    }
  }

  Future<void> _edit([
    Map<String, Object?>? row,
    String action = 'edit',
  ]) async {
    if (_busy || _dialog) return;
    _dialog = true;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GroupEditor(
        loader: widget.loader,
        token: _session,
        channels: widget.channels,
        row: row,
        action: action,
      ),
    );
    _dialog = false;
    if (mounted && result == true) await _load();
  }

  Future<void> _configure(Map<String, Object?> row) async {
    if (_busy || _dialog) return;
    if (![1, 2].contains(_id(row['t']))) {
      setState(() => _message = '统计模式无法识别');
      return;
    }
    _dialog = true;
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _id(row['t']) == 2
          ? _CategoryEditor(loader: widget.loader, token: _session, row: row)
          : _ProductEditor(loader: widget.loader, token: _session, row: row),
    );
    _dialog = false;
    if (mounted) await _load();
  }

  Future<void> _delete() async {
    if (_busy || _dialog) return;
    if (_selected.isEmpty) {
      setState(() => _message = '请勾选需要删除的类别');
      return;
    }
    final ids = _selected.toList();
    _dialog = true;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确认删除选中的 ${ids.length} 个类别？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定删除'),
          ),
        ],
      ),
    );
    _dialog = false;
    if (!mounted || yes != true) return;
    await _write(widget.channels ? _Op.deleteChannels : _Op.deleteStatistics, {
      'ids': ids,
    });
  }

  Future<void> _write(_Op operation, Map<String, Object?> body) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _request(widget.loader, _session, operation, body, () => mounted);
      if (mounted) await _load();
    } on Object catch (e) {
      if (mounted) setState(() => _message = _error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _move(int index, int delta) async {
    final target = index + delta;
    if (target < 0 || target >= _items.length) return;
    await _write(widget.channels ? _Op.moveChannel : _Op.moveStatistic, {
      'id': _id(_items[index]['id']),
      'dest_id': _id(_items[target]['id']),
      'down_up': delta < 0 ? 2 : 1,
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.channels ? '渠道类别配置' : '统计类别配置'),
      actions: [
        IconButton(
          onPressed: _busy ? null : _load,
          tooltip: '刷新',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _busy ? null : () => _edit(),
                child: const Text('新增类别'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _delete,
                child: const Text('批量删除'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        if (_selected.length == _items.length) {
                          _selected.clear();
                        } else {
                          _selected.addAll(_items.map((r) => _id(r['id'])));
                        }
                      }),
                child: const Text('全选/清空'),
              ),
            ],
          ),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_message!, style: const TextStyle(color: Colors.red)),
          ),
        if (_busy) const LinearProgressIndicator(),
        Expanded(
          child: _items.isEmpty
              ? const Center(child: Text('暂无类别'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final row = _items[index], id = _id(row['id']);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(_text(row, 'n')),
                              value: _selected.contains(id),
                              onChanged: _busy
                                  ? null
                                  : (v) => setState(() {
                                      v == true
                                          ? _selected.add(id)
                                          : _selected.remove(id);
                                    }),
                            ),
                            Text(
                              widget.channels
                                  ? '包含渠道：${_text(row, 'cs')}'
                                  : '${switch (_id(row['b'])) {
                                      1 => '主营',
                                      2 => '非主营',
                                      _ => '全部',
                                    }} · ${_text(row, 'tn')}\n包含：${_text(row, 'ct')}',
                            ),
                            Text(
                              '创建：${_text(row, 'c')}\n更新：${_text(row, 'u')}',
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: _busy ? null : () => _edit(row),
                                  child: Text(widget.channels ? '编辑' : '更改名称'),
                                ),
                                if (!widget.channels) ...[
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _edit(row, 'business'),
                                    child: const Text('更改营业类型'),
                                  ),
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _configure(row),
                                    child: const Text('配置'),
                                  ),
                                ],
                                IconButton(
                                  tooltip: '上移',
                                  onPressed: _busy || index == 0
                                      ? null
                                      : () => _move(index, -1),
                                  icon: const Icon(Icons.arrow_upward),
                                ),
                                IconButton(
                                  tooltip: '下移',
                                  onPressed: _busy || index == _items.length - 1
                                      ? null
                                      : () => _move(index, 1),
                                  icon: const Icon(Icons.arrow_downward),
                                ),
                              ],
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

class _GroupEditor extends StatefulWidget {
  const _GroupEditor({
    required this.loader,
    required this.token,
    required this.channels,
    required this.row,
    required this.action,
  });
  final BmsLoader loader;
  final Object? token;
  final bool channels;
  final Map<String, Object?>? row;
  final String action;
  @override
  State<_GroupEditor> createState() => _GroupEditorState();
}

class _GroupEditorState extends State<_GroupEditor> {
  late final TextEditingController _name;
  bool _busy = false, _active = true, _loaded = false;
  String? _error;
  int _biz = 3, _type = 2;
  List<Map<String, Object?>> _items = [];
  final _selected = <int>{};
  int get _idValue => _id(widget.row?['id']);
  bool get _business => widget.action == 'business';
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.row == null ? '' : _text(widget.row!, 'n'),
    );
    _biz = _id(widget.row?['b']);
    if (![1, 2, 3].contains(_biz)) _biz = 3;
    if (widget.channels) {
      unawaited(_load());
    } else {
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _active = false;
    _name.dispose();
    super.dispose();
  }

  bool get _current => mounted && _active;
  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final data = await _request(
        widget.loader,
        widget.token,
        _Op.channelItems,
        {},
        () => _current,
      );
      final rows = _rows(data['records'], owner: 'ci');
      if (!_current) return;
      setState(() {
        _items = rows;
        _selected.addAll(
          rows
              .where((r) => _id(r['ci']) == _idValue && _idValue > 0)
              .map((r) => _id(r['id'])),
        );
        _loaded = true;
      });
    } on Object catch (e) {
      if (_current) setState(() => _error = _errorText(e));
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  String _errorText(Object e) => _errorFor(e);
  Future<void> _save() async {
    if (_busy || !_loaded) return;
    if (!_business && !_validName(_name.text)) {
      setState(() => _error = '请输入类别名称，长度不超过20字符（中文计2）');
      return;
    }
    if (widget.channels && _selected.isEmpty) {
      setState(() => _error = '请至少选择一个渠道');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.channels) {
        final fresh = _rows(
          (await _request(
            widget.loader,
            widget.token,
            _Op.channelItems,
            {},
            () => _current,
          ))['records'],
          owner: 'ci',
        );
        if (_selected.any(
          (id) => !fresh.any(
            (r) =>
                _id(r['id']) == id &&
                (_id(r['ci']) == 0 || _id(r['ci']) == _idValue),
          ),
        )) {
          throw '渠道归属已变化，请重新打开配置';
        }
      }
      final operation = widget.channels
          ? _Op.saveChannel
          : _business
          ? _Op.saveStatisticBusinessType
          : widget.row == null
          ? _Op.createStatistic
          : _Op.renameStatistic;
      final body = <String, Object?>{
        if (widget.channels || widget.row != null) 'id': _idValue,
        if (!_business) 'name': _name.text.trim(),
        if (widget.channels) 'pay_cnl_ids': _selected.toList(),
        if (!widget.channels && widget.row == null) 'type_id': _type,
        if (!widget.channels && (widget.row == null || _business))
          'biz_type': _biz,
      };
      await _request(
        widget.loader,
        widget.token,
        operation,
        body,
        () => _current,
      );
      if (mounted && _current) {
        final route = ModalRoute.of(context);
        if (route?.isActive == true) {
          Navigator.of(context).removeRoute(route!, true);
        }
      }
    } on Object catch (e) {
      if (_current) setState(() => _error = _errorFor(e));
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<bool>(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) _active = false;
    },
    child: AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _business
                ? '更改营业类型'
                : widget.row == null
                ? '新增类别'
                : '编辑类别',
          ),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_business)
                TextField(
                  key: const Key('configuration-name'),
                  controller: _name,
                  enabled: !_busy,
                  decoration: const InputDecoration(labelText: '类别名称'),
                ),
              if (!widget.channels && (widget.row == null || _business))
                DropdownButtonFormField<int>(
                  initialValue: _biz,
                  decoration: const InputDecoration(labelText: '营业类型'),
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('全部')),
                    DropdownMenuItem(value: 1, child: Text('主营')),
                    DropdownMenuItem(value: 2, child: Text('非主营')),
                  ],
                  onChanged: _busy ? null : (v) => setState(() => _biz = v!),
                ),
              if (!widget.channels && widget.row == null)
                DropdownButtonFormField<int>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: '模式'),
                  items: const [
                    DropdownMenuItem(value: 2, child: Text('分类模式（推荐）')),
                    DropdownMenuItem(value: 1, child: Text('商品模式')),
                  ],
                  onChanged: _busy ? null : (v) => setState(() => _type = v!),
                ),
              if (widget.channels)
                for (final row in _items)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${_text(row, 'n')}${_id(row['ci']) > 0 ? ' - ${_text(row, 'cn')}' : ''}',
                    ),
                    value:
                        _selected.contains(_id(row['id'])) ||
                        (_id(row['ci']) > 0 && _id(row['ci']) != _idValue),
                    onChanged:
                        _busy ||
                            (_id(row['ci']) > 0 && _id(row['ci']) != _idValue)
                        ? null
                        : (v) => setState(() {
                            v == true
                                ? _selected.add(_id(row['id']))
                                : _selected.remove(_id(row['id']));
                          }),
                  ),
              if (_busy) const LinearProgressIndicator(),
              if (widget.channels && !_loaded && !_busy)
                TextButton(onPressed: _load, child: const Text('重试读取渠道')),
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
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('configuration-save'),
          onPressed: _busy || !_loaded ? null : _save,
          child: const Text('保存'),
        ),
      ],
    ),
  );
}

String _errorFor(Object e) => _error(e);

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({
    required this.loader,
    required this.token,
    required this.row,
  });
  final BmsLoader loader;
  final Object? token;
  final Map<String, Object?> row;
  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  List<Map<String, Object?>> _groups = [];
  final _selected = <int>{};
  bool _active = true, _busy = false, _loaded = false;
  String? _error;
  int get id => _id(widget.row['id']);
  bool get current => mounted && _active;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _active = false;
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final data = await _request(
        widget.loader,
        widget.token,
        _Op.statisticCategoryItems,
        {},
        () => current,
      );
      final groups = _rows(data['cates']);
      for (final group in groups) {
        for (final row in _rows(group['ss'], owner: 'ji')) {
          if (_id(row['ji']) == id) _selected.add(_id(row['id']));
        }
      }
      if (current) {
        setState(() {
          _groups = groups;
          _loaded = true;
        });
      }
    } on Object catch (e) {
      if (current) setState(() => _error = _errorFor(e));
    } finally {
      if (current) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_selected.isEmpty) {
      setState(() => _error = '请至少选择一个二级分类');
      return;
    }
    setState(() => _busy = true);
    try {
      final groups = _rows(
        (await _request(
          widget.loader,
          widget.token,
          _Op.statisticCategoryItems,
          {},
          () => current,
        ))['cates'],
      );
      final rows = [
        for (final group in groups) ..._rows(group['ss'], owner: 'ji'),
      ];
      if (_selected.any(
        (v) => !rows.any(
          (r) => _id(r['id']) == v && (_id(r['ji']) == 0 || _id(r['ji']) == id),
        ),
      )) {
        throw '分类归属已变化，请重新打开配置';
      }
      await _request(widget.loader, widget.token, _Op.saveStatisticCategories, {
        'id': id,
        'cate_ids': _selected.toList(),
      }, () => current);
      if (mounted && current) {
        final route = ModalRoute.of(context);
        if (route?.isActive == true) {
          Navigator.of(context).removeRoute(route!, true);
        }
      }
    } on Object catch (e) {
      if (current) setState(() => _error = _errorFor(e));
    } finally {
      if (current) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<bool>(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) _active = false;
    },
    child: AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('配置二级分类 - ${_text(widget.row, 'n')}'),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final group in _groups) ...[
                Text(_text(group, 'n')),
                for (final row in _rows(group['ss']))
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${_text(row, 'n')}${_id(row['ji']) > 0 ? ' - ${_text(row, 'jc')}' : ''}',
                    ),
                    value:
                        _selected.contains(_id(row['id'])) ||
                        (_id(row['ji']) > 0 && _id(row['ji']) != id),
                    onChanged:
                        _busy || (_id(row['ji']) > 0 && _id(row['ji']) != id)
                        ? null
                        : (v) => setState(() {
                            v == true
                                ? _selected.add(_id(row['id']))
                                : _selected.remove(_id(row['id']));
                          }),
                  ),
              ],
              if (_busy) const LinearProgressIndicator(),
              if (!_loaded && !_busy)
                TextButton(onPressed: _load, child: const Text('重试')),
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
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('configuration-save'),
          onPressed: _busy || !_loaded ? null : _save,
          child: const Text('保存'),
        ),
      ],
    ),
  );
}

class _ProductEditor extends StatefulWidget {
  const _ProductEditor({
    required this.loader,
    required this.token,
    required this.row,
  });
  final BmsLoader loader;
  final Object? token;
  final Map<String, Object?> row;
  @override
  State<_ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<_ProductEditor> {
  final _name = TextEditingController();
  final _selected = <int>{};
  List<Map<String, Object?>> _rowsValue = [], _categories = [];
  bool _adding = false, _busy = false, _active = true;
  int _one = 0, _two = 0;
  String? _error;
  bool get current => mounted && _active;
  int get id => _id(widget.row['id']);
  @override
  void initState() {
    super.initState();
    unawaited(_load(true));
  }

  @override
  void dispose() {
    _active = false;
    _name.dispose();
    super.dispose();
  }

  Map<String, Object?> filters(bool init) => {
    if (!_adding) 'id': id,
    'init': init ? 1 : 2,
    'one_cate_id': _one,
    'two_cate_id': _two,
    'name': _name.text.trim(),
  };
  Future<void> _load(bool init) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final data = await _request(
        widget.loader,
        widget.token,
        _adding ? _Op.statisticProductItems : _Op.statisticProducts,
        filters(init),
        () => current,
      );
      final rows = _rows(data['prds'], owner: _adding ? 'ji' : null);
      final categories = init ? _rows(data['cates']) : _categories;
      if (current) {
        setState(() {
          _rowsValue = rows;
          _categories = categories;
          _selected.clear();
          _error = null;
        });
      }
    } on Object catch (e) {
      if (current) setState(() => _error = _errorFor(e));
    } finally {
      if (current) setState(() => _busy = false);
    }
  }

  Future<void> _changeMode() async {
    if (_busy) return;
    setState(() {
      _adding = !_adding;
      _name.clear();
      _one = 0;
      _two = 0;
      _selected.clear();
    });
    await _load(true);
  }

  Future<void> _reset() async {
    if (_busy) return;
    setState(() {
      _name.clear();
      _one = 0;
      _two = 0;
      _selected.clear();
    });
    await _load(true);
  }

  String _productDescription(Map<String, Object?> row) {
    final one = _categories
        .where((c) => _id(c['id']) == _id(row[_adding ? 'oi' : 'oc']))
        .firstOrNull;
    final two = one == null
        ? null
        : _rows(one['ss'])
              .where((c) => _id(c['id']) == _id(row[_adding ? 'ti' : 'tc']))
              .firstOrNull;
    return '${one == null ? '未知分类' : _text(one, 'n')} > ${two == null ? '未知分类' : _text(two, 'n')}\n商品类型：${_text(row, 't')} · 营业类型：${_text(row, 'b')}';
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_selected.isEmpty) {
      setState(() => _error = '请选择商品');
      return;
    }
    if (!_adding) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('移除商品'),
          content: Text('确认移除 ${_selected.length} 个商品关联？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确定移除'),
            ),
          ],
        ),
      );
      if (!current || yes != true) return;
    }
    setState(() => _busy = true);
    try {
      final fresh = _rows(
        (await _request(
          widget.loader,
          widget.token,
          _adding ? _Op.statisticProductItems : _Op.statisticProducts,
          filters(false),
          () => current,
        ))['prds'],
        owner: _adding ? 'ji' : null,
      );
      if (_selected.any(
        (v) => !fresh.any(
          (r) => _id(r['id']) == v && (!_adding || _id(r['ji']) == 0),
        ),
      )) {
        throw '商品归属已变化，请重新查询';
      }
      await _request(
        widget.loader,
        widget.token,
        _adding ? _Op.addStatisticProducts : _Op.deleteStatisticProducts,
        {'id': id, 'prd_ids': _selected.toList()},
        () => current,
      );
      if (current) {
        setState(() => _busy = false);
        if (_adding) {
          await _changeMode();
        } else {
          await _load(false);
        }
      }
    } on Object catch (e) {
      if (current) setState(() => _error = _errorFor(e));
    } finally {
      if (current) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seconds = [
      for (final row in _categories.where((r) => _id(r['id']) == _one))
        ..._rows(row['ss']),
    ];
    return PopScope<bool>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _active = false;
      },
      child: AlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_adding ? '添加' : '已关联'}商品 - ${_text(widget.row, 'n')}'),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _name,
                  enabled: !_busy,
                  decoration: const InputDecoration(labelText: '商品名称'),
                  onSubmitted: (_) => _load(false),
                ),
                DropdownButtonFormField<int>(
                  key: ValueKey('one-$_one'),
                  initialValue: _one,
                  decoration: const InputDecoration(labelText: '一级分类'),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('全部')),
                    for (final row in _categories)
                      DropdownMenuItem(
                        value: _id(row['id']),
                        child: Text(_text(row, 'n')),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => setState(() {
                          _one = v!;
                          _two = 0;
                        }),
                ),
                DropdownButtonFormField<int>(
                  key: ValueKey('two-$_one-$_two'),
                  initialValue: _two,
                  decoration: const InputDecoration(labelText: '二级分类'),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('全部')),
                    for (final row in seconds)
                      DropdownMenuItem(
                        value: _id(row['id']),
                        child: Text(_text(row, 'n')),
                      ),
                  ],
                  onChanged: _busy ? null : (v) => setState(() => _two = v!),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: _busy ? null : () => _load(false),
                      child: const Text('查询'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _reset,
                      child: const Text('重置'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _changeMode,
                      child: Text(_adding ? '返回已关联' : '添加商品'),
                    ),
                  ],
                ),
                for (final row in _rowsValue)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${_text(row, 'n')}${_adding && _id(row['ji']) != 0 ? '（已归属${_text(row, 'jc')}）' : ''}',
                    ),
                    subtitle: Text(_productDescription(row)),
                    value:
                        _selected.contains(_id(row['id'])) ||
                        (_adding && _id(row['ji']) != 0),
                    onChanged: _busy || (_adding && _id(row['ji']) != 0)
                        ? null
                        : (v) => setState(() {
                            v == true
                                ? _selected.add(_id(row['id']))
                                : _selected.remove(_id(row['id']));
                          }),
                  ),
                if (_busy) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _active = false;
              Navigator.pop(context, true);
            },
            child: const Text('关闭'),
          ),
          FilledButton(
            key: const Key('configuration-save'),
            onPressed: _busy ? null : _save,
            child: Text(_adding ? '添加所选' : '移除所选'),
          ),
        ],
      ),
    );
  }
}
