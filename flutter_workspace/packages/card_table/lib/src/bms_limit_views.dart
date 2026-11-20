import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_models.dart';
import 'package:flutter/material.dart';

// =============================================================================
// S7.P4.T01 商品组管理视图
// =============================================================================

class BmsPrdGroupConfigView extends StatefulWidget {
  const BmsPrdGroupConfigView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsPrdGroupConfigView> createState() => _BmsPrdGroupConfigViewState();
}

class _BmsPrdGroupConfigViewState extends State<BmsPrdGroupConfigView> {
  List<BmsProductGroupItem> _groups = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadProductGroups();
    if (mounted) {
      setState(() {
        _loading = false;
        _groups = res.valueOrNull ?? [];
      });
    }
  }

  void _openGroupForm([BmsProductGroupItem? group]) {
    final nameCtrl = TextEditingController(text: group?.name ?? '');
    final remarkCtrl = TextEditingController(text: group?.remark ?? '');

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group == null ? '新建商品组' : '编辑商品组', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '商品组名称')),
            const SizedBox(height: 12),
            TextField(controller: remarkCtrl, decoration: const InputDecoration(labelText: '备注说明')),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await widget.loader.saveProductGroup({
                      if (group != null) 'id': group.id,
                      'name': nameCtrl.text.trim(),
                      'remark': remarkCtrl.text.trim(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadData();
                  },
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('商品组管理'),
        actions: [
          IconButton(
            key: const Key('bms-pgrp-add-btn'),
            icon: const Icon(Icons.add),
            onPressed: () => _openGroupForm(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const Center(child: Text('暂无商品组数据'))
              : ListView.separated(
                  itemCount: _groups.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final item = _groups[idx];
                    return ListTile(
                      key: Key('bms-pgrp-item-${item.id}'),
                      title: Text(item.name),
                      subtitle: Text('包含商品数: ${item.prdIds.length} | 备注: ${item.remark}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _openGroupForm(item),
                      ),
                    );
                  },
                ),
    );
  }
}

// =============================================================================
// S7.P4.T02 限额限量管理视图
// =============================================================================

class BmsLimitConfigView extends StatefulWidget {
  const BmsLimitConfigView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsLimitConfigView> createState() => _BmsLimitConfigViewState();
}

class _BmsLimitConfigViewState extends State<BmsLimitConfigView> {
  List<BmsLimitConfigItem> _limits = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadLimitConfigs();
    if (mounted) {
      setState(() {
        _loading = false;
        _limits = res.valueOrNull ?? [];
      });
    }
  }

  void _openLimitForm([BmsLimitConfigItem? limit]) {
    final nameCtrl = TextEditingController(text: limit?.name ?? '');
    final qtyCtrl = TextEditingController(text: limit != null ? limit.maxQty.toString() : '0');
    final amountCtrl = TextEditingController(text: limit != null ? limit.maxAmount.toString() : '0.0');

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(limit == null ? '新建限额限量' : '编辑限额限量', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '方案名称')),
            const SizedBox(height: 12),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: '最大限量 (件/份)'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: '最高限额 (¥)'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await widget.loader.saveLimitConfig({
                      if (limit != null) 'id': limit.id,
                      'name': nameCtrl.text.trim(),
                      'max_qty': int.tryParse(qtyCtrl.text) ?? 0,
                      'max_amount': double.tryParse(amountCtrl.text) ?? 0.0,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadData();
                  },
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('限额限量管理'),
        actions: [
          IconButton(
            key: const Key('bms-limit-add-btn'),
            icon: const Icon(Icons.add),
            onPressed: () => _openLimitForm(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _limits.isEmpty
              ? const Center(child: Text('暂无限额限量规则'))
              : ListView.separated(
                  itemCount: _limits.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final item = _limits[idx];
                    return ListTile(
                      key: Key('bms-limit-item-${item.id}'),
                      title: Text(item.name),
                      subtitle: Text('限量: ${item.maxQty}份 | 限额: ¥${item.maxAmount} | 状态: ${item.status == 1 ? "生效中" : "已停用"}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _openLimitForm(item),
                      ),
                    );
                  },
                ),
    );
  }
}
