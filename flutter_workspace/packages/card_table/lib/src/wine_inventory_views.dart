import 'dart:async';

import 'package:card_table/src/wine_loader.dart';
import 'package:card_table/src/wine_models.dart';
import 'package:card_table/src/wine_save_edit.dart';
import 'package:card_table/src/wine_save_edit_dialog.dart';
import 'package:card_table/src/wine_pending_get.dart';
import 'package:card_table/src/wine_pending_get_dialog.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';

/// S5.P1 存酒待入库视图
final class WineSaveNeedView extends StatefulWidget {
  const WineSaveNeedView({required this.loader, super.key});
  final WineLoader loader;

  @override
  State<WineSaveNeedView> createState() => _WineSaveNeedViewState();
}

final class _WineSaveNeedViewState extends State<WineSaveNeedView> {
  bool _openingSaveEdit = false;
  final _searchController = TextEditingController();
  List<WineSaveRecord> _records = [];
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
    final res = await widget.loader.loadSaveNeedToLib(keyword: _searchController.text.trim());
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
      _showMsg('请先勾选需要入库的单据');
      return;
    }
    final confirmed = await _confirmDialog('确认入库', '确认将选中的 ${_selectedIds.length} 笔存酒单入库吗？');
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    final res = await widget.loader.confirmSaveNeedToLib(_selectedIds.toList());
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.failureOrNull case final f?) {
      _showMsg(f.safeMessage);
    } else {
      _showMsg('确认入库成功');
      await _load();
    }
  }

  Future<void> _batchReject() async {
    if (_selectedIds.isEmpty) {
      _showMsg('请先勾选需要驳回的单据');
      return;
    }
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量驳回'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定驳回选中的 ${_selectedIds.length} 笔存酒单吗？'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '驳回原因',
                hintText: '请输入驳回原因（选填）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定驳回'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    final res = await widget.loader.backSaveNeedToLib(
      _selectedIds.toList(),
      reason: reasonController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.failureOrNull case final f?) {
      _showMsg(f.safeMessage);
    } else {
      _showMsg('驳回成功');
      await _load();
    }
  }

  Future<void> _openEditDrawer(WineSaveRecord record) async {
    if (_openingSaveEdit) return;
    _openingSaveEdit = true;
    try {
    final loader=widget.loader;
    if(loader is! WineSaveEditLoader) { _showMsg('存酒改单资料尚未接入');return; }
    final edit=loader as WineSaveEditLoader;
    final session=edit.saveEditSession;
    if(session==null||!edit.saveEditSnapshot.known) { _showMsg('营业日及订位人资料尚未同步');return; }
    final result=await edit.loadSaveEditContext();
    if(!mounted||!identical(loader,widget.loader)||session!=edit.saveEditSession) return;
    if(result.failureOrNull case final f?) { _showMsg(f.safeMessage);return; }
    final data=result.valueOrNull!;
    final current=data.records.where((r)=>'${r.id}'==record.id).firstOrNull;
    if(current==null||data.needsAuthorization==null) { _showMsg('单据或授权配置无效，请重新查询');return; }
    final saved=await showDialog<bool>(context:context,barrierDismissible:false,
      builder:(_)=>WineSaveEditDialog(loader:loader,record:current,needsAuthorization:data.needsAuthorization!));
    if(!mounted||saved!=true||session!=edit.saveEditSession) return;
    _showMsg('改单保存成功');
    await _load();
    } finally {
      _openingSaveEdit = false;
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }


  Future<bool?> _confirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _records.isNotEmpty && _selectedIds.length == _records.length;

    return Column(
      children: [
        // 顶部工具栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xff141D35),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '输入客人姓名/手机号/商品/卡台/订位人',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white54),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xff1D2C50),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => unawaited(_load()),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xff2362D5)),
                  onPressed: _loading ? null : _load,
                  child: const Text('查询'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    unawaited(_load());
                  },
                  child: const Text('重置'),
                ),
                const SizedBox(width: 24),
                FilledButton.icon(
                  key: const Key('wine-save-need-confirm'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xff009370)),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('确认入库'),
                  onPressed: _loading ? null : _batchConfirm,
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: const Key('wine-save-need-reject'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xffC62828)),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('驳回'),
                  onPressed: _loading ? null : _batchReject,
                ),
              ],
            ),
          ),
        ),

        // 表格区域
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                  : _records.isEmpty
                      ? const Center(child: Text('暂无待入库数据', style: TextStyle(color: Colors.white38)))
                      : SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xff182037)),
                              dataRowColor: WidgetStateProperty.all(const Color(0xff0D172D)),
                              headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              dataTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
                              columns: [
                                DataColumn(
                                  label: Row(
                                    children: [
                                      Checkbox(
                                        value: allSelected,
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedIds.addAll(_records.map((r) => r.id));
                                            } else {
                                              _selectedIds.clear();
                                            }
                                          });
                                        },
                                      ),
                                      const Text('全选'),
                                    ],
                                  ),
                                ),
                                const DataColumn(label: Text('客人姓名')),
                                const DataColumn(label: Text('联系方式')),
                                const DataColumn(label: Text('卡台')),
                                const DataColumn(label: Text('订台人')),
                                const DataColumn(label: Text('服务员')),
                                const DataColumn(label: Text('存酒时间')),
                                const DataColumn(label: Text('备注')),
                                const DataColumn(label: Text('操作')),
                              ],
                              rows: [
                                for (final record in _records) ...[
                                  DataRow(
                                    selected: _selectedIds.contains(record.id),
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: _selectedIds.contains(record.id),
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedIds.add(record.id);
                                                  } else {
                                                    _selectedIds.remove(record.id);
                                                  }
                                                });
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                _expandedIds.contains(record.id) ? Icons.expand_less : Icons.expand_more,
                                                color: Colors.white70,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  if (_expandedIds.contains(record.id)) {
                                                    _expandedIds.remove(record.id);
                                                  } else {
                                                    _expandedIds.add(record.id);
                                                  }
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(record.customerName)),
                                      DataCell(Text(record.customerPhone)),
                                      DataCell(Text(record.seatName)),
                                      DataCell(Text(record.salesName)),
                                      DataCell(Text(record.waiterName)),
                                      DataCell(Text(record.saveTime)),
                                      DataCell(Text(record.remark.isEmpty ? '-' : record.remark)),
                                      DataCell(
                                        TextButton(
                                          onPressed: () => unawaited(_openEditDrawer(record)),
                                          child: const Text('改单/编辑'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_expandedIds.contains(record.id))
                                    DataRow(
                                      cells: [
                                        const DataCell(SizedBox()),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('【酒水明细】', style: TextStyle(color: Color(0xff4B89FF), fontWeight: FontWeight.bold)),
                                                for (final item in record.items)
                                                  Text(
                                                    '• ${item.name} | 规格: ${item.unit} | 数量: ${item.count} | 每瓶克数: ${item.gram.isEmpty ? '-' : item.gram} | 过期时间: ${item.expireTime}',
                                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        for (var i = 0; i < 7; i++) const DataCell(SizedBox()),
                                      ],
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
        ),
      ],
    );
  }
}

/// S5.P2 取酒待出库视图
final class WineGetNeedView extends StatefulWidget {
  const WineGetNeedView({required this.loader, super.key});
  final WineLoader loader;

  @override
  State<WineGetNeedView> createState() => _WineGetNeedViewState();
}

final class _WineGetNeedViewState extends State<WineGetNeedView> {
  final _searchController = TextEditingController();
  List<WineGetRecord> _records = [];
  final Set<String> _selectedIds = {};
  final Set<String> _expandedIds = {};
  bool _loading = false;
  String? _error;
  bool? _needsAuthorization;
  Object? _recordsContext;
  bool _batchInFlight = false;
  int _loadVersion = 0;

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
    final loader = widget.loader;
    if (loader is WinePendingGetLoader) {
      final version = ++_loadVersion;
      final before = loader is WineBorrowFormContext ? (loader as WineBorrowFormContext).borrowFormContext : null;
      final res = await (loader as WinePendingGetLoader).loadPendingGetContext(keyword: _searchController.text.trim());
      if (!mounted || !identical(loader, widget.loader) || version != _loadVersion) return;
      if (loader is WineBorrowFormContext && (before == null || before != (loader as WineBorrowFormContext).borrowFormContext)) {
        setState(() { _loading = false; _recordsContext = null; _error = '登录或连接状态已改变，请重新查询'; });
        return;
      }
      setState(() {
        _loading = false;
        _recordsContext = res.failureOrNull == null ? before : null;
        _needsAuthorization = res.valueOrNull?.needsAuthorization;
        if (res.failureOrNull case final f?) {
          _error = f.safeMessage;
        } else {
          _records = res.valueOrNull!.records;
          _selectedIds.clear();
        }
      });
      return;
    }
    final res = await loader.loadNeedToLib(keyword: _searchController.text.trim());
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

  Future<void> _batchConfirm() => _runPendingBatch(reject: false);

  Future<void> _batchReject() => _runPendingBatch(reject: true);

  Future<void> _runPendingBatch({required bool reject}) async {
    if (_loading || _batchInFlight) return;
    final loader = widget.loader;
    final before = _recordsContext;
    final version = _loadVersion;
    final ownerRoute = ModalRoute.of(context);
    final ids = List<String>.unmodifiable(_selectedIds);
    bool current() => mounted && identical(loader, widget.loader) &&
        before != null && before == _recordsContext && version == _loadVersion &&
        loader is WineBorrowFormContext &&
        before == (loader as WineBorrowFormContext).borrowFormContext &&
        ownerRoute?.isCurrent == true;
    if (ids.isEmpty) {
      _showMsg(reject ? '请先勾选需要驳回的单据' : '请先勾选需要出库的单据');
      return;
    }
    if (!current() || ids.any((id) {
      final number = int.tryParse(id);
      return number == null || number <= 0 || number > 9007199254740991 ||
          _records.where((row) => row.id == id).length != 1;
    })) {
      _showMsg('单据或登录状态已变化，请重新查询');
      return;
    }
    _batchInFlight = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(reject ? '批量驳回取酒' : '确认出库'),
          content: Text('确定${reject ? '驳回' : '出库'}选中的 ${ids.length} 笔取酒单吗？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text(reject ? '确定驳回' : '确定')),
          ],
        ),
      );
      if (confirmed != true || !current()) return;
      setState(() => _loading = true);
      final result = reject
          ? await loader.backGetNeedToLib(ids)
          : await loader.confirmGetNeedToLib(ids);
      if (!current()) return;
      if (result.failureOrNull case final failure?) {
        _showMsg(failure.safeMessage);
      } else {
        _showMsg(reject ? '驳回成功' : '确认出库成功');
        await _load();
      }
    } on Object {
      if (current()) _showMsg('无法确认操作结果，请重新查询');
    } finally {
      _batchInFlight = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _authConfirm(WineGetRecord record) async {
    final loader = widget.loader;
    final needsAuthorization = _needsAuthorization;
    final before = _recordsContext;
    var expired = false;
    bool current() {
      if (!mounted || !identical(loader, widget.loader) || before == null ||
          loader is! WineBorrowFormContext || before != (loader as WineBorrowFormContext).borrowFormContext) {
        expired = true;
      }
      return !expired;
    }
    if (loader is! WinePendingGetLoader || needsAuthorization == null || !current()) {
      _showMsg('取酒授权配置未就绪，请重新查询');
      return;
    }
    setState(() => _loading = true);
    final inventory = await (loader as WinePendingGetLoader).loadPendingGetInventory(record.customerPhone);
    if (!current()) {
      if (mounted) setState(() { _loading = false; _error = '登录或连接状态已改变，请重新查询'; });
      return;
    }
    setState(() => _loading = false);
    if (inventory.failureOrNull case final failure?) {
      _showMsg(failure.safeMessage);
      return;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => WinePendingGetDialog(
        record: record, inventory: inventory.valueOrNull!,
        needsAuthorization: needsAuthorization,
        isCurrent: current,
        submit: (body) async {
          if (!current()) {
            return const FailureResult(AppFailure(kind: FailureKind.authentication,
              code: 'wine.session_changed', safeMessage: '登录或连接状态已改变，请重新打开'));
          }
          return loader.confirmAuthGetNeedToLib(body);
        },
      ),
    );
    if (ok != true || !current()) return;
    _showMsg('出库成功');
    await _load();
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _records.isNotEmpty && _selectedIds.length == _records.length;

    return Column(
      children: [
        // 顶部工具栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xff141D35),
          child: LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: constraints.maxWidth < 740 ? 740 : constraints.maxWidth,
              child: Row(
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '输入客人姓名/手机号/商品/卡台/订位人',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white54),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xff1D2C50),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => unawaited(_load()),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xff2362D5)),
                onPressed: _loading ? null : _load,
                child: const Text('查询'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  unawaited(_load());
                },
                child: const Text('重置'),
              ),
              const Spacer(),
              FilledButton.icon(
                key: const Key('wine-get-need-confirm'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xff009370)),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('确认出库'),
                onPressed: _loading ? null : _batchConfirm,
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                key: const Key('wine-get-need-reject'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xffC62828)),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('驳回'),
                onPressed: _loading ? null : _batchReject,
              ),
            ],
          ),
            ),
          )),
        ),

        // 表格
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                  : _records.isEmpty
                      ? const Center(child: Text('暂无待出库数据', style: TextStyle(color: Colors.white38)))
                      : SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xff182037)),
                              dataRowColor: WidgetStateProperty.all(const Color(0xff0D172D)),
                              headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              dataTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
                              columns: [
                                DataColumn(
                                  label: Row(
                                    children: [
                                      Checkbox(
                                        value: allSelected,
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedIds.addAll(_records.map((r) => r.id));
                                            } else {
                                              _selectedIds.clear();
                                            }
                                          });
                                        },
                                      ),
                                      const Text('全选'),
                                    ],
                                  ),
                                ),
                                const DataColumn(label: Text('超级码')),
                                const DataColumn(label: Text('客人姓名')),
                                const DataColumn(label: Text('联系方式')),
                                const DataColumn(label: Text('卡台')),
                                const DataColumn(label: Text('订台人')),
                                const DataColumn(label: Text('服务员')),
                                const DataColumn(label: Text('取酒时间')),
                                const DataColumn(label: Text('操作')),
                              ],
                              rows: [
                                for (final record in _records) ...[
                                  DataRow(
                                    selected: _selectedIds.contains(record.id),
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: _selectedIds.contains(record.id),
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedIds.add(record.id);
                                                  } else {
                                                    _selectedIds.remove(record.id);
                                                  }
                                                });
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                _expandedIds.contains(record.id) ? Icons.expand_less : Icons.expand_more,
                                                color: Colors.white70,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  if (_expandedIds.contains(record.id)) {
                                                    _expandedIds.remove(record.id);
                                                  } else {
                                                    _expandedIds.add(record.id);
                                                  }
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          record.superCode.isEmpty ? '-' : record.superCode,
                                          style: TextStyle(color: record.superCode.isNotEmpty ? const Color(0xffFFA726) : null),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          record.customerName,
                                          style: TextStyle(color: record.isBlack ? Colors.redAccent : null),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          record.customerPhone,
                                          style: TextStyle(color: record.isBlack ? Colors.redAccent : null),
                                        ),
                                      ),
                                      DataCell(Text(record.seatName)),
                                      DataCell(Text(record.salesName)),
                                      DataCell(Text(record.waiterName)),
                                      DataCell(Text(record.getTime)),
                                      DataCell(
                                        TextButton(
                                          onPressed: () => unawaited(_authConfirm(record)),
                                          child: const Text('编辑取酒'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_expandedIds.contains(record.id))
                                    DataRow(
                                      cells: [
                                        const DataCell(SizedBox()),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('【出库明细】', style: TextStyle(color: Color(0xff4B89FF), fontWeight: FontWeight.bold)),
                                                for (final item in record.items)
                                                  Text(
                                                    '• ${item.name} | 规格: ${item.unit} | 数量: ${item.count} | 存酒卡台: ${item.saveSeat} | 过期时间: ${item.expireTime}',
                                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        for (var i = 0; i < 7; i++) const DataCell(SizedBox()),
                                      ],
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
        ),
      ],
    );
  }
}

/// S5.P3 存酒库视图
final class WineSaveLibView extends StatefulWidget {
  const WineSaveLibView({required this.loader, super.key});
  final WineLoader loader;

  @override
  State<WineSaveLibView> createState() => _WineSaveLibViewState();
}

final class _WineSaveLibViewState extends State<WineSaveLibView> {
  final _searchController = TextEditingController();
  final _daysController = TextEditingController();
  List<WineInventoryItem> _items = [];
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
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final days = int.tryParse(_daysController.text.trim()) ?? 0;
    final res = await widget.loader.loadSaveLibList(
      daysLeft: days,
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

  Future<void> _delaySelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先勾选需要延期的存酒')));
      return;
    }
    final daysController = TextEditingController(text: '30');
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('存酒延期'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '延期天数', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: '延期理由', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定延期')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final days = int.tryParse(daysController.text.trim()) ?? 30;
    for (final id in _selectedIds) {
      await widget.loader.delayWineInvt(id: id, days: days, reason: reasonController.text.trim());
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('延期操作成功')));
    await _load();
  }

  Future<void> _cgSelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先勾选需要充公的存酒')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('库存充公'),
        content: Text('确认将选中的 ${_selectedIds.length} 笔存酒转入待充公列表吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认充公'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await widget.loader.cgWineInvt(_selectedIds.toList());
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.safeMessage)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('充公成功，已进入待充公列表')));
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xff141D35),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '客人姓名/手机号/商品/卡台',
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xff1D2C50),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => unawaited(_load()),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '剩余天数',
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xff1D2C50),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => unawaited(_load()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xff2362D5)),
                onPressed: _loading ? null : _load,
                child: const Text('查询'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xff2362D5)),
                onPressed: _loading ? null : _delaySelected,
                child: const Text('延期'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xffC62828)),
                onPressed: _loading ? null : _cgSelected,
                child: const Text('批量充公'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.download, size: 16),
                label: const Text('导出明细'),
                onPressed: () async {
                  final result = await widget.loader.exportWineDetailList(keyword: _searchController.text.trim(), daysLeft: int.tryParse(_daysController.text.trim()) ?? 0);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.failureOrNull != null ? '导出失败: ${result.failureOrNull!.safeMessage}' : wineExportSuccessMessage(widget.loader))));
                },
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
                  ? const Center(child: Text('暂无存酒库数据', style: TextStyle(color: Colors.white38)))
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
                            DataColumn(label: Text('订台人')),
                            DataColumn(label: Text('存酒时间')),
                            DataColumn(label: Text('入库时间')),
                            DataColumn(label: Text('备注')),
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
                                  DataCell(Text(_items[i].customerName)),
                                  DataCell(Text(_items[i].customerPhone)),
                                  DataCell(Text(_items[i].seatName)),
                                  DataCell(Text(_items[i].salesName)),
                                  DataCell(Text(_items[i].saveTime)),
                                  DataCell(Text(_items[i].inLibTime)),
                                  DataCell(Text(_items[i].remark.isEmpty ? '-' : _items[i].remark)),
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

/// S5.P4 存酒库子订单视图
final class WineSaveLibChildView extends StatefulWidget {
  const WineSaveLibChildView({required this.loader, super.key});
  final WineLoader loader;

  @override
  State<WineSaveLibChildView> createState() => _WineSaveLibChildViewState();
}

final class _WineSaveLibChildViewState extends State<WineSaveLibChildView> {
  final _searchController = TextEditingController();
  final _startDayController = TextEditingController();
  final _endDayController = TextEditingController();
  List<WineInventoryItem> _items = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final fmt = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _startDayController.text = fmt;
    _endDayController.text = fmt;
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _startDayController.dispose();
    _endDayController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await widget.loader.loadSaveLibChildList(
      startDate: _startDayController.text.trim(),
      endDate: _endDayController.text.trim(),
      keyword: _searchController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.failureOrNull case final f?) {
        _error = f.safeMessage;
      } else {
        _items = res.valueOrNull ?? [];
      }
    });
  }

  void _reset() {
    final now = DateTime.now();
    final fmt = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _startDayController.text = fmt;
    _endDayController.text = fmt;
    _searchController.clear();
    unawaited(_load());
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
                width: 120,
                child: TextField(
                  controller: _startDayController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: '开始日期',
                    labelStyle: TextStyle(color: Colors.white70),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const Text('至', style: TextStyle(color: Colors.white)),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _endDayController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: '结束日期',
                    labelStyle: TextStyle(color: Colors.white70),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: '客人姓名/手机/商品/流水号/订位人',
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
                onPressed: _reset,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重置'),
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
                  ? const Center(child: Text('暂无子订单数据', style: TextStyle(color: Colors.white38)))
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
                            DataColumn(label: Text('数量')),
                            DataColumn(label: Text('存酒时间')),
                            DataColumn(label: Text('过期时间')),
                            DataColumn(label: Text('存酒流水号')),
                            DataColumn(label: Text('订位人')),
                            DataColumn(label: Text('客人姓名')),
                            DataColumn(label: Text('客人手机号')),
                            DataColumn(label: Text('授权人')),
                            DataColumn(label: Text('备注姓名')),
                            DataColumn(label: Text('备注手机号')),
                          ],
                          rows: [
                            for (var i = 0; i < _items.length; i++)
                              DataRow(
                                cells: [
                                  DataCell(Text('${i + 1}')),
                                  DataCell(Text(_items[i].wineName.isEmpty ? '-' : _items[i].wineName)),
                                  DataCell(Text(_items[i].unit.isEmpty ? '-' : _items[i].unit)),
                                  DataCell(Text(_items[i].gram.isEmpty ? '-' : _items[i].gram)),
                                  DataCell(Text('${_items[i].count}')),
                                  DataCell(Text(_items[i].saveTime.isEmpty ? '-' : _items[i].saveTime)),
                                  DataCell(Text(_items[i].expireTime.isEmpty ? '-' : _items[i].expireTime)),
                                  DataCell(Text(_items[i].subOrderNo.isEmpty ? '-' : _items[i].subOrderNo)),
                                  DataCell(Text(_items[i].salesName.isEmpty ? '-' : _items[i].salesName)),
                                  DataCell(Text(_items[i].customerName.isEmpty ? '-' : _items[i].customerName)),
                                  DataCell(Text(_items[i].customerPhone.isEmpty ? '-' : _items[i].customerPhone)),
                                  DataCell(Text(_items[i].waiterName.isEmpty ? '-' : _items[i].waiterName)),
                                  DataCell(Text(_items[i].remark.isEmpty ? '-' : _items[i].remark)),
                                  DataCell(Text(_items[i].salesDept.isEmpty ? '-' : _items[i].salesDept)),
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

/// S5.P5 过期待处理视图
final class WinePassTimeView extends StatefulWidget {
  const WinePassTimeView({required this.loader, super.key});
  final WineLoader loader;

  @override
  State<WinePassTimeView> createState() => _WinePassTimeViewState();
}

final class _WinePassTimeViewState extends State<WinePassTimeView> {
  final _searchController = TextEditingController();
  final _daysController = TextEditingController(text: '0');
  int _sortVal = 1; // 1: 过期天数, 2: 存酒日期
  List<WineInventoryItem> _items = [];
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
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await widget.loader.loadPassTimeNeedToLib(
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

  Future<void> _batchDelay() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先选择需要延期的商品')));
      return;
    }
    final daysCtrl = TextEditingController(text: '30');
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量延期'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: daysCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '延期天数', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: '延期理由', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定延期')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final days = int.tryParse(daysCtrl.text.trim()) ?? 30;
    for (final id in _selectedIds) {
      await widget.loader.delayExpiredWineInvt(id: id, days: days, reason: reasonCtrl.text.trim());
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('延期操作成功')));
    await _load();
  }

  Future<void> _batchCg() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先选择需要充公的商品')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量充公'),
        content: Text('确认将选中的 ${_selectedIds.length} 项商品充公吗？充公后将进入待充公列表。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认充公'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await widget.loader.cgExpiredWineInvt(_selectedIds.toList());
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('充公失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已加入待充公列表')));
      await _load();
    }
  }

  Future<void> _export() async {
    final res = await widget.loader.exportWineInvtExpired(
      keyword: _searchController.text.trim(),
      ordType: _sortVal,
    );
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(wineExportSuccessMessage(widget.loader))));
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
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
                        hintText: '客人姓名/手机/商品/卡台/订位人',
                        hintStyle: TextStyle(color: Colors.white38),
                        prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => unawaited(_load()),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('过期天数 > ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _daysController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                        ),
                      ),
                      const Text(' 天', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  DropdownButton<int>(
                    value: _sortVal,
                    dropdownColor: const Color(0xff182037),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('按过期天数排序')),
                      DropdownMenuItem(value: 2, child: Text('按存酒日期排序')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _sortVal = val);
                    },
                  ),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('查询'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      _daysController.text = '0';
                      unawaited(_load());
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重置'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _batchDelay,
                    icon: const Icon(Icons.access_time, size: 18),
                    label: const Text('批量延期'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
                    onPressed: _batchCg,
                    icon: const Icon(Icons.gavel, size: 18),
                    label: const Text('批量充公'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _export,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('导出'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                  ),
                  const Text('说明：过期充公酒水将进入待充公列表', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
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
                  ? const Center(child: Text('暂无过期待处理数据', style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (ctx, idx) {
                        final item = _items[idx];
                        final isExpanded = _expandedIds.contains(item.id);
                        final allSubChecked = item.items.isNotEmpty && item.items.every((s) => _selectedIds.contains(s.id));
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
                                      value: allSubChecked,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            for (final s in item.items) {
                                              _selectedIds.add(s.id);
                                            }
                                          } else {
                                            for (final s in item.items) {
                                              _selectedIds.remove(s.id);
                                            }
                                          }
                                        });
                                      },
                                    ),
                                    Text('${idx + 1}. 客人: ${item.customerName} (${item.customerPhone})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 16),
                                    Text('卡台: ${item.seatName}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(width: 16),
                                    Text('订台人: ${item.salesName}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                                subtitle: Text('存酒时间: ${item.saveTime}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              ),
                              if (isExpanded && item.items.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  color: const Color(0xff141F36),
                                  child: Column(
                                    children: [
                                      for (var sIdx = 0; sIdx < item.items.length; sIdx++)
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: _selectedIds.contains(item.items[sIdx].id),
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedIds.add(item.items[sIdx].id);
                                                  } else {
                                                    _selectedIds.remove(item.items[sIdx].id);
                                                  }
                                                });
                                              },
                                            ),
                                            Text('${sIdx + 1}. ', style: const TextStyle(color: Colors.white38)),
                                            Expanded(
                                              flex: 2,
                                              child: Text(item.items[sIdx].wineName, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                            ),
                                            Expanded(
                                              child: Text('规格: ${item.items[sIdx].unit} (${item.items[sIdx].gram})', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                            ),
                                            Expanded(
                                              child: Text('数量: ${item.items[sIdx].count}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                                            ),
                                            Expanded(
                                              child: Text('过期天数: ${item.items[sIdx].daysLeft}', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                                            ),
                                            Expanded(
                                              child: Text('过期时间: ${item.items[sIdx].expireTime}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                            ),
                                          ],
                                        ),
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

/// S5.P6 全部数据（网格呈现+弹窗明细+导出）
final class WineSaveLibAllDataView extends StatefulWidget {
  const WineSaveLibAllDataView({required this.loader, super.key});
  final WineLoader loader;

  @override
  State<WineSaveLibAllDataView> createState() => _WineSaveLibAllDataViewState();
}

final class _WineSaveLibAllDataViewState extends State<WineSaveLibAllDataView> {
  final _searchController = TextEditingController();
  List<WineGridItem> _items = [];
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
    final res = await widget.loader.loadSaveLibGrid(
      keyword: _searchController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.failureOrNull case final f?) {
        _error = f.safeMessage;
      } else {
        _items = res.valueOrNull ?? [];
      }
    });
  }

  Future<void> _export() async {
    final res = await widget.loader.exportExcelOfGridReport();
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(wineExportSuccessMessage(widget.loader))));
    }
  }

  void _showDetail(WineGridItem item, String spec) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => _WineGridDetailDialog(loader: widget.loader, item: item, spec: spec),
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
                onPressed: _export,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('导出'),
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
                  ? const Center(child: Text('暂无网格库存数据', style: TextStyle(color: Colors.white38)))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xff182037)),
                          dataRowColor: WidgetStateProperty.all(const Color(0xff0D172D)),
                          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
                          columns: const [
                            DataColumn(label: Text('商品名称')),
                            DataColumn(label: Text('整瓶')),
                            DataColumn(label: Text('0.1')),
                            DataColumn(label: Text('0.2')),
                            DataColumn(label: Text('0.3')),
                            DataColumn(label: Text('0.4')),
                            DataColumn(label: Text('0.5')),
                            DataColumn(label: Text('0.6')),
                            DataColumn(label: Text('0.7')),
                            DataColumn(label: Text('0.8')),
                            DataColumn(label: Text('0.9')),
                          ],
                          rows: [
                            for (final item in _items)
                              DataRow(
                                cells: [
                                  DataCell(Text(item.productName)),
                                  _buildSpecCell(item, '1', item.wholeBottle),
                                  _buildSpecCell(item, '0.1', item.partials['0.1'] ?? ''),
                                  _buildSpecCell(item, '0.2', item.partials['0.2'] ?? ''),
                                  _buildSpecCell(item, '0.3', item.partials['0.3'] ?? ''),
                                  _buildSpecCell(item, '0.4', item.partials['0.4'] ?? ''),
                                  _buildSpecCell(item, '0.5', item.partials['0.5'] ?? ''),
                                  _buildSpecCell(item, '0.6', item.partials['0.6'] ?? ''),
                                  _buildSpecCell(item, '0.7', item.partials['0.7'] ?? ''),
                                  _buildSpecCell(item, '0.8', item.partials['0.8'] ?? ''),
                                  _buildSpecCell(item, '0.9', item.partials['0.9'] ?? ''),
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

  DataCell _buildSpecCell(WineGridItem item, String spec, String value) {
    final count = int.tryParse(value) ?? 0;
    if (count <= 0) {
      return const DataCell(Text(''));
    }
    return DataCell(
      InkWell(
        onTap: () => _showDetail(item, spec),
        child: Text(
          value,
          style: const TextStyle(color: Colors.lightBlueAccent, decoration: TextDecoration.underline),
        ),
      ),
    );
  }
}

class _WineGridDetailDialog extends StatefulWidget {
  const _WineGridDetailDialog({
    required this.loader,
    required this.item,
    required this.spec,
  });

  final WineLoader loader;
  final WineGridItem item;
  final String spec;

  @override
  State<_WineGridDetailDialog> createState() => _WineGridDetailDialogState();
}

class _WineGridDetailDialogState extends State<_WineGridDetailDialog> {
  List<WineInventoryItem> _details = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final res = await widget.loader.loadSaveLibGridDetail(widget.item.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.failureOrNull case final f?) {
        _error = f.safeMessage;
      } else {
        _details = res.valueOrNull ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xff0D172D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 860,
        height: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '库存明细 - ${widget.item.productName} (${widget.spec == '1' ? '整瓶' : '${widget.spec}瓶'})',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Color(0xff2A3959)),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withAlpha(50),
                child: Text('加载错误: $_error', style: const TextStyle(color: Colors.redAccent)),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _details.isEmpty
                      ? const Center(child: Text('暂无详细数据', style: TextStyle(color: Colors.white38)))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xff182037)),
                              headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              dataTextStyle: const TextStyle(color: Colors.white, fontSize: 11),
                              columns: const [
                                DataColumn(label: Text('序号')),
                                DataColumn(label: Text('入库时间')),
                                DataColumn(label: Text('客人姓名')),
                                DataColumn(label: Text('手机号')),
                                DataColumn(label: Text('库存数量')),
                                DataColumn(label: Text('流水号')),
                                DataColumn(label: Text('卡台')),
                                DataColumn(label: Text('订位人')),
                                DataColumn(label: Text('服务员')),
                                DataColumn(label: Text('存酒时间')),
                                DataColumn(label: Text('过期时间')),
                              ],
                              rows: [
                                for (var i = 0; i < _details.length; i++)
                                  DataRow(
                                    cells: [
                                      DataCell(Text('${i + 1}')),
                                      DataCell(Text(_details[i].inLibTime)),
                                      DataCell(Text(_details[i].customerName)),
                                      DataCell(Text(_details[i].customerPhone)),
                                      DataCell(Text('${_details[i].count}')),
                                      DataCell(Text(_details[i].subOrderNo)),
                                      DataCell(Text(_details[i].seatName)),
                                      DataCell(Text(_details[i].salesName)),
                                      DataCell(Text(_details[i].waiterName)),
                                      DataCell(Text(_details[i].saveTime)),
                                      DataCell(Text(_details[i].expireTime)),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
