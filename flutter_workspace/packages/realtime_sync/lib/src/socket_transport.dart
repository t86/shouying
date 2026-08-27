import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

abstract interface class SocketTransport {
  Future<SocketConnection> connect(Uri uri);
}

abstract interface class SocketConnection {
  Future<void> get ready;

  Stream<Object?> get incoming;

  Future<void> sendText(String value);

  Future<void> close();
}

final class WebSocketChannelTransport implements SocketTransport {
  const WebSocketChannelTransport();

  @override
  Future<SocketConnection> connect(Uri uri) async {
    if (!uri.isAbsolute ||
        !uri.hasAuthority ||
        (uri.scheme != 'ws' && uri.scheme != 'wss')) {
      throw ArgumentError.value(uri, 'uri', 'must be an absolute ws/wss URI');
    }
    final channel = WebSocketChannel.connect(uri);
    return _WebSocketChannelConnection(channel);
  }
}

final class SocketMessageTypeException implements Exception {
  const SocketMessageTypeException();

  @override
  String toString() => 'SocketMessageTypeException(text message required)';
}

final class SocketClosedBeforeReadyException implements Exception {
  const SocketClosedBeforeReadyException();

  @override
  String toString() => 'SocketClosedBeforeReadyException()';
}

final class _WebSocketChannelConnection implements SocketConnection {
  _WebSocketChannelConnection(this._channel) {
    unawaited(_readyCompleter.future.catchError((Object _) {}));
    unawaited(
      _channel.ready.then(
        (_) {
          if (!_readyCompleter.isCompleted) _readyCompleter.complete();
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!_readyCompleter.isCompleted) {
            _readyCompleter.completeError(error, stackTrace);
          }
        },
      ),
    );
  }

  final WebSocketChannel _channel;
  final Completer<void> _readyCompleter = Completer<void>();
  Future<void>? _closeFuture;

  @override
  Future<void> get ready => _readyCompleter.future;

  @override
  Stream<Object?> get incoming => _channel.stream.map<Object?>((message) {
    if (message is String) return message;
    throw const SocketMessageTypeException();
  });

  @override
  Future<void> sendText(String value) =>
      Future<void>.sync(() => _channel.sink.add(value));

  @override
  Future<void> close() {
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.completeError(const SocketClosedBeforeReadyException());
    }
    return _closeFuture ??= _closeChannel();
  }

  Future<void> _closeChannel() async {
    await _channel.sink.close();
  }
}
