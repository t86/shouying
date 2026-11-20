import 'dart:async';

import 'package:card_table/src/order_late_deposit.dart';
import 'package:card_table/src/qr_code_pane.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Adding new staff-collected funds to this seat; not cashier balance payment.
final class OrderLateDepositScreen extends StatefulWidget {
  const OrderLateDepositScreen({
    required this.seatId,
    required this.loader,
    required this.canOperate,
    this.scanCode,
    this.onPaid,
    super.key,
  });
  final String seatId;
  final OrderLateDepositLoader loader;
  final ValueListenable<bool> canOperate;
  final Future<String?> Function()? scanCode;
  final VoidCallback? onPaid;
  @override
  State<OrderLateDepositScreen> createState() => _OrderLateDepositState();
}

class _OrderLateDepositState extends State<OrderLateDepositScreen> {
  final _amount = TextEditingController();
  int? _payType;
  int _epoch = 0;
  bool _active = true,
      _expired = false,
      _busy = false,
      _polling = false,
      _closing = false,
      _paid = false,
      _uncertain = false,
      _creationStarted = false;
  String? _message;
  OrderLateDepositPayment? _payment;
  Timer? _timer;
  DialogRoute<bool>? _closeDialog;
  bool get _current =>
      mounted &&
      _active &&
      !_expired &&
      widget.canOperate.value &&
      ((ModalRoute.of(context)?.isCurrent ?? false) ||
          (_closeDialog?.isCurrent ?? false));
  bool get _locked => _uncertain || widget.loader.needsVerification;
  bool get _editing =>
      _current && !_busy && !_locked && _payment == null && !_paid;
  bool get _needsConfirmation =>
      !_paid && (_creationStarted || _payment != null || _locked);
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
    widget.canOperate.addListener(_accessChanged);
  }

  void _accessChanged() {
    if (widget.canOperate.value) return;
    _epoch++;
    _timer?.cancel();
    _expired = true;
    _update(() {
      _payment = null;
      _message = '登录、权限或连接已变化；原付款可能仍在处理，请核实系统记录，勿重复收取';
    });
  }

  @override
  void didUpdateWidget(covariant OrderLateDepositScreen old) {
    super.didUpdateWidget(old);
    if (!identical(old.canOperate, widget.canOperate)) {
      old.canOperate.removeListener(_accessChanged);
      widget.canOperate.addListener(_accessChanged);
      _expire();
    }
    if (old.seatId != widget.seatId || !identical(old.loader, widget.loader)) {
      _expire();
    }
  }

  void _expire() {
    _active = false;
    _epoch++;
    _timer?.cancel();
    _payment = null;
    _dismissCloseDialog();
  }

  void _dismissCloseDialog() {
    final dialog = _closeDialog;
    _closeDialog = null;
    if (dialog == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (dialog.isActive) dialog.navigator?.removeRoute(dialog, false);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _expire();
    widget.canOperate.removeListener(_accessChanged);
    _amount.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_editing) return;
    final type = _payType, amount = _amount.text.trim(), token = _epoch;
    if (type == null || !isValidOrderLateDepositAmount(amount)) {
      _update(() => _message = '请选择渠道并输入有效金额（元，最多两位小数）');
      return;
    }
    bool current() => _current && token == _epoch;
    _update(() {
      _busy = true;
      _message = null;
    });
    var sent = false;
    try {
      String? code;
      if (type == 5 || type == 6) {
        if (widget.scanCode == null) return;
        code = await widget.scanCode!();
        if (!current()) return;
        if (code == null || code.trim().isEmpty) {
          _update(() => _message = '扫码已取消，尚未创建付款');
          return;
        }
      }
      if (!current()) return;
      _creationStarted = true;
      sent = true;
      final result = await widget.loader.create(
        seatId: widget.seatId,
        payType: type,
        amountYuan: amount,
        authCode: code,
        canDispatch: current,
      );
      if (!current()) return;
      if (result.failureOrNull case final failure?) {
        _update(() {
          _uncertain =
              widget.loader.needsVerification ||
              failure.code == 'order_late.result_unknown';
          _creationStarted = _uncertain;
          _message = _uncertain
              ? '付款结果不确定，请核实系统记录，请勿重复创建'
              : failure.safeMessage;
        });
        return;
      }
      final payment = result.valueOrNull!;
      if (payment.result == 1) {
        _finishPaid();
        return;
      }
      if (payment.result == 2) {
        _update(() {
          _creationStarted = false;
          _message = '支付失败；请核实后重新操作';
        });
        return;
      }
      _update(() => _payment = payment);
      _timer?.cancel();
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(_poll()),
      );
    } on Object {
      if (current()) {
        _update(() {
          _uncertain = sent;
          _message = sent ? '付款结果不确定，请核实系统记录，请勿重复创建' : '扫码失败，尚未创建付款，请重试';
        });
      }
    } finally {
      if (mounted) _update(() => _busy = false);
    }
  }

  Future<void> _poll() async {
    final payment = _payment, token = _epoch;
    if (!_current || payment == null || _polling || _paid) return;
    bool current() =>
        _current && token == _epoch && identical(_payment, payment);
    _polling = true;
    try {
      final result = await widget.loader.status(
        payment.payDetailId,
        canDispatch: current,
      );
      if (!current()) return;
      if (result.failureOrNull != null) {
        _update(() => _message = '付款查询未确认，请继续查询原付款记录，勿重新创建');
        return;
      }
      if (result.valueOrNull == 5) {
        _finishPaid();
      }
    } on Object {
      if (current()) _update(() => _message = '付款查询未确认，请继续查询原付款记录，勿重新创建');
    } finally {
      _polling = false;
    }
  }

  void _finishPaid() {
    if (!_current || _paid) return;
    final route = ModalRoute.of(context);
    _timer?.cancel();
    _paid = true;
    _creationStarted = false;
    _update(() => _message = '支付成功');
    _dismissCloseDialog();
    try {
      widget.onPaid?.call();
    } on Object {
      // A refresh callback cannot turn a confirmed payment into an unknown one.
    }
    // Remove only this page, never whatever the caller may have navigated to.
    if (mounted && route?.isActive == true && !route!.isFirst) {
      _expire();
      route.navigator?.removeRoute(route, true);
    }
  }

  Future<void> _requestClose() async {
    if (_closing || !mounted) return;
    final owner = ModalRoute.of(context);
    _closing = true;
    try {
      if (_needsConfirmation) {
        final dialog = DialogRoute<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认关闭'),
            content: const Text('关闭后将停止查询支付结果，但不会撤销付款。请核实系统记录，避免重复收取。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('继续等待'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确认关闭'),
              ),
            ],
          ),
        );
        _closeDialog = dialog;
        final confirmed = await Navigator.of(context).push(dialog);
        _closeDialog = null;
        if (confirmed != true || !mounted) return;
      }
      _expire();
      if (owner?.isActive == true && !owner!.isFirst) {
        owner.navigator?.removeRoute(owner, false);
      } else if (mounted) {
        setState(() {});
      }
    } finally {
      _closing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = _payment;
    return PopScope<void>(
      canPop: !_needsConfirmation,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _expire();
        } else {
          unawaited(_requestClose());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('添加滞留金'),
          leading: IconButton(
            tooltip: '关闭',
            onPressed: _requestClose,
            icon: const Icon(Icons.close),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_expired || !_active) const Text('本次操作已失效，请关闭后重新进入'),
              if (payment == null && !_paid && !_expired && _active) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in {
                      2: '客人扫我-微信',
                      1: '客人扫我-支付宝',
                      if (widget.scanCode != null) ...{
                        6: '扫客人-微信',
                        5: '扫客人-支付宝',
                      },
                    }.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _payType == entry.key,
                        onSelected: _editing
                            ? (selected) {
                                if (selected) {
                                  setState(() => _payType = entry.key);
                                }
                              }
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('order-late-amount'),
                  controller: _amount,
                  enabled: _editing,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: '滞留金金额',
                    suffixText: '元',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _editing ? _create : null,
                  child: const Text('确认收取'),
                ),
              ],
              if (payment != null) ...[
                Text('待支付金额：${_amount.text.trim()} 元'),
                const SizedBox(height: 16),
                if ((_payType == 1 || _payType == 2) &&
                    payment.payUrl.isNotEmpty)
                  QrCodePane(
                    data: payment.payUrl,
                    paintKey: const Key('order-late-qr'),
                  ),
                const SizedBox(height: 12),
                const Text('等待支付结果；仅查询这笔原付款，不会重新创建'),
                TextButton(
                  onPressed: _current && !_polling ? _poll : null,
                  child: const Text('查询支付结果'),
                ),
              ],
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('正在处理，请勿重复提交…'),
                ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_message!),
                )
              else if (_locked)
                const Text('原付款结果不确定，请核实系统记录，请勿重复创建'),
            ],
          ),
        ),
      ),
    );
  }
}
