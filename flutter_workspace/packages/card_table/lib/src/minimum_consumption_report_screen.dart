import 'dart:async';
import 'dart:math' as math;

import 'package:card_table/src/minimum_consumption_report.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:foundation/foundation.dart';

final class MinimumConsumptionReportScreen extends StatefulWidget {
  const MinimumConsumptionReportScreen({
    required this.load,
    required this.canRead,
    super.key,
  });

  final MinimumConsumptionLoader load;
  final ValueListenable<bool> canRead;

  @override
  State<MinimumConsumptionReportScreen> createState() =>
      _MinimumConsumptionReportScreenState();
}

final class _MinimumConsumptionReportScreenState
    extends State<MinimumConsumptionReportScreen> {
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();
  List<MinimumConsumptionReportRow> _rows = const [];
  AppFailure? _failure;
  bool _loading = false;
  bool _hasLoaded = false;
  bool _readRefreshScheduled = false;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    widget.canRead.addListener(_readAccessChanged);
    if (widget.canRead.value) unawaited(_load());
  }

  @override
  void didUpdateWidget(MinimumConsumptionReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.canRead, widget.canRead)) {
      oldWidget.canRead.removeListener(_readAccessChanged);
      widget.canRead.addListener(_readAccessChanged);
      _invalidate();
    } else if (oldWidget.load != widget.load) {
      _invalidate();
    }
  }

  void _readAccessChanged() {
    if (!mounted) return;
    if (!widget.canRead.value) _invalidate();
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // Another route can revoke access during its build or disposal. Clear
      // sensitive state synchronously; only defer marking this route dirty.
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

  void _invalidate() {
    // A subsequent true must not revive a response from an earlier permission
    // or session generation, including false→true before the next frame.
    _requestVersion++;
    _rows = const [];
    _failure = null;
    _loading = false;
    _hasLoaded = false;
  }

  Future<void> _load() async {
    if (!mounted || !widget.canRead.value || _loading) return;
    final version = ++_requestVersion;
    setState(() {
      _loading = true;
      _rows = const [];
      _failure = null;
      _hasLoaded = false;
    });
    Result<List<MinimumConsumptionReportRow>> result;
    try {
      result = await widget.load();
    } on Object {
      result = const FailureResult(_loadFailure);
    }
    if (!mounted || version != _requestVersion || !widget.canRead.value) return;
    setState(() {
      _loading = false;
      _failure = result.failureOrNull;
      _hasLoaded = _failure == null;
      _rows = List<MinimumConsumptionReportRow>.unmodifiable(
        result.valueOrNull ?? const [],
      );
    });
  }

  @override
  void dispose() {
    _requestVersion++;
    widget.canRead.removeListener(_readAccessChanged);
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  void _close() => unawaited(Navigator.of(context).maybePop());

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3373E8)),
    ),
    child: Scaffold(
      backgroundColor: const Color(0xffFAFAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '低消进度统计表',
                      style: TextStyle(fontSize: 24, color: Color(0xff08080A)),
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭统计表',
                    onPressed: _close,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(child: _table()),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: widget.canRead.value && !_loading
                        ? () => unawaited(_load())
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xff3373E8),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: _close,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xffDCE1EA),
                      foregroundColor: const Color(0xff08080A),
                      minimumSize: const Size(130, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('关闭', style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _table() => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.max(_minimumTableWidth, constraints.maxWidth);
      final message = !widget.canRead.value
          ? '当前不可查询低消进度统计表'
          : _failure?.safeMessage ?? (_hasLoaded ? '暂无数据' : '点击重试查询低消进度统计表');
      return Stack(
        children: [
          Scrollbar(
            controller: _vertical,
            thumbVisibility: true,
            notificationPredicate: (notification) =>
                notification.metrics.axis == Axis.vertical,
            child: Scrollbar(
              controller: _horizontal,
              thumbVisibility: true,
              notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _horizontal,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      _tableRow(
                        MinimumConsumptionReportRow.columnLabels,
                        const Color(0xffC4CBD7),
                        width,
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _vertical,
                          itemExtent: _rowHeight,
                          itemCount: _rows.length,
                          itemBuilder: (context, index) => _tableRow(
                            ['${index + 1}', ..._rows[index].cells],
                            index.isEven
                                ? const Color(0xffDCE1EA)
                                : const Color(0xffECEFF4),
                            width,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_rows.isEmpty)
            Positioned.fill(
              top: _rowHeight,
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator(color: Color(0xff3373E8))
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xff08080A),
                          ),
                        ),
                      ),
              ),
            ),
        ],
      );
    },
  );

  Widget _tableRow(List<String> cells, Color color, double width) => ColoredBox(
    color: color,
    child: SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          for (var index = 0; index < cells.length; index++)
            SizedBox(
              width: _columnWidths[index] * width / _minimumTableWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  cells[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Color(0xff08080A),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  static const double _rowHeight = 56;
  static const List<double> _columnWidths = [
    100,
    100,
    140,
    240,
    160,
    160,
    150,
    150,
    150,
    150,
    240,
    160,
  ];
  static const double _minimumTableWidth = 2000;
  static const AppFailure _loadFailure = AppFailure(
    kind: FailureKind.unknown,
    code: 'minimum_consumption_report.load_failed',
    safeMessage: '低消进度统计表查询失败，请重试',
  );
}
