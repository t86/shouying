import 'dart:async';

import 'package:card_table/src/wine_loader.dart';
import 'package:card_table/src/wine_models.dart';
import 'package:flutter/material.dart';

/// S5.P7.T01 待充公视图
final class WineToStoreView extends StatefulWidget {
  const WineToStoreView({required this.loader, super.key});
  final WineLoader loader;

  @override
  State<WineToStoreView> createState() => _WineToStoreViewState();
}

final class _WineToStoreViewState extends State<WineToStoreView> {
  final _searchController = TextEditingController();
  List<WineConfiscateItem> _items = [];
  final Set<String> _selectedIds = {};
  final Set<String> _expandedIds = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await widget.loader.loadNeedToStoreList(
      keyword: _searchController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.failureOrNull case final f?) {
        _error = f.safeMessage;
      } else {
        _items = res.valueOrNull ?? [];
        _selectedIds.clear();
      }
    });
  }

  Future<void> _confirmSelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先勾选需要入库的商品')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认入充公库'),
        content: Text('确认将选中的 ${_selectedIds.length} 项记录转入充公库吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xff009370)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认入库'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await widget.loader.confirmToStoreList(_selectedIds.toList());
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('入库失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('确认入库成功')));
      await _load();
    }
  }

  Future<void> _rejectSelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先勾选需要驳回的记录')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('驳回充公'),
        content: Text('确认驳回选中的 ${_selectedIds.length} 项充公记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认驳回'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await widget.loader.backToStoreList(_selectedIds.toList());
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('驳回失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('驳回操作成功')));
      await _load();
    }
  }

  Future<void> _editItem(WineConfiscateItem item) async {
    final reasonController = TextEditingController(text: item.reason);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑待充公信息'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: '充公原因/说明', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await widget.loader.chgCsmCgBefIn({
      'id': item.id,
      'reason': reasonController.text.trim(),
    });
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('修改失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('修改成功')));
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xff182037),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: '充公人/商品/卡台/订台人',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => unawaited(_load()),
                ),
              ),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('查询'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  unawaited(_load());
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重置'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xff009370)),
                onPressed: _confirmSelected,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('确认入库'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _rejectSelected,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('驳回'),
              ),
            ],
          ),
        ),
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.red.withAlpha(50),
            child: Text('加载错误: $_error', style: const TextStyle(color: Colors.redAccent)),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? const Center(child: Text('暂无待充公数据', style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (ctx, idx) {
                        final item = _items[idx];
                        final isSelected = _selectedIds.contains(item.id);
                        final isExpanded = _expandedIds.contains(item.id);
                        return Card(
                          color: const Color(0xff0D172D),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Color(0xff2A3959)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ListTile(
                                leading: IconButton(
                                  icon: Icon(isExpanded ? Icons.remove_circle_outline : Icons.add_circle_outline, color: Colors.blueAccent),
                                  onPressed: () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedIds.remove(item.id);
                                      } else {
                                        _expandedIds.add(item.id);
                                      }
                                    });
                                  },
                                ),
                                title: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedIds.add(item.id);
                                          } else {
                                            _selectedIds.remove(item.id);
                                          }
                                        });
                                      },
                                    ),
                                    Text('${idx + 1}. 充公人: ${item.salesName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 16),
                                    Text('卡台: ${item.seatName}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(width: 16),
                                    Text('订台人: ${item.customerName}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(width: 16),
                                    Text('时间: ${item.expireTime}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                  ],
                                ),
                                trailing: TextButton.icon(
                                  onPressed: () => unawaited(_editItem(item)),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('编辑'),
                                ),
                              ),
                              if (isExpanded)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  color: const Color(0xff141F36),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text('商品: ${item.wineName}', style: const TextStyle(color: Colors.white))),
                                      Expanded(child: Text('规格: ${item.unit}', style: const TextStyle(color: Colors.white70))),
                                      Expanded(child: Text('数量: ${item.count}', style: const TextStyle(color: Colors.amberAccent))),
                                      if (item.reason.isNotEmpty)
                                        Expanded(child: Text('原因: ${item.reason}', style: const TextStyle(color: Colors.white60))),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

/// S5.P7.T02 充公库视图
final class WineStoreLibView extends StatefulWidget {
  const WineStoreLibView({required this.loader, super.key});
  final WineLoader loader;

  @override
  State<WineStoreLibView> createState() => _WineStoreLibViewState();
}

final class _WineStoreLibViewState extends State<WineStoreLibView> {
  final _searchController = TextEditingController();
  List<WineConfiscateItem> _items = [];
  final Set<String> _selectedIds = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await widget.loader.loadStoreLibList(
      keyword: _searchController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.failureOrNull case final f?) {
        _error = f.safeMessage;
      } else {
        _items = res.valueOrNull ?? [];
        _selectedIds.clear();
      }
    });
  }

  Future<void> _outLibSelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先勾选需要充公出库的商品')));
      return;
    }
    final remarkController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('充公出库开单'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('选中的商品项数: ${_selectedIds.length}'),
            const SizedBox(height: 12),
            TextField(
              controller: remarkController,
              decoration: const InputDecoration(labelText: '出库备注/去向', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xff00897B)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认出库'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await widget.loader.newCgOut({
      'ids': _selectedIds.toList(),
      'remark': remarkController.text.trim(),
    });
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('出库失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('充公出库开单成功')));
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xff182037),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: '商品名称',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => unawaited(_load()),
                ),
              ),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('查询'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  unawaited(_load());
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重置'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xff00897B)),
                onPressed: _outLibSelected,
                icon: const Icon(Icons.output, size: 18),
                label: const Text('充公出库'),
              ),
            ],
          ),
        ),
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.red.withAlpha(50),
            child: Text('加载错误: $_error', style: const TextStyle(color: Colors.redAccent)),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? const Center(child: Text('暂无充公库数据', style: TextStyle(color: Colors.white38)))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xff182037)),
                          dataRowColor: WidgetStateProperty.all(const Color(0xff0D172D)),
                          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
                          columns: const [
                            DataColumn(label: Text('序号')),
                            DataColumn(label: Text('商品名称')),
                            DataColumn(label: Text('规格')),
                            DataColumn(label: Text('库存数量')),
                          ],
                          rows: [
                            for (var i = 0; i < _items.length; i++)
                              DataRow(
                                selected: _selectedIds.contains(_items[i].id),
                                onSelectChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedIds.add(_items[i].id);
                                    } else {
                                      _selectedIds.remove(_items[i].id);
                                    }
                                  });
                                },
                                cells: [
                                  DataCell(Text('${i + 1}')),
                                  DataCell(Text(_items[i].wineName)),
                                  DataCell(Text(_items[i].unit)),
                                  DataCell(Text('${_items[i].count}')),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

/// S5.P7.T03 充公出库单视图
final class WineToStoreDetailView extends StatefulWidget {
  const WineToStoreDetailView({required this.loader, super.key});
  final WineLoader loader;

  @override
  State<WineToStoreDetailView> createState() => _WineToStoreDetailViewState();
}

final class _WineToStoreDetailViewState extends State<WineToStoreDetailView> {
  final _startDayController = TextEditingController();
  final _endDayController = TextEditingController();
  List<WineConfiscateItem> _items = [];
  String? _selectedId;
  final int _page = 1;
  final int _pageSize = 15;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setDateRange(7);
    unawaited(_load());
  }

  void _setDateRange(int days) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    _startDayController.text = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    _endDayController.text = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _startDayController.dispose();
    _endDayController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await widget.loader.loadToStoreDetailList(
      startDate: _startDayController.text.trim(),
      endDate: _endDayController.text.trim(),
      page: _page,
      pageSize: _pageSize,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.failureOrNull case final f?) {
        _error = f.safeMessage;
      } else {
        _items = res.valueOrNull ?? [];
        _selectedId = null;
      }
    });
  }

  Future<void> _hongChong() async {
    if (_selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择需要红冲的出库单')));
      return;
    }
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('充公出库单红冲'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('单号: $_selectedId'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: '红冲理由', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认红冲'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await widget.loader.toStoreToHc(_selectedId!);
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('红冲失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('红冲成功')));
      await _load();
    }
  }

  Future<void> _showDetail(String id) async {
    final res = await widget.loader.loadToStoreOrderDetail(id);
    if (!mounted) return;
    final map = res.valueOrNull ?? {};
    final list = (map['records'] ?? map['items'] ?? map['goods'] ?? []) as List? ?? [];
    if (!mounted) return;
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('出库单明细: $id'),
          content: SizedBox(
            width: 500,
            child: list.isEmpty
                ? const Text('无详细明细记录')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (c, idx) {
                      final row = list[idx] as Map? ?? {};
                      return ListTile(
                        title: Text('${row['name'] ?? row['prd_name'] ?? row['n'] ?? '-'}'),
                        subtitle: Text('规格: ${row['unit'] ?? row['unit_name'] ?? row['u'] ?? '-'} | 数量: ${row['count'] ?? row['c'] ?? 1}'),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xff182037),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  _setDateRange(7);
                  unawaited(_load());
                },
                child: const Text('近7天'),
              ),
              OutlinedButton(
                onPressed: () {
                  _setDateRange(30);
                  unawaited(_load());
                },
                child: const Text('近30天'),
              ),
              OutlinedButton(
                onPressed: () {
                  _setDateRange(90);
                  unawaited(_load());
                },
                child: const Text('近90天'),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _startDayController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(isDense: true, labelText: '开始日期', border: OutlineInputBorder()),
                ),
              ),
              const Text('至', style: TextStyle(color: Colors.white)),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _endDayController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(isDense: true, labelText: '结束日期', border: OutlineInputBorder()),
                ),
              ),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('查询'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _hongChong,
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('红冲'),
              ),
            ],
          ),
        ),
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.red.withAlpha(50),
            child: Text('加载错误: $_error', style: const TextStyle(color: Colors.redAccent)),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? const Center(child: Text('暂无出库单数据', style: TextStyle(color: Colors.white38)))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xff182037)),
                          dataRowColor: WidgetStateProperty.all(const Color(0xff0D172D)),
                          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
                          columns: const [
                            DataColumn(label: Text('序号')),
                            DataColumn(label: Text('单号')),
                            DataColumn(label: Text('充公出库操作人')),
                            DataColumn(label: Text('充公出库时间')),
                          ],
                          rows: [
                            for (var i = 0; i < _items.length; i++)
                              DataRow(
                                selected: _selectedId == _items[i].id,
                                onSelectChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedId = _items[i].id;
                                    } else if (_selectedId == _items[i].id) {
                                      _selectedId = null;
                                    }
                                  });
                                },
                                cells: [
                                  DataCell(Text('${i + 1}')),
                                  DataCell(
                                    InkWell(
                                      onTap: () => unawaited(_showDetail(_items[i].id)),
                                      child: Text(_items[i].id, style: const TextStyle(color: Colors.lightBlueAccent, decoration: TextDecoration.underline)),
                                    ),
                                  ),
                                  DataCell(Text(_items[i].salesName)),
                                  DataCell(Text(_items[i].expireTime)),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}
