import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';

import 'package:card_table/src/wine_loader.dart';

class _Line {
  _Line(this.id);
  final int id;
  final search = TextEditingController();
  final count = TextEditingController(text: '0');
  final remark = TextEditingController();
  List<Map<String, Object?>> options = [];
  int? productId;
  int? available;
  int request = 0;
  bool loading = false;
  void dispose() {
    search.dispose();
    count.dispose();
    remark.dispose();
  }
}

/// Source borrowWine/returnWine: five optional rows, one employee, parallel arrays.
class WineBorrowFormDialog extends StatefulWidget {
  const WineBorrowFormDialog({
    required this.loader,
    required this.returning,
    super.key,
  });
  final WineLoader loader;
  final bool returning;
  @override
  State<WineBorrowFormDialog> createState() => _WineBorrowFormDialogState();
}

class _WineBorrowFormDialogState extends State<WineBorrowFormDialog> {
  final _employeeSearch = TextEditingController();
  final _lines = List.generate(5, _Line.new);
  final _standaloneContext = Object();
  Object? _openedContext;
  List<Map<String, Object?>> _employees = [];
  int? _employeeId;
  String _employeeName = '';
  int _employeeRequest = 0, _serial = 5;
  bool _employeeLoading = false, _busy = false, _invalid = false;
  String? _error;
  String get _action => widget.returning ? '还酒' : '借酒';
  String get _stockLabel => widget.returning ? '未还数量' : '可借数量';
  Object? get _currentContext => widget.loader is WineBorrowFormContext
      ? (widget.loader as WineBorrowFormContext).borrowFormContext
      : _standaloneContext;
  bool get _current {
    if (!mounted || _invalid) return false;
    if (_openedContext == null || _openedContext != _currentContext) {
      _invalid = true;
      return false;
    }
    return true;
  }

  bool _checkCurrent() {
    if (_current) return true;
    if (mounted) setState(() => _error = '登录或连接状态已改变，请重新打开表单');
    return false;
  }

  static int? _integer(Object? value) {
    if (value is int) return value;
    if (value is String && RegExp(r'^\d+$').hasMatch(value)) {
      return int.tryParse(value);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _openedContext = _currentContext;
  }

  @override
  void dispose() {
    _invalid = true;
    _employeeSearch.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _fail(String message) {
    if (mounted) setState(() => _error = message);
  }

  Future<void> _findEmployee() async {
    if (!_checkCurrent() || _busy) return;
    final query = _employeeSearch.text.trim();
    final request = ++_employeeRequest;
    setState(() {
      _employeeLoading = true;
      _employees = [];
      _error = null;
    });
    try {
      if (query.isEmpty) return;
      final result = await widget.loader.loadWineBorrowEmployees(query);
      if (!_checkCurrent() || request != _employeeRequest) return;
      if (result.failureOrNull case final failure?) {
        _fail(failure.safeMessage);
        return;
      }
      final rows = result.valueOrNull;
      if (rows == null ||
          rows.any((r) => (_integer(r['id']) ?? 0) <= 0 || r['n'] is! String)) {
        _fail('员工数据无法识别，请重试');
        return;
      }
      setState(() => _employees = rows);
      if (rows.isEmpty) _fail('没有匹配的员工');
    } on Object {
      _fail('员工查询失败，请重试');
    } finally {
      if (mounted && request == _employeeRequest) {
        setState(() => _employeeLoading = false);
      }
    }
  }

  Future<Result<List<Map<String, Object?>>>> _products(String query) =>
      widget.returning
      ? widget.loader.loadWineReturnOptions(keyword: query)
      : widget.loader.loadWineCanBorrowList(keyword: query);
  bool _validOptions(List<Map<String, Object?>>? rows) =>
      rows != null &&
      rows.every(
        (r) =>
            (_integer(r['id']) ?? 0) > 0 &&
            r['n'] is String &&
            (_integer(r['c']) ?? -1) >= 0,
      ) &&
      rows.map((r) => _integer(r['id'])).toSet().length == rows.length;
  Future<void> _findProducts(_Line line) async {
    if (!_checkCurrent() || _busy) return;
    final request = ++line.request;
    final query = line.search.text.trim();
    setState(() {
      line.loading = true;
      line.options = [];
      line.productId = null;
      line.available = null;
      line.count.text = '0';
      _error = null;
    });
    try {
      if (query.isEmpty) return;
      final result = await _products(query);
      if (!_checkCurrent() ||
          !_lines.contains(line) ||
          request != line.request) {
        return;
      }
      if (result.failureOrNull case final failure?) {
        _fail(failure.safeMessage);
        return;
      }
      if (!_validOptions(result.valueOrNull)) {
        _fail('酒水库存数据无法识别，请重试');
        return;
      }
      setState(() => line.options = result.valueOrNull!);
      if (line.options.isEmpty) _fail('没有匹配的酒水');
    } on Object {
      _fail('酒水查询失败，请重试');
    } finally {
      if (mounted && _lines.contains(line) && request == line.request) {
        setState(() => line.loading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_busy || !_checkCurrent()) return;
    if (_employeeId == null) {
      _fail('请选择$_action人');
      return;
    }
    final selected = <_Line>[];
    final totals = <int, int>{};
    for (final line in _lines) {
      final count = _integer(line.count.text.trim());
      if (count == 0) continue;
      if (line.productId == null &&
          (count == null || count == 0) &&
          line.remark.text.isEmpty) {
        continue;
      }
      if (line.productId == null ||
          count == null ||
          count <= 0 ||
          line.available == null ||
          count > line.available! ||
          line.remark.text.runes.length > 30) {
        _fail('请选择有效商品并输入正整数，$_action数量不能超过$_stockLabel，备注不超过30字');
        return;
      }
      selected.add(line);
      totals.update(line.productId!, (n) => n + count, ifAbsent: () => count);
    }
    if (selected.isEmpty) {
      _fail('请至少添加一个有效的$_action商品');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final route = ModalRoute.of(context);
    final navigator = Navigator.of(context);
    try {
      // Re-read current availability; cancel/dispose during this read must not write.
      final fresh = await _products('');
      if (!_checkCurrent()) return;
      if (fresh.failureOrNull case final failure?) {
        _fail(failure.safeMessage);
        return;
      }
      if (!_validOptions(fresh.valueOrNull)) {
        _fail('酒水库存数据无法识别，请重试');
        return;
      }
      final limits = {
        for (final row in fresh.valueOrNull!)
          _integer(row['id'])!: _integer(row['c'])!,
      };
      if (totals.entries.any(
        (e) => !limits.containsKey(e.key) || e.value > limits[e.key]!,
      )) {
        _fail('$_action数量不能超过最新$_stockLabel（同商品合计），请调整后重试');
        return;
      }
      if (!_checkCurrent()) return;
      final body = <String, Object?>{
        'br_emp_id': _employeeId,
        'prd_ids': [for (final l in selected) l.productId!],
        'prd_cnts': [for (final l in selected) int.parse(l.count.text.trim())],
        'remarks': [for (final l in selected) l.remark.text],
      };
      final result = widget.returning
          ? await widget.loader.submitWineReturn(body)
          : await widget.loader.submitWineBorrow(body);
      if (!_checkCurrent()) return;
      if (result.failureOrNull case final failure?) {
        _fail(failure.safeMessage);
        return;
      }
      if (route?.isActive == true) navigator.removeRoute(route!, true);
    } on Object {
      _fail('$_action请求失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<bool>(
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) _invalid = true;
    },
    child: AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('新增$_action'),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
        ],
      ),
      insetPadding: const EdgeInsets.all(12),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('wine-form-employee-search'),
                controller: _employeeSearch,
                enabled: !_busy,
                decoration: InputDecoration(labelText: '搜索$_action人员'),
                onSubmitted: (_) => _findEmployee(),
              ),
              TextButton(
                key: const Key('wine-form-employee-find'),
                onPressed: _busy || _employeeLoading ? null : _findEmployee,
                child: const Text('查询员工'),
              ),
              if (_employeeName.isNotEmpty) Text('已选$_action人：$_employeeName'),
              for (final employee in _employees)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _employeeId = _integer(employee['id']);
                          _employeeName = employee['n'] as String;
                          _employees = [];
                        }),
                  child: Text(employee['n'] as String),
                ),
              for (final line in _lines)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('商品 ${_lines.indexOf(line) + 1}'),
                            ),
                            IconButton(
                              tooltip: '删除商品',
                              onPressed: _busy || _lines.length <= 1
                                  ? null
                                  : () {
                                      setState(() => _lines.remove(line));
                                      line.dispose();
                                    },
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                        TextField(
                          key: Key('wine-form-search-${line.id}'),
                          controller: line.search,
                          enabled: !_busy,
                          decoration: const InputDecoration(
                            labelText: '酒水名称或拼音简写',
                          ),
                          onSubmitted: (_) => _findProducts(line),
                        ),
                        TextButton(
                          key: Key('wine-form-find-${line.id}'),
                          onPressed: _busy || line.loading
                              ? null
                              : () => _findProducts(line),
                          child: const Text('查询酒水'),
                        ),
                        DropdownButtonFormField<int>(
                          key: Key('wine-form-choice-${line.id}'),
                          initialValue: line.productId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: '选择酒水'),
                          items: [
                            for (final row in line.options)
                              DropdownMenuItem(
                                value: _integer(row['id']),
                                child: Text(
                                  row['n'] as String,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _busy
                              ? null
                              : (value) => setState(() {
                                  line.productId = value;
                                  line.available = _integer(
                                    line.options.firstWhere(
                                      (r) => _integer(r['id']) == value,
                                    )['c'],
                                  );
                                  line.count.text = '0';
                                }),
                        ),
                        Text('$_stockLabel：${line.available ?? "待选择"}'),
                        TextField(
                          key: Key('wine-form-count-${line.id}'),
                          controller: line.count,
                          enabled: !_busy,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: '$_action数量'),
                        ),
                        TextField(
                          key: Key('wine-form-remark-${line.id}'),
                          controller: line.remark,
                          enabled: !_busy,
                          maxLength: 30,
                          decoration: const InputDecoration(labelText: '备注'),
                        ),
                      ],
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => setState(() => _lines.add(_Line(_serial++))),
                icon: const Icon(Icons.add),
                label: const Text('添加商品'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _invalid = true;
            Navigator.of(context).pop(false);
          },
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('wine-form-submit'),
          onPressed: _busy || _invalid ? null : _submit,
          child: Text(_busy ? '处理中' : '确认$_action'),
        ),
      ],
    ),
  );
}
