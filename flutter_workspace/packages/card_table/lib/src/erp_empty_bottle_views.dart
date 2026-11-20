import 'dart:async';
import 'package:card_table/src/erp_loader.dart';
import 'package:card_table/src/erp_models.dart';
import 'package:flutter/material.dart';

// =============================================================================
// S8.P4.T01 空瓶入库单
// =============================================================================

class ErpEmptyInLibOrderView extends StatefulWidget {
  const ErpEmptyInLibOrderView({required this.loader, super.key});
  final ErpLoader loader;

  @override
  State<ErpEmptyInLibOrderView> createState() => _ErpEmptyInLibOrderViewState();
}

class _ErpEmptyInLibOrderViewState extends State<ErpEmptyInLibOrderView> {
  bool _loading = false;
  List<ErpEmptyInItem> _items = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadEmptyInList();
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
          Text('空瓶入库单', style: Theme.of(context).textTheme.headlineSmall),
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
                          DataColumn(label: Text('入库日期')),
                          DataColumn(label: Text('入库数量')),
                          DataColumn(label: Text('状态')),
                          DataColumn(label: Text('操作人')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: [
                          for (var i = 0; i < _items.length; i++)
                            DataRow(cells: [
                              DataCell(Text('${i + 1}')),
                              DataCell(Text(_items[i].code)),
                              DataCell(Text(_items[i].day)),
                              DataCell(Text('${_items[i].count}')),
                              DataCell(Text(_items[i].status == 1 ? '已入库' : '已红冲',
                                  style: TextStyle(color: _items[i].status == 1 ? Colors.green : Colors.red))),
                              DataCell(Text(_items[i].operName)),
                              DataCell(Row(
                                children: [
                                  if (_items[i].status == 1) ...[
                                    TextButton(
                                      onPressed: () async {
                                        await widget.loader.confirmEmptyIn(_items[i].id);
                                        unawaited(_loadData());
                                      },
                                      child: const Text('确认入库'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await widget.loader.redPunchEmptyIn(_items[i].id);
                                        unawaited(_loadData());
                                      },
                                      child: const Text('红冲', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ],
                              )),
                            ]),
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
// S8.P4.T02 空瓶仓
// =============================================================================

class ErpEmptyLibView extends StatefulWidget {
  const ErpEmptyLibView({required this.loader, super.key});
  final ErpLoader loader;

  @override
  State<ErpEmptyLibView> createState() => _ErpEmptyLibViewState();
}

class _ErpEmptyLibViewState extends State<ErpEmptyLibView> {
  bool _loading = false;
  List<ErpEmptyInvtItem> _items = const [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadEmptyInvtList(keyword: _searchCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res.valueOrNull ?? [];
    });
  }

  void _openBatchOutDialog() {
    final selected = _items.where((i) => i.checked).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先勾选需要出库的空瓶商品')));
      return;
    }

    final memoCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('批量空瓶出库 (已选 ${selected.length} 种)'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: memoCtrl, decoration: const InputDecoration(labelText: '出库备注 / 说明')),
              const SizedBox(height: 12),
              for (final s in selected)
                ListTile(
                  dense: true,
                  title: Text(s.name),
                  trailing: Text('库存: ${s.count}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.loader.submitEmptyOut({
                'memo': memoCtrl.text.trim(),
                'items': selected.map((s) => {'id': s.id, 'n': s.name, 'c': s.count}).toList(),
              });
              unawaited(_loadData());
            },
            child: const Text('确认出库'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allChecked = _items.isNotEmpty && _items.every((i) => i.checked);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('空瓶仓', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: '空瓶名称',
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => unawaited(_loadData()),
                    ),
                  ),
                  onSubmitted: (_) => unawaited(_loadData()),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _openBatchOutDialog,
                icon: const Icon(Icons.outbox),
                label: const Text('批量出库'),
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
                        columns: [
                          DataColumn(
                            label: Row(
                              children: [
                                Checkbox(
                                  value: allChecked,
                                  onChanged: (v) {
                                    final checked = v ?? false;
                                    setState(() {
                                      _items = _items.map((i) => i.copyWith(checked: checked)).toList();
                                    });
                                  },
                                ),
                                const Text('全选'),
                              ],
                            ),
                          ),
                          const DataColumn(label: Text('空瓶名称')),
                          const DataColumn(label: Text('库存数量')),
                        ],
                        rows: [
                          for (var i = 0; i < _items.length; i++)
                            DataRow(
                              selected: _items[i].checked,
                              onSelectChanged: (v) {
                                setState(() {
                                  _items[i] = _items[i].copyWith(checked: v ?? false);
                                });
                              },
                              cells: [
                                DataCell(Text('${i + 1}')),
                                DataCell(Text(_items[i].name)),
                                DataCell(Text('${_items[i].count}')),
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
// S8.P4.T03 空瓶出库单
// =============================================================================

class ErpEmptyOutLibOrderView extends StatefulWidget {
  const ErpEmptyOutLibOrderView({required this.loader, super.key});
  final ErpLoader loader;

  @override
  State<ErpEmptyOutLibOrderView> createState() => _ErpEmptyOutLibOrderViewState();
}

class _ErpEmptyOutLibOrderViewState extends State<ErpEmptyOutLibOrderView> {
  bool _loading = false;
  List<ErpEmptyOutItem> _items = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadEmptyOutList();
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
          Text('空瓶出库单', style: Theme.of(context).textTheme.headlineSmall),
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
                          DataColumn(label: Text('出库日期')),
                          DataColumn(label: Text('出库数量')),
                          DataColumn(label: Text('状态')),
                          DataColumn(label: Text('操作人')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: [
                          for (var i = 0; i < _items.length; i++)
                            DataRow(cells: [
                              DataCell(Text('${i + 1}')),
                              DataCell(Text(_items[i].code)),
                              DataCell(Text(_items[i].day)),
                              DataCell(Text('${_items[i].count}')),
                              DataCell(Text(_items[i].status == 1 ? '已出库' : '已红冲',
                                  style: TextStyle(color: _items[i].status == 1 ? Colors.green : Colors.red))),
                              DataCell(Text(_items[i].operName)),
                              DataCell(Row(
                                children: [
                                  if (_items[i].status == 1)
                                    TextButton(
                                      onPressed: () async {
                                        await widget.loader.redPunchEmptyOut(_items[i].id);
                                        unawaited(_loadData());
                                      },
                                      child: const Text('红冲', style: TextStyle(color: Colors.red)),
                                    ),
                                ],
                              )),
                            ]),
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
