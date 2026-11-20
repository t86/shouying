export 'package:card_table/src/erp_sout_workflow_views.dart';

import 'dart:async';

import 'package:card_table/src/erp_loader.dart';
import 'package:card_table/src/erp_models.dart';
import 'package:flutter/material.dart';

// =============================================================================
// S8.P3.T01 其他出库
// =============================================================================

// Other-out retains its dedicated source workflow; transfer-out below is unchanged.

// =============================================================================
// S8.P3.T02 调拨出库
// =============================================================================

class ErpChangeOutLibView extends StatefulWidget {
  const ErpChangeOutLibView({required this.loader, super.key});
  final ErpLoader loader;

  @override
  State<ErpChangeOutLibView> createState() => _ErpChangeOutLibViewState();
}

class _ErpChangeOutLibViewState extends State<ErpChangeOutLibView> {
  bool _loading = false;
  List<ErpSoutdItem> _items = const [];
  int? _selectedStatus;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadSoutdList(status: _selectedStatus);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res.valueOrNull ?? [];
    });
  }

  void _openNewSoutdDialog() {
    final outStoreCtrl = TextEditingController();
    final inStoreCtrl = TextEditingController();
    final memoCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建调拨出库单'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: outStoreCtrl,
                decoration: const InputDecoration(labelText: '调出仓库 ID'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: inStoreCtrl,
                decoration: const InputDecoration(labelText: '调入仓库 ID'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: memoCtrl,
                decoration: const InputDecoration(labelText: '调拨事由'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.loader.createSoutdOrder({
                'out_store_id': outStoreCtrl.text.trim(),
                'in_store_id': inStoreCtrl.text.trim(),
                'memo': memoCtrl.text.trim(),
                'record_type': 3,
              });
              unawaited(_loadData());
            },
            child: const Text('提交调拨出库'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('调拨出库', style: Theme.of(context).textTheme.headlineSmall),
              FilledButton.icon(
                onPressed: _openNewSoutdDialog,
                icon: const Icon(Icons.add),
                label: const Text('新建调拨出库单'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('序号')),
                          DataColumn(label: Text('单号')),
                          DataColumn(label: Text('调出仓库')),
                          DataColumn(label: Text('调入仓库')),
                          DataColumn(label: Text('调拨日期')),
                          DataColumn(label: Text('制单人')),
                          DataColumn(label: Text('状态')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: [
                          for (var i = 0; i < _items.length; i++)
                            DataRow(
                              cells: [
                                DataCell(Text('${i + 1}')),
                                DataCell(Text(_items[i].code)),
                                DataCell(Text(_items[i].outStoreName)),
                                DataCell(Text(_items[i].inStoreName)),
                                DataCell(Text(_items[i].billDay)),
                                DataCell(Text(_items[i].operName)),
                                DataCell(
                                  Text(
                                    _items[i].status == 1 ? '已审核' : '已红冲',
                                    style: TextStyle(
                                      color: _items[i].status == 1
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      if (_items[i].status == 1) ...[
                                        TextButton(
                                          onPressed: () async {
                                            await widget.loader
                                                .reverseSoutdOrder(
                                                  _items[i].id,
                                                );
                                            unawaited(_loadData());
                                          },
                                          child: const Text('反审核'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await widget.loader
                                                .redPunchSoutdOrder(
                                                  _items[i].id,
                                                );
                                            unawaited(_loadData());
                                          },
                                          child: const Text(
                                            '红冲',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
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
      ),
    );
  }
}

// =============================================================================
// S8.P3.T03 出库异议订单
// =============================================================================

class ErpApplyForOutLibView extends StatefulWidget {
  const ErpApplyForOutLibView({required this.loader, super.key});
  final ErpLoader loader;

  @override
  State<ErpApplyForOutLibView> createState() => _ErpApplyForOutLibViewState();
}

class _ErpApplyForOutLibViewState extends State<ErpApplyForOutLibView> {
  bool _loading = false;
  List<ErpDisputeItem> _items = const [];
  int _orderStatus = 3;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadDisputeOutList(
      status: _orderStatus == 0 ? null : _orderStatus,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res.valueOrNull ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('出库异议订单', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('状态：', style: TextStyle(fontWeight: FontWeight.bold)),
              for (final entry in [
                (0, '全部'),
                (3, '待处理'),
                (2, '已处理'),
                (1, '已完成'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.$2),
                    selected: _orderStatus == entry.$1,
                    onSelected: (v) {
                      if (v) {
                        setState(() => _orderStatus = entry.$1);
                        unawaited(_loadData());
                      }
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('序号')),
                          DataColumn(label: Text('单号')),
                          DataColumn(label: Text('子单号')),
                          DataColumn(label: Text('物料名称')),
                          DataColumn(label: Text('异议数量')),
                          DataColumn(label: Text('出库日期')),
                          DataColumn(label: Text('状态')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: [
                          for (var i = 0; i < _items.length; i++)
                            DataRow(
                              cells: [
                                DataCell(Text('${i + 1}')),
                                DataCell(Text(_items[i].code)),
                                DataCell(Text(_items[i].subCode)),
                                DataCell(Text(_items[i].matName)),
                                DataCell(
                                  Text(
                                    '${_items[i].diffCount}',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                                DataCell(Text(_items[i].date)),
                                DataCell(
                                  Text(
                                    switch (_items[i].status) {
                                      3 => '待处理',
                                      2 => '已处理',
                                      1 => '已完成',
                                      _ => '未知',
                                    },
                                    style: TextStyle(
                                      color: switch (_items[i].status) {
                                        3 => Colors.orange,
                                        2 => Colors.blue,
                                        1 => Colors.green,
                                        _ => Colors.grey,
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      if (_items[i].status == 3) ...[
                                        TextButton(
                                          onPressed: () async {
                                            await widget.loader
                                                .redPunchDisputeOut(
                                                  _items[i].id,
                                                );
                                            unawaited(_loadData());
                                          },
                                          child: const Text('直接红冲'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await widget.loader
                                                .breakLossDisputeOut(
                                                  _items[i].id,
                                                );
                                            unawaited(_loadData());
                                          },
                                          child: const Text('报损出库'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await widget.loader
                                                .rejectDisputeOut(_items[i].id);
                                            unawaited(_loadData());
                                          },
                                          child: const Text(
                                            '驳回',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
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
      ),
    );
  }
}
