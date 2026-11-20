import 'package:card_table/src/sold_out_products.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

typedef SoldOutListRemote = Future<Result<List<SoldOutItem>>> Function(
  ClientKind client,
);
typedef SoldOutSetRemote = Future<Result<void>> Function({
  required ClientKind client,
  required bool Function() canDispatch,
  required String productId,
  required int count,
});
typedef SoldOutDeleteRemote = Future<Result<void>> Function(
  String productId, {
  required ClientKind client,
  required bool Function() canDispatch,
});

final class SessionBoundSoldOutProductsLoader {
  const SessionBoundSoldOutProductsLoader({
    required this.session,
    required this.listRemote,
    required this.setRemote,
    required this.deleteRemote,
    required this.phase,
    required this.generation,
  });

  final SessionRepository session;
  final SoldOutListRemote listRemote;
  final SoldOutSetRemote setRemote;
  final SoldOutDeleteRemote deleteRemote;
  final ConnectionPhase Function() phase;
  final int Function() generation;

  Future<Result<List<SoldOutItem>>> list() =>
      _guard((client, guard) => listRemote(client));

  Future<Result<void>> set({
    required String productId,
    required int count,
    bool Function()? canDispatch,
  }) => _guard(
    (client, guard) => setRemote(
      client: client,
      canDispatch: guard,
      productId: productId,
      count: count,
    ),
    canDispatch: canDispatch,
  );

  Future<Result<void>> delete(
    String productId, {
    bool Function()? canDispatch,
  }) => _guard(
    (client, guard) =>
        deleteRemote(productId, client: client, canDispatch: guard),
    canDispatch: canDispatch,
  );

  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function(ClientKind, bool Function()) run, {
    bool Function()? canDispatch,
  }) async {
    try {
      final user = session.currentUser;
      final machine = session.currentMachine;
      if (session.isClosed ||
          user == null ||
          machine == null ||
          (machine.client != ClientKind.order &&
              machine.client != ClientKind.cashier)) {
        return const FailureResult(_sessionRequiredFailure);
      }
      final epoch = generation();
      if (phase() != ConnectionPhase.online) {
        return const FailureResult(_connectionUnavailableFailure);
      }

      bool current() =>
          !session.isClosed &&
          identical(user, session.currentUser) &&
          identical(machine, session.currentMachine) &&
          generation() == epoch &&
          phase() == ConnectionPhase.online &&
          (canDispatch?.call() ?? true);
      if (!current()) return const FailureResult(_contextChangedFailure);
      final result = await run(machine.client, current);

      if (session.isClosed ||
          !identical(user, session.currentUser) ||
          !identical(machine, session.currentMachine) ||
          generation() != epoch ||
          !(canDispatch?.call() ?? true)) {
        return const FailureResult(_contextChangedFailure);
      }
      if (phase() != ConnectionPhase.online) {
        return const FailureResult(_connectionUnavailableFailure);
      }
      return result;
    } on Object {
      return const FailureResult(_loadFailure);
    }
  }

  static const AppFailure _sessionRequiredFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.sold_out_products_session_required',
    safeMessage: '请登录点单或收银系统后维护估清商品',
  );
  static const AppFailure _connectionUnavailableFailure = AppFailure(
    kind: FailureKind.network,
    code: 'network.sold_out_products_unavailable',
    safeMessage: '连接未就绪，暂时无法维护估清商品',
  );
  static const AppFailure _contextChangedFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.sold_out_products_context_changed',
    safeMessage: '登录或连接状态已变化，请重新打开估清商品',
  );
  static const AppFailure _loadFailure = AppFailure(
    kind: FailureKind.unknown,
    code: 'sold_out_products.load_failed',
    safeMessage: '估清商品操作失败，请重试',
  );
}
