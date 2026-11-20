import 'dart:async';

import 'package:card_table/src/wine_loader.dart';
import 'package:card_table/src/wine_models.dart';
import 'package:flutter/material.dart';

/// S5.P9 客户中心存取酒视图
final class WineCustomerCenterView extends StatefulWidget {
  const WineCustomerCenterView({required this.loader, super.key});
  final WineLoader loader;

  @override
  State<WineCustomerCenterView> createState() => _WineCustomerCenterViewState();
}

final class _WineCustomerCenterViewState extends State<WineCustomerCenterView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xff182037),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.lightBlueAccent,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.lightBlueAccent,
            tabs: const [
              Tab(text: '客户中心 - 待入库'),
              Tab(text: '客户中心 - 取酒开单'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              WineCustomerSaveView(loader: widget.loader),
              WineCustomerGetView(loader: widget.loader),
            ],
          ),
        ),
      ],
    );
  }
}

/// S5.P9.T01 客户中心待入库
final class WineCustomerSaveView extends StatefulWidget {
  const WineCustomerSaveView({required this.loader, super.key});
  final WineLoader loader;

  @override
  State<WineCustomerSaveView> createState() => _WineCustomerSaveViewState();
}

final class _WineCustomerSaveViewState extends State<WineCustomerSaveView> {
  final _searchController = TextEditingController();
  List<WineSaveRecord> _records = [];
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
    final res = await widget.loader.loadCustomCenterSaveWineList(
      keyword: _searchController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.failureOrNull case final f?) {
        _error = f.safeMessage;
      } else {
        _records = res.valueOrNull ?? [];
        _selectedIds.clear();
      }
    });
  }

  Future<void> _batchConfirm() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先勾选需要入库的存酒')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量入库'),
        content: Text('确认将选中的 ${_selectedIds.length} 笔客户存酒入库吗？'),
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
    final res = await widget.loader.confirmSaveNeedToLib(_selectedIds.toList());
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('入库失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('入库操作成功')));
      await _load();
    }
  }

  Future<void> _batchReject() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先勾选需要驳回的存酒')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量驳回'),
        content: Text('确认将选中的 ${_selectedIds.length} 笔客户存酒驳回吗？'),
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
    final res = await widget.loader.backSaveNeedToLib(_selectedIds.toList());
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('驳回失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('驳回操作成功')));
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
                    hintText: '客人姓名/手机/商品/订位人',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => unawaited(_load()),
                ),
              ),
              FilledButton.icon(
                onPressed: () => unawaited(_load()),
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
                onPressed: _batchConfirm,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('批量入库'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _batchReject,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('批量驳回'),
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
              : _records.isEmpty
                  ? const Center(child: Text('暂无待入库数据', style: TextStyle(color: Colors.white38)))
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
                            DataColumn(label: Text('客人姓名')),
                            DataColumn(label: Text('联系方式')),
                            DataColumn(label: Text('卡台')),
                            DataColumn(label: Text('订位人')),
                            DataColumn(label: Text('服务员')),
                            DataColumn(label: Text('存酒时间')),
                            DataColumn(label: Text('酒水明细')),
                          ],
                          rows: [
                            for (var i = 0; i < _records.length; i++)
                              DataRow(
                                selected: _selectedIds.contains(_records[i].id),
                                onSelectChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedIds.add(_records[i].id);
                                    } else {
                                      _selectedIds.remove(_records[i].id);
                                    }
                                  });
                                },
                                cells: [
                                  DataCell(Text('${i + 1}')),
                                  DataCell(Text(_records[i].customerName)),
                                  DataCell(Text(_records[i].customerPhone)),
                                  DataCell(Text(_records[i].seatName)),
                                  DataCell(Text(_records[i].salesName)),
                                  DataCell(Text(_records[i].waiterName)),
                                  DataCell(Text(_records[i].saveTime)),
                                  DataCell(
                                    Text(_records[i].items.map((it) => '${it.name} x${it.count}').join(', ')),
                                  ),
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

/// S5.P9.T02 客户中心待出库开单
final class WineCustomerGetView extends StatefulWidget {
  const WineCustomerGetView({required this.loader, super.key});
  final WineLoader loader;

  @override
  State<WineCustomerGetView> createState() => _WineCustomerGetViewState();
}

final class _WineCustomerGetViewState extends State<WineCustomerGetView> {
  final _phoneController = TextEditingController();
  List<WineInventoryItem> _items = [];
  final Set<String> _selectedIds = {};
  List<Map<String, Object?>> _seats = [];
  String? _selectedSeatId;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSeats());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSeats() async {
    final res = await widget.loader.loadCustomCenterSeatList();
    if (!mounted) return;
    setState(() {
      _seats = res.valueOrNull ?? [];
      if (_seats.isNotEmpty) {
        _selectedSeatId = '${_seats.first['id'] ?? ''}';
      }
    });
  }

  Future<void> _searchWine() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入客户手机号进行查询')));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await widget.loader.loadCustomCenterGetWineList(
      phone: phone,
      seatId: _selectedSeatId ?? '',
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

  Future<void> _submitGetWine() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先勾选需要出库的存酒')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('客户中心取酒开单'),
        content: Text('确认将选中的 ${_selectedIds.length} 项存酒开单出库至卡台吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xff009370)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认出库'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await widget.loader.submitCustomCenterGetWine({
      'invt_ids': _selectedIds.toList(),
      'seat_id': _selectedSeatId,
    });
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('开单失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('取酒开单成功')));
      await _searchWine();
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
                width: 200,
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: '客人手机号',
                    labelStyle: TextStyle(color: Colors.white70),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => unawaited(_searchWine()),
                ),
              ),
              if (_seats.isNotEmpty)
                DropdownButton<String>(
                  value: _selectedSeatId,
                  dropdownColor: const Color(0xff182037),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: [
                    for (final s in _seats)
                      DropdownMenuItem(
                        value: '${s['id'] ?? ''}',
                        child: Text('${s['name'] ?? s['seat_name'] ?? '卡台'}'),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedSeatId = v);
                  },
                ),
              FilledButton.icon(
                onPressed: () => unawaited(_searchWine()),
                icon: const Icon(Icons.search, size: 18),
                label: const Text('查询客户存酒'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xff009370)),
                onPressed: _submitGetWine,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('确认出库'),
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
                  ? const Center(child: Text('请输入手机号查询或暂无存酒记录', style: TextStyle(color: Colors.white38)))
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
                            DataColumn(label: Text('酒水名称')),
                            DataColumn(label: Text('规格')),
                            DataColumn(label: Text('每瓶克数')),
                            DataColumn(label: Text('库存数量')),
                            DataColumn(label: Text('存酒时间')),
                            DataColumn(label: Text('过期时间')),
                            DataColumn(label: Text('订位人')),
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
                                  DataCell(Text(_items[i].gram.isEmpty ? '-' : _items[i].gram)),
                                  DataCell(Text('${_items[i].count}')),
                                  DataCell(Text(_items[i].saveTime)),
                                  DataCell(Text(_items[i].expireTime)),
                                  DataCell(Text(_items[i].salesName)),
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
