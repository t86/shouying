import 'package:card_table/src/management_route_observer.dart';
import 'package:card_table/src/management_permissions.dart';
import 'package:permissions/permissions.dart';
import 'package:protocol/protocol.dart';
import 'package:card_table/src/account_password_screen.dart';
import 'package:card_table/src/bms_card_views.dart';
import 'package:card_table/src/bms_limit_views.dart';
import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_product_views.dart';
import 'package:card_table/src/bms_rules_reports_views.dart';
import 'package:card_table/src/bms_staff_views.dart';
import 'package:card_table/src/bms_store_device_views.dart';
import 'package:card_table/src/bms_wine_sms_views.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
import 'package:card_table/src/bms_fc_price_screen.dart';

class BmsNavItem {
  const BmsNavItem({required this.name, required this.url});
  final String name;
  final String url;
}

class BmsNavGroup {
  const BmsNavGroup({
    required this.name,
    required this.icon,
    required this.items,
  });
  final String name;
  final IconData icon;
  final List<BmsNavItem> items;
}

class BmsNavScreen extends StatefulWidget {
  const BmsNavScreen({
    super.key,
    required this.loader,
    this.permissions,
    this.phase,
    this.routeObserver,
    this.safeModeEnabled = true,
    this.client = ClientKind.orgManager,
    this.initialPage = 'stationConfig',
    this.onBack,
    this.onChangePassword,
    this.onPasswordChanged,
    this.userName = '管理员',
  });

  final BmsLoader loader;
  final String? initialPage;
  final VoidCallback? onBack;
  final PermissionSnapshot? permissions;
  final ConnectionPhase? phase;
  final ManagementRouteObserver? routeObserver;
  final bool safeModeEnabled;
  final ClientKind client;
  final ChangePasswordSubmit? onChangePassword;

  /// Success notification only; management-system password changes do not log out.
  final VoidCallback? onPasswordChanged;
  final String userName;

  static final List<BmsNavGroup> groups = [
    BmsNavGroup(
      name: '人员管理',
      icon: Icons.people,
      items: const [
        BmsNavItem(name: '工号生成规则', url: 'codeRules'),
        BmsNavItem(name: '岗位管理', url: 'stationConfig'),
        BmsNavItem(name: '员工管理', url: 'employeeList'),
        BmsNavItem(name: '入职审批', url: 'onboardingApproval'),
        BmsNavItem(name: '商务组订位人', url: 'businessEmp'),
      ],
    ),
    BmsNavGroup(
      name: '商品管理',
      icon: Icons.inventory_2,
      items: const [
        BmsNavItem(name: '商品管理', url: 'prdConfig'),
        BmsNavItem(name: '批量上传图片', url: 'uploadProImg'),
        BmsNavItem(name: '套餐可选组模板', url: 'taocanTemplate'),
        BmsNavItem(name: '价格方案配置', url: 'fcPriceConfig'),
      ],
    ),
    BmsNavGroup(
      name: '卡台管理',
      icon: Icons.table_bar,
      items: const [
        BmsNavItem(name: '卡台管理', url: 'cardConfig'),
        BmsNavItem(name: '卡台低消组', url: 'cardMinGroup'),
        BmsNavItem(name: '卡台标签', url: 'cardTips'),
        BmsNavItem(name: '计抵达规则', url: 'arriveRules'),
      ],
    ),
    BmsNavGroup(
      name: '限额限量',
      icon: Icons.price_change,
      items: const [
        BmsNavItem(name: '商品组管理', url: 'prdGroupConfig'),
        BmsNavItem(name: '限额限量管理', url: 'limitConfig'),
      ],
    ),
    BmsNavGroup(
      name: '门店信息',
      icon: Icons.store,
      items: const [
        BmsNavItem(name: '门店信息', url: 'store'),
        BmsNavItem(name: '营业日管理', url: 'restore'),
      ],
    ),
    BmsNavGroup(
      name: '支付管理',
      icon: Icons.payment,
      items: const [BmsNavItem(name: '渠道管理', url: 'payList')],
    ),
    BmsNavGroup(
      name: '设备管理',
      icon: Icons.devices,
      items: const [
        BmsNavItem(name: '打印机管理', url: 'printers'),
        BmsNavItem(name: '出品库管理', url: 'outLibConfig'),
        BmsNavItem(name: '小票管理', url: 'bills'),
        BmsNavItem(name: '终端管理', url: 'terminalBms'),
      ],
    ),
    BmsNavGroup(
      name: '报表配置',
      icon: Icons.bar_chart,
      items: const [
        BmsNavItem(name: '鸡尾酒导出配置', url: 'reportTYConfig'),
        BmsNavItem(name: '销售商品统计设置', url: 'sealPrdConfig'),
        BmsNavItem(name: '统计类别配置', url: 'statisticalGroupConfig'),
        BmsNavItem(name: '渠道类别配置', url: 'channelGroupConfig'),
      ],
    ),
    BmsNavGroup(
      name: '小程序报表',
      icon: Icons.assessment_outlined,
      items: const [
        BmsNavItem(name: '高毛利商品配置', url: 'miniProgressConfig'),
      ],
    ),
    BmsNavGroup(
      name: '要求管理',
      icon: Icons.rule,
      items: const [BmsNavItem(name: '要求管理', url: 'requireConfig')],
    ),
    BmsNavGroup(
      name: '理由管理',
      icon: Icons.list_alt,
      items: const [
        BmsNavItem(name: '优惠理由管理', url: 'YHReason'),
        BmsNavItem(name: '退单理由管理', url: 'backReason'),
        BmsNavItem(name: '退卡理由管理', url: 'backVipCard'),
        BmsNavItem(name: '取消优惠理由管理', url: 'QXYHReason'),
      ],
    ),
    BmsNavGroup(
      name: '业务规则',
      icon: Icons.settings,
      items: const [
        BmsNavItem(name: '规则配置', url: 'terminalRules'),
        BmsNavItem(name: '会员卡规则', url: 'vipRules'),
      ],
    ),
    BmsNavGroup(
      name: '存酒设置',
      icon: Icons.wine_bar,
      items: const [
        BmsNavItem(name: '存酒设置', url: 'saveConfig'),
        BmsNavItem(name: '可存酒水', url: 'wineInfo'),
      ],
    ),
    BmsNavGroup(
      name: '抽成管理',
      icon: Icons.percent,
      items: const [BmsNavItem(name: '抽成管理', url: 'cutPrd')],
    ),
    BmsNavGroup(
      name: '短信管理',
      icon: Icons.sms,
      items: const [
        BmsNavItem(name: '账户管理', url: 'accountInfo'),
        BmsNavItem(name: '短信明细', url: 'messageDetail'),
        BmsNavItem(name: '短信结果查询', url: 'messageResult'),
      ],
    ),
  ];

  @override
  State<BmsNavScreen> createState() => _BmsNavScreenState();
}

class _BmsNavScreenState extends State<BmsNavScreen> {
  late String _activePage;

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
  void didUpdateWidget(covariant BmsNavScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _registerOwner();
    if (_pageVisible(_activePage, oldWidget) && !_pageVisible(_activePage)) {
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
    _activePage = widget.initialPage ?? '';
  }

  bool _groupVisible(BmsNavGroup group, [BmsNavScreen? configuration]) {
    final config = configuration ?? widget;
    final snapshot = config.permissions;
    return snapshot != null &&
        managementGroupVisible(
          client: config.client,
          groupName: group.name,
          systems: const [ClientKind.orgManager],
          snapshot: snapshot,
          safeModeEnabled: config.safeModeEnabled,
          sessionOnline: config.phase == null
              ? null : config.phase == ConnectionPhase.online,
        );
  }

  bool _pageVisible(String page, [BmsNavScreen? configuration]) =>
      BmsNavScreen.groups.any(
        (group) =>
            _groupVisible(group, configuration) &&
            group.items.any((item) => item.url == page),
      );

  void _selectPage(String url) {
    if (_pageVisible(url)) setState(() => _activePage = url);
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
    if (widget.phase != null && widget.phase != ConnectionPhase.online) {
      return const Center(child: Text('连接尚未就绪，请等待恢复后重试'));
    }
    if (!_pageVisible(_activePage)) {
      return const Center(child: Text('当前页面不可用或暂无权限'));
    }
    return switch (_activePage) {
      'fcPriceConfig' => BmsFcPriceScreen(loader: widget.loader),
      'codeRules' => BmsCodeRulesView(loader: widget.loader),
      'stationConfig' => BmsStationConfigView(loader: widget.loader),
      'employeeList' => BmsEmployeeListView(loader: widget.loader),
      'onboardingApproval' => BmsOnboardingApprovalView(loader: widget.loader),
      'businessEmp' => BmsBusinessEmpView(loader: widget.loader),
      'prdConfig' => BmsPrdConfigView(loader: widget.loader),
      'uploadProImg' => BmsUploadProImgView(loader: widget.loader),
      'taocanTemplate' => BmsTaocanTemplateView(loader: widget.loader),
      'cardConfig' => BmsCardConfigView(loader: widget.loader),
      'cardMinGroup' => BmsCardMinGroupView(loader: widget.loader),
      'cardTips' => BmsCardTipsView(loader: widget.loader),
      'arriveRules' => BmsArriveRulesView(loader: widget.loader),
      'prdGroupConfig' => BmsPrdGroupConfigView(loader: widget.loader),
      'limitConfig' => BmsLimitConfigView(loader: widget.loader),
      'store' => BmsStoreInfoView(loader: widget.loader),
      'restore' => BmsRestoreView(loader: widget.loader),
      'payList' => BmsPayListView(loader: widget.loader),
      'printers' => BmsPrintersView(loader: widget.loader),
      'outLibConfig' => BmsOutLibConfigView(loader: widget.loader),
      'bills' => BmsBillsView(loader: widget.loader),
      'terminalBms' => BmsTerminalBmsView(loader: widget.loader),
      'reportTYConfig' => BmsReportTYConfigView(loader: widget.loader),
      'sealPrdConfig' => BmsSealPrdConfigView(loader: widget.loader),
      'statisticalGroupConfig' => BmsStatisticalGroupConfigView(
        loader: widget.loader,
      ),
      'channelGroupConfig' => BmsChannelGroupConfigView(loader: widget.loader),
      'miniProgressConfig' => BmsMiniProgressConfigView(loader: widget.loader),
      'requireConfig' => BmsRequireConfigView(loader: widget.loader),
      'YHReason' => BmsReasonView(
        loader: widget.loader,
        reasonType: 'YH',
        title: '优惠理由管理',
      ),
      'backReason' => BmsReasonView(
        loader: widget.loader,
        reasonType: 'back',
        title: '退单理由管理',
      ),
      'backVipCard' => BmsReasonView(
        loader: widget.loader,
        reasonType: 'backVip',
        title: '退卡理由管理',
      ),
      'QXYHReason' => BmsReasonView(
        loader: widget.loader,
        reasonType: 'QXYH',
        title: '取消优惠理由管理',
      ),
      'terminalRules' => BmsTerminalRulesView(loader: widget.loader),
      'vipRules' => BmsVipRulesView(loader: widget.loader),
      'saveConfig' => BmsSaveConfigView(loader: widget.loader),
      'wineInfo' => BmsWineInfoView(loader: widget.loader),
      'cutPrd' => BmsCutPrdView(loader: widget.loader),
      'accountInfo' => BmsAccountInfoView(loader: widget.loader),
      'messageDetail' => BmsMessageDetailView(loader: widget.loader),
      'messageResult' => BmsMessageResultView(loader: widget.loader),
      _ => BmsStationConfigView(loader: widget.loader),
    };
  }

  Widget _buildSidebar({VoidCallback? closeMenu}) {
    return Material(
      color: const Color(0xFFF9FAFB),
      child: SizedBox(
        width: 220,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(Icons.storefront, color: Color(0xFF2170FF)),
                  const SizedBox(width: 8),
                  Text(
                    '门店管理后台',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: BmsNavScreen.groups.where(_groupVisible).length,
                itemBuilder: (ctx, gIdx) {
                  final group = BmsNavScreen.groups
                      .where(_groupVisible)
                      .elementAt(gIdx);
                  final isCurrentGroupActive = group.items.any(
                    (item) => item.url == _activePage,
                  );
                  return Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: isCurrentGroupActive || gIdx == 0,
                      leading: Icon(
                        group.icon,
                        size: 20,
                        color: const Color(0xFF475569),
                      ),
                      title: Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      children: group.items.map((item) {
                        final isSelected = item.url == _activePage;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          child: Material(
                            color: isSelected
                                ? const Color(0xFF2170FF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            child: ListTile(
                              key: Key('bms-nav-item-${item.url}'),
                              dense: true,
                              title: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              onTap: () {
                                _selectPage(item.url);
                                closeMenu?.call();
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 720;
    // Only the unselected landing page chooses a visible entry. Explicit URLs
    // remain denied instead of silently opening a different permission scope.
    if (_activePage.isEmpty) {
      for (final group in BmsNavScreen.groups.where(_groupVisible)) {
        if (group.items.isNotEmpty) {
          _activePage = group.items.first.url;
          break;
        }
      }
    }
    return Scaffold(
      drawer: narrow ? Drawer(child: SafeArea(child: Builder(
        builder: (context) => _buildSidebar(
          closeMenu: () => Scaffold.of(context).closeDrawer()),
      ))) : null,
      appBar: AppBar(
        leading: narrow ? Builder(builder: (context) => IconButton(
          tooltip: '打开门店后台菜单',
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        )) : null,
        title: Text(narrow ? '门店后台' : 'BMS 门店后台系统',
          maxLines: 1, overflow: TextOverflow.ellipsis),
        elevation: 1,
        actions: [
          Row(
            children: [
              if (!narrow) ...[
                const Icon(Icons.account_circle, size: 20),
                const SizedBox(width: 6),
                Text(widget.userName),
                const SizedBox(width: 8),
              ],
              PopupMenuButton<String>(
                tooltip: widget.userName,
                onSelected: (cmd) async {
                  if (cmd == 'pwd') {
                    await _showChangePasswordDialog();
                  } else if (cmd == 'exit') {
                    widget.onBack?.call();
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'pwd', child: Text('修改密码')),
                  PopupMenuItem(value: 'exit', child: Text('退出系统')),
                ],
              ),
              const SizedBox(width: 12),
            ],
          ),
          if (widget.onBack != null)
            IconButton(
              key: const Key('bms-back-to-cashier-btn'),
              icon: const Icon(Icons.exit_to_app),
              tooltip: '返回前台系统',
              onPressed: widget.onBack,
            ),
        ],
      ),
      body: Row(
        children: [
          if (!narrow) _buildSidebar(),
          if (!narrow) const VerticalDivider(width: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
