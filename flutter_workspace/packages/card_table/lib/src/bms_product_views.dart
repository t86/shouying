import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_models.dart';
import 'package:flutter/material.dart';
export 'package:card_table/src/bms_product_image_view.dart';

// =============================================================================
// S7.P2.T01 ~ T04 商品管理主视图
// =============================================================================

class BmsPrdConfigView extends StatefulWidget {
  const BmsPrdConfigView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsPrdConfigView> createState() => _BmsPrdConfigViewState();
}

class _BmsPrdConfigViewState extends State<BmsPrdConfigView> {
  List<BmsOneCateItem> _oneCates = [];
  List<BmsTwoCateItem> _twoCates = [];
  List<BmsProductItem> _products = [];
  String? _selectedOneCateId;
  String? _selectedTwoCateId;
  bool _loading = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCates();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCates() async {
    setState(() => _loading = true);
    final oneRes = await widget.loader.loadOneCates();
    final twoRes = await widget.loader.loadTwoCates();
    if (mounted) {
      setState(() {
        _oneCates = oneRes.valueOrNull ?? [];
        _twoCates = twoRes.valueOrNull ?? [];
        if (_selectedOneCateId == null && _oneCates.isNotEmpty) {
          _selectedOneCateId = _oneCates.first.id;
        }
      });
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadProducts(
      oneCateId: _selectedOneCateId ?? '',
      twoCateId: _selectedTwoCateId ?? '',
      keyword: _searchCtrl.text.trim(),
    );
    if (mounted) {
      setState(() {
        _loading = false;
        _products = res.valueOrNull ?? [];
      });
    }
  }

  Future<void> _togglePrdStatus(BmsProductItem prd) async {
    await widget.loader.setProductStatus(prd.id, !prd.isValid);
    _loadProducts();
  }

  void _openProductForm([BmsProductItem? prd]) {
    final nameCtrl = TextEditingController(text: prd?.name ?? '');
    final codeCtrl = TextEditingController(text: prd?.code ?? '');
    final priceCtrl = TextEditingController(text: prd != null ? prd.price.toString() : '0.0');
    final vipPriceCtrl = TextEditingController(text: prd != null ? prd.vipPrice.toString() : '0.0');
    final unitCtrl = TextEditingController(text: prd?.unit ?? '份');
    bool isPackage = prd?.isPackage ?? false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prd == null ? '新建商品' : '编辑商品', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '商品名称')),
              const SizedBox(height: 12),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '商品编码')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: '售价'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: vipPriceCtrl, decoration: const InputDecoration(labelText: '会员价'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: '单位')),
              CheckboxListTile(
                title: const Text('是否套餐商品'),
                value: isPackage,
                onChanged: (v) => setModalState(() => isPackage = v ?? false),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      await widget.loader.saveProduct({
                        if (prd != null) 'id': prd.id,
                        'name': nameCtrl.text.trim(),
                        'code': codeCtrl.text.trim(),
                        'price': double.tryParse(priceCtrl.text) ?? 0.0,
                        'vip_price': double.tryParse(vipPriceCtrl.text) ?? 0.0,
                        'unit': unitCtrl.text.trim(),
                        'is_package': isPackage ? 1 : 0,
                        'ocate_id': _selectedOneCateId ?? '',
                        'tcate_id': _selectedTwoCateId ?? '',
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadProducts();
                    },
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTwoCates = _selectedOneCateId == null
        ? _twoCates
        : _twoCates.where((c) => c.oneCateId == _selectedOneCateId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('商品管理'),
        actions: [
          IconButton(
            key: const Key('bms-prd-add-btn'),
            icon: const Icon(Icons.add),
            onPressed: () => _openProductForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 一级分类标签栏
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _oneCates.length,
              itemBuilder: (ctx, idx) {
                final cate = _oneCates[idx];
                final isSelected = cate.id == _selectedOneCateId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    key: Key('bms-one-cate-${cate.id}'),
                    label: Text(cate.name),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedOneCateId = cate.id;
                        _selectedTwoCateId = null;
                      });
                      _loadProducts();
                    },
                  ),
                );
              },
            ),
          ),
          // 二级分类标签栏
          if (filteredTwoCates.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: filteredTwoCates.length + 1,
                itemBuilder: (ctx, idx) {
                  if (idx == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('全部二级'),
                        selected: _selectedTwoCateId == null,
                        onSelected: (_) {
                          setState(() => _selectedTwoCateId = null);
                          _loadProducts();
                        },
                      ),
                    );
                  }
                  final twoCate = filteredTwoCates[idx - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(twoCate.name),
                      selected: twoCate.id == _selectedTwoCateId,
                      onSelected: (_) {
                        setState(() => _selectedTwoCateId = twoCate.id);
                        _loadProducts();
                      },
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: '搜索商品名称/编码',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _loadProducts(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _loadProducts, child: const Text('查询')),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('暂无商品数据'))
                    : ListView.separated(
                        itemCount: _products.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final p = _products[idx];
                          return ListTile(
                            key: Key('bms-prd-item-${p.id}'),
                            title: Text('${p.name} (${p.code})'),
                            subtitle: Text('售价: ¥${p.price} | 会员价: ¥${p.vipPrice} | 单位: ${p.unit}${p.isPackage ? ' [套餐]' : ''}'),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                Switch(
                                  value: p.isValid,
                                  onChanged: (_) => _togglePrdStatus(p),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _openProductForm(p),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () async {
                                    await widget.loader.deleteProduct(p.id);
                                    _loadProducts();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// S7.P2.T05 批量上传商品图片视图
// =============================================================================

// =============================================================================
// S7.P2.T06 套餐可选组模板视图
// =============================================================================

class BmsTaocanTemplateView extends StatefulWidget {
  const BmsTaocanTemplateView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsTaocanTemplateView> createState() => _BmsTaocanTemplateViewState();
}

class _BmsTaocanTemplateViewState extends State<BmsTaocanTemplateView> {
  List<BmsPackageGroupTemplate> _templates = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadTaocanTemplates();
    if (mounted) {
      setState(() {
        _loading = false;
        _templates = res.valueOrNull ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('套餐可选组模板')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? const Center(child: Text('暂无套餐可选组模板'))
              : ListView.separated(
                  itemCount: _templates.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final item = _templates[idx];
                    return ListTile(
                      key: Key('bms-taocan-tpl-${item.id}'),
                      title: Text(item.name),
                      subtitle: Text('可选数量: ${item.minSelect} ~ ${item.maxSelect} 项 | 商品数: ${item.items.length}'),
                    );
                  },
                ),
    );
  }
}
