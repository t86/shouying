import 'package:card_table/src/vip_manager.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

final class SessionBoundVipManagerLoader {
  const SessionBoundVipManagerLoader({
    required this.session,
    required this.api,
    required this.phase,
    required this.generation,
    this.hasMemberEditModule,
    this.accessGeneration,
  });

  final SessionRepository session;
  final ProtocolVipManagerApi api;
  final ConnectionPhase Function() phase;
  final int Function() generation;
  final bool Function()? hasMemberEditModule;
  final int Function()? accessGeneration;
  bool get _canManageMembers =>
      session.currentMachine != null &&
      (session.currentMachine!.client != ClientKind.vip ||
          (hasMemberEditModule?.call() ?? false));

  Future<Result<VipCardPage>> listCards({
    required int pageNum,
    required int pageSize,
    String keyword = '',
    bool init = false,
  }) => _guard(
    (client, api) => api.listCards(
      client,
      pageNum: pageNum,
      pageSize: pageSize,
      keyword: keyword,
      init: init,
    ),
  );

  Future<Result<VipNewCardParams>> newCardParams() =>
      _guard((client, api) => api.newCardParams(client));

  Future<Result<String>> createCard({
    required String cardNo,
    required String typeId,
    required String levelId,
    required String name,
    String bindPhone = '',
    String bindAuthCode = '',
    String contactPhone = '',
  }) => _guard(
    (client, api) => api.createCard(
      client,
      cardNo: cardNo,
      typeId: typeId,
      levelId: levelId,
      name: name,
      bindPhone: bindPhone,
      bindAuthCode: bindAuthCode,
      contactPhone: contactPhone,
    ),
    memberEdit: true,
  );

  Future<Result<List<VipCardRow>>> phoneCards(String phone) =>
      _guard((client, api) => api.phoneCards(client, phone: phone));

  Future<Result<VipMakeCardBegin>> makeCardBegin({
    required String cardNo,
    required String memberCardId,
  }) => _guard(
    (client, api) =>
        api.makeCardBegin(client, cardNo: cardNo, memberCardId: memberCardId),
    memberEdit: true,
  );

  Future<Result<void>> makeCardEnd({
    required String cardNo,
    required String memberCardId,
  }) => _guard(
    (client, api) =>
        api.makeCardEnd(client, cardNo: cardNo, memberCardId: memberCardId),
    memberEdit: true,
  );

  Future<Result<void>> sendSms({required String phone, required int typeId}) =>
      _guard(
        (client, api) => api.sendSms(client, phone: phone, typeId: typeId),
      );

  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function(ClientKind client, ProtocolVipManagerApi api)
    run, {
    bool memberEdit = false,
  }) async {
    try {
      final user = session.currentUser;
      final machine = session.currentMachine;
      if (user == null || machine == null) {
        return const FailureResult(_sessionRequired);
      }
      final epoch = generation();
      final accessEpoch = accessGeneration?.call();
      if (memberEdit && !_canManageMembers) {
        return const FailureResult(_permissionDenied);
      }
      if (phase() != ConnectionPhase.online) {
        return const FailureResult(_unavailable);
      }
      bool current() =>
          identical(user, session.currentUser) &&
          identical(machine, session.currentMachine) &&
          generation() == epoch &&
          accessGeneration?.call() == accessEpoch &&
          phase() == ConnectionPhase.online &&
          (!memberEdit || _canManageMembers);
      final result = await run(
        machine.client,
        ProtocolVipManagerApi(
          client: api.client,
          canDispatch: () => current() && (api.canDispatch?.call() ?? true),
        ),
      );
      if (!current()) return const FailureResult(_changed);
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
    code: 'authentication.vip_manager_session_required',
    safeMessage: '请登录后再打开会员系统',
  );
  static const AppFailure _permissionDenied = AppFailure(
    kind: FailureKind.authentication,
    code: 'vip.permission_denied',
    safeMessage: '当前会员系统无此操作权限',
  );
  static const AppFailure _unavailable = AppFailure(
    kind: FailureKind.network,
    code: 'network.vip_manager_unavailable',
    safeMessage: '连接未就绪，暂时无法打开会员系统',
  );
  static const AppFailure _changed = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.vip_manager_context_changed',
    safeMessage: '登录或连接状态已变化，请重新打开',
  );
  static const AppFailure _failed = AppFailure(
    kind: FailureKind.unknown,
    code: 'vip_manager.load_failed',
    safeMessage: '会员操作失败，请重试',
  );
}
