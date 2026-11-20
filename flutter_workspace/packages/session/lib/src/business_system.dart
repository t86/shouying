import 'package:protocol/protocol.dart';

enum BusinessSystem {
  booking(label: '预定', client: ClientKind.booking, landingPath: '/cardMachine'),
  order(label: '点单', client: ClientKind.order, landingPath: '/orderCard'),
  cashier(label: '收银', client: ClientKind.cashier, landingPath: '/moneyCard'),
  vip(label: '会员', client: ClientKind.vip, landingPath: '/vipManager'),
  wine(label: '存酒', client: ClientKind.wine, landingPath: '/wine/saveNeedToLib'),
  queue(
    label: '排队',
    client: ClientKind.queueDisplay,
    landingPath: '/queue/bigScreen',
  ),
  bms(
    label: '门店后台',
    client: ClientKind.orgManager,
    landingPath: '/BMS/codeRules',
  ),
  erp(
    label: 'ERP 管理员',
    client: ClientKind.erpAdmin,
    landingPath: '/ERP/home',
  ),
  erpWarehouse(
    label: 'ERP 仓库管理员',
    client: ClientKind.erp,
    landingPath: '/ERP/anotherInLib',
  ),
  superAdmin(
    label: '超管中心',
    client: ClientKind.superAdmin,
    landingPath: '/ManagementSystem/appinfo/smgr',
  );

  const BusinessSystem({
    required this.label,
    required this.client,
    required this.landingPath,
  });

  final String label;
  final ClientKind client;
  final String landingPath;

  String get developmentAuthorizationPlaceholder =>
      'loopback-development-${client.clientName}';

  static BusinessSystem? fromClient(ClientKind client) {
    for (final system in values) {
      if (system.client == client) return system;
    }
    return null;
  }
}
