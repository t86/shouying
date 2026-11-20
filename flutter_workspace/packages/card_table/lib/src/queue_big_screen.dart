import 'dart:async';

import 'package:card_table/src/booking_queue.dart';
import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/legacy_card_table_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:realtime_sync/realtime_sync.dart';

/// 格式化大屏日期时间 YYYY-MM-DD 星期X HH:mm
String formatBigScreenDate(DateTime date) {
  const weekdays = [
    '星期日',
    '星期一',
    '星期二',
    '星期三',
    '星期四',
    '星期五',
    '星期六',
  ];
  final year = date.year;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hours = date.hour.toString().padLeft(2, '0');
  final minutes = date.minute.toString().padLeft(2, '0');
  final weekday = weekdays[date.weekday % 7];
  return '$year-$month-$day $weekday $hours:$minutes';
}

/// 叫号大屏显示数据行
final class QueueBigScreenRowData {
  const QueueBigScreenRowData({
    required this.typeId,
    required this.typeName,
    required this.currNum,
    required this.takenNum,
    required this.waitNum,
    required this.waitCnt,
  });

  final int typeId;
  final String typeName;
  final String currNum;
  final String takenNum;
  final String waitNum;
  final String waitCnt;
}

/// S6.P1.T01 全屏只读叫号大屏 (`/queue/bigScreen`)
final class QueueBigScreen extends StatefulWidget {
  const QueueBigScreen({
    super.key,
    this.events,
    this.machineId,
    this.stationId,
    this.onBack,
    this.initialSnapshot,
    this.nowProvider,
  });

  final Stream<SyncEnvelope>? events;
  final String? machineId;
  final String? stationId;
  final VoidCallback? onBack;
  final CardTableSnapshot? initialSnapshot;
  final DateTime Function()? nowProvider;

  @override
  State<QueueBigScreen> createState() => _QueueBigScreenState();
}

final class _QueueBigScreenState extends State<QueueBigScreen> {
  late LegacyCardTableStore _store;
  CardTableSnapshot? _snapshot;
  StreamSubscription<SyncEnvelope>? _subscription;
  Timer? _clockTimer;
  late String _formattedDate;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _store = LegacyCardTableStore(
      machineId: widget.machineId,
      stationId: widget.stationId,
    );
    _snapshot = widget.initialSnapshot;
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateTime();
        });
      }
    });
    _subscribe();
  }

  void _updateTime() {
    final now = widget.nowProvider?.call() ?? DateTime.now();
    _formattedDate = formatBigScreenDate(now);
  }

  void _subscribe() {
    unawaited(_subscription?.cancel());
    final events = widget.events;
    if (events != null) {
      _subscription = events.listen((event) {
        final result = _store.applyEnvelope(event);
        if (!mounted) return;
        setState(() {
          _snapshot = result.valueOrNull ?? _store.currentSnapshot ?? _snapshot;
        });
      });
    }
  }

  @override
  void didUpdateWidget(QueueBigScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.events, widget.events)) {
      _subscribe();
    }
    if (widget.initialSnapshot != null &&
        widget.initialSnapshot != oldWidget.initialSnapshot) {
      _snapshot = widget.initialSnapshot;
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _toggleFullScreen();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_isFullScreen) {
          setState(() {
            _isFullScreen = false;
          });
          return KeyEventResult.handled;
        } else if (widget.onBack != null) {
          widget.onBack!();
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  List<QueueBigScreenRowData> _buildRows() {
    final snapshot = _snapshot;
    if (snapshot == null) return const [];
    final queue = snapshot.queue;
    final config = queue.config;
    final types = queue.types;
    final curNumbers = queue.curNumbers;

    final rows = <QueueBigScreenRowData>[];
    for (final type in types) {
      final cur = curNumbers.cast<QueueCurNumber?>().firstWhere(
        (c) => c?.queueTypeId == type.id,
        orElse: () => null,
      );

      if (cur == null) {
        rows.add(
          QueueBigScreenRowData(
            typeId: type.id,
            typeName: type.name,
            currNum: '-',
            takenNum: '-',
            waitNum: '-',
            waitCnt: '-',
          ),
        );
      } else {
        final currNum = cur.currNo <= 0
            ? '-'
            : formatQueueNumber(type.numPrefix, cur.currNo, config.numberType);
        final takenNum = cur.lastGenNum <= 0
            ? '-'
            : formatQueueNumber(
                type.numPrefix,
                cur.lastGenNum,
                config.numberType,
              );
        final waitNum = cur.waitNo <= 0
            ? '-'
            : formatQueueNumber(type.numPrefix, cur.waitNo, config.numberType);
        final waitCnt = '${cur.waitCnt}';

        rows.add(
          QueueBigScreenRowData(
            typeId: type.id,
            typeName: type.name,
            currNum: currNum,
            takenNum: takenNum,
            waitNum: waitNum,
            waitCnt: waitCnt,
          ),
        );
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final storeName = (_snapshot?.storeName.isNotEmpty ?? false)
        ? _snapshot!.storeName
        : '叫号大屏';
    final rows = _buildRows();

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF070B19),
        body: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F172A), Color(0xFF050814)],
              ),
            ),
            child: Column(
              children: [
                _buildHeader(storeName),
                Expanded(
                  child: rows.isEmpty
                      ? _buildEmptyState()
                      : _buildTable(rows),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String storeName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              key: const Key('queue-big-screen-back'),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white70,
                size: 26,
              ),
              tooltip: '返回',
              onPressed: widget.onBack,
            ),
          IconButton(
            key: const Key('queue-big-screen-fullscreen'),
            icon: Icon(
              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white70,
              size: 28,
            ),
            tooltip: _isFullScreen ? '退出全屏 (Esc)' : '全屏 (Enter)',
            onPressed: _toggleFullScreen,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Center(
              child: Text(
                storeName,
                key: const Key('queue-big-screen-store-name'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _formattedDate,
            key: const Key('queue-big-screen-date'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 22,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        '暂无数据',
        key: Key('queue-big-screen-empty'),
        style: TextStyle(
          color: Colors.white60,
          fontSize: 36,
          fontWeight: FontWeight.w500,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildTable(List<QueueBigScreenRowData> rows) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      child: Column(
        children: [
          // 表头
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      '类型',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      '当前叫号',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      '当前取号',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      '等待叫号',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      '等待桌数',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 表体列表
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = rows[index];
                final isEven = index % 2 == 0;
                return Container(
                  key: Key('queue-big-screen-row-${item.typeId}'),
                  padding: const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isEven
                        ? const Color(0xFF131C31).withValues(alpha: 0.6)
                        : const Color(0xFF0F172A).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 类型
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Text(
                            item.typeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // 当前叫号
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Text(
                            item.currNum,
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // 当前取号
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Text(
                            item.takenNum,
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // 等待叫号
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Text(
                            item.waitNum,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // 等待桌数
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            item.waitCnt,
                            style: const TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
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
