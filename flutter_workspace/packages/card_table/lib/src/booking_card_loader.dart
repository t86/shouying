import 'package:card_table/src/booking_card_api.dart';
import 'package:card_table/src/booking_detail_access.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

final class SessionBoundBookingCardLoader {
  const SessionBoundBookingCardLoader({
    required this.session,
    required this.api,
    required this.phase,
    required this.generation,
  });

  final SessionRepository session;
  final ProtocolBookingCardApi api;
  final ConnectionPhase Function() phase;
  final int Function() generation;

  Future<Result<void>> write({
    required BookingCardWriteAction action,
    required String seatId,
    String bookId = '',
    Map<String, Object?> fields = const <String, Object?>{},
    bool Function()? canDispatch,
  }) => _guard(
    (client, scoped) => scoped.write(
      client,
      action: action,
      seatId: seatId,
      bookId: bookId,
      fields: fields,
    ),
    canDispatch,
  );

  Future<Result<BookingDetailConfig>> getBookingDetailConfig() =>
      _guard((client, scoped) => scoped.getBookingDetailConfig(client));

  Future<Result<BookingBookDetail>> getBookDetail(String bookId) =>
      _guard((client, scoped) => scoped.getBookDetail(client, bookId: bookId));

  Future<Result<List<TurnoverSaleHistoryItem>>> getHisSales(String seatId) =>
      _guard((client, scoped) => scoped.getHisSales(client, seatId: seatId));

  Future<Result<void>> chgHisSales({
    required String seatId,
    required String csmId,
    required String salesEmpId,
    String secondSalesEmpId = '',
    required String reason,
  }) => _guard(
    (client, scoped) => scoped.chgHisSales(
      client,
      seatId: seatId,
      csmId: csmId,
      salesEmpId: salesEmpId,
      secondSalesEmpId: secondSalesEmpId,
      reason: reason,
    ),
  );

  Future<Result<List<SeatTurnbackItem>>> getTurnbackList(String seatId) =>
      _guard(
        (client, scoped) => scoped.getSeatTurnbackList(client, seatId: seatId),
      );

  Future<Result<void>> seatTurnBack(String csmId) =>
      _guard((client, scoped) => scoped.seatTurnBack(client, csmId: csmId));

  Future<Result<BookingOrderDetailData>> getOrderDetail({
    required String seatId,
    required int turnoverCount,
  }) => _guard(
    (client, scoped) => scoped.getOrderDetail(
      client,
      seatId: seatId,
      turnoverCount: turnoverCount,
    ),
  );

  Future<Result<List<BookingReservedItem>>> getReservedList({
    required bool isToday,
    int futureType = 1,
    DateTime? now,
  }) => _guard(
    (client, scoped) => scoped.getReservedList(
      client,
      isToday: isToday,
      futureType: futureType,
      now: now,
    ),
  );

  Future<Result<void>> cancelReservedInfo(List<String> bookIds) => _guard(
    (client, scoped) => scoped.cancelReservedInfo(client, bookIds: bookIds),
  );

  Future<Result<void>> singleAllocation({
    required String id,
    required String seatId,
  }) => _guard(
    (client, scoped) => scoped.singleAllocation(client, id: id, seatId: seatId),
  );

  Future<Result<void>> manyAllocation(List<String> bookIds) => _guard(
    (client, scoped) => scoped.manyAllocation(client, bookIds: bookIds),
  );

  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function(ClientKind client, ProtocolBookingCardApi scoped)
    run, [
    bool Function()? permitted,
  ]) async {
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
      bool current() =>
          !session.isClosed &&
          identical(user, session.currentUser) &&
          identical(machine, session.currentMachine) &&
          generation() == epoch &&
          phase() == ConnectionPhase.online &&
          (permitted?.call() ?? true);
      if (!current()) return const FailureResult(_changed);
      final result = await run(
        machine.client,
        ProtocolBookingCardApi(
          client: api.client,
          canDispatch: () => current() && (api.canDispatch?.call() ?? true),
        ),
      );
      if (!current()) return const FailureResult(_changed);
      return result;
    } on Object {
      return const FailureResult(_failed);
    }
  }
}

const AppFailure _sessionRequired = AppFailure(
  kind: FailureKind.authentication,
  code: 'session.required',
  safeMessage: '请重新登录后再操作',
);
const AppFailure _unavailable = AppFailure(
  kind: FailureKind.realtime,
  code: 'realtime.unavailable',
  safeMessage: '当前无法连接服务器，请稍后重试',
);
const AppFailure _changed = AppFailure(
  kind: FailureKind.authentication,
  code: 'session.changed',
  safeMessage: '登录状态已变化，请重试',
);
const AppFailure _failed = AppFailure(
  kind: FailureKind.unknown,
  code: 'booking.card_write_failed',
  safeMessage: '操作失败，请重试',
);
