import 'package:card_table/src/order_refund.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/services.dart';
import 'package:foundation/foundation.dart';

/// Credentials are local to this route and cleared on every attempt or exit.
class OrderRefundDialog extends StatefulWidget {
  const OrderRefundDialog({
    required this.draft,
    required this.reasons,
    required this.contextToken,
    required this.submit,
    super.key,
  });
  final OrderRefundDraft draft;
  final List<String> reasons;
  final ValueListenable<Object?> contextToken;
  final Future<Result<void>> Function(
    OrderRefundDraft draft,
    String authEmpCode,
    String authEmpPasswd,
    int passType,
    bool Function() isCurrentAttempt,
  )
  submit;
  @override
  State<OrderRefundDialog> createState() => _OrderRefundDialogState();
}

class _OrderRefundDialogState extends State<OrderRefundDialog> {
  late OrderRefundDraft _draft = widget.draft;
  late final Object? _token = widget.contextToken.value;
  late final _count = TextEditingController(text: '${_draft.count}');
  late final _amount = TextEditingController(text: _draft.amount);
  final _code = TextEditingController(), _password = TextEditingController();
  bool _busy = false, _authorization = false, _invalidated = false;
  int _passType = 1;
  int _attempt = 0;
  String? _error;
  bool get _current =>
      mounted &&
      !_invalidated &&
      _token != null &&
      identical(_token, widget.contextToken.value);
  @override
  void initState() {
    super.initState();
    widget.contextToken.addListener(_contextChanged);
    if (_token == null) _invalidated = true;
  }

  @override
  void didUpdateWidget(OrderRefundDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.contextToken, widget.contextToken)) {
      oldWidget.contextToken.removeListener(_contextChanged);
      widget.contextToken.addListener(_contextChanged);
      _invalidate();
    }
  }

  void _contextChanged() {
    if (!identical(_token, widget.contextToken.value)) _invalidate();
  }

  void _clearCredentials() {
    _code.clear();
    _password.clear();
  }

  void _invalidate() {
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _clearCredentials();
    _attempt++;
    setState(() {
      _invalidated = true;
      _error = '登录、连接或卡台状态已改变，请关闭后重新退单';
    });
  }

  @override
  void dispose() {
    _invalidated = true;
    _attempt++;
    widget.contextToken.removeListener(_contextChanged);
    _clearCredentials();
    _count.dispose();
    _amount.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  void _close([bool success = false]) {
    _invalidated = true;
    _attempt++;
    FocusManager.instance.primaryFocus?.unfocus();
    _clearCredentials();
    final route = ModalRoute.of(context);
    if (route?.isCurrent == true) {
      Navigator.pop(context, success);
    } else if (route?.isActive == true) {
      route!.navigator?.removeRoute(route, success);
    }
  }

  void _countChanged(String text) {
    final count = int.tryParse(text);
    if (count == null) return;
    setState(() {
      _draft = _draft.withCount(count);
      _amount.text = _draft.amount;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy || !_current) return;
    if (_draft.quantityEditable) {
      final count = int.tryParse(_count.text);
      if (count == null) {
        setState(() => _error = '请输入有效整数数量');
        return;
      }
      _draft = _draft.withCount(count);
    }
    if (_draft.amountEditable) _draft = _draft.withAmount(_amount.text.trim());
    if (_draft.reason.trim().isEmpty) {
      setState(() => _error = '请选择退单理由');
      return;
    }
    final invalid = _draft.validate();
    if (invalid != null) {
      setState(() => _error = invalid.safeMessage);
      return;
    }
    if (_authorization &&
        (_code.text.trim().isEmpty || _password.text.isEmpty)) {
      setState(
        () => _error = _passType == 1 ? '请输入授权工号和密码' : '请输入已有读卡结果中的卡码和卡密码',
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final code = _authorization ? _code.text.trim() : '';
    final password = _authorization ? _password.text : '';
    _clearCredentials();
    setState(() {
      _busy = true;
      _error = null;
    });
    final attempt = ++_attempt;
    try {
      final result = await widget.submit(
        _draft,
        code,
        password,
        _authorization ? _passType : 1,
        () => mounted && attempt == _attempt && _busy && _current,
      );
      if (!mounted || !_current) return;
      if (result.failureOrNull case final failure?) {
        setState(() {
          _error = failure.safeMessage;
          if (failure.code == orderRefundAuthorizationRequiredCode) {
            _authorization = true;
          }
        });
      } else {
        _close(true);
      }
    } on Object {
      if (mounted && _current) setState(() => _error = '退单请求失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(_authorization ? '退单授权' : '退单'),
    content: SizedBox(
      width: 430,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.draft.order.name),
            Text('可退数量：${widget.draft.order.count}'),
            TextField(
              key: const Key('order-refund-count'),
              controller: _count,
              enabled:
                  !_busy &&
                  _current &&
                  _draft.quantityEditable &&
                  !_authorization,
              autofocus: _draft.quantityEditable && !widget.draft.isCashier,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: '退单数量'),
              onChanged: _countChanged,
            ),
            if (!_draft.quantityEditable) const Text('此订单按规则锁定退单数量'),
            if (!_draft.amountEditable)
              Text(
                '退单金额：￥${_draft.order.recordedPrice.amountFor(changeCount: _draft.count).toStringAsFixed(2)}',
              ),
            if ([3, 5, 8].contains(_draft.productType))
              TextField(
                key: const Key('order-refund-amount'),
                controller: _amount,
                enabled:
                    !_busy &&
                    _current &&
                    _draft.amountEditable &&
                    !_authorization,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _draft.amountEditable
                      ? '退款金额（元），不超过${widget.draft.order.recordedAmount}'
                      : '原订单金额（特殊类型退单请求使用）',
                ),
                onChanged: (value) => _draft = _draft.withAmount(value),
              ),
            const SizedBox(height: 10),
            const Text('退单理由'),
            Wrap(
              spacing: 8,
              children: [
                for (final reason in widget.reasons)
                  ChoiceChip(
                    label: Text(reason),
                    selected: _draft.reason == reason,
                    onSelected: _busy || !_current || _authorization
                        ? null
                        : (_) => setState(
                            () => _draft = _draft.withReason(reason),
                          ),
                  ),
              ],
            ),
            if (_authorization) ...[
              const Divider(),
              const Text('本人授权不足，请使用他人授权信息重试'),
              Wrap(
                spacing: 8,
                children: [
                  for (final type in [1, 2])
                    ChoiceChip(
                      label: Text(type == 1 ? '账号密码' : '卡码输入'),
                      selected: _passType == type,
                      onSelected: _busy || !_current
                          ? null
                          : (_) => setState(() {
                              _passType = type;
                              _clearCredentials();
                            }),
                    ),
                ],
              ),
              if (_passType == 2) const Text('未接自动读卡；请输入已有读卡结果，不会模拟读卡成功。'),
              TextField(
                key: const Key('order-refund-auth-code'),
                controller: _code,
                enabled: !_busy && _current,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: _passType == 1 ? '授权工号' : '卡码（读卡结果）',
                ),
              ),
              TextField(
                key: const Key('order-refund-auth-password'),
                controller: _password,
                enabled: !_busy && _current,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: _passType == 1 ? '授权密码' : '卡密码（读卡结果）',
                ),
              ),
            ],
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_invalidated) const Text('此退单窗口已失效，重连不会恢复提交'),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => _close(), child: const Text('取消')),
      FilledButton(
        onPressed: _busy || !_current ? null : _submit,
        child: Text(
          _busy
              ? '提交中…'
              : _authorization
              ? '授权退单'
              : '确认',
        ),
      ),
    ],
  );
}
