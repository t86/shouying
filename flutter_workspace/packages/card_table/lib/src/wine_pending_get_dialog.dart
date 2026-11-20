import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';

import 'package:card_table/src/wine_models.dart';
import 'package:card_table/src/wine_pending_get.dart';

final class WinePendingGetDialog extends StatefulWidget {
  const WinePendingGetDialog({
    super.key,
    required this.record,
    required this.inventory,
    required this.needsAuthorization,
    required this.submit,
    this.isCurrent,
  });
  final WineGetRecord record;
  final List<WineGetSubItem> inventory;
  final bool needsAuthorization;
  final Future<Result<void>> Function(Map<String, Object?>) submit;
  final bool Function()? isCurrent;
  @override
  State<WinePendingGetDialog> createState() => _WinePendingGetDialogState();
}

final class _WinePendingGetDialogState extends State<WinePendingGetDialog> {
  final _counts = <String, TextEditingController>{};
  final _maximum = <String, int>{};
  final _items = <String, WineGetSubItem>{};
  final _account = TextEditingController();
  final _secret = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _valid = true;
  bool _expired = false;

  bool _checkContext() {
    if (!mounted) return false;
    if (_expired || widget.isCurrent?.call() == false) {
      _expired = true;
      _account.clear(); _secret.clear();
      setState(() => _error = '登录或连接状态已改变，请关闭后重新打开');
      return false;
    }
    return true;
  }
  int _passType = 1;

  @override
  void initState() {
    super.initState();
    for (final item in widget.inventory) {
      if (_items.containsKey(item.id)) _valid = false;
      _items[item.id] = item;
      _maximum[item.id] = item.count;
    }
    final originals = <String, int>{};
    for (final item in widget.record.items) {
      _items.putIfAbsent(item.id, () => item);
      originals.update(
        item.id,
        (n) => n + item.count,
        ifAbsent: () => item.count,
      );
      _maximum.update(
        item.id,
        (n) => n + item.count,
        ifAbsent: () => item.count,
      );
    }
    for (final item in _items.values) {
      if ((int.tryParse(item.id) ?? 0) <= 0 || item.count < 0) _valid = false;
      _counts[item.id] = TextEditingController(
        text: '${originals[item.id] ?? 0}',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _counts.values) {
      controller.dispose();
    }
    _account.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_valid || !_checkContext()) return;
    final ownerRoute = ModalRoute.of(context);
    final counts = <String, int>{};
    for (final entry in _counts.entries) {
      final count = int.tryParse(entry.value.text);
      if (count == null || count < 0 || count > _maximum[entry.key]!) {
        setState(() => _error = '数量必须为 0 到可取总数之间的整数');
        return;
      }
      if (count > 0) counts[entry.key] = count;
    }
    late final Map<String, Object?> body;
    try {
      body = winePendingGetBody(
        orderId: widget.record.id,
        counts: counts,
        needsAuthorization: widget.needsAuthorization,
        account: _account.text,
        secret: _secret.text,
        passType: _passType,
      );
    } on ArgumentError {
      setState(() => _error = '请选择酒水并填写完整授权信息');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    _account.clear(); _secret.clear();
    final result = await widget.submit(body);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!_checkContext()) return;
    if (result.failureOrNull case final failure?) {
      setState(() => _error = failure.safeMessage);
    } else {
      if (ownerRoute?.isCurrent == true) {
        ownerRoute!.navigator?.pop(true);
      } else if (ownerRoute?.isActive == true) {
        ownerRoute!.navigator?.removeRoute(ownerRoute, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('编辑取酒单 - ${widget.record.customerName}'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('手机号：${widget.record.customerPhone}'),
            const Text('数量填 0 删除；可取总数含本单原数量与剩余库存。'),
            for (final item in _items.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  key: ValueKey('wine-get-count-${item.id}'),
                  controller: _counts[item.id],
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${item.name} / ${item.unit} / ${item.gram}',
                    helperText: '可取总数：${_maximum[item.id]}',
                  ),
                ),
              ),
            if (widget.needsAuthorization) ...[
              DropdownButton<int>(
                value: _passType,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('账号密码')),
                  DropdownMenuItem(value: 2, child: Text('员工卡（手工输入）')),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                        _passType = value!;
                        _account.clear();
                        _secret.clear();
                      }),
              ),
              if (_passType == 2) const Text('自动读卡尚未接入，请输入卡号和原始卡数据。'),
              TextField(
                key: const Key('wine-get-account'),
                controller: _account,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: _passType == 1 ? '授权人工号' : '员工卡号',
                ),
              ),
              TextField(
                key: const Key('wine-get-secret'),
                controller: _secret,
                enabled: !_busy,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: _passType == 1 ? '授权人密码' : '原始卡数据',
                ),
              ),
            ],
            if (!_valid) const Text('库存数据无效，请重新查询'),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.of(context).pop(false),
        child: const Text('取消'),
      ),
      FilledButton(
        key: const Key('wine-get-submit'),
        onPressed: _busy || !_valid ? null : _submit,
        child: Text(_busy ? '提交中…' : '确认出库'),
      ),
    ],
  );
}
