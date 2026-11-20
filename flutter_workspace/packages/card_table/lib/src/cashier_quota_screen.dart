import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:foundation/foundation.dart';

import 'package:card_table/src/cashier_quota.dart';
import 'package:card_table/src/cashier_reports.dart';

final class CashierQuotaScreen extends StatefulWidget {
  const CashierQuotaScreen({required this.load, this.canRead, super.key});
  final Future<Result<CashierReportPage>> Function(CashierReportQuery)? load;
  final ValueListenable<bool>? canRead;
  @override
  State<CashierQuotaScreen> createState() => _CashierQuotaScreenState();
}

class _CashierQuotaScreenState extends State<CashierQuotaScreen> {
  final _code = TextEditingController(), _password = TextEditingController();
  CashierReportPage? _result;
  List<CashierReportRow>? _products;
  String? _productTitle, _error;
  bool _busy = false;
  bool _closed = false;
  int _passType = 1, _epoch = 0;
  bool get _allowed => !_closed && (widget.canRead?.value ?? true);
  @override
  void initState() {
    super.initState();
    widget.canRead?.addListener(_access);
  }

  void _access() {
    if (!mounted || _allowed) return;
    _epoch++;
    _code.clear();
    _password.clear();
    setState(() {
      _result = null;
      _products = null;
      _productTitle = null;
      _error = null;
    });
  }

  @override
  void didUpdateWidget(CashierQuotaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.canRead, widget.canRead)) {
      oldWidget.canRead?.removeListener(_access);
      widget.canRead?.addListener(_access);
      _epoch++;
      _result = null;
      _products = null;
      _code.clear();
      _password.clear();
    }
  }

  @override
  void dispose() {
    _epoch++;
    widget.canRead?.removeListener(_access);
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _query({CashierReportRow? detail}) async {
    final load = widget.load;
    if (_busy || !_allowed || load == null) return;
    final id = detail == null ? null : int.tryParse(detail.id);
    if (detail != null && (id == null || id <= 0)) return;
    final auth = detail == null
        ? CashierQuotaAuthorization(
            code: _code.text.trim(),
            password: _password.text,
            passType: _passType,
          )
        : null;
    if (auth != null && !auth.valid) {
      setState(() => _error = '请输入授权账号和密码');
      return;
    }
    _password.clear();
    final epoch = _epoch;
    bool current() => mounted && _allowed && epoch == _epoch;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await load(
        CashierReportQuery(
          title: '查询优惠额度',
          quotaAuthorization: auth,
          quotaLimitId: id,
          canDispatch: current,
        ),
      );
      if (!current()) return;
      setState(() {
        _error = result.failureOrNull?.safeMessage;
        if (result.valueOrNull case final page?) {
          if (detail == null) {
            _result = page;
            _code.clear();
          } else {
            _products = page.rows;
            _productTitle = detail['n'];
          }
        }
      });
    } on Object {
      if (current()) setState(() => _error = '查询失败，请重新授权');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        _closed = true;
        _access();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('查询优惠额度')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_allowed) const Text('连接或权限已变化，请恢复后重新授权'),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (result == null) ...[
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('账号密码'),
                    selected: _passType == 1,
                    onSelected: _busy || !_allowed
                        ? null
                        : (_) => setState(() {
                            _passType = 1;
                            _code.clear();
                            _password.clear();
                          }),
                  ),
                  ChoiceChip(
                    label: const Text('手工卡号/卡密'),
                    selected: _passType == 2,
                    onSelected: _busy || !_allowed
                        ? null
                        : (_) => setState(() {
                            _passType = 2;
                            _code.clear();
                            _password.clear();
                          }),
                  ),
                ],
              ),
              if (_passType == 2) const Text('仅输入已取得的卡号/卡密，不代表已接入原生读卡器'),
              TextField(
                controller: _code,
                enabled: !_busy && _allowed,
                decoration: InputDecoration(
                  labelText: _passType == 1 ? '授权人工号' : '卡号',
                ),
              ),
              TextField(
                controller: _password,
                enabled: !_busy && _allowed,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: _passType == 1 ? '授权密码' : '卡密',
                ),
              ),
              FilledButton(
                onPressed: _busy || !_allowed ? null : () => _query(),
                child: Text(_busy ? '查询中…' : '授权查询'),
              ),
            ] else ...[
              Text(
                '姓名：${result.quota?.name ?? ''}　工号：${result.quota?.code ?? ''}',
              ),
              if (result.rows.isEmpty) const Text('暂无数据'),
              for (final row in result.rows)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: _busy || !_allowed
                              ? null
                              : () => _query(detail: row),
                          child: Text(row['n']),
                        ),
                        Text('类型：${row['t']}'),
                        Text('日限数量　已用：${row['udc']}　剩余：${row['ldc']}'),
                        Text('日限金额　已用：${row['uda']}　剩余：${row['lda']}'),
                        Text('月用数量　已用：${row['umc']}　剩余：${row['lmc']}'),
                        Text('月限金额　已用：${row['uma']}　剩余：${row['lma']}'),
                      ],
                    ),
                  ),
                ),
              if (_products != null) ...[
                Text('$_productTitle · 商品明细'),
                if (_products!.isEmpty) const Text('暂无商品'),
                for (var i = 0; i < _products!.length; i++)
                  Text('${i + 1}. ${_products![i]['p']}'),
                TextButton(
                  onPressed: () => setState(() {
                    _products = null;
                    _productTitle = null;
                  }),
                  child: const Text('关闭商品明细'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
