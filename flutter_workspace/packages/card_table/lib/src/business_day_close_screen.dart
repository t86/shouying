import 'dart:async';

import 'package:card_table/src/business_day_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:foundation/foundation.dart';

typedef CloseBusinessDay = Future<Result<void>> Function();
typedef PrintShiftBill = Future<Result<void>> Function();
typedef LoadAutoClose = Future<Result<AutoCloseConfig>> Function();
typedef SaveAutoClose = Future<Result<void>> Function({
  required bool enabled,
  required int hour,
  required int minute,
});

/// Cashier end-of-day drawer from Vue `drawerStopStore.vue`.
final class BusinessDayCloseScreen extends StatefulWidget {
  const BusinessDayCloseScreen({
    required this.automatic,
    this.closeDay,
    this.printShift,
    this.loadAutoClose,
    this.saveAutoClose,
    this.canOperate,
    this.onClosed,
    super.key,
  });

  final bool automatic;
  final CloseBusinessDay? closeDay;
  final PrintShiftBill? printShift;
  final LoadAutoClose? loadAutoClose;
  final SaveAutoClose? saveAutoClose;
  final ValueListenable<bool>? canOperate;
  final Future<void> Function()? onClosed;

  @override
  State<BusinessDayCloseScreen> createState() => _BusinessDayCloseScreenState();
}

final class _BusinessDayCloseScreenState extends State<BusinessDayCloseScreen> {
  bool _enabled = false;
  int _hour = 0;
  int _minute = 0;
  bool _busy = false;
  bool _loaded = false;
  bool _loading = false;
  bool _expired = false;
  bool _closeUncertain = false;
  bool get _allowed => !_expired && (widget.canOperate?.value ?? true);

  void _accessChanged() {
    if (!(widget.canOperate?.value ?? true) && mounted) {
      setState(() => _expired = true);
    }
  }

  @override
  void initState() {
    super.initState();
    _expired = !(widget.canOperate?.value ?? true);
    widget.canOperate?.addListener(_accessChanged);
    if (widget.automatic) {
      unawaited(Future<void>.microtask(_load));
    }
  }

  @override
  void dispose() {
    widget.canOperate?.removeListener(_accessChanged);
    super.dispose();
  }

  Future<void> _load() async {
    final load = widget.loadAutoClose;
    if (load == null || _loading || !_allowed) return;
    setState(() => _loading = true);
    Result<AutoCloseConfig> result;
    try {
      result = await load();
    } on Object {
      result = const FailureResult(_operationFailure);
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (!_allowed) return;
    final config = result.valueOrNull;
    if (config == null) {
      _toast(result.failureOrNull?.safeMessage ?? '读取失败');
      return;
    }
    setState(() {
      _loaded = true;
      _enabled = config.enabled;
      _hour = config.hour;
      _minute = config.minute;
    });
  }

  Future<void> _close() async {
    final close = widget.closeDay;
    if (close == null || _busy || !_allowed || _closeUncertain) return;
    setState(() => _busy = true);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('结束营业日'),
        content: const Text('注意：结束营业日会清空当前营业数据，请确认场所已结束营业。相关人员已下班。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok != true || !_allowed) {
      setState(() => _busy = false);
      return;
    }
    Result<void> result;
    try {
      result = await close();
    } on Object {
      result = const FailureResult(_operationFailure);
    }
    if (!mounted) return;
    final failure = result.failureOrNull;
    setState(() {
      _busy = false;
      _closeUncertain = failure != null && failure.kind != FailureKind.business;
    });
    _toast(
      _closeUncertain
          ? _uncertainCloseMessage
          : failure?.safeMessage ?? '结束操作成功',
    );
    if (result.failureOrNull == null) {
      final route = ModalRoute.of(context);
      if (route != null) Navigator.of(context).removeRoute(route);
      await widget.onClosed?.call();
    }
  }

  Future<void> _save() async {
    final save = widget.saveAutoClose;
    if (save == null || _busy || !_allowed || !_loaded) return;
    setState(() => _busy = true);
    Result<void> result;
    try {
      result = await save(enabled: _enabled, hour: _hour, minute: _minute);
    } on Object {
      result = const FailureResult(_operationFailure);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (_allowed) _toast(result.failureOrNull?.safeMessage ?? '设置成功');
  }

  Future<void> _print() async {
    final print = widget.printShift;
    if (print == null || _busy || !_allowed) return;
    setState(() => _busy = true);
    Result<void> result;
    try {
      result = await print();
    } on Object {
      result = const FailureResult(_operationFailure);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (_allowed) _toast(result.failureOrNull?.safeMessage ?? '打印成功');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  static const _operationFailure = AppFailure(
    kind: FailureKind.network,
    code: 'business_day.operation_failed',
    safeMessage: '操作失败，请检查连接后重试',
  );
  static const _uncertainCloseMessage = '结束营业日结果尚未确认，请核实服务端营业日状态后返回重新打开，勿重复提交';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.automatic ? '自动结束营业日时间设置' : '手动结束营业')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_allowed) const Text('连接、会话或营业日已变化，请返回重新打开'),
          if (!widget.automatic) ...[
            const Text('结束营业日会清空当前营业数据。'),
            if (_closeUncertain) const Text(_uncertainCloseMessage),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy || !_allowed || _closeUncertain ? null : _close,
              child: const Text('结束营业日'),
            ),
            TextButton(
              onPressed: _busy || !_allowed ? null : _print,
              child: const Text('打印班结表'),
            ),
          ] else ...[
            if (!_loaded)
              TextButton(
                onPressed: _loading || !_allowed ? null : _load,
                child: Text(_loading ? '正在读取配置…' : '重新读取配置'),
              ),
            SwitchListTile(
              title: const Text('是否开启自动结束营业日功能'),
              value: _enabled,
              onChanged: _busy || !_allowed || !_loaded
                  ? null
                  : (value) => setState(() => _enabled = value),
            ),
            if (_enabled) ...[
              Text('时 $_hour'),
              Slider(
                min: 0,
                max: 23,
                divisions: 23,
                value: _hour.toDouble(),
                onChanged: _busy || !_allowed
                    ? null
                    : (value) => setState(() => _hour = value.round()),
              ),
              Text('分 $_minute'),
              Slider(
                min: 0,
                max: 59,
                divisions: 59,
                value: _minute.toDouble(),
                onChanged: _busy || !_allowed
                    ? null
                    : (value) => setState(() => _minute = value.round()),
              ),
            ],
            FilledButton(
              onPressed: _busy || !_allowed || !_loaded ? null : _save,
              child: const Text('保存'),
            ),
          ],
        ],
      ),
    );
  }
}
