import 'dart:async';

import 'package:card_table/src/booking_queue.dart';
import 'package:card_table/src/booking_queue_loader.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color _bgDark = BookingTokens.surfaceFooter;
const Color _headerBg = BookingTokens.surfaceHeader;
const Color _rowAltBg = BookingTokens.tableRowAlt;
const Color _borderColor = BookingTokens.tableBorder;
const Color _primaryBlue = BookingTokens.brandPrimary;

final class BookingQueueScreen extends StatefulWidget {
  const BookingQueueScreen({
    required this.queue,
    this.onCall,
    this.onArrive,
    this.onExpired,
    this.onExport,
    this.onRefresh,
    super.key,
  });

  static const Key tabCallKey = Key('queue-tab-call');
  static const Key tabListKey = Key('queue-tab-list');
  static const Key searchInputKey = Key('queue-search-input');
  static const Key exportButtonKey = Key('queue-export-btn');

  final CardTableQueueSnapshot queue;
  final BookingQueueAction? onCall;
  final BookingQueueAction? onArrive;
  final BookingQueueAction? onExpired;
  final BookingQueueExporter? onExport;
  final Future<void> Function()? onRefresh;

  @override
  State<BookingQueueScreen> createState() => _BookingQueueScreenState();
}

final class _BookingQueueScreenState extends State<BookingQueueScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalCall = ScrollController();
  final ScrollController _verticalCall = ScrollController();
  final ScrollController _horizontalList = ScrollController();
  final ScrollController _verticalList = ScrollController();

  int _selectedTypeId = -1; // -1: 全部
  int _selectedStatus = -1; // -1: 全部, 1: 排队中, 2: 已过号, 3: 已取消, 5: 已进店
  bool _actionInProgress = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _horizontalCall.dispose();
    _verticalCall.dispose();
    _horizontalList.dispose();
    _verticalList.dispose();
    super.dispose();
  }

  void _close() => unawaited(Navigator.of(context).maybePop());

  Future<void> _export() async {
    final exporter = widget.onExport;
    if (exporter == null || _exporting || !mounted) return;
    setState(() => _exporting = true);
    try {
      final result = await exporter(
        queueTypeId: _selectedTypeId > 0 ? _selectedTypeId : 0,
        status: _selectedStatus > 0 ? _selectedStatus : 0,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (result.failureOrNull case final failure?) {
        messenger?.showSnackBar(SnackBar(content: Text(failure.safeMessage)));
      } else {
        final location = result.valueOrNull ?? '';
        messenger?.showSnackBar(
          SnackBar(
            content: Text(location.isEmpty ? '导出成功' : '导出成功：$location'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmAndExecute({
    required String title,
    required String content,
    required Future<void> Function() action,
  }) async {
    final ok = await showBookingConfirmDialog(
      context: context,
      title: title,
      message: content,
      confirmLabel: '确认',
    );
    if (ok == true && mounted) {
      setState(() => _actionInProgress = true);
      try {
        await action();
        if (widget.onRefresh != null) {
          await widget.onRefresh!();
        }
      } finally {
        if (mounted) setState(() => _actionInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = BookingViewportTier.of(context).isPhone;
    return Theme(
      data: BookingTheme.dark().copyWith(
        scaffoldBackgroundColor: _bgDark,
        colorScheme: const ColorScheme.dark(
          primary: _primaryBlue,
          surface: _headerBg,
        ),
      ),
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): _close,
        },
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isPhone ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        '排队详情',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (!isPhone) ...[
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 220,
                          child: TabBar(
                            controller: _tabController,
                            indicatorColor: _primaryBlue,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white60,
                            tabs: const [
                              Tab(
                                key: BookingQueueScreen.tabCallKey,
                                text: '排队叫号',
                              ),
                              Tab(
                                key: BookingQueueScreen.tabListKey,
                                text: '排队列表',
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (widget.onExport != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: OutlinedButton.icon(
                            key: BookingQueueScreen.exportButtonKey,
                            onPressed: _exporting ? null : _export,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BookingTokens.outlineActionText,
                              side: const BorderSide(
                                color: BookingTokens.outlineActionBorder,
                              ),
                              minimumSize: const Size(84, 34),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            icon: _exporting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.download_outlined, size: 16),
                            label: Text(_exporting ? '导出中' : '导出Excel'),
                          ),
                        ),
                      if (widget.onRefresh != null)
                        IconButton(
                          tooltip: '刷新',
                          onPressed: _actionInProgress
                              ? null
                              : widget.onRefresh,
                          icon: const Icon(Icons.refresh, color: Colors.white70),
                        ),
                      IconButton(
                        tooltip: '关闭',
                        onPressed: _close,
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  if (isPhone)
                    TabBar(
                      controller: _tabController,
                      indicatorColor: _primaryBlue,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      tabs: const [
                        Tab(key: BookingQueueScreen.tabCallKey, text: '排队叫号'),
                        Tab(key: BookingQueueScreen.tabListKey, text: '排队列表'),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCallTab(),
                        _buildListTab(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.center,
                    child: FilledButton(
                      onPressed: _close,
                      style: FilledButton.styleFrom(
                        backgroundColor: BookingTokens.brandSecondary,
                        minimumSize: const Size(120, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('关闭', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // Tab 1: 排队叫号
  // ==========================================================================
  Widget _buildCallTab() {
    final types = widget.queue.types.where((t) => t.status == 1).toList();
    if (types.isEmpty) {
      return const Center(child: Text('暂无排队类型数据', style: TextStyle(color: Colors.white54)));
    }

    const columns = ['类型', '当前叫号', '当前取号', '等待桌数', '等待叫号', '操作'];
    final colWidths = [140.0, 120.0, 120.0, 120.0, 120.0, 240.0];
    final totalWidth = colWidths.reduce((a, b) => a + b);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Scrollbar(
        controller: _horizontalCall,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalCall,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Column(
              children: [
                Container(
                  color: _headerBg,
                  height: 40,
                  child: Row(
                    children: [
                      for (var i = 0; i < columns.length; i++)
                        SizedBox(
                          width: colWidths[i],
                          child: Center(
                            child: Text(
                              columns[i],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    controller: _verticalCall,
                    child: ListView.builder(
                      controller: _verticalCall,
                      itemCount: types.length,
                      itemBuilder: (context, index) {
                        final t = types[index];
                        final cur = widget.queue.curNumbers.cast<QueueCurNumber?>().firstWhere(
                              (c) => c?.queueTypeId == t.id,
                              orElse: () => null,
                            );
                        final numType = widget.queue.config.numberType;
                        final currNumStr = cur != null && cur.currNo > 0
                            ? formatQueueNumber(t.numPrefix, cur.currNo, numType)
                            : '-';
                        final lastGenNumStr = cur != null && cur.lastGenNum > 0
                            ? formatQueueNumber(t.numPrefix, cur.lastGenNum, numType)
                            : '-';
                        final waitCntStr = cur != null ? '${cur.waitCnt}' : '-';
                        final waitNoStr = cur != null && cur.waitNo > 0
                            ? formatQueueNumber(t.numPrefix, cur.waitNo, numType)
                            : '-';

                        final canCall = cur != null && (cur.currNoStatus == 1 || cur.waitNo > 0);
                        final canEnter = cur != null && cur.currNoStatus == 1;
                        final canOverdue = cur != null && cur.currNoStatus == 1;

                        final targetCallNo = cur != null
                            ? (cur.currNoStatus == 1 ? cur.currNo : cur.waitNo)
                            : 0;
                        final targetActionNo = cur?.currNo ?? 0;

                        final bg = index.isEven ? _bgDark : _rowAltBg;
                        return Container(
                          color: bg,
                          height: 48,
                          child: Row(
                            children: [
                              SizedBox(width: colWidths[0], child: Center(child: Text(t.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)))),
                              SizedBox(width: colWidths[1], child: Center(child: Text(currNumStr, style: const TextStyle(color: Colors.white70)))),
                              SizedBox(width: colWidths[2], child: Center(child: Text(lastGenNumStr, style: const TextStyle(color: Colors.white70)))),
                              SizedBox(width: colWidths[3], child: Center(child: Text(waitCntStr, style: const TextStyle(color: Colors.white70)))),
                              SizedBox(width: colWidths[4], child: Center(child: Text(waitNoStr, style: const TextStyle(color: Colors.white70)))),
                              SizedBox(
                                width: colWidths[5],
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FilledButton(
                                      onPressed: canCall && !_actionInProgress && widget.onCall != null
                                          ? () => _confirmAndExecute(
                                                title: '叫号',
                                                content: '是否确认叫号？',
                                                action: () => widget.onCall!(
                                                  queueTypeId: t.id,
                                                  queueNo: targetCallNo,
                                                ),
                                              )
                                          : null,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _primaryBlue,
                                        minimumSize: const Size(60, 32),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                      ),
                                      child: const Text('叫号', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      onPressed: canEnter && !_actionInProgress && widget.onArrive != null
                                          ? () => _confirmAndExecute(
                                                title: '进店',
                                                content: '是否确认客人已进店？',
                                                action: () => widget.onArrive!(
                                                  queueTypeId: t.id,
                                                  queueNo: targetActionNo,
                                                ),
                                              )
                                          : null,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xff10B981),
                                        minimumSize: const Size(60, 32),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                      ),
                                      child: const Text('进店', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      onPressed: canOverdue && !_actionInProgress && widget.onExpired != null
                                          ? () => _confirmAndExecute(
                                                title: '过号',
                                                content: '是否设置为过号？操作后不可撤销。',
                                                action: () => widget.onExpired!(
                                                  queueTypeId: t.id,
                                                  queueNo: targetActionNo,
                                                ),
                                              )
                                          : null,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xffEF4444),
                                        minimumSize: const Size(60, 32),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                      ),
                                      child: const Text('过号', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // Tab 2: 排队列表
  // ==========================================================================
  Widget _buildListTab() {
    final types = widget.queue.types.where((t) => t.status == 1).toList();
    final records = widget.queue.records;
    final keyword = _searchController.text.trim();

    // 过滤逻辑
    final filtered = records.where((r) {
      if (_selectedTypeId != -1 && r.queueTypeId != _selectedTypeId) return false;
      if (_selectedStatus != -1 && r.status != _selectedStatus) return false;
      if (keyword.isNotEmpty) {
        final matchesNo = r.queueNo.toString().contains(keyword);
        final matchesPhone = r.phoneNum.contains(keyword);
        final matchesName = r.name.contains(keyword);
        if (!matchesNo && !matchesPhone && !matchesName) return false;
      }
      return true;
    }).toList();

    const columns = [
      '排队号码', '排队类型', '客户姓名', '前方桌数', '状态', '电话', '等待时间', '取号时间',
    ];
    final colWidths = [120.0, 120.0, 120.0, 100.0, 100.0, 130.0, 140.0, 180.0];
    final totalWidth = colWidths.reduce((a, b) => a + b);

    return Column(
      children: [
        // 筛选区
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('排队类型：', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  _buildFilterChip('全部', -1, _selectedTypeId, (v) => setState(() => _selectedTypeId = v)),
                  for (final t in types)
                    _buildFilterChip(t.name, t.id, _selectedTypeId, (v) => setState(() => _selectedTypeId = v)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('状态：', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  _buildFilterChip('全部', -1, _selectedStatus, (v) => setState(() => _selectedStatus = v)),
                  _buildFilterChip('排队中', 1, _selectedStatus, (v) => setState(() => _selectedStatus = v)),
                  _buildFilterChip('已过号', 2, _selectedStatus, (v) => setState(() => _selectedStatus = v)),
                  _buildFilterChip('已取消', 3, _selectedStatus, (v) => setState(() => _selectedStatus = v)),
                  _buildFilterChip('已进店', 5, _selectedStatus, (v) => setState(() => _selectedStatus = v)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 240,
                    height: 36,
                    child: TextField(
                      key: BookingQueueScreen.searchInputKey,
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '支持排队号码、手机号或昵称',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        filled: true,
                        fillColor: _headerBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: _borderColor),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: filtered.isEmpty
                ? const Center(child: Text('暂无数据', style: TextStyle(color: Colors.white54)))
                : Scrollbar(
                    controller: _horizontalList,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _horizontalList,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: totalWidth,
                        child: Column(
                          children: [
                            Container(
                              color: _headerBg,
                              height: 40,
                              child: Row(
                                children: [
                                  for (var i = 0; i < columns.length; i++)
                                    SizedBox(
                                      width: colWidths[i],
                                      child: Center(
                                        child: Text(
                                          columns[i],
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Scrollbar(
                                controller: _verticalList,
                                child: ListView.builder(
                                  controller: _verticalList,
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final r = filtered[index];
                                    final t = types.cast<QueueType?>().firstWhere(
                                          (tp) => tp?.id == r.queueTypeId,
                                          orElse: () => null,
                                        );
                                    final prefix = t?.numPrefix ?? '';
                                    final typeName = t?.name ?? '';
                                    final numType = widget.queue.config.numberType;
                                    final queueNoName = formatQueueNumber(prefix, r.queueNo, numType);
                                    final deskCnt = records.where((el) =>
                                        el.status == 1 &&
                                        el.obtainTime.compareTo(r.obtainTime) < 0).length;
                                    final statusName = switch (r.status) {
                                      1 => '排队中',
                                      2 => '已过号',
                                      3 => '已取消',
                                      5 => '已进店',
                                      _ => '未知',
                                    };
                                    final waitDuration = formatWaitDuration(r.obtainTime, r.updateTime, r.status);
                                    final obtainTimeFormatted = formatTimestamp(r.obtainTime);

                                    final bg = index.isEven ? _bgDark : _rowAltBg;
                                    final cells = [
                                      queueNoName, typeName, r.name, '$deskCnt',
                                      statusName, r.phoneNum, waitDuration, obtainTimeFormatted,
                                    ];

                                    return Container(
                                      color: bg,
                                      height: 38,
                                      child: Row(
                                        children: [
                                          for (var i = 0; i < cells.length; i++)
                                            SizedBox(
                                              width: colWidths[i],
                                              child: Center(
                                                child: Text(
                                                  cells[i],
                                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int value, int current, ValueChanged<int> onSelect) {
    final selected = current == value;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? _primaryBlue : _headerBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: selected ? _primaryBlue : _borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : Colors.white70,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
