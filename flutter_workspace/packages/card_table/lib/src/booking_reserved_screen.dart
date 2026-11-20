import 'dart:async';

import 'package:card_table/src/account_password_screen.dart';
import 'package:card_table/src/booking_card_api.dart';
import 'package:card_table/src/card_table_screen.dart' show BookingBookDetailLoader;
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foundation/foundation.dart';

const Color _bgDark = BookingTokens.surfaceCanvas;
const Color _cardDark = BookingTokens.surfaceFooter;
const Color _tableHeaderBg = BookingTokens.tableHeaderBg;
const Color _borderDark = BookingTokens.tableBorder;
const Color _primaryBlue = BookingTokens.brandPrimary;
const Color _textPrimary = BookingTokens.textPrimary;
const Color _textMuted = BookingTokens.textMuted;

/// 独立预留管理页 (S1.P2.T01 ~ S1.P2.T03)
final class BookingReservedScreen extends StatefulWidget {
  const BookingReservedScreen({
    required this.onLoadReservedList,
    this.onCancelReservedInfo,
    this.onSingleAllocation,
    this.onManyAllocation,
    this.onBookingCardWrite,
    this.onLoadBookDetail,
    this.onChangePassword,
    this.onLogout,
    this.onBackToCardMachine,
    this.userName,
    this.employeeId,
    super.key,
  });

  static const Key tabTodayKey = Key('reserved-tab-today');
  static const Key tabFutureKey = Key('reserved-tab-future');
  static const Key searchKey = Key('reserved-search-input');
  static const Key searchBtnKey = Key('reserved-search-btn');
  static const Key resetBtnKey = Key('reserved-reset-btn');
  static const Key addBtnKey = Key('reserved-add-btn');
  static const Key deleteBtnKey = Key('reserved-delete-btn');
  static const Key manyAllocationBtnKey = Key('reserved-many-allocation-btn');
  static const Key backCardMachineKey = Key('reserved-back-card-machine');
  static const Key accountMenuKey = Key('reserved-account-menu');
  static const Key changePasswordKey = Key('reserved-change-password');
  static const Key logoutKey = Key('reserved-logout');

  final Future<Result<List<BookingReservedItem>>> Function({
    required bool isToday,
    int futureType,
  }) onLoadReservedList;
  final Future<Result<void>> Function(List<String> bookIds)? onCancelReservedInfo;
  final Future<Result<void>> Function({
    required String id,
    required String seatId,
  })? onSingleAllocation;
  final Future<Result<void>> Function(List<String> bookIds)? onManyAllocation;
  final BookingCardWrite? onBookingCardWrite;
  final BookingBookDetailLoader? onLoadBookDetail;
  final ChangePasswordSubmit? onChangePassword;
  final VoidCallback? onLogout;
  final VoidCallback? onBackToCardMachine;
  final String? userName;
  final String? employeeId;

  @override
  State<BookingReservedScreen> createState() => _BookingReservedScreenState();
}

final class _BookingReservedScreenState extends State<BookingReservedScreen> {
  int _activeTabIndex = 0; // 0: 当日预留, 1: 其它预留
  int _futureTypeId = 1; // 1: 明天, 2: 未来7天, 3: 全部
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _verticalScroll = ScrollController();

  bool _loading = false;
  int _loadGeneration = 0;
  int _editGeneration = 0;
  List<BookingReservedItem> _allItems = <BookingReservedItem>[];
  List<BookingReservedItem> _displayItems = <BookingReservedItem>[];
  final Set<String> _selectedIds = <String>{};
  AppFailure? _failure;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchData());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _horizontalScroll.dispose();
    _verticalScroll.dispose();
    super.dispose();
  }

  bool get _isToday => _activeTabIndex == 0;

  Future<void> _fetchData() async {
    _editGeneration++;
    final generation = ++_loadGeneration;
    final isToday = _isToday;
    final futureType = _futureTypeId;
    setState(() {
      _loading = true;
      _failure = null;
      _allItems = [];
      _displayItems = [];
      _selectedIds.clear();
    });
    try {
      final res = await widget.onLoadReservedList(
        isToday: isToday,
        futureType: futureType,
      );
      if (!mounted || generation != _loadGeneration) return;
      if (res.failureOrNull case final f?) {
        setState(() {
          _loading = false;
          _failure = f;
        });
        return;
      }
      final list = res.valueOrNull ?? <BookingReservedItem>[];
      setState(() {
        _loading = false;
        _allItems = list;
        _selectedIds.clear();
        _applyFilter();
      });
    } catch (_) {
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _loading = false;
          _failure = const AppFailure(
            kind: FailureKind.unknown,
            code: 'reserved.fetch_failed',
            safeMessage: '获取预留数据失败',
          );
        });
      }
    }
  }

  void _applyFilter() {
    final kw = _searchCtrl.text.trim().toLowerCase();
    if (kw.isEmpty) {
      _displayItems = List.of(_allItems);
    } else {
      _displayItems = _allItems.where((item) {
        return item.orderPersonName.toLowerCase().contains(kw) ||
            item.orderPersonCode.toLowerCase().contains(kw) ||
            item.customerName.toLowerCase().contains(kw) ||
            item.customerPhone.toLowerCase().contains(kw) ||
            item.seatName.toLowerCase().contains(kw);
      }).toList();
    }
  }

  void _onSearch() {
    setState(() {
      _applyFilter();
    });
  }

  void _onReset() {
    _searchCtrl.clear();
    setState(() {
      _applyFilter();
    });
  }

  void _onSwitchTab(int index) {
    if (_activeTabIndex == index) return;
    setState(() {
      _activeTabIndex = index;
      if (_activeTabIndex == 1) {
        _futureTypeId = 1;
      }
    });
    unawaited(_fetchData());
  }

  void _onChangeDateFilter(int typeId) {
    if (_futureTypeId == typeId) return;
    setState(() {
      _futureTypeId = typeId;
    });
    unawaited(_fetchData());
  }

  void _toggleSelectAll(bool? val) {
    setState(() {
      if (val == true) {
        _selectedIds.addAll(_displayItems.map((e) => e.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelectItem(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _onDeleteSelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请选择需要删除的列表！'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardDark,
        title: const Text('删除预留', style: TextStyle(color: _textPrimary)),
        content: Text(
          '是否确认删除选中的 ${_selectedIds.length} 条预留信息？',
          style: const TextStyle(color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final deleter = widget.onCancelReservedInfo;
    if (deleter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未配置删除接口')),
      );
      return;
    }
    final res = await deleter(_selectedIds.toList());
    if (!mounted) return;
    if (res.failureOrNull == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('删除成功'),
          backgroundColor: Colors.green,
        ),
      );
      _selectedIds.clear();
      unawaited(_fetchData());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failureOrNull?.safeMessage ?? '删除失败'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _onOneKeyAllocation() async {
    final allocator = widget.onManyAllocation;
    if (allocator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未配置一键分配接口')),
      );
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先勾选需要分配的预留信息'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final res = await allocator(_selectedIds.toList());
    if (!mounted) return;
    if (res.failureOrNull == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('分配成功'),
          backgroundColor: Colors.green,
        ),
      );
      unawaited(_fetchData());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failureOrNull?.safeMessage ?? '一键分配失败'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _onSingleAllocation(BookingReservedItem item) async {
    final allocator = widget.onSingleAllocation;
    if (allocator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未配置单台分配接口')),
      );
      return;
    }
    final seatCtrl = TextEditingController(text: item.seatId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardDark,
        title: Text(
          '分配卡台 - ${item.customerName}',
          style: const TextStyle(color: _textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('意向卡台: ${item.seatName}', style: const TextStyle(color: _textMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: seatCtrl,
              decoration: const InputDecoration(
                labelText: '卡台ID / 编号',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: _textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认分配', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final res = await allocator(id: item.id, seatId: seatCtrl.text.trim());
    if (!mounted) return;
    if (res.failureOrNull == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('分配成功'), backgroundColor: Colors.green),
      );
      unawaited(_fetchData());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failureOrNull?.safeMessage ?? '分配失败'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _onAddNewReservation() async {
    final writer = widget.onBookingCardWrite;
    if (writer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未配置预留写入接口')),
      );
      return;
    }
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '2');
    final minConsumeCtrl = TextEditingController(text: '0');
    final arriveCtrl = TextEditingController();
    final remarkCtrl = TextEditingController();
    var autoSendMsg = 2;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(ctx).pop(false),
            const SingleActivator(LogicalKeyboardKey.enter): () =>
                Navigator.of(ctx).pop(true),
            const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
                Navigator.of(ctx).pop(true),
          },
          child: AlertDialog(
            backgroundColor: BookingTokens.surfaceDialog,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0x6632B9FF)),
            ),
            title: const Text('新增预留', style: TextStyle(color: _textPrimary)),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: '客人姓名',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: _textPrimary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '客人电话',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: _textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          '是否发送短信：',
                          style: TextStyle(color: _textMuted, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('否'),
                          selected: autoSendMsg == 2,
                          onSelected: (_) =>
                              setDialogState(() => autoSendMsg = 2),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('是'),
                          selected: autoSendMsg == 1,
                          onSelected: (_) =>
                              setDialogState(() => autoSendMsg = 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: arriveCtrl,
                      decoration: const InputDecoration(
                        labelText: '预定到达时间 (如 2100)',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: _textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final slot in const [
                          ('20:00', '2000'),
                          ('21:00', '2100'),
                          ('22:00', '2200'),
                          ('23:00', '2300'),
                        ])
                          ActionChip(
                            label: Text(slot.$1),
                            onPressed: () =>
                                setDialogState(() => arriveCtrl.text = slot.$2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: countCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '人数 (1-100)',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: _textPrimary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: minConsumeCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '最低消费(元)',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: _textPrimary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remarkCtrl,
                      decoration: const InputDecoration(
                        labelText: '备注',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: _textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('取消', style: TextStyle(color: _textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  '提交预留',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final cnt = (int.tryParse(countCtrl.text.trim()) ?? 2).clamp(1, 100);
    final res = await writer(
      action: BookingCardWriteAction.createReserve,
      seatId: '',
      fields: {
        'customer_name': nameCtrl.text.trim(),
        'customer_phone': phoneCtrl.text.trim(),
        'auto_send_msg': autoSendMsg,
        'exp_arrive_time': arriveCtrl.text.trim(),
        'customer_exp_cnt': cnt,
        'exp_min_csm_amt': num.tryParse(minConsumeCtrl.text.trim()) ?? 0,
        'remark': remarkCtrl.text.trim(),
      },
    );
    if (!mounted) return;
    if (res.failureOrNull == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新增预留成功'), backgroundColor: Colors.green),
      );
      unawaited(_fetchData());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failureOrNull?.safeMessage ?? '新增预留失败'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _onEditReservation(BookingReservedItem item) async {
    final generation = ++_editGeneration;
    final writer = widget.onBookingCardWrite;
    if (writer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未配置预留写入接口')),
      );
      return;
    }
    final loader = widget.onLoadBookDetail;
    Map<String, Object?>? original;
    try {
      if (loader != null) {
        final result = await loader(item.bookId);
        if (!mounted || generation != _editGeneration) return;
        original = result.valueOrNull?.reservationFields;
        if (result.failureOrNull case final failure?) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.safeMessage)),
          );
          return;
        }
      }
    } catch (_) {
      if (!mounted || generation != _editGeneration) return;
    }
    if (!mounted || generation != _editGeneration) return;
    if (original == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('预留详情不完整，无法安全修改，请重试')),
      );
      return;
    }
    final fields = Map<String, Object?>.of(original);
    final nameCtrl = TextEditingController(text: '${fields['customer_name']}');
    final phoneCtrl = TextEditingController(text: '${fields['customer_phone']}');
    final countCtrl = TextEditingController(text: '${fields['customer_exp_cnt']}');
    final minConsumeCtrl = TextEditingController(text: '${fields['exp_min_csm_amt']}');
    final arriveCtrl = TextEditingController(text: '${fields['exp_arrive_time']}');
    final remarkCtrl = TextEditingController(text: '${fields['remark']}');
    final originalAutoSend = int.tryParse('${fields['auto_send_msg']}') ?? 2;
    var autoSendMsg = originalAutoSend == 1 ? 1 : 2;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(ctx).pop(false),
            const SingleActivator(LogicalKeyboardKey.enter): () =>
                Navigator.of(ctx).pop(true),
            const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
                Navigator.of(ctx).pop(true),
          },
          child: AlertDialog(
            backgroundColor: BookingTokens.surfaceDialog,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0x6632B9FF)),
            ),
            title: Text(
              '编辑预留 - ${item.seatName}',
              style: const TextStyle(color: _textPrimary),
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: '客人姓名',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: _textPrimary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: '客人电话',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: _textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          '是否发送短信：',
                          style: TextStyle(color: _textMuted, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('否'),
                          selected: autoSendMsg == 2,
                          onSelected: (_) =>
                              setDialogState(() => autoSendMsg = 2),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('是'),
                          selected: autoSendMsg == 1,
                          onSelected: (_) =>
                              setDialogState(() => autoSendMsg = 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: arriveCtrl,
                      decoration: const InputDecoration(
                        labelText: '预定到达时间',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: _textPrimary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: countCtrl,
                      decoration: const InputDecoration(
                        labelText: '人数 (1-100)',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: _textPrimary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: minConsumeCtrl,
                      decoration: const InputDecoration(
                        labelText: '最低消费(元)',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: _textPrimary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remarkCtrl,
                      decoration: const InputDecoration(
                        labelText: '备注',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: _textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('取消', style: TextStyle(color: _textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  '保存修改',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted || generation != _editGeneration) return;
    if (nameCtrl.text != '${original['customer_name']}') {
      fields['customer_name'] = nameCtrl.text.trim();
    }
    if (phoneCtrl.text != '${original['customer_phone']}') {
      fields['customer_phone'] = phoneCtrl.text.trim();
    }
    if (arriveCtrl.text != '${original['exp_arrive_time']}') {
      fields['exp_arrive_time'] = arriveCtrl.text.trim();
    }
    if (autoSendMsg != originalAutoSend) {
      fields['auto_send_msg'] = autoSendMsg;
    }
    if (remarkCtrl.text != '${original['remark']}') {
      fields['remark'] = remarkCtrl.text.trim();
    }
    final countChanged = countCtrl.text != '${original['customer_exp_cnt']}';
    final minimumChanged = minConsumeCtrl.text != '${original['exp_min_csm_amt']}';
    final count = num.tryParse(countCtrl.text.trim());
    final minimum = num.tryParse(minConsumeCtrl.text.trim());
    if ((countChanged &&
            (count == null ||
                !count.isFinite ||
                count < 1 ||
                count > 100 ||
                count % 1 != 0)) ||
        (minimumChanged &&
            (minimum == null || !minimum.isFinite || minimum < 0))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的人数和最低消费')),
      );
      return;
    }
    if (countChanged) {
      fields['customer_exp_cnt'] = count!.toInt();
    }
    if (minimumChanged) {
      fields['exp_min_csm_amt'] = minimum;
    }
    final res = await writer(
      action: BookingCardWriteAction.updateReserve,
      seatId: '${original['exp_seat_id']}',
      bookId: item.bookId,
      fields: fields,
    );
    if (!mounted || generation != _editGeneration) return;
    if (res.failureOrNull == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('修改预留成功'), backgroundColor: Colors.green),
      );
      unawaited(_fetchData());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failureOrNull?.safeMessage ?? '修改预留失败'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showCustomerHistory(BookingReservedItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardDark,
        title: Text('客人信息 - ${item.customerName}', style: const TextStyle(color: _textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('联系电话: ${item.customerPhone}', style: const TextStyle(color: _textPrimary)),
            const SizedBox(height: 8),
            Text('订位人: ${item.orderPersonName} (${item.orderPersonCode})', style: const TextStyle(color: _textMuted)),
            const SizedBox(height: 8),
            Text('订位部门: ${item.departmentName}', style: const TextStyle(color: _textMuted)),
            const SizedBox(height: 8),
            Text('预计到店: ${item.expArriveTime}', style: const TextStyle(color: _textMuted)),
            const SizedBox(height: 8),
            Text('备注: ${item.remark.isEmpty ? "无" : item.remark}', style: const TextStyle(color: _textMuted)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('确定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _openChangePassword() async {
    final submit = widget.onChangePassword;
    if (submit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('修改密码暂不可用')),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ChangePasswordScreen(
          submit: submit,
          onChanged: widget.onLogout,
          darkTheme: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAllSelected = _displayItems.isNotEmpty &&
        _displayItems.every((e) => _selectedIds.contains(e.id));

    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部 Tab 导航
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: _cardDark,
                border: Border(bottom: BorderSide(color: _borderDark)),
              ),
              child: Row(
                children: [
                  _tabButton(
                    key: BookingReservedScreen.tabTodayKey,
                    label: '当日预留',
                    index: 0,
                  ),
                  const SizedBox(width: 16),
                  _tabButton(
                    key: BookingReservedScreen.tabFutureKey,
                    label: '其它预留',
                    index: 1,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: _textPrimary),
                    tooltip: '刷新',
                    onPressed: _loading ? null : _fetchData,
                  ),
                ],
              ),
            ),

            // 筛选栏与操作按钮
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: _bgDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // 如果在「其它预留」Tab，展示日期筛选子按钮
                        if (!_isToday) ...[
                          const Text('日期：', style: TextStyle(color: _textMuted, fontSize: 14)),
                          _dateFilterButton(label: '明天', typeId: 1),
                          const SizedBox(width: 8),
                          _dateFilterButton(label: '未来7天', typeId: 2),
                          const SizedBox(width: 8),
                          _dateFilterButton(label: '全部', typeId: 3),
                          const SizedBox(width: 24),
                        ],
                        // 搜索输入框
                        SizedBox(
                          width: 320,
                          height: 38,
                          child: TextField(
                            key: BookingReservedScreen.searchKey,
                            controller: _searchCtrl,
                            style: const TextStyle(color: _textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: '订位人姓名/工号/客户姓名/电话',
                              hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              filled: true,
                              fillColor: _cardDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(color: _borderDark),
                              ),
                            ),
                            onSubmitted: (_) => _onSearch(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          key: BookingReservedScreen.searchBtnKey,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onPressed: _onSearch,
                          child: const Text('查询'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          key: BookingReservedScreen.resetBtnKey,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textMuted,
                            side: const BorderSide(color: _borderDark),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onPressed: _onReset,
                          child: const Text('重置'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 操作按钮行
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          key: BookingReservedScreen.addBtnKey,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('新增预留'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _onAddNewReservation,
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          key: BookingReservedScreen.deleteBtnKey,
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('删除预留'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _onDeleteSelected,
                        ),
                        if (_isToday) ...[
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            key: BookingReservedScreen.manyAllocationBtnKey,
                            icon: const Icon(Icons.table_restaurant_outlined, size: 16),
                            label: const Text('一键分配卡台'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _onOneKeyAllocation,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 数据表格区域（桌面/平板/Web 展示完整表格，手机展示触摸友好的卡片列表）
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _failure != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _failure!.safeMessage,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _fetchData,
                                child: const Text('重试'),
                              ),
                            ],
                          ),
                        )
                      : _displayItems.isEmpty
                          ? const Center(
                              child: Text(
                                '暂无预留数据',
                                style: TextStyle(color: _textMuted, fontSize: 16),
                              ),
                            )
                          : BookingViewportTier.of(context).isPhone
                              ? _buildPhoneList()
                              : Scrollbar(
                                  controller: _verticalScroll,
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    controller: _verticalScroll,
                                    child: Scrollbar(
                                      controller: _horizontalScroll,
                                      thumbVisibility: true,
                                      child: SingleChildScrollView(
                                        controller: _horizontalScroll,
                                        scrollDirection: Axis.horizontal,
                                        child: _buildTable(isAllSelected),
                                      ),
                                    ),
                                  ),
                                ),
            ),

            // 底部 Legend 与快捷操作导航栏 (S1.P2.T02 & S1.P2.T03)
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(
                horizontal: BookingViewportTier.of(context).isPhone ? 12 : 24,
              ),
              decoration: const BoxDecoration(
                color: _cardDark,
                border: Border(top: BorderSide(color: _borderDark)),
              ),
              child: Row(
                children: [
                  // 返回预订管理按钮 (S1.P2.T02) — 冰白切换卡
                  BookingIceSwitchCard(
                    key: BookingReservedScreen.backCardMachineKey,
                    label: '预订管理',
                    icon: Icons.grid_view_rounded,
                    compact: true,
                    onTap: widget.onBackToCardMachine ??
                        () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  if (!BookingViewportTier.of(context).isPhone) ...[
                    const Text(
                      '更多功能',
                      style: TextStyle(color: _textMuted, fontSize: 13),
                    ),
                    const SizedBox(width: 24),
                  ],
                  // 工号与账户菜单 (S1.P2.T03)
                  PopupMenuButton<String>(
                    key: BookingReservedScreen.accountMenuKey,
                    tooltip: '账户菜单',
                    color: _cardDark,
                    onSelected: (val) {
                      if (val == 'pwd') {
                        unawaited(_openChangePassword());
                      } else if (val == 'logout') {
                        widget.onLogout?.call();
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem<String>(
                        key: BookingReservedScreen.changePasswordKey,
                        value: 'pwd',
                        child: Row(
                          children: [
                            Icon(Icons.lock_reset, color: _textPrimary, size: 18),
                            SizedBox(width: 8),
                            Text('修改密码', style: TextStyle(color: _textPrimary)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        key: BookingReservedScreen.logoutKey,
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.redAccent, size: 18),
                            SizedBox(width: 8),
                            Text('退出登录', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, color: _textPrimary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '工号：${widget.employeeId ?? widget.userName ?? "未知"}',
                          style: const TextStyle(color: _textPrimary, fontSize: 14),
                        ),
                        const Icon(Icons.arrow_drop_down, color: _textPrimary),
                      ],
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

  Widget _tabButton({required Key key, required String label, required int index}) {
    final active = _activeTabIndex == index;
    return InkWell(
      key: key,
      onTap: () => _onSwitchTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : _textMuted,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _dateFilterButton({required String label, required int typeId}) {
    final active = _futureTypeId == typeId;
    return InkWell(
      onTap: () => _onChangeDateFilter(typeId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _primaryBlue : _cardDark,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active ? _primaryBlue : _borderDark,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : _textMuted,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneList() {
    return ListView.separated(
      controller: _verticalScroll,
      padding: const EdgeInsets.all(12),
      itemCount: _displayItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _displayItems[index];
        final selected = _selectedIds.contains(item.id);
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BookingTokens.surfaceDrawer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _primaryBlue : _borderDark,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: (_) => _toggleSelectItem(item.id),
                    activeColor: _primaryBlue,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _showCustomerHistory(item),
                      child: Text(
                        '${item.customerName.isEmpty ? '散客' : item.customerName}  ${item.customerPhone}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  if (item.seatName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: BookingTokens.statusReserved,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.seatName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    '订位人：${item.orderPersonName}${item.orderPersonCode.isNotEmpty ? '(${item.orderPersonCode})' : ''}',
                    style: const TextStyle(color: _textMuted, fontSize: 12),
                  ),
                  if (item.expArriveTime.isNotEmpty)
                    Text(
                      '预计到店：${item.expArriveTime}',
                      style: const TextStyle(color: _textMuted, fontSize: 12),
                    ),
                  Text(
                    '人数：${item.customerCount}  低消：¥${item.minConsumeYuan}',
                    style: const TextStyle(color: _textMuted, fontSize: 12),
                  ),
                ],
              ),
              if (item.remark.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '备注：${item.remark}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textMuted, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _onEditReservation(item),
                    child: const Text(
                      '编辑',
                      style: TextStyle(color: _primaryBlue),
                    ),
                  ),
                  if (_isToday)
                    TextButton(
                      onPressed: () => _onSingleAllocation(item),
                      child: const Text(
                        '分配卡台',
                        style: TextStyle(color: Color(0xFF10B981)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTable(bool isAllSelected) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(_tableHeaderBg),
      headingTextStyle: const TextStyle(
        color: _textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      dataRowColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryBlue.withValues(alpha: 0.15);
        }
        return Colors.transparent;
      }),
      horizontalMargin: 12,
      columnSpacing: 16,
      border: TableBorder.all(color: _borderDark, width: 0.5),
      columns: [
        DataColumn(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: isAllSelected,
                onChanged: _toggleSelectAll,
                activeColor: _primaryBlue,
              ),
              const Text('序号'),
            ],
          ),
        ),
        const DataColumn(label: Text('订位人部门')),
        const DataColumn(label: Text('订位人名称')),
        const DataColumn(label: Text('订位人工号')),
        const DataColumn(label: Text('预计到达时间')),
        const DataColumn(label: Text('最低消费(元)')),
        const DataColumn(label: Text('人数')),
        const DataColumn(label: Text('客人姓名')),
        const DataColumn(label: Text('客人联系方式')),
        const DataColumn(label: Text('意向卡台')),
        const DataColumn(label: Text('备注')),
        const DataColumn(label: Text('操作')),
      ],
      rows: [
        for (var i = 0; i < _displayItems.length; i++)
          _buildRow(_displayItems[i], i + 1),
      ],
    );
  }

  DataRow _buildRow(BookingReservedItem item, int index) {
    final isSelected = _selectedIds.contains(item.id);
    return DataRow(
      selected: isSelected,
      onSelectChanged: (_) => _toggleSelectItem(item.id),
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelectItem(item.id),
                activeColor: _primaryBlue,
              ),
              Text('$index', style: const TextStyle(color: _textMuted)),
            ],
          ),
        ),
        DataCell(Text(item.departmentName, style: const TextStyle(color: _textPrimary))),
        DataCell(Text(item.orderPersonName, style: const TextStyle(color: _textPrimary))),
        DataCell(Text(item.orderPersonCode, style: const TextStyle(color: _textPrimary))),
        DataCell(Text(item.expArriveTime, style: const TextStyle(color: _textPrimary))),
        DataCell(Text(item.minConsumeYuan, style: const TextStyle(color: _textPrimary))),
        DataCell(Text(item.customerCount, style: const TextStyle(color: _textPrimary))),
        DataCell(
          InkWell(
            onTap: () => _showCustomerHistory(item),
            child: Text(
              item.customerName,
              style: const TextStyle(
                color: _primaryBlue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        DataCell(Text(item.customerPhone, style: const TextStyle(color: _textPrimary))),
        DataCell(Text(item.seatName, style: const TextStyle(color: _textPrimary))),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              item.remark,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _textMuted),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => _onEditReservation(item),
                child: const Text('编辑', style: TextStyle(color: _primaryBlue)),
              ),
              if (_isToday) ...[
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => _onSingleAllocation(item),
                  child: const Text('分配卡台', style: TextStyle(color: Color(0xFF10B981))),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
