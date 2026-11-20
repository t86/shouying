import 'package:card_table/src/paid_order_refund.dart';
import 'package:card_table/src/not_pay_order_view.dart' show payOrderProductName;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/services.dart';
import 'package:foundation/foundation.dart';

const paidRefundWarning = '如果继续操作，本订单已支付渠道将进入滞留金列表，本订单中未退单的商品需重新支付。请确认是否继续操作？';

class PaidOrderRefundDialog extends StatefulWidget {
  const PaidOrderRefundDialog({
    required this.draft,
    required this.reasons,
    required this.contextToken,
    required this.submit,
    this.productNameFor,
    super.key,
  });
  final PaidOrderRefundDraft draft;
  final String? Function(String productId)? productNameFor;
  final List<String> reasons;
  final ValueListenable<Object?> contextToken;
  final Future<Result<void>> Function(
    PaidOrderRefundDraft,
    bool Function() isCurrentAttempt,
  )
  submit;
  @override
  State<PaidOrderRefundDialog> createState() => _PaidOrderRefundDialogState();
}

class _PaidOrderRefundDialogState extends State<PaidOrderRefundDialog> {
  late PaidOrderRefundDraft _draft = widget.draft;
  late final Object? _token = widget.contextToken.value;
  final _counts = <String, TextEditingController>{},
      _amounts = <String, TextEditingController>{};
  bool _busy = false, _invalid = false;
  int _attempt = 0;
  String? _error;
  bool get _current =>
      mounted &&
      !_invalid &&
      _token != null &&
      identical(_token, widget.contextToken.value);
  @override
  void initState() {
    super.initState();
    for (final line in _draft.lines) {
      _counts[line.id] = TextEditingController(text: '${line.count}');
      _amounts[line.id] = TextEditingController(text: line.amount);
    }
    widget.contextToken.addListener(_changed);
    if (_token == null) _invalid = true;
  }

  void _changed() {
    if (!identical(_token, widget.contextToken.value)) {
      _attempt++;
      FocusManager.instance.primaryFocus?.unfocus();
      if (mounted) {
        setState(() {
          _invalid = true;
          _error = '登录、连接或卡台状态已改变，请关闭后重新打开退款';
        });
      }
    }
  }

  @override
  void didUpdateWidget(PaidOrderRefundDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.contextToken, widget.contextToken)) {
      oldWidget.contextToken.removeListener(_changed);
      widget.contextToken.addListener(_changed);
      _invalid = true;
      _attempt++;
    }
  }

  @override
  void dispose() {
    _invalid = true;
    _attempt++;
    widget.contextToken.removeListener(_changed);
    for (final controller in [..._counts.values, ..._amounts.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _close([bool success = false]) {
    _invalid = true;
    _attempt++;
    FocusManager.instance.primaryFocus?.unfocus();
    final route = ModalRoute.of(context);
    if (route?.isCurrent == true) {
      Navigator.pop(context, success);
    } else if (route?.isActive == true) {
      route!.navigator?.removeRoute(route, success);
    }
  }

  void _changeCount(String id, String value) {
    final count = int.tryParse(value);
    if (count == null) return;
    setState(() {
      _draft = _draft.withCount(id, count);
      _amounts[id]!.text = _draft.lines
          .firstWhere((line) => line.id == id)
          .amount;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy || !_current) return;
    for (final line in _draft.lines.where((line) => line.selected)) {
      final count = int.tryParse(_counts[line.id]!.text);
      if (count == null) {
        setState(() => _error = '请输入有效整数退单数量');
        return;
      }
      _draft = _draft.withCount(line.id, count);
      final updated = _draft.lines.firstWhere((row) => row.id == line.id);
      if (updated.amountEditable) {
        _draft = _draft.withAmount(line.id, _amounts[line.id]!.text.trim());
      }
    }
    final invalid = _draft.validate();
    if (invalid != null) {
      setState(() => _error = invalid.safeMessage);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final attempt = ++_attempt;
    bool active() => mounted && attempt == _attempt && _busy && _current;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认已结退款'),
        content: const Text(paidRefundWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('返回修改'),
          ),
          FilledButton(
            key: const Key('paid-refund-final-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('继续退款'),
          ),
        ],
      ),
    );
    if (!active()) return;
    if (yes != true) {
      setState(() => _busy = false);
      return;
    }
    try {
      final result = await widget.submit(_draft, active);
      if (!active()) return;
      if (result.failureOrNull case final failure?) {
        setState(() => _error = failure.safeMessage);
      } else {
        _close(true);
      }
    } on Object {
      if (active()) setState(() => _error = '退款请求失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('已结支付单 ${_draft.payId} 退单'),
    content: SizedBox(
      width: 800,
      height: MediaQuery.sizeOf(context).height * .65,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(paidRefundWarning, style: TextStyle(color: Colors.red)),
          TextButton(
            onPressed: _busy || !_current
                ? null
                : () => setState(
                    () => _draft = _draft.selectAll(
                      !_draft.lines
                          .where(
                            (line) =>
                                line.item.count > 0 && !line.item.isRefunded,
                          )
                          .every((line) => line.selected),
                    ),
                  ),
            child: const Text('全选/取消全选'),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final line in _draft.lines)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            key: Key('paid-refund-select-${line.id}'),
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              payOrderProductName(
                                line.item.name,
                                line.item.productId,
                                widget.productNameFor,
                              ),
                            ),
                            subtitle: Text(
                              '可退数量：${line.item.count} · 原小计：￥${line.item.recordedAmount}',
                            ),
                            value: line.selected,
                            onChanged:
                                _busy ||
                                    !_current ||
                                    line.item.isRefunded ||
                                    line.item.count <= 0
                                ? null
                                : (value) => setState(
                                    () => _draft = _draft.withSelected(
                                      line.id,
                                      value == true,
                                    ),
                                  ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  key: Key('paid-refund-count-${line.id}'),
                                  controller: _counts[line.id],
                                  enabled: !_busy && _current && line.selected,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: '退单数量',
                                  ),
                                  onChanged: (value) =>
                                      _changeCount(line.id, value),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: line.amountEditable
                                    ? TextField(
                                        key: Key(
                                          'paid-refund-amount-${line.id}',
                                        ),
                                        controller: _amounts[line.id],
                                        enabled:
                                            !_busy && _current && line.selected,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: InputDecoration(
                                          labelText:
                                              '退款金额（元），不超过${line.item.recordedAmount}',
                                        ),
                                        onChanged: (value) => _draft = _draft
                                            .withAmount(line.id, value),
                                      )
                                    : Text('退单小计：￥${line.backAmount}'),
                              ),
                            ],
                          ),
                          if (line.item.packageDetails.isNotEmpty)
                            for (final detail in line.item.packageDetails)
                              Text(
                                '套餐明细：${payOrderProductName(detail.name, detail.id, widget.productNameFor)} × ${detail.count}',
                              ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Text('请选择退单理由'),
          Wrap(
            spacing: 8,
            children: [
              for (final reason in widget.reasons)
                ChoiceChip(
                  label: Text(reason),
                  selected: _draft.reason == reason,
                  onSelected: _busy || !_current
                      ? null
                      : (_) =>
                            setState(() => _draft = _draft.withReason(reason)),
                ),
            ],
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          if (_busy) const Text('若退款请求已发出，关闭窗口不会撤回该请求。'),
          if (_invalid) const Text('此退款窗口已失效，请重新打开'),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => _close(), child: const Text('取消')),
      FilledButton(
        key: const Key('paid-refund-submit'),
        onPressed: _busy || !_current ? null : _submit,
        child: Text(_busy ? '提交中…' : '确认'),
      ),
    ],
  );
}
