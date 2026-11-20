import 'dart:async';

import 'package:card_table/src/cashier_credit_accounts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:foundation/foundation.dart';

final class CashierCreditAccountsScreen extends StatefulWidget {
  const CashierCreditAccountsScreen({
    required this.loader,
    required this.canOperate,
    super.key,
  });
  final CashierCreditAccountsLoader loader;
  final ValueListenable<bool> canOperate;
  @override
  State<CashierCreditAccountsScreen> createState() => _CreditState();
}

enum _Mode { accounts, edit, logs, repay }

class _CreditState extends State<CashierCreditAccountsScreen> {
  final _keyword = TextEditingController(),
      _name = TextEditingController(),
      _contact = TextEditingController(),
      _phone = TextEditingController();
  final _channelInputs = {
    for (final id in creditRepaymentChannels.keys) id: TextEditingController(),
  };
  List<CashierCreditAccount> _accounts = [];
  List<CashierCreditLog> _logs = [];
  List<CashierCreditOrder> _orders = [];
  final _selected = <String>{}, _selectedOrders = <String>{};
  final _channels = <int>{};
  CashierCreditAccount? _account;
  _Mode _mode = _Mode.accounts;
  int _scope = 0, _request = 0, _logType = 0;
  bool _loading = false, _writing = false, _confirming = false, _closed = false;
  String? _message;
  bool get _allowed => !_closed && widget.canOperate.value;
  bool get _busy => _loading || _writing || _confirming;
  bool get _editable => _allowed && !_busy && !widget.loader.needsVerification;
  bool _current(int scope) =>
      mounted &&
      _allowed &&
      scope == _scope &&
      (ModalRoute.of(context)?.isActive ?? true);
  void _update(VoidCallback change) {
    change();
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    widget.canOperate.addListener(_access);
    unawaited(_loadAccounts());
  }

  void _access() {
    _scope++;
    _request++;
    _update(() {
      _accounts = [];
      _orders = [];
      _logs = [];
      _selected.clear();
      _selectedOrders.clear();
      _channels.clear();
      _mode = _Mode.accounts;
      _loading = false;
      _message = _allowed ? null : '登录、连接或权限已变化，请查询核实';
    });
    if (_allowed) unawaited(_loadAccounts());
  }

  @override
  void didUpdateWidget(CashierCreditAccountsScreen old) {
    super.didUpdateWidget(old);
    if (!identical(old.canOperate, widget.canOperate)) {
      old.canOperate.removeListener(_access);
      widget.canOperate.addListener(_access);
      _access();
    } else if (!identical(old.loader, widget.loader)) {
      _access();
    }
  }

  void _close() {
    _closed = true;
    _scope++;
    _request++;
  }

  @override
  void dispose() {
    _close();
    widget.canOperate.removeListener(_access);
    _keyword.dispose();
    _name.dispose();
    _contact.dispose();
    _phone.dispose();
    for (final c in _channelInputs.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAccounts({bool verify = false}) async {
    if (!_allowed) return;
    final scope = _scope, request = ++_request;
    _update(() {
      _loading = true;
      _message = null;
    });
    try {
      final result = await widget.loader.list(_keyword.text, verify: verify);
      if (!_current(scope) || request != _request) return;
      _update(() {
        _accounts = result.valueOrNull ?? [];
        _selected.clear();
        _message = result.failureOrNull?.safeMessage;
      });
    } on Object {
      if (_current(scope) && request == _request) {
        _update(() => _message = '挂账账户查询失败，请重试');
      }
    } finally {
      if (mounted && request == _request) _update(() => _loading = false);
    }
  }

  void _leave() {
    if (_mode == _Mode.accounts) return;
    _scope++;
    _request++;
    _update(() {
      _mode = _Mode.accounts;
      _message = null;
      _loading = false;
    });
    unawaited(_loadAccounts());
  }

  CashierCreditAccount? _single() {
    final values = _accounts.where((a) => _selected.contains(a.id)).toList();
    if (values.length != 1) {
      _update(() => _message = '请选择一个账户进行操作');
      return null;
    }
    return values.single;
  }

  void _edit([CashierCreditAccount? account]) {
    if (!_editable) return;
    _scope++;
    _account = account;
    _name.text = account?.name ?? '';
    _contact.text = account?.contactName ?? '';
    _phone.text = account?.contactPhone ?? '';
    _update(() {
      _mode = _Mode.edit;
      _message = null;
    });
  }

  Future<void> _perform(
    Future<Result<void>> Function(bool Function()) run,
  ) async {
    if (!_editable) return;
    final scope = _scope;
    bool current() => _current(scope);
    _update(() {
      _writing = true;
      _message = null;
    });
    try {
      final result = await run(current);
      if (!current()) return;
      if (result.failureOrNull case final failure?) {
        _update(() => _message = failure.safeMessage);
        return;
      }
      _scope++;
      _update(() {
        _mode = _Mode.accounts;
        _message = '操作成功';
      });
      await _loadAccounts();
    } on Object {
      if (current()) _update(() => _message = '操作结果尚未确认，请查询核实，勿重复提交');
    } finally {
      if (mounted) _update(() => _writing = false);
    }
  }

  Future<void> _delete() async {
    if (!_editable) return;
    final account = _single();
    if (account == null) return;
    if (account.balance > 0) {
      _update(() => _message = '当前账户挂账金额大于0，不可删除');
      return;
    }
    final scope = _scope;
    _update(() => _confirming = true);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('删除挂账账户'),
        content: Text('确认删除“${account.name}”？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _update(() => _confirming = false);
    if (accepted == true && _current(scope)) {
      await _perform((guard) => widget.loader.delete(account, guard));
    }
  }

  void _save() {
    final draft = CashierCreditAccountDraft(
      id: _account?.id,
      name: _name.text,
      contactName: _contact.text,
      contactPhone: _phone.text,
    );
    if (draft.name.isEmpty) {
      _update(() => _message = '请输入挂账账户名称');
      return;
    }
    if (draft.contactPhone.isNotEmpty && draft.contactPhone.length != 11) {
      _update(() => _message = '请输入正确的11位手机号码');
      return;
    }
    unawaited(_perform((guard) => widget.loader.save(draft, guard)));
  }

  void _openLogs(CashierCreditAccount account) {
    if (!_allowed || _busy) return;
    _scope++;
    _account = account;
    _logType = 0;
    _update(() {
      _mode = _Mode.logs;
      _message = null;
    });
    unawaited(_loadLogs());
  }

  Future<void> _loadLogs() async {
    if (!_allowed || _account == null) return;
    final scope = _scope, request = ++_request;
    _update(() => _loading = true);
    try {
      final result = await widget.loader.logs(_account!.id, _logType);
      if (!_current(scope) || request != _request) return;
      _update(() {
        _logs = result.valueOrNull ?? [];
        _message = result.failureOrNull?.safeMessage;
      });
    } on Object {
      if (_current(scope)) _update(() => _message = '挂账记录查询失败，请重试');
    } finally {
      if (mounted && request == _request) _update(() => _loading = false);
    }
  }

  void _openRepay(CashierCreditAccount account) {
    if (!_editable || account.balance <= 0) return;
    _scope++;
    _account = account;
    _selectedOrders.clear();
    _channels.clear();
    for (final c in _channelInputs.values) {
      c.clear();
    }
    _update(() {
      _mode = _Mode.repay;
      _orders = [];
      _message = null;
    });
    unawaited(_loadOrders());
  }

  Future<void> _loadOrders() async {
    final scope = _scope, request = ++_request;
    _update(() => _loading = true);
    try {
      final result = await widget.loader.orders(_account!.id);
      if (!_current(scope) || request != _request) return;
      _update(() {
        _orders = result.valueOrNull ?? [];
        _selectedOrders.clear();
        _channels.clear();
        _message = result.failureOrNull?.safeMessage;
      });
    } on Object {
      if (_current(scope)) _update(() => _message = '待还订单查询失败，请重试');
    } finally {
      if (mounted && request == _request) _update(() => _loading = false);
    }
  }

  CashierCreditRepayment get _repayment => CashierCreditRepayment(
    accountId: _account!.id,
    orders: List.unmodifiable(
      _orders.where((o) => _selectedOrders.contains(o.id)),
    ),
    channelAmounts: Map.unmodifiable({
      for (final id in _channels) id: _channelInputs[id]!.text,
    }),
  );
  void _autoFill(int id) {
    if (!_editable || _selectedOrders.isEmpty) return;
    try {
      final draft = _repayment;
      final owed =
          draft.orders.fold<int>(0, (sum, o) => sum + o.amountFen) / 100;
      final remaining = owed - draft.totalYuan;
      if (remaining <= 0) return;
      final existing = _channelInputs[id]!.text.trim().isEmpty
          ? 0.0
          : double.parse(_channelInputs[id]!.text);
      _update(
        () => _channelInputs[id]!.text = (existing + remaining).toStringAsFixed(
          2,
        ),
      );
    } on Object {
      _update(() => _message = '请先输入正确的渠道金额');
    }
  }

  void _repay() {
    final draft = _repayment;
    try {
      draft.allocate();
    } on FormatException catch (error) {
      _update(
        () => _message = error.message.isEmpty ? '请检查还款金额' : error.message,
      );
      return;
    }
    unawaited(_perform((guard) => widget.loader.repay(draft, guard)));
  }

  String _total() {
    try {
      return _repayment.totalYuan.toStringAsFixed(2);
    } on Object {
      return '--';
    }
  }

  List<CashierCreditAllocation> _allocations() {
    try {
      return _repayment.allocate();
    } on Object {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: _mode == _Mode.accounts,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) {
        _close();
      } else {
        _leave();
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(switch (_mode) {
          _Mode.accounts => '挂账账户',
          _Mode.edit => _account == null ? '新增账户' : '修改账户',
          _Mode.logs => '查看记录',
          _Mode.repay => '挂账还款',
        }),
        leading: _mode == _Mode.accounts ? null : BackButton(onPressed: _leave),
      ),
      body: Column(
        children: [
          if (_loading || _writing) const LinearProgressIndicator(),
          if (widget.loader.needsVerification)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('上次操作结果尚未确认，请返回账户列表点击查询核实，勿重复提交'),
            ),
          if (_message != null)
            Padding(padding: const EdgeInsets.all(8), child: Text(_message!)),
          Expanded(
            child: switch (_mode) {
              _Mode.accounts => _accountList(),
              _Mode.edit => _editor(),
              _Mode.logs => _logList(),
              _Mode.repay => _repayForm(),
            },
          ),
        ],
      ),
    ),
  );
  Widget _accountList() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                key: const Key('credit-search'),
                controller: _keyword,
                enabled: _allowed && !_busy,
                decoration: const InputDecoration(labelText: '账户名称'),
                onSubmitted: (_) => unawaited(_loadAccounts(verify: true)),
              ),
            ),
            FilledButton(
              onPressed: _allowed && !_busy
                  ? () => unawaited(_loadAccounts(verify: true))
                  : null,
              child: const Text('查询核实'),
            ),
            TextButton(
              onPressed: _editable ? () => _edit() : null,
              child: const Text('新增'),
            ),
            TextButton(
              onPressed: _editable
                  ? () {
                      final account = _single();
                      if (account != null) _edit(account);
                    }
                  : null,
              child: const Text('编辑'),
            ),
            TextButton(
              onPressed: _editable ? _delete : null,
              child: const Text('删除'),
            ),
            FilterChip(
              label: const Text('全选'),
              selected:
                  _accounts.isNotEmpty && _selected.length == _accounts.length,
              onSelected: _allowed && !_busy
                  ? (selected) => _update(() {
                      _selected.clear();
                      if (selected) {
                        _selected.addAll(_accounts.map((a) => a.id));
                      }
                    })
                  : null,
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView(
          children: [
            if (_accounts.isEmpty && !_loading)
              const Center(child: Text('暂无数据')),
            for (final account in _accounts)
              Card(
                child: Column(
                  children: [
                    CheckboxListTile(
                      key: ValueKey('credit-account-${account.id}'),
                      title: Text(account.name),
                      subtitle: Text(
                        '剩余挂账金额：${account.amountYuan} 元\n联系人：${account.contactName}　联系方式：${account.contactPhone}',
                      ),
                      value: _selected.contains(account.id),
                      onChanged: _allowed && !_busy
                          ? (v) => _update(() {
                              if (v == true) {
                                _selected.add(account.id);
                              } else {
                                _selected.remove(account.id);
                              }
                            })
                          : null,
                    ),
                    Wrap(
                      spacing: 12,
                      children: [
                        TextButton(
                          onPressed: _editable && account.balance > 0
                              ? () => _openRepay(account)
                              : null,
                          child: const Text('挂账还款'),
                        ),
                        TextButton(
                          onPressed: _allowed && !_busy
                              ? () => _openLogs(account)
                              : null,
                          child: const Text('查看记录'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );
  Widget _editor() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      TextField(
        key: const Key('credit-name'),
        controller: _name,
        enabled: _editable,
        decoration: const InputDecoration(labelText: '账户名称（必填）'),
      ),
      TextField(
        key: const Key('credit-contact'),
        controller: _contact,
        enabled: _editable,
        decoration: const InputDecoration(labelText: '联系人'),
      ),
      TextField(
        key: const Key('credit-phone'),
        controller: _phone,
        enabled: _editable,
        decoration: const InputDecoration(labelText: '联系方式（11位）'),
      ),
      Wrap(
        children: [
          TextButton(onPressed: _leave, child: const Text('关闭')),
          FilledButton(
            onPressed: _editable ? _save : null,
            child: const Text('确定'),
          ),
        ],
      ),
    ],
  );
  Widget _logList() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<int>(
                key: ValueKey('credit-log-type-$_logType'),
                initialValue: _logType,
                items: [
                  for (final e in const {0: '全部', 1: '挂账', 2: '挂账还款'}.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: _allowed && !_busy
                    ? (v) => _update(() => _logType = v!)
                    : null,
              ),
            ),
            TextButton(
              onPressed: _allowed && !_busy ? _loadLogs : null,
              child: const Text('查询'),
            ),
            TextButton(
              onPressed: _allowed && !_busy
                  ? () {
                      _logType = 0;
                      unawaited(_loadLogs());
                    }
                  : null,
              child: const Text('重置'),
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView(
          children: [
            if (_logs.isEmpty && !_loading) const Text('暂无数据'),
            for (final (index, log) in _logs.indexed)
              ListTile(
                title: Text(
                  '${index + 1}. ${log.time}　${log.type}　${log.amountYuan} 元',
                ),
                subtitle: Text('还款方式：${log.channel}　操作人：${log.operatorName}'),
              ),
          ],
        ),
      ),
    ],
  );
  Widget _repayForm() {
    final allocations = _allocations();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('当前账户：${_account!.name}　剩余挂账金额：${_account!.amountYuan} 元'),
        const Text('请勾选要还款的订单，系统会按渠道及订单顺序分配金额'),
        CheckboxListTile(
          title: const Text('全选订单'),
          value: _orders.isNotEmpty && _selectedOrders.length == _orders.length,
          onChanged: _editable
              ? (v) => _update(() {
                  _selectedOrders.clear();
                  if (v == true) {
                    _selectedOrders.addAll(_orders.map((o) => o.id));
                  }
                })
              : null,
        ),
        for (final order in _orders)
          Card(
            child: Column(
              children: [
                CheckboxListTile(
                  key: ValueKey('credit-order-${order.id}'),
                  title: Text(
                    '${order.seat}　挂账金额：${(order.amountFen / 100).toStringAsFixed(2)} 元',
                  ),
                  subtitle: Text('挂账时间：${order.time}　订位人：${order.salesName}'),
                  value: _selectedOrders.contains(order.id),
                  onChanged: _editable
                      ? (v) => _update(() {
                          if (v == true) {
                            _selectedOrders.add(order.id);
                          } else {
                            _selectedOrders.remove(order.id);
                          }
                        })
                      : null,
                ),
                if (_selectedOrders.contains(order.id))
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      allocations
                              .where((a) => a.orderId == order.id)
                              .map(
                                (a) =>
                                    '${creditRepaymentChannels[a.channelId]}：${(a.rawFen / 100).toStringAsFixed(2)}',
                              )
                              .join('　')
                              .isEmpty
                          ? '未分配'
                          : allocations
                                .where((a) => a.orderId == order.id)
                                .map(
                                  (a) =>
                                      '${creditRepaymentChannels[a.channelId]}：${(a.rawFen / 100).toStringAsFixed(2)}',
                                )
                                .join('　'),
                    ),
                  ),
              ],
            ),
          ),
        if (_orders.isEmpty && !_loading) const Text('暂无待还订单'),
        Wrap(
          spacing: 8,
          children: [
            for (final channel in creditRepaymentChannels.entries)
              FilterChip(
                key: ValueKey('credit-channel-${channel.key}'),
                label: Text(channel.value),
                selected: _channels.contains(channel.key),
                onSelected: _editable
                    ? (v) => _update(() {
                        if (v) {
                          _channels.add(channel.key);
                        } else {
                          _channels.remove(channel.key);
                          _channelInputs[channel.key]!.clear();
                        }
                      })
                    : null,
              ),
          ],
        ),
        Text('总还款金额：${_total()} 元'),
        for (final channel in creditRepaymentChannels.entries)
          if (_channels.contains(channel.key))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextField(
                      key: ValueKey('credit-channel-amount-${channel.key}'),
                      controller: _channelInputs[channel.key],
                      enabled: _editable,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: '${channel.value}（元）',
                      ),
                      onChanged: (_) => _update(() => _message = null),
                    ),
                  ),
                  TextButton(
                    onPressed: _editable && _selectedOrders.isNotEmpty
                        ? () => _autoFill(channel.key)
                        : null,
                    child: const Text('自动填入余额'),
                  ),
                ],
              ),
            ),
        Wrap(
          children: [
            TextButton(onPressed: _leave, child: const Text('关闭')),
            FilledButton(
              onPressed: _editable ? _repay : null,
              child: const Text('确定还款'),
            ),
          ],
        ),
      ],
    );
  }
}
