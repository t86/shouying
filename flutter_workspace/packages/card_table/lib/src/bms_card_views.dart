import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_models.dart';
import 'package:flutter/material.dart';

// =============================================================================
// S7.P3.T01 ~ T02 卡台管理主视图
// =============================================================================

class BmsCardConfigView extends StatefulWidget {
  const BmsCardConfigView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsCardConfigView> createState() => _BmsCardConfigViewState();
}

class _BmsCardConfigViewState extends State<BmsCardConfigView> {
  List<BmsRegionItem> _regions = [];
  List<BmsCardItem> _seats = [];
  String? _selectedRegionId;
  bool _loading = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadRegions();
    if (mounted) {
      setState(() {
        _regions = res.valueOrNull ?? [];
        if (_selectedRegionId == null && _regions.isNotEmpty) {
          _selectedRegionId = _regions.first.id;
        }
      });
      _loadSeats();
    }
  }

  Future<void> _loadSeats() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadSeats(
      regionId: _selectedRegionId ?? '',
      keyword: _searchCtrl.text.trim(),
    );
    if (mounted) {
      setState(() {
        _loading = false;
        _seats = res.valueOrNull ?? [];
      });
    }
  }

  void _openSeatForm([BmsCardItem? seat]) {
    final nameCtrl = TextEditingController(text: seat?.name ?? '');
    final chargeCtrl = TextEditingController(text: seat != null ? seat.minCharge.toString() : '0.0');
    final seatNumCtrl = TextEditingController(text: seat != null ? seat.seatNum.toString() : '4');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
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
            Text(seat == null ? '新建卡台' : '编辑卡台', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '卡台名称/桌号')),
            const SizedBox(height: 12),
            TextField(controller: chargeCtrl, decoration: const InputDecoration(labelText: '最低消费 (¥)'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: seatNumCtrl, decoration: const InputDecoration(labelText: '容纳人数'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await widget.loader.saveSeat({
                      if (seat != null) 'id': seat.id,
                      'name': nameCtrl.text.trim(),
                      'region_id': _selectedRegionId ?? '',
                      'min_charge': double.tryParse(chargeCtrl.text) ?? 0.0,
                      'seat_num': int.tryParse(seatNumCtrl.text) ?? 4,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadSeats();
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
        title: const Text('卡台管理'),
        actions: [
          IconButton(
            key: const Key('bms-seat-add-btn'),
            icon: const Icon(Icons.add),
            onPressed: () => _openSeatForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 区域选择标签栏
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _regions.length,
              itemBuilder: (ctx, idx) {
                final r = _regions[idx];
                final isSelected = r.id == _selectedRegionId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    key: Key('bms-region-${r.id}'),
                    label: Text(r.name),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedRegionId = r.id);
                      _loadSeats();
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
                      hintText: '搜索卡台名称',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _loadSeats(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _loadSeats, child: const Text('查询')),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _seats.isEmpty
                    ? const Center(child: Text('暂无卡台数据'))
                    : ListView.separated(
                        itemCount: _seats.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final seat = _seats[idx];
                          return ListTile(
                            key: Key('bms-seat-item-${seat.id}'),
                            title: Text(seat.name),
                            subtitle: Text('低消: ¥${seat.minCharge} | 容纳: ${seat.seatNum}人 | 区域: ${seat.regionName}'),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.qr_code, size: 20),
                                  tooltip: '查看二维码',
                                  onPressed: () {
                                    showDialog<void>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text('卡台二维码 - ${seat.name}'),
                                        content: const Icon(Icons.qr_code_2, size: 160),
                                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭'))],
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _openSeatForm(seat),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () async {
                                    await widget.loader.deleteSeat(seat.id);
                                    _loadSeats();
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
// S7.P3.T03 卡台抵消组视图
// =============================================================================

class BmsCardMinGroupView extends StatefulWidget {
  const BmsCardMinGroupView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsCardMinGroupView> createState() => _BmsCardMinGroupViewState();
}

class _BmsCardMinGroupViewState extends State<BmsCardMinGroupView> {
  List<BmsCardMinGroupItem> _groups = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadCardMinGroups();
    if (mounted) {
      setState(() {
        _loading = false;
        _groups = res.valueOrNull ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('卡台抵消组')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const Center(child: Text('暂无低消组配置'))
              : ListView.separated(
                  itemCount: _groups.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final item = _groups[idx];
                    return ListTile(
                      key: Key('bms-seat-grp-${item.id}'),
                      title: Text(item.name),
                      subtitle: Text('基准最低消费: ¥${item.minCharge} | 关联卡台数: ${item.cardIds.length}'),
                    );
                  },
                ),
    );
  }
}

// =============================================================================
// S7.P3.T04 卡台标签视图
// =============================================================================

class BmsCardTipsView extends StatefulWidget {
  const BmsCardTipsView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsCardTipsView> createState() => _BmsCardTipsViewState();
}

class _BmsCardTipsViewState extends State<BmsCardTipsView> {
  List<BmsCardTipItem> _tips = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadCardTips();
    if (mounted) {
      setState(() {
        _loading = false;
        _tips = res.valueOrNull ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('卡台标签')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tips.isEmpty
              ? const Center(child: Text('暂无标签配置'))
              : ListView.separated(
                  itemCount: _tips.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final tip = _tips[idx];
                    return ListTile(
                      key: Key('bms-card-tip-${tip.id}'),
                      leading: CircleAvatar(backgroundColor: Colors.blue, radius: 12),
                      title: Text(tip.name),
                    );
                  },
                ),
    );
  }
}

// =============================================================================
// S7.P3.T05 计抵达规则视图
// =============================================================================

class BmsArriveRulesView extends StatefulWidget {
  const BmsArriveRulesView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsArriveRulesView> createState() => _BmsArriveRulesViewState();
}

class _BmsArriveRulesViewState extends State<BmsArriveRulesView> {
  List<BmsArriveRuleItem> _rules = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadArriveRules();
    if (mounted) {
      setState(() {
        _loading = false;
        _rules = res.valueOrNull ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('计抵达规则')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? const Center(child: Text('暂无抵达规则'))
              : ListView.separated(
                  itemCount: _rules.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final r = _rules[idx];
                    return ListTile(
                      key: Key('bms-arrive-rule-${r.id}'),
                      title: Text(r.name),
                      subtitle: Text('抵达阈值: ${r.arriveMin}分钟 | 计算系数: ${r.arriveRatio}'),
                    );
                  },
                ),
    );
  }
}
