import 'package:card_table/src/order_meal.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

final class SessionBoundOrderMealLoader {
  const SessionBoundOrderMealLoader({
    required this.session,
    required this.api,
    required this.phase,
    required this.generation,
  });

  final SessionRepository session;
  final ProtocolOrderMealApi api;
  final ConnectionPhase Function() phase;
  final int Function() generation;

  Future<Result<void>> addProduct({
    required String seatId,
    required String productId,
    required int count,
    required String price,
    String amount = '',
  }) => _guard(
    (client) => api.addProduct(
      client,
      seatId: seatId,
      productId: productId,
      count: count,
      price: price,
      amount: amount,
    ),
  );

  Future<Result<int>> cartCount(String seatId) =>
      _guard((client) => api.cartCount(client, seatId: seatId));

  Future<Result<List<OrderCartItem>>> listItems(String seatId) =>
      _guard((client) => api.listItems(client, seatId: seatId));

  Future<Result<void>> setCount({
    required String seatId,
    required String itemId,
    required int count,
  }) => _guard(
    (client) =>
        api.setCount(client, seatId: seatId, itemId: itemId, count: count),
  );

  Future<Result<void>> bindWaiter({required String seatId}) =>
      _guard((client) => api.bindWaiter(client, seatId: seatId));

  Future<Result<List<OrderGuestHit>>> searchGuests({required String phone}) =>
      _guard((client) => api.searchGuests(client, phone: phone));

  Future<Result<void>> bindGuest({
    required String seatId,
    required String phone,
  }) => _guard((client) => api.bindGuest(client, seatId: seatId, phone: phone));

  Future<Result<List<OrderPlacedItem>>> listOrders({
    required String seatId,
    required int turnoverCount,
  }) => _guard(
    (client) =>
        api.listOrders(client, seatId: seatId, turnoverCount: turnoverCount),
  );

  Future<Result<OrderPlacedData>> listOrdersWithSummary({
    required String seatId,
    required int turnoverCount,
  }) => _guard(
    (client) => api.listOrdersWithSummary(
      client,
      seatId: seatId,
      turnoverCount: turnoverCount,
    ),
  );

  Future<Result<void>> placeOrder({
    required String seatId,
    required List<String> cartItemIds,
  }) => _guard(
    (client) =>
        api.placeOrder(client, seatId: seatId, cartItemIds: cartItemIds),
  );

  Future<Result<void>> addTimed({
    required String seatId,
    required String productId,
    required int count,
    required String amount,
  }) => _guard(
    (client) => api.addTimed(
      client,
      seatId: seatId,
      productId: productId,
      count: count,
      amount: amount,
    ),
  );

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
  }) => _guard(
    (client) => api.addSet(
      client,
      seatId: seatId,
      productId: productId,
      count: count,
      priceFen: priceFen,
      groupIds: groupIds,
      detailProductIds: detailProductIds,
      detailCounts: detailCounts,
      selectCounts: selectCounts,
      requirements: requirements,
    ),
  );

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
  }) => _guard(
    (client) => api.refundOrder(
      client,
      seatId: seatId,
      orderId: orderId,
      count: count,
      amount: amount,
      remark: remark,
      online: online,
      authEmpCode: authEmpCode,
      authEmpPasswd: authEmpPasswd,
      passType: passType,
    ),
  );

  Future<Result<bool>> checkOrderAmounts(String seatId) =>
      _guard((client) => api.checkOrderAmounts(client, seatId: seatId));

  Future<Result<void>> convertCartToYh({
    required String seatId,
    required List<String> cartItemIds,
    required List<int> counts,
    required String reason,
  }) => _guard(
    (client) => api.convertCartToYh(
      client,
      seatId: seatId,
      cartItemIds: cartItemIds,
      counts: counts,
      reason: reason,
    ),
  );

  Future<Result<void>> addYh({
    required String seatId,
    required String productId,
    required int count,
    required String amount,
    required String price,
    required String reason,
  }) => _guard(
    (client) => api.addYh(
      client,
      seatId: seatId,
      productId: productId,
      count: count,
      amount: amount,
      price: price,
      reason: reason,
    ),
  );

  Future<Result<void>> addYh2({
    required String seatId,
    required String productId,
    required int count,
    required String salesEmpId,
    required String yh2SeatId,
  }) => _guard(
    (client) => api.addYh2(
      client,
      seatId: seatId,
      productId: productId,
      count: count,
      salesEmpId: salesEmpId,
      yh2SeatId: yh2SeatId,
    ),
  );

  Future<Result<void>> addRequirement({
    required String seatId,
    required String itemId,
    required String requirement,
  }) => _guard(
    (client) => api.addRequirement(
      client,
      seatId: seatId,
      itemId: itemId,
      requirement: requirement,
    ),
  );

  Future<Result<void>> changeSetDetail({
    required String seatId,
    required String itemId,
    required String groupId,
    required String detailProductId,
    required List<String> destDetailProductIds,
    required List<int> destSelectCounts,
    required String requirement,
    required List<String> destRequirements,
  }) => _guard(
    (client) => api.changeSetDetail(
      client,
      seatId: seatId,
      itemId: itemId,
      groupId: groupId,
      detailProductId: detailProductId,
      destDetailProductIds: destDetailProductIds,
      destSelectCounts: destSelectCounts,
      requirement: requirement,
      destRequirements: destRequirements,
    ),
  );

  Future<Result<void>> convertCartToYh2({
    required String seatId,
    required List<String> cartItemIds,
    required List<int> counts,
    required String salesEmpId,
    required String yh2SeatId,
  }) => _guard(
    (client) => api.convertCartToYh2(
      client,
      seatId: seatId,
      cartItemIds: cartItemIds,
      counts: counts,
      salesEmpId: salesEmpId,
      yh2SeatId: yh2SeatId,
    ),
  );

  Future<Result<void>> giftOrdered({
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String reason,
  }) => _guard(
    (client) => api.giftOrdered(
      client,
      seatId: seatId,
      orderIds: orderIds,
      counts: counts,
      reason: reason,
    ),
  );

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
  }) => _guard(
    (client) => api.changeOrderedSet(
      client,
      seatId: seatId,
      orderId: orderId,
      orderDetailId: orderDetailId,
      destDetailProductIds: destDetailProductIds,
      destSelectCounts: destSelectCounts,
      destRequirements: destRequirements,
      authEmpCode: authEmpCode,
      authEmpPasswd: authEmpPasswd,
      passType: passType,
    ),
  );

  Future<Result<void>> convertOrderToYh2({
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String salesEmpId,
    required String yh2SeatId,
  }) => _guard(
    (client) => api.convertOrderToYh2(
      client,
      seatId: seatId,
      orderIds: orderIds,
      counts: counts,
      salesEmpId: salesEmpId,
      yh2SeatId: yh2SeatId,
    ),
  );

  Future<Result<void>> reprintKitchen(String orderId) =>
      _guard((client) => api.reprintKitchen(client, orderId: orderId));

  Future<Result<void>> printBill({
    required String seatId,
    required bool unpaid,
    required bool includeHl,
  }) => _guard(
    (client) => api.printBill(
      client,
      seatId: seatId,
      unpaid: unpaid,
      includeHl: includeHl,
    ),
  );

  Future<Result<void>> cleanSeat(String seatId) =>
      _guard((client) => api.cleanSeat(client, seatId: seatId));

  Future<Result<void>> mergeYh2({
    required String seatId,
    required List<String> orderIds,
    required String destSeatId,
  }) => _guard(
    (client) => api.mergeYh2(
      client,
      seatId: seatId,
      orderIds: orderIds,
      destSeatId: destSeatId,
    ),
  );

  Future<Result<List<OrderPlacedItem>>> waiterTodoOrders(String seatId) =>
      _guard((client) => api.waiterTodoOrders(client, seatId: seatId));

  Future<Result<WaiterPayQr>> createWaiterPay({
    required String seatId,
    required int payType,
    required List<String> orderIds,
  }) => _guard(
    (client) => api.createWaiterPay(
      client,
      seatId: seatId,
      payType: payType,
      orderIds: orderIds,
    ),
  );

  Future<Result<void>> redeemCoupon(String authCode) =>
      _guard((client) => api.redeemCoupon(client, authCode: authCode));

  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function(ClientKind client) run,
  ) async {
    try {
      final user = session.currentUser;
      final machine = session.currentMachine;
      if (user == null || machine == null) {
        return const FailureResult(_sessionRequired);
      }
      final epoch = generation();
      if (phase() != ConnectionPhase.online) {
        return const FailureResult(_unavailable);
      }
      final result = await run(machine.client);
      if (!identical(user, session.currentUser) ||
          !identical(machine, session.currentMachine) ||
          generation() != epoch) {
        return const FailureResult(_changed);
      }
      if (phase() != ConnectionPhase.online) {
        return const FailureResult(_unavailable);
      }
      return result;
    } on Object {
      return const FailureResult(_failed);
    }
  }

  static const AppFailure _sessionRequired = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.order_meal_session_required',
    safeMessage: '请登录后再点单',
  );
  static const AppFailure _unavailable = AppFailure(
    kind: FailureKind.network,
    code: 'network.order_meal_unavailable',
    safeMessage: '连接未就绪，暂时无法点单',
  );
  static const AppFailure _changed = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.order_meal_context_changed',
    safeMessage: '登录或连接状态已变化，请重新打开',
  );
  static const AppFailure _failed = AppFailure(
    kind: FailureKind.unknown,
    code: 'order_meal.load_failed',
    safeMessage: '点单失败，请重试',
  );
}
