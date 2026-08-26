enum ClientKind {
  orgManager(clientName: 'org_mgr', termType: 1),
  booking(clientName: 'book', termType: 2),
  order(clientName: 'order', termType: 4),
  cashier(clientName: 'money', termType: 8),
  vip(clientName: 'vip', termType: 16),
  erp(clientName: 'erp', termType: 32),
  erpAdmin(clientName: 'erpAdmin', termType: 64),
  wine(clientName: 'wine', termType: 256),
  queueDisplay(clientName: 'queuedsp', termType: 512),
  superAdmin(clientName: 'appinfo', termType: null);

  const ClientKind({required this.clientName, required this.termType});

  final String clientName;
  final int? termType;
}
