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
    try {
      await channel.ready;
    } on Object {
      try {
        await channel.sink.close();
      } on Object {
        // Connection setup has already failed; cleanup is best effort.
      }
      rethrow;
    }
    return _WebSocketChannelConnection(channel);
  }
}

final class SocketMessageTypeException implements Exception {
  const SocketMessageTypeException();

  @override
  String toString() => 'SocketMessageTypeException(text message required)';
}

final class _WebSocketChannelConnection implements SocketConnection {
  const _WebSocketChannelConnection(this._channel);

  final WebSocketChannel _channel;

  @override
  Future<void> get ready => _channel.ready;

  @override
  Stream<Object?> get incoming => _channel.stream.map<Object?>((message) {
    if (message is String) return message;
    throw const SocketMessageTypeException();
  });

  @override
  Future<void> sendText(String value) =>
      Future<void>.sync(() => _channel.sink.add(value));

  @override
  Future<void> close() async {
    await _channel.sink.close();
  }
}
