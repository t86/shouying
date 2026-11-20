import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';

/// 异议单条目数据模型 (S3.P1.T03)
final class CashierObjectionItem {
  const CashierObjectionItem({
    required this.id,
    this.seatName = '',
    this.bookerName = '',
    this.customerName = '',
    this.customerPhone = '',
    this.payChannelName = '',
    this.amount = '0',
    this.time = '',
    this.businessType = '',
    this.businessInfo = '',
    this.remark = '',
    this.failReason = '',
    this.commands = const [],
    this.processing = false,
  });

  final String id;
  final String seatName;
  final String bookerName;
  final String customerName;
  final String customerPhone;
  final String payChannelName;
  final String amount;
  final String time;
  final String businessType;
  final String businessInfo;
  final String remark;
  final String failReason;
  final List<CashierObjectionCommand> commands;
  final bool processing;

  CashierObjectionItem copyWith({bool? processing}) => CashierObjectionItem(
    id: id,
    seatName: seatName,
    bookerName: bookerName,
    customerName: customerName,
    customerPhone: customerPhone,
    payChannelName: payChannelName,
    amount: amount,
    time: time,
    businessType: businessType,
    businessInfo: businessInfo,
    remark: remark,
    failReason: failReason,
    commands: commands,
    processing: processing ?? this.processing,
  );
}

final class CashierObjectionCommand {
  const CashierObjectionCommand({required this.key, required this.label});
  final String key;
  final String label;
}

final class CashierObjectionData {
  const CashierObjectionData({
    this.todos = const [],
    this.doings = const [],
    this.dones = const [],
    this.fails = const [],
  });

  final List<CashierObjectionItem> todos;
  final List<CashierObjectionItem> doings;
  final List<CashierObjectionItem> dones;
  final List<CashierObjectionItem> fails;

  int get totalPending => todos.length + fails.length;
}

/// 异议单退款与重试交互抽屉
final class CashierObjectionDrawer extends StatefulWidget {
  const CashierObjectionDrawer({
    required this.onLoadList,
    required this.onExecuteCommand,
    this.onClose,
    super.key,
  });

  final Future<Result<CashierObjectionData>> Function() onLoadList;
  final Future<Result<void>> Function(String id, String commandKey)
  onExecuteCommand;
  final VoidCallback? onClose;

  @override
  State<CashierObjectionDrawer> createState() => _CashierObjectionDrawerState();
}

final class _CashierObjectionDrawerState extends State<CashierObjectionDrawer> {
  int _activeTab = 0; // 0: 待退款, 1: 退款中, 2: 已退款, 3: 已失败
  CashierObjectionData _data = const CashierObjectionData();
  bool _loading = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_loading) {
        unawaited(_refresh(silent: true));
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final res = await widget.onLoadList();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.valueOrNull != null) {
        _data = res.valueOrNull!;
      }
    });
  }

  List<CashierObjectionItem> get _currentList => switch (_activeTab) {
    0 => _data.todos,
    1 => _data.doings,
    2 => _data.dones,
    3 => _data.fails,
    _ => _data.todos,
  };

  Future<void> _handleCommand(
    CashierObjectionItem item,
    CashierObjectionCommand cmd,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xff182037),
            title: Text(cmd.label, style: const TextStyle(color: Colors.white)),
            content: Text(
              '确认对单号 ${item.id} 执行 [${cmd.label}] 操作吗？',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  '取消',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff2362D5),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('确定'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    final res = await widget.onExecuteCommand(item.id, cmd.key);
    if (!mounted) return;
    if (res.failureOrNull == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${cmd.label}成功')));
      await _refresh();
    } else {
      final msg = res.failureOrNull?.safeMessage ?? '操作失败';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _currentList;

    return Container(
      width: 860,
      color: const Color(0xff0D172D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部标题与关闭
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xff141D35),
              border: Border(bottom: BorderSide(color: Color(0xff263352))),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: Color(0xff4B89FF),
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Text(
                  '异议单列表',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  tooltip: '刷新',
                  onPressed: _loading ? null : () => unawaited(_refresh()),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  tooltip: '关闭',
                  onPressed: widget.onClose ?? () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tab 切换栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xff182037),
            child: Row(
              children: [
                _buildTab(0, '待退款', _data.todos.length),
                const SizedBox(width: 8),
                _buildTab(1, '退款中', _data.doings.length),
                const SizedBox(width: 8),
                _buildTab(2, '已退款', _data.dones.length),
                const SizedBox(width: 8),
                _buildTab(3, '已失败', _data.fails.length),
              ],
            ),
          ),

          // 提示条
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xff2A1520),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.redAccent, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '注意：退款操作后，请至少等待 10 秒后点击刷新查看退款详情，具体时间取决于支付渠道的退款处理进度。',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // 表格内容
          Expanded(
            child:
                _loading && list.isEmpty
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff4B89FF),
                      ),
                    )
                    : list.isEmpty
                    ? const Center(
                      child: Text(
                        '暂无异议单数据',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    )
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xff182037),
                          ),
                          dataRowColor: WidgetStateProperty.all(
                            const Color(0xff0D172D),
                          ),
                          headingTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          dataTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          columnSpacing: 14,
                          columns: [
                            const DataColumn(label: Text('序号')),
                            const DataColumn(label: Text('单号')),
                            const DataColumn(label: Text('卡台')),
                            const DataColumn(label: Text('订位人')),
                            const DataColumn(label: Text('客人')),
                            const DataColumn(label: Text('手机号')),
                            const DataColumn(label: Text('支付途径')),
                            const DataColumn(label: Text('金额(元)')),
                            const DataColumn(label: Text('时间')),
                            const DataColumn(label: Text('业务类型')),
                            const DataColumn(label: Text('备注')),
                            if (_activeTab == 3)
                              const DataColumn(label: Text('失败原因')),
                            if (_activeTab == 0 || _activeTab == 3)
                              const DataColumn(label: Text('操作')),
                          ],
                          rows: [
                            for (var i = 0; i < list.length; i++)
                              _buildRow(i, list[i]),
                          ],
                        ),
                      ),
                    ),
          ),

          // 底部关闭按钮栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xff141D35),
              border: Border(top: BorderSide(color: Color(0xff263352))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Color(0xff263352)),
                  ),
                  onPressed: widget.onClose ?? () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff2362D5),
                  ),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('立即刷新'),
                  onPressed: () => unawaited(_refresh()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, int count) {
    final active = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xff2362D5) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: active ? Colors.white24 : const Color(0xff263352),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xffFFA726),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(int index, CashierObjectionItem item) {
    return DataRow(
      cells: [
        DataCell(Text('${index + 1}')),
        DataCell(Text(item.id)),
        DataCell(Text(item.seatName)),
        DataCell(Text(item.bookerName)),
        DataCell(Text(item.customerName)),
        DataCell(Text(item.customerPhone)),
        DataCell(Text(item.payChannelName)),
        DataCell(
          Text(
            item.amount,
            style: const TextStyle(
              color: Color(0xffFFA726),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataCell(Text(item.time)),
        DataCell(Text(item.businessType)),
        DataCell(Text(item.remark)),
        if (_activeTab == 3)
          DataCell(
            Text(
              item.failReason,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ),
        if (_activeTab == 0 || _activeTab == 3)
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final cmd in item.commands)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            _activeTab == 3
                                ? const Color(0xffC62828)
                                : const Color(0xff2362D5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => unawaited(_handleCommand(item, cmd)),
                      child: Text(cmd.label, style: const TextStyle(fontSize: 11)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
