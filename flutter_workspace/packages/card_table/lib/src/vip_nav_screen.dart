import 'dart:async';

import 'package:card_table/src/vip_manager.dart';
import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/vip_pages.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';

typedef VipListCards = Future<Result<VipCardPage>> Function({
  required int pageNum,
  required int pageSize,
  String keyword,
  bool init,
});

typedef VipCreateCard = Future<Result<String>> Function({
  required String cardNo,
  required String typeId,
  required String levelId,
  required String name,
  String bindPhone,
  String bindAuthCode,
  String contactPhone,
});

typedef VipNewParams = Future<Result<VipNewCardParams>> Function();
typedef VipPhoneCards = Future<Result<List<VipCardRow>>> Function(String phone);
typedef VipMakeBegin = Future<Result<VipMakeCardBegin>> Function({
  required String cardNo,
  required String memberCardId,
});
typedef VipMakeEnd = Future<Result<void>> Function({
  required String cardNo,
  required String memberCardId,
});
typedef VipSendSms = Future<Result<void>> Function({
  required String phone,
  required int typeId,
});

final class _VipNavItem {
  const _VipNavItem(this.id, this.name, [this.children = const []]);

  final int id;
  final String name;
  final List<_VipNavItem> children;
}

const _nav = <_VipNavItem>[
  _VipNavItem(0, '返回'),
  _VipNavItem(1, '首页'),
  _VipNavItem(2, '会员管理', [
    _VipNavItem(21, '会员管理'),
    _VipNavItem(23, '企微会员'),
    _VipNavItem(22, '会员卡类型'),
    _VipNavItem(24, '积分设置'),
  ]),
  _VipNavItem(3, '业务配置', [
    _VipNavItem(31, '会员卡充值设置'),
    _VipNavItem(32, '会员卡号生成规则'),
    _VipNavItem(33, '会员卡结账规则'),
  ]),
  _VipNavItem(4, '报表管理', [
    _VipNavItem(41, '充值记录'),
    _VipNavItem(42, '滞留金管理'),
    _VipNavItem(43, '消费记录'),
    _VipNavItem(44, '扣款记录'),
    _VipNavItem(45, '积分记录'),
    _VipNavItem(46, '会员卡余额汇总表'),
    _VipNavItem(47, '会员消费排名表'),
    _VipNavItem(48, '客户关系维护表'),
    _VipNavItem(49, '注销记录表'),
    _VipNavItem(50, '更改等级记录表'),
  ]),
];

final class VipNavScreen extends StatefulWidget {
  const VipNavScreen({
    required this.onBack,
    required this.listCards,
    this.newCardParams,
    this.createCard,
    this.phoneCards,
    this.makeCardBegin,
    this.makeCardEnd,
    this.sendSms,
    this.pages = const VipPages(),
    super.key,
  });

  static const Key searchKey = Key('vip-nav-search');

  final VoidCallback onBack;
  final VipListCards listCards;
  final VipNewParams? newCardParams;
  final VipCreateCard? createCard;
  final VipPhoneCards? phoneCards;
  final VipMakeBegin? makeCardBegin;
  final VipMakeEnd? makeCardEnd;
  final VipSendSms? sendSms;
  final VipPages pages;

  @override
  State<VipNavScreen> createState() => _VipNavScreenState();
}

final class _VipNavScreenState extends State<VipNavScreen> {
  int _firstId = 2;
  int _secondId = 21;
  String _keyword = '';
  VipCardPage _page = const VipCardPage(total: 0);
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load(init: true));
  }

  _VipNavItem get _first =>
      _nav.firstWhere((item) => item.id == _firstId, orElse: () => _nav[2]);

  Future<void> _load({bool init = false}) async {
    setState(() => _busy = true);
    final result = await widget.listCards(
      pageNum: 1,
      pageSize: 20,
      keyword: _keyword,
      init: init,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _page = result.valueOrNull ?? const VipCardPage(total: 0);
    });
    if (result.failureOrNull != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failureOrNull!.safeMessage)),
      );
    }
  }

  void _tapFirst(_VipNavItem item) {
    if (item.id == 0) {
      widget.onBack();
      return;
    }
    setState(() {
      _firstId = item.id;
      _secondId = item.children.isEmpty ? item.id : item.children.first.id;
    });
    if (_secondId == 21 || item.id == 1) unawaited(_load());
  }

  void _tapSecond(_VipNavItem item) {
    setState(() => _secondId = item.id);
    if (item.id == 21) unawaited(_load());
  }

  Future<void> _openCreate() async {
    final pages = widget.pages;
    if (widget.createCard == null || !pages.canManageMembers) return;
    VipNewCardParams params = const VipNewCardParams();
    if (widget.newCardParams != null) {
      params = (await widget.newCardParams!()).valueOrNull ?? params;
    }
    if (!mounted || !pages.canManageMembers) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => _CreateCardDialog(
        params: params,
        createCard: widget.createCard!,
        canSubmit: () => pages.canManageMembers,
        sendSms: widget.sendSms,
      ),
    );
    if (created == true) unawaited(_load());
  }

  Future<void> _makeCard(VipCardRow row) async {
    final pages = widget.pages;
    if (!pages.canManageMembers) return;
    if (widget.makeCardBegin == null || widget.makeCardEnd == null) return;
    final cardNo = await showDialog<String>(
      context: context,
      builder: (context) => const _TextAskDialog(title: '制卡', label: '物理卡号'),
    );
    if (cardNo == null || cardNo.isEmpty || !mounted || !pages.canManageMembers)
      return;
    final begin = await widget.makeCardBegin!(
      cardNo: cardNo,
      memberCardId: row.id,
    );
    if (!mounted) return;
    if (begin.failureOrNull != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(begin.failureOrNull!.safeMessage)));
      return;
    }
    if (!pages.canManageMembers) return;
    final end = await widget.makeCardEnd!(cardNo: cardNo, memberCardId: row.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(end.failureOrNull?.safeMessage ?? '制卡成功')),
    );
    unawaited(_load());
  }

  Future<void> _cardAction(VipCardRow row, String action) async {
    final pages = widget.pages;
    Result<void>? result;
    if (action == 'deposit_pt' || action == 'subtract_pt') {
      final form = await showDialog<(int, String)>(
        context: context,
        builder: (context) =>
            _PointAmtDialog(title: action == 'deposit_pt' ? '充值积分' : '扣除积分'),
      );
      if (form == null) return;
      result = action == 'deposit_pt'
          ? await pages.depositPoints?.call(
              cardId: row.id,
              points: form.$1,
              remark: form.$2,
            )
          : await pages.subtractPoints?.call(
              cardId: row.id,
              points: form.$1,
              remark: form.$2,
            );
    } else if (action == 'edit') {
      final name = TextEditingController(text: row.name);
      final phone = TextEditingController(text: row.contactPhone);
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('编辑会员卡信息'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: '姓名'),
              ),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: '联系手机'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      result = await pages.saveMemberCard?.call(
        cardId: row.id,
        name: name.text.trim(),
        contactPhone: phone.text.trim(),
      );
    } else if (action == 'level') {
      final info = await pages.getLevelChange?.call(row.id);
      if (!mounted) return;
      if (info == null || info.failureOrNull != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(info?.failureOrNull?.safeMessage ?? '无法读取等级')),
        );
        return;
      }
      final data = info.valueOrNull!;
      var levelId = data.currentLevelId;
      final picked = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('更改会员卡等级'),
          content: DropdownButton<String>(
            isExpanded: true,
            value: data.levels.any((item) => item.id == levelId)
                ? levelId
                : data.levels.firstOrNull?.id,
            items: [
              for (final item in data.levels)
                DropdownMenuItem(value: item.id, child: Text(item.name)),
            ],
            onChanged: (value) => levelId = value ?? levelId,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, levelId),
              child: const Text('确认'),
            ),
          ],
        ),
      );
      if (picked == null || picked.isEmpty) return;
      result = await pages.changeLevel?.call(cardId: row.id, levelId: picked);
    } else if (action == 'phone') {
      final form = await showDialog<(String, String, List<int>)>(
        context: context,
        builder: (context) => _BindPhoneDialog(
          row: row,
          sendSms: widget.sendSms,
          checkSms: pages.checkSms,
          loadPrep: pages.getForBindPhone,
          loadOper: pages.getOperCard,
        ),
      );
      if (form == null) return;
      if (row.bindPhone.isNotEmpty) {
        result = await pages.changeBindPhone?.call(
          cardId: row.id,
          phone: form.$1,
          authCode: form.$2,
        );
      } else {
        result = await pages.bindPhone?.call(
          cardId: row.id,
          phone: form.$1,
          authCode: form.$2,
          smsTypeIds: form.$3,
        );
      }
    } else if (action == 'replace') {
      final cardNo = await showDialog<String>(
        context: context,
        builder: (context) => const _TextAskDialog(title: '换卡', label: '物理卡号'),
      );
      if (cardNo == null || cardNo.isEmpty) return;
      result = await pages.changePhysicalCard?.call(
        cardNo: cardNo,
        memberCardId: row.id,
      );
    } else if (action == 'return') {
      final remark = await showDialog<String>(
        context: context,
        builder: (context) => const _TextAskDialog(title: '退卡', label: '退卡理由'),
      );
      if (remark == null || remark.isEmpty) return;
      result = await pages.returnCard?.call(cardId: row.id, remark: remark);
    } else if (action == 'subtract') {
      final form = await showDialog<(String, String, int, int)>(
        context: context,
        builder: (context) =>
            _SubtractMoneyDialog(row: row, loadOper: pages.getOperCard),
      );
      if (form == null) return;
      result = await pages.subtractMoney?.call(
        cardId: row.id,
        storedAmt: form.$1,
        giftAmt: form.$2,
        points: form.$3,
        typeId: form.$4,
      );
    } else if (action == 'lock') {
      result = await pages.lockCard?.call(row.id);
    } else if (action == 'unlock') {
      result = await pages.unlockCard?.call(row.id);
    } else if (action == 'close') {
      final oper = await pages.getOperCard?.call(row.id);
      final snap = oper?.valueOrNull;
      result = await pages.closeCard?.call(
        cardId: row.id,
        storedBalance: snap?.storedBalance ?? row.balance,
        giftBalance: snap?.giftBalance ?? '0',
        points: int.tryParse(snap?.points ?? row.points) ?? 0,
      );
    } else if (action == 'loss') {
      result = row.statusName.contains('挂失')
          ? await pages.enableCard?.call(row.id)
          : await pages.lossCard?.call(row.id);
    }
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.failureOrNull?.safeMessage ?? '操作成功')),
    );
    if (result.failureOrNull == null) unawaited(_load());
  }

  Future<void> _openDeposit() async {
    final pages = widget.pages;
    if (pages.searchDepositCards == null || pages.depositMoney == null) return;
    final done = await showDialog<bool>(
      context: context,
      builder: (context) => _DepositDialog(pages: pages),
    );
    if (done == true) unawaited(_load());
  }

  Future<void> _openReadCard() async {
    final pages = widget.pages;
    if (pages.getCardIdFromReal == null) return;
    final cardNo = await showDialog<String>(
      context: context,
      builder: (context) => const _TextAskDialog(title: '读取卡信息', label: '物理卡号'),
    );
    if (cardNo == null || cardNo.isEmpty || !mounted) return;
    final digest = await showDialog<String>(
      context: context,
      builder: (context) =>
          const _TextAskDialog(title: '读取卡信息', label: '卡验证数据'),
    );
    if (digest == null || digest.isEmpty || !mounted) return;
    final id = await pages.getCardIdFromReal!(cardNo: cardNo, digest: digest);
    if (!mounted) return;
    if (id.failureOrNull != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(id.failureOrNull!.safeMessage)));
      return;
    }
    await _openDetail(
      VipCardRow(
        id: id.valueOrNull ?? '',
        name: '',
        statusName: '',
        bindPhone: '',
        contactPhone: '',
        sex: '',
        birthday: '',
        cardNo: cardNo,
        typeName: '',
        levelName: '',
        balance: '',
        points: '',
        salesName: '',
      ),
    );
  }

  Future<void> _openPaySerial() async {
    final pages = widget.pages;
    if (pages.validPaySerial == null) return;
    final done = await showDialog<VipCardRow>(
      context: context,
      builder: (context) => _PaySerialDialog(pages: pages),
    );
    if (done == null || !mounted || !pages.canManageMembers) return;
    await _makeCard(done);
  }

  Future<void> _openDetail(VipCardRow row) async {
    final pages = widget.pages;
    if (pages.getMemberDetail == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _MemberDetailDialog(row: row, pages: pages),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2362D5)),
        splashFactory: InkRipple.splashFactory,
      ),
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: const Color(0xff1F2A44),
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final item in _nav)
                        if (item.id != 0 || widget.pages.canConfigure)
                          TextButton(
                            onPressed: () => _tapFirst(item),
                            child: Text(
                              item.name,
                              style: TextStyle(
                                color: item.id == _firstId
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                            ),
                          ),
                      if (!widget.pages.canConfigure)
                        TextButton(
                          onPressed: widget.onBack,
                          child: const Text('退出登录'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (_first.children.isNotEmpty)
              ColoredBox(
                color: const Color(0xff2B3A5C),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final item in _first.children)
                        if (item.id != 32 || widget.pages.canConfigure)
                          TextButton(
                            onPressed: () => _tapSecond(item),
                            child: Text(
                              item.name,
                              style: TextStyle(
                                color: item.id == _secondId
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_secondId == 24) {
      return _PointSettingsView(pages: widget.pages);
    }
    if (_secondId == 31) {
      return _DepositRulesView(pages: widget.pages);
    }
    if (_secondId == 32) {
      if (!widget.pages.canConfigure)
        return const Center(child: Text('当前会员系统无此操作权限'));
      return _CardNoRuleView(pages: widget.pages);
    }
    if (_secondId == 33) {
      return _BillRulesView(pages: widget.pages);
    }
    if (_secondId == 23) {
      return _QwMembersView(pages: widget.pages);
    }
    if (_secondId == 22) {
      return _CardTypesView(pages: widget.pages);
    }
    if (_secondId == 42) {
      return _LateDepositView(pages: widget.pages);
    }
    final report = _reportKind(_secondId);
    if (report != null) {
      return _VipReportView(
        key: ValueKey(report),
        kind: report,
        title: _reportTitle(_secondId),
        pages: widget.pages,
      );
    }
    if (_secondId != 21 && _firstId != 1) {
      final name =
          [
            for (final item in _first.children)
              if (item.id == _secondId) item.name,
          ].firstOrNull ??
          _first.name;
      return Center(child: Text('$name 尚未接入'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: VipNavScreen.searchKey,
                  decoration: const InputDecoration(
                    hintText: '姓名/手机号(支持11位)/会员卡号',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _keyword = value,
                  onSubmitted: (_) => unawaited(_load()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _busy ? null : () => unawaited(_load()),
                child: const Text('查询'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        _keyword = '';
                        unawaited(_load(init: true));
                      },
                child: const Text('重置'),
              ),
              if (widget.pages.canManageMembers)
                TextButton(
                  onPressed: _busy ? null : _openCreate,
                  child: const Text('新增'),
                ),
              if (widget.pages.canConfigure)
                TextButton(
                  onPressed: _busy ? null : () => unawaited(_openDeposit()),
                  child: const Text('充值'),
                ),
              TextButton(
                onPressed: _busy ? null : () => unawaited(_openReadCard()),
                child: const Text('读取卡信息'),
              ),
              if (widget.pages.canManageMembers)
                TextButton(
                  onPressed: _busy ? null : () => unawaited(_openPaySerial()),
                  child: const Text('付款序列号制卡'),
                ),
            ],
          ),
        ),
        Expanded(
          child: _page.records.isEmpty
              ? const Center(child: Text('暂无数据'))
              : ListView(
                  children: [
                    for (final row in _page.records)
                      ListTile(
                        onTap: () => unawaited(_openDetail(row)),
                        title: Text(row.name.isEmpty ? row.cardNo : row.name),
                        subtitle: Text(
                          '${row.cardNo}  ${row.typeName}/${row.levelName}  ${row.statusName}  ￥${row.balance}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!row.hasPhysicalCard &&
                                widget.pages.canConfigure)
                              TextButton(
                                onPressed: () => unawaited(_makeCard(row)),
                                child: const Text('制卡'),
                              )
                            else if (row.hasPhysicalCard)
                              const Text('实体卡'),
                            PopupMenuButton<String>(
                              onSelected: (value) =>
                                  unawaited(_cardAction(row, value)),
                              itemBuilder: (context) =>
                                  [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('编辑会员卡信息'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'level',
                                      child: Text('更改会员卡等级'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'phone',
                                      child: Text('更改/绑定手机号'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'replace',
                                      child: Text('换卡'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'return',
                                      child: Text('退卡'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'subtract',
                                      child: Text('扣款'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'deposit_pt',
                                      child: Text('充值积分'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'subtract_pt',
                                      child: Text('扣除积分'),
                                    ),
                                    PopupMenuItem(
                                      value: row.statusName == '冻结'
                                          ? 'unlock'
                                          : 'lock',
                                      child: Text(
                                        row.statusName == '冻结' ? '解冻' : '冻结',
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'loss',
                                      child: Text('挂失/解除挂失'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'close',
                                      child: Text('注销'),
                                    ),
                                  ].where((item) {
                                    if (['lock', 'unlock'].contains(item.value))
                                      return true;
                                    if ([
                                      'subtract',
                                      'deposit_pt',
                                      'subtract_pt',
                                    ].contains(item.value))
                                      return widget.pages.canConfigure;
                                    return widget.pages.canManageMembers;
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

final class _CreateCardDialog extends StatefulWidget {
  const _CreateCardDialog({
    required this.params,
    required this.createCard,
    required this.canSubmit,
    this.sendSms,
  });

  final VipNewCardParams params;
  final VipCreateCard createCard;
  final bool Function() canSubmit;
  final VipSendSms? sendSms;

  @override
  State<_CreateCardDialog> createState() => _CreateCardDialogState();
}

final class _CreateCardDialogState extends State<_CreateCardDialog> {
  late final TextEditingController _cardNo = TextEditingController(
    text: widget.params.cardNo,
  );
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  String? _typeId;
  String? _levelId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _typeId = widget.params.types.firstOrNull?.id;
    _levelId = widget.params.types.firstOrNull?.levels.firstOrNull?.id;
  }

  @override
  void dispose() {
    _cardNo.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!widget.canSubmit()) return;
    final typeId = _typeId;
    final levelId = _levelId;
    if (_cardNo.text.trim().isEmpty || typeId == null || levelId == null) {
      return;
    }
    setState(() => _busy = true);
    final result = await widget.createCard(
      cardNo: _cardNo.text.trim(),
      typeId: typeId,
      levelId: levelId,
      name: _name.text.trim(),
      bindPhone: _phone.text.trim(),
      contactPhone: _phone.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.failureOrNull != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failureOrNull!.safeMessage)),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final levels = widget.params.types
        .where((item) => item.id == _typeId)
        .expand((item) => item.levels)
        .toList();
    return AlertDialog(
      title: const Text('新增会员卡'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _cardNo,
              decoration: const InputDecoration(labelText: '会员卡号'),
            ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '姓名'),
            ),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: '绑定手机'),
            ),
            DropdownButton<String>(
              isExpanded: true,
              value: _typeId,
              hint: const Text('卡类型'),
              items: [
                for (final item in widget.params.types)
                  DropdownMenuItem(value: item.id, child: Text(item.name)),
              ],
              onChanged: (value) => setState(() {
                _typeId = value;
                _levelId = widget.params.types
                    .where((item) => item.id == value)
                    .expand((item) => item.levels)
                    .firstOrNull
                    ?.id;
              }),
            ),
            DropdownButton<String>(
              isExpanded: true,
              value: _levelId,
              hint: const Text('卡等级'),
              items: [
                for (final item in levels)
                  DropdownMenuItem(value: item.id, child: Text(item.name)),
              ],
              onChanged: (value) => setState(() => _levelId = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('确认'),
        ),
      ],
    );
  }
}

final class _TextAskDialog extends StatefulWidget {
  const _TextAskDialog({required this.title, required this.label});

  final String title;
  final String label;

  @override
  State<_TextAskDialog> createState() => _TextAskDialogState();
}

final class _TextAskDialogState extends State<_TextAskDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(labelText: widget.label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('确认'),
        ),
      ],
    );
  }
}

VipReportKind? _reportKind(int id) => switch (id) {
  41 => VipReportKind.depositLog,
  43 => VipReportKind.consumeLog,
  44 => VipReportKind.subtractLog,
  45 => VipReportKind.pointLog,
  46 => VipReportKind.balance,
  47 => VipReportKind.consumeRank,
  48 => VipReportKind.customerRelation,
  49 => VipReportKind.logout,
  50 => VipReportKind.changeLevel,
  _ => null,
};

String _reportTitle(int id) => switch (id) {
  41 => '充值记录',
  43 => '消费记录',
  44 => '扣款记录',
  45 => '积分记录',
  46 => '会员卡余额汇总表',
  47 => '会员消费排名表',
  48 => '客户关系维护表',
  49 => '注销记录表',
  50 => '更改等级记录表',
  _ => '报表',
};

String _today() {
  final now = DateTime.now().subtract(const Duration(hours: 8));
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

Future<void> _toast(
  BuildContext context,
  Result<void> result, [
  String ok = '操作成功',
]) async {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result.failureOrNull?.safeMessage ?? ok)),
  );
}

final class _PointAmtDialog extends StatefulWidget {
  const _PointAmtDialog({required this.title});
  final String title;

  @override
  State<_PointAmtDialog> createState() => _PointAmtDialogState();
}

final class _PointAmtDialogState extends State<_PointAmtDialog> {
  final TextEditingController _points = TextEditingController();
  final TextEditingController _remark = TextEditingController();

  @override
  void dispose() {
    _points.dispose();
    _remark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _points,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '积分'),
          ),
          TextField(
            controller: _remark,
            decoration: const InputDecoration(labelText: '备注'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final points = int.tryParse(_points.text.trim()) ?? 0;
            if (points < 1) return;
            Navigator.pop(context, (points, _remark.text.trim()));
          },
          child: const Text('确认'),
        ),
      ],
    );
  }
}

final class _PointSettingsView extends StatefulWidget {
  const _PointSettingsView({required this.pages});
  final VipPages pages;

  @override
  State<_PointSettingsView> createState() => _PointSettingsViewState();
}

final class _PointSettingsViewState extends State<_PointSettingsView> {
  int _typeId = 1;
  final TextEditingController _amount = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final get = widget.pages.getPointRule;
    if (get == null) return;
    final result = await get();
    if (!mounted) return;
    final rule = result.valueOrNull;
    if (rule != null) {
      setState(() {
        _typeId = rule.typeId;
        _amount.text = rule.baseAmt == 0 ? '' : '${rule.baseAmt}';
      });
    }
  }

  Future<void> _save() async {
    final save = widget.pages.savePointRule;
    if (save == null) return;
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    final result = await save(
      typeId: _typeId,
      baseAmt: _typeId == 1 ? 0 : amount,
    );
    if (!mounted) return;
    await _toast(context, result, '保存成功');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('积分设置', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 12),
        const Text('赠送积分规则：'),
        RadioListTile<int>(
          title: const Text('不赠送积分'),
          value: 1,
          groupValue: _typeId,
          onChanged: widget.pages.canConfigure
              ? (value) => setState(() => _typeId = value ?? 1)
              : null,
        ),
        RadioListTile<int>(
          title: const Text('消费赠送积分'),
          value: 3,
          groupValue: _typeId,
          onChanged: widget.pages.canConfigure
              ? (value) => setState(() => _typeId = value ?? 3)
              : null,
        ),
        if (_typeId != 1) ...[
          Row(
            children: [
              Text(_typeId == 2 ? '充值' : '消费'),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _amount,
                  readOnly: !widget.pages.canConfigure,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              Text(_typeId == 2 ? '元送1积分' : '元储值金额送1积分'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _typeId == 2
                ? '说明: 不足的部分不会赠送，例如设置10元赠送1积分，充值999元则赠送99积分'
                : '说明: 不足的部分不会赠送，例如设置消费10元储值金额赠送1积分，消费999元储值金额则赠送99积分',
            style: const TextStyle(color: Colors.red),
          ),
        ],
        const SizedBox(height: 16),
        if (widget.pages.canConfigure)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(onPressed: _save, child: const Text('保存')),
          ),
      ],
    );
  }
}

final class _DepositRulesView extends StatefulWidget {
  const _DepositRulesView({required this.pages});
  final VipPages pages;

  @override
  State<_DepositRulesView> createState() => _DepositRulesViewState();
}

final class _DepositRulesViewState extends State<_DepositRulesView> {
  List<VipDepositGiftRule> _rows = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final list = widget.pages.listDepositRules;
    if (list == null) return;
    final result = await list(cardTypeId: '0');
    if (!mounted) return;
    setState(() => _rows = result.valueOrNull ?? const []);
  }

  Future<void> _edit([VipDepositGiftRule? row]) async {
    final save = widget.pages.saveDepositRule;
    if (save == null) return;
    final deposit = TextEditingController(
      text: row == null ? '' : (row.depositFen / 100).toStringAsFixed(2),
    );
    final gift = TextEditingController(
      text: row == null ? '' : (row.giftFen / 100).toStringAsFixed(2),
    );
    final points = TextEditingController(
      text: row == null || row.giftPoints == 0 ? '' : '${row.giftPoints}',
    );
    final remark = TextEditingController(text: row?.remark ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(row == null ? '新增' : '编辑'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: deposit,
              decoration: const InputDecoration(labelText: '充值金额'),
            ),
            TextField(
              controller: gift,
              decoration: const InputDecoration(labelText: '赠送金额'),
            ),
            TextField(
              controller: points,
              decoration: const InputDecoration(labelText: '赠送积分'),
            ),
            TextField(
              controller: remark,
              decoration: const InputDecoration(labelText: '充值规则'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final depositYuan = num.tryParse(deposit.text.trim()) ?? 0;
    final giftYuan = num.tryParse(gift.text.trim()) ?? 0;
    final result = await save(
      id: row?.id ?? '',
      depositFen: (depositYuan * 100).round(),
      giftFen: (giftYuan * 100).round(),
      giftPoints: int.tryParse(points.text.trim()) ?? 0,
      remark: remark.text.trim(),
    );
    if (!mounted) return;
    await _toast(context, result, row == null ? '新建成功' : '编辑成功');
    unawaited(_load());
  }

  Future<void> _delete(VipDepositGiftRule row) async {
    final del = widget.pages.deleteDepositRule;
    if (del == null) return;
    final result = await del(depositFen: row.depositFen, giftFen: row.giftFen);
    if (!mounted) return;
    await _toast(context, result, '删除成功');
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Text('会员卡充值设置', style: TextStyle(fontSize: 18)),
              const Spacer(),
              if (widget.pages.canConfigure)
                TextButton(
                  onPressed: () => unawaited(_edit()),
                  child: const Text('新增'),
                ),
              if (widget.pages.canConfigure)
                TextButton(
                  onPressed: _rows.isEmpty
                      ? null
                      : () => unawaited(_edit(_rows.first)),
                  child: const Text('编辑'),
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: Text('序号')),
              Expanded(child: Text('充值金额')),
              Expanded(child: Text('赠送金额')),
              Expanded(child: Text('操作')),
            ],
          ),
        ),
        Expanded(
          child: _rows.isEmpty
              ? const Center(child: Text('暂无数据'))
              : ListView.builder(
                  itemCount: _rows.length,
                  itemBuilder: (context, index) {
                    final row = _rows[index];
                    return ListTile(
                      title: Text('${row.depositFen}'),
                      subtitle: Text('赠送 ${row.giftFen}'),
                      leading: Text('${index + 1}'),
                      trailing: !widget.pages.canConfigure
                          ? null
                          : TextButton(
                              onPressed: () => unawaited(_delete(row)),
                              child: const Text('删除'),
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

final class _CardNoRuleView extends StatefulWidget {
  const _CardNoRuleView({required this.pages});
  final VipPages pages;

  @override
  State<_CardNoRuleView> createState() => _CardNoRuleViewState();
}

final class _CardNoRuleViewState extends State<_CardNoRuleView> {
  int _length = 5;
  final TextEditingController _prefix = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _prefix.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final get = widget.pages.getCardNoRule;
    if (get == null) return;
    final result = await get();
    final rule = result.valueOrNull;
    if (!mounted || rule == null) return;
    setState(() {
      _length = rule.numLength;
      _prefix.text = rule.prefix;
    });
  }

  Future<void> _save() async {
    final save = widget.pages.saveCardNoRule;
    if (save == null) return;
    if (_length <= 0) return;
    final result = await save(numLength: _length, prefix: _prefix.text.trim());
    if (!mounted) return;
    await _toast(context, result, '保存成功');
  }

  @override
  Widget build(BuildContext context) {
    final count = (_length - 1).clamp(0, 32);
    final begin = '${_prefix.text}${'0' * count}';
    final end = '${_prefix.text}${'9' * count}';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('会员卡号生成规则', style: TextStyle(fontSize: 18)),
        Row(
          children: [
            const Text('卡号编码长度：'),
            IconButton(
              onPressed: () =>
                  setState(() => _length = (_length - 1).clamp(1, 32)),
              icon: const Icon(Icons.remove),
            ),
            Text('$_length'),
            IconButton(
              onPressed: () => setState(() => _length += 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        TextField(
          controller: _prefix,
          maxLength: 4,
          decoration: const InputDecoration(labelText: '卡号前缀'),
          onChanged: (_) => setState(() {}),
        ),
        Text('卡号预览：${begin}0、${begin}1、${begin}2、${begin}3、${begin}5'),
        const Text('......'),
        Text('$end${end}3、$end${end}5、$end${end}6、$end${end}8、$end${end}9'),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(onPressed: _save, child: const Text('保存')),
        ),
      ],
    );
  }
}

final class _QwMembersView extends StatefulWidget {
  const _QwMembersView({required this.pages});
  final VipPages pages;

  @override
  State<_QwMembersView> createState() => _QwMembersViewState();
}

final class _QwMembersViewState extends State<_QwMembersView> {
  final _search = TextEditingController();
  String _keyword = '';
  int _pageNum = 1;
  int _request = 0;
  bool _busy = false;
  String? _error;
  VipReportPage _page = const VipReportPage();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final request = ++_request;
    final list = widget.pages.listQwMembers;
    setState(() {
      _busy = true;
      _error = null;
      _page = const VipReportPage();
    });
    Result<VipReportPage>? result;
    try {
      result = await list?.call(
        pageNum: _pageNum,
        pageSize: 10,
        keyword: _keyword,
      );
    } on Object {
      // Display only a safe local message, never raw transport data.
    }
    if (!mounted || request != _request) return;
    setState(() {
      _busy = false;
      _page = result?.valueOrNull ?? const VipReportPage();
      _error =
          result?.failureOrNull?.safeMessage ??
          (result?.valueOrNull == null ? '企微会员查询失败，请重试' : null);
    });
  }

  void _query({bool reset = false}) {
    if (reset) _search.clear();
    _keyword = _search.text;
    _pageNum = 1;
    unawaited(_load());
  }

  @override
  void dispose() {
    _request++;
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lastPage = _page.total > 0 ? (_page.total + 9) ~/ 10 : 1;
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('企微会员', style: TextStyle(fontSize: 18)),
        ),
        if (widget.pages.canConfigure)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      hintText: '昵称/手机号',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _query(),
                  ),
                ),
                TextButton(onPressed: _query, child: const Text('查询')),
                TextButton(
                  onPressed: () => _query(reset: true),
                  child: const Text('重置'),
                ),
              ],
            ),
          ),
        Expanded(
          child: _busy
              ? const Center(child: Text('正在查询…'))
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(
                        onPressed: () => unawaited(_load()),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _page.records.isEmpty
              ? const Center(child: Text('暂无数据'))
              : ListView.builder(
                  itemCount: _page.records.length,
                  itemBuilder: (context, index) {
                    final row = _page.records[index];
                    return ListTile(
                      leading: Text('${index + 1}'),
                      title: Text(row['n'] ?? ''),
                      subtitle: Text('${row['p'] ?? ''}  ${row['t'] ?? ''}'),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: _busy || _error != null || _pageNum <= 1
                    ? null
                    : () {
                        _pageNum--;
                        unawaited(_load());
                      },
                child: const Text('上一页'),
              ),
              Text(
                _busy
                    ? '第 $_pageNum 页 · 正在查询'
                    : _error != null
                    ? '第 $_pageNum 页 · 查询失败'
                    : '共 ${_page.total} 条 · 第 $_pageNum / $lastPage 页',
              ),
              TextButton(
                onPressed: _busy || _error != null || _pageNum >= lastPage
                    ? null
                    : () {
                        _pageNum++;
                        unawaited(_load());
                      },
                child: const Text('下一页'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _CardTypesView extends StatefulWidget {
  const _CardTypesView({required this.pages});
  final VipPages pages;

  @override
  State<_CardTypesView> createState() => _CardTypesViewState();
}

final class _CardTypesViewState extends State<_CardTypesView> {
  List<VipCardTypeRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final list = widget.pages.listCardTypes;
    if (list == null) return;
    final result = await list();
    if (!mounted) return;
    setState(() => _rows = result.valueOrNull ?? const []);
  }

  Future<void> _create() async {
    final create = widget.pages.createCardType;
    if (create == null) return;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _TextAskDialog(title: '新增', label: '会员卡类型'),
    );
    if (name == null || name.isEmpty) return;
    final result = await create(name: name, isDefault: _rows.isEmpty);
    if (!mounted) return;
    await _toast(context, result, '新建成功');
    unawaited(_load());
  }

  Future<void> _delete(VipCardTypeRow row) async {
    final del = widget.pages.deleteCardType;
    if (del == null) return;
    final result = await del(row.id);
    if (!mounted) return;
    await _toast(context, result, '删除成功');
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Text('会员卡类型', style: TextStyle(fontSize: 18)),
              const Spacer(),
              if (widget.pages.canConfigure)
                TextButton(onPressed: _create, child: const Text('新增')),
            ],
          ),
        ),
        Expanded(
          child: _rows.isEmpty
              ? const Center(child: Text('暂无数据'))
              : ListView(
                  children: [
                    for (final row in _rows)
                      ListTile(
                        title: Text(row.name),
                        subtitle: Text(
                          '等级 ${row.levelCount}  更新 ${row.updatedAt}  创建 ${row.createdAt}',
                        ),
                        trailing: !widget.pages.canConfigure
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => unawaited(
                                      showDialog<void>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('${row.name} 配置'),
                                          content: SizedBox(
                                            width: 640,
                                            height: 420,
                                            child: _TypeConfigView(
                                              pages: widget.pages,
                                              type: row,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: const Text('配置'),
                                  ),
                                  TextButton(
                                    onPressed: () => unawaited(_delete(row)),
                                    child: const Text('删除'),
                                  ),
                                ],
                              ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

final class _BillRulesView extends StatefulWidget {
  const _BillRulesView({required this.pages, this.cardTypeId});
  final VipPages pages;
  final String? cardTypeId;

  @override
  State<_BillRulesView> createState() => _BillRulesViewState();
}

final class _BillRulesViewState extends State<_BillRulesView> {
  List<VipCardTypeRow> _types = const [];
  String? _typeId;
  VipReportPage _page = const VipReportPage();
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _typeId = widget.cardTypeId;
    unawaited(_boot());
  }

  Future<void> _boot() async {
    if (_typeId == null) {
      final list = widget.pages.listCardTypes;
      if (list != null) {
        final result = await list();
        _types = result.valueOrNull ?? const [];
        _typeId = _types.firstOrNull?.id;
      }
    }
    await _load(init: true);
  }

  Future<void> _load({bool init = false}) async {
    final typeId = _typeId;
    final list = widget.pages.listBillRules;
    if (typeId == null || list == null) return;
    final result = await list(
      cardTypeId: typeId,
      init: init,
      keyword: _keyword,
    );
    if (!mounted) return;
    setState(() => _page = result.valueOrNull ?? const VipReportPage());
  }

  Future<void> _deleteSelected() async {
    final typeId = _typeId;
    final del = widget.pages.deleteBillRule;
    if (typeId == null || del == null) return;
    final ids = [
      for (final row in _page.records)
        if (row['id'] != null && row['id']!.isNotEmpty) row['id']!,
    ];
    if (ids.isEmpty) return;
    final result = await del(cardTypeId: typeId, ids: ids);
    if (!mounted) return;
    await _toast(context, result, '删除成功');
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '说明：未在表单中配置规则的商品, 不能使用当前会员卡结账！',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
        if (widget.cardTypeId == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _typeId,
              hint: const Text('卡类型'),
              items: [
                for (final item in _types)
                  DropdownMenuItem(value: item.id, child: Text(item.name)),
              ],
              onChanged: (value) {
                setState(() => _typeId = value);
                unawaited(_load(init: true));
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '商品名称/首字母',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _keyword = value,
                  onSubmitted: (_) => unawaited(_load()),
                ),
              ),
              TextButton(
                onPressed: () => unawaited(_load()),
                child: const Text('查询'),
              ),
              if (widget.pages.canConfigure)
                TextButton(
                  onPressed: _deleteSelected,
                  child: const Text('批量删除'),
                ),
            ],
          ),
        ),
        Expanded(
          child: _page.records.isEmpty
              ? const Center(child: Text('暂无数据'))
              : ListView(
                  children: [
                    for (final row in _page.records)
                      ListTile(
                        title: Text(row['n'] ?? ''),
                        subtitle: Text(
                          '${row['l'] ?? ''}  ${row['t'] ?? ''}  ${row['tn'] ?? ''}  ${row['p'] ?? ''}',
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

final class _LateDepositView extends StatefulWidget {
  const _LateDepositView({required this.pages});
  final VipPages pages;

  @override
  State<_LateDepositView> createState() => _LateDepositViewState();
}

final class _LateDepositViewState extends State<_LateDepositView> {
  String _keyword = '';
  List<VipLateDeposit> _rows = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final list = widget.pages.listLateDeposits;
    if (list == null) return;
    final result = await list(keyword: _keyword);
    if (!mounted) return;
    setState(() => _rows = result.valueOrNull ?? const []);
  }

  Future<void> _refund(VipLateDeposit row) async {
    final refund = widget.pages.refundLateDeposit;
    if (refund == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退款'),
        content: Text(
          '请检查以下退款信息，退款后不得撤销！\n当前卡号：${row.cardNo}  手机号：${row.phone}\n退款金额：￥${(row.amountFen / 100).toStringAsFixed(2)}',
        ),
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
    if (ok != true) return;
    final result = await refund(row.id);
    if (!mounted) return;
    await _toast(context, result, '退款成功');
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Text('滞留金管理', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '会员卡号/手机号/姓名',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _keyword = value,
                  onSubmitted: (_) => unawaited(_load()),
                ),
              ),
              TextButton(
                onPressed: () => unawaited(_load()),
                child: const Text('查询'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _rows.isEmpty
              ? const Center(child: Text('暂无滞留金记录'))
              : ListView(
                  children: [
                    for (final row in _rows)
                      ListTile(
                        title: Text('${row.cardNo}  ${row.name}'),
                        subtitle: Text(
                          '${row.phone}  ${row.channel}  ￥${(row.amountFen / 100).toStringAsFixed(2)}  ${row.operatedAt}',
                        ),
                        trailing: TextButton(
                          onPressed: () => unawaited(_refund(row)),
                          child: const Text('退款'),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

final class _VipReportView extends StatefulWidget {
  const _VipReportView({
    super.key,
    required this.kind,
    required this.title,
    required this.pages,
  });

  final VipReportKind kind;
  final String title;
  final VipPages pages;

  @override
  State<_VipReportView> createState() => _VipReportViewState();
}

final class _VipReportViewState extends State<_VipReportView> {
  late String _begin = _today();
  late String _end = _today();
  late final _beginInput = TextEditingController(text: _begin);
  late final _endInput = TextEditingController(text: _end);
  final _keywordInput = TextEditingController();
  final _salesInput = TextEditingController();
  final _salesFocus = FocusNode();
  String _salesEmpId = '';
  String _keyword = '';
  int _typeId = 0;
  int _pageNum = 1, _loadEpoch = 0;
  bool _exporting = false;
  VipReportPage _page = const VipReportPage();

  @override
  void dispose() {
    _loadEpoch++;
    _beginInput.dispose();
    _endInput.dispose();
    _keywordInput.dispose();
    _salesInput.dispose();
    _salesFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final epoch = ++_loadEpoch;
    final query = widget.pages.queryReport;
    if (query == null) return;
    final result = await query(
      kind: widget.kind,
      pageNum: _pageNum,
      pageSize: 20,
      beginDay: _begin,
      endDay: _end,
      keyword: _keyword,
      typeId: _typeId,
      salesEmpId: _salesEmpId,
    );
    if (!mounted || epoch != _loadEpoch) return;
    setState(() => _page = result.valueOrNull ?? const VipReportPage());
  }

  Future<void> _export() async {
    final export = widget.pages.exportReport;
    if (export == null || _exporting) return;
    final route = ModalRoute.of(context);
    bool current() =>
        mounted &&
        (route == null ||
            (route.isCurrent &&
                route.animation?.status != AnimationStatus.reverse));
    if (!current()) return;
    setState(() => _exporting = true);
    try {
      final result = await export(
        kind: widget.kind,
        pageNum: _pageNum,
        pageSize: 20,
        beginDay: _begin,
        endDay: _end,
        keyword: _keyword,
        typeId: _typeId,
        salesEmpId: _salesEmpId,
        canDispatch: current,
      );
      if (!mounted || !current()) return;
      await _toast(context, result, '导出成功');
    } on Object {
      if (mounted && current())
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('导出失败，请重试')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _print(Map<String, String> row) async {
    final reprint = widget.pages.reprintBill;
    final id = row['id'] ?? '';
    if (reprint == null || id.isEmpty) return;
    final result = await reprint(id);
    if (!mounted) return;
    await _toast(context, result, '重打小票成功');
  }

  @override
  Widget build(BuildContext context) {
    final printable =
        widget.pages.canConfigure &&
        (widget.kind == VipReportKind.depositLog ||
            widget.kind == VipReportKind.consumeLog ||
            widget.kind == VipReportKind.subtractLog ||
            widget.kind == VipReportKind.pointLog);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 18)),
              if (widget.kind != VipReportKind.balance)
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _beginInput,
                    decoration: const InputDecoration(
                      labelText: '开始日期',
                      isDense: true,
                    ),
                    onChanged: (value) => _begin = value,
                  ),
                ),
              if (widget.kind != VipReportKind.balance)
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _endInput,
                    decoration: const InputDecoration(
                      labelText: '结束日期',
                      isDense: true,
                    ),
                    onChanged: (value) => _end = value,
                  ),
                ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _keywordInput,
                  decoration: const InputDecoration(
                    hintText: '姓名/手机号/会员卡号',
                    isDense: true,
                  ),
                  onChanged: (value) => _keyword = value,
                  onSubmitted: (_) => unawaited(_load()),
                ),
              ),
              if (widget.kind == VipReportKind.customerRelation)
                SizedBox(
                  width: 260,
                  child: RawAutocomplete<CardEmployee>(
                    textEditingController: _salesInput,
                    focusNode: _salesFocus,
                    displayStringForOption: (employee) =>
                        '${employee.name} (${employee.code})',
                    optionsBuilder: (value) {
                      final key = value.text.trim().toLowerCase();
                      if (key.isEmpty)
                        return const Iterable<CardEmployee>.empty();
                      return widget.pages.salesEmployees.where(
                        (employee) => [
                          employee.name,
                          employee.code,
                          employee.namePy,
                        ].any((value) => value.toLowerCase().contains(key)),
                      );
                    },
                    onSelected: (employee) => _salesEmpId = employee.id,
                    fieldViewBuilder: (context, controller, focus, submit) =>
                        TextField(
                          controller: controller,
                          focusNode: focus,
                          decoration: const InputDecoration(
                            labelText: '开卡推荐人（工号/姓名/拼音）',
                            isDense: true,
                          ),
                          onChanged: (_) => _salesEmpId = '',
                          onSubmitted: (_) => submit(),
                        ),
                    optionsViewBuilder: (context, select, options) => Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        child: SizedBox(
                          width: 260,
                          height: 180,
                          child: ListView(
                            children: [
                              for (final employee in options)
                                ListTile(
                                  title: Text(
                                    '${employee.name} (${employee.code})',
                                  ),
                                  onTap: () => select(employee),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.kind == VipReportKind.depositLog ||
                  widget.kind == VipReportKind.subtractLog ||
                  widget.kind == VipReportKind.pointLog)
                DropdownButton<int>(
                  value: _typeId,
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('全部')),
                    if (widget.kind == VipReportKind.depositLog) ...[
                      const DropdownMenuItem(value: 1, child: Text('线上充值')),
                      const DropdownMenuItem(value: 2, child: Text('线下充值')),
                    ],
                    if (widget.kind == VipReportKind.subtractLog) ...[
                      const DropdownMenuItem(value: 1, child: Text('业务扣款')),
                      const DropdownMenuItem(value: 2, child: Text('充错扣款')),
                    ],
                    if (widget.kind == VipReportKind.pointLog) ...[
                      const DropdownMenuItem(value: 35, child: Text('扣除')),
                      const DropdownMenuItem(value: 36, child: Text('充值')),
                      const DropdownMenuItem(value: 50, child: Text('消费赠送')),
                    ],
                  ],
                  onChanged: (value) {
                    setState(() {
                      _typeId = value ?? 0;
                      _pageNum = 1;
                    });
                    unawaited(_load());
                  },
                ),
              FilledButton(
                onPressed: () {
                  _pageNum = 1;
                  unawaited(_load());
                },
                child: const Text('查询'),
              ),
              TextButton(
                onPressed: () {
                  _begin = _end = _today();
                  _beginInput.text = _begin;
                  _endInput.text = _end;
                  _keywordInput.clear();
                  _keyword = '';
                  _typeId = 0;
                  _pageNum = 1;
                  setState(() {});
                  unawaited(_load());
                },
                child: const Text('重置'),
              ),
              TextButton(
                onPressed: _exporting ? null : () => unawaited(_export()),
                child: Text(_exporting ? '正在导出…' : '导出'),
              ),
            ],
          ),
        ),
        if (_page.summary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _page.summary.entries
                  .map((e) => '${e.key}:${e.value}')
                  .join('  '),
            ),
          ),
        Expanded(
          child: _page.records.isEmpty
              ? const Center(child: Text('暂无数据'))
              : ListView(
                  children: [
                    for (final row in _page.records)
                      ListTile(
                        title: Text(row['n'] ?? row['cn'] ?? row['id'] ?? ''),
                        subtitle: Text(
                          row.entries
                              .where((e) => e.value.isNotEmpty)
                              .map((e) => '${e.key}:${e.value}')
                              .join('  '),
                        ),
                        trailing: printable
                            ? TextButton(
                                onPressed: () => unawaited(_print(row)),
                                child: const Text('打印小票'),
                              )
                            : null,
                      ),
                  ],
                ),
        ),
        if (![
          VipReportKind.consumeRank,
          VipReportKind.customerRelation,
          VipReportKind.logout,
        ].contains(widget.kind))
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: _pageNum <= 1
                    ? null
                    : () {
                        _pageNum--;
                        unawaited(_load());
                      },
                child: const Text('上一页'),
              ),
              Text('共 ${_page.total} 条 · 第 $_pageNum 页'),
              TextButton(
                onPressed: _pageNum * 20 >= _page.total
                    ? null
                    : () {
                        _pageNum++;
                        unawaited(_load());
                      },
                child: const Text('下一页'),
              ),
            ],
          ),
      ],
    );
  }
}

final class _TypeConfigView extends StatelessWidget {
  const _TypeConfigView({required this.pages, required this.type});

  final VipPages pages;
  final VipCardTypeRow type;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '卡等级'),
              Tab(text: '结账规则'),
              Tab(text: '积分规则'),
              Tab(text: '卡面'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TypeLevelsView(pages: pages, typeId: type.id),
                _BillRulesView(pages: pages, cardTypeId: type.id),
                _TypePointRulesView(pages: pages, typeId: type.id),
                _TypeCoversView(pages: pages),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _TypeLevelsView extends StatefulWidget {
  const _TypeLevelsView({required this.pages, required this.typeId});
  final VipPages pages;
  final String typeId;

  @override
  State<_TypeLevelsView> createState() => _TypeLevelsViewState();
}

final class _TypeLevelsViewState extends State<_TypeLevelsView> {
  VipCardTypeDetail? _detail;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final get = widget.pages.getCardTypeDetail;
    if (get == null) return;
    final result = await get(widget.typeId);
    if (!mounted) return;
    setState(() => _detail = result.valueOrNull);
  }

  Future<void> _add() async {
    final create = widget.pages.newLevel;
    if (create == null) return;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _TextAskDialog(title: '新增等级', label: '等级名称'),
    );
    if (name == null || name.isEmpty) return;
    final result = await create(typeId: widget.typeId, name: name);
    if (!mounted) return;
    await _toast(
      context,
      result.failureOrNull == null
          ? const Success(null)
          : FailureResult(result.failureOrNull!),
      '新建等级成功',
    );
    unawaited(_load());
  }

  Future<void> _delete(VipTypeLevel level) async {
    final del = widget.pages.deleteLevel;
    if (del == null) return;
    final result = await del(level.id);
    if (!mounted) return;
    await _toast(context, result, '删除成功');
    unawaited(_load());
  }

  Future<void> _rename(VipTypeLevel level) async {
    final rename = widget.pages.renameLevel;
    if (rename == null) return;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _TextAskDialog(title: '改名', label: '等级名称'),
    );
    if (name == null || name.isEmpty) return;
    final result = await rename(id: level.id, name: name);
    if (!mounted) return;
    await _toast(context, result, '保存成功');
    unawaited(_load());
  }

  Future<void> _saveExp(VipTypeLevel level, String raw) async {
    final save = widget.pages.changeLevelExp;
    if (save == null) return;
    final result = await save(
      id: level.id,
      expThreshold: int.tryParse(raw) ?? 0,
    );
    if (!mounted) return;
    await _toast(context, result, '保存成功');
  }

  Future<void> _toggleAuto(bool enable) async {
    if (enable) {
      final levels =
          _detail?.levels.where((item) => !item.isDefault).toList() ?? [];
      final result = await widget.pages.enableAutoUpgrade?.call(
        typeId: widget.typeId,
        levelIds: [for (final item in levels) item.id],
        expThresholds: [for (final item in levels) item.expThreshold],
      );
      if (!mounted || result == null) return;
      await _toast(context, result, '已开启自动升级');
    } else {
      final result = await widget.pages.disableAutoUpgrade?.call(widget.typeId);
      if (!mounted || result == null) return;
      await _toast(context, result, '已关闭自动升级');
    }
  }

  @override
  Widget build(BuildContext context) {
    final levels = _detail?.levels ?? const <VipTypeLevel>[];
    return Column(
      children: [
        Row(
          children: [
            TextButton(onPressed: _add, child: const Text('新增等级')),
            TextButton(
              onPressed: () => unawaited(_toggleAuto(true)),
              child: const Text('开启自动升级'),
            ),
            TextButton(
              onPressed: () => unawaited(_toggleAuto(false)),
              child: const Text('关闭自动升级'),
            ),
          ],
        ),
        Expanded(
          child: levels.isEmpty
              ? const Center(child: Text('暂无等级'))
              : ListView(
                  children: [
                    for (final level in levels)
                      ListTile(
                        title: Text(level.name),
                        subtitle: Text(
                          '经验 ${level.expThreshold}  ${level.couponName}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => unawaited(_rename(level)),
                              child: const Text('改名'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final raw = await showDialog<String>(
                                  context: context,
                                  builder: (context) => const _TextAskDialog(
                                    title: '经验阀值',
                                    label: '经验',
                                  ),
                                );
                                if (raw == null) return;
                                await _saveExp(level, raw);
                                unawaited(_load());
                              },
                              child: const Text('经验'),
                            ),
                            TextButton(
                              onPressed: () => unawaited(_delete(level)),
                              child: const Text('删除'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

final class _TypePointRulesView extends StatefulWidget {
  const _TypePointRulesView({required this.pages, required this.typeId});
  final VipPages pages;
  final String typeId;

  @override
  State<_TypePointRulesView> createState() => _TypePointRulesViewState();
}

final class _TypePointRulesViewState extends State<_TypePointRulesView> {
  List<VipTypePointRule> _rows = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final list = widget.pages.listTypePointRules;
    if (list == null) return;
    final result = await list(widget.typeId);
    if (!mounted) return;
    setState(() => _rows = result.valueOrNull ?? const []);
  }

  Future<void> _add() async {
    final save = widget.pages.saveTypePointRule;
    if (save == null) return;
    final amt = await showDialog<String>(
      context: context,
      builder: (context) =>
          const _TextAskDialog(title: '新增积分规则', label: '门槛金额(元)'),
    );
    if (amt == null) return;
    final yuan = num.tryParse(amt) ?? 0;
    final result = await save(
      cardTypeId: widget.typeId,
      cardLevelId: '0',
      baseAmtFen: (yuan * 100).round(),
    );
    if (!mounted) return;
    await _toast(context, result, '新建成功');
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: _add, child: const Text('新增')),
        ),
        Expanded(
          child: _rows.isEmpty
              ? const Center(child: Text('暂无数据'))
              : ListView(
                  children: [
                    for (final row in _rows)
                      ListTile(
                        title: Text(row.levelName),
                        subtitle: Text(
                          '${row.ruleName}  ${(row.baseAmtFen / 100).toStringAsFixed(2)}',
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final del = widget.pages.deleteTypePointRule;
                            if (del == null) return;
                            final result = await del(
                              id: row.id,
                              cardTypeId: widget.typeId,
                            );
                            if (!mounted) return;
                            await _toast(context, result, '删除成功');
                            unawaited(_load());
                          },
                          child: const Text('删除'),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

final class _TypeCoversView extends StatefulWidget {
  const _TypeCoversView({required this.pages});
  final VipPages pages;

  @override
  State<_TypeCoversView> createState() => _TypeCoversViewState();
}

final class _TypeCoversViewState extends State<_TypeCoversView> {
  List<VipCover> _rows = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final list = widget.pages.listCovers;
    if (list == null) return;
    final result = await list();
    if (!mounted) return;
    setState(() => _rows = result.valueOrNull ?? const []);
  }

  Future<void> _add() async {
    final add = widget.pages.newCover;
    if (add == null) return;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _TextAskDialog(title: '新增卡面', label: '图片文件名'),
    );
    if (name == null || name.isEmpty) return;
    final result = await add(name);
    if (!mounted) return;
    await _toast(context, result, '新增成功');
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: _add, child: const Text('新增')),
        ),
        Expanded(
          child: _rows.isEmpty
              ? const Center(child: Text('暂无自定义卡面'))
              : ListView(
                  children: [
                    for (final row in _rows)
                      ListTile(
                        title: Text(row.picName),
                        subtitle: Text(row.url),
                        trailing: TextButton(
                          onPressed: () async {
                            final del = widget.pages.deleteCover;
                            if (del == null) return;
                            final result = await del(row.id);
                            if (!mounted) return;
                            await _toast(context, result, '删除成功');
                            unawaited(_load());
                          },
                          child: const Text('删除'),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

final class _BindPhoneDialog extends StatefulWidget {
  const _BindPhoneDialog({
    required this.row,
    this.sendSms,
    this.checkSms,
    this.loadPrep,
    this.loadOper,
  });

  final VipCardRow row;
  final VipSendSms? sendSms;
  final VipCheckSms? checkSms;
  final VipGetBindPrep? loadPrep;
  final VipGetOperCard? loadOper;

  @override
  State<_BindPhoneDialog> createState() => _BindPhoneDialogState();
}

final class _BindPhoneDialogState extends State<_BindPhoneDialog> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _code = TextEditingController();
  List<VipCardLevel> _sms = const [];
  final Set<String> _checked = {};

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    if (widget.row.bindPhone.isEmpty && widget.loadPrep != null) {
      final prep = await widget.loadPrep!(widget.row.id);
      final data = prep.valueOrNull;
      if (!mounted || data == null) return;
      setState(() {
        _sms = data.smsTypes;
        _checked.addAll(data.registeredSmsTypeIds.map((id) => '$id'));
      });
    }
  }

  Future<void> _send() async {
    final phone = _phone.text.trim();
    if (phone.length != 11 || widget.sendSms == null) return;
    final typeId = widget.row.bindPhone.isEmpty ? 103 : 102;
    final result = await widget.sendSms!(phone: phone, typeId: typeId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.failureOrNull?.safeMessage ?? '验证码发送成功')),
    );
  }

  Future<void> _submit() async {
    final phone = _phone.text.trim();
    if (phone.length != 11) return;
    var auth = '';
    final code = _code.text.trim();
    if (code == 'NO_NEED_VALIDATE') {
      auth = '';
    } else if (widget.checkSms != null && code.length == 5) {
      final checked = await widget.checkSms!(phone: phone, code: code);
      if (!mounted) return;
      if (checked.failureOrNull != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(checked.failureOrNull!.safeMessage)),
        );
        return;
      }
      auth = checked.valueOrNull ?? '';
    } else if (code.isNotEmpty) {
      return;
    }
    Navigator.pop(context, (
      phone,
      auth,
      [for (final id in _checked) int.tryParse(id) ?? 0],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('更改/绑定手机号'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: '手机号'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    decoration: const InputDecoration(labelText: '验证码'),
                  ),
                ),
                TextButton(onPressed: _send, child: const Text('发送验证码')),
              ],
            ),
            if (widget.row.bindPhone.isEmpty)
              Wrap(
                children: [
                  for (final item in _sms)
                    FilterChip(
                      label: Text(item.name),
                      selected: _checked.contains(item.id),
                      onSelected: (on) => setState(() {
                        if (on) {
                          _checked.add(item.id);
                        } else {
                          _checked.remove(item.id);
                        }
                      }),
                    ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('确认')),
      ],
    );
  }
}

final class _SubtractMoneyDialog extends StatefulWidget {
  const _SubtractMoneyDialog({required this.row, this.loadOper});
  final VipCardRow row;
  final VipGetOperCard? loadOper;

  @override
  State<_SubtractMoneyDialog> createState() => _SubtractMoneyDialogState();
}

final class _SubtractMoneyDialogState extends State<_SubtractMoneyDialog> {
  VipOperCard? _oper;
  final TextEditingController _amt = TextEditingController();
  final TextEditingController _gift = TextEditingController(text: '0');
  final TextEditingController _points = TextEditingController(text: '0');
  int _typeId = 1;

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  @override
  void dispose() {
    _amt.dispose();
    _gift.dispose();
    _points.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final load = widget.loadOper;
    if (load == null) return;
    final result = await load(widget.row.id);
    if (!mounted) return;
    setState(() => _oper = result.valueOrNull);
  }

  @override
  Widget build(BuildContext context) {
    final oper = _oper;
    return AlertDialog(
      title: const Text('扣款'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (oper != null)
              Text(
                '${oper.cardNo}  ${oper.name}\n储值 ${oper.storedBalance}  赠送 ${oper.giftBalance}  积分 ${oper.points}',
              ),
            RadioListTile<int>(
              title: const Text('业务扣款'),
              value: 1,
              groupValue: _typeId,
              onChanged: (value) => setState(() => _typeId = value ?? 1),
            ),
            RadioListTile<int>(
              title: const Text('充错扣款'),
              value: 2,
              groupValue: _typeId,
              onChanged: (value) => setState(() => _typeId = value ?? 2),
            ),
            TextField(
              controller: _amt,
              decoration: const InputDecoration(labelText: '储值金额'),
            ),
            TextField(
              controller: _gift,
              decoration: const InputDecoration(labelText: '赠送金额'),
            ),
            TextField(
              controller: _points,
              decoration: InputDecoration(
                labelText: _typeId == 1 ? '本次消费赠送积分' : '扣除积分',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (_amt.text.trim().isEmpty) return;
            Navigator.pop(context, (
              _amt.text.trim(),
              _gift.text.trim().isEmpty ? '0' : _gift.text.trim(),
              int.tryParse(_points.text.trim()) ?? 0,
              _typeId,
            ));
          },
          child: const Text('确认'),
        ),
      ],
    );
  }
}

final class _DepositDialog extends StatefulWidget {
  const _DepositDialog({required this.pages});
  final VipPages pages;

  @override
  State<_DepositDialog> createState() => _DepositDialogState();
}

final class _DepositDialogState extends State<_DepositDialog> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _stored = TextEditingController();
  final TextEditingController _gift = TextEditingController(text: '0');
  final TextEditingController _remark = TextEditingController();
  List<Map<String, String>> _hits = const [];
  String? _cardId;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _stored.dispose();
    _gift.dispose();
    _remark.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final phone = _phone.text.trim();
    final search = widget.pages.searchDepositCards;
    if (search == null || (phone.length != 4 && phone.length != 11)) return;
    final result = await search(phone);
    if (!mounted) return;
    setState(() {
      _hits = result.valueOrNull?.records ?? const [];
      _cardId = _hits.firstOrNull?['id'];
    });
  }

  Future<void> _submit() async {
    final id = _cardId;
    final deposit = widget.pages.depositMoney;
    if (id == null || deposit == null || _stored.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final result = await deposit(
      cardId: id,
      storedAmt: _stored.text.trim(),
      giftAmt: _gift.text.trim().isEmpty ? '0' : _gift.text.trim(),
      remark: _remark.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.failureOrNull != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failureOrNull!.safeMessage)),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('充值'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phone,
                    decoration: const InputDecoration(
                      labelText: '手机号后四位或完整手机号',
                    ),
                  ),
                ),
                TextButton(onPressed: _search, child: const Text('查询')),
              ],
            ),
            if (_hits.isNotEmpty)
              DropdownButton<String>(
                isExpanded: true,
                value: _cardId,
                items: [
                  for (final hit in _hits)
                    DropdownMenuItem(
                      value: hit['id'],
                      child: Text(
                        '${hit['n'] ?? ''} ${hit['cn'] ?? hit['id'] ?? ''}',
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _cardId = value),
              ),
            TextField(
              controller: _stored,
              decoration: const InputDecoration(labelText: '有价金额'),
            ),
            TextField(
              controller: _gift,
              decoration: const InputDecoration(labelText: '赠送金额'),
            ),
            TextField(
              controller: _remark,
              decoration: const InputDecoration(labelText: '备注'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('关闭'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('确认'),
        ),
      ],
    );
  }
}

final class _PaySerialDialog extends StatefulWidget {
  const _PaySerialDialog({required this.pages});
  final VipPages pages;

  @override
  State<_PaySerialDialog> createState() => _PaySerialDialogState();
}

final class _PaySerialDialogState extends State<_PaySerialDialog> {
  final TextEditingController _code = TextEditingController();
  List<Map<String, String>> _rows = const [];

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final code = _code.text.trim();
    if (code.length != 6) return;
    final valid = widget.pages.validPaySerial;
    final list = widget.pages.listPhonePayCards;
    if (valid == null || list == null) return;
    final serial = await valid(code);
    if (!mounted) return;
    if (serial.failureOrNull != null || serial.valueOrNull == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(serial.failureOrNull?.safeMessage ?? '序列号无效')),
      );
      return;
    }
    final page = await list(
      phone: serial.valueOrNull!.phone,
      authCode: serial.valueOrNull!.authCode,
    );
    if (!mounted) return;
    setState(() => _rows = page.valueOrNull?.records ?? const []);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('付款序列号制卡'),
      content: SizedBox(
        width: 420,
        height: 320,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    decoration: const InputDecoration(labelText: '六位付款序列号'),
                  ),
                ),
                TextButton(onPressed: _search, child: const Text('搜索')),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final row in _rows)
                    ListTile(
                      title: Text(row['c'] ?? row['id'] ?? ''),
                      subtitle: Text('${row['n'] ?? ''} ${row['p'] ?? ''}'),
                      trailing: TextButton(
                        onPressed: row['r'] == '1'
                            ? null
                            : () => Navigator.pop(
                                context,
                                VipCardRow(
                                  id: row['id'] ?? '',
                                  name: row['n'] ?? '',
                                  statusName: '',
                                  bindPhone: row['p'] ?? '',
                                  contactPhone: '',
                                  sex: '',
                                  birthday: '',
                                  cardNo: row['c'] ?? '',
                                  typeName: row['ct'] ?? '',
                                  levelName: row['cl'] ?? '',
                                  balance: '',
                                  points: '',
                                  salesName: '',
                                ),
                              ),
                        child: const Text('制卡'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

final class _MemberDetailDialog extends StatefulWidget {
  const _MemberDetailDialog({required this.row, required this.pages});
  final VipCardRow row;
  final VipPages pages;

  @override
  State<_MemberDetailDialog> createState() => _MemberDetailDialogState();
}

final class _MemberDetailDialogState extends State<_MemberDetailDialog> {
  Map<String, String> _detail = const {};
  List<Map<String, String>> _rows = const [];
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final detail = await widget.pages.getMemberDetail?.call(
      cardId: widget.row.id,
      phone: widget.row.bindPhone,
    );
    if (!mounted) return;
    setState(() => _detail = detail?.valueOrNull ?? const {});
    await _loadTab(0);
  }

  Future<void> _loadTab(int tab) async {
    setState(() => _tab = tab);
    final phone = _detail['bind_phone'] ?? widget.row.bindPhone;
    final Result<VipMapPage>? result = switch (tab) {
      0 => await widget.pages.getMemberCards?.call(
        cardId: widget.row.id,
        phone: phone,
      ),
      1 => await widget.pages.getBalanceLogs?.call(
        cardId: widget.row.id,
        phone: phone,
      ),
      2 => await widget.pages.getMemberCoupons?.call(phone: phone),
      3 => await widget.pages.getMemberWines?.call(phone: phone),
      _ => await widget.pages.getTopProducts?.call(
        cardId: widget.row.id,
        phone: phone,
      ),
    };
    if (!mounted) return;
    setState(() => _rows = result?.valueOrNull?.records ?? const []);
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['会员卡详情', '交易明细', '优惠券', '剩余存酒', '消费喜好'];
    return AlertDialog(
      title: const Text('会员详情'),
      content: SizedBox(
        width: 520,
        height: 420,
        child: Column(
          children: [
            Text(_detail.entries.map((e) => '${e.key}:${e.value}').join('  ')),
            Wrap(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  TextButton(
                    onPressed: () => unawaited(_loadTab(i)),
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        fontWeight: i == _tab
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: _rows.isEmpty
                  ? const Center(child: Text('暂无数据'))
                  : ListView(
                      children: [
                        for (final row in _rows)
                          ListTile(
                            title: Text(
                              row['n'] ?? row['cn'] ?? row['id'] ?? '',
                            ),
                            subtitle: Text(
                              row.entries
                                  .where((e) => e.value.isNotEmpty)
                                  .map((e) => '${e.key}:${e.value}')
                                  .join('  '),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
