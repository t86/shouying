import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:design_system/design_system.dart';
import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:permissions/permissions.dart';
import 'package:protocol/protocol.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

final _appLabelProvider = Provider<String>(
  (ref) => throw StateError('native app label required'),
);
final _platformLabelProvider = Provider<String>(
  (ref) => throw StateError('native platform label required'),
);
final _terminalIdentityProvider = Provider<TerminalIdentityService>(
  (_) => const UnsupportedTerminalIdentityService(),
);

final class AppRuntimeConfiguration {
  const AppRuntimeConfiguration._({
    required this.config,
    required this.invalidKeys,
    required this.developmentSystemSelection,
  });

  factory AppRuntimeConfiguration.fromEnvironment() =>
      AppRuntimeConfiguration.fromValues(
        apiBase: const String.fromEnvironment('SHOUYIN_API_BASE'),
        onlineBase: const String.fromEnvironment('SHOUYIN_ONLINE_BASE'),
        websocketBase: const String.fromEnvironment('SHOUYIN_WS_BASE'),
        developmentSystemSelection: const bool.fromEnvironment(
          'SHOUYIN_DEV_SYSTEM_SELECTION',
        ),
      );

  factory AppRuntimeConfiguration.fromValues({
    required String apiBase,
    required String onlineBase,
    required String websocketBase,
    bool developmentSystemSelection = false,
  }) {
    final invalidKeys = <String>[];
    final api = _validatedEndpoint(apiBase, _EndpointKind.api);
    final online = _validatedEndpoint(onlineBase, _EndpointKind.online);
    final websocket = _validatedEndpoint(
      websocketBase,
      _EndpointKind.websocket,
    );
    if (api == null) invalidKeys.add('SHOUYIN_API_BASE');
    if (online == null) invalidKeys.add('SHOUYIN_ONLINE_BASE');
    if (websocket == null) invalidKeys.add('SHOUYIN_WS_BASE');
    ApiConfig? config;
    if (invalidKeys.isEmpty) {
      config = ApiConfig(
        apiBase: api!,
        onlineBase: online!,
        websocketBase: websocket!,
      );
    }
    return AppRuntimeConfiguration._(
      config: config,
      invalidKeys: List<String>.unmodifiable(invalidKeys),
      developmentSystemSelection:
          developmentSystemSelection &&
          config != null &&
          (_validLoopbackDevelopment(api, online, websocket) ||
              _validVueDevEndpoints(api, online, websocket)),
    );
  }

  final ApiConfig? config;
  final List<String> invalidKeys;
  final bool developmentSystemSelection;

  static bool _validLoopbackDevelopment(Uri? api, Uri? online, Uri? websocket) {
    if (api == null || online == null || websocket == null) return false;
    if (api.scheme != 'http' ||
        online.scheme != 'http' ||
        websocket.scheme != 'ws') {
      return false;
    }
    if (!_isLoopback(api.host) ||
        api.host != online.host ||
        api.host != websocket.host) {
      return false;
    }
    int port(Uri uri) => uri.hasPort ? uri.port : 80;
    if (port(api) != port(online) || port(api) != port(websocket)) {
      return false;
    }
    return api.path == '/dev-api/server' &&
        online.path == '/online/server' &&
        websocket.path == '/socket/server';
  }

  static bool _validVueDevEndpoints(Uri? api, Uri? online, Uri? websocket) {
    if (api == null || online == null || websocket == null) return false;
    return api.scheme == 'http' &&
        api.host == 'nls-dev.xmsjznwl.com' &&
        api.path == '/server' &&
        online.scheme == 'https' &&
        online.host == 'ncrmyun-dev.xmsjznwl.com' &&
        online.path == '/server' &&
        websocket.scheme == 'ws' &&
        websocket.host == 'nls-dev.xmsjznwl.com' &&
        websocket.path == '/server';
  }

  static bool _isLoopback(String host) =>
      host == '127.0.0.1' || host == 'localhost' || host == '::1';

  static Uri? _validatedEndpoint(String raw, _EndpointKind kind) {
    if (raw.trim().isEmpty) return null;
    final candidate = Uri.tryParse(raw);
    if (candidate == null) return null;
    final safeHttp = Uri.parse('https://config.invalid');
    final safeWebsocket = Uri.parse('wss://config.invalid');
    try {
      switch (kind) {
        case _EndpointKind.api:
          ApiConfig(
            apiBase: candidate,
            onlineBase: safeHttp,
            websocketBase: safeWebsocket,
          );
        case _EndpointKind.online:
          ApiConfig(
            apiBase: safeHttp,
            onlineBase: candidate,
            websocketBase: safeWebsocket,
          );
        case _EndpointKind.websocket:
          ApiConfig(
            apiBase: safeHttp,
            onlineBase: safeHttp,
            websocketBase: candidate,
          );
      }
      return candidate;
    } on ArgumentError {
      return null;
    }
  }
}

enum _EndpointKind { api, online, websocket }

String _developmentAuthorizationCode(BusinessSystem system, ApiConfig config) {
  final usesVueDevCodes =
      config.apiBase.scheme == 'http' &&
      config.apiBase.host == 'nls-dev.xmsjznwl.com' &&
      config.apiBase.path == '/server';
  if (!usesVueDevCodes) {
    return system.developmentAuthorizationPlaceholder;
  }
  return switch (system) {
    BusinessSystem.booking => 'iwdvowefdwjvhvoepqjdjq221',
    BusinessSystem.order => 'sfjofdjvcow3dfolwnmvowejw',
    BusinessSystem.cashier => 'sp2pvoijgole4mrfjp3240490',
    BusinessSystem.wine => 'iwucvjiwnvio24qyxtaocx0',
    BusinessSystem.queue => 'dfdfjliwijfojoenmfcvnei',
    BusinessSystem.bms => 'fiwojcowjvbuiwhfv8172jmv',
    BusinessSystem.erp => 'jvioauhqonvoqj490vjjoah',
    BusinessSystem.superAdmin => system.developmentAuthorizationPlaceholder,
    BusinessSystem.vip => 'io3i40329uv9f8jvej04rjfg',
    BusinessSystem.erpWarehouse => '2oiej3ojc099u02j3rnv984',
  };
}

abstract interface class ShellDependenciesFactory {
  ShellDependencies create(ApiConfig config);

  void onRouterCreated();

  void onRouterDisposed();
}

abstract interface class ShellDependencies {
  Future<Result<void>> printCashierReportQuery(CashierReportQuery query);
  Future<Result<List<CashierVoucherRecord>>> loadVouchers(
    CashierVoucherQuery query,
  );
  Future<Result<void>> cancelVoucher(
    String recordId,
    bool Function() canDispatch,
  );
  Future<Result<String>> exportVouchers(
    CashierVoucherQuery query,
    bool Function() canDispatch,
  );
  Future<Result<List<CashierProfitLossRecord>>> loadProfitLoss();
  Future<Result<void>> submitProfitLoss(
    CashierProfitLossDraft draft,
    bool Function() canDispatch,
  );
  Future<Result<CashierReportPage>> loadCashierReportPage(
    CashierReportQuery query,
  );
  Future<Result<Map<int, String>>> loadCashierDepartments();
  Future<Result<String>> exportCashierReport(CashierReportQuery query);
  Future<Result<void>> printCashierReport(String title);
  Future<Result<CashierPaymentCustomer?>> findCashierPaymentCustomer(
    String phone,
  );
  Future<Result<void>> changeCashierPaymentCustomer(
    String paymentId,
    String phone,
  );
  ValueListenable<ManagementAccess> get managementAccess;
  ErpLoader get erpLoader;
  SessionRepository get sessionRepository;
  CashierCreditAccountsLoader get creditAccountsLoader;
  CashierMerchantManagementLoader get merchantManagementLoader;
  OrderLateDepositLoader get orderLateDepositLoader;

  ConnectionPhase get connectionPhase;

  Stream<ConnectionPhase> get connectionPhases;

  Stream<AppFailure> get realtimeFailures;

  Stream<SyncEnvelope> get cardTableEvents;

  Future<Result<void>> refreshRealtime();

  Future<Result<void>> openBusinessDay();

  Future<Result<List<MinimumConsumptionReportRow>>>
  loadMinimumConsumptionReport();

  Future<Result<List<CashierReportRow>>> loadCashierReport(
    String title,
    String startDate,
    String endDate,
    String keyword,
  );

  Future<Result<List<CocktailDetailReportRow>>> loadCocktailDetailReport(
    String keyword,
  );

  Future<Result<List<SoldOutItem>>> listSoldOutProducts();

  Future<Result<void>> setSoldOutProduct({
    required String productId,
    required int count,
    bool Function()? canDispatch,
  });

  Future<Result<void>> deleteSoldOutProduct(
    String productId, {
    bool Function()? canDispatch,
  });

  Future<Result<List<VipCardHit>>> searchVipCards(String keyword);

  Future<Result<VipMemberCard>> loadVipMember(String cardId);

  Future<Result<List<VipDepositRule>>> loadVipRules(String cardId);

  Future<Result<VipRechargeOrder>> createVipOrder(
    Map<String, Object?> body, {
    bool Function()? canDispatch,
  });

  Future<Result<VipRechargePay>> createVipPay({
    required String payId,
    required int payAmtFen,
    required int payType,
    String authCode = '',
    bool Function()? canDispatch,
  });

  Future<Result<VipLastSales?>> loadVipLastSales(String cardId);

  Future<Result<VipOrderStatus>> pollVipOrderStatus(String orderId);

  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  Future<Result<bool>> authPasswordEnabled();

  Future<Result<void>> changeAuthPassword({
    required bool enabled,
    required String loginPassword,
    required String authPassword,
  });

  Future<Result<void>> addOrderProduct({
    required String seatId,
    required String productId,
    required int count,
    required String price,
    String amount = '',
  });

  Future<Result<int>> orderCartCount(String seatId);

  Future<Result<List<OrderCartItem>>> orderCartItems(String seatId);

  Future<Result<void>> setOrderCartCount({
    required String seatId,
    required String itemId,
    required int count,
  });

  Future<Result<void>> bindOrderWaiter(String seatId);

  Future<Result<List<OrderGuestHit>>> searchOrderGuests(String phone);

  Future<Result<void>> bindOrderGuest({
    required String seatId,
    required String phone,
  });

  Future<Result<List<OrderPlacedItem>>> loadOrderItems({
    required String seatId,
    required int turnoverCount,
  });

  Future<Result<bool>> checkOrderAmounts(String seatId);

  Future<Result<OrderPlacedData>> loadOrderDetails({
    required String seatId,
    required int turnoverCount,
  });

  Future<Result<void>> placeOrder({
    required String seatId,
    required List<String> cartItemIds,
  });

  Future<Result<void>> addTimedProduct({
    required String seatId,
    required String productId,
    required int count,
    required String amount,
  });

  Future<Result<void>> addSet({
    required String seatId,
    required String productId,
    required int count,
    required int priceFen,
    required List<String> groupIds,
    required List<String> detailProductIds,
    required List<int> detailCounts,
    required List<int> selectCounts,
    List<String> requirements = const [],
  });

  Future<Result<void>> refundOrder({
    required String seatId,
    required String orderId,
    required int count,
    required String amount,
    required String remark,
    required bool online,
    String authEmpCode = '',
    String authEmpPasswd = '',
    int passType = 1,
  });

  Future<Result<void>> convertCartToYh({
    required String seatId,
    required List<String> cartItemIds,
    required List<int> counts,
    required String reason,
  });

  Future<Result<void>> addYh({
    required String seatId,
    required String productId,
    required int count,
    required String amount,
    required String price,
    required String reason,
  });

  Future<Result<void>> addYh2({
    required String seatId,
    required String productId,
    required int count,
    required String salesEmpId,
    required String yh2SeatId,
  });

  Future<Result<void>> addRequirement({
    required String seatId,
    required String itemId,
    required String requirement,
  });

  Future<Result<void>> changeSetDetail({
    required String seatId,
    required String itemId,
    required String groupId,
    required String detailProductId,
    required List<String> destDetailProductIds,
    required List<int> destSelectCounts,
    required String requirement,
    required List<String> destRequirements,
  });

  Future<Result<void>> convertCartToYh2({
    required String seatId,
    required List<String> cartItemIds,
    required List<int> counts,
    required String salesEmpId,
    required String yh2SeatId,
  });

  Future<Result<void>> giftOrdered({
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String reason,
  });

  Future<Result<void>> changeOrderedSet({
    required String seatId,
    required String orderId,
    required String orderDetailId,
    required List<String> destDetailProductIds,
    required List<int> destSelectCounts,
    required List<String> destRequirements,
    String authEmpCode = '',
    String authEmpPasswd = '',
    int passType = 1,
  });

  Future<Result<void>> convertOrderToYh2({
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String salesEmpId,
    required String yh2SeatId,
  });

  Future<Result<void>> reprintKitchen(String orderId);

  Future<Result<void>> printBill({
    required String seatId,
    required bool unpaid,
    required bool includeHl,
  });

  Future<Result<void>> cleanSeat(String seatId);

  Future<Result<void>> mergeYh2({
    required String seatId,
    required List<String> orderIds,
    required String destSeatId,
  });

  Future<Result<List<OrderPlacedItem>>> waiterTodoOrders(String seatId);

  Future<Result<WaiterPayQr>> createWaiterPay({
    required String seatId,
    required int payType,
    required List<String> orderIds,
  });

  Future<Result<void>> redeemCoupon(String authCode);

  Future<Result<List<WineSaveCsm>>> listWineCsms(String seatId);

  Future<Result<void>> submitSaveWine({
    required List<String> cartIds,
    required String phone,
    required String name,
    required String authCode,
  });

  Future<Result<void>> submitTakeWine({
    required String seatId,
    required List<String> inventoryIds,
    required List<int> counts,
    required String phone,
    required String authCode,
  });

  Future<Result<void>> submitConfiscateWine({
    required String seatId,
    required String date,
    required String salesEmpId,
    required List<String> productIds,
    required List<String> unitTypes,
    required List<int> counts,
    required List<int> grams,
  });

  Future<Result<PayOrderData>> loadPayOrders({
    required String seatId,
    required int turnoverCount,
  });

  Future<Result<List<PayCartItem>>> payCartItems(String seatId);

  Future<Result<void>> refundPaidOrder({
    required String seatId,
    required String payId,
    required List<String> orderIds,
    required List<int> counts,
    required List<String> amounts,
    required String remark,
  });

  Future<Result<void>> movePayOrder({
    required String seatId,
    required String destSeatId,
    required List<String> orderIds,
    List<int> counts = const [],
    int? totalAmtFen,
    bool Function()? canDispatch,
  });

  Future<Result<void>> batchUpdateOrderWaiter({
    required String seatId,
    required List<String> orderIds,
    required String waiterEmpId,
    bool Function()? canDispatch,
  });

  Set<String> paidTransfersNeedingVerification(String seatId);
  Future<Result<void>> verifyPaidTransfer({
    required String seatId,
    required String payId,
    required int turnoverCount,
    bool Function()? canDispatch,
  });
  Future<Result<void>> movePaidPayOrder({
    required String seatId,
    required String destSeatId,
    required String payId,
    required int totalAmtFen,
    required int turnoverCount,
    required String receiptFingerprint,
    List<String> selectedUnpaidIds = const [],
    bool Function()? canDispatch,
  });

  Future<Result<void>> batchUpdateOrderAuther({
    required String seatId,
    required List<String> orderIds,
    required String authEmpId,
    bool Function()? canDispatch,
  });

  Future<Result<void>> addPayChannel({
    required String seatId,
    required String channelId,
    required String amount,
  });

  Future<Result<void>> deletePayChannel({
    required String seatId,
    required String itemId,
  });

  Future<Result<void>> submitPayOrder({
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String totalAmount,
  });

  Future<Result<void>> payCleanSeat(String seatId);

  Future<Result<void>> paySettleMode({
    required String seatId,
    required int settleMode,
  });

  Future<Result<void>> payPrintBill(String seatId);

  Future<Result<void>> payAuthChannel({
    required String seatId,
    required String amount,
  });

  Future<Result<void>> payLateChannel({
    required String seatId,
    required String lateId,
  });

  Future<Result<void>> payMemberChannel({
    required String seatId,
    required String cardId,
    required int amountFen,
    required String phone,
    required String authCode,
  });

  Future<Result<void>> payPrepayChannel({
    required String seatId,
    required String prepayId,
    required String amount,
    required String authCode,
  });

  Future<Result<void>> closeBusinessDay();

  Future<Result<void>> printShiftBill();

  Future<Result<AutoCloseConfig>> loadAutoClose();

  Future<Result<void>> saveAutoClose({
    required bool enabled,
    required int hour,
    required int minute,
  });

  Future<Result<VipCardPage>> listVipCards({
    required int pageNum,
    required int pageSize,
    String keyword = '',
    bool init = false,
  });

  Future<Result<VipNewCardParams>> vipNewCardParams();

  Future<Result<String>> createVipCard({
    required String cardNo,
    required String typeId,
    required String levelId,
    required String name,
    String bindPhone = '',
    String bindAuthCode = '',
    String contactPhone = '',
  });

  Future<Result<List<VipCardRow>>> vipPhoneCards(String phone);

  Future<Result<VipMakeCardBegin>> vipMakeCardBegin({
    required String cardNo,
    required String memberCardId,
  });

  Future<Result<void>> vipMakeCardEnd({
    required String cardNo,
    required String memberCardId,
  });

  Future<Result<void>> vipSendSms({required String phone, required int typeId});

  VipPages vipPages();

  Future<Result<void>> writeBookingCard({
    required BookingCardWriteAction action,
    required String seatId,
    String bookId = '',
    Map<String, Object?> fields = const <String, Object?>{},
    bool Function()? canDispatch,
  });

  Future<Result<BookingBookDetail>> loadBookingBookDetail(String bookId);

  Future<Result<BookingDetailConfig>> loadBookingDetailConfig();

  Future<Result<List<SeatOpenLogRow>>> loadSeatOpenLog({
    String key = '',
    int deptId = 0,
    int typeId = 1,
  });

  Future<Result<String>> exportSeatOpenLog({String key = '', int typeId = 1});

  Future<Result<List<SeatChangeLogRow>>> loadSeatChangeLog();

  Future<Result<List<BookListRow>>> loadBookList();

  Future<Result<String>> exportBookList();

  Future<Result<List<OnlineBookListRow>>> loadOnlineBookList();

  Future<Result<String>> exportOnlineBookList();

  Future<Result<List<SeatOpeningRow>>> loadSeatOpeningList();

  Future<Result<String>> exportSeatOpeningList();

  Future<Result<DeptRegionSeatOpenData>> loadDeptRegionSeatOpenList();

  Future<Result<String>> exportDeptRegionSeatOpenList();

  Future<Result<void>> queueCall({
    required int queueTypeId,
    required int queueNo,
  });

  Future<Result<void>> queueArrive({
    required int queueTypeId,
    required int queueNo,
  });

  Future<Result<void>> queueExpired({
    required int queueTypeId,
    required int queueNo,
  });

  Future<Result<String>> exportQueueList({int queueTypeId = 0, int status = 0});

  Future<Result<List<TurnoverSaleHistoryItem>>> loadTurnoverSales(
    String seatId,
  );

  Future<Result<void>> changeTurnoverSales({
    required String seatId,
    required String csmId,
    required String salesEmpId,
    String secondSalesEmpId = '',
    required String reason,
  });

  Future<Result<List<SeatTurnbackItem>>> loadTurnbackList(String seatId);

  Future<Result<void>> confirmTurnback(String csmId);

  Future<Result<BookingOrderDetailData>> loadOrderDetail({
    required String seatId,
    required int turnoverCount,
  });

  Future<Result<List<BookingReservedItem>>> loadReservedList({
    required bool isToday,
    int futureType = 1,
  });

  Future<Result<void>> cancelReservedInfo(List<String> bookIds);

  Future<Result<void>> singleAllocation({
    required String id,
    required String seatId,
  });

  Future<Result<void>> manyAllocation(List<String> bookIds);

  Future<void> startRealtime();

  Future<void> stopRealtime();

  Future<void> dispose();
}

final class DefaultShellDependenciesFactory
    implements ShellDependenciesFactory {
  const DefaultShellDependenciesFactory();

  @override
  ShellDependencies create(ApiConfig config) =>
      _DefaultShellDependencies(config);

  @override
  void onRouterCreated() {}

  @override
  void onRouterDisposed() {}
}

final class _DefaultShellDependencies implements ShellDependencies {
  int _businessDayDispatchEpoch = 0;
  final ManagementPermissionFeed _managementFeed = ManagementPermissionFeed();
  final WineSaveEditMetadata _wineSaveEditMetadata = WineSaveEditMetadata();
  @override
  ValueListenable<ManagementAccess> get managementAccess => _managementFeed;
  _DefaultShellDependencies(this._config)
    : _credentialStore = FlutterSecureCredentialStore(),
      _dio = Dio(),
      _syncDio = Dio() {
    _protocolClient = ProtocolClient(
      dio: _dio,
      config: _config,
      credentialStore: _credentialStore,
      requestGate: RequestGate(clock: DateTime.now),
    );
    _syncProtocolClient = ProtocolClient(
      dio: _syncDio,
      config: _config,
      credentialStore: _credentialStore,
      requestGate: RequestGate(clock: DateTime.now),
      responseLimits: const ProtocolResponseLimits(
        maxRawResponseBytes: 64 * 1024 * 1024,
        maxDepth: 64,
        maxNodes: 1000000,
      ),
    );
    sessionRepository = SessionRepository(
      api: SessionApi(client: _protocolClient),
      credentialStore: _credentialStore,
    );
    connectionPhases = _CurrentValueStream<ConnectionPhase>(
      _phaseEvents.stream,
      () => _currentPhase,
    );
    realtimeFailures = _OptionalCurrentValueStream<AppFailure>(
      _failureEvents.stream,
      () => _lastFailure,
    );
  }

  final ApiConfig _config;
  final CredentialStore _credentialStore;
  final Dio _dio;
  final Dio _syncDio;
  late final ProtocolClient _protocolClient;
  late final ProtocolClient _syncProtocolClient;
  RealtimeController? _realtimeController;
  final StreamController<ConnectionPhase> _phaseEvents =
      StreamController<ConnectionPhase>.broadcast(sync: true);
  final StreamController<AppFailure> _failureEvents =
      StreamController<AppFailure>.broadcast(sync: true);
  final CardTableEventFeed _cardEvents = CardTableEventFeed();
  // ignore: cancel_subscriptions
  StreamSubscription<ConnectionPhase>? _phaseSubscription;
  // ignore: cancel_subscriptions
  StreamSubscription<AppFailure>? _failureSubscription;
  // ignore: cancel_subscriptions
  StreamSubscription<SyncEnvelope>? _eventSubscription;
  ConnectionPhase _currentPhase = ConnectionPhase.blocked;
  AppFailure? _lastFailure;
  int _realtimeGeneration = 0;
  int? _activeRealtimeGeneration;
  bool _disposed = false;
  int _reportGeneration = 0;
  @override
  late final CashierCreditAccountsLoader creditAccountsLoader =
      SessionBoundCashierCreditAccountsLoader(
        session: sessionRepository,
        api: ProtocolCashierCreditAccountsApi(client: _syncProtocolClient),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  @override
  late final CashierMerchantManagementLoader merchantManagementLoader =
      SessionBoundCashierMerchantManagementLoader(
        session: sessionRepository,
        api: ProtocolCashierMerchantManagementApi(client: _syncProtocolClient),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  late final SessionBoundMinimumConsumptionReportLoader _minimumReportLoader =
      SessionBoundMinimumConsumptionReportLoader(
        session: sessionRepository,
        loadRemote: () =>
            ProtocolMinimumConsumptionReportApi(client: _syncProtocolClient)
                .load(ClientKind.order),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  late final SessionBoundCocktailDetailReportLoader _cocktailReportLoader =
      SessionBoundCocktailDetailReportLoader(
        session: sessionRepository,
        loadRemote: (keyword) =>
            ProtocolCocktailDetailReportApi(client: _syncProtocolClient)
                .load(ClientKind.order, keyword: keyword),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  late final SessionBoundCashierReportPrinter _reportPrinter =
      SessionBoundCashierReportPrinter(
        session: sessionRepository,
        api: ProtocolCashierReportsApi(client: _syncProtocolClient),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  late final SessionBoundCashierVoucherLoader _voucherLoader =
      SessionBoundCashierVoucherLoader(
        session: sessionRepository,
        api: ProtocolCashierVoucherApi(client: _syncProtocolClient),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  late final SessionBoundCashierProfitLossLoader _profitLossLoader =
      SessionBoundCashierProfitLossLoader(
        session: sessionRepository,
        api: ProtocolCashierProfitLossApi(client: _syncProtocolClient),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  late final SessionBoundSoldOutProductsLoader _soldOutLoader =
      SessionBoundSoldOutProductsLoader(
        session: sessionRepository,
        listRemote: (client) =>
            ProtocolSoldOutProductsApi(client: _syncProtocolClient)
                .list(client),
        setRemote:
            ({
              required ClientKind client,
              required bool Function() canDispatch,
              required String productId,
              required int count,
            }) => ProtocolSoldOutProductsApi(client: _syncProtocolClient).set(
              client,
              productId: productId,
              count: count,
              canDispatch: canDispatch,
            ),
        deleteRemote:
            (
              productId, {
              required ClientKind client,
              required bool Function() canDispatch,
            }) => ProtocolSoldOutProductsApi(client: _syncProtocolClient)
                .delete(client, productId: productId, canDispatch: canDispatch),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  late final SessionBoundVipRechargeLoader _vipRechargeLoader =
      SessionBoundVipRechargeLoader(
        session: sessionRepository,
        api: ProtocolVipRechargeApi(client: _syncProtocolClient),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  late final SessionBoundAccountPasswordLoader _accountPasswordLoader =
      SessionBoundAccountPasswordLoader(
        session: sessionRepository,
        api: ProtocolAccountPasswordApi(client: _syncProtocolClient),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  late final SessionBoundOrderMealLoader _orderMealLoader =
      SessionBoundOrderMealLoader(
        session: sessionRepository,
        api: ProtocolOrderMealApi(client: _syncProtocolClient),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  @override
  late final OrderLateDepositLoader orderLateDepositLoader =
      SessionBoundOrderLateDepositLoader(
        session: sessionRepository,
        api: ProtocolOrderLateDepositApi(client: _syncProtocolClient),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  late final SessionBoundWineOrderLoader _wineOrderLoader =
      SessionBoundWineOrderLoader(
        session: sessionRepository,
        api: ProtocolWineOrderApi(client: _syncProtocolClient),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  late final SessionBoundPayOrderLoader _payOrderLoader =
      SessionBoundPayOrderLoader(
        session: sessionRepository,
        api: ProtocolPayOrderApi(client: _syncProtocolClient),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  late final SessionBoundVipManagerLoader _vipManagerLoader =
      SessionBoundVipManagerLoader(
        session: sessionRepository,
        hasMemberEditModule: () =>
            _managementFeed.value.snapshot.available &&
            _managementFeed.value.snapshot.moduleIds.contains(30),
        accessGeneration: () => _managementFeed.revision,
        api: ProtocolVipManagerApi(client: _syncProtocolClient),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  late final SessionBoundVipPagesLoader _vipPagesLoader =
      SessionBoundVipPagesLoader(
        session: sessionRepository,
        hasMemberEditModule: () =>
            _managementFeed.value.snapshot.available &&
            _managementFeed.value.snapshot.moduleIds.contains(30),
        accessGeneration: () => _managementFeed.revision,
        pages: ProtocolVipPagesApi(client: _syncProtocolClient),
        cards: ProtocolVipManagerApi(client: _syncProtocolClient),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  late final SessionBoundBookingCardLoader _bookingCardLoader =
      SessionBoundBookingCardLoader(
        session: sessionRepository,
        api: ProtocolBookingCardApi(client: _syncProtocolClient),
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );
  late final ProtocolBookingReportsLoader _bookingReportsLoader =
      ProtocolBookingReportsLoader(
        api: ProtocolBookingReportsApi(client: _syncProtocolClient),
      );
  late final ProtocolBookingQueueLoader _bookingQueueLoader =
      ProtocolBookingQueueLoader(
        api: ProtocolBookingQueueApi(client: _syncProtocolClient),
      );
  late final WineLoader wineLoader = SessionBoundWineLoader(
    session: sessionRepository,
    saveEditMetadata: () => _wineSaveEditMetadata.snapshot,
    api: ProtocolWineApi(client: _syncProtocolClient),
    isOnline: () => !_disposed && _currentPhase == ConnectionPhase.online,
    generation: () => _reportGeneration,
  );
  late final BmsLoader bmsLoader = ProtocolBmsLoader(
    sessionRepository: sessionRepository,
    api: ProtocolBmsApi(client: _syncProtocolClient),
    phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
    generation: () => _reportGeneration,
  );
  @override
  ErpLoader get erpLoader => ProtocolErpLoader(
    session: sessionRepository,
    isOnline: () => !_disposed && _currentPhase == ConnectionPhase.online,
    generation: () => _reportGeneration,
    api: ProtocolErpApi(
      client: _syncProtocolClient,
      clientKind:
          sessionRepository.currentMachine?.client ?? ClientKind.erpAdmin,
    ),
  );
  late final ProtocolSuperAdminLoader superAdminLoader =
      ProtocolSuperAdminLoader(
        session: sessionRepository,
        credentials: _credentialStore,
        api: ProtocolSuperAdminApi(client: _syncProtocolClient),
      );

  @override
  late final SessionRepository sessionRepository;

  @override
  late final Stream<ConnectionPhase> connectionPhases;

  @override
  late final Stream<AppFailure> realtimeFailures;

  @override
  Stream<SyncEnvelope> get cardTableEvents => _cardEvents.events;

  RealtimeController get _realtime {
    final existing = _realtimeController;
    if (existing != null) return existing;
    final controller = RealtimeController(
      config: _config,
      client: sessionRepository.currentMachine?.client ?? ClientKind.cashier,
      credentialStore: _credentialStore,
      syncApi: ProtocolSyncApi(client: _syncProtocolClient),
      socketTransport: const WebSocketChannelTransport(),
    );
    final generation = ++_realtimeGeneration;
    _activeRealtimeGeneration = generation;
    _realtimeController = controller;
    // Stored and cancelled by stopRealtime/dispose.
    // ignore: cancel_subscriptions
    _phaseSubscription = controller.phases.listen((phase) {
      if (!identical(_realtimeController, controller) ||
          _activeRealtimeGeneration != generation) {
        return;
      }
      if (_currentPhase != phase) {
        _reportGeneration += 1;
      }
      _currentPhase = phase;
      _managementFeed.setPhase(phase);
      _wineSaveEditMetadata.setPhase(phase);
      if (!_phaseEvents.isClosed) _phaseEvents.add(phase);
    });
    // Stored and cancelled by stopRealtime/dispose.
    // ignore: cancel_subscriptions
    _failureSubscription = controller.failures.listen((failure) {
      if (!identical(_realtimeController, controller) ||
          _activeRealtimeGeneration != generation) {
        return;
      }
      _lastFailure = failure;
      if (!_failureEvents.isClosed) _failureEvents.add(failure);
    });
    // Stored and cancelled by stopRealtime/dispose.
    // ignore: cancel_subscriptions
    _eventSubscription = controller.events.listen((event) {
      if (!identical(_realtimeController, controller) ||
          _activeRealtimeGeneration != generation) {
        return;
      }
      _managementFeed.add(event);
      _wineSaveEditMetadata.add(event);
      if (event.type != SyncEventType.heartbeat) {
        final data = event.data;
        if (event.type != SyncEventType.data ||
            data is List ||
            (data is Map &&
                (data.containsKey(18) ||
                    data.containsKey('18') ||
                    data.containsKey(54) ||
                    data.containsKey('54')))) {
          _businessDayDispatchEpoch++;
        }
      }
      _cardEvents.add(event);
    });
    return controller;
  }

  @override
  ConnectionPhase get connectionPhase => _currentPhase;

  @override
  Future<Result<void>> printCashierReportQuery(CashierReportQuery query) =>
      _reportPrinter.print(query);
  @override
  Future<Result<List<CashierVoucherRecord>>> loadVouchers(
    CashierVoucherQuery query,
  ) => _voucherLoader.load(query);
  @override
  Future<Result<void>> cancelVoucher(
    String recordId,
    bool Function() canDispatch,
  ) => _voucherLoader.cancel(recordId, canDispatch);
  @override
  Future<Result<String>> exportVouchers(
    CashierVoucherQuery query,
    bool Function() canDispatch,
  ) async {
    final user = sessionRepository.currentUser,
        machine = sessionRepository.currentMachine;
    final epoch = _reportGeneration;
    bool current() =>
        !_disposed &&
        _currentPhase == ConnectionPhase.online &&
        identical(user, sessionRepository.currentUser) &&
        identical(machine, sessionRepository.currentMachine) &&
        epoch == _reportGeneration &&
        canDispatch();
    const stale = AppFailure(
      kind: FailureKind.authentication,
      code: 'voucher.export_context_changed',
      safeMessage: '页面、登录或连接已改变，请重新导出',
    );
    final file = await _voucherLoader.export(query, current);
    if (file.failureOrNull case final failure?) return FailureResult(failure);
    if (!current()) return const FailureResult(stale);
    final saved = await saveWineExport(file.valueOrNull!, canSave: current);
    return current() ? saved : const FailureResult(stale);
  }

  @override
  Future<Result<List<CashierProfitLossRecord>>> loadProfitLoss() =>
      _profitLossLoader.load();

  @override
  Future<Result<void>> submitProfitLoss(
    CashierProfitLossDraft draft,
    bool Function() canDispatch,
  ) => _profitLossLoader.submit(draft, canDispatch);

  @override
  Future<Result<List<MinimumConsumptionReportRow>>>
  loadMinimumConsumptionReport() => _minimumReportLoader.load();

  @override
  Future<Result<List<CashierReportRow>>> loadCashierReport(
    String title,
    String startDate,
    String endDate,
    String keyword,
  ) => _cashierReportCall(
    (kind) => ProtocolCashierReportsApi(client: _syncProtocolClient)
        .loadReportData(
          kind,
          reportTitle: title,
          startDate: startDate,
          endDate: endDate,
          keyword: keyword,
        ),
  );

  Future<Result<T>> _cashierReportCall<T>(
    Future<Result<T>> Function(ClientKind) run,
  ) async {
    const failure = AppFailure(
      kind: FailureKind.authentication,
      code: 'cashier_report.context_unavailable',
      safeMessage: '登录或连接状态已变化，请重新打开报表',
    );
    final user = sessionRepository.currentUser;
    final machine = sessionRepository.currentMachine;
    final epoch = _reportGeneration;
    if (_disposed ||
        user == null ||
        machine?.client != ClientKind.cashier ||
        _currentPhase != ConnectionPhase.online) {
      return const FailureResult(failure);
    }
    final Result<T> result;
    try {
      result = await run(machine!.client);
    } on Object {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.unknown,
          code: 'cashier_report.failed',
          safeMessage: '报表操作失败，请重试',
        ),
      );
    }
    if (_disposed ||
        !identical(user, sessionRepository.currentUser) ||
        !identical(machine, sessionRepository.currentMachine) ||
        epoch != _reportGeneration ||
        _currentPhase != ConnectionPhase.online) {
      return const FailureResult(failure);
    }
    return result;
  }

  @override
  Future<Result<CashierReportPage>> loadCashierReportPage(
    CashierReportQuery query,
  ) => _cashierReportCall(
    (kind) =>
        ProtocolCashierReportsApi(client: _syncProtocolClient)
            .loadReportPage(kind, query: query),
  );

  @override
  Future<Result<Map<int, String>>> loadCashierDepartments() =>
      _cashierReportCall(
        (kind) =>
            ProtocolCashierReportsApi(client: _syncProtocolClient)
                .loadDepartments(kind),
      );

  @override
  Future<Result<void>> printCashierReport(String title) => _cashierReportCall(
    (kind) =>
        ProtocolCashierReportsApi(client: _syncProtocolClient)
            .printReport(kind, title: title),
  );

  @override
  Future<Result<CashierPaymentCustomer?>> findCashierPaymentCustomer(
    String phone,
  ) => _cashierReportCall(
    (kind) =>
        ProtocolCashierReportsApi(client: _syncProtocolClient)
            .findPaymentCustomer(kind, phone: phone),
  );

  @override
  Future<Result<void>> changeCashierPaymentCustomer(
    String paymentId,
    String phone,
  ) => _cashierReportCall(
    (kind) =>
        ProtocolCashierReportsApi(client: _syncProtocolClient)
            .changePaymentCustomer(kind, paymentId: paymentId, phone: phone),
  );

  @override
  Future<Result<String>> exportCashierReport(CashierReportQuery query) async {
    final user = sessionRepository.currentUser;
    final machine = sessionRepository.currentMachine;
    final epoch = _reportGeneration;
    bool current() =>
        !_disposed &&
        _currentPhase == ConnectionPhase.online &&
        identical(user, sessionRepository.currentUser) &&
        identical(machine, sessionRepository.currentMachine) &&
        epoch == _reportGeneration &&
        (query.canDispatch?.call() ?? true);
    const stale = AppFailure(
      kind: FailureKind.authentication,
      code: 'cashier_report.context_unavailable',
      safeMessage: '登录或连接已改变，请重新导出',
    );
    final file = await _cashierReportCall(
      (kind) =>
          ProtocolCashierReportsApi(client: _syncProtocolClient)
              .exportReport(kind, query: query),
    );
    if (file.failureOrNull case final failure?) return FailureResult(failure);
    if (!current()) return const FailureResult(stale);
    final saved = await saveWineExport(file.valueOrNull!, canSave: current);
    return current() ? saved : const FailureResult(stale);
  }

  @override
  Future<Result<List<CocktailDetailReportRow>>> loadCocktailDetailReport(
    String keyword,
  ) => _cocktailReportLoader.load(keyword);

  @override
  Future<Result<List<SoldOutItem>>> listSoldOutProducts() =>
      _soldOutLoader.list();

  @override
  Future<Result<void>> setSoldOutProduct({
    required String productId,
    required int count,
    bool Function()? canDispatch,
  }) => _soldOutLoader.set(
    productId: productId,
    count: count,
    canDispatch: canDispatch,
  );

  @override
  Future<Result<void>> deleteSoldOutProduct(
    String productId, {
    bool Function()? canDispatch,
  }) => _soldOutLoader.delete(productId, canDispatch: canDispatch);

  @override
  Future<Result<List<VipCardHit>>> searchVipCards(String keyword) =>
      _vipRechargeLoader.search(keyword);

  @override
  Future<Result<VipMemberCard>> loadVipMember(String cardId) =>
      _vipRechargeLoader.detail(cardId);

  @override
  Future<Result<List<VipDepositRule>>> loadVipRules(String cardId) =>
      _vipRechargeLoader.rules(cardId);

  @override
  Future<Result<VipRechargeOrder>> createVipOrder(
    Map<String, Object?> body, {
    bool Function()? canDispatch,
  }) => _vipRechargeLoader.createOrder(body, canDispatch: canDispatch);

  @override
  Future<Result<VipRechargePay>> createVipPay({
    required String payId,
    required int payAmtFen,
    required int payType,
    String authCode = '',
    bool Function()? canDispatch,
  }) => _vipRechargeLoader.createPay(
    payId: payId,
    payAmtFen: payAmtFen,
    payType: payType,
    authCode: authCode,
    canDispatch: canDispatch,
  );

  @override
  Future<Result<VipLastSales?>> loadVipLastSales(String cardId) =>
      _vipRechargeLoader.lastSales(cardId);

  @override
  Future<Result<VipOrderStatus>> pollVipOrderStatus(String orderId) =>
      _vipRechargeLoader.orderStatus(orderId);

  @override
  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) => _accountPasswordLoader.changePassword(
    oldPassword: oldPassword,
    newPassword: newPassword,
  );

  @override
  Future<Result<bool>> authPasswordEnabled() =>
      _accountPasswordLoader.authPasswordEnabled();

  @override
  Future<Result<void>> changeAuthPassword({
    required bool enabled,
    required String loginPassword,
    required String authPassword,
  }) => _accountPasswordLoader.changeAuthPassword(
    enabled: enabled,
    loginPassword: loginPassword,
    authPassword: authPassword,
  );

  @override
  Future<Result<void>> addOrderProduct({
    required String seatId,
    required String productId,
    required int count,
    required String price,
    String amount = '',
  }) => _orderMealLoader.addProduct(
    seatId: seatId,
    productId: productId,
    count: count,
    price: price,
    amount: amount,
  );

  @override
  Future<Result<int>> orderCartCount(String seatId) =>
      _orderMealLoader.cartCount(seatId);

  @override
  Future<Result<List<OrderCartItem>>> orderCartItems(String seatId) =>
      _orderMealLoader.listItems(seatId);

  @override
  Future<Result<void>> setOrderCartCount({
    required String seatId,
    required String itemId,
    required int count,
  }) => _orderMealLoader.setCount(seatId: seatId, itemId: itemId, count: count);

  @override
  Future<Result<void>> bindOrderWaiter(String seatId) =>
      _orderMealLoader.bindWaiter(seatId: seatId);

  @override
  Future<Result<List<OrderGuestHit>>> searchOrderGuests(String phone) =>
      _orderMealLoader.searchGuests(phone: phone);

  @override
  Future<Result<void>> bindOrderGuest({
    required String seatId,
    required String phone,
  }) => _orderMealLoader.bindGuest(seatId: seatId, phone: phone);

  @override
  Future<Result<List<OrderPlacedItem>>> loadOrderItems({
    required String seatId,
    required int turnoverCount,
  }) =>
      _orderMealLoader.listOrders(seatId: seatId, turnoverCount: turnoverCount);

  @override
  Future<Result<OrderPlacedData>> loadOrderDetails({
    required String seatId,
    required int turnoverCount,
  }) => _orderMealLoader.listOrdersWithSummary(
    seatId: seatId,
    turnoverCount: turnoverCount,
  );

  @override
  Future<Result<void>> placeOrder({
    required String seatId,
    required List<String> cartItemIds,
  }) => _orderMealLoader.placeOrder(seatId: seatId, cartItemIds: cartItemIds);

  @override
  Future<Result<void>> addTimedProduct({
    required String seatId,
    required String productId,
    required int count,
    required String amount,
  }) => _orderMealLoader.addTimed(
    seatId: seatId,
    productId: productId,
    count: count,
    amount: amount,
  );

  @override
  Future<Result<void>> addSet({
    required String seatId,
    required String productId,
    required int count,
    required int priceFen,
    required List<String> groupIds,
    required List<String> detailProductIds,
    required List<int> detailCounts,
    required List<int> selectCounts,
    List<String> requirements = const [],
  }) => _orderMealLoader.addSet(
    seatId: seatId,
    productId: productId,
    count: count,
    priceFen: priceFen,
    groupIds: groupIds,
    detailProductIds: detailProductIds,
    detailCounts: detailCounts,
    selectCounts: selectCounts,
    requirements: requirements,
  );

  @override
  Future<Result<void>> refundOrder({
    required String seatId,
    required String orderId,
    required int count,
    required String amount,
    required String remark,
    required bool online,
    String authEmpCode = '',
    String authEmpPasswd = '',
    int passType = 1,
  }) => _orderMealLoader.refundOrder(
    seatId: seatId,
    orderId: orderId,
    count: count,
    amount: amount,
    remark: remark,
    online: online,
    authEmpCode: authEmpCode,
    authEmpPasswd: authEmpPasswd,
    passType: passType,
  );

  @override
  Future<Result<bool>> checkOrderAmounts(String seatId) =>
      _orderMealLoader.checkOrderAmounts(seatId);

  @override
  Future<Result<void>> convertCartToYh({
    required String seatId,
    required List<String> cartItemIds,
    required List<int> counts,
    required String reason,
  }) => _orderMealLoader.convertCartToYh(
    seatId: seatId,
    cartItemIds: cartItemIds,
    counts: counts,
    reason: reason,
  );

  @override
  Future<Result<void>> addYh({
    required String seatId,
    required String productId,
    required int count,
    required String amount,
    required String price,
    required String reason,
  }) => _orderMealLoader.addYh(
    seatId: seatId,
    productId: productId,
    count: count,
    amount: amount,
    price: price,
    reason: reason,
  );

  @override
  Future<Result<void>> addYh2({
    required String seatId,
    required String productId,
    required int count,
    required String salesEmpId,
    required String yh2SeatId,
  }) => _orderMealLoader.addYh2(
    seatId: seatId,
    productId: productId,
    count: count,
    salesEmpId: salesEmpId,
    yh2SeatId: yh2SeatId,
  );

  @override
  Future<Result<void>> addRequirement({
    required String seatId,
    required String itemId,
    required String requirement,
  }) => _orderMealLoader.addRequirement(
    seatId: seatId,
    itemId: itemId,
    requirement: requirement,
  );

  @override
  Future<Result<void>> changeSetDetail({
    required String seatId,
    required String itemId,
    required String groupId,
    required String detailProductId,
    required List<String> destDetailProductIds,
    required List<int> destSelectCounts,
    required String requirement,
    required List<String> destRequirements,
  }) => _orderMealLoader.changeSetDetail(
    seatId: seatId,
    itemId: itemId,
    groupId: groupId,
    detailProductId: detailProductId,
    destDetailProductIds: destDetailProductIds,
    destSelectCounts: destSelectCounts,
    requirement: requirement,
    destRequirements: destRequirements,
  );

  @override
  Future<Result<void>> convertCartToYh2({
    required String seatId,
    required List<String> cartItemIds,
    required List<int> counts,
    required String salesEmpId,
    required String yh2SeatId,
  }) => _orderMealLoader.convertCartToYh2(
    seatId: seatId,
    cartItemIds: cartItemIds,
    counts: counts,
    salesEmpId: salesEmpId,
    yh2SeatId: yh2SeatId,
  );

  @override
  Future<Result<void>> giftOrdered({
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String reason,
  }) => _orderMealLoader.giftOrdered(
    seatId: seatId,
    orderIds: orderIds,
    counts: counts,
    reason: reason,
  );

  @override
  Future<Result<void>> changeOrderedSet({
    required String seatId,
    required String orderId,
    required String orderDetailId,
    required List<String> destDetailProductIds,
    required List<int> destSelectCounts,
    required List<String> destRequirements,
    String authEmpCode = '',
    String authEmpPasswd = '',
    int passType = 1,
  }) => _orderMealLoader.changeOrderedSet(
    seatId: seatId,
    orderId: orderId,
    orderDetailId: orderDetailId,
    destDetailProductIds: destDetailProductIds,
    destSelectCounts: destSelectCounts,
    destRequirements: destRequirements,
    authEmpCode: authEmpCode,
    authEmpPasswd: authEmpPasswd,
    passType: passType,
  );

  @override
  Future<Result<void>> convertOrderToYh2({
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String salesEmpId,
    required String yh2SeatId,
  }) => _orderMealLoader.convertOrderToYh2(
    seatId: seatId,
    orderIds: orderIds,
    counts: counts,
    salesEmpId: salesEmpId,
    yh2SeatId: yh2SeatId,
  );

  @override
  Future<Result<void>> reprintKitchen(String orderId) =>
      _orderMealLoader.reprintKitchen(orderId);

  @override
  Future<Result<void>> printBill({
    required String seatId,
    required bool unpaid,
    required bool includeHl,
  }) => _orderMealLoader.printBill(
    seatId: seatId,
    unpaid: unpaid,
    includeHl: includeHl,
  );

  @override
  Future<Result<void>> cleanSeat(String seatId) =>
      _orderMealLoader.cleanSeat(seatId);

  @override
  Future<Result<void>> mergeYh2({
    required String seatId,
    required List<String> orderIds,
    required String destSeatId,
  }) => _orderMealLoader.mergeYh2(
    seatId: seatId,
    orderIds: orderIds,
    destSeatId: destSeatId,
  );

  @override
  Future<Result<List<OrderPlacedItem>>> waiterTodoOrders(String seatId) =>
      _orderMealLoader.waiterTodoOrders(seatId);

  @override
  Future<Result<WaiterPayQr>> createWaiterPay({
    required String seatId,
    required int payType,
    required List<String> orderIds,
  }) => _orderMealLoader.createWaiterPay(
    seatId: seatId,
    payType: payType,
    orderIds: orderIds,
  );

  @override
  Future<Result<void>> redeemCoupon(String authCode) =>
      _orderMealLoader.redeemCoupon(authCode);

  @override
  Future<Result<List<WineSaveCsm>>> listWineCsms(String seatId) =>
      _wineOrderLoader.listCsms(seatId);

  @override
  Future<Result<void>> submitSaveWine({
    required List<String> cartIds,
    required String phone,
    required String name,
    required String authCode,
  }) => _wineOrderLoader.submitSave(
    cartIds: cartIds,
    phone: phone,
    name: name,
    authCode: authCode,
  );

  @override
  Future<Result<void>> submitTakeWine({
    required String seatId,
    required List<String> inventoryIds,
    required List<int> counts,
    required String phone,
    required String authCode,
  }) => _wineOrderLoader.submitTake(
    seatId: seatId,
    inventoryIds: inventoryIds,
    counts: counts,
    phone: phone,
    authCode: authCode,
  );

  @override
  Future<Result<void>> submitConfiscateWine({
    required String seatId,
    required String date,
    required String salesEmpId,
    required List<String> productIds,
    required List<String> unitTypes,
    required List<int> counts,
    required List<int> grams,
  }) => _wineOrderLoader.submitConfiscate(
    seatId: seatId,
    date: date,
    salesEmpId: salesEmpId,
    productIds: productIds,
    unitTypes: unitTypes,
    counts: counts,
    grams: grams,
  );

  @override
  Future<Result<PayOrderData>> loadPayOrders({
    required String seatId,
    required int turnoverCount,
  }) =>
      _payOrderLoader.loadOrders(seatId: seatId, turnoverCount: turnoverCount);

  @override
  Future<Result<List<PayCartItem>>> payCartItems(String seatId) =>
      _payOrderLoader.listCart(seatId);

  @override
  Future<Result<void>> refundPaidOrder({
    required String seatId,
    required String payId,
    required List<String> orderIds,
    required List<int> counts,
    required List<String> amounts,
    required String remark,
  }) => _payOrderLoader.refundPayed(
    seatId: seatId,
    payId: payId,
    orderIds: orderIds,
    counts: counts,
    amounts: amounts,
    remark: remark,
  );

  @override
  Future<Result<void>> movePayOrder({
    required String seatId,
    required String destSeatId,
    required List<String> orderIds,
    List<int> counts = const [],
    int? totalAmtFen,
    bool Function()? canDispatch,
  }) => _payOrderLoader.moveOrder(
    seatId: seatId,
    destSeatId: destSeatId,
    orderIds: orderIds,
    counts: counts,
    totalAmtFen: totalAmtFen,
    canDispatch: canDispatch,
  );

  @override
  Set<String> paidTransfersNeedingVerification(String seatId) =>
      _payOrderLoader.paidTransfersNeedingVerification(seatId);
  @override
  Future<Result<void>> verifyPaidTransfer({
    required String seatId,
    required String payId,
    required int turnoverCount,
    bool Function()? canDispatch,
  }) => _payOrderLoader.verifyPaidTransfer(
    seatId: seatId,
    payId: payId,
    turnoverCount: turnoverCount,
    canDispatch: canDispatch,
  );
  @override
  Future<Result<void>> movePaidPayOrder({
    required String seatId,
    required String destSeatId,
    required String payId,
    required int totalAmtFen,
    required int turnoverCount,
    required String receiptFingerprint,
    List<String> selectedUnpaidIds = const [],
    bool Function()? canDispatch,
  }) => _payOrderLoader.movePayedOrder(
    seatId: seatId,
    destSeatId: destSeatId,
    payId: payId,
    totalAmtFen: totalAmtFen,
    turnoverCount: turnoverCount,
    receiptFingerprint: receiptFingerprint,
    selectedUnpaidIds: selectedUnpaidIds,
    canDispatch: canDispatch,
  );

  @override
  Future<Result<void>> batchUpdateOrderWaiter({
    required String seatId,
    required List<String> orderIds,
    required String waiterEmpId,
    bool Function()? canDispatch,
  }) => _payOrderLoader.batchUpdateOrderWaiter(
    seatId: seatId,
    orderIds: orderIds,
    waiterEmpId: waiterEmpId,
    canDispatch: canDispatch,
  );
  @override
  Future<Result<void>> batchUpdateOrderAuther({
    required String seatId,
    required List<String> orderIds,
    required String authEmpId,
    bool Function()? canDispatch,
  }) => _payOrderLoader.batchUpdateOrderAuther(
    seatId: seatId,
    orderIds: orderIds,
    authEmpId: authEmpId,
    canDispatch: canDispatch,
  );

  @override
  Future<Result<void>> addPayChannel({
    required String seatId,
    required String channelId,
    required String amount,
  }) => _payOrderLoader.addChannel(
    seatId: seatId,
    channelId: channelId,
    amount: amount,
  );

  @override
  Future<Result<void>> deletePayChannel({
    required String seatId,
    required String itemId,
  }) => _payOrderLoader.deleteChannel(seatId: seatId, itemId: itemId);

  @override
  Future<Result<void>> submitPayOrder({
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String totalAmount,
  }) => _payOrderLoader.payOrder(
    seatId: seatId,
    orderIds: orderIds,
    counts: counts,
    totalAmount: totalAmount,
  );

  @override
  Future<Result<void>> payCleanSeat(String seatId) =>
      _payOrderLoader.cleanSeat(seatId);

  @override
  Future<Result<void>> paySettleMode({
    required String seatId,
    required int settleMode,
  }) => _payOrderLoader.setSettleMode(seatId: seatId, settleMode: settleMode);

  @override
  Future<Result<void>> payPrintBill(String seatId) =>
      _payOrderLoader.printBill(seatId);

  @override
  Future<Result<void>> payAuthChannel({
    required String seatId,
    required String amount,
  }) => _payOrderLoader.addAuthChannel(seatId: seatId, amount: amount);

  @override
  Future<Result<void>> payLateChannel({
    required String seatId,
    required String lateId,
  }) => _payOrderLoader.addLateChannel(seatId: seatId, lateId: lateId);

  @override
  Future<Result<void>> payMemberChannel({
    required String seatId,
    required String cardId,
    required int amountFen,
    required String phone,
    required String authCode,
  }) => _payOrderLoader.addMemberCardChannel(
    seatId: seatId,
    cardId: cardId,
    amountFen: amountFen,
    phone: phone,
    authCode: authCode,
  );

  @override
  Future<Result<void>> payPrepayChannel({
    required String seatId,
    required String prepayId,
    required String amount,
    required String authCode,
  }) => _payOrderLoader.addPrepayChannel(
    seatId: seatId,
    prepayId: prepayId,
    amount: amount,
    authCode: authCode,
  );

  late final ProtocolBusinessDayApi _businessDayApi = ProtocolBusinessDayApi(
    client: _protocolClient,
  );

  late final SessionBoundBusinessDayLoader _cashierDayLoader =
      SessionBoundBusinessDayLoader(
        session: sessionRepository,
        api: _businessDayApi,
        dispatchScope: () => _businessDayDispatchEpoch,
        phase: () => _disposed ? ConnectionPhase.blocked : _currentPhase,
        generation: () => _reportGeneration,
      );

  @override
  Future<Result<void>> openBusinessDay() {
    if (_disposed) {
      return Future<Result<void>>.value(
        const FailureResult<void>(
          AppFailure(
            kind: FailureKind.realtime,
            code: 'business_day.unavailable',
            safeMessage: '当前无法开启营业日，请稍后重试',
          ),
        ),
      );
    }
    final machine = sessionRepository.currentMachine;
    if (machine?.client != ClientKind.booking) {
      return Future<Result<void>>.value(
        const FailureResult<void>(
          AppFailure(
            kind: FailureKind.authentication,
            code: 'business_day.booking_required',
            safeMessage: '仅预订终端可开启营业日',
          ),
        ),
      );
    }
    return _businessDayApi.open(machine!.client);
  }

  @override
  Future<Result<void>> closeBusinessDay() => _cashierDayLoader.close();

  @override
  Future<Result<void>> printShiftBill() => _cashierDayLoader.printShift();

  @override
  Future<Result<AutoCloseConfig>> loadAutoClose() =>
      _cashierDayLoader.loadAutoClose();

  @override
  Future<Result<void>> saveAutoClose({
    required bool enabled,
    required int hour,
    required int minute,
  }) => _cashierDayLoader.saveAutoClose(
    enabled: enabled,
    hour: hour,
    minute: minute,
  );

  @override
  Future<Result<VipCardPage>> listVipCards({
    required int pageNum,
    required int pageSize,
    String keyword = '',
    bool init = false,
  }) => _vipManagerLoader.listCards(
    pageNum: pageNum,
    pageSize: pageSize,
    keyword: keyword,
    init: init,
  );

  @override
  Future<Result<VipNewCardParams>> vipNewCardParams() =>
      _vipManagerLoader.newCardParams();

  @override
  Future<Result<String>> createVipCard({
    required String cardNo,
    required String typeId,
    required String levelId,
    required String name,
    String bindPhone = '',
    String bindAuthCode = '',
    String contactPhone = '',
  }) => _vipManagerLoader.createCard(
    cardNo: cardNo,
    typeId: typeId,
    levelId: levelId,
    name: name,
    bindPhone: bindPhone,
    bindAuthCode: bindAuthCode,
    contactPhone: contactPhone,
  );

  @override
  Future<Result<List<VipCardRow>>> vipPhoneCards(String phone) =>
      _vipManagerLoader.phoneCards(phone);

  @override
  Future<Result<VipMakeCardBegin>> vipMakeCardBegin({
    required String cardNo,
    required String memberCardId,
  }) => _vipManagerLoader.makeCardBegin(
    cardNo: cardNo,
    memberCardId: memberCardId,
  );

  @override
  Future<Result<void>> vipMakeCardEnd({
    required String cardNo,
    required String memberCardId,
  }) =>
      _vipManagerLoader.makeCardEnd(cardNo: cardNo, memberCardId: memberCardId);

  @override
  Future<Result<void>> vipSendSms({
    required String phone,
    required int typeId,
  }) => _vipManagerLoader.sendSms(phone: phone, typeId: typeId);

  @override
  VipPages vipPages() => _vipPagesLoader.workspace;

  @override
  Future<Result<void>> writeBookingCard({
    required BookingCardWriteAction action,
    required String seatId,
    String bookId = '',
    Map<String, Object?> fields = const <String, Object?>{},
    bool Function()? canDispatch,
  }) => _bookingCardLoader.write(
    action: action,
    seatId: seatId,
    bookId: bookId,
    fields: fields,
    canDispatch: canDispatch,
  );

  @override
  Future<Result<BookingBookDetail>> loadBookingBookDetail(String bookId) =>
      _bookingCardLoader.getBookDetail(bookId);

  @override
  Future<Result<BookingDetailConfig>> loadBookingDetailConfig() =>
      _bookingCardLoader.getBookingDetailConfig();

  bool Function() _bookingExportGuard() {
    final user = sessionRepository.currentUser;
    final machine = sessionRepository.currentMachine;
    final epoch = _reportGeneration;
    return () =>
        !_disposed &&
        _currentPhase == ConnectionPhase.online &&
        user != null &&
        machine != null &&
        identical(user, sessionRepository.currentUser) &&
        identical(machine, sessionRepository.currentMachine) &&
        _reportGeneration == epoch;
  }

  @override
  Future<Result<List<SeatOpenLogRow>>> loadSeatOpenLog({
    String key = '',
    int deptId = 0,
    int typeId = 1,
  }) => _bookingReportsLoader.loadSeatOpenLog(
    key: key,
    deptId: deptId,
    typeId: typeId,
  );

  @override
  Future<Result<String>> exportSeatOpenLog({
    String key = '',
    int typeId = 1,
  }) => _bookingReportsLoader.exportSeatOpenLog(
    key: key,
    typeId: typeId,
    canDispatch: _bookingExportGuard(),
  );

  @override
  Future<Result<List<SeatChangeLogRow>>> loadSeatChangeLog() =>
      _bookingReportsLoader.loadSeatChangeLog();

  @override
  Future<Result<List<BookListRow>>> loadBookList() =>
      _bookingReportsLoader.loadBookList();

  @override
  Future<Result<String>> exportBookList() =>
      _bookingReportsLoader.exportBookList(canDispatch: _bookingExportGuard());

  @override
  Future<Result<List<OnlineBookListRow>>> loadOnlineBookList() =>
      _bookingReportsLoader.loadOnlineBookList();

  @override
  Future<Result<String>> exportOnlineBookList() => _bookingReportsLoader
      .exportOnlineBookList(canDispatch: _bookingExportGuard());

  @override
  Future<Result<List<SeatOpeningRow>>> loadSeatOpeningList() =>
      _bookingReportsLoader.loadSeatOpeningList();

  @override
  Future<Result<String>> exportSeatOpeningList() => _bookingReportsLoader
      .exportSeatOpeningList(canDispatch: _bookingExportGuard());

  @override
  Future<Result<DeptRegionSeatOpenData>> loadDeptRegionSeatOpenList() =>
      _bookingReportsLoader.loadDeptRegionSeatOpenList();

  @override
  Future<Result<String>> exportDeptRegionSeatOpenList() => _bookingReportsLoader
      .exportDeptRegionSeatOpenList(canDispatch: _bookingExportGuard());

  @override
  Future<Result<void>> queueCall({
    required int queueTypeId,
    required int queueNo,
  }) => _bookingQueueLoader.call(queueTypeId: queueTypeId, queueNo: queueNo);

  @override
  Future<Result<void>> queueArrive({
    required int queueTypeId,
    required int queueNo,
  }) => _bookingQueueLoader.arrive(queueTypeId: queueTypeId, queueNo: queueNo);

  @override
  Future<Result<void>> queueExpired({
    required int queueTypeId,
    required int queueNo,
  }) => _bookingQueueLoader.expired(queueTypeId: queueTypeId, queueNo: queueNo);

  @override
  Future<Result<String>> exportQueueList({
    int queueTypeId = 0,
    int status = 0,
  }) => _bookingQueueLoader.exportQueueList(
    queueTypeId: queueTypeId,
    status: status,
    canDispatch: _bookingExportGuard(),
  );

  @override
  Future<Result<List<TurnoverSaleHistoryItem>>> loadTurnoverSales(
    String seatId,
  ) => _bookingCardLoader.getHisSales(seatId);

  @override
  Future<Result<void>> changeTurnoverSales({
    required String seatId,
    required String csmId,
    required String salesEmpId,
    String secondSalesEmpId = '',
    required String reason,
  }) => _bookingCardLoader.chgHisSales(
    seatId: seatId,
    csmId: csmId,
    salesEmpId: salesEmpId,
    secondSalesEmpId: secondSalesEmpId,
    reason: reason,
  );

  @override
  Future<Result<List<SeatTurnbackItem>>> loadTurnbackList(String seatId) =>
      _bookingCardLoader.getTurnbackList(seatId);

  @override
  Future<Result<void>> confirmTurnback(String csmId) =>
      _bookingCardLoader.seatTurnBack(csmId);

  @override
  Future<Result<BookingOrderDetailData>> loadOrderDetail({
    required String seatId,
    required int turnoverCount,
  }) => _bookingCardLoader.getOrderDetail(
    seatId: seatId,
    turnoverCount: turnoverCount,
  );

  @override
  Future<Result<List<BookingReservedItem>>> loadReservedList({
    required bool isToday,
    int futureType = 1,
  }) => _bookingCardLoader.getReservedList(
    isToday: isToday,
    futureType: futureType,
  );

  @override
  Future<Result<void>> cancelReservedInfo(List<String> bookIds) =>
      _bookingCardLoader.cancelReservedInfo(bookIds);

  @override
  Future<Result<void>> singleAllocation({
    required String id,
    required String seatId,
  }) => _bookingCardLoader.singleAllocation(id: id, seatId: seatId);

  @override
  Future<Result<void>> manyAllocation(List<String> bookIds) =>
      _bookingCardLoader.manyAllocation(bookIds);

  @override
  Future<Result<void>> refreshRealtime() async {
    final user = sessionRepository.currentUser;
    final machine = sessionRepository.currentMachine;
    if (_disposed || user == null || machine == null) {
      return const FailureResult<void>(_refreshUnavailable);
    }
    try {
      await stopRealtime();
      if (_disposed ||
          !identical(user, sessionRepository.currentUser) ||
          !identical(machine, sessionRepository.currentMachine)) {
        return const FailureResult<void>(_refreshUnavailable);
      }
      await startRealtime();
      return const Success<void>(null);
    } on Object {
      return const FailureResult<void>(
        AppFailure(
          kind: FailureKind.realtime,
          code: 'realtime.refresh_failed',
          safeMessage: '刷新卡台数据失败，请重试',
        ),
      );
    }
  }

  @override
  Future<void> startRealtime() async {
    if (_disposed || sessionRepository.currentUser == null) return;
    if (_realtimeController == null) {
      _managementFeed.start(sessionRepository.currentUser!.stationId);
      _wineSaveEditMetadata.start();
    }
    await _realtime.start();
  }

  @override
  Future<void> stopRealtime() async {
    _businessDayDispatchEpoch++;
    _managementFeed.reset();
    _wineSaveEditMetadata.reset();
    _reportGeneration += 1;
    _cardEvents.reset();
    _lastFailure = null;
    _currentPhase = ConnectionPhase.blocked;
    if (!_phaseEvents.isClosed) _phaseEvents.add(_currentPhase);
    final controller = _realtimeController;
    if (controller == null) return;
    final generation = _activeRealtimeGeneration;
    _realtimeController = null;
    _activeRealtimeGeneration = null;
    final phaseSubscription = _phaseSubscription;
    final failureSubscription = _failureSubscription;
    final eventSubscription = _eventSubscription;
    // Stored and cancelled by stopRealtime/dispose.
    // ignore: cancel_subscriptions
    _phaseSubscription = null;
    // Stored and cancelled by stopRealtime/dispose.
    // ignore: cancel_subscriptions
    _failureSubscription = null;
    // Stored and cancelled by stopRealtime/dispose.
    // ignore: cancel_subscriptions
    _eventSubscription = null;
    await controller.dispose();
    await phaseSubscription?.cancel();
    await failureSubscription?.cancel();
    await eventSubscription?.cancel();
    if (_realtimeController == null && _realtimeGeneration == generation) {
      _currentPhase = ConnectionPhase.blocked;
      if (!_phaseEvents.isClosed) _phaseEvents.add(_currentPhase);
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stopRealtime();
    await sessionRepository.close();
    _managementFeed.dispose();
    await _phaseEvents.close();
    await _failureEvents.close();
    await _cardEvents.close();
    _dio.close(force: true);
    _syncDio.close(force: true);
  }

  static const _refreshUnavailable = AppFailure(
    kind: FailureKind.authentication,
    code: 'realtime.refresh_unavailable',
    safeMessage: '当前登录状态不可刷新',
  );
}

final _apiConfigProvider = Provider<ApiConfig>(
  (ref) => throw StateError('api config must be overridden'),
);
final _dependenciesFactoryProvider = Provider<ShellDependenciesFactory>(
  (ref) => const DefaultShellDependenciesFactory(),
);
final _shellDependenciesProvider = Provider<ShellDependencies>((ref) {
  final dependencies = ref
      .watch(_dependenciesFactoryProvider)
      .create(ref.watch(_apiConfigProvider));
  ref.onDispose(() => unawaited(dependencies.dispose()));
  return dependencies;
});
final _appSessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => ref.watch(_shellDependenciesProvider).sessionRepository,
);
final _managementAccessProvider = StreamProvider<ManagementAccess>((ref) {
  final access = ref.watch(_shellDependenciesProvider).managementAccess;
  final controller = StreamController<ManagementAccess>.broadcast(sync: true);
  void publish() => controller.add(access.value);
  access.addListener(publish);
  ref.onDispose(() {
    access.removeListener(publish);
    unawaited(controller.close());
  });
  return _CurrentValueStream<ManagementAccess>(
    controller.stream,
    () => access.value,
  );
});
final _managementRouteObserverProvider = Provider<ManagementRouteObserver>(
  (ref) => ManagementRouteObserver(),
);
final _businessRouteObserverProvider = Provider<BusinessRouteObserver>(
  (ref) => BusinessRouteObserver(),
);
final _permissionSnapshotProvider = Provider<PermissionSnapshot>(
  (ref) => PermissionSnapshot(
    available: false,
    roleIds: const <int>{},
    moduleIds: const <int>{},
    subPermissions: const <SubPermissionKey>{},
    stationId: null,
  ),
);

// Preserve authentication identity; equal employee fields are not equal logins.
final class _SessionIdentity {
  const _SessionIdentity(this.user);
  final UserSession? user;
}

final _currentUserProvider = StreamProvider<_SessionIdentity>((ref) {
  return ref
      .watch(_appSessionRepositoryProvider)
      .userSessions
      .map(_SessionIdentity.new);
});
final _realtimeLifecycleProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<_SessionIdentity>>(_currentUserProvider, (
    previous,
    next,
  ) {
    final user = next.value?.user;
    final before = previous?.value?.user;
    final dependencies = ref.read(_shellDependenciesProvider);
    if (before != null && !identical(before, user)) {
      ref.read(_managementRouteObserverProvider).closeAllOwnedRoutes();
      ref.read(_businessRouteObserverProvider).closeAllOwnedRoutes();
    }
    if (user != null) {
      if (before != null && !identical(before, user)) {
        unawaited(() async {
          await dependencies.stopRealtime();
          if (identical(dependencies.sessionRepository.currentUser, user)) {
            await dependencies.startRealtime();
          }
        }());
      } else {
        unawaited(dependencies.startRealtime());
      }
    } else if (before != null) {
      unawaited(dependencies.stopRealtime());
    }
  }, fireImmediately: true);
});
final _connectionPhaseProvider = StreamProvider<ConnectionPhase>((ref) {
  return ref.watch(_shellDependenciesProvider).connectionPhases;
});
final _realtimeFailureProvider = StreamProvider<AppFailure>((ref) {
  return ref.watch(_shellDependenciesProvider).realtimeFailures;
});
final _initialLocationProvider = Provider<String>((ref) => '/login');
final _registeredTerminalRestoreProvider = Provider<void>((ref) {
  final identity = ref.watch(_terminalIdentityProvider);
  final repository = ref.watch(_appSessionRepositoryProvider);
  final initial = ref.read(_initialLocationProvider);
  if (!identity.supported ||
      initial == '/register' ||
      initial == '/appinfo' ||
      initial.startsWith('/ManagementSystem/appinfo'))
    return;
  unawaited(() async {
    final saved = await const TerminalRegistrationSettings().load();
    final terminal = saved.valueOrNull;
    if (terminal == null ||
        repository.isClosed ||
        repository.currentMachine != null)
      return;
    final code = await identity.getMachineCode();
    if (repository.isClosed ||
        repository.currentMachine != null ||
        code.valueOrNull != terminal.machineCode)
      return;
    await repository.authorizeMachine(terminal.machineCode);
  }());
});
final _developmentSystemSelectionProvider = Provider<bool>((ref) => false);
final _superAdminLoaderProvider = Provider<SuperAdminLoader>((ref) {
  final dependencies = ref.watch(_shellDependenciesProvider);
  if (dependencies is _DefaultShellDependencies) {
    ref.onDispose(dependencies.superAdminLoader.dispose);
    return dependencies.superAdminLoader;
  }
  final credentials = FlutterSecureCredentialStore();
  final loader = ProtocolSuperAdminLoader(
    credentials: credentials,
    session: dependencies.sessionRepository,
    api: ProtocolSuperAdminApi(
      client: ProtocolClient(
        dio: Dio(),
        config: ref.watch(_apiConfigProvider),
        credentialStore: credentials,
        requestGate: RequestGate(clock: DateTime.now),
      ),
    ),
  );
  ref.onDispose(loader.dispose);
  return loader;
});

final _routerProvider = Provider<GoRouter>((ref) {
  final repository = ref.watch(_appSessionRepositoryProvider);
  final factory = ref.watch(_dependenciesFactoryProvider);
  final developmentSystemSelection = ref.watch(
    _developmentSystemSelectionProvider,
  );
  final superAdmin = ref.watch(_superAdminLoaderProvider);
  final refresh = _SessionRefresh(repository, superAdmin);
  unawaited(superAdmin.restore());
  ref.onDispose(refresh.dispose);
  final router = GoRouter(
    observers: [
      ref.read(_managementRouteObserverProvider),
      ref.read(_businessRouteObserverProvider),
    ],
    initialLocation: ref.watch(_initialLocationProvider),
    refreshListenable: refresh,
    redirect: (context, state) {
      final machine = repository.currentMachine;
      final authenticated = repository.currentUser != null;
      final location = state.matchedLocation;
      if (location == '/register') return null;
      if (location == '/appinfo') {
        return superAdmin.isAuthenticated
            ? '/ManagementSystem/appinfo/smgr'
            : null;
      }
      if (location.startsWith('/ManagementSystem/appinfo')) {
        return superAdmin.isAuthenticated || superAdmin.isBusy
            ? null
            : '/appinfo';
      }
      if (developmentSystemSelection && machine == null) {
        return location == '/select-system' ? null : '/select-system';
      }
      if (machine == null || !authenticated) {
        if (location == '/appinfo' || location == '/register') {
          return null;
        }
        return location == '/login' ? null : '/login';
      }
      final system = BusinessSystem.fromClient(machine.client);
      final landingPath = system?.landingPath ?? '/diagnostics';
      if (location == '/login' || location == '/select-system') {
        return landingPath;
      }
      if (location.startsWith('/BMS/') &&
          machine.client != ClientKind.orgManager) {
        return landingPath;
      }
      if (location.startsWith('/wine/') && machine.client != ClientKind.wine) {
        return landingPath;
      }
      if (location.startsWith('/ERP/')) {
        return machine.client == ClientKind.erp ||
                machine.client == ClientKind.erpAdmin
            ? null
            : landingPath;
      }
      if (BusinessSystem.values.any((value) => value.landingPath == location) &&
          location != landingPath) {
        return landingPath;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/select-system',
        builder: (context, state) => BusinessSystemSelectionScreen(
          onSuperAdmin: () => context.go('/appinfo'),
          onRegister: ref.read(_terminalIdentityProvider).supported
              ? () => context.go('/register')
              : null,
          authorize: (system) => ref
              .read(loginViewModelProvider.notifier)
              .authorizeMachine(
                _developmentAuthorizationCode(
                  system,
                  ref.read(_apiConfigProvider),
                ),
              ),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const _SystemLoginScreen(),
      ),
      GoRoute(
        path: '/ManagementSystem/appinfo',
        redirect: (_, _) => '/ManagementSystem/appinfo/smgr',
      ),
      for (final system in BusinessSystem.values)
        GoRoute(
          path: system.landingPath,
          builder: (context, state) => _BusinessHomeScreen(
            system: system,
            initialPath: system.landingPath,
          ),
        ),
      GoRoute(
        path: '/wine/:page',
        builder: (context, state) => _BusinessHomeScreen(
          system: BusinessSystem.wine,
          initialPath: '/wine/${state.pathParameters['page'] ?? ''}',
        ),
      ),
      GoRoute(
        path: '/BMS/:page',
        builder: (context, state) => _BusinessHomeScreen(
          system: BusinessSystem.bms,
          initialPath: state.pathParameters['page'] ?? 'stationConfig',
        ),
      ),
      GoRoute(
        path: '/ERP/:page',
        builder: (context, state) => _BusinessHomeScreen(
          system: BusinessSystem.erp,
          initialPath: state.pathParameters['page'] ?? 'home',
        ),
      ),
      GoRoute(
        path: '/appinfo',
        builder: (context, state) => SuperAdminLoginScreen(
          loader: ref.watch(_superAdminLoaderProvider),
          onLoginSuccess: (_) => context.go('/ManagementSystem/appinfo/smgr'),
          onBack: () => context.go(
            developmentSystemSelection ? '/select-system' : '/login',
          ),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => TerminalRegisterScreen(
          loader: ref.watch(_superAdminLoaderProvider),
          loadMachineCode: ref.read(_terminalIdentityProvider).getMachineCode,
          completeRegistration: (result, machineCode, current) async {
            const changed = FailureResult<void>(
              AppFailure(
                kind: FailureKind.authentication,
                code: 'terminal.context_changed',
                safeMessage: '页面已变化，请重新打开终端注册',
              ),
            );
            if (!current()) return changed;
            final saved = await const TerminalRegistrationSettings().save(
              machineCode,
              result.authMode,
            );
            if (saved.failureOrNull case final failure?)
              return FailureResult(failure);
            if (!current()) return changed;
            final authorized = await repository.authorizeMachine(machineCode);
            if (!current()) return changed;
            if (authorized.failureOrNull case final failure?)
              return FailureResult(failure);
            return const Success(null);
          },
          onRegisterSuccess: (_) => context.go('/login'),
          onBack: () => context.go(
            developmentSystemSelection ? '/select-system' : '/login',
          ),
        ),
      ),
      GoRoute(
        path: '/diagnostics',
        builder: (context, state) => const _DiagnosticsScreen(),
      ),
      GoRoute(
        path: '/diagnostics/devices',
        builder: (context, state) => DeviceDiagnosticsScreen(
          appVersion: '1.0.0+1',
          platformLabel: ref.read(_platformLabelProvider),
        ),
      ),
      GoRoute(
        path: '/reserved',
        builder: (context, state) {
          final dependencies = ref.watch(_shellDependenciesProvider);
          return BookingReservedScreen(
            onLoadBookDetail: dependencies.loadBookingBookDetail,
            onLoadReservedList: dependencies.loadReservedList,
            onCancelReservedInfo: dependencies.cancelReservedInfo,
            onSingleAllocation: dependencies.singleAllocation,
            onManyAllocation: dependencies.manyAllocation,
            onBookingCardWrite: dependencies.writeBookingCard,
            onChangePassword: (oldPassword, newPassword) =>
                dependencies.changePassword(
                  oldPassword: oldPassword,
                  newPassword: newPassword,
                ),
            onLogout: ref.read(loginViewModelProvider.notifier).logout,
            onBackToCardMachine: () => context.go('/cardMachine'),
            userName: dependencies.sessionRepository.currentUser?.name,
            employeeId: dependencies.sessionRepository.currentUser?.employeeId,
          );
        },
      ),
      GoRoute(
        path: '/payOrder',
        builder: (context, state) {
          final dependencies = ref.watch(_shellDependenciesProvider);
          final table =
              state.extra as CardTable? ??
              CardTable(
                id: '0',
                name: '卡台',
                regionId: '',
                seatType: 1,
                businessType: 1,
                capacity: 0,
                displayOrder: 0,
                businessStatus: 0,
                orderAmount: 0,
                paidAmount: 0,
                customerName: '',
                customerCount: 0,
                reservationTime: '',
                openTime: '',
                remark: '',
                mark: '',
                turnoverCount: 0,
              );
          return PayOrderScreen(
            key: ObjectKey(dependencies.sessionRepository.currentUser),
            table: table,
            loadOrders: dependencies.loadPayOrders,
            refundPayed:
                dependencies.sessionRepository.currentMachine?.client ==
                    ClientKind.cashier
                ? dependencies.refundPaidOrder
                : null,
            events: dependencies.cardTableEvents,
            connectionPhases: dependencies.connectionPhases,
            connectionPhase: dependencies.connectionPhase,
            loadCart: dependencies.payCartItems,
            addChannel: dependencies.addPayChannel,
            deleteChannel: dependencies.deletePayChannel,
            payOrder: dependencies.submitPayOrder,
            cleanSeat: dependencies.payCleanSeat,
            setSettleMode: dependencies.paySettleMode,
            printBill: dependencies.payPrintBill,
            addAuthChannel: dependencies.payAuthChannel,
            addLateChannel: dependencies.payLateChannel,
            addMemberCardChannel: dependencies.payMemberChannel,
            addPrepayChannel: dependencies.payPrepayChannel,
            moveOrder: dependencies.movePayOrder,
            movePayedOrder: dependencies.movePaidPayOrder,
            paidTransfersNeedingVerification:
                dependencies.paidTransfersNeedingVerification,
            verifyPaidTransfer: dependencies.verifyPaidTransfer,
            batchUpdateOrderWaiter: dependencies.batchUpdateOrderWaiter,
            batchUpdateOrderAuther: dependencies.batchUpdateOrderAuther,
            onOpenOrderMeal: () => context.push(
              '/orderMeal',
              extra: <String, Object?>{
                'seatId': table.id,
                'seatName': table.name,
                'turnoverCount': table.turnoverCount,
              },
            ),
          );
        },
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('页面不可用'))),
  );
  factory.onRouterCreated();
  ref.onDispose(() {
    router.dispose();
    factory.onRouterDisposed();
  });
  return router;
});

final class NativeClientApp extends StatelessWidget {
  const NativeClientApp({
    required this.appLabel,
    required this.platformLabel,
    required this.createScanner,
    required this.createPrinter,
    this.createTerminalIdentity,
    this.environment,
    this.dependenciesFactory,
    this.initialLocation = '/login',
    super.key,
  });

  final AppRuntimeConfiguration? environment;
  final ShellDependenciesFactory? dependenciesFactory;
  final String initialLocation;
  final String appLabel, platformLabel;
  final ScannerService Function(Ref ref) createScanner;
  final PrinterService Function() createPrinter;
  final TerminalIdentityService Function()? createTerminalIdentity;

  @override
  Widget build(BuildContext context) {
    final resolved = environment ?? AppRuntimeConfiguration.fromEnvironment();
    final config = resolved.config;
    if (config == null) {
      return MaterialApp(
        title: appLabel,
        theme: BookingTheme.dark(),
        home: ConfigurationErrorScreen(missingKeys: resolved.invalidKeys),
      );
    }
    return ProviderScope(
      overrides: [
        _appLabelProvider.overrideWithValue(appLabel),
        _platformLabelProvider.overrideWithValue(platformLabel),
        _apiConfigProvider.overrideWithValue(config),
        if (dependenciesFactory case final value?)
          _dependenciesFactoryProvider.overrideWithValue(value),
        _initialLocationProvider.overrideWithValue(initialLocation),
        _developmentSystemSelectionProvider.overrideWithValue(
          resolved.developmentSystemSelection,
        ),
        sessionRepositoryProvider.overrideWith(
          (ref) => ref.watch(_appSessionRepositoryProvider),
        ),
        scannerServiceProvider.overrideWith(createScanner),
        printerServiceProvider.overrideWith((ref) => createPrinter()),
        if (createTerminalIdentity case final factory?)
          _terminalIdentityProvider.overrideWith((_) => factory()),
      ],
      child: const _AppView(),
    );
  }
}

final class _AppView extends ConsumerWidget {
  const _AppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(_currentUserProvider);
    ref.watch(_registeredTerminalRestoreProvider);
    ref.watch(_realtimeLifecycleProvider);
    ref.watch(_permissionSnapshotProvider);
    return MaterialApp.router(
      title: ref.watch(_appLabelProvider),
      theme: BookingTheme.dark(),
      routerConfig: ref.watch(_routerProvider),
    );
  }
}

final class _SuperAdminHomeScreen extends ConsumerWidget {
  const _SuperAdminHomeScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) => SuperAdminNavScreen(
    loader: ref.watch(_superAdminLoaderProvider),
    onBack: () => unawaited(() async {
      await ref.read(loginViewModelProvider.notifier).logout();
      if (context.mounted)
        context.go(
          ref.read(_developmentSystemSelectionProvider)
              ? '/select-system'
              : '/login',
        );
    }()),
  );
}

final class _SystemLoginScreen extends ConsumerWidget {
  const _SystemLoginScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(loginViewModelProvider);
    final machine = ref.watch(_appSessionRepositoryProvider).currentMachine;
    final system = machine == null
        ? null
        : BusinessSystem.fromClient(machine.client);
    return Scaffold(
      backgroundColor: BookingTokens.canvasLogin,
      appBar: AppBar(
        backgroundColor: BookingTokens.surfacePanelDark,
        foregroundColor: BookingTokens.textPrimary,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: BookingTokens.dividerBlue),
        ),
        title: Text(system == null ? '登录' : '${system.label}登录'),
        actions: <Widget>[
          if (system != null)
            TextButton.icon(
              onPressed: () =>
                  ref.read(loginViewModelProvider.notifier).logout(),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('切换系统'),
            ),
          if (ref.read(_terminalIdentityProvider).supported)
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text(
                '终端注册',
                style: TextStyle(color: BookingTokens.textMuted, fontSize: 13),
              ),
            ),
          TextButton(
            onPressed: () => context.go('/appinfo'),
            child: const Text(
              '超级账号',
              style: TextStyle(color: BookingTokens.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
      body: const LoginScreen(),
    );
  }
}

final class _BusinessHomeScreen extends ConsumerWidget {
  const _BusinessHomeScreen({required this.system, this.initialPath});

  final BusinessSystem system;
  final String? initialPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dependencies = ref.watch(_shellDependenciesProvider);
    final access =
        ref.watch(_managementAccessProvider).value ??
        dependencies.managementAccess.value;
    final user =
        ref.watch(_currentUserProvider).value?.user ??
        dependencies.sessionRepository.currentUser;
    final routeObserver = ref.watch(_managementRouteObserverProvider);
    if (system == BusinessSystem.superAdmin)
      return const _SuperAdminHomeScreen();
    if (system == BusinessSystem.vip) {
      final phase =
          ref.watch(_connectionPhaseProvider).value ??
          dependencies.connectionPhase;
      if (phase != ConnectionPhase.online) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('会员系统'),
            actions: [
              TextButton(
                onPressed: () =>
                    ref.read(loginViewModelProvider.notifier).logout(),
                child: const Text('退出登录'),
              ),
            ],
          ),
          body: Column(
            children: [
              ConnectionBanner(phase: phase),
              const Expanded(child: Center(child: Text('正在连接会员系统，请稍候'))),
            ],
          ),
        );
      }
      return VipNavScreen(
        onBack: () => ref.read(loginViewModelProvider.notifier).logout(),
        listCards: dependencies.listVipCards,
        newCardParams: dependencies.vipNewCardParams,
        createCard: dependencies.createVipCard,
        phoneCards: dependencies.vipPhoneCards,
        makeCardBegin: dependencies.vipMakeCardBegin,
        makeCardEnd: dependencies.vipMakeCardEnd,
        sendSms: dependencies.vipSendSms,
        pages: dependencies.vipPages(),
      );
    }
    if (system == BusinessSystem.erp || system == BusinessSystem.erpWarehouse) {
      final erpLoader = dependencies.erpLoader;
      return ErpNavScreen(
        key: ObjectKey(user),
        phase:
            ref.watch(_connectionPhaseProvider).value ??
            dependencies.connectionPhase,
        loader: erpLoader,
        onPrintDocument: (bytes, name, canDispatch) async {
          if (!canDispatch())
            return const FailureResult(
              AppFailure(
                kind: FailureKind.authentication,
                code: 'printer.context_changed',
                safeMessage: '页面或登录已变化，打印已取消',
              ),
            );
          final printer = ref.read(printerServiceProvider);
          if (printer is! PdfDocumentPrinter)
            return const FailureResult(
              AppFailure(
                kind: FailureKind.device,
                code: 'printer.pdf_unsupported',
                safeMessage: '当前设备不支持系统文档打印',
              ),
            );
          return (printer as PdfDocumentPrinter).printPdfDocument(
            bytes,
            name: name,
            canDispatch: canDispatch,
          );
        },
        client:
            dependencies.sessionRepository.currentMachine?.client ??
            system.client,
        permissions: access.snapshot,
        safeModeEnabled: access.safeModeEnabled,
        routeObserver: routeObserver,
        onChangePassword: (oldPassword, newPassword) => dependencies
            .changePassword(oldPassword: oldPassword, newPassword: newPassword),
        initialPage: initialPath ?? 'home',
        userName: dependencies.sessionRepository.currentUser?.name ?? '管理员',
        onBack: ref.read(loginViewModelProvider.notifier).logout,
      );
    }
    if (system == BusinessSystem.bms) {
      final bmsLoader = (dependencies is _DefaultShellDependencies)
          ? dependencies.bmsLoader
          : ProtocolBmsLoader(
              sessionRepository: dependencies.sessionRepository,
              api: ProtocolBmsApi(
                client: ProtocolClient(
                  dio: Dio(),
                  config: ref.watch(_apiConfigProvider),
                  credentialStore: FlutterSecureCredentialStore(),
                  requestGate: RequestGate(clock: DateTime.now),
                ),
              ),
            );
      return BmsNavScreen(
        key: ObjectKey(user),
        phase:
            ref.watch(_connectionPhaseProvider).value ??
            dependencies.connectionPhase,
        client:
            dependencies.sessionRepository.currentMachine?.client ??
            system.client,
        loader: bmsLoader,
        permissions: access.snapshot,
        safeModeEnabled: access.safeModeEnabled,
        routeObserver: routeObserver,
        onChangePassword: (oldPassword, newPassword) => dependencies
            .changePassword(oldPassword: oldPassword, newPassword: newPassword),
        initialPage: initialPath?.split('/').last,
        userName: dependencies.sessionRepository.currentUser?.name ?? '管理员',
        onBack: ref.read(loginViewModelProvider.notifier).logout,
      );
    }
    if (system == BusinessSystem.wine) {
      final wineLoader = (dependencies is _DefaultShellDependencies)
          ? dependencies.wineLoader
          : SessionBoundWineLoader(
              session: dependencies.sessionRepository,
              isOnline: () =>
                  dependencies.connectionPhase == ConnectionPhase.online,
              api: ProtocolWineApi(
                client: ProtocolClient(
                  dio: Dio(),
                  config: ref.watch(_apiConfigProvider),
                  credentialStore: FlutterSecureCredentialStore(),
                  requestGate: RequestGate(clock: DateTime.now),
                ),
              ),
            );
      return WineNavScreen(
        key: ObjectKey(user),
        phase:
            ref.watch(_connectionPhaseProvider).value ??
            dependencies.connectionPhase,
        client:
            dependencies.sessionRepository.currentMachine?.client ??
            system.client,
        loader: wineLoader,
        permissions: access.snapshot,
        safeModeEnabled: access.safeModeEnabled,
        routeObserver: routeObserver,
        initialPath: initialPath,
        onBack: ref.read(loginViewModelProvider.notifier).logout,
      );
    }
    if (system == BusinessSystem.queue) {
      return QueueBigScreen(
        events: dependencies.cardTableEvents,
        machineId: dependencies.sessionRepository.currentMachine?.machineId,
        stationId: dependencies.sessionRepository.currentUser?.stationId,
        onBack: ref.read(loginViewModelProvider.notifier).logout,
      );
    }
    final phase =
        ref.watch(_connectionPhaseProvider).value ??
        dependencies.connectionPhase;
    return CardTableScreen(
      key: ObjectKey(user),
      businessRouteObserver: ref.watch(_businessRouteObserverProvider),
      system: system,
      events: dependencies.cardTableEvents,
      connectionPhase: phase,
      connectionPhases: dependencies.connectionPhases,
      lastFailure: ref.watch(_realtimeFailureProvider).value,
      onLogout: ref.read(loginViewModelProvider.notifier).logout,
      onSwitchSystem: ref.read(loginViewModelProvider.notifier).logout,
      onOpenBusinessDay: system == BusinessSystem.booking
          ? dependencies.openBusinessDay
          : null,
      onCloseBusinessDay: system == BusinessSystem.cashier
          ? dependencies.closeBusinessDay
          : null,
      onPrintShiftBill: system == BusinessSystem.cashier
          ? dependencies.printShiftBill
          : null,
      onLoadAutoClose: system == BusinessSystem.cashier
          ? dependencies.loadAutoClose
          : null,
      onSaveAutoClose: system == BusinessSystem.cashier
          ? dependencies.saveAutoClose
          : null,
      onRefresh: dependencies.refreshRealtime,
      onLoadMinimumConsumption: dependencies.loadMinimumConsumptionReport,
      onLoadCashierReport: dependencies.loadCashierReport,
      onLoadCashierReportPage: dependencies.loadCashierReportPage,
      onLoadProfitLoss: dependencies.loadProfitLoss,
      onSubmitProfitLoss: dependencies.submitProfitLoss,
      onLoadCashierDepartments: dependencies.loadCashierDepartments,
      onExportCashierReport: dependencies.exportCashierReport,
      onPrintCashierReport: dependencies.printCashierReport,
      onPrintCashierReportQuery: dependencies.printCashierReportQuery,
      onLoadVouchers: dependencies.loadVouchers,
      createCreditAccountsLoader: () => dependencies.creditAccountsLoader,
      createMerchantManagementLoader: () =>
          dependencies.merchantManagementLoader,
      onCancelVoucher: dependencies.cancelVoucher,
      onExportVouchers: dependencies.exportVouchers,
      onFindCashierPaymentCustomer: dependencies.findCashierPaymentCustomer,
      onChangeCashierPaymentCustomer: dependencies.changeCashierPaymentCustomer,
      onLoadCocktailDetail: dependencies.loadCocktailDetailReport,
      onListSoldOutProducts: dependencies.listSoldOutProducts,
      onSetSoldOutProduct: dependencies.setSoldOutProduct,
      onDeleteSoldOutProduct: dependencies.deleteSoldOutProduct,
      onSearchVipCards: dependencies.searchVipCards,
      onLoadVipMember: dependencies.loadVipMember,
      onLoadVipRules: dependencies.loadVipRules,
      onCreateVipOrder: dependencies.createVipOrder,
      onCreateVipPay: dependencies.createVipPay,
      onLoadVipLastSales: dependencies.loadVipLastSales,
      onPollVipOrderStatus: dependencies.pollVipOrderStatus,
      onChangePassword: (oldPassword, newPassword) => dependencies
          .changePassword(oldPassword: oldPassword, newPassword: newPassword),
      onLoadAuthPasswordEnabled: dependencies.authPasswordEnabled,
      onChangeAuthPassword: dependencies.changeAuthPassword,
      onAddOrderProduct: dependencies.addOrderProduct,
      onOrderCartCount: dependencies.orderCartCount,
      onOrderCartItems: dependencies.orderCartItems,
      onSetOrderCartCount: dependencies.setOrderCartCount,
      onBindOrderWaiter: dependencies.bindOrderWaiter,
      onSearchOrderGuests: dependencies.searchOrderGuests,
      onBindOrderGuest: dependencies.bindOrderGuest,
      onLoadOrderItems: dependencies.loadOrderItems,
      onLoadOrderDetails: dependencies.loadOrderDetails,
      onPlaceOrder: dependencies.placeOrder,
      onAddTimedProduct: dependencies.addTimedProduct,
      onAddSet: dependencies.addSet,
      onRefundOrder: dependencies.refundOrder,
      onCheckOrderAmounts: dependencies.checkOrderAmounts,
      onConvertCartToYh: dependencies.convertCartToYh,
      onAddYh: dependencies.addYh,
      onAddYh2: dependencies.addYh2,
      onAddRequirement: dependencies.addRequirement,
      onChangeSetDetail: dependencies.changeSetDetail,
      onConvertCartToYh2: dependencies.convertCartToYh2,
      onGiftOrdered: dependencies.giftOrdered,
      onChangeOrderedSet: dependencies.changeOrderedSet,
      onConvertOrderToYh2: dependencies.convertOrderToYh2,
      onReprintKitchen: dependencies.reprintKitchen,
      onPrintBill: dependencies.printBill,
      onCleanSeat: dependencies.cleanSeat,
      onMergeYh2: dependencies.mergeYh2,
      onWaiterTodoOrders: dependencies.waiterTodoOrders,
      onCreateWaiterPay: dependencies.createWaiterPay,
      onRedeemCoupon: dependencies.redeemCoupon,
      onListWineCsms: dependencies.listWineCsms,
      onSubmitSaveWine: dependencies.submitSaveWine,
      onSubmitTakeWine: dependencies.submitTakeWine,
      onSubmitConfiscateWine: dependencies.submitConfiscateWine,
      onLoadPayOrders: dependencies.loadPayOrders,
      onMovePayOrder: dependencies.movePayOrder,
      onMovePaidPayOrder: dependencies.movePaidPayOrder,
      paidTransfersNeedingVerification:
          dependencies.paidTransfersNeedingVerification,
      onVerifyPaidTransfer: dependencies.verifyPaidTransfer,
      onBatchUpdateOrderWaiter: dependencies.batchUpdateOrderWaiter,
      onBatchUpdateOrderAuther: dependencies.batchUpdateOrderAuther,
      onRefundPaidOrder: dependencies.refundPaidOrder,
      onPayCartItems: dependencies.payCartItems,
      onAddPayChannel: dependencies.addPayChannel,
      onDeletePayChannel: dependencies.deletePayChannel,
      onSubmitPayOrder: dependencies.submitPayOrder,
      onPayCleanSeat: dependencies.payCleanSeat,
      onPaySettleMode: dependencies.paySettleMode,
      onPayPrintBill: dependencies.payPrintBill,
      onPayAuthChannel: dependencies.payAuthChannel,
      onPayLateChannel: dependencies.payLateChannel,
      onPayMemberChannel: dependencies.payMemberChannel,
      onPayPrepayChannel: dependencies.payPrepayChannel,
      onListVipCards: dependencies.listVipCards,
      onVipNewCardParams: dependencies.vipNewCardParams,
      onCreateVipCard: dependencies.createVipCard,
      onVipPhoneCards: dependencies.vipPhoneCards,
      onVipMakeCardBegin: dependencies.vipMakeCardBegin,
      onVipMakeCardEnd: dependencies.vipMakeCardEnd,
      onVipSendSms: dependencies.vipSendSms,
      vipPages: dependencies.vipPages(),
      onBookingCardWrite: dependencies.writeBookingCard,
      onLoadBookingDetailConfig: system == BusinessSystem.booking
          ? dependencies.loadBookingDetailConfig
          : null,
      onLoadBookDetail: dependencies.loadBookingBookDetail,
      onLoadSeatOpenLog: ({key = '', deptId = 0, typeId = 1}) => dependencies
          .loadSeatOpenLog(key: key, deptId: deptId, typeId: typeId),
      onExportSeatOpenLog: ({key = '', typeId = 1}) =>
          dependencies.exportSeatOpenLog(key: key, typeId: typeId),
      onLoadSeatChangeLog: dependencies.loadSeatChangeLog,
      onLoadBookList: dependencies.loadBookList,
      onExportBookList: dependencies.exportBookList,
      onLoadOnlineBookList: dependencies.loadOnlineBookList,
      onExportOnlineBookList: dependencies.exportOnlineBookList,
      onLoadSeatOpening: dependencies.loadSeatOpeningList,
      onExportSeatOpening: dependencies.exportSeatOpeningList,
      onLoadDeptRegionSeatOpen: dependencies.loadDeptRegionSeatOpenList,
      onExportDeptRegionSeatOpen: dependencies.exportDeptRegionSeatOpenList,
      onQueueCall: dependencies.queueCall,
      onQueueArrive: dependencies.queueArrive,
      onQueueExpired: dependencies.queueExpired,
      onExportQueueList: ({queueTypeId = 0, status = 0}) => dependencies
          .exportQueueList(queueTypeId: queueTypeId, status: status),
      onLoadTurnoverSales: dependencies.loadTurnoverSales,
      onChangeTurnoverSales: dependencies.changeTurnoverSales,
      onLoadTurnbackList: dependencies.loadTurnbackList,
      onConfirmTurnback: dependencies.confirmTurnback,
      onLoadOrderDetail: dependencies.loadOrderDetail,
      onOpenReserved: () => unawaited(context.push('/reserved')),
      onOpenPayOrder: (table) =>
          unawaited(context.push('/payOrder', extra: table)),
      onOpenDiagnostics: () => context.push('/diagnostics/devices'),
      orderLateDepositLoader: dependencies.orderLateDepositLoader,
      userName: dependencies.sessionRepository.currentUser?.name,
      machineId: dependencies.sessionRepository.currentMachine?.machineId,
      stationId: dependencies.sessionRepository.currentUser?.stationId,
      employeeId: dependencies.sessionRepository.currentUser?.employeeId,
    );
  }
}

final class _DiagnosticsScreen extends ConsumerWidget {
  const _DiagnosticsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(_appSessionRepositoryProvider);
    final config = ref.watch(_apiConfigProvider);
    final dependencies = ref.watch(_shellDependenciesProvider);
    final phase =
        ref.watch(_connectionPhaseProvider).value ??
        dependencies.connectionPhase;
    final failure = ref.watch(_realtimeFailureProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(ref.watch(_appLabelProvider))),
      body: Column(
        children: <Widget>[
          ConnectionBanner(phase: phase),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: DiagnosticPanel(
                appVersion: '1.0.0+1',
                platformLabel: ref.watch(_platformLabelProvider),
                phase: phase,
                machineId: repository.currentMachine?.machineId,
                machineName: repository.currentMachine?.machineName,
                userId: repository.currentUser?.employeeId,
                userName: repository.currentUser?.name,
                apiBase: config.apiBase,
                onlineBase: config.onlineBase,
                websocketBase: config.websocketBase,
                lastFailure: failure,
                onWriteCommand: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _SessionRefresh extends ChangeNotifier {
  _SessionRefresh(SessionRepository repository, this.admin) {
    admin.addListener(notifyListeners);
    _machineSubscription = repository.machineSessions.listen((_) {
      notifyListeners();
    });
    _userSubscription = repository.userSessions.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<MachineSession?> _machineSubscription;
  final Listenable admin;
  late final StreamSubscription<UserSession?> _userSubscription;

  @override
  void dispose() {
    admin.removeListener(notifyListeners);
    unawaited(_machineSubscription.cancel());
    unawaited(_userSubscription.cancel());
    super.dispose();
  }
}

final class _CurrentValueStream<T> extends Stream<T> {
  const _CurrentValueStream(this.source, this.current);

  final Stream<T> source;
  final T Function() current;

  @override
  bool get isBroadcast => true;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _replayStream(
    source: source,
    initial: current(),
    onData: onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

final class _OptionalCurrentValueStream<T> extends Stream<T> {
  const _OptionalCurrentValueStream(this.source, this.current);

  final Stream<T> source;
  final T? Function() current;

  @override
  bool get isBroadcast => true;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _replayStream(
    source: source,
    initial: current(),
    onData: onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

StreamSubscription<T> _replayStream<T>({
  required Stream<T> source,
  required T? initial,
  required void Function(T event)? onData,
  required Function? onError,
  required void Function()? onDone,
  required bool? cancelOnError,
}) {
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;
  controller = StreamController<T>(
    sync: true,
    onListen: () {
      subscription = source.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      if (initial != null) controller.add(initial);
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () => subscription?.cancel(),
  );
  return controller.stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}
