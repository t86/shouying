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
    this.onRefresh,
    this.onOpenDiagnostics,
    this.userName,
    this.showCustomerDetails = false,
    this.machineId,
    this.stationId,
    super.key,
  });

  static const Key searchKey = Key('card-table-search');
  static const Key gridKey = Key('card-table-grid');
  static const Key logoutKey = Key('card-table-logout');
  static const Key switchSystemKey = Key('card-table-switch-system');
  static const Key openBusinessDayKey = Key('card-table-open-business-day');
  static const Key refreshKey = Key('card-table-refresh');
  static const Key moreFunctionsKey = Key('card-table-more-functions');
  static const Key openDiagnosticsKey = Key('card-table-open-diagnostics');
  static Key cardKey(String id) => ValueKey<String>('card-table-$id');

  final BusinessSystem system;
  final Stream<SyncEnvelope> events;
  final ConnectionPhase connectionPhase;
  final AppFailure? lastFailure;
  final CardTableSessionAction? onLogout;
  final CardTableSessionAction? onSwitchSystem;
  final CardTableSessionAction? onOpenBusinessDay;
  final CardTableSessionAction? onRefresh;
  final VoidCallback? onOpenDiagnostics;
  final String? userName;
  final bool showCustomerDetails;
  final String? machineId;
  final String? stationId;

  @override
  State<CardTableScreen> createState() => _CardTableScreenState();
}

final class _CardTableScreenState extends State<CardTableScreen> {
  late LegacyCardTableStore _store;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<SyncEnvelope>? _subscription;
  CardTableSnapshot? _snapshot;
  AppFailure? _failure;
  String? _regionId;
  int? _businessStatus;
  String? _businessDateId;
  bool _sessionActionInProgress = false;
  AppFailure? _sessionFailure;
  bool _businessDayOpening = false;
  AppFailure? _businessDayFailure;
  String? _businessDayMessage;

  @override
  void initState() {
    super.initState();
    _store = LegacyCardTableStore(
      machineId: widget.machineId,
      stationId: widget.stationId,
    );
    _subscribe();
  }

  @override
  void didUpdateWidget(CardTableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.machineId != widget.machineId ||
        oldWidget.stationId != widget.stationId) {
      _store = LegacyCardTableStore(
        machineId: widget.machineId,
        stationId: widget.stationId,
      );
      _snapshot = null;
      _failure = null;
      _subscribe();
    } else if (!identical(oldWidget.events, widget.events)) {
      _subscribe();
    }
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
        final dates = _snapshot?.businessDates ?? const <CardBusinessDate>[];
        if (dates.isNotEmpty &&
            !dates.any((date) => date.id == _businessDateId)) {
          _businessDateId = dates.first.id;
        }
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
          if (snapshot == null)
            Expanded(child: _waitingState(context))
          else ...<Widget>[
            if (snapshot.businessDates.isNotEmpty) _dateTabs(snapshot),
            _filters(snapshot),
            if (!snapshot.businessOpen) _closedBusinessDayBanner(context),
            Expanded(child: _tableGrid(snapshot)),
            _statusFooter(snapshot),
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

  Widget _dateTabs(CardTableSnapshot snapshot) => ColoredBox(
    color: const Color(0xff1e3152),
    child: SizedBox(
      width: double.infinity,
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        scrollDirection: Axis.horizontal,
        itemCount: snapshot.businessDates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = snapshot.businessDates[index];
          return ChoiceChip(
            label: Text(date.label),
            selected: date.id == _businessDateId,
            onSelected: (_) => setState(() {
              _businessDateId = date.id;
              _businessStatus = null;
              _searchController.clear();
            }),
          );
        },
      ),
    ),
  );

  Widget _filters(CardTableSnapshot snapshot) => ColoredBox(
    color: const Color(0xff1e3152),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Column(
        children: <Widget>[
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
                const SizedBox(width: 12),
                DropdownButton<int?>(
                  value: _businessStatus,
                  hint: const Text('全部状态'),
                  dropdownColor: const Color(0xff1e3152),
                  style: const TextStyle(color: Colors.white),
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
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: TextField(
              key: CardTableScreen.searchKey,
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.showCustomerDetails ? '卡台名称 / 客人' : '卡台名称',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white70,
                  size: 20,
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _tableGrid(CardTableSnapshot snapshot) {
    final keyword = _searchController.text.trim().toLowerCase();
    final tables = snapshot
        .tablesForDate(_businessDateId)
        .where((table) {
          if (_regionId != null && table.regionId != _regionId) return false;
          if (_businessStatus != null &&
              !_matchesStatusFilter(table.businessStatus, _businessStatus!)) {
            return false;
          }
          if (keyword.isEmpty) return true;
          return table.name.toLowerCase().contains(keyword) ||
              (widget.showCustomerDetails &&
                  table.customerName.toLowerCase().contains(keyword));
        })
        .toList(growable: false);
    if (tables.isEmpty) return const Center(child: Text('没有符合条件的卡台'));
    final regionNames = <String, String>{
      for (final region in snapshot.regions) region.id: region.name,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 178).floor().clamp(1, 12);
        return ColoredBox(
          color: const Color(0xff203253),
          child: GridView.builder(
            key: CardTableScreen.gridKey,
            padding: const EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 1.12,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              return Card(
                color: _statusColor(table.businessStatus),
                margin: EdgeInsets.zero,
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: Colors.white),
                  child: InkWell(
                    key: CardTableScreen.cardKey(table.id),
                    onTap: () => _showCardMenu(snapshot, table),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  regionNames[table.regionId] ?? '未知区域',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${table.capacity > 0 ? table.capacity : 1}人',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            table.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: Colors.white),
                          ),
                          const Spacer(),
                          Text(_statusLabel(table.businessStatus)),
                          if (widget.showCustomerDetails &&
                              table.customerName.isNotEmpty)
                            Text(
                              table.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _statusFooter(CardTableSnapshot snapshot) {
    final tables = snapshot
        .tablesForDate(_businessDateId)
        .where((table) => _regionId == null || table.regionId == _regionId);
    final derived = <int, int>{};
    for (final table in tables) {
      derived.update(
        table.businessStatus,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final isCurrentDate =
        _businessDateId == snapshot.businessDates.firstOrNull?.id;
    final counts = isCurrentDate
        ? snapshot.statusCountsForRegion(_regionId)
        : derived;
    int count(int status) =>
        counts[status] ?? (isCurrentDate ? 0 : derived[status] ?? 0);
    return ColoredBox(
      color: const Color(0xff0d1a31),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: IconTheme.merge(
          data: const IconThemeData(color: Colors.white70),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: <Widget>[
                        _legendItem('空台', count(1), 1),
                        _legendItem('预订', count(8), 8),
                        _legendItem('开台', counts[10] ?? 0, 4),
                        _legendItem('点单', count(5) + count(6), 5),
                        _legendItem('已结', count(7), 7),
                        _legendItem('抵达数', counts[20] ?? 0, 20),
                      ],
                    ),
                  ),
                  if (widget.onRefresh != null)
                    TextButton.icon(
                      key: CardTableScreen.refreshKey,
                      onPressed: _sessionActionInProgress
                          ? null
                          : () => _runSessionAction(widget.onRefresh!),
                      icon: const Icon(Icons.refresh),
                      label: const Text('刷新'),
                    ),
                  TextButton.icon(
                    key: CardTableScreen.moreFunctionsKey,
                    onPressed: _showMoreFunctions,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('更多功能'),
                  ),
                  if (widget.userName case final userName?)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(userName),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCardMenu(
    CardTableSnapshot snapshot,
    CardTable table,
  ) async {
    final actions = _cardActions(snapshot, table);
    if (actions.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('当前卡台没有可用操作')));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text(
                  '${table.name} · ${_statusLabel(table.businessStatus)}',
                ),
                subtitle: const Text('卡台操作'),
              ),
              const Divider(height: 1),
              for (final action in actions)
                ListTile(
                  leading: Icon(action.icon),
                  title: Text(action.label),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${action.label}功能正在迁移')),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('关闭'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_CardMenuAction> _cardActions(
    CardTableSnapshot snapshot,
    CardTable table,
  ) {
    final isCurrentDate =
        _businessDateId == snapshot.businessDates.firstOrNull?.id;
    final actions = switch (widget.system) {
      BusinessSystem.booking => _bookingCardActions(
        table.businessStatus,
        businessOpen: snapshot.businessOpen,
        isCurrentDate: isCurrentDate,
      ),
      BusinessSystem.order => <_CardMenuAction>[
        if (<int>{4, 5, 6, 7}.contains(table.businessStatus)) ...const [
          _CardMenuAction('存酒', Icons.wine_bar_outlined),
          _CardMenuAction('取酒', Icons.output_outlined),
        ],
        const _CardMenuAction('充公', Icons.inventory_2_outlined),
      ],
      BusinessSystem.cashier => <_CardMenuAction>[
        if (<int>{4, 5, 6, 7}.contains(table.businessStatus))
          const _CardMenuAction('查看卡台记录', Icons.receipt_long_outlined),
      ],
    };
    return List<_CardMenuAction>.of(actions);
  }

  static List<_CardMenuAction> _bookingCardActions(
    int status, {
    required bool businessOpen,
    required bool isCurrentDate,
  }) {
    final actions = switch (status) {
      1 when !businessOpen || !isCurrentDate => <_CardMenuAction>[
        const _CardMenuAction('预留', Icons.history_toggle_off),
      ],
      1 => <_CardMenuAction>[
        const _CardMenuAction('预留', Icons.history_toggle_off),
        const _CardMenuAction('开台', Icons.play_arrow),
        const _CardMenuAction('锁定', Icons.lock_outline),
      ],
      2 when businessOpen && isCurrentDate => <_CardMenuAction>[
        const _CardMenuAction('取消锁定', Icons.lock_open),
      ],
      4 => <_CardMenuAction>[
        const _CardMenuAction('修改低消', Icons.price_change_outlined),
        const _CardMenuAction('修改订位人', Icons.person_outline),
        const _CardMenuAction('转台', Icons.swap_horiz),
        const _CardMenuAction('撤台', Icons.undo),
        const _CardMenuAction('查看卡台详情', Icons.receipt_long_outlined),
        const _CardMenuAction('修改翻台订位人', Icons.manage_accounts_outlined),
        const _CardMenuAction('修改卡台标记', Icons.flag_outlined),
        const _CardMenuAction('修改备注', Icons.edit_note_outlined),
        const _CardMenuAction('修改服务员', Icons.badge_outlined),
        const _CardMenuAction('取消必点商品', Icons.remove_shopping_cart_outlined),
      ],
      5 || 6 || 7 => <_CardMenuAction>[
        const _CardMenuAction('修改低消', Icons.price_change_outlined),
        const _CardMenuAction('修改订位人', Icons.person_outline),
        const _CardMenuAction('转台', Icons.swap_horiz),
        const _CardMenuAction('查看卡台详情', Icons.receipt_long_outlined),
        const _CardMenuAction('修改翻台订位人', Icons.manage_accounts_outlined),
        const _CardMenuAction('修改卡台标记', Icons.flag_outlined),
        const _CardMenuAction('修改备注', Icons.edit_note_outlined),
        const _CardMenuAction('修改服务员', Icons.badge_outlined),
      ],
      8 when !businessOpen || !isCurrentDate => <_CardMenuAction>[
        const _CardMenuAction('修改预留', Icons.edit_calendar_outlined),
        const _CardMenuAction('取消预留', Icons.event_busy_outlined),
      ],
      8 => <_CardMenuAction>[
        const _CardMenuAction('开台', Icons.play_arrow),
        const _CardMenuAction('转台', Icons.swap_horiz),
        const _CardMenuAction('取消预留', Icons.event_busy_outlined),
        const _CardMenuAction('修改预留', Icons.edit_calendar_outlined),
        const _CardMenuAction('修改翻台订位人', Icons.manage_accounts_outlined),
      ],
      _ => <_CardMenuAction>[],
    };
    return <_CardMenuAction>[
      ...actions,
      const _CardMenuAction('置顶', Icons.vertical_align_top),
    ];
  }

  Widget _legendItem(String label, int count, int status) => InkWell(
    onTap: status == 20
        ? null
        : () => setState(() {
            _businessStatus = _businessStatus == status ? null : status;
          }),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: status == 20 ? Colors.cyan : _statusColor(status),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Text('$label $count'),
        ],
      ),
    ),
  );

  Future<void> _showMoreFunctions() => showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final label in const <String>[
              '开台记录',
              '转台记录',
              '预留记录',
              '线上预订记录',
              '入客数据实时汇总',
              '部门实时订台 / 区域开台',
              '排队详情',
            ])
              ListTile(
                enabled: false,
                title: Text(label),
                trailing: const Text('迁移中'),
              ),
            if (widget.onOpenDiagnostics != null)
              ListTile(
                key: CardTableScreen.openDiagnosticsKey,
                leading: const Icon(Icons.devices_other),
                title: const Text('设备诊断'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onOpenDiagnostics!();
                },
              ),
          ],
        ),
      ),
    ),
  );

  static Color _statusColor(int status) => switch (status) {
    1 => const Color(0xff465675),
    2 => const Color(0xff7d6a33),
    3 || 8 => const Color(0xff008f95),
    4 => const Color(0xffd08322),
    5 || 6 => const Color(0xffc83758),
    7 => const Color(0xff5c3bc1),
    _ => const Color(0xff465675),
  };

  static bool _matchesStatusFilter(int actual, int selected) =>
      switch (selected) {
        8 => actual == 3 || actual == 8,
        5 => actual == 5 || actual == 6,
        _ => actual == selected,
      };

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

final class _CardMenuAction {
  const _CardMenuAction(this.label, this.icon);

  final String label;
  final IconData icon;
}
