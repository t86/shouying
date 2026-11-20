import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:card_table/src/booking_reports.dart';
import 'package:card_table/src/booking_reports_loader.dart';
import 'package:card_table/src/card_table_models.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foundation/foundation.dart';

/// 通用报表暗色容器装饰
const Color _bgDark = BookingTokens.surfaceFooter;
const Color _headerBg = BookingTokens.surfaceHeader;
const Color _rowAltBg = BookingTokens.tableRowAlt;
const Color _borderColor = BookingTokens.tableBorder;
const Color _primaryBlue = BookingTokens.brandPrimary;

Future<void> _showReportExportResult(
  BuildContext context,
  Result<String> result,
) async {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (result.failureOrNull case final failure?) {
    messenger?.showSnackBar(SnackBar(content: Text(failure.safeMessage)));
    return;
  }
  final location = result.valueOrNull ?? '';
  messenger?.showSnackBar(
    SnackBar(content: Text(location.isEmpty ? '导出成功' : '导出成功：$location')),
  );
}

Widget _bookingReportTopBar({
  required String title,
  required String refreshLabel,
  required VoidCallback onClose,
  VoidCallback? onRefresh,
  bool loading = false,
  VoidCallback? onExport,
  bool exporting = false,
  Key? exportKey,
}) => Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Expanded(
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (refreshLabel.isNotEmpty)
            Text(
              refreshLabel,
              style: const TextStyle(
                fontSize: 12,
                color: BookingTokens.textMuted,
              ),
            ),
        ],
      ),
    ),
    if (onExport != null)
      Padding(
        padding: const EdgeInsets.only(right: 4),
        child: OutlinedButton.icon(
          key: exportKey,
          onPressed: exporting ? null : onExport,
          style: OutlinedButton.styleFrom(
            foregroundColor: BookingTokens.outlineActionText,
            side: const BorderSide(color: BookingTokens.outlineActionBorder),
            minimumSize: const Size(84, 34),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          icon: exporting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined, size: 16),
          label: Text(exporting ? '导出中' : '导出Excel'),
        ),
      ),
    if (onRefresh != null)
      IconButton(
        tooltip: '刷新',
        onPressed: loading ? null : onRefresh,
        icon: const Icon(Icons.refresh, color: Colors.white70),
      ),
    IconButton(
      tooltip: '关闭',
      onPressed: onClose,
      icon: const Icon(Icons.close, color: Colors.white70),
    ),
  ],
);

// ============================================================================
// 1. 开台记录界面
// ============================================================================
final class SeatOpenLogScreen extends StatefulWidget {
  const SeatOpenLogScreen({
    required this.load,
    required this.canRead,
    this.onExport,
    this.departments = const [],
    super.key,
  });

  static const Key keywordKey = Key('seat-open-keyword');
  static const Key searchButtonKey = Key('seat-open-search');
  static const Key exportButtonKey = Key('seat-open-export');

  final SeatOpenLogLoader load;
  final SeatOpenLogExporter? onExport;
  final ValueListenable<bool> canRead;
  final List<CardDepartment> departments;

  @override
  State<SeatOpenLogScreen> createState() => _SeatOpenLogScreenState();
}

final class _SeatOpenLogScreenState extends State<SeatOpenLogScreen> {
  final TextEditingController _keyword = TextEditingController();
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();
  List<SeatOpenLogRow> _rows = const [];
  AppFailure? _failure;
  bool _loading = false;
  bool _exporting = false;
  bool _hasLoaded = false;
  int _typeId = 1;
  int _deptId = 0;
  String _lastRefreshTime = '';

  @override
  void initState() {
    super.initState();
    if (widget.canRead.value) unawaited(_load());
  }

  @override
  void dispose() {
    _keyword.dispose();
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  void _close() => unawaited(Navigator.of(context).maybePop());

  Future<void> _export() async {
    final exporter = widget.onExport;
    if (exporter == null || _exporting || !mounted) return;
    setState(() => _exporting = true);
    try {
      final result = await exporter(
        key: _keyword.text.trim(),
        typeId: _typeId,
      );
      if (!mounted) return;
      await _showReportExportResult(context, result);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _load() async {
    if (!mounted || !widget.canRead.value || _loading) return;
    setState(() {
      _loading = true;
      _rows = const [];
      _failure = null;
      _hasLoaded = false;
    });
    final now = DateTime.now();
    final timeStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final result = await widget.load(
      key: _keyword.text.trim(),
      deptId: _deptId,
      typeId: _typeId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _lastRefreshTime = timeStr;
      _failure = result.failureOrNull;
      _rows = result.valueOrNull ?? const [];
      _hasLoaded = true;
    });
  }

  void _reset() {
    _keyword.clear();
    _typeId = 1;
    _deptId = 0;
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) => Theme(
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _bookingReportTopBar(
                  title: '开台记录',
                  refreshLabel: _lastRefreshTime.isNotEmpty
                      ? '最近刷新时间：$_lastRefreshTime'
                      : '',
                  onClose: _close,
                  onRefresh: () => unawaited(_load()),
                  loading: _loading,
                  onExport: widget.onExport != null
                      ? () => unawaited(_export())
                      : null,
                  exporting: _exporting,
                  exportKey: SeatOpenLogScreen.exportButtonKey,
                ),
                const SizedBox(height: 12),
                _buildFilterBar(),
                const SizedBox(height: 12),
                Expanded(child: _buildTable()),
                const SizedBox(height: 12),
                _buildCloseButton(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildFilterBar() => Wrap(
    spacing: 10,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const Text('排序：', style: TextStyle(color: Colors.white70, fontSize: 13)),
      DropdownButton<int>(
        value: _typeId,
        dropdownColor: _headerBg,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 1, child: Text('按开台时间排序')),
          DropdownMenuItem(value: 2, child: Text('按部门员工排序')),
          DropdownMenuItem(value: 3, child: Text('按区域排序')),
        ],
        onChanged: (v) {
          if (v != null) {
            setState(() => _typeId = v);
            unawaited(_load());
          }
        },
      ),
      const SizedBox(width: 8),
      DropdownButton<int>(
        value: _deptId,
        dropdownColor: _headerBg,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        underline: const SizedBox(),
        items: [
          const DropdownMenuItem(value: 0, child: Text('全部部门')),
          for (final dept in widget.departments)
            DropdownMenuItem(
              value: int.tryParse(dept.id) ?? 0,
              child: Text(dept.name),
            ),
        ],
        onChanged: (v) {
          if (v != null) {
            setState(() => _deptId = v);
            unawaited(_load());
          }
        },
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 240,
        height: 36,
        child: TextField(
          key: SeatOpenLogScreen.keywordKey,
          controller: _keyword,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: '卡台标记/台位/订位人/客户姓名/电话',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            filled: true,
            fillColor: _headerBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: _borderColor),
            ),
          ),
          onSubmitted: (_) => unawaited(_load()),
        ),
      ),
      FilledButton(
        key: SeatOpenLogScreen.searchButtonKey,
        onPressed: _loading ? null : () => unawaited(_load()),
        style: FilledButton.styleFrom(
          backgroundColor: _primaryBlue,
          minimumSize: const Size(64, 36),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text('查询'),
      ),
      OutlinedButton(
        onPressed: _loading ? null : _reset,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 36),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: const BorderSide(color: Colors.white30),
        ),
        child: const Text('重置', style: TextStyle(color: Colors.white70)),
      ),
    ],
  );

  Widget _buildTable() {
    const columns = [
      '序号', '区域', '卡台名称', '订位人部门', '订位人', '卡台标记',
      '低消进度', '点单金额', '客人电话', '客人姓名', '客人人数',
      '订位人电话', '订位人工号', '开台时间', '清台时间', '联合订位人',
      '联合订位人部门', '备注', '咨客',
    ];
    final colWidths = [
      60.0, 90.0, 110.0, 110.0, 100.0, 90.0,
      90.0, 100.0, 120.0, 100.0, 90.0,
      120.0, 110.0, 150.0, 150.0, 110.0,
      120.0, 150.0, 100.0,
    ];
    final totalWidth = colWidths.reduce((a, b) => a + b);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failure != null) {
      return Center(child: Text(_failure!.safeMessage, style: const TextStyle(color: Colors.redAccent)));
    }
    if (_rows.isEmpty && _hasLoaded) {
      return const Center(child: Text('暂无数据', style: TextStyle(color: Colors.white54)));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Scrollbar(
        controller: _horizontal,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontal,
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
                    controller: _vertical,
                    child: ListView.builder(
                      controller: _vertical,
                      itemCount: _rows.length,
                      itemBuilder: (context, index) {
                        final r = _rows[index];
                        final cells = [
                          '${index + 1}', r.regionName, r.seatName, r.salesDeptName,
                          r.salesEmpName, r.mark, r.minConsumeProgress, r.orderAmountYuan,
                          r.customerPhone, r.customerName, r.customerCount, r.salesPhone,
                          r.salesCode, r.openTime, r.clearTime, r.jointSalesName,
                          r.jointDeptName, r.remark, r.operatorName,
                        ];
                        final bg = index.isEven ? _bgDark : _rowAltBg;
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
    );
  }

  Widget _buildCloseButton() => Align(
    alignment: Alignment.center,
    child: FilledButton(
      onPressed: _close,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xff2A3756),
        minimumSize: const Size(120, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: const Text('关闭', style: TextStyle(fontSize: 16)),
    ),
  );
}

// ============================================================================
// 2. 转台记录界面
// ============================================================================
final class SeatChangeLogScreen extends StatefulWidget {
  const SeatChangeLogScreen({
    required this.load,
    required this.canRead,
    super.key,
  });

  final SeatChangeLogLoader load;
  final ValueListenable<bool> canRead;

  @override
  State<SeatChangeLogScreen> createState() => _SeatChangeLogScreenState();
}

final class _SeatChangeLogScreenState extends State<SeatChangeLogScreen> {
  final ScrollController _scrollController = ScrollController();
  List<SeatChangeLogRow> _rows = const [];
  AppFailure? _failure;
  bool _loading = false;
  bool _hasLoaded = false;
  String _lastRefreshTime = '';

  @override
  void initState() {
    super.initState();
    if (widget.canRead.value) unawaited(_load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _close() => unawaited(Navigator.of(context).maybePop());

  Future<void> _load() async {
    if (!mounted || !widget.canRead.value || _loading) return;
    setState(() {
      _loading = true;
      _rows = const [];
      _failure = null;
    });
    final now = DateTime.now();
    final timeStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final result = await widget.load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _lastRefreshTime = timeStr;
      _failure = result.failureOrNull;
      _rows = result.valueOrNull ?? const [];
      _hasLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) => Theme(
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _bookingReportTopBar(
                  title: '转台记录',
                  refreshLabel: _lastRefreshTime.isNotEmpty
                      ? '最近刷新时间：$_lastRefreshTime'
                      : '',
                  onClose: _close,
                  onRefresh: () => unawaited(_load()),
                  loading: _loading,
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildTable()),
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

  Widget _buildTable() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failure != null) {
      return Center(child: Text(_failure!.safeMessage, style: const TextStyle(color: Colors.redAccent)));
    }
    if (_rows.isEmpty && _hasLoaded) {
      return const Center(child: Text('暂无数据', style: TextStyle(color: Colors.white54)));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            color: _headerBg,
            height: 40,
            child: const Row(
              children: [
                SizedBox(width: 80, child: Center(child: Text('序号', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)))),
                SizedBox(width: 200, child: Center(child: Text('开台时间', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)))),
                Expanded(child: Padding(padding: EdgeInsets.only(left: 16), child: Text('转台记录', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _rows.length,
              itemBuilder: (context, index) {
                final r = _rows[index];
                final bg = index.isEven ? _bgDark : _rowAltBg;
                return Container(
                  color: bg,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 80, child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white70)))),
                      SizedBox(width: 200, child: Center(child: Text(r.openTime, style: const TextStyle(color: Colors.white70)))),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final line in r.detailList)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(line, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. 预留记录界面
// ============================================================================
final class BookListScreen extends StatefulWidget {
  const BookListScreen({
    required this.load,
    required this.canRead,
    this.onExport,
    super.key,
  });

  static const Key exportButtonKey = Key('book-list-export');

  final BookListLoader load;
  final BookingReportExporter? onExport;
  final ValueListenable<bool> canRead;

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

final class _BookListScreenState extends State<BookListScreen> {
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();
  List<BookListRow> _rows = const [];
  AppFailure? _failure;
  bool _loading = false;
  bool _exporting = false;
  bool _hasLoaded = false;
  String _lastRefreshTime = '';

  @override
  void initState() {
    super.initState();
    if (widget.canRead.value) unawaited(_load());
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  void _close() => unawaited(Navigator.of(context).maybePop());

  Future<void> _export() async {
    final exporter = widget.onExport;
    if (exporter == null || _exporting || !mounted) return;
    setState(() => _exporting = true);
    try {
      final result = await exporter();
      if (!mounted) return;
      await _showReportExportResult(context, result);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _load() async {
    if (!mounted || !widget.canRead.value || _loading) return;
    setState(() {
      _loading = true;
      _rows = const [];
      _failure = null;
    });
    final now = DateTime.now();
    final timeStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final result = await widget.load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _lastRefreshTime = timeStr;
      _failure = result.failureOrNull;
      _rows = result.valueOrNull ?? const [];
      _hasLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) => Theme(
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _bookingReportTopBar(
                  title: '开台预留记录',
                  refreshLabel: _lastRefreshTime.isNotEmpty
                      ? '最近刷新时间：$_lastRefreshTime'
                      : '',
                  onClose: _close,
                  onRefresh: () => unawaited(_load()),
                  loading: _loading,
                  onExport: widget.onExport != null
                      ? () => unawaited(_export())
                      : null,
                  exporting: _exporting,
                  exportKey: BookListScreen.exportButtonKey,
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildTable()),
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

  Widget _buildTable() {
    const columns = [
      '序号', '预留时间', '预留客人姓名', '客人电话', '订位人部门', '订位人',
      '区域', '台号', '卡台标记', '状态', '状态变更时间', '备注', '咨客',
    ];
    final colWidths = [
      60.0, 140.0, 110.0, 120.0, 120.0, 100.0,
      100.0, 100.0, 90.0, 90.0, 140.0, 150.0, 100.0,
    ];
    final totalWidth = colWidths.reduce((a, b) => a + b);

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failure != null) {
      return Center(child: Text(_failure!.safeMessage, style: const TextStyle(color: Colors.redAccent)));
    }
    if (_rows.isEmpty && _hasLoaded) {
      return const Center(child: Text('暂无数据', style: TextStyle(color: Colors.white54)));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Scrollbar(
        controller: _horizontal,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontal,
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
                    controller: _vertical,
                    child: ListView.builder(
                      controller: _vertical,
                      itemCount: _rows.length,
                      itemBuilder: (context, index) {
                        final r = _rows[index];
                        final cells = [
                          '${index + 1}', r.bookTime, r.customerName, r.customerPhone,
                          r.salesDeptName, r.salesEmpName, r.regionName, r.seatName,
                          r.mark, r.status, r.statusChgTime, r.remark, r.operatorName,
                        ];
                        final bg = index.isEven ? _bgDark : _rowAltBg;
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
    );
  }
}

// ============================================================================
// 4. 线上预订记录界面
// ============================================================================
final class OnlineBookListScreen extends StatefulWidget {
  const OnlineBookListScreen({
    required this.load,
    required this.canRead,
    this.onExport,
    super.key,
  });

  static const Key exportButtonKey = Key('online-book-list-export');

  final OnlineBookListLoader load;
  final BookingReportExporter? onExport;
  final ValueListenable<bool> canRead;

  @override
  State<OnlineBookListScreen> createState() => _OnlineBookListScreenState();
}

final class _OnlineBookListScreenState extends State<OnlineBookListScreen> {
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();
  List<OnlineBookListRow> _rows = const [];
  AppFailure? _failure;
  bool _loading = false;
  bool _exporting = false;
  bool _hasLoaded = false;
  String _lastRefreshTime = '';

  @override
  void initState() {
    super.initState();
    if (widget.canRead.value) unawaited(_load());
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  void _close() => unawaited(Navigator.of(context).maybePop());

  Future<void> _export() async {
    final exporter = widget.onExport;
    if (exporter == null || _exporting || !mounted) return;
    setState(() => _exporting = true);
    try {
      final result = await exporter();
      if (!mounted) return;
      await _showReportExportResult(context, result);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _load() async {
    if (!mounted || !widget.canRead.value || _loading) return;
    setState(() {
      _loading = true;
      _rows = const [];
      _failure = null;
    });
    final now = DateTime.now();
    final timeStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final result = await widget.load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _lastRefreshTime = timeStr;
      _failure = result.failureOrNull;
      _rows = result.valueOrNull ?? const [];
      _hasLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) => Theme(
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _bookingReportTopBar(
                  title: '线上预订记录',
                  refreshLabel: _lastRefreshTime.isNotEmpty
                      ? '最近刷新时间：$_lastRefreshTime'
                      : '',
                  onClose: _close,
                  onRefresh: () => unawaited(_load()),
                  loading: _loading,
                  onExport: widget.onExport != null
                      ? () => unawaited(_export())
                      : null,
                  exporting: _exporting,
                  exportKey: OnlineBookListScreen.exportButtonKey,
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildTable()),
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

  Widget _buildTable() {
    const columns = [
      '序号', '卡台名称', '区域', '客人姓名', '手机号', '预订时间',
      '开台时间', '预付金', '预付金(已使用)', '预付金(剩余)', '预付金(退还)', '状态', '备注',
    ];
    final colWidths = [
      60.0, 110.0, 100.0, 100.0, 120.0, 140.0,
      140.0, 100.0, 120.0, 110.0, 110.0, 90.0, 150.0,
    ];
    final totalWidth = colWidths.reduce((a, b) => a + b);

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failure != null) {
      return Center(child: Text(_failure!.safeMessage, style: const TextStyle(color: Colors.redAccent)));
    }
    if (_rows.isEmpty && _hasLoaded) {
      return const Center(child: Text('暂无数据', style: TextStyle(color: Colors.white54)));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Scrollbar(
        controller: _horizontal,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontal,
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
                    controller: _vertical,
                    child: ListView.builder(
                      controller: _vertical,
                      itemCount: _rows.length,
                      itemBuilder: (context, index) {
                        final r = _rows[index];
                        final cells = [
                          '${index + 1}', r.seatName, r.regionName, r.customerName,
                          r.customerPhone, r.orderTime, r.openTime, r.prepayAmount,
                          r.usedAmount, r.balanceAmount, r.refundAmount, r.status, r.remark,
                        ];
                        final bg = index.isEven ? _bgDark : _rowAltBg;
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
    );
  }
}

// ============================================================================
// 5. 入客数据实时汇总界面
// ============================================================================
final class SeatOpeningScreen extends StatefulWidget {
  const SeatOpeningScreen({
    required this.load,
    required this.canRead,
    this.onExport,
    super.key,
  });

  static const Key exportButtonKey = Key('seat-opening-export');

  final SeatOpeningLoader load;
  final BookingReportExporter? onExport;
  final ValueListenable<bool> canRead;

  @override
  State<SeatOpeningScreen> createState() => _SeatOpeningScreenState();
}

final class _SeatOpeningScreenState extends State<SeatOpeningScreen> {
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();
  List<SeatOpeningRow> _rows = const [];
  AppFailure? _failure;
  bool _loading = false;
  bool _exporting = false;
  bool _hasLoaded = false;
  String _lastRefreshTime = '';

  @override
  void initState() {
    super.initState();
    if (widget.canRead.value) unawaited(_load());
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  void _close() => unawaited(Navigator.of(context).maybePop());

  Future<void> _export() async {
    final exporter = widget.onExport;
    if (exporter == null || _exporting || !mounted) return;
    setState(() => _exporting = true);
    try {
      final result = await exporter();
      if (!mounted) return;
      await _showReportExportResult(context, result);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _load() async {
    if (!mounted || !widget.canRead.value || _loading) return;
    setState(() {
      _loading = true;
      _rows = const [];
      _failure = null;
    });
    final now = DateTime.now();
    final timeStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final result = await widget.load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _lastRefreshTime = timeStr;
      _failure = result.failureOrNull;
      _rows = result.valueOrNull ?? const [];
      _hasLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) => Theme(
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _bookingReportTopBar(
                  title: '入客数据实时汇总表',
                  refreshLabel: _lastRefreshTime.isNotEmpty
                      ? '最近刷新时间：$_lastRefreshTime'
                      : '',
                  onClose: _close,
                  onRefresh: () => unawaited(_load()),
                  loading: _loading,
                  onExport: widget.onExport != null
                      ? () => unawaited(_export())
                      : null,
                  exporting: _exporting,
                  exportKey: SeatOpeningScreen.exportButtonKey,
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildTable()),
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

  Widget _buildTable() {
    const columns = [
      '部门/区域', '20点(含前)', '21点', '22点', '23点', '0点',
      '1点', '2点', '3点', '4点', '5点', '6点(含后)',
    ];
    final colWidths = [
      160.0, 95.0, 95.0, 95.0, 95.0, 95.0,
      95.0, 95.0, 95.0, 95.0, 95.0, 95.0,
    ];
    final totalWidth = colWidths.reduce((a, b) => a + b);

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failure != null) {
      return Center(child: Text(_failure!.safeMessage, style: const TextStyle(color: Colors.redAccent)));
    }
    if (_rows.isEmpty && _hasLoaded) {
      return const Center(child: Text('暂无数据', style: TextStyle(color: Colors.white54)));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Scrollbar(
        controller: _horizontal,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontal,
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
                    controller: _vertical,
                    child: ListView.builder(
                      controller: _vertical,
                      itemCount: _rows.length,
                      itemBuilder: (context, index) {
                        final r = _rows[index];
                        final cells = [
                          r.name, r.c20, r.c21, r.c22, r.c23, r.c00,
                          r.c01, r.c02, r.c03, r.c04, r.c05, r.c06,
                        ];
                        final bg = index.isEven ? _bgDark : _rowAltBg;
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
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: i == 0 ? Colors.white : Colors.white70,
                                        fontWeight: i == 0 ? FontWeight.w500 : FontWeight.normal,
                                      ),
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
    );
  }
}

// ============================================================================
// 6. 部门实时订台/区域开台界面
// ============================================================================
final class DeptRegionSeatOpenScreen extends StatefulWidget {
  const DeptRegionSeatOpenScreen({
    required this.load,
    required this.canRead,
    this.onExport,
    super.key,
  });

  static const Key exportButtonKey = Key('dept-region-seat-open-export');

  final DeptRegionSeatOpenLoader load;
  final BookingReportExporter? onExport;
  final ValueListenable<bool> canRead;

  @override
  State<DeptRegionSeatOpenScreen> createState() => _DeptRegionSeatOpenScreenState();
}

final class _DeptRegionSeatOpenScreenState extends State<DeptRegionSeatOpenScreen> {
  final ScrollController _deptScrollController = ScrollController();
  final ScrollController _regionScrollController = ScrollController();
  final ScrollController _narrowScrollController = ScrollController();
  DeptRegionSeatOpenData? _data;
  AppFailure? _failure;
  bool _loading = false;
  bool _exporting = false;
  bool _hasLoaded = false;
  String _lastRefreshTime = '';

  @override
  void initState() {
    super.initState();
    if (widget.canRead.value) unawaited(_load());
  }

  @override
  void dispose() {
    _deptScrollController.dispose();
    _regionScrollController.dispose();
    _narrowScrollController.dispose();
    super.dispose();
  }

  void _close() => unawaited(Navigator.of(context).maybePop());

  Future<void> _export() async {
    final exporter = widget.onExport;
    if (exporter == null || _exporting || !mounted) return;
    setState(() => _exporting = true);
    try {
      final result = await exporter();
      if (!mounted) return;
      await _showReportExportResult(context, result);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _load() async {
    if (!mounted || !widget.canRead.value || _loading) return;
    setState(() {
      _loading = true;
      _data = null;
      _failure = null;
    });
    final now = DateTime.now();
    final timeStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final result = await widget.load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _lastRefreshTime = timeStr;
      _failure = result.failureOrNull;
      _data = result.valueOrNull;
      _hasLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) => Theme(
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
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: const {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
            PointerDeviceKind.unknown,
          },
        ),
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _bookingReportTopBar(
                    title: '部门实时订台/区域开台表',
                    refreshLabel: _lastRefreshTime.isNotEmpty
                        ? '最后刷新时间：${_data?.nowTime.isNotEmpty == true ? _data!.nowTime : _lastRefreshTime}'
                        : '',
                    onClose: _close,
                    onRefresh: () => unawaited(_load()),
                    loading: _loading,
                    onExport: widget.onExport != null
                        ? () => unawaited(_export())
                        : null,
                    exporting: _exporting,
                    exportKey: DeptRegionSeatOpenScreen.exportButtonKey,
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildContent()),
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
    ),
  );

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failure != null) {
      return Center(child: Text(_failure!.safeMessage, style: const TextStyle(color: Colors.redAccent)));
    }
    final data = _data;
    if (data == null && _hasLoaded) {
      return const Center(child: Text('暂无数据', style: TextStyle(color: Colors.white54)));
    }
    if (data == null) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildDeptSection(data.deptList, isWide: true)),
              const SizedBox(width: 16),
              Expanded(child: _buildRegionSection(data.regionList, isWide: true)),
            ],
          );
        } else {
          return Scrollbar(
            controller: _narrowScrollController,
            thumbVisibility: true,
            interactive: true,
            child: SingleChildScrollView(
              controller: _narrowScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildDeptSection(data.deptList, isWide: false),
                  const SizedBox(height: 16),
                  _buildRegionSection(data.regionList, isWide: false),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildDeptSection(List<DeptRegionItem> list, {required bool isWide}) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: _borderColor),
      borderRadius: BorderRadius.circular(6),
      color: _bgDark,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: _headerBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  '订台部门 (实时订台数)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Text(
                '数量',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
        if (list.isEmpty)
          isWide
              ? const Expanded(
                  child: Center(child: Text('暂无数据', style: TextStyle(color: Colors.white38))),
                )
              : const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('暂无数据', style: TextStyle(color: Colors.white38))),
                )
        else if (isWide)
          Expanded(
            child: Scrollbar(
              controller: _deptScrollController,
              thumbVisibility: true,
              interactive: true,
              child: ListView.builder(
                controller: _deptScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  final isTotal = item.isTotal;
                  final bg = isTotal
                      ? const Color(0xff1E3A5F)
                      : (index.isEven ? _bgDark : _rowAltBg);
                  return Container(
                    color: bg,
                    padding: EdgeInsets.only(
                      left: 16.0 + item.indent * 12.0,
                      right: 16,
                      top: 8,
                      bottom: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: isTotal ? const Color(0xff60A5FA) : Colors.white,
                              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          item.count,
                          style: TextStyle(
                            fontSize: 13,
                            color: isTotal ? const Color(0xff60A5FA) : Colors.white70,
                            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final isTotal = item.isTotal;
              final bg = isTotal
                  ? const Color(0xff1E3A5F)
                  : (index.isEven ? _bgDark : _rowAltBg);
              return Container(
                color: bg,
                padding: EdgeInsets.only(
                  left: 16.0 + item.indent * 12.0,
                  right: 16,
                  top: 8,
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: isTotal ? const Color(0xff60A5FA) : Colors.white,
                          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      item.count,
                      style: TextStyle(
                        fontSize: 13,
                        color: isTotal ? const Color(0xff60A5FA) : Colors.white70,
                        fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    ),
  );

  Widget _buildRegionSection(List<DeptRegionItem> list, {required bool isWide}) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: _borderColor),
      borderRadius: BorderRadius.circular(6),
      color: _bgDark,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: _headerBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  '区域 (开台总数)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Text(
                '开台总数',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
        if (list.isEmpty)
          isWide
              ? const Expanded(
                  child: Center(child: Text('暂无数据', style: TextStyle(color: Colors.white38))),
                )
              : const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('暂无数据', style: TextStyle(color: Colors.white38))),
                )
        else if (isWide)
          Expanded(
            child: Scrollbar(
              controller: _regionScrollController,
              thumbVisibility: true,
              interactive: true,
              child: ListView.builder(
                controller: _regionScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  final isTotal = item.isTotal;
                  final bg = isTotal
                      ? const Color(0xff1E3A5F)
                      : (index.isEven ? _bgDark : _rowAltBg);
                  return Container(
                    color: bg,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: isTotal ? const Color(0xff60A5FA) : Colors.white,
                              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          item.count,
                          style: TextStyle(
                            fontSize: 13,
                            color: isTotal ? const Color(0xff60A5FA) : Colors.white70,
                            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final isTotal = item.isTotal;
              final bg = isTotal
                  ? const Color(0xff1E3A5F)
                  : (index.isEven ? _bgDark : _rowAltBg);
              return Container(
                color: bg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: isTotal ? const Color(0xff60A5FA) : Colors.white,
                          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      item.count,
                      style: TextStyle(
                        fontSize: 13,
                        color: isTotal ? const Color(0xff60A5FA) : Colors.white70,
                        fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    ),
  );
}
