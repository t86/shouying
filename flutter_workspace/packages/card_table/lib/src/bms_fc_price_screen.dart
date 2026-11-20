import 'dart:async';

import 'package:card_table/src/bms_fc_price.dart';
import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_models.dart';
import 'package:card_table/src/management_route_observer.dart';
import 'package:flutter/material.dart';

class BmsFcPriceScreen extends StatefulWidget {
  const BmsFcPriceScreen({required this.loader, super.key});
  final BmsLoader loader;
  @override
  State<BmsFcPriceScreen> createState() => _BmsFcPriceState();
}

class _BmsFcPriceState extends State<BmsFcPriceScreen> {
  bool _products = true, _busy = false;
  String? _error, _notice;
  final _keyword = TextEditingController();
  final _selected = <int>{};
  final _drafts = <String, TextEditingController>{};
  BmsFcMatrix? _matrix;
  List<BmsFcPlan> _plans = [];
  int _version = 0;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _version++;
    _keyword.dispose();
    for (final ctrl in _drafts.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final version = ++_version;
    setState(() {
      _busy = true;
      _error = null;
      _selected.clear();
    });
    try {
      final data = await _fcData(
        widget.loader,
        BmsFcPriceRequest(
          _products ? BmsFcPriceOperation.products : BmsFcPriceOperation.plans,
          key: _keyword.text.trim(),
        ),
      );
      if (!mounted || version != _version) return;
      if (_products) {
        final matrix = BmsFcMatrix.fromWire(data);
        for (final ctrl in _drafts.values) {
          ctrl.dispose();
        }
        _drafts.clear();
        for (final product in matrix.products) {
          for (final plan in matrix.plans) {
            _drafts['${product.id}:${plan.id}'] = TextEditingController(
              text: bmsFcCentsToYuan(matrix.priceFor(product, plan)),
            );
          }
        }
        _matrix = matrix;
      } else {
        _plans = bmsFcRows(data['records']).map(BmsFcPlan.fromWire).toList();
      }
    } catch (error) {
      if (mounted && version == _version) _error = _fcError(error);
    }
    if (mounted && version == _version) setState(() => _busy = false);
  }

  Future<void> _savePrice(BmsFcCandidate product, BmsFcPlan plan) async {
    if (_busy) return;
    try {
      final cents = bmsFcYuanToCents(_drafts['${product.id}:${plan.id}']!.text);
      setState(() {
        _busy = true;
        _error = null;
        _notice = null;
      });
      await _fcData(
        widget.loader,
        BmsFcPriceRequest(
          BmsFcPriceOperation.savePrice,
          productId: product.id,
          planId: plan.id,
          amount: cents,
        ),
      );
      if (mounted) {
        setState(() {
          _drafts['${product.id}:${plan.id}']!.text = bmsFcCentsToYuan(cents);
          _notice = '价格已保存';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = _fcError(error));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _delete() async {
    if (_busy || _selected.isEmpty) return;
    setState(() => _busy = true);
    final yes = await _fcConfirm(
      context,
      '批量删除',
      _products ? '确认删除所选商品？删除后这些商品不再受方案价格限制。' : '确认删除所选价格方案？相关员工不再受这些方案价格限制。',
    );
    if (!mounted) return;
    if (!yes) {
      setState(() => _busy = false);
      return;
    }
    try {
      await _fcData(
        widget.loader,
        BmsFcPriceRequest(
          _products
              ? BmsFcPriceOperation.deleteProducts
              : BmsFcPriceOperation.deletePlans,
          ids: _selected.toList(),
        ),
      );
      if (mounted) await _load();
    } catch (error) {
      if (mounted) setState(() => _error = _fcError(error));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _edit([BmsFcPlan? plan]) async {
    if (_busy) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(
          name: ManagementRouteObserver.childRouteName,
        ),
        builder: (_) =>
            _FcEditor(loader: widget.loader, products: _products, plan: plan),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('价格方案配置')),
    body: Column(
      children: [
        Wrap(
          spacing: 12,
          children: [
            for (final product in [true, false])
              ChoiceChip(
                label: Text(product ? '商品列表' : '价格方案管理'),
                selected: _products == product,
                onSelected: _busy
                    ? null
                    : (_) {
                        setState(() {
                          _products = product;
                          _notice = null;
                        });
                        unawaited(_load());
                      },
              ),
          ],
        ),
        if (_products)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('未配置方案价格时使用商品原单价；价格以元输入，可保存0元。'),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_products)
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _keyword,
                    enabled: !_busy,
                    decoration: const InputDecoration(labelText: '商品名称/拼音'),
                    onSubmitted: (_) => unawaited(_load()),
                  ),
                ),
              if (_products)
                TextButton(
                  onPressed: _busy ? null : _load,
                  child: const Text('查询'),
                ),
              if (_products)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () {
                          _keyword.clear();
                          unawaited(_load());
                        },
                  child: const Text('重置'),
                ),
              FilledButton(
                onPressed: _busy ? null : () => unawaited(_edit()),
                child: Text(_products ? '添加商品' : '新增方案'),
              ),
              if (!_products)
                TextButton(
                  onPressed: _busy || _selected.length != 1
                      ? null
                      : () => unawaited(
                          _edit(
                            _plans.firstWhere((p) => p.id == _selected.single),
                          ),
                        ),
                  child: const Text('编辑方案'),
                ),
              TextButton(
                onPressed: _busy || _selected.isEmpty ? null : _delete,
                child: const Text('批量删除'),
              ),
            ],
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        if (_notice != null) Text(_notice!),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: _products ? _productTable() : _planTable(),
            ),
          ),
        ),
      ],
    ),
  );
  void _choose(int id, bool? selected) => setState(() {
    if (selected == true) {
      _selected.add(id);
    } else {
      _selected.remove(id);
    }
  });
  Widget _productTable() => DataTable(
    columns: [
      for (final text in ['商品名称', '一级分类', '二级分类', '原单价（元）'])
        DataColumn(label: Text(text)),
      for (final plan in _matrix?.plans ?? <BmsFcPlan>[])
        DataColumn(label: Text(plan.name)),
    ],
    rows: [
      for (final product in _matrix?.products ?? <BmsFcCandidate>[])
        DataRow(
          selected: _selected.contains(product.id),
          onSelectChanged: _busy ? null : (v) => _choose(product.id, v),
          cells: [
            DataCell(Text(product.name)),
            DataCell(Text(product.oneCate)),
            DataCell(Text(product.twoCate)),
            DataCell(Text(bmsFcCentsToYuan(product.price))),
            for (final plan in _matrix!.plans)
              DataCell(
                Row(
                  children: [
                    SizedBox(
                      width: 95,
                      child: TextField(
                        key: Key('fc-price-${product.id}-${plan.id}'),
                        controller: _drafts['${product.id}:${plan.id}'],
                        enabled: !_busy,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    TextButton(
                      key: Key('fc-save-${product.id}-${plan.id}'),
                      onPressed: _busy
                          ? null
                          : () => unawaited(_savePrice(product, plan)),
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ),
          ],
        ),
    ],
  );
  Widget _planTable() => DataTable(
    columns: [
      for (final text in ['方案名称', '包含员工数量', '创建时间', '更新时间'])
        DataColumn(label: Text(text)),
    ],
    rows: [
      for (final plan in _plans)
        DataRow(
          selected: _selected.contains(plan.id),
          onSelectChanged: _busy ? null : (v) => _choose(plan.id, v),
          cells: [
            DataCell(Text(plan.name)),
            DataCell(Text(plan.employees)),
            DataCell(Text(plan.created)),
            DataCell(Text(plan.updated)),
          ],
        ),
    ],
  );
}

class _FcEditor extends StatefulWidget {
  const _FcEditor({required this.loader, required this.products, this.plan});
  final BmsLoader loader;
  final bool products;
  final BmsFcPlan? plan;
  @override
  State<_FcEditor> createState() => _FcEditorState();
}

class _FcEditorState extends State<_FcEditor> {
  final _name = TextEditingController(), _keyword = TextEditingController();
  final _selected = <int, BmsFcCandidate>{},
      _checked = <int>{},
      _departments = <int>{};
  List<BmsFcCandidate> _candidates = [];
  List<Map<String, Object?>> _categories = [];
  final Map<int, String> _deptOptions = {};
  int _one = 0, _two = 0, _version = 0;
  bool _busy = false, _ready = false;
  String? _error, _notice;
  @override
  void initState() {
    super.initState();
    _name.text = widget.plan?.name ?? '';
    unawaited(_search(initial: true));
    if (!widget.products) unawaited(_loadDepartments());
  }

  @override
  void dispose() {
    _version++;
    _name.dispose();
    _keyword.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    final result = await widget.loader.loadDepartments();
    if (!mounted) return;
    void visit(List<BmsDepartmentOption> rows, String prefix) {
      for (final row in rows) {
        _deptOptions[bmsFcInt(row.id)] = '$prefix${row.name}';
        visit(row.children, '$prefix${row.name} / ');
      }
    }

    try {
      if (result.failureOrNull != null) {
        setState(() => _error = result.failureOrNull!.safeMessage);
      } else {
        visit(result.valueOrNull!, '');
        setState(() {});
      }
    } catch (_) {
      if (mounted) setState(() => _error = '部门数据无法识别');
    }
  }

  Future<void> _search({bool initial = false}) async {
    if (_busy) return;
    final version = ++_version;
    initial = initial || !_ready;
    if (initial) {
      _keyword.clear();
      _one = _two = 0;
      _departments.clear();
    }
    setState(() {
      _busy = true;
      _error = null;
      _checked.clear();
    });
    try {
      final records = <int, BmsFcCandidate>{};
      if (widget.products) {
        final data = await _fcData(
          widget.loader,
          BmsFcPriceRequest(
            BmsFcPriceOperation.productItems,
            key: _keyword.text.trim(),
            oneCateId: _one,
            twoCateId: _two,
          ),
        );
        if (!mounted || version != _version) return;
        _categories = bmsFcRows(data['cates']);
        for (final row in bmsFcRows(data['records'])) {
          final candidate = BmsFcCandidate.fromWire(row, product: true);
          records[candidate.id] = candidate;
        }
      } else {
        for (final dept in _departments.isEmpty ? [0] : _departments.toList()) {
          final data = await _fcData(
            widget.loader,
            BmsFcPriceRequest(
              BmsFcPriceOperation.employeeItems,
              planId: widget.plan?.id ?? 0,
              deptId: dept,
              key: _keyword.text.trim(),
            ),
          );
          if (!mounted || version != _version) return;
          for (final row in bmsFcRows(data['records'])) {
            final candidate = BmsFcCandidate.fromWire(row, product: false);
            records[candidate.id] = candidate;
          }
        }
      }
      if (!mounted || version != _version) return;
      setState(() {
        _candidates = records.values.toList();
        if (initial && !widget.products) {
          _selected.clear();
          for (final row in _candidates.where((r) => r.status == 1)) {
            _selected[row.id] = row;
          }
        }
        _ready = true;
      });
    } catch (error) {
      if (mounted && version == _version) {
        setState(() => _error = _fcError(error));
      }
    }
    if (mounted && version == _version) setState(() => _busy = false);
  }

  Future<void> _removeAssigned(
    BmsFcCandidate row, {
    bool addToCurrent = false,
  }) async {
    if (_busy || ![1, 2].contains(row.status) || row.planId <= 0) return;
    if (addToCurrent && row.status != 2) return;
    setState(() => _busy = true);
    final yes = await _fcConfirm(
      context,
      addToCurrent ? '移除并添加' : '移除方案人员',
      '确认将“${row.name}”从“${row.planName}”移除${addToCurrent ? '并加入当前方案的已选列表' : ''}？移除立即生效，取消当前编辑也不会恢复。${addToCurrent ? '加入当前方案需点击确定保存。' : ''}',
    );
    if (!mounted) return;
    if (!yes) {
      setState(() => _busy = false);
      return;
    }
    try {
      await _fcData(
        widget.loader,
        BmsFcPriceRequest(
          BmsFcPriceOperation.removeEmployee,
          planId: row.planId,
          employeeId: row.id,
        ),
      );
      if (mounted) {
        setState(() {
          _version++;
          _selected.remove(row.id);
          _checked.remove(row.id);
          row.status = 0;
          row.planId = 0;
          row.planName = '';
          if (addToCurrent) _selected[row.id] = row;
          _notice = addToCurrent
              ? '已移除并加入已选列表，请点击确定保存；取消编辑不会恢复原方案。'
              : '已从原方案移除；取消编辑不会恢复。可重新选择后保存加入当前方案。';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = _fcError(error));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save() async {
    if (_busy || !_ready) return;
    if (widget.products && _selected.isEmpty) {
      setState(() => _error = '请选择商品');
      return;
    }
    if (!widget.products &&
        (_name.text.trim().isEmpty || _name.text.trim().length > 50)) {
      setState(() => _error = '请输入50字以内方案名称');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _fcData(
        widget.loader,
        BmsFcPriceRequest(
          widget.products
              ? BmsFcPriceOperation.addProducts
              : widget.plan == null
              ? BmsFcPriceOperation.addPlan
              : BmsFcPriceOperation.savePlan,
          planId: widget.plan?.id ?? 0,
          name: _name.text.trim(),
          ids: _selected.keys.toList(),
        ),
      );
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.pop(context);
        return;
      }
    } catch (error) {
      if (mounted) setState(() => _error = _fcError(error));
    }
    if (mounted) setState(() => _busy = false);
  }

  Widget? _assignedActions(BmsFcCandidate row) {
    if (widget.products || ![1, 2].contains(row.status) || row.planId <= 0) {
      return null;
    }
    return Wrap(
      children: [
        TextButton(
          key: Key('fc-remove-assigned-${row.id}'),
          onPressed: _busy ? null : () => unawaited(_removeAssigned(row)),
          child: const Text('从原方案移除'),
        ),
        if (row.status == 2)
          TextButton(
            key: Key('fc-remove-add-${row.id}'),
            onPressed: _busy
                ? null
                : () => unawaited(_removeAssigned(row, addToCurrent: true)),
            child: const Text('移除并添加'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final oneOptions = {
      0: '全部一级分类',
      for (final row in _categories) bmsFcInt(row['id']): '${row['n'] ?? ''}',
    };
    final category = _categories
        .where((row) => bmsFcInt(row['id']) == _one)
        .firstOrNull;
    final twoOptions = {
      0: '全部二级分类',
      for (final row in bmsFcRows(category?['cs']))
        bmsFcInt(row['id']): '${row['n'] ?? ''}',
    };
    final compact = MediaQuery.sizeOf(context).width < 700;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.products
                ? '添加商品'
                : widget.plan == null
                ? '新增价格方案'
                : '编辑价格方案',
          ),
        ),
        body: Column(
          children: [
            if (_busy) const LinearProgressIndicator(),
            if (!widget.products)
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  key: const Key('fc-plan-name'),
                  controller: _name,
                  maxLength: 50,
                  enabled: !_busy,
                  decoration: const InputDecoration(labelText: '方案名称（必填）'),
                ),
              ),
            if (!widget.products)
              const Text('移除原方案员工立即生效；加入当前方案需点确定。取消不会恢复已移除员工。'),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_notice != null) Text(_notice!),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 8,
                children: [
                  if (widget.products) ...[
                    DropdownButton<int>(
                      value: oneOptions.containsKey(_one) ? _one : 0,
                      items: oneOptions.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: _busy
                          ? null
                          : (v) => setState(() {
                              _one = v!;
                              _two = 0;
                            }),
                    ),
                    DropdownButton<int>(
                      value: twoOptions.containsKey(_two) ? _two : 0,
                      items: twoOptions.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _two = v!),
                    ),
                  ],
                  if (!widget.products)
                    for (final dept in _deptOptions.entries)
                      FilterChip(
                        label: Text(dept.value),
                        selected: _departments.contains(dept.key),
                        onSelected: _busy
                            ? null
                            : (v) => setState(() {
                                if (v) {
                                  _departments.add(dept.key);
                                } else {
                                  _departments.remove(dept.key);
                                }
                              }),
                      ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      key: const Key('fc-candidate-key'),
                      controller: _keyword,
                      enabled: !_busy,
                      decoration: InputDecoration(
                        labelText: widget.products ? '商品名称/拼音' : '工号/姓名',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => unawaited(_search()),
                    child: const Text('查询候选'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            _keyword.clear();
                            _one = _two = 0;
                            _departments.clear();
                            unawaited(_search());
                          },
                    child: const Text('重置'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Flex(
                direction: compact ? Axis.vertical : Axis.horizontal,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('待选${widget.products ? '商品' : '员工'}'),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                  if (_checked.isNotEmpty) {
                                    _checked.clear();
                                  } else {
                                    _checked.addAll(
                                      _candidates
                                          .where(
                                            (row) => !row.unavailable(
                                              widget.products,
                                              _selected.keys,
                                            ),
                                          )
                                          .map((row) => row.id),
                                    );
                                  }
                                }),
                          child: const Text('全选候选/取消全选'),
                        ),
                        Expanded(
                          child: ListView(
                            children: [
                              for (final row in _candidates)
                                Column(
                                  children: [
                                    CheckboxListTile(
                                      key: Key('fc-candidate-${row.id}'),
                                      value:
                                          row.configured ||
                                          _selected.containsKey(row.id) ||
                                          _checked.contains(row.id),
                                      onChanged:
                                          _busy ||
                                              row.unavailable(
                                                widget.products,
                                                _selected.keys,
                                              )
                                          ? null
                                          : (v) => setState(() {
                                              if (v == true) {
                                                _checked.add(row.id);
                                              } else {
                                                _checked.remove(row.id);
                                              }
                                            }),
                                      title: Text(
                                        '${row.name}${widget.products ? '' : ' (${row.code})'}',
                                      ),
                                      subtitle: Text(
                                        widget.products
                                            ? '${row.oneCate}/${row.twoCate} · ${bmsFcCentsToYuan(row.price)}元${row.configured ? ' · 已配置' : ''}'
                                            : '${row.department} · ${row.planName.isNotEmpty
                                                  ? row.planName
                                                  : row.status == 2
                                                  ? '其他方案占用'
                                                  : _selected.containsKey(row.id)
                                                  ? '已选'
                                                  : ''}',
                                      ),
                                      secondary: compact
                                          ? null
                                          : _assignedActions(row),
                                    ),
                                    if (compact)
                                      _assignedActions(row) ??
                                          const SizedBox.shrink(),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _busy || _checked.isEmpty
                        ? null
                        : () => setState(() {
                            for (final row in _candidates) {
                              if (_checked.contains(row.id) &&
                                  !row.unavailable(
                                    widget.products,
                                    _selected.keys,
                                  )) {
                                _selected[row.id] = row;
                              }
                            }
                            _checked.clear();
                          }),
                    child: const Text('添加 >'),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('已选（${_selected.length}）'),
                        Expanded(
                          child: ListView(
                            children: [
                              for (final row in _selected.values)
                                ListTile(
                                  key: Key('fc-selected-${row.id}'),
                                  title: Text(row.name),
                                  subtitle: Text(
                                    widget.products
                                        ? '${row.oneCate}/${row.twoCate} · ${bmsFcCentsToYuan(row.price)}元'
                                        : '${row.department} · ${row.code}',
                                  ),
                                  trailing: TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => setState(
                                            () => _selected.remove(row.id),
                                          ),
                                    child: const Text('移除草稿'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: _busy || !_ready ? null : _save,
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<Map<String, Object?>> _fcData(
  BmsLoader loader,
  BmsFcPriceRequest request,
) async {
  final result = await loader.requestFcPrice(request);
  if (result.failureOrNull case final failure?) {
    throw StateError(failure.safeMessage);
  }
  return result.valueOrNull!;
}

String _fcError(Object error) => error is FormatException
    ? error.message
    : error is StateError
    ? error.message
    : '操作失败，请重试';
Future<bool> _fcConfirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    ) ??
    false;
