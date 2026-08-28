import 'dart:async';

import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/legacy_card_table_store.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

typedef CardTableSessionAction = Future<Result<void>> Function();

final class CardTableScreen extends StatefulWidget {
  const CardTableScreen({
    required this.system,
    required this.events,
    required this.connectionPhase,
    this.lastFailure,
    this.onLogout,
    this.onSwitchSystem,
    this.onOpenBusinessDay,
    super.key,
  });

  static const Key searchKey = Key('card-table-search');
  static const Key gridKey = Key('card-table-grid');
  static const Key logoutKey = Key('card-table-logout');
  static const Key switchSystemKey = Key('card-table-switch-system');
  static const Key openBusinessDayKey = Key('card-table-open-business-day');

  final BusinessSystem system;
  final Stream<SyncEnvelope> events;
  final ConnectionPhase connectionPhase;
  final AppFailure? lastFailure;
  final CardTableSessionAction? onLogout;
  final CardTableSessionAction? onSwitchSystem;
  final CardTableSessionAction? onOpenBusinessDay;

  @override
  State<CardTableScreen> createState() => _CardTableScreenState();
}

final class _CardTableScreenState extends State<CardTableScreen> {
  final LegacyCardTableStore _store = LegacyCardTableStore();
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<SyncEnvelope>? _subscription;
  CardTableSnapshot? _snapshot;
  AppFailure? _failure;
  String? _regionId;
  int? _businessStatus;
  bool _sessionActionInProgress = false;
  AppFailure? _sessionFailure;
  bool _businessDayOpening = false;
  AppFailure? _businessDayFailure;
  String? _businessDayMessage;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(CardTableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.events, widget.events)) _subscribe();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _searchController.dispose();
    super.dispose();
  }

  void _subscribe() {
    unawaited(_subscription?.cancel());
    _subscription = widget.events.listen((event) {
      final result = _store.applyEnvelope(event);
      if (!mounted) return;
      setState(() {
        _snapshot = result.valueOrNull ?? _snapshot;
        _failure = result.failureOrNull;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.system.label} · 卡台列表'),
        actions: <Widget>[
          if (widget.onSwitchSystem != null)
            TextButton(
              key: CardTableScreen.switchSystemKey,
              onPressed: _sessionActionInProgress
                  ? null
                  : () => _runSessionAction(widget.onSwitchSystem!),
              child: const Text('切换系统'),
            ),
          if (widget.onLogout != null)
            TextButton(
              key: CardTableScreen.logoutKey,
              onPressed: _sessionActionInProgress
                  ? null
                  : () => _runSessionAction(widget.onLogout!),
              child: const Text('退出登录'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: <Widget>[
          _connectionBanner(context),
          if (_sessionFailure case final failure?)
            ColoredBox(
              color: Theme.of(context).colorScheme.errorContainer,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(failure.safeMessage, textAlign: TextAlign.center),
                ),
              ),
            ),
          if (snapshot != null && !snapshot.businessOpen)
            _closedBusinessDayBanner(context),
          if (snapshot == null)
            Expanded(child: _waitingState(context))
          else ...<Widget>[
            _filters(snapshot),
            Expanded(child: _tableGrid(snapshot)),
          ],
        ],
      ),
    );
  }

  Widget _connectionBanner(BuildContext context) {
    final color = switch (widget.connectionPhase) {
      ConnectionPhase.online => Colors.green,
      ConnectionPhase.reconciling => Colors.orange,
      ConnectionPhase.blocked => Theme.of(context).colorScheme.error,
    };
    final label = switch (widget.connectionPhase) {
      ConnectionPhase.online => '服务端状态已同步',
      ConnectionPhase.reconciling => '正在同步卡台数据',
      ConnectionPhase.blocked => '网络不可用，业务操作已禁用',
    };
    return ColoredBox(
      color: color,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Future<void> _runSessionAction(CardTableSessionAction action) async {
    if (_sessionActionInProgress) return;
    setState(() {
      _sessionActionInProgress = true;
      _sessionFailure = null;
    });
    Result<void> result;
    try {
      result = await action();
    } on Object {
      result = const FailureResult<void>(_sessionActionFailure);
    }
    if (!mounted) return;
    setState(() {
      _sessionActionInProgress = false;
      _sessionFailure = result.failureOrNull;
    });
  }

  Widget _closedBusinessDayBanner(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.tertiaryContainer,
    child: SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: <Widget>[
            const Expanded(child: Text('营业日未开启')),
            if (_businessDayFailure case final failure?)
              Expanded(child: Text(failure.safeMessage))
            else if (_businessDayMessage case final message?)
              Expanded(child: Text(message)),
            if (widget.system == BusinessSystem.booking &&
                widget.onOpenBusinessDay != null)
              FilledButton(
                key: CardTableScreen.openBusinessDayKey,
                onPressed:
                    widget.connectionPhase.allowsWrites && !_businessDayOpening
                    ? _confirmOpenBusinessDay
                    : null,
                child: Text(_businessDayOpening ? '开启中…' : '开启营业日'),
              )
            else
              const Text('卡台仅供查看'),
          ],
        ),
      ),
    ),
  );

  Future<void> _confirmOpenBusinessDay() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('开启营业日'),
        content: const Text('是否确认开启营业日？'),
        actions: <Widget>[
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
    if (confirmed != true || !mounted) return;
    setState(() {
      _businessDayOpening = true;
      _businessDayFailure = null;
      _businessDayMessage = null;
    });
    Result<void> result;
    try {
      result = await widget.onOpenBusinessDay!();
    } on Object {
      result = const FailureResult<void>(_businessDayActionFailure);
    }
    if (!mounted) return;
    setState(() {
      _businessDayOpening = false;
      _businessDayFailure = result.failureOrNull;
      _businessDayMessage = result.failureOrNull == null
          ? '开启请求已提交，等待服务端同步'
          : null;
    });
  }

  Widget _waitingState(BuildContext context) {
    final failure = _failure ?? widget.lastFailure;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(failure?.safeMessage ?? '正在等待完整卡台数据'),
      ),
    );
  }

  Widget _filters(CardTableSnapshot snapshot) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Column(
      children: <Widget>[
        TextField(
          key: CardTableScreen.searchKey,
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: '搜索卡台或客户',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              ChoiceChip(
                label: const Text('全部区域'),
                selected: _regionId == null,
                onSelected: (_) => setState(() => _regionId = null),
              ),
              for (final region in snapshot.regions) ...<Widget>[
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(region.name),
                  selected: _regionId == region.id,
                  onSelected: (_) => setState(() => _regionId = region.id),
                ),
              ],
              const SizedBox(width: 16),
              DropdownButton<int?>(
                value: _businessStatus,
                hint: const Text('全部状态'),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('全部状态'),
                  ),
                  for (final status in <int>[1, 2, 3, 4, 5, 6, 7, 8])
                    DropdownMenuItem<int?>(
                      value: status,
                      child: Text(_statusLabel(status)),
                    ),
                ],
                onChanged: (value) => setState(() => _businessStatus = value),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _tableGrid(CardTableSnapshot snapshot) {
    final keyword = _searchController.text.trim().toLowerCase();
    final tables = snapshot.tables
        .where((table) {
          if (_regionId != null && table.regionId != _regionId) return false;
          if (_businessStatus != null &&
              table.businessStatus != _businessStatus) {
            return false;
          }
          if (keyword.isEmpty) return true;
          return table.name.toLowerCase().contains(keyword) ||
              table.customerName.toLowerCase().contains(keyword);
        })
        .toList(growable: false);
    if (tables.isEmpty) return const Center(child: Text('没有符合条件的卡台'));
    final regionNames = <String, String>{
      for (final region in snapshot.regions) region.id: region.name,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 260).floor().clamp(1, 6);
        return GridView.builder(
          key: CardTableScreen.gridKey,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 1.6,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            final table = tables[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      table.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(regionNames[table.regionId] ?? '未知区域'),
                    Text(_statusLabel(table.businessStatus)),
                    if (table.customerName.isNotEmpty)
                      Text('客户：${table.customerName}'),
                    Text('消费：${table.orderAmount}  已付：${table.paidAmount}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _statusLabel(int status) => switch (status) {
    1 => '空台',
    2 => '锁定',
    3 => '预订',
    4 => '开台',
    5 => '点单未结',
    6 => '部分结账',
    7 => '已结账',
    8 => '线上预订',
    _ => '未知状态',
  };

  static const AppFailure _sessionActionFailure = AppFailure(
    kind: FailureKind.unknown,
    code: 'session.action_failed',
    safeMessage: '登录状态切换失败，请重试',
  );
  static const AppFailure _businessDayActionFailure = AppFailure(
    kind: FailureKind.unknown,
    code: 'business_day.action_failed',
    safeMessage: '开启营业日失败，请重试',
  );
}
