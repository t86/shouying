import 'dart:async';

import 'package:card_table/src/pay_order_models.dart';
import 'package:flutter/material.dart';

/// 预设支付渠道定义
final class PayChannelDef {
  const PayChannelDef({
    required this.id,
    required this.name,
    this.authType = 0,
    this.icon = Icons.payment,
  });

  final int id;
  final String name;
  final int authType;
  final IconData icon;

  bool get supported => id != 6;
}

const List<PayChannelDef> kDefaultPayChannels = [
  PayChannelDef(id: 1, name: '现金', icon: Icons.attach_money),
  PayChannelDef(id: 2, name: '微信支付', icon: Icons.chat),
  PayChannelDef(id: 3, name: '支付宝', icon: Icons.account_balance_wallet),
  PayChannelDef(id: 4, name: '银行卡刷卡', icon: Icons.credit_card),
  PayChannelDef(id: 6, name: '挂账', icon: Icons.book),
  PayChannelDef(id: 10, name: '抹零', authType: 1, icon: Icons.content_cut),
  PayChannelDef(id: 500, name: '会员卡', icon: Icons.card_membership),
  PayChannelDef(id: 202, name: '预订金', icon: Icons.event),
  PayChannelDef(id: 9999, name: '滞留金', icon: Icons.pending_actions),
];

/// 收款交互抽屉组件 (S3.P2.T04 ~ T08)
final class PayMoneyDrawer extends StatefulWidget {
  const PayMoneyDrawer({
    required this.seatId,
    required this.totalUnpayAmt,
    required this.cartItems,
    required this.onAddChannel,
    required this.onDeleteChannel,
    required this.onAddZeroAuth,
    this.onAddLate,
    this.onAddMemberCard,
    this.onAddPrepay,
    required this.onSubmitPay,
    this.onClose,
    this.refreshCart,
    super.key,
  });

  final int seatId;
  final double totalUnpayAmt;
  final List<PayCartItem> cartItems;
  final Future<void> Function(int payCnlId, int amtFen, String note)
  onAddChannel;
  final Future<void> Function(int cartItemId) onDeleteChannel;
  final Future<void> Function(int amtFen, String authCode) onAddZeroAuth;
  final Future<void> Function(String lateId)? onAddLate;
  final Future<void> Function({
    required String cardId,
    required int amountFen,
    required String phone,
    required String authCode,
  })?
  onAddMemberCard;
  final Future<void> Function({
    required String prepayId,
    required String amount,
    required String authCode,
  })?
  onAddPrepay;
  final Future<void> Function() onSubmitPay;
  final VoidCallback? onClose;
  final Future<List<PayCartItem>> Function()? refreshCart;

  @override
  State<PayMoneyDrawer> createState() => _PayMoneyDrawerState();
}

final class _PayMoneyDrawerState extends State<PayMoneyDrawer> {
  PayChannelDef _activeChannel = kDefaultPayChannels.first;
  String _inputAmountStr = '';
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _authCodeCtrl = TextEditingController();
  final TextEditingController _lateIdCtrl = TextEditingController();
  final TextEditingController _cardIdCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _prepayIdCtrl = TextEditingController();
  bool _submitting = false;
  bool _cartFresh = true;
  late List<PayCartItem> _cartItems;

  double get _cartTotal => _cartItems.fold(
    0.0,
    (sum, it) => sum + (double.tryParse(it.amount) ?? 0.0),
  );

  double get _remainingAmt =>
      (widget.totalUnpayAmt - _cartTotal).clamp(0.0, double.infinity);

  double get _inputAmount => double.tryParse(_inputAmountStr) ?? 0.0;

  bool _ready(PayChannelDef channel) {
    return switch (channel.id) {
      6 => false,
      10 => true,
      500 => widget.onAddMemberCard != null,
      202 => widget.onAddPrepay != null,
      9999 => widget.onAddLate != null,
      _ => true,
    };
  }

  double get _changeAmt =>
      (_inputAmount - _remainingAmt).clamp(0.0, double.infinity);

  @override
  void initState() {
    super.initState();
    _cartItems = widget.cartItems;
    _inputAmountStr = _remainingAmt > 0 ? _remainingAmt.toStringAsFixed(2) : '';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _authCodeCtrl.dispose();
    _lateIdCtrl.dispose();
    _cardIdCtrl.dispose();
    _phoneCtrl.dispose();
    _prepayIdCtrl.dispose();
    super.dispose();
  }

  void _onKeypadTap(String val) {
    setState(() {
      if (val == 'C') {
        _inputAmountStr = '';
      } else if (val == '⌫') {
        if (_inputAmountStr.isNotEmpty) {
          _inputAmountStr = _inputAmountStr.substring(
            0,
            _inputAmountStr.length - 1,
          );
        }
      } else if (val == '.') {
        if (!_inputAmountStr.contains('.')) {
          _inputAmountStr = _inputAmountStr.isEmpty
              ? '0.'
              : '$_inputAmountStr.';
        }
      } else {
        if (_inputAmountStr.contains('.') &&
            _inputAmountStr.split('.')[1].length >= 2) {
          return;
        }
        _inputAmountStr += val;
      }
    });
  }

  Future<void> _addChannel() async {
    if (_submitting || !_cartFresh || !_ready(_activeChannel)) return;
    final amt = _inputAmount;
    if (amt <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入有效金额')));
      return;
    }
    final amtFen = (amt.clamp(0, _remainingAmt) * 100).round();
    if (amtFen <= 0) return;

    setState(() => _submitting = true);
    try {
      if (_activeChannel.id == 10) {
        await widget.onAddZeroAuth(amtFen, _authCodeCtrl.text.trim());
      } else if (_activeChannel.id == 9999) {
        final add = widget.onAddLate;
        if (add == null) throw StateError('滞留金尚未接入');
        final lateId = _lateIdCtrl.text.trim();
        if (lateId.isEmpty) throw StateError('请输入滞留金单号');
        await add(lateId);
      } else if (_activeChannel.id == 500) {
        final add = widget.onAddMemberCard;
        if (add == null) throw StateError('会员卡渠道尚未接入');
        await add(
          cardId: _cardIdCtrl.text.trim(),
          amountFen: amtFen,
          phone: _phoneCtrl.text.trim(),
          authCode: _authCodeCtrl.text.trim(),
        );
      } else if (_activeChannel.id == 202) {
        final add = widget.onAddPrepay;
        if (add == null) throw StateError('预订金渠道尚未接入');
        await add(
          prepayId: _prepayIdCtrl.text.trim(),
          amount: amt.toStringAsFixed(2),
          authCode: _authCodeCtrl.text.trim(),
        );
      } else {
        await widget.onAddChannel(
          _activeChannel.id,
          amtFen,
          _noteCtrl.text.trim(),
        );
      }
      await _refreshCart();
      if (!mounted) return;
      setState(() {
        _inputAmountStr = '';
        _noteCtrl.clear();
        _authCodeCtrl.clear();
      });
    } on Object catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _refreshCart() async {
    _cartFresh = false;
    final refresh = widget.refreshCart;
    if (refresh == null) throw StateError('收款清单刷新未接入，请关闭后重试');
    final items = await refresh();
    if (!mounted) return;
    setState(() {
      _cartItems = items;
      _cartFresh = true;
    });
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is StateError ? error.message.toString() : '操作失败，请重试',
        ),
      ),
    );
  }

  Future<void> _deleteChannel(PayCartItem item) async {
    if (_submitting || !_cartFresh) return;
    setState(() => _submitting = true);
    try {
      await widget.onDeleteChannel(int.parse(item.id));
      await _refreshCart();
    } on Object catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.88,
      backgroundColor: const Color(0xff0D172D),
      child: SafeArea(
        child: Column(
          children: [
            // 抽屉头部
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xff182037),
                border: Border(bottom: BorderSide(color: Color(0xff263352))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '收款结算',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed:
                        widget.onClose ?? () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // 主内容区域（三栏：左渠道、中输入、右清单）
            Expanded(
              child: Row(
                children: [
                  // 左栏：渠道选择
                  SizedBox(
                    width: 170,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xff141D35),
                        border: Border(
                          right: BorderSide(color: Color(0xff263352)),
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: kDefaultPayChannels.length,
                        itemBuilder: (context, index) {
                          final ch = kDefaultPayChannels[index];
                          final isActive = ch.id == _activeChannel.id;
                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              enabled: _ready(ch) && !_submitting,
                              subtitle: _ready(ch)
                                  ? null
                                  : const Text('暂未接入'),
                              selected: isActive,
                              selectedTileColor: const Color(0xff2362D5),
                              leading: Icon(
                                ch.icon,
                                color: isActive ? Colors.white : Colors.white70,
                                size: 20,
                              ),
                              title: Text(
                                ch.name,
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                              onTap: () => setState(() {
                                _activeChannel = ch;
                                if (_inputAmountStr.isEmpty &&
                                    _remainingAmt > 0) {
                                  _inputAmountStr = _remainingAmt
                                      .toStringAsFixed(2);
                                }
                              }),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 中栏：金额与键盘输入
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 提示信息
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xff182037),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '待结金额:',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '¥${_remainingAmt.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 当前选中渠道及金额显示
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xff101930),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xff3373E8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${_activeChannel.name}:',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _inputAmountStr.isEmpty
                                        ? '0.00'
                                        : '¥$_inputAmountStr',
                                    style: const TextStyle(
                                      color: Color(0xffFFA726),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (_changeAmt > 0)
                                  Text(
                                    '找零: ¥${_changeAmt.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // 抹零需输入授权码
                          if (_activeChannel.id == 10 ||
                              _activeChannel.id == 500 ||
                              _activeChannel.id == 202) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _authCodeCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: _activeChannel.id == 10
                                    ? '请输入授权码 / 密码'
                                    : '授权码',
                                labelStyle: const TextStyle(color: Colors.white60),
                                filled: true,
                                fillColor: const Color(0xff182037),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ],
                          if (_activeChannel.id == 9999) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _lateIdCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: '滞留金单号',
                                labelStyle: TextStyle(color: Colors.white60),
                                filled: true,
                                fillColor: Color(0xff182037),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                          if (_activeChannel.id == 500) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _cardIdCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: '会员卡Id',
                                labelStyle: TextStyle(color: Colors.white60),
                                filled: true,
                                fillColor: Color(0xff182037),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _phoneCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: '手机号',
                                labelStyle: TextStyle(color: Colors.white60),
                                filled: true,
                                fillColor: Color(0xff182037),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                          if (_activeChannel.id == 202) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _prepayIdCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: '预订金Id',
                                labelStyle: TextStyle(color: Colors.white60),
                                filled: true,
                                fillColor: Color(0xff182037),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),
                          // 快捷金额按键
                          Row(
                            children: [100, 300, 500, 800].map((quick) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff182037),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => setState(
                                      () => _inputAmountStr = quick
                                          .toStringAsFixed(2),
                                    ),
                                    child: Text('¥$quick'),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 12),
                          // 数字键盘
                          Expanded(child: _buildNumericKeypad()),

                          const SizedBox(height: 12),
                          // 加入流水按钮
                          SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff2362D5),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _submitting ? null : _addChannel,
                              icon: const Icon(Icons.add_circle_outline),
                              label: Text(
                                _activeChannel.authType == 1
                                    ? '授权加入流水'
                                    : '确认加入流水',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 右栏：待结算流水购物车清单
                  SizedBox(
                    width: 330,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xff141D35),
                        border: Border(
                          left: BorderSide(color: Color(0xff263352)),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xff182037),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '本次应收:',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      '¥${widget.totalUnpayAmt.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '已收渠道:',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      '¥${_cartTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xffFFA726),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '待结算渠道明细',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Expanded(
                            child: _cartItems.isEmpty
                                ? const Center(
                                    child: Text(
                                      '暂未添加支付渠道\n请在左侧选择并加入流水',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 13,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _cartItems.length,
                                    separatorBuilder: (_, _) => const Divider(
                                      color: Color(0xff263352),
                                      height: 10,
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = _cartItems[index];
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.channelName,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Text(
                                                  '¥${item.amount}',
                                                  style: const TextStyle(
                                                    color: Color(0xffFFA726),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                              size: 20,
                                            ),
                                            onPressed: _submitting
                                                ? null
                                                : () => unawaited(
                                                    _deleteChannel(item),
                                                  ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                          ),

                          const Divider(color: Color(0xff263352), height: 24),
                          // 结账完成按钮
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff00B894),
                                foregroundColor: Colors.white,
                              ),
                              onPressed:
                                  _submitting ||
                                      !_cartFresh ||
                                      !widget.totalUnpayAmt.isFinite ||
                                      widget.totalUnpayAmt < 0 ||
                                      _remainingAmt > 0.005
                                  ? null
                                  : () async {
                                      setState(() => _submitting = true);
                                      try {
                                        await widget.onSubmitPay();
                                      } on Object catch (error) {
                                        _showError(error);
                                      } finally {
                                        if (mounted) {
                                          setState(() => _submitting = false);
                                        }
                                      }
                                    },
                              child: const Text(
                                '完成收款',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
      ['C'],
    ];

    return Column(
      children: keys.map((row) {
        return Expanded(
          child: Row(
            children: row.map((k) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: k == 'C' || k == '⌫'
                          ? const Color(0xff263352)
                          : const Color(0xff182037),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () => _onKeypadTap(k),
                    child: Text(
                      k,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
