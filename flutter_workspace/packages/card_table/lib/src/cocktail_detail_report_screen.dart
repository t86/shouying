import 'dart:async';
import 'dart:math' as math;

import 'package:card_table/src/cocktail_detail_report.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:foundation/foundation.dart';

final class CocktailDetailReportScreen extends StatefulWidget {
  const CocktailDetailReportScreen({
    required this.load,
    required this.canRead,
    super.key,
  });

  static const Key keywordKey = Key('cocktail-detail-keyword');

  final CocktailDetailLoader load;
  final ValueListenable<bool> canRead;

  @override
  State<CocktailDetailReportScreen> createState() =>
      _CocktailDetailReportScreenState();
}

final class _CocktailDetailReportScreenState
    extends State<CocktailDetailReportScreen> {
  final TextEditingController _keyword = TextEditingController();
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();
  List<CocktailDetailReportRow> _rows = const [];
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
  void didUpdateWidget(CocktailDetailReportScreen oldWidget) {
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
    Result<List<CocktailDetailReportRow>> result;
    try {
      result = await widget.load(_keyword.text);
    } on Object {
      result = const FailureResult(_loadFailure);
    }
    if (!mounted || version != _requestVersion || !widget.canRead.value) return;
    setState(() {
      _loading = false;
      _failure = result.failureOrNull;
      _hasLoaded = _failure == null;
      _rows = List<CocktailDetailReportRow>.unmodifiable(
        result.valueOrNull ?? const [],
      );
    });
  }

  void _reset() {
    _keyword.clear();
    unawaited(_load());
  }

  @override
  void dispose() {
    _requestVersion++;
    widget.canRead.removeListener(_readAccessChanged);
    _keyword.dispose();
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
                      '鸡尾酒明细表',
                      style: TextStyle(fontSize: 24, color: Color(0xff08080A)),
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭明细表',
                    onPressed: _close,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: CocktailDetailReportScreen.keywordKey,
                      controller: _keyword,
                      enabled: widget.canRead.value && !_loading,
                      decoration: const InputDecoration(
                        hintText: '订台人/点单人/商品名称',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: widget.canRead.value && !_loading
                        ? () => unawaited(_load())
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff3373E8),
                      minimumSize: const Size(88, 40),
                    ),
                    child: const Text('查询'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: widget.canRead.value && !_loading
                        ? _reset
                        : null,
                    child: const Text('重置'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _table()),
              const SizedBox(height: 16),
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
        ),
      ),
    ),
  );

  Widget _table() => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.max(_minimumTableWidth, constraints.maxWidth);
      final message = !widget.canRead.value
          ? '当前不可查询鸡尾酒明细表'
          : _failure?.safeMessage ?? (_hasLoaded ? '暂无数据' : '点击查询鸡尾酒明细表');
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
                        [
                          ...CocktailDetailReportRow.columnLabels,
                          CocktailDetailReportRow.scrollIndicator,
                        ],
                        const Color(0xffC4CBD7),
                        width,
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _vertical,
                          itemExtent: _rowHeight,
                          itemCount: _rows.length,
                          itemBuilder: (context, index) {
                            final row = _rows[index];
                            final sequence = row.cells.first == '合计'
                                ? ''
                                : '${index + 1}';
                            return _tableRow(
                              [
                                sequence,
                                ...row.cells,
                                CocktailDetailReportRow.scrollIndicator,
                              ],
                              index.isEven
                                  ? const Color(0xffDCE1EA)
                                  : const Color(0xffECEFF4),
                              width,
                            );
                          },
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
                child: index == 14
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          cells[index],
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xff08080A),
                          ),
                        ),
                      )
                    : Text(
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

  static const double _rowHeight = 64;
  static const List<double> _columnWidths = [
    80,
    100,
    140,
    200,
    160,
    140,
    160,
    140,
    140,
    160,
    140,
    160,
    160,
    160,
    140,
    140,
    160,
    140,
    160,
    160,
    180,
    48,
  ];
  static const double _minimumTableWidth = 3200;
  static const AppFailure _loadFailure = AppFailure(
    kind: FailureKind.unknown,
    code: 'cocktail_detail_report.load_failed',
    safeMessage: '鸡尾酒明细表查询失败，请重试',
  );
}
