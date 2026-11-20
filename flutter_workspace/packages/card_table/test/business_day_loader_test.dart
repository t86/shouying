import 'dart:async';

import 'package:card_table/src/business_day_api.dart';
import 'package:card_table/src/business_day_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:session/session.dart';

import 'bms_loader_guard_test.dart' show loginSession;
import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;

class DayApi implements BusinessDayApi {
  int calls = 0;
  Completer<void>? wait;
  Future<Result<void>> invoke() async {
    calls++;
    await wait?.future;
    return const Success(null);
  }

  @override
  Future<Result<void>> open(client) => invoke();
  @override
  Future<Result<void>> close(client, {bool Function()? canDispatch}) =>
      invoke();
  @override
  Future<Result<void>> printShift(client, {bool Function()? canDispatch}) =>
      invoke();
  @override
  Future<Result<AutoCloseConfig>> loadAutoClose(
    client, {
    bool Function()? canDispatch,
  }) async {
    await invoke();
    return const Success(AutoCloseConfig(enabled: false, hour: 0, minute: 0));
  }

  @override
  Future<Result<void>> saveAutoClose(
    client, {
    required bool enabled,
    required int hour,
    required int minute,
    bool Function()? canDispatch,
  }) => invoke();
}

void main() {
  for (final operation in ['close', 'print', 'load', 'save']) {
    test(
      '$operation passes pre-dispatch day scope through real protocol API',
      () async {
        final adapter = Adapter();
        final session = SessionRepository(
          api: SessionApi(client: makeApi(adapter).client),
          credentialStore: Credentials(),
        );
        await loginSession(session, adapter, 8);
        final before = adapter.requests.length;
        var scopeCalls = 0;
        final loader = SessionBoundBusinessDayLoader(
          session: session,
          api: ProtocolBusinessDayApi(client: makeApi(adapter).client),
          phase: () => ConnectionPhase.online,
          generation: () => 1,
          // Captured before invoke, changed by the time headers are prepared.
          dispatchScope: () => scopeCalls++ == 0 ? 1 : 2,
        );
        final Result<Object?> result = switch (operation) {
          'close' => await loader.close(),
          'print' => await loader.printShift(),
          'load' => await loader.loadAutoClose(),
          _ => await loader.saveAutoClose(enabled: true, hour: 5, minute: 0),
        };
        expect(result.failureOrNull?.code, 'protocol.dispatch_invalidated');
        expect(adapter.requests.length, before);
      },
    );
  }
  for (final operation in ['close', 'print', 'load', 'save']) {
    for (final change in ['offline', 'same-account', 'epoch']) {
      test(
        '$operation rejects absent/offline session and late $change',
        () async {
          final adapter = Adapter();
          final session = SessionRepository(
            api: SessionApi(client: makeApi(adapter).client),
            credentialStore: Credentials(),
          );
          var phase = ConnectionPhase.online, epoch = 1;
          final api = DayApi();
          final loader = SessionBoundBusinessDayLoader(
            session: session,
            api: api,
            phase: () => phase,
            generation: () => epoch,
          );
          Future<Result<Object?>> run() => switch (operation) {
            'close' => loader.close(),
            'print' => loader.printShift(),
            'load' => loader.loadAutoClose(),
            _ => loader.saveAutoClose(enabled: true, hour: 10, minute: 20),
          };
          expect((await run()).failureOrNull, isNotNull);
          expect(api.calls, 0);
          await loginSession(session, adapter, 8);
          phase = ConnectionPhase.blocked;
          expect((await run()).failureOrNull, isNotNull);
          expect(api.calls, 0);
          phase = ConnectionPhase.online;
          api.wait = Completer<void>();
          final pending = run();
          await Future<void>.delayed(Duration.zero);
          if (change == 'offline') phase = ConnectionPhase.blocked;
          if (change == 'epoch') epoch++;
          if (change == 'same-account') {
            await Future<void>.delayed(const Duration(milliseconds: 2));
            adapter.data = {'emp_id': '1', 'name': '测试', 'station_id': '1'};
            expect(
              (await session.login(
                account: 'test',
                password: 'test',
                type: EmployeeLoginType.account,
              )).failureOrNull,
              isNull,
            );
          }
          api.wait!.complete();
          expect(
            (await pending).failureOrNull?.code,
            'business_day.context_changed',
          );
          expect(api.calls, 1);
        },
      );
    }
  }
}
