import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

void main() {
  for (final duringCredentials in [true, false]) {
    test(
      'binary blocks stale scope at ${duringCredentials ? 'credential' : 'adapter'} boundary',
      () async {
        final credentials = _Credentials(), adapter = _Adapter();
        var current = true;
        final dio = Dio()..httpClientAdapter = adapter;
        if (!duringCredentials) {
          dio.interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                current = false;
                handler.next(options);
              },
            ),
          );
        }
        final client = ProtocolClient(
          dio: dio,
          config: ApiConfig(
            apiBase: Uri.parse('https://example.test'),
            onlineBase: Uri.parse('https://example.test'),
            websocketBase: Uri.parse('wss://example.test'),
          ),
          credentialStore: credentials,
          requestGate: RequestGate(clock: DateTime.now),
        );
        final pending = client.postBinary(
          '/export',
          client: ClientKind.erpAdmin,
          canDispatch: () => current,
        );
        await credentials.started.future;
        if (duringCredentials) current = false;
        credentials.gate.complete(
          const CredentialSnapshot(tk: 'synthetic', stk: null),
        );
        expect(
          (await pending).failureOrNull?.code,
          'protocol.dispatch_invalidated',
        );
        expect(adapter.requests, 0);
      },
    );
  }
}

class _Credentials implements CredentialStore {
  final started = Completer<void>(), gate = Completer<CredentialSnapshot>();
  @override
  Future<CredentialSnapshot> readSnapshot() {
    started.complete();
    return gate.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Adapter implements HttpClientAdapter {
  int requests = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    return ResponseBody.fromBytes([80, 75, 3, 4], 200);
  }

  @override
  void close({bool force = false}) {}
}
