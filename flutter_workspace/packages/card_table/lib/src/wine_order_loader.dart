import 'package:card_table/src/wine_order.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

final class SessionBoundWineOrderLoader {
  const SessionBoundWineOrderLoader({
    required this.session,
    required this.api,
    required this.phase,
    required this.generation,
  });

  final SessionRepository session;
  final ProtocolWineOrderApi api;
  final ConnectionPhase Function() phase;
  final int Function() generation;

  Future<Result<List<WineSaveCsm>>> listCsms(String seatId) =>
      _guard((client) => api.listCsms(client, seatId: seatId));

  Future<Result<void>> addCart({
    required String csmId,
    required String productId,
    required List<String> unitTypes,
    required List<int> counts,
    required List<int> grams,
  }) => _guard(
    (client) => api.addCart(
      client,
      csmId: csmId,
      productId: productId,
      unitTypes: unitTypes,
      counts: counts,
      grams: grams,
    ),
  );

  Future<Result<void>> submitSave({
    required List<String> cartIds,
    required String phone,
    required String name,
    required String authCode,
  }) => _guard(
    (client) => api.submitSave(
      client,
      cartIds: cartIds,
      phone: phone,
      name: name,
      authCode: authCode,
    ),
  );

  Future<Result<void>> submitTake({
    required String seatId,
    required List<String> inventoryIds,
    required List<int> counts,
    required String phone,
    required String authCode,
  }) => _guard(
    (client) => api.submitTake(
      client,
      seatId: seatId,
      inventoryIds: inventoryIds,
      counts: counts,
      phone: phone,
      authCode: authCode,
    ),
  );

  Future<Result<void>> submitConfiscate({
    required String seatId,
    required String date,
    required String salesEmpId,
    required List<String> productIds,
    required List<String> unitTypes,
    required List<int> counts,
    required List<int> grams,
  }) => _guard(
    (client) => api.submitConfiscate(
      client,
      seatId: seatId,
      date: date,
      salesEmpId: salesEmpId,
      productIds: productIds,
      unitTypes: unitTypes,
      counts: counts,
      grams: grams,
    ),
  );

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
    code: 'authentication.wine_order_session_required',
    safeMessage: '请登录后再存酒',
  );
  static const AppFailure _unavailable = AppFailure(
    kind: FailureKind.network,
    code: 'network.wine_order_unavailable',
    safeMessage: '连接未就绪，暂时无法存酒',
  );
  static const AppFailure _changed = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.wine_order_context_changed',
    safeMessage: '登录或连接状态已变化，请重新打开',
  );
  static const AppFailure _failed = AppFailure(
    kind: FailureKind.unknown,
    code: 'wine_order.load_failed',
    safeMessage: '存酒失败，请重试',
  );
}
