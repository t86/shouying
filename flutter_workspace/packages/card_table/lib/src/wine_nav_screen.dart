import 'package:card_table/src/management_route_observer.dart';
import 'package:card_table/src/management_permissions.dart';
import 'package:permissions/permissions.dart';
import 'package:protocol/protocol.dart';
import 'package:card_table/src/wine_borrow_return_views.dart';
import 'package:card_table/src/wine_confiscate_views.dart';
import 'package:card_table/src/wine_customer_views.dart';
import 'package:card_table/src/wine_inventory_views.dart';
import 'package:card_table/src/wine_loader.dart';
import 'package:card_table/src/wine_reports_screens.dart';
import 'package:card_table/src/wine_user_config_view.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';

final class _WineNavItem {
  const _WineNavItem(
    this.id,
    this.name,
    this.route, {
    this.icon = Icons.folder,
    this.children = const [],
  });

  final int id;
  final String name;
  final String route;
  final IconData icon;
  final List<_WineNavItem> children;
}

const _wineNav = <_WineNavItem>[
  _WineNavItem(
    10,
    '存酒管理',
    '/wine/saveNeedToLib',
    icon: Icons.liquor,
    children: [
      _WineNavItem(11, '存酒待入库', '/wine/saveNeedToLib', icon: Icons.login),
      _WineNavItem(12, '取酒待出库', '/wine/getNeedToLib', icon: Icons.logout),
      _WineNavItem(13, '存酒库', '/wine/saveLib', icon: Icons.inventory_2),
      _WineNavItem(
        14,
        '存酒库子订单',
        '/wine/saveLibChild',
        icon: Icons.receipt_long,
      ),
      _WineNavItem(15, '过期待处理', '/wine/passTime', icon: Icons.warning_amber),
      _WineNavItem(16, '存酒库库存', '/wine/saveLibAllData', icon: Icons.grid_view),
    ],
  ),
  _WineNavItem(
    20,
    '充公管理',
    '/wine/toStore',
    icon: Icons.gavel,
    children: [
      _WineNavItem(21, '待充公', '/wine/toStore', icon: Icons.pending_actions),
      _WineNavItem(22, '充公库', '/wine/storeLib', icon: Icons.archive),
      _WineNavItem(23, '充公出库单', '/wine/toStoreDetail', icon: Icons.description),
    ],
  ),
  _WineNavItem(
    30,
    '用户管理',
    '/wine/userConfig',
    icon: Icons.manage_accounts,
    children: [
      _WineNavItem(31, '用户管理', '/wine/userConfig', icon: Icons.people),
    ],
  ),
  _WineNavItem(
    40,
    '客户中心存酒',
    '/wine/customSaveLib',
    icon: Icons.storefront,
    children: [
      _WineNavItem(41, '待入库', '/wine/customSaveLib', icon: Icons.input),
      _WineNavItem(42, '取酒', '/wine/customGetLib', icon: Icons.output),
    ],
  ),
  _WineNavItem(
    50,
    '报表管理',
    '/wine/saveAndGetReport',
    icon: Icons.bar_chart,
    children: [
      _WineNavItem(
        51,
        '存取酒记录',
        '/wine/saveAndGetReport',
        icon: Icons.analytics,
      ),
      _WineNavItem(52, '延期记录', '/wine/passTimeLongReport', icon: Icons.history),
      _WineNavItem(
        53,
        '充公出库记录',
        '/wine/toStoreOutReport',
        icon: Icons.assignment_returned,
      ),
      _WineNavItem(
        54,
        '入库统计',
        '/wine/saveAllDataReport',
        icon: Icons.insert_chart_outlined,
      ),
      _WineNavItem(
        55,
        '出库统计',
        '/wine/getAllDataReport',
        icon: Icons.show_chart,
      ),
      _WineNavItem(
        56,
        '充公统计',
        '/wine/toStoreAllDataReport',
        icon: Icons.pie_chart,
      ),
      _WineNavItem(57, '存酒查询', '/wine/saveWineSearch', icon: Icons.search),
      _WineNavItem(58, '日实时库存', '/wine/nowInvtReport', icon: Icons.today),
    ],
  ),
  _WineNavItem(
    60,
    '存酒借还',
    '/wine/borrowWine',
    icon: Icons.swap_horiz,
    children: [
      _WineNavItem(61, '借酒', '/wine/borrowWine', icon: Icons.call_made),
      _WineNavItem(62, '还酒', '/wine/returnWine', icon: Icons.call_received),
      _WineNavItem(
        63,
        '未还酒水',
        '/wine/unreturnedWine',
        icon: Icons.hourglass_bottom,
      ),
    ],
  ),
];

/// S5 存酒系统主导航容器
final class WineNavScreen extends StatefulWidget {
  const WineNavScreen({
    required this.loader,
    this.permissions,
    this.routeObserver,
    this.safeModeEnabled = true,
    this.client = ClientKind.wine,
    this.initialPath,
    this.onBack,
    this.phase,
    super.key,
  });

  final WineLoader loader;
  final String? initialPath;
  final VoidCallback? onBack;
  final PermissionSnapshot? permissions;
  final ManagementRouteObserver? routeObserver;
  final bool safeModeEnabled;
  final ClientKind client;

  /// Display only; operation/session authorization remains in the loader.
  final ConnectionPhase? phase;

  @override
  State<WineNavScreen> createState() => _WineNavScreenState();
}

final class _WineNavScreenState extends State<WineNavScreen> {
  late int _selectedId;
  late final Set<int> _expandedGroups;

  bool _groupVisible(_WineNavItem group, [WineNavScreen? configuration]) {
    final config = configuration ?? widget;
    final snapshot = config.permissions;
    return snapshot != null &&
        managementGroupVisible(
          client: config.client,
          groupName: group.name,
          systems: const [ClientKind.wine],
          authorizationClients: group.id == 50
              ? const []
              : const [ClientKind.wine],
          needsAuthorization: group.id != 50,
          snapshot: snapshot,
          safeModeEnabled: config.safeModeEnabled,
          sessionOnline: config.phase == null
              ? null
              : config.phase == ConnectionPhase.online,
        );
  }

  bool _pageVisible(int id, [WineNavScreen? configuration]) => _wineNav.any(
    (group) =>
        _groupVisible(group, configuration) &&
        group.children.any((item) => item.id == id),
  );

  Route<dynamic>? _ownerRoute;
  ManagementRouteObserver? _registeredObserver;

  void _registerOwner() {
    final route = ModalRoute.of(context);
    if (identical(route, _ownerRoute) &&
        identical(_registeredObserver, widget.routeObserver)) {
      return;
    }
    if (_ownerRoute case final old?) _registeredObserver?.unregisterOwner(old);
    _ownerRoute = route;
    _registeredObserver = widget.routeObserver;
    if (route != null) _registeredObserver?.registerOwner(route);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registerOwner();
  }

  @override
  void didUpdateWidget(covariant WineNavScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _registerOwner();
    if (_pageVisible(_selectedId, oldWidget) && !_pageVisible(_selectedId)) {
      final owner = _ownerRoute;
      final observer = _registeredObserver;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && owner?.isActive == true) {
          observer?.closeOwnedRoutes(owner!);
        }
      });
    }
  }

  @override
  void dispose() {
    if (_ownerRoute case final owner?) {
      _registeredObserver?.unregisterOwner(owner);
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedId = _resolveInitialId(widget.initialPath);
    _expandedGroups = {(_selectedId ~/ 10) * 10};
  }

  int _resolveInitialId(String? path) {
    if (path == null || path.isEmpty) return 11;
    for (final group in _wineNav) {
      for (final child in group.children) {
        if (child.route == path) return child.id;
      }
    }
    return -1;
  }

  Widget _buildContent() {
    if (widget.phase != null && widget.phase != ConnectionPhase.online) {
      return const Center(
        child: Text('连接尚未就绪，请等待恢复后重试', style: TextStyle(color: Colors.white70)),
      );
    }
    if (!_pageVisible(_selectedId) && widget.permissions?.available != true) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '权限数据尚未就绪，请等待同步或检查连接',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    if (!_pageVisible(_selectedId)) {
      return const Center(child: Text('当前页面不可用或暂无权限'));
    }
    return switch (_selectedId) {
      11 => WineSaveNeedView(loader: widget.loader),
      12 => WineGetNeedView(loader: widget.loader),
      13 => WineSaveLibView(loader: widget.loader),
      14 => WineSaveLibChildView(loader: widget.loader),
      15 => WinePassTimeView(loader: widget.loader),
      16 => WineSaveLibAllDataView(loader: widget.loader),
      21 => WineToStoreView(loader: widget.loader),
      22 => WineStoreLibView(loader: widget.loader),
      23 => WineToStoreDetailView(loader: widget.loader),
      31 => WineUserConfigView(loader: widget.loader),
      41 => WineCustomerSaveView(loader: widget.loader),
      42 => WineCustomerGetView(loader: widget.loader),
      51 => WineReportsScreen(loader: widget.loader, initialReportIndex: 0),
      52 => WineReportsScreen(loader: widget.loader, initialReportIndex: 1),
      53 => WineReportsScreen(loader: widget.loader, initialReportIndex: 2),
      54 => WineReportsScreen(loader: widget.loader, initialReportIndex: 3),
      55 => WineReportsScreen(loader: widget.loader, initialReportIndex: 4),
      56 => WineReportsScreen(loader: widget.loader, initialReportIndex: 5),
      57 => WineReportsScreen(loader: widget.loader, initialReportIndex: 6),
      58 => WineReportsScreen(loader: widget.loader, initialReportIndex: 7),
      61 => WineBorrowView(loader: widget.loader),
      62 => WineReturnView(loader: widget.loader),
      63 => WineUnreturnedView(loader: widget.loader),
      _ => WineSaveNeedView(loader: widget.loader),
    };
  }

  String _currentTitle() {
    for (final group in _wineNav) {
      for (final child in group.children) {
        if (child.id == _selectedId) return '${group.name} · ${child.name}';
      }
    }
    return '存酒系统';
  }

  Widget _navigation({VoidCallback? closeMenu}) {
    return Container(
      color: const Color(0xff121B30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部系统标题 & 返回按钮
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xff18223C),
            child: Row(
              children: [
                const Icon(Icons.liquor, color: Colors.amberAccent, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '存酒管理系统',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onBack != null)
                  IconButton(
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white70,
                      size: 20,
                    ),
                    tooltip: '退出存酒系统',
                    onPressed: widget.onBack,
                  ),
              ],
            ),
          ),
          // 菜单列表
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (!_wineNav.any(_groupVisible))
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.phase != null &&
                                widget.phase != ConnectionPhase.online
                            ? '连接尚未就绪，菜单暂不可用'
                            : widget.permissions?.available != true
                            ? '权限数据尚未就绪，请等待同步或检查连接'
                            : '当前没有可用菜单，请联系管理员核对权限',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  for (final group in _wineNav.where(_groupVisible))
                    Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: _expandedGroups.contains(group.id),
                        onExpansionChanged: (expanded) {
                          setState(() {
                            if (expanded) {
                              _expandedGroups.add(group.id);
                            } else {
                              _expandedGroups.remove(group.id);
                            }
                          });
                        },
                        leading: Icon(
                          group.icon,
                          color: Colors.lightBlueAccent,
                          size: 20,
                        ),
                        title: Text(
                          group.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          for (final child in group.children)
                            ListTile(
                              dense: true,
                              selected: _selectedId == child.id,
                              selectedTileColor: const Color(0xff1E2F52),
                              leading: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Icon(
                                  child.icon,
                                  size: 16,
                                  color: _selectedId == child.id
                                      ? Colors.lightBlueAccent
                                      : Colors.white38,
                                ),
                              ),
                              title: Text(
                                child.name,
                                style: TextStyle(
                                  color: _selectedId == child.id
                                      ? Colors.lightBlueAccent
                                      : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: _selectedId == child.id
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  if (_pageVisible(child.id)) {
                                    _selectedId = child.id;
                                  }
                                });
                                closeMenu?.call();
                              },
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 720;
        return Scaffold(
          backgroundColor: const Color(0xff09101F),
          drawer: narrow
              ? Drawer(
                  child: SafeArea(
                    child: Builder(
                      builder: (drawerContext) => _navigation(
                        closeMenu: () =>
                            Scaffold.of(drawerContext).closeDrawer(),
                      ),
                    ),
                  ),
                )
              : null,
          body: SafeArea(
            child: Row(
              children: [
                if (!narrow) SizedBox(width: 220, child: _navigation()),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 顶部面包屑/标题栏
                      Container(
                        height: 50,
                        padding: EdgeInsets.symmetric(
                          horizontal: narrow ? 8 : 20,
                        ),
                        color: const Color(0xff121B30),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (narrow)
                              Builder(
                                builder: (scaffoldContext) => IconButton(
                                  tooltip: '打开存酒菜单',
                                  color: Colors.white,
                                  icon: const Icon(Icons.menu),
                                  onPressed: () =>
                                      Scaffold.of(scaffoldContext).openDrawer(),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                _currentTitle(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white38),
                                  ),
                                  child: Text(
                                    switch (widget.phase) {
                                      ConnectionPhase.online => '在线',
                                      ConnectionPhase.blocked => '连接已断开',
                                      ConnectionPhase.reconciling => '正在同步',
                                      null => '连接状态待确认',
                                    },
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 内容视图
                      Expanded(child: _buildContent()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
