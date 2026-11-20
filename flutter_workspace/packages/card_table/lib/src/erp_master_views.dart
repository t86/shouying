import 'dart:async';
import 'package:card_table/src/erp_loader.dart';
import 'package:card_table/src/erp_models.dart';
import 'package:flutter/material.dart';

// =============================================================================
// S8.P1.T01 ERP 首页
// =============================================================================

class ErpHomeView extends StatefulWidget {
  const ErpHomeView({required this.loader, super.key});
  final ErpLoader loader;

  @override
  State<ErpHomeView> createState() => _ErpHomeViewState();
}

class _ErpHomeViewState extends State<ErpHomeView> {
  bool _loading = false;
  String? _error;
  List<ErpNegStoreAlert> _negAlerts = const [];
  List<ErpUnboundPrdAlert> _unboundAlerts = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    final negRes = await widget.loader.loadNegStoreAlerts();
    final unboundRes = await widget.loader.loadUnboundPrdAlerts();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = negRes.failureOrNull?.safeMessage ?? unboundRes.failureOrNull?.safeMessage;
      _negAlerts = negRes.valueOrNull ?? [];
      _unboundAlerts = unboundRes.valueOrNull ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, textAlign: TextAlign.center),
        TextButton(onPressed: _loadData, child: const Text('重试')),
      ]));
    }

    final hasNoAlerts = _negAlerts.isEmpty && _unboundAlerts.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasNoAlerts)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 36),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ERP 仓库运行正常', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        const Text('暂无负库存物料或待对照的收银商品', style: TextStyle(color: Colors.grey)),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          if (_negAlerts.isNotEmpty) ...[
            Text(
              '！检测到以下物料库存为负，请尽快处理',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            for (final alert in _negAlerts)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('仓库：${alert.storeName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('正在跳转处理仓库 ${alert.storeName} 的负库存')),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('立即处理 >>'),
                          ),
                        ],
                      ),
                      const Divider(),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('序号')),
                            DataColumn(label: Text('收银商品名称')),
                            DataColumn(label: Text('对应物料名称')),
                            DataColumn(label: Text('一级分类')),
                            DataColumn(label: Text('二级分类')),
                            DataColumn(label: Text('单位')),
                            DataColumn(label: Text('当前库存')),
                            DataColumn(label: Text('卡住库存数')),
                          ],
                          rows: [
                            for (var i = 0; i < alert.materials.length; i++)
                              DataRow(cells: [
                                DataCell(Text('${i + 1}')),
                                DataCell(Text(alert.materials[i].productName)),
                                DataCell(Text(alert.materials[i].matName)),
                                DataCell(Text(alert.materials[i].oneCate)),
                                DataCell(Text(alert.materials[i].twoCate)),
                                DataCell(Text(alert.materials[i].unit)),
                                DataCell(Text('${alert.materials[i].count}', style: const TextStyle(color: Colors.redAccent))),
                                DataCell(Text('${alert.materials[i].blockedCount}')),
                              ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          if (_unboundAlerts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '！检测到以下售出的收银商品未配置对照关系，请尽快处理',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('序号')),
                    DataColumn(label: Text('收银商品名称')),
                    DataColumn(label: Text('一级分类')),
                    DataColumn(label: Text('二级分类')),
                    DataColumn(label: Text('操作')),
                  ],
                  rows: [
                    for (var i = 0; i < _unboundAlerts.length; i++)
                      DataRow(cells: [
                        DataCell(Text('${i + 1}')),
                        DataCell(Text(_unboundAlerts[i].productName)),
                        DataCell(Text(_unboundAlerts[i].oneCate)),
                        DataCell(Text(_unboundAlerts[i].twoCate)),
                        DataCell(Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('去绑定商品: ${_unboundAlerts[i].productName}')),
                                );
                              },
                              child: const Text('去绑定'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await widget.loader.closeBindPrds([_unboundAlerts[i].id]);
                                unawaited(_loadData());
                              },
                              child: const Text('不用对照'),
                            ),
                          ],
                        )),
                      ]),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// S8.P1.T02 仓库管理 CRUD
// =============================================================================

class ErpStoreManagementView extends StatefulWidget {
  const ErpStoreManagementView({required this.loader, super.key});
  final ErpLoader loader;

  @override
  State<ErpStoreManagementView> createState() => _ErpStoreManagementViewState();
}

class _ErpStoreManagementViewState extends State<ErpStoreManagementView> {
  bool _loading = false;
  List<ErpStoreItem> _stores = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadStores();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _stores = res.valueOrNull ?? [];
    });
  }

  void _openStoreDialog([ErpStoreItem? item]) {
    final codeCtrl = TextEditingController(text: item?.code ?? '');
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final memoCtrl = TextEditingController(text: item?.memo ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? '新建仓库' : '编辑仓库'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '仓库编码')),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '仓库名称')),
              const SizedBox(height: 12),
              TextField(controller: memoCtrl, decoration: const InputDecoration(labelText: '备注')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final newStore = ErpStoreItem(
                id: item?.id ?? '',
                code: codeCtrl.text.trim(),
                name: nameCtrl.text.trim(),
                memo: memoCtrl.text.trim(),
                status: item?.status ?? 1,
              );
              Navigator.pop(ctx);
              await widget.loader.saveStore(newStore);
              unawaited(_loadData());
            },
            child: const Text('保存'),
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
              Text('仓库管理', style: Theme.of(context).textTheme.headlineSmall),
              FilledButton.icon(
                onPressed: () => _openStoreDialog(),
                icon: const Icon(Icons.add),
                label: const Text('新建仓库'),
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
                          DataColumn(label: Text('编码')),
                          DataColumn(label: Text('仓库名称')),
                          DataColumn(label: Text('状态')),
                          DataColumn(label: Text('备注')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: [
                          for (var i = 0; i < _stores.length; i++)
                            DataRow(cells: [
                              DataCell(Text('${i + 1}')),
                              DataCell(Text(_stores[i].code)),
                              DataCell(Text(_stores[i].name)),
                              DataCell(Text(_stores[i].isValid ? '正常' : '停用',
                                  style: TextStyle(color: _stores[i].isValid ? Colors.green : Colors.grey))),
                              DataCell(Text(_stores[i].memo)),
                              DataCell(Row(
                                children: [
                                  TextButton(onPressed: () => _openStoreDialog(_stores[i]), child: const Text('编辑')),
                                  TextButton(
                                    onPressed: () async {
                                      await widget.loader.toggleStoreStatus(_stores[i].id, !_stores[i].isValid);
                                      unawaited(_loadData());
                                    },
                                    child: Text(_stores[i].isValid ? '停用' : '启用'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await widget.loader.deleteStore(_stores[i].id);
                                      unawaited(_loadData());
                                    },
                                    child: const Text('删除', style: TextStyle(color: Colors.red)),
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

// =============================================================================
// S8.P1.T03 / T04 物料列表与物料新建/保存/单位
// =============================================================================

class ErpMatsView extends StatefulWidget {
  const ErpMatsView({required this.loader, super.key});
  final ErpLoader loader;

  @override
  State<ErpMatsView> createState() => _ErpMatsViewState();
}

class _ErpMatsViewState extends State<ErpMatsView> {
  bool _loading = false;
  List<ErpMatCate> _cates = const [];
  List<ErpMatItem> _mats = const [];
  String? _selectedOneCateId;
  String? _selectedTwoCateId;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final cateRes = await widget.loader.loadMatCateTree();
    final matRes = await widget.loader.loadMats(
      oneCateId: _selectedOneCateId,
      twoCateId: _selectedTwoCateId,
      keyword: _searchCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _cates = cateRes.valueOrNull ?? [];
      _mats = matRes.valueOrNull ?? [];
    });
  }

  void _openMatDialog([ErpMatItem? item]) {
    final codeCtrl = TextEditingController(text: item?.code ?? '');
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final unitCtrl = TextEditingController(text: item?.unitName ?? '');
    final priceCtrl = TextEditingController(text: item != null ? '${item.price}' : '0.0');
    final specCtrl = TextEditingController(text: item?.spec ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? '新建物料' : '编辑物料'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '物料编码')),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '物料名称')),
                const SizedBox(height: 12),
                TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: '主单位 (如: 瓶/箱/包)')),
                const SizedBox(height: 12),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: '成本单价 (元)')),
                const SizedBox(height: 12),
                TextField(controller: specCtrl, decoration: const InputDecoration(labelText: '规格型号')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final newMat = ErpMatItem(
                id: item?.id ?? '',
                code: codeCtrl.text.trim(),
                name: nameCtrl.text.trim(),
                unitName: unitCtrl.text.trim(),
                price: double.tryParse(priceCtrl.text) ?? 0.0,
                spec: specCtrl.text.trim(),
                oneCateId: _selectedOneCateId ?? '',
                twoCateId: _selectedTwoCateId ?? '',
                status: item?.status ?? 1,
              );
              Navigator.pop(ctx);
              await widget.loader.saveMat(newMat);
              unawaited(_loadData());
            },
            child: const Text('保存'),
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
            children: [
              Text('物料管理', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: '物料名称或编码',
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
                onPressed: () => _openMatDialog(),
                icon: const Icon(Icons.add),
                label: const Text('新建物料'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧分类导航
                Container(
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView(
                    children: [
                      ListTile(
                        dense: true,
                        selected: _selectedOneCateId == null,
                        title: const Text('全部分类', style: TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () {
                          setState(() {
                            _selectedOneCateId = null;
                            _selectedTwoCateId = null;
                          });
                          unawaited(_loadData());
                        },
                      ),
                      for (final cate in _cates)
                        ExpansionTile(
                          dense: true,
                          title: Text(cate.name),
                          initiallyExpanded: true,
                          children: [
                            for (final sub in cate.children)
                              ListTile(
                                dense: true,
                                selected: _selectedTwoCateId == sub.id,
                                title: Text(sub.name),
                                onTap: () {
                                  setState(() {
                                    _selectedOneCateId = cate.id;
                                    _selectedTwoCateId = sub.id;
                                  });
                                  unawaited(_loadData());
                                },
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 右侧物料列表
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('序号')),
                                DataColumn(label: Text('编码')),
                                DataColumn(label: Text('物料名称')),
                                DataColumn(label: Text('单位')),
                                DataColumn(label: Text('单价')),
                                DataColumn(label: Text('规格')),
                                DataColumn(label: Text('状态')),
                                DataColumn(label: Text('操作')),
                              ],
                              rows: [
                                for (var i = 0; i < _mats.length; i++)
                                  DataRow(cells: [
                                    DataCell(Text('${i + 1}')),
                                    DataCell(Text(_mats[i].code)),
                                    DataCell(Text(_mats[i].name)),
                                    DataCell(Text(_mats[i].unitName)),
                                    DataCell(Text('¥${_mats[i].price.toStringAsFixed(2)}')),
                                    DataCell(Text(_mats[i].spec)),
                                    DataCell(Text(_mats[i].isValid ? '正常' : '停用',
                                        style: TextStyle(color: _mats[i].isValid ? Colors.green : Colors.grey))),
                                    DataCell(Row(
                                      children: [
                                        TextButton(onPressed: () => _openMatDialog(_mats[i]), child: const Text('编辑')),
                                        TextButton(
                                          onPressed: () async {
                                            await widget.loader.toggleMatStatus(_mats[i].id, !_mats[i].isValid);
                                            unawaited(_loadData());
                                          },
                                          child: Text(_mats[i].isValid ? '停用' : '启用'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await widget.loader.deleteMat(_mats[i].id);
                                            unawaited(_loadData());
                                          },
                                          child: const Text('删除', style: TextStyle(color: Colors.red)),
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
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// S8.P1.T05 商品对照
// =============================================================================

class ErpComparePrdView extends StatefulWidget {
  const ErpComparePrdView({required this.loader, super.key});
  final ErpLoader loader;

  @override
  State<ErpComparePrdView> createState() => _ErpComparePrdViewState();
}

class _ErpComparePrdViewState extends State<ErpComparePrdView> {
  int _activeTab = 1; // 1: 待绑定, 2: 已绑定, 3: 不绑定
  bool _loading = false;
  List<ErpComparePrdItem> _items = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadComparePrds(_activeTab);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res.valueOrNull ?? [];
    });
  }

  void _openBindDialog(ErpComparePrdItem item) {
    final matIdCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('对照商品: ${item.productName}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: matIdCtrl,
                decoration: const InputDecoration(labelText: '目标物料 ID / 编号', hintText: '输入物料 ID 完成关联对照'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final matId = matIdCtrl.text.trim();
              if (matId.isEmpty) return;
              Navigator.pop(ctx);
              await widget.loader.bindMatPrd(prdId: item.id, matId: matId);
              unawaited(_loadData());
            },
            child: const Text('确认绑定'),
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
          Text('商品对照', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              ChoiceChip(
                label: const Text('待绑定存货商品'),
                selected: _activeTab == 1,
                onSelected: (v) {
                  if (v) {
                    setState(() => _activeTab = 1);
                    unawaited(_loadData());
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('已绑定存货商品'),
                selected: _activeTab == 2,
                onSelected: (v) {
                  if (v) {
                    setState(() => _activeTab = 2);
                    unawaited(_loadData());
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('不绑定存货商品'),
                selected: _activeTab == 3,
                onSelected: (v) {
                  if (v) {
                    setState(() => _activeTab = 3);
                    unawaited(_loadData());
                  }
                },
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
                          DataColumn(label: Text('收银商品名称')),
                          DataColumn(label: Text('一级分类')),
                          DataColumn(label: Text('二级分类')),
                          DataColumn(label: Text('关联物料')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: [
                          for (var i = 0; i < _items.length; i++)
                            DataRow(cells: [
                              DataCell(Text('${i + 1}')),
                              DataCell(Text(_items[i].productName)),
                              DataCell(Text(_items[i].oneCate)),
                              DataCell(Text(_items[i].twoCate)),
                              DataCell(Text(_items[i].matName.isEmpty ? '-' : _items[i].matName)),
                              DataCell(Row(
                                children: [
                                  if (_activeTab == 1) ...[
                                    TextButton(
                                      onPressed: () => _openBindDialog(_items[i]),
                                      child: const Text('去绑定'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await widget.loader.closeBindPrds([_items[i].id]);
                                        unawaited(_loadData());
                                      },
                                      child: const Text('不用对照'),
                                    ),
                                  ],
                                  if (_activeTab == 2)
                                    TextButton(
                                      onPressed: () => _openBindDialog(_items[i]),
                                      child: const Text('重新绑定'),
                                    ),
                                  if (_activeTab == 3)
                                    TextButton(
                                      onPressed: () => _openBindDialog(_items[i]),
                                      child: const Text('恢复绑定'),
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

// =============================================================================
// S8.P1.T06 供应商 CRUD
// =============================================================================

class ErpSupplierView extends StatefulWidget {
  const ErpSupplierView({required this.loader, super.key});
  final ErpLoader loader;

  @override
  State<ErpSupplierView> createState() => _ErpSupplierViewState();
}

class _ErpSupplierViewState extends State<ErpSupplierView> {
  bool _loading = false;
  List<ErpSupplierItem> _suppliers = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadSuppliers();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _suppliers = res.valueOrNull ?? [];
    });
  }

  void _openSupplierDialog([ErpSupplierItem? item]) {
    final codeCtrl = TextEditingController(text: item?.code ?? '');
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final linkmanCtrl = TextEditingController(text: item?.linkman ?? '');
    final telCtrl = TextEditingController(text: item?.tel ?? '');
    final addressCtrl = TextEditingController(text: item?.address ?? '');
    final memoCtrl = TextEditingController(text: item?.memo ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? '新建供应商' : '编辑供应商'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '供应商编码')),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '供应商名称')),
                const SizedBox(height: 12),
                TextField(controller: linkmanCtrl, decoration: const InputDecoration(labelText: '联系人')),
                const SizedBox(height: 12),
                TextField(controller: telCtrl, decoration: const InputDecoration(labelText: '联系电话')),
                const SizedBox(height: 12),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: '联系地址')),
                const SizedBox(height: 12),
                TextField(controller: memoCtrl, decoration: const InputDecoration(labelText: '备注')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final newSupplier = ErpSupplierItem(
                id: item?.id ?? '',
                code: codeCtrl.text.trim(),
                name: nameCtrl.text.trim(),
                linkman: linkmanCtrl.text.trim(),
                tel: telCtrl.text.trim(),
                address: addressCtrl.text.trim(),
                memo: memoCtrl.text.trim(),
                status: item?.status ?? 1,
              );
              Navigator.pop(ctx);
              await widget.loader.saveSupplier(newSupplier);
              unawaited(_loadData());
            },
            child: const Text('保存'),
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
              Text('供应商管理', style: Theme.of(context).textTheme.headlineSmall),
              FilledButton.icon(
                onPressed: () => _openSupplierDialog(),
                icon: const Icon(Icons.add),
                label: const Text('新建供应商'),
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
                          DataColumn(label: Text('编码')),
                          DataColumn(label: Text('名称')),
                          DataColumn(label: Text('联系人')),
                          DataColumn(label: Text('电话')),
                          DataColumn(label: Text('地址')),
                          DataColumn(label: Text('状态')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: [
                          for (var i = 0; i < _suppliers.length; i++)
                            DataRow(cells: [
                              DataCell(Text('${i + 1}')),
                              DataCell(Text(_suppliers[i].code)),
                              DataCell(Text(_suppliers[i].name)),
                              DataCell(Text(_suppliers[i].linkman)),
                              DataCell(Text(_suppliers[i].tel)),
                              DataCell(Text(_suppliers[i].address)),
                              DataCell(Text(_suppliers[i].isValid ? '正常' : '停用',
                                  style: TextStyle(color: _suppliers[i].isValid ? Colors.green : Colors.grey))),
                              DataCell(Row(
                                children: [
                                  TextButton(onPressed: () => _openSupplierDialog(_suppliers[i]), child: const Text('编辑')),
                                  TextButton(
                                    onPressed: () async {
                                      await widget.loader.toggleSupplierStatus(_suppliers[i].id, !_suppliers[i].isValid);
                                      unawaited(_loadData());
                                    },
                                    child: Text(_suppliers[i].isValid ? '停用' : '启用'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await widget.loader.deleteSupplier(_suppliers[i].id);
                                      unawaited(_loadData());
                                    },
                                    child: const Text('删除', style: TextStyle(color: Colors.red)),
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
