import 'package:protocol/protocol.dart';

enum BusinessSystem {
  booking(label: '预定', client: ClientKind.booking, landingPath: '/cardMachine'),
  order(label: '点单', client: ClientKind.order, landingPath: '/orderCard'),
  cashier(label: '收银', client: ClientKind.cashier, landingPath: '/moneyCard');

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
