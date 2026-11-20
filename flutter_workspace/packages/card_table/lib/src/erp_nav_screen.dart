import 'package:card_table/src/management_route_observer.dart';
import 'package:card_table/src/management_permissions.dart';
import 'package:permissions/permissions.dart';
import 'package:protocol/protocol.dart';
import 'package:card_table/src/account_password_screen.dart';
import 'package:card_table/src/erp_empty_bottle_views.dart';
import 'package:card_table/src/erp_in_views.dart';
import 'package:card_table/src/erp_loader.dart';
import 'package:card_table/src/erp_master_views.dart';
import 'package:card_table/src/erp_out_views.dart';
import 'package:card_table/src/erp_sout_workflow.dart';
import 'package:card_table/src/erp_report_views.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';

/// ERP 侧栏单项
final class ErpNavItem {
  const ErpNavItem({
    required this.key,
    required this.title,
    required this.icon,
  });

  final String key;
  final String title;
  final IconData icon;
}

/// ERP 侧栏分组
final class ErpNavGroup {
  const ErpNavGroup({
    required this.title,
    required this.icon,
    required this.items,
    this.systems = const [ClientKind.erp, ClientKind.erpAdmin],
    this.authorizationClients = const [],
    this.needsAuthorization = false,
  });

  final String title;
  final IconData icon;
  final List<ErpNavItem> items;
  final List<ClientKind> systems, authorizationClients;
  final bool needsAuthorization;
}

/// S8 ERP 仓库系统主导航壳容器
class ErpNavScreen extends StatefulWidget {
  const ErpNavScreen({
    required this.loader,
    this.permissions,
    this.phase,
    this.routeObserver,
    this.safeModeEnabled = true,
    this.client = ClientKind.erpAdmin,
    this.initialPage = 'home',
    this.userName = '管理员',
    this.onBack,
    this.onChangePassword,
    this.onPasswordChanged,
    this.onPrintDocument,
    super.key,
  });

  final ErpLoader loader;
  final String initialPage;
  final String userName;
  final VoidCallback? onBack;
  final PermissionSnapshot? permissions;
  final ConnectionPhase? phase;
  final ManagementRouteObserver? routeObserver;
  final bool safeModeEnabled;
  final ClientKind client;
  final ChangePasswordSubmit? onChangePassword;
  final ErpSoutPrint? onPrintDocument;

  /// Success notification only; management-system password changes do not log out.
  final VoidCallback? onPasswordChanged;

  @override
  State<ErpNavScreen> createState() => _ErpNavScreenState();
}

class _ErpNavScreenState extends State<ErpNavScreen> {
  late String _currentPage;
  int _reportEpoch = 0;
  bool Function() _reportAllowed(String page) {
    final epoch = _reportEpoch;
    return () =>
        mounted &&
        epoch == _reportEpoch &&
        _currentPage == page &&
        widget.phase == ConnectionPhase.online &&
        _pageVisible(page);
  }

  static const List<ErpNavGroup> _groups = [
    ErpNavGroup(
      title: '首页',
      icon: Icons.home_outlined,
      items: [
        ErpNavItem(key: 'home', title: '首页看板', icon: Icons.dashboard_outlined),
      ],
    ),
    ErpNavGroup(
      title: '仓库管理',
      systems: [ClientKind.erpAdmin],
      icon: Icons.warehouse_outlined,
      items: [
        ErpNavItem(key: 'erpLib', title: '仓库设置', icon: Icons.store_outlined),
      ],
    ),
    ErpNavGroup(
      title: '物料管理',
      systems: [ClientKind.erpAdmin],
      icon: Icons.category_outlined,
      items: [
        ErpNavItem(
          key: 'mats',
          title: '物料列表',
          icon: Icons.inventory_2_outlined,
        ),
        ErpNavItem(
          key: 'comparePrd',
          title: '商品对照',
          icon: Icons.compare_arrows_outlined,
        ),
      ],
    ),
    ErpNavGroup(
      title: '入库管理',
      icon: Icons.move_to_inbox_outlined,
      items: [
        ErpNavItem(
          key: 'anotherInLib',
          title: '其他入库',
          icon: Icons.input_outlined,
        ),
        ErpNavItem(
          key: 'changeInLib',
          title: '调拨入库',
          icon: Icons.sync_alt_outlined,
        ),
        ErpNavItem(
          key: 'applyForInLib',
          title: '入库异议订单',
          icon: Icons.warning_amber_outlined,
        ),
      ],
    ),
    ErpNavGroup(
      title: '出库管理',
      icon: Icons.outbox_outlined,
      items: [
        ErpNavItem(
          key: 'anotherOutLib',
          title: '其他出库',
          icon: Icons.output_outlined,
        ),
        ErpNavItem(
          key: 'changeOutLib',
          title: '调拨出库',
          icon: Icons.sync_alt_outlined,
        ),
        ErpNavItem(
          key: 'applyForOutLib',
          title: '出库异议订单',
          icon: Icons.warning_amber_outlined,
        ),
      ],
    ),
    ErpNavGroup(
      title: '供应商管理',
      systems: [ClientKind.erpAdmin],
      icon: Icons.business_outlined,
      items: [
        ErpNavItem(
          key: 'supplierConfig',
          title: '供应商设置',
          icon: Icons.contacts_outlined,
        ),
      ],
    ),
    ErpNavGroup(
      title: '空瓶管理',
      systems: [ClientKind.erpAdmin],
      needsAuthorization: true,
      authorizationClients: [ClientKind.erp],
      icon: Icons.local_drink_outlined,
      items: [
        ErpNavItem(
          key: 'emptyInLibOrder',
          title: '空瓶入库单',
          icon: Icons.receipt_outlined,
        ),
        ErpNavItem(
          key: 'emptyLib',
          title: '空瓶仓',
          icon: Icons.inventory_outlined,
        ),
        ErpNavItem(
          key: 'emptyOutLibOrder',
          title: '空瓶出库单',
          icon: Icons.receipt_long_outlined,
        ),
      ],
    ),
    ErpNavGroup(
      title: '报表管理',
      icon: Icons.bar_chart_outlined,
      items: [
        ErpNavItem(
          key: 'warehousePSI',
          title: '仓库进销存',
          icon: Icons.table_chart_outlined,
        ),
        ErpNavItem(
          key: 'matLibNow',
          title: '物料实时库存表',
          icon: Icons.timelapse_outlined,
        ),
        ErpNavItem(
          key: 'matLib',
          title: '物料库存表',
          icon: Icons.calendar_today_outlined,
        ),
        ErpNavItem(
          key: 'inLibRep',
          title: '入库明细表',
          icon: Icons.list_alt_outlined,
        ),
        ErpNavItem(
          key: 'outLibRep',
          title: '出库明细表',
          icon: Icons.list_alt_outlined,
        ),
        ErpNavItem(
          key: 'inLibAllRep',
          title: '入库汇总表',
          icon: Icons.summarize_outlined,
        ),
        ErpNavItem(
          key: 'outLibAllRep',
          title: '出库汇总表',
          icon: Icons.summarize_outlined,
        ),
        ErpNavItem(
          key: 'emptyInLib',
          title: '空瓶入库明细',
          icon: Icons.description_outlined,
        ),
        ErpNavItem(
          key: 'emptyOutLib',
          title: '空瓶出库明细',
          icon: Icons.description_outlined,
        ),
      ],
    ),
  ];

  bool _groupVisible(ErpNavGroup group, [ErpNavScreen? configuration]) {
    final config = configuration ?? widget;
    final snapshot = config.permissions;
    return snapshot != null &&
        managementGroupVisible(
          client: config.client,
          groupName: group.title,
          systems: group.systems,
          authorizationClients: group.authorizationClients,
          needsAuthorization: group.needsAuthorization,
          snapshot: snapshot,
          safeModeEnabled: config.safeModeEnabled,
          sessionOnline: config.phase == null
              ? null
              : config.phase == ConnectionPhase.online,
        );
  }

  bool _pageVisible(String page, [ErpNavScreen? configuration]) => _groups.any(
    (group) =>
        _groupVisible(group, configuration) &&
        group.items.any((item) => item.key == page),
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
  void didUpdateWidget(covariant ErpNavScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.permissions != widget.permissions ||
        oldWidget.phase != widget.phase ||
        oldWidget.client != widget.client ||
        oldWidget.safeModeEnabled != widget.safeModeEnabled) {
      _reportEpoch++;
    }
    _registerOwner();
    if (_pageVisible(_currentPage, oldWidget) && !_pageVisible(_currentPage)) {
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
    _currentPage = widget.initialPage.replaceAll('/ERP/', '');
  }

  Future<void> _showChangePasswordDialog() async {
    final submit = widget.onChangePassword;
    if (submit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码修改尚未接入，当前不会更改密码。请使用原系统修改。')),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: ManagementRouteObserver.childRouteName,
        ),
        builder: (_) => ChangePasswordScreen(
          submit: submit,
          requiresRelogin: false,
          onChanged: widget.onPasswordChanged,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_pageVisible(_currentPage)) {
      return const Center(child: Text('当前页面不可用或暂无权限'));
    }
    switch (_currentPage) {
      // S8.P1 主数据
      case 'home':
        return ErpHomeView(loader: widget.loader);
      case 'erpLib':
        return ErpStoreManagementView(loader: widget.loader);
      case 'mats':
        return ErpMatsView(loader: widget.loader);
      case 'comparePrd':
        return ErpComparePrdView(loader: widget.loader);
      case 'supplierConfig':
        return ErpSupplierView(loader: widget.loader);

      // S8.P2 入库
      case 'anotherInLib':
        return ErpAnotherInLibView(loader: widget.loader);
      case 'changeInLib':
        return ErpChangeInLibView(loader: widget.loader);
      case 'applyForInLib':
        return ErpApplyForInLibView(loader: widget.loader);

      // S8.P3 出库
      case 'anotherOutLib':
        return ErpAnotherOutLibView(
          loader: widget.loader,
          onPrintDocument: widget.onPrintDocument,
        );
      case 'changeOutLib':
        return ErpChangeOutLibView(loader: widget.loader);
      case 'applyForOutLib':
        return ErpApplyForOutLibView(loader: widget.loader);

      // S8.P4 空瓶
      case 'emptyInLibOrder':
        return ErpEmptyInLibOrderView(loader: widget.loader);
      case 'emptyLib':
        return ErpEmptyLibView(loader: widget.loader);
      case 'emptyOutLibOrder':
        return ErpEmptyOutLibOrderView(loader: widget.loader);

      // S8.P5 报表
      case 'matLibNow':
        return ErpMatLibNowView(
          key: ValueKey('matLibNow-$_reportEpoch'),
          loader: widget.loader,
          canOperate: _reportAllowed('matLibNow'),
        );
      case 'matLib':
        return ErpMatLibView(
          key: ValueKey('matLib-$_reportEpoch'),
          loader: widget.loader,
          canOperate: _reportAllowed('matLib'),
        );
      case 'inLibRep':
        return ErpInLibRepView(
          key: ValueKey('inLibRep-$_reportEpoch'),
          loader: widget.loader,
          canOperate: _reportAllowed('inLibRep'),
        );
      case 'outLibRep':
        return ErpOutLibRepView(
          key: ValueKey('outLibRep-$_reportEpoch'),
          loader: widget.loader,
          canOperate: _reportAllowed('outLibRep'),
        );
      case 'inLibAllRep':
        return ErpInLibAllRepView(
          key: ValueKey('inLibAllRep-$_reportEpoch'),
          loader: widget.loader,
          canOperate: _reportAllowed('inLibAllRep'),
        );
      case 'outLibAllRep':
        return ErpOutLibAllRepView(
          key: ValueKey('outLibAllRep-$_reportEpoch'),
          loader: widget.loader,
          canOperate: _reportAllowed('outLibAllRep'),
        );
      case 'warehousePSI':
        return ErpWarehousePsiView(
          key: ValueKey('warehousePSI-$_reportEpoch'),
          loader: widget.loader,
          canOperate: _reportAllowed('warehousePSI'),
        );
      case 'emptyInLib':
        return ErpEmptyInLibRepView(
          key: ValueKey('emptyInLib-$_reportEpoch'),
          loader: widget.loader,
          canOperate: _reportAllowed('emptyInLib'),
        );
      case 'emptyOutLib':
        return ErpEmptyOutLibRepView(
          key: ValueKey('emptyOutLib-$_reportEpoch'),
          loader: widget.loader,
          canOperate: _reportAllowed('emptyOutLib'),
        );

      default:
        return ErpHomeView(loader: widget.loader);
    }
  }

  Widget _navigation(BuildContext context, {bool closeMenu = false}) =>
      Material(
        color: Theme.of(context).cardColor,
        child: ListView(
          children: [
            for (final group in _groups.where(_groupVisible))
              ExpansionTile(
                dense: true,
                leading: Icon(group.icon, size: 18),
                title: Text(group.title),
                initiallyExpanded: group.items.any(
                  (item) => item.key == _currentPage,
                ),
                children: [
                  for (final item in group.items)
                    ListTile(
                      dense: true,
                      selected: _currentPage == item.key,
                      leading: Icon(item.icon, size: 16),
                      title: Text(item.title),
                      onTap: () {
                        if (_pageVisible(item.key))
                          setState(() => _currentPage = item.key);
                        if (closeMenu) Scaffold.of(context).closeDrawer();
                      },
                    ),
                ],
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 720;
    return Scaffold(
      drawer: narrow
          ? Drawer(
              child: SafeArea(
                child: Builder(
                  builder: (context) => _navigation(context, closeMenu: true),
                ),
              ),
            )
          : null,
      appBar: AppBar(
        leading: narrow
            ? Builder(
                builder: (context) => IconButton(
                  tooltip: '打开仓库菜单',
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        title: Text(
          narrow ? '仓库管理' : 'ERP 仓库管理系统',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!narrow) ...[
            Text(widget.userName),
            TextButton.icon(
              onPressed: _showChangePasswordDialog,
              icon: const Icon(Icons.lock_outline),
              label: const Text('修改密码'),
            ),
            if (widget.onBack != null)
              FilledButton.tonalIcon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.logout),
                label: const Text('返回收银'),
              ),
          ],
          if (narrow)
            PopupMenuButton<String>(
              tooltip: widget.userName,
              onSelected: (command) {
                if (command == 'password') _showChangePasswordDialog();
                if (command == 'exit') widget.onBack?.call();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'password', child: Text('修改密码')),
                if (widget.onBack != null)
                  const PopupMenuItem(value: 'exit', child: Text('退出系统')),
              ],
            ),
        ],
      ),
      body: Row(
        children: [
          if (!narrow) SizedBox(width: 230, child: _navigation(context)),
          if (!narrow) const VerticalDivider(width: 1),
          Expanded(
            child:
                widget.phase != null && widget.phase != ConnectionPhase.online
                ? const Center(child: Text('连接尚未就绪，请等待恢复后重试'))
                : _buildBody(),
          ),
        ],
      ),
    );
  }
}
