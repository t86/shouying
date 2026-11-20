import 'dart:async';

import 'package:card_table/src/vip_recharge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:foundation/foundation.dart';
import 'package:card_table/src/qr_code_pane.dart';

typedef VipRechargeSearch = Future<Result<List<VipCardHit>>> Function(
  String keyword,
);
typedef VipRechargeDetail = Future<Result<VipMemberCard>> Function(
  String cardId,
);
typedef VipRechargeRules = Future<Result<List<VipDepositRule>>> Function(
  String cardId,
);
typedef VipRechargeLastSales = Future<Result<VipLastSales?>> Function(
  String cardId,
);
typedef VipRechargePollStatus = Future<Result<VipOrderStatus>> Function(
  String orderId,
);
typedef VipRechargeCreateOrder = Future<Result<VipRechargeOrder>> Function(
  Map<String, Object?> body, {
  bool Function()? canDispatch,
});
typedef VipRechargeCreatePay = Future<Result<VipRechargePay>> Function({
  required String payId,
  required int payAmtFen,
  required int payType,
  String authCode,
  bool Function()? canDispatch,
});

final class VipRechargeScreen extends StatefulWidget {
  const VipRechargeScreen({
    required this.search,
    required this.detail,
    required this.rules,
    required this.createOrder,
    required this.createPay,
    required this.canRead,
    this.lastSales,
    this.pollStatus,
    this.employees = const [],
    this.csmId,
    this.seatSales,
    this.scanPaymentCode,
    this.needsVerification,
    this.pendingOrder,
    super.key,
  });

  static const Key searchKey = Key('vip-recharge-search');
  static const Key qrKey = Key('vip-recharge-qr');
  static const Key recommenderKey = Key('vip-recharge-recommender');

  final VipRechargeSearch search;
  final VipRechargeDetail detail;
  final VipRechargeRules rules;
  final VipRechargeLastSales? lastSales;
  final VipRechargePollStatus? pollStatus;
  final VipRechargeCreateOrder createOrder;
  final VipRechargeCreatePay createPay;
  final ValueListenable<bool> canRead;
  final List<VipRechargeEmployee> employees;
  final String? csmId;
  final VipRechargeEmployee? seatSales;
  final Future<String?> Function()? scanPaymentCode;
  final bool Function()? needsVerification;
  final VipRechargeOrder? Function()? pendingOrder;

  @override
  State<VipRechargeScreen> createState() => _VipRechargeScreenState();
}

final class _VipRechargeScreenState extends State<VipRechargeScreen> {
  final TextEditingController _keyword = TextEditingController();
  final TextEditingController _customAmount = TextEditingController();
  final TextEditingController _remark = TextEditingController();
  List<VipCardHit> _hits = const [];
  VipMemberCard? _member;
  List<VipDepositRule> _rules = const [];
  List<VipRechargeEmployee> _employeeOptions = const [];
  int _optionIndex = -1;
  String _recommenderId = '';
  String _recommenderName = '';
  bool _autoRecommender = false;
  bool _loading = false;
  bool _readRefreshScheduled = false;
  bool _qrOpen = false;
  bool _paying = false,
      _confirmOpen = false,
      _uncertain = false,
      _active = true,
      _polling = false;
  int _paymentEpoch = 0;
  Route<void>? _qrRoute;
  VipRechargeOrder? _createdOrder;
  int _version = 0;
  Timer? _paymentTimer;

  bool get _customSelected =>
      _optionIndex >= 0 && _optionIndex == _rules.length;

  bool get _canConfirm {
    if (!_active ||
        _paying ||
        _confirmOpen ||
        _uncertain ||
        (widget.needsVerification?.call() ?? false) ||
        !widget.canRead.value ||
        _member == null ||
        _optionIndex < 0) {
      return false;
    }
    if (!_customSelected) return true;
    return _amountFen(_customAmount.text) != null;
  }

  int? _amountFen(String text) {
    final match = RegExp(r'^(\d{1,13})(?:\.(\d{1,2}))?$')
        .firstMatch(text.trim());
    if (match == null) return null;
    final amount =
        int.parse(match[1]!) * 100 +
        int.parse((match[2] ?? '').padRight(2, '0'));
    return amount > 0 && amount <= 9007199254740991 ? amount : null;
  }

  bool Function() _capture() {
    final version = _version;
    final route = ModalRoute.of(context);
    return () =>
        mounted &&
        _active &&
        widget.canRead.value &&
        version == _version &&
        (route == null ||
            (route.isActive &&
                route.animation?.status != AnimationStatus.reverse));
  }

  @override
  void didUpdateWidget(VipRechargeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canRead != widget.canRead) {
      oldWidget.canRead.removeListener(_onRead);
      widget.canRead.addListener(_onRead);
      _onRead();
    }
    if (oldWidget.csmId != widget.csmId ||
        oldWidget.seatSales?.id != widget.seatSales?.id)
      _onRead();
  }

  List<VipRechargeEmployee> get _visibleEmployees {
    if (_recommenderId.isEmpty) return _employeeOptions;
    if (_employeeOptions.any((item) => item.id == _recommenderId)) {
      return _employeeOptions;
    }
    return [
      VipRechargeEmployee(id: _recommenderId, name: _recommenderName),
      ..._employeeOptions,
    ];
  }

  @override
  void initState() {
    super.initState();
    widget.canRead.addListener(_onRead);
    _employeeOptions = widget.employees;
  }

  @override
  void dispose() {
    _version++;
    _stopPoll();
    widget.canRead.removeListener(_onRead);
    _keyword.dispose();
    _customAmount.dispose();
    _remark.dispose();
    super.dispose();
  }

  void _stopPoll() {
    _paymentEpoch++;
    _paymentTimer?.cancel();
    _paymentTimer = null;
  }

  void _onRead() {
    _version++;
    if (!mounted) return;
    if (!widget.canRead.value) {
      _hits = const [];
      _member = null;
      _rules = const [];
      _optionIndex = -1;
      _stopPoll();
      final route = _qrRoute;
      _qrOpen = false;
      _qrRoute = null;
      if (route != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (route.isActive) route.navigator?.removeRoute(route);
        });
      }
    }
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_readRefreshScheduled) return;
      _readRefreshScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _readRefreshScheduled = false;
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
  }

  Future<void> _onKeyword(String value) async {
    final version = ++_version;
    if (value.length < 4 || !widget.canRead.value) {
      setState(() {
        _hits = const [];
        if (value.length < 4) {
          _member = null;
          _rules = const [];
          _optionIndex = -1;
        }
      });
      return;
    }
    setState(() => _loading = true);
    final result = await widget.search(value);
    if (!mounted || version != _version) return;
    setState(() {
      _loading = false;
      _hits = result.valueOrNull ?? const [];
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
      }
    });
  }

  Future<void> _select(VipCardHit hit) async {
    final version = ++_version;
    setState(() {
      _loading = true;
      _hits = const [];
    });
    final detail = await widget.detail(hit.id);
    final rules = await widget.rules(hit.id);
    final last = widget.lastSales == null
        ? const Success<VipLastSales?>(null)
        : await widget.lastSales!(hit.id);
    if (!mounted || version != _version) return;
    final member = detail.valueOrNull;
    setState(() {
      _loading = false;
      _member = member;
      _rules = rules.valueOrNull ?? const [];
      _optionIndex = member == null ? -1 : 0;
      _employeeOptions = widget.employees;
      _applyRecommender(
        lastSales: last.valueOrNull,
        openCardId: member?.salesEmployeeId ?? '',
      );
      if (detail.failureOrNull != null) {
        _show(detail.failureOrNull!.safeMessage);
      } else if (rules.failureOrNull != null) {
        _show(rules.failureOrNull!.safeMessage);
      }
    });
  }

  void _applyRecommender({
    required VipLastSales? lastSales,
    required String openCardId,
  }) {
    final seat = widget.seatSales;
    if (seat != null &&
        seat.id.isNotEmpty &&
        _employeeOptions.any((employee) => employee.id == seat.id)) {
      _recommenderId = seat.id;
      _recommenderName = seat.name;
      _autoRecommender = true;
      return;
    }
    if (lastSales != null && lastSales.id.isNotEmpty) {
      _recommenderId = lastSales.id;
      _recommenderName = lastSales.name;
      _autoRecommender = true;
      return;
    }
    final open = _employeeOptions.where((item) => item.id == openCardId);
    if (open.isNotEmpty) {
      _recommenderId = open.first.id;
      _recommenderName = open.first.name;
      _autoRecommender = true;
      return;
    }
    if (_employeeOptions.isNotEmpty) {
      _recommenderId = _employeeOptions.first.id;
      _recommenderName = _employeeOptions.first.name;
      _autoRecommender = true;
      return;
    }
    _recommenderId = '';
    _recommenderName = '';
    _autoRecommender = false;
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _close() => unawaited(Navigator.of(context).maybePop());

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    final current = _capture();
    final member = _member!;
    final isCustom = _customSelected;
    final rule = isCustom ? null : _rules[_optionIndex];
    final depositFen = isCustom
        ? _amountFen(_customAmount.text)!
        : rule!.depositFen;
    final giftFen = rule?.giftFen ?? 0;
    final body = <String, Object?>{
      'mode': isCustom ? 2 : 1,
      'id': int.tryParse(member.id) ?? 0,
      'deposit_amt': depositFen,
      'free_amt': giftFen,
      'free_pt_amt': rule?.giftPoints ?? 0,
      'free_kq_id': rule?.couponId ?? 0,
      'sales_emp_id': int.tryParse(_recommenderId) ?? 0,
      'remark': _remark.text,
      if ((int.tryParse(widget.csmId ?? '') ?? 0) > 0)
        'csm_id': int.parse(widget.csmId!),
    };
    setState(() => _confirmOpen = true);
    try {
      await showDialog<void>(
        context: context,
        builder: (context) => _PaymentDialog(
          member: member,
          depositYuan: depositFen / 100,
          giftYuan: giftFen / 100,
          canScan: widget.scanPaymentCode != null,
          onConfirm: (payType) => unawaited(
            _pay(
              member: member,
              body: body,
              depositFen: depositFen,
              current: current,
              payType: payType,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _confirmOpen = false);
    }
  }

  Future<void> _pay({
    required VipMemberCard member,
    required Map<String, Object?> body,
    required int depositFen,
    required bool Function() current,
    required int payType,
  }) async {
    if (!current() ||
        _paying ||
        _uncertain ||
        (widget.needsVerification?.call() ?? false))
      return;
    setState(() => _paying = true);
    try {
      String authCode = '';
      if (payType == 5 || payType == 6) {
        final scan = widget.scanPaymentCode;
        if (scan == null) return;
        final code = await scan();
        if (!current() || code == null || code.trim().isEmpty) return;
        authCode = code.trim();
      }
      if (!current()) return;
      _uncertain = true;
      final order = await widget.createOrder(body, canDispatch: current);
      if (!current()) return;
      if (order.failureOrNull != null) {
        if (order.failureOrNull!.kind == FailureKind.business)
          _uncertain = false;
        _show(order.failureOrNull!.safeMessage);
        return;
      }
      final created = order.valueOrNull!;
      _createdOrder = created;
      final pay = await widget.createPay(
        payId: created.payId,
        payAmtFen: depositFen,
        payType: payType,
        authCode: authCode,
        canDispatch: current,
      );
      if (!current()) return;
      if (pay.failureOrNull != null) {
        if (pay.failureOrNull!.kind == FailureKind.business) {
          _uncertain = false;
          _createdOrder = null;
        }
        _show(pay.failureOrNull!.safeMessage);
        return;
      }
      final paid = pay.valueOrNull!;
      if (paid.payResult == 1) {
        _uncertain = false;
        _createdOrder = null;
        await _showSuccess(member: member, depositYuan: depositFen / 100);
        return;
      }
      if (paid.payResult == 2) {
        _uncertain = false;
        _createdOrder = null;
        _show('支付失败');
        return;
      }
      if (paid.payResult == 0) {
        await _showQr(
          scanUrl: paid.scanUrl,
          orderId: created.orderId,
          payType: payType,
          member: member,
          depositYuan: depositFen / 100,
          current: current,
        );
        return;
      }
      _show('请完成支付');
    } on Object {
      if (current()) _show('无法确认充值结果，请先核实，勿重复支付');
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _showQr({
    required String scanUrl,
    required String orderId,
    required int payType,
    required VipMemberCard member,
    required double depositYuan,
    required bool Function() current,
  }) async {
    _stopPoll();
    _qrOpen = true;
    final paymentEpoch = _paymentEpoch;
    if (widget.pollStatus != null) {
      _paymentTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(
          _poll(
            orderId: orderId,
            member: member,
            depositYuan: depositYuan,
            current: () =>
                current() && _qrOpen && paymentEpoch == _paymentEpoch,
          ),
        );
      });
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        _qrRoute = ModalRoute.of(context);
        return AlertDialog(
          title: const Text('请扫码支付'),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (scanUrl.isNotEmpty)
                  QrCodePane(data: scanUrl, paintKey: VipRechargeScreen.qrKey)
                else
                  const Text('正在核实付款结果…'),
                const SizedBox(height: 12),
                Text('支付金额：¥${depositYuan.toStringAsFixed(2)}'),
                Text('请使用${payType == 2 ? '微信' : '支付宝'}扫码支付'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _stopPoll();
                Navigator.pop(context);
              },
              child: const Text('取消支付'),
            ),
          ],
        );
      },
    );
    _qrOpen = false;
    _qrRoute = null;
    _stopPoll();
  }

  Future<void> _poll({
    required String orderId,
    required VipMemberCard member,
    required double depositYuan,
    required bool Function() current,
  }) async {
    final poll = widget.pollStatus;
    if (poll == null || _polling || !current()) return;
    _polling = true;
    try {
      final result = await poll(orderId);
      if (!current()) return;
      final status = result.valueOrNull;
      if (status == null) return;
      if (status.payResult == 1) {
        _uncertain = false;
        _createdOrder = null;
        _stopPoll();
        if (_qrOpen) {
          if (_qrRoute?.isActive ?? false)
            Navigator.of(context).removeRoute(_qrRoute!);
          _qrOpen = false;
        }
        await _showSuccess(member: member, depositYuan: depositYuan);
        return;
      }
      if (status.payResult == 2) {
        _uncertain = false;
        _createdOrder = null;
        _stopPoll();
        if (_qrOpen) {
          if (_qrRoute?.isActive ?? false)
            Navigator.of(context).removeRoute(_qrRoute!);
          _qrOpen = false;
        }
        _show('支付失败');
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _showSuccess({
    required VipMemberCard member,
    required double depositYuan,
  }) async {
    if (!mounted) return;
    _show('充值成功！');
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('支付成功！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('会员姓名：${member.name}'),
            Text('支付金额：¥${depositYuan.toStringAsFixed(2)}'),
            if (member.bindPhone.isNotEmpty) Text('手机号码：${member.bindPhone}'),
            const SizedBox(height: 8),
            const Text('充值金额已到账，感谢您的使用！'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('返回充值页面'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPending() async {
    final current = _capture();
    final pending = widget.pendingOrder?.call() ?? _createdOrder;
    if (!current() || _paying || pending == null || widget.pollStatus == null)
      return;
    setState(() => _paying = true);
    try {
      final result = await widget.pollStatus!(pending.orderId);
      if (!current()) return;
      final status = result.valueOrNull?.payResult;
      if (status == 1 || status == 2) {
        _uncertain = false;
        _createdOrder = null;
        _show(status == 1 ? '已核实：充值成功，请勿重复支付' : '已核实：支付失败，可以重新操作');
      } else {
        _show(result.failureOrNull?.safeMessage ?? '订单仍待支付确认，请勿重复支付');
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readable = widget.canRead.value;
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _active = false;
          _version++;
          _stopPoll();
        }
      },
      child: Theme(
        data: ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3373E8)),
        ),
        child: Scaffold(
          backgroundColor: const Color(0xffFAFAFC),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '会员充值',
                    style: TextStyle(fontSize: 24, color: Color(0xff08080A)),
                  ),
                  const SizedBox(height: 12),
                  if (_uncertain || (widget.needsVerification?.call() ?? false))
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('充值订单结果待核实，请勿重复支付'),
                        if (widget.pendingOrder?.call() != null ||
                            _createdOrder != null)
                          TextButton(
                            onPressed: _paying
                                ? null
                                : () => unawaited(_verifyPending()),
                            child: const Text('核实支付状态'),
                          ),
                      ],
                    ),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: readable
                            ? () => _show('如搜索不到手机号，可进行新客户可直接注册开卡')
                            : null,
                        child: const Text('注册开卡'),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('如搜索不到手机号，可进行新客户可直接注册开卡')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '* ',
                          style: TextStyle(color: Color(0xffE23C39)),
                        ),
                        TextSpan(text: '选择充值账户:'),
                      ],
                    ),
                  ),
                  TextField(
                    key: VipRechargeScreen.searchKey,
                    controller: _keyword,
                    enabled: readable && !_loading,
                    decoration: const InputDecoration(
                      hintText: '输入手机号后四位或会员卡号',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => unawaited(_onKeyword(value)),
                  ),
                  if (_hits.isNotEmpty)
                    SizedBox(
                      height: 160,
                      child: ListView(
                        children: [
                          for (final hit in _hits)
                            ListTile(
                              title: Text(hit.label),
                              onTap: () => unawaited(_select(hit)),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: !readable
                        ? const Center(child: Text('当前不可会员充值'))
                        : _member == null
                        ? const SizedBox.shrink()
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _info('会员卡号:', _member!.cardNo),
                                _info('会员姓名:', _member!.name),
                                _info('绑定手机:', _member!.bindPhone),
                                _info('储值余额:', '¥${_member!.storedBalance}'),
                                _info('赠送余额:', '¥${_member!.giftBalance}'),
                                _info('总余额:', '¥${_member!.totalBalance}'),
                                const SizedBox(height: 12),
                                const Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '* ',
                                        style: TextStyle(
                                          color: Color(0xffE23C39),
                                        ),
                                      ),
                                      TextSpan(text: '选择充值规则:'),
                                    ],
                                  ),
                                ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (var i = 0; i < _rules.length; i++)
                                      _ruleChip(
                                        i,
                                        '¥${_rules[i].displayPrice}',
                                        _rules[i],
                                      ),
                                    _ruleChip(_rules.length, '自定义', null),
                                  ],
                                ),
                                if (_customSelected)
                                  TextField(
                                    controller: _customAmount,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: const InputDecoration(
                                      labelText: '自定义充值金额:',
                                      hintText: '请输入金额',
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                const SizedBox(height: 12),
                                const Text('充值推荐人:'),
                                DropdownButton<String>(
                                  key: VipRechargeScreen.recommenderKey,
                                  isExpanded: true,
                                  value:
                                      _visibleEmployees.any(
                                        (e) => e.id == _recommenderId,
                                      )
                                      ? _recommenderId
                                      : null,
                                  hint: const Text('输入员工姓名或工号进行查询'),
                                  items: [
                                    for (final emp in _visibleEmployees)
                                      DropdownMenuItem(
                                        value: emp.id,
                                        child: Text(
                                          emp.code.isEmpty
                                              ? emp.name
                                              : '${emp.name} (${emp.code})',
                                        ),
                                      ),
                                  ],
                                  onChanged: (value) => setState(() {
                                    _recommenderId = value ?? '';
                                    _autoRecommender = false;
                                  }),
                                ),
                                if (_autoRecommender &&
                                    _recommenderId.isNotEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text('已自动设置推荐人，允许修改'),
                                  ),
                                const SizedBox(height: 12),
                                const Text('备注:'),
                                TextField(
                                  controller: _remark,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText: '请输入备注信息',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: _close, child: const Text('取消')),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _canConfirm
                            ? () => unawaited(_confirm())
                            : null,
                        child: const Text('确认充值'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 88, child: Text(label)),
        Expanded(child: Text(value)),
      ],
    ),
  );

  Widget _ruleChip(int index, String title, VipDepositRule? rule) {
    final selected = _optionIndex == index;
    return InkWell(
      onTap: () => setState(() => _optionIndex = index),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffE8F0FF) : const Color(0xffECEFF4),
          border: Border.all(
            color: selected ? const Color(0xff3373E8) : const Color(0xffC4CBD7),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18)),
            if (rule != null && rule.giftAmount > 0)
              Text('赠：¥${rule.giftAmount.toStringAsFixed(2)}'),
            if (rule != null && rule.giftPoints > 0)
              Text('赠：${rule.giftPoints}积分'),
            if (rule != null && rule.giftCoupon.isNotEmpty)
              Text('赠：${rule.giftCoupon}'),
          ],
        ),
      ),
    );
  }
}

final class _PaymentDialog extends StatelessWidget {
  const _PaymentDialog({
    required this.member,
    required this.depositYuan,
    required this.giftYuan,
    required this.onConfirm,
    required this.canScan,
  });

  final VipMemberCard member;
  final double depositYuan;
  final double giftYuan;
  final ValueChanged<int> onConfirm;
  final bool canScan;

  @override
  Widget build(BuildContext context) {
    var selected = 0;
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('选择支付方式'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('会员卡号：${member.cardNo}'),
              Text('会员姓名：${member.name}'),
              Text('手机号：${member.bindPhone}'),
              Text('充值金额：¥${depositYuan.toStringAsFixed(2)}'),
              Text('赠送金额：¥${giftYuan.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              for (final method in const [
                (1, '客人扫我-支付宝'),
                (2, '客人扫我-微信'),
                (5, '扫客人-支付宝'),
                (6, '扫客人-微信'),
              ])
                if (method.$1 < 5 || canScan)
                  ListTile(
                    dense: true,
                    title: Text(method.$2),
                    selected: selected == method.$1,
                    onTap: () => setState(() => selected = method.$1),
                  ),
              Text('实付金额：¥${depositYuan.toStringAsFixed(2)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: selected == 0
                ? null
                : () {
                    Navigator.pop(context);
                    onConfirm(selected);
                  },
            child: const Text('确认支付'),
          ),
        ],
      ),
    );
  }
}
