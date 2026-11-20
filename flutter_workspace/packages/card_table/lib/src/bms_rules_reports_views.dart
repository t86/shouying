import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_models.dart';
import 'package:flutter/material.dart';

export 'package:card_table/src/bms_report_selection_views.dart';
export 'package:card_table/src/bms_statistics_configuration_views.dart';
export 'package:card_table/src/bms_high_margin_configuration_view.dart';

// =============================================================================
// S7.P6.T06 要求类型与要求项视图
// =============================================================================

class BmsRequireConfigView extends StatefulWidget {
  const BmsRequireConfigView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsRequireConfigView> createState() => _BmsRequireConfigViewState();
}

class _BmsRequireConfigViewState extends State<BmsRequireConfigView> {
  List<BmsRequireItem> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRequires();
  }

  Future<void> _loadRequires() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadRequires();
    if (mounted) {
      setState(() {
        _loading = false;
        _items = res.valueOrNull ?? [];
      });
    }
  }

  void _openRequireForm([BmsRequireItem? item]) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final priceCtrl = TextEditingController(text: item != null ? item.price.toString() : '0.0');

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item == null ? '新建要求项' : '编辑要求项', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '要求名称 (如: 加冰、微辣)')),
            const SizedBox(height: 12),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: '加价金额 (¥)'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await widget.loader.saveRequireItem({
                      if (item != null) 'id': item.id,
                      'name': nameCtrl.text.trim(),
                      'price': double.tryParse(priceCtrl.text) ?? 0.0,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadRequires();
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
        title: const Text('要求管理'),
        actions: [
          IconButton(
            key: const Key('bms-require-add-btn'),
            icon: const Icon(Icons.add),
            onPressed: () => _openRequireForm(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('暂无定制要求'))
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final item = _items[idx];
                    return ListTile(
                      key: Key('bms-require-item-${item.id}'),
                      title: Text(item.name),
                      subtitle: Text('加价: ¥${item.price} | 分类: ${item.typeName.isEmpty ? "通用" : item.typeName}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _openRequireForm(item),
                      ),
                    );
                  },
                ),
    );
  }
}

// =============================================================================
// S7.P6.T07 通用理由管理视图（4合1：优惠/退单/退卡/取消优惠）
// =============================================================================

class BmsReasonView extends StatefulWidget {
  const BmsReasonView({
    super.key,
    required this.loader,
    required this.reasonType,
    required this.title,
  });

  final BmsLoader loader;
  final String reasonType; // YH, back, backVip, QXYH
  final String title;

  @override
  State<BmsReasonView> createState() => _BmsReasonViewState();
}

class _BmsReasonViewState extends State<BmsReasonView> {
  List<BmsReasonItem> _reasons = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  @override
  void didUpdateWidget(covariant BmsReasonView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reasonType != widget.reasonType) {
      _loadReasons();
    }
  }

  Future<void> _loadReasons() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadReasons(widget.reasonType);
    if (mounted) {
      setState(() {
        _loading = false;
        _reasons = res.valueOrNull ?? [];
      });
    }
  }

  void _openReasonForm([BmsReasonItem? item]) {
    final textCtrl = TextEditingController(text: item?.reasonText ?? '');

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item == null ? '新建理由' : '编辑理由', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: textCtrl, decoration: const InputDecoration(labelText: '理由说明')),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (textCtrl.text.trim().isEmpty) return;
                    await widget.loader.saveReason({
                      if (item != null) 'id': item.id,
                      'reason_type': widget.reasonType,
                      'reason_text': textCtrl.text.trim(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadReasons();
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
        title: Text(widget.title),
        actions: [
          IconButton(
            key: const Key('bms-reason-add-btn'),
            icon: const Icon(Icons.add),
            onPressed: () => _openReasonForm(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reasons.isEmpty
              ? const Center(child: Text('暂无配置理由'))
              : ListView.separated(
                  itemCount: _reasons.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final item = _reasons[idx];
                    return ListTile(
                      key: Key('bms-reason-item-${item.id}'),
                      title: Text(item.reasonText),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _openReasonForm(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () async {
                              await widget.loader.deleteReason(item.id);
                              _loadReasons();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// =============================================================================
// S7.P6.T08 终端规则配置视图
// =============================================================================

class BmsTerminalRulesView extends StatefulWidget {
  const BmsTerminalRulesView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsTerminalRulesView> createState() => _BmsTerminalRulesViewState();
}

class _BmsTerminalRulesViewState extends State<BmsTerminalRulesView> {
  final _lockMinutesCtrl = TextEditingController(text: '15');
  final _timeoutCtrl = TextEditingController(text: '60');
  final _copiesCtrl = TextEditingController(text: '1');
  bool _antiCheckout = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  @override
  void dispose() {
    _lockMinutesCtrl.dispose();
    _timeoutCtrl.dispose();
    _copiesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRules() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadTerminalRules();
    if (mounted) {
      if (res.failureOrNull == null) {
        final cfg = res.valueOrNull ?? const BmsTerminalRuleConfig();
        _lockMinutesCtrl.text = cfg.autoLockMinutes.toString();
        _timeoutCtrl.text = cfg.scanPayTimeout.toString();
        _copiesCtrl.text = cfg.printBillCopies.toString();
        _antiCheckout = cfg.enableAntiCheckout;
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _saveRules() async {
    await widget.loader.saveTerminalRules({
      'auto_lock_minutes': int.tryParse(_lockMinutesCtrl.text) ?? 15,
      'scan_pay_timeout': int.tryParse(_timeoutCtrl.text) ?? 60,
      'print_bill_copies': int.tryParse(_copiesCtrl.text) ?? 1,
      'enable_anti_checkout': _antiCheckout,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('终端规则已保存')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('规则配置')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    TextField(controller: _lockMinutesCtrl, decoration: const InputDecoration(labelText: '终端无操作自动锁屏时间 (分钟)'), keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    TextField(controller: _timeoutCtrl, decoration: const InputDecoration(labelText: '扫码支付超时时间 (秒)'), keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    TextField(controller: _copiesCtrl, decoration: const InputDecoration(labelText: '小票默认打印联数'), keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('允许反结账操作'),
                      value: _antiCheckout,
                      onChanged: (v) => setState(() => _antiCheckout = v),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      key: const Key('bms-term-rules-save-btn'),
                      onPressed: _saveRules,
                      child: const Text('保存规则配置'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// =============================================================================
// S7.P6.T09 会员卡规则视图
// =============================================================================

class BmsVipRulesView extends StatefulWidget {
  const BmsVipRulesView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsVipRulesView> createState() => _BmsVipRulesViewState();
}

class _BmsVipRulesViewState extends State<BmsVipRulesView> {
  final _minRechargeCtrl = TextEditingController(text: '100');
  final _discountCtrl = TextEditingController(text: '0.9');
  final _scoreRatioCtrl = TextEditingController(text: '1.0');
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  @override
  void dispose() {
    _minRechargeCtrl.dispose();
    _discountCtrl.dispose();
    _scoreRatioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRules() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadVipRules();
    if (mounted) {
      if (res.failureOrNull == null) {
        final cfg = res.valueOrNull ?? const BmsVipRuleConfig();
        _minRechargeCtrl.text = cfg.rechargeMin.toString();
        _discountCtrl.text = cfg.discountRate.toString();
        _scoreRatioCtrl.text = cfg.scoreRatio.toString();
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _saveRules() async {
    await widget.loader.saveVipRules({
      'recharge_min': double.tryParse(_minRechargeCtrl.text) ?? 100.0,
      'discount_rate': double.tryParse(_discountCtrl.text) ?? 0.9,
      'score_ratio': double.tryParse(_scoreRatioCtrl.text) ?? 1.0,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('会员卡规则已保存')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('会员卡规则')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    TextField(controller: _minRechargeCtrl, decoration: const InputDecoration(labelText: '起充门槛 (¥)'), keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    TextField(controller: _discountCtrl, decoration: const InputDecoration(labelText: '统一消费折扣系数 (如: 0.9 为九折)'), keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    TextField(controller: _scoreRatioCtrl, decoration: const InputDecoration(labelText: '积分兑换系数 (1元累计积分数)'), keyboardType: TextInputType.number),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      key: const Key('bms-vip-rules-save-btn'),
                      onPressed: _saveRules,
                      child: const Text('保存会员规则'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
