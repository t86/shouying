import 'dart:async';

import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_models.dart';
import 'package:card_table/src/bms_sms_cooldown.dart';
import 'package:flutter/material.dart';

// =============================================================================
// S7.P7.T01 存酒设置视图
// =============================================================================

class BmsSaveConfigView extends StatefulWidget {
  const BmsSaveConfigView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsSaveConfigView> createState() => _BmsSaveConfigViewState();
}

class _BmsSaveConfigViewState extends State<BmsSaveConfigView> {
  final _defaultDaysCtrl = TextEditingController(text: '30');
  final _maxDaysCtrl = TextEditingController(text: '90');
  bool _allowBorrow = true;
  bool _smsNotify = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _defaultDaysCtrl.dispose();
    _maxDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadWineConfig();
    if (mounted) {
      if (res.failureOrNull == null) {
        final cfg = res.valueOrNull ?? const BmsWineConfig();
        _defaultDaysCtrl.text = cfg.defaultExpiredDays.toString();
        _maxDaysCtrl.text = cfg.maxSaveDays.toString();
        _allowBorrow = cfg.isAllowBorrow;
        _smsNotify = cfg.isSmsNotify;
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _saveConfig() async {
    await widget.loader.saveWineConfig({
      'default_expired_days': int.tryParse(_defaultDaysCtrl.text) ?? 30,
      'max_save_days': int.tryParse(_maxDaysCtrl.text) ?? 90,
      'is_allow_borrow': _allowBorrow,
      'is_sms_notify': _smsNotify,
    });
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('存酒设置已保存')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('存酒设置')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    TextField(
                      controller: _defaultDaysCtrl,
                      decoration: const InputDecoration(
                        labelText: '默认存酒保质期 (天)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _maxDaysCtrl,
                      decoration: const InputDecoration(
                        labelText: '最长延期天数 (天)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('允许员工借酒操作'),
                      value: _allowBorrow,
                      onChanged: (v) => setState(() => _allowBorrow = v),
                    ),
                    SwitchListTile(
                      title: const Text('开启存取酒短信通知'),
                      value: _smsNotify,
                      onChanged: (v) => setState(() => _smsNotify = v),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      key: const Key('bms-wine-cfg-save-btn'),
                      onPressed: _saveConfig,
                      child: const Text('保存存酒设置'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// =============================================================================
// S7.P7.T02 可存酒水增删改视图
// =============================================================================

class BmsWineInfoView extends StatefulWidget {
  const BmsWineInfoView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsWineInfoView> createState() => _BmsWineInfoViewState();
}

class _BmsWineInfoViewState extends State<BmsWineInfoView> {
  List<BmsWineItem> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadWinePrdItems();
    if (mounted) {
      setState(() {
        _loading = false;
        _items = res.valueOrNull ?? [];
      });
    }
  }

  void _openAddWinePrd() {
    final prdNameCtrl = TextEditingController();
    final daysCtrl = TextEditingController(text: '30');
    bool isAllowPart = false;

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
            children: [
              const Text(
                '新增可存酒水',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: prdNameCtrl,
                decoration: const InputDecoration(labelText: '酒水商品名称'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: daysCtrl,
                decoration: const InputDecoration(labelText: '保质天数'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('允许存半瓶/散瓶'),
                value: isAllowPart,
                onChanged: (v) => setModalState(() => isAllowPart = v ?? false),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (prdNameCtrl.text.trim().isEmpty) return;
                      await widget.loader.saveWinePrd({
                        'prd_name': prdNameCtrl.text.trim(),
                        'expired_days': int.tryParse(daysCtrl.text) ?? 30,
                        'is_allow_part': isAllowPart ? 1 : 0,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('可存酒水'),
        actions: [
          IconButton(
            key: const Key('bms-wine-prd-add-btn'),
            icon: const Icon(Icons.add),
            onPressed: _openAddWinePrd,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('暂无可存酒水商品'))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final item = _items[idx];
                return ListTile(
                  key: Key('bms-wine-prd-${item.id}'),
                  title: Text(item.prdName),
                  subtitle: Text(
                    '过期期限: ${item.expiredDays} 天 | ${item.isAllowPart ? "允许散存" : "仅整瓶"}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () async {
                      await widget.loader.deleteWinePrd(item.id);
                      _loadData();
                    },
                  ),
                );
              },
            ),
    );
  }
}

// =============================================================================
// S7.P7.T03 抽成管理视图
// =============================================================================

class BmsCutPrdView extends StatefulWidget {
  const BmsCutPrdView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsCutPrdView> createState() => _BmsCutPrdViewState();
}

class _BmsCutPrdViewState extends State<BmsCutPrdView> {
  List<BmsCutPrdItem> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadCutPrds();
    if (mounted) {
      setState(() {
        _loading = false;
        _items = res.valueOrNull ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('抽成管理')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('暂无商品提成配置'))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final item = _items[idx];
                return ListTile(
                  key: Key('bms-cut-prd-${item.id}'),
                  title: Text(item.prdName),
                  subtitle: Text(
                    '岗位: ${item.stationName} | 提成: ${item.cutType == 1 ? "${item.cutValue}%" : "¥${item.cutValue}/份"}',
                  ),
                );
              },
            ),
    );
  }
}

// =============================================================================
// S7.P7.T04 短信账户视图
// =============================================================================

class BmsAccountInfoView extends StatefulWidget {
  const BmsAccountInfoView({
    super.key,
    required this.loader,
    this.readCooldown = readSmsSelfCheckTime,
    this.writeCooldown = writeSmsSelfCheckTime,
    this.clock = DateTime.now,
  });
  final BmsLoader loader;
  final Future<DateTime?> Function() readCooldown;
  final Future<void> Function(DateTime) writeCooldown;
  final DateTime Function() clock;

  @override
  State<BmsAccountInfoView> createState() => _BmsAccountInfoViewState();
}

class _BmsAccountInfoViewState extends State<BmsAccountInfoView> {
  BmsSmsAccountInfo _account = const BmsSmsAccountInfo();
  bool _loading = false;
  String? _error;
  final _mobile = TextEditingController();
  Timer? _timer;
  DateTime? _sentAt;
  int _seconds = 0;
  bool _sending = false, _cooldownReady = false;
  String? _sendMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
    unawaited(_restoreCooldown());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _restoreCooldown() async {
    try {
      final sentAt = await widget.readCooldown();
      if (!mounted) return;
      _sentAt = sentAt;
      _cooldownReady = true;
      _sendMessage = null;
      _startTimer();
    } on Object {
      if (mounted) setState(() => _sendMessage = '无法读取发送间隔，请刷新后重试');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    void tick() {
      if (!mounted) return;
      final remaining = _sentAt == null
          ? 0
          : 60 - widget.clock().difference(_sentAt!).inSeconds;
      setState(() => _seconds = remaining.clamp(0, 60));
      if (_seconds == 0) _timer?.cancel();
    }

    tick();
    if (_seconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
  }

  Future<void> _sendSelfCheck() async {
    if (_sending || !_cooldownReady || _seconds > 0) return;
    final mobile = _mobile.text.trim();
    if (!RegExp(r'^\d{11}$').hasMatch(mobile)) {
      setState(() => _sendMessage = '请输入11位手机号');
      return;
    }
    setState(() {
      _sending = true;
      _sendMessage = null;
    });
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('发送自查短信'),
        content: Text('将向 $mobile 发送一条真实自查短信，可能产生短信费用。确认发送？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认发送'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _sending = false);
      return;
    }
    try {
      final result = await widget.loader.sendSmsSelfCheck(mobile);
      if (result.failureOrNull case final failure?) {
        if (mounted) {
          setState(() => _sendMessage = '发送失败：${failure.safeMessage}');
        }
      } else {
        final sentAt = widget.clock();
        _sentAt = sentAt;
        String message = '发送成功';
        try {
          await widget.writeCooldown(sentAt);
        } on Object {
          message = '发送成功；间隔记录保存失败，请勿重新启动后重复发送';
        }
        if (mounted) {
          setState(() => _sendMessage = message);
          _startTimer();
        }
      }
    } on Object {
      if (mounted) setState(() => _sendMessage = '发送失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadSmsAccount();
    if (mounted) {
      setState(() {
        _loading = false;
        _error = res.failureOrNull?.safeMessage;
        _account = res.valueOrNull ?? const BmsSmsAccountInfo();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('短信账户'),
        actions: [
          IconButton(
            onPressed: _loading || _sending
                ? null
                : () {
                    unawaited(_loadData());
                    if (!_cooldownReady) unawaited(_restoreCooldown());
                  },
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sms, size: 48, color: Colors.blue),
                          const SizedBox(height: 16),
                          Text('客户名称：${_account.customerName}'),
                          Text('账户余额：${_account.moneyBalance}'),
                          Text(
                            '剩余短信条数：${_account.balance}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('最近充值金额：${_account.lastRecharge}'),
                          Text('最近充值日期：${_account.lastRechargeDate}'),
                          const SizedBox(height: 8),
                          Text('当前状态：${_account.state}'),
                          Text('开通状态：${_account.openState}'),
                          const SizedBox(height: 16),
                          TextField(
                            key: const Key('bms-sms-self-check-mobile'),
                            controller: _mobile,
                            keyboardType: TextInputType.phone,
                            enabled: !_sending,
                            decoration: const InputDecoration(
                              labelText: '自查手机号',
                            ),
                          ),
                          FilledButton(
                            key: const Key('bms-sms-self-check-send'),
                            onPressed:
                                _sending || !_cooldownReady || _seconds > 0
                                ? null
                                : _sendSelfCheck,
                            child: Text(
                              _sending
                                  ? '发送中…'
                                  : _seconds > 0
                                  ? '$_seconds秒后发送'
                                  : '发送短信',
                            ),
                          ),
                          if (_sendMessage != null) Text(_sendMessage!),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// =============================================================================
// S7.P7.T05 短信明细视图
// =============================================================================

class BmsMessageDetailView extends StatefulWidget {
  const BmsMessageDetailView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsMessageDetailView> createState() => _BmsMessageDetailViewState();
}

class _BmsMessageDetailViewState extends State<BmsMessageDetailView> {
  List<BmsSmsBill> _records = [];
  bool _loading = false;
  String? _error;
  int _page = 1, _total = 0, _type = 0;
  late DateTime _start, _end;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month, now.day);
    _page = 1;
    _type = 0;
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadSmsBills(
      startDay: _smsDay(_start),
      endDay: _smsDay(_end),
      type: _type,
      page: _page,
    );
    if (mounted) {
      setState(() {
        _loading = false;
        _error = res.failureOrNull?.safeMessage;
        _records = res.valueOrNull?.records ?? [];
        _total = res.valueOrNull?.total ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('短信明细')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            initialDateRange: DateTimeRange(
                              start: _start,
                              end: _end,
                            ),
                          );
                          if (range != null && mounted) {
                            setState(() {
                              _start = range.start;
                              _end = range.end;
                            });
                          }
                        },
                  child: Text('${_smsDay(_start)} 至 ${_smsDay(_end)}'),
                ),
                DropdownButton<int>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('全部')),
                    DropdownMenuItem(value: 1, child: Text('充值')),
                    DropdownMenuItem(value: 2, child: Text('消费')),
                  ],
                  onChanged: _loading
                      ? null
                      : (v) => setState(() => _type = v!),
                ),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          _page = 1;
                          unawaited(_loadData());
                        },
                  child: const Text('查询'),
                ),
                TextButton(
                  onPressed: _loading ? null : _reset,
                  child: const Text('重置'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : _records.isEmpty
                ? const Center(child: Text('暂无短信发送明细'))
                : ListView.separated(
                    itemCount: _records.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final r = _records[idx];
                      return ListTile(
                        key: Key('bms-sms-bill-${r.id}'),
                        title: Text('${r.date} · ${r.type}'),
                        subtitle: Text(
                          '金额：${r.amount} · 短信数量：${r.count}\n剩余金额：${r.balance} · 剩余短信：${r.remaining}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            settings: const RouteSettings(
                              name: 'management-child',
                            ),
                            builder: (_) => _SmsRecordDetailView(
                              loader: widget.loader,
                              bill: r,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          _smsPagination(_page, _total, _loading, (page) {
            _page = page;
            unawaited(_loadData());
          }),
        ],
      ),
    );
  }
}

// =============================================================================
// S7.P7.T06 短信结果查询视图
// =============================================================================

class BmsMessageResultView extends StatefulWidget {
  const BmsMessageResultView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsMessageResultView> createState() => _BmsMessageResultState();
}

class _BmsMessageResultState extends State<BmsMessageResultView> {
  final _mobile = TextEditingController();
  bool _loading = false, _queried = false;
  String? _error;
  List<BmsSmsRecord> _records = [];
  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _query() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.loader.loadSmsMobileResults(
      mobile: _mobile.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _queried = true;
      _error = result.failureOrNull?.safeMessage;
      _records = result.valueOrNull?.records ?? [];
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('短信结果查询')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: '手机号'),
                  onSubmitted: (_) {
                    if (!_loading) unawaited(_query());
                  },
                ),
              ),
              TextButton(
                onPressed: _loading ? null : _query,
                child: const Text('查询'),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                        _mobile.clear();
                        _records = [];
                        _queried = false;
                        _error = null;
                      }),
                child: const Text('重置'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : !_queried
              ? const Center(child: Text('输入手机号后查询发送结果'))
              : _smsRecords(_records),
        ),
      ],
    ),
  );
}

class _SmsRecordDetailView extends StatefulWidget {
  const _SmsRecordDetailView({required this.loader, required this.bill});
  final BmsLoader loader;
  final BmsSmsBill bill;
  @override
  State<_SmsRecordDetailView> createState() => _SmsRecordDetailState();
}

class _SmsRecordDetailState extends State<_SmsRecordDetailView> {
  final _mobile = TextEditingController();
  int _page = 1, _total = 0, _status = 0;
  bool _loading = false, _initialized = false;
  String? _error;
  List<Map<String, Object?>> _templates = [];
  List<BmsSmsRecord> _records = [];
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.loader.loadSmsRecordDetails(
      recordId: widget.bill.id,
      status: _status,
      mobile: _mobile.text.trim(),
      page: _page,
      initialize: !_initialized,
      templates: _templates,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = result.failureOrNull?.safeMessage;
      _records = result.valueOrNull?.records ?? [];
      _total = result.valueOrNull?.total ?? 0;
      if (result.valueOrNull case final data?) {
        _templates = data.templates;
        _initialized = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.bill.date} 短信明细')),
    body: Column(
      children: [
        Text('成功：${widget.bill.count} 条 · 失败：${widget.bill.failed} 条'),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              DropdownButton<int>(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('全部')),
                  DropdownMenuItem(value: 1, child: Text('成功')),
                  DropdownMenuItem(value: 2, child: Text('失败')),
                ],
                onChanged: _loading
                    ? null
                    : (v) => setState(() => _status = v!),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _mobile,
                  decoration: const InputDecoration(labelText: '手机号码（模糊查询）'),
                ),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        _page = 1;
                        unawaited(_load());
                      },
                child: const Text('查询'),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        _mobile.clear();
                        _status = 0;
                        _page = 1;
                        unawaited(_load());
                      },
                child: const Text('重置'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : _smsRecords(_records),
        ),
        _smsPagination(_page, _total, _loading, (page) {
          _page = page;
          unawaited(_load());
        }),
      ],
    ),
  );
}

String _smsDay(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
Widget _smsPagination(
  int page,
  int total,
  bool loading,
  void Function(int) change,
) => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    TextButton(
      onPressed: loading || page <= 1 ? null : () => change(page - 1),
      child: const Text('上一页'),
    ),
    Text('第 $page 页，共 $total 条'),
    TextButton(
      onPressed: loading || page * 20 >= total ? null : () => change(page + 1),
      child: const Text('下一页'),
    ),
  ],
);
Widget _smsRecords(List<BmsSmsRecord> records) => records.isEmpty
    ? const Center(child: Text('暂无短信记录'))
    : ListView.separated(
        itemCount: records.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final item = records[index];
          return ListTile(
            title: Text('${item.phone} · ${item.typeName}'),
            subtitle: Text(
              '${item.content}\n字数/条数：${item.content.length}/${item.count}\n发送：${item.sendTime} · 接收：${item.receiveTime}\n状态：${item.state}${item.failReason.isEmpty ? '' : ' · 失败原因：${item.failReason}'}',
            ),
          );
        },
      );
