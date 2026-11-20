import 'dart:async';

import 'package:card_table/src/wine_loader.dart';
import 'package:card_table/src/wine_models.dart';
import 'package:flutter/material.dart';

/// S5.P8 用户管理与黑名单视图
final class WineUserConfigView extends StatefulWidget {
  const WineUserConfigView({required this.loader, super.key});
  final WineLoader loader;

  @override
  State<WineUserConfigView> createState() => _WineUserConfigViewState();
}

final class _WineUserConfigViewState extends State<WineUserConfigView> with SingleTickerProviderStateMixin {
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
              Tab(text: '客户列表'),
              Tab(text: '黑名单管理'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _WineUserListSubView(loader: widget.loader),
              _WineBlackListSubView(loader: widget.loader),
            ],
          ),
        ),
      ],
    );
  }
}

class _WineUserListSubView extends StatefulWidget {
  const _WineUserListSubView({required this.loader});
  final WineLoader loader;

  @override
  State<_WineUserListSubView> createState() => _WineUserListSubViewState();
}

class _WineUserListSubViewState extends State<_WineUserListSubView> {
  final _searchController = TextEditingController();
  List<WineCustomerItem> _items = [];
  final Set<String> _selectedIds = {};
  int _page = 1;
  final int _pageSize = 20;
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
    final res = await widget.loader.loadCustomList(
      page: _page,
      pageSize: _pageSize,
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

  Future<void> _toggleSmsBatch(bool enable) async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先选择需要设置短信开关的客户')));
      return;
    }
    final res = await widget.loader.openOrCloseMsg(
      custIds: _selectedIds.toList(),
      enable: enable,
    );
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('设置失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已批量${enable ? '开启' : '关闭'}短信通知')));
      await _load();
    }
  }

  Future<void> _editName(WineCustomerItem item) async {
    final nameCtrl = TextEditingController(text: item.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改客户姓名'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: '客户姓名', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await widget.loader.updateCustomName(
      custId: item.id,
      name: nameCtrl.text.trim(),
    );
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('修改失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('姓名修改成功')));
      await _load();
    }
  }

  Future<void> _editPhone(WineCustomerItem item) async {
    final phoneCtrl = TextEditingController(text: item.phone);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改客户手机号'),
        content: TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: '新手机号', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final newPhone = phoneCtrl.text.trim();
    if (newPhone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入11位手机号码')));
      return;
    }
    final valRes = await widget.loader.validatePhoneNum(newPhone);
    if (!mounted) return;
    if (valRes.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('验证失败: ${f.safeMessage}')));
      return;
    }
    final res = await widget.loader.updateCustomPhoneNum(
      custId: item.id,
      phone: newPhone,
    );
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('修改失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('手机号修改成功')));
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
                    hintText: '客户姓名/手机号',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) {
                    _page = 1;
                    unawaited(_load());
                  },
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  _page = 1;
                  unawaited(_load());
                },
                icon: const Icon(Icons.search, size: 18),
                label: const Text('查询'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _page = 1;
                  unawaited(_load());
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重置'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xff00897B)),
                onPressed: () => unawaited(_toggleSmsBatch(true)),
                icon: const Icon(Icons.sms, size: 18),
                label: const Text('批量开启短信'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.blueGrey),
                onPressed: () => unawaited(_toggleSmsBatch(false)),
                icon: const Icon(Icons.sms_failed, size: 18),
                label: const Text('批量关闭短信'),
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
                  ? const Center(child: Text('暂无客户数据', style: TextStyle(color: Colors.white38)))
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
                            DataColumn(label: Text('客户姓名')),
                            DataColumn(label: Text('手机号码')),
                            DataColumn(label: Text('短信通知')),
                            DataColumn(label: Text('操作')),
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
                                  DataCell(Text(_items[i].name)),
                                  DataCell(Text(_items[i].phone)),
                                  DataCell(
                                    Text(
                                      _items[i].isSmsOpen ? '已开启' : '已关闭',
                                      style: TextStyle(color: _items[i].isSmsOpen ? Colors.greenAccent : Colors.white38),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextButton(onPressed: () => unawaited(_editName(_items[i])), child: const Text('修改姓名')),
                                          TextButton(onPressed: () => unawaited(_editPhone(_items[i])), child: const Text('修改手机')),
                                        ],
                                    ),
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

class _WineBlackListSubView extends StatefulWidget {
  const _WineBlackListSubView({required this.loader});
  final WineLoader loader;

  @override
  State<_WineBlackListSubView> createState() => _WineBlackListSubViewState();
}

class _WineBlackListSubViewState extends State<_WineBlackListSubView> {
  final _searchController = TextEditingController();
  List<WineBlacklistItem> _items = [];
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
    final res = await widget.loader.loadBlackList(
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

  Future<void> _addBlackUser() async {
    final phoneCtrl = TextEditingController();
    final remarkCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增黑名单'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: '手机号码 (多个逗号分隔)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarkCtrl,
              decoration: const InputDecoration(labelText: '拉黑备注', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('添加')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final phones = phoneCtrl.text.split(RegExp(r'[,，\s]+')).where((p) => p.trim().isNotEmpty).toList();
    if (phones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入至少一个手机号')));
      return;
    }
    final res = await widget.loader.addBlackList(
      phones: phones,
      remark: remarkCtrl.text.trim(),
    );
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('添加失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已成功加入黑名单')));
      await _load();
    }
  }

  Future<void> _removeBlackList(List<String> ids) async {
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择需要移出的黑名单项')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移出黑名单'),
        content: Text('确认将选中的 ${ids.length} 项移出黑名单吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认移出')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await widget.loader.deleteBlackList(ids);
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('移出失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('移出黑名单成功')));
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
                    hintText: '手机号/备注',
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
                style: FilledButton.styleFrom(backgroundColor: const Color(0xffD32F2F)),
                onPressed: _addBlackUser,
                icon: const Icon(Icons.person_add_disabled, size: 18),
                label: const Text('新增黑名单'),
              ),
              OutlinedButton.icon(
                onPressed: () => unawaited(_removeBlackList(_selectedIds.toList())),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('批量移出'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
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
                  ? const Center(child: Text('暂无黑名单数据', style: TextStyle(color: Colors.white38)))
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
                            DataColumn(label: Text('手机号码')),
                            DataColumn(label: Text('拉黑备注')),
                            DataColumn(label: Text('加入时间')),
                            DataColumn(label: Text('操作')),
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
                                  DataCell(Text(_items[i].phone)),
                                  DataCell(Text(_items[i].remark.isEmpty ? '-' : _items[i].remark)),
                                  DataCell(Text(_items[i].createTime)),
                                  DataCell(
                                      TextButton(
                                        onPressed: () => unawaited(_removeBlackList([_items[i].id])),
                                        child: const Text('移出', style: TextStyle(color: Colors.redAccent)),
                                      ),
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
