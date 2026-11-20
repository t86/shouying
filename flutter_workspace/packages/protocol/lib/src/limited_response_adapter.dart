import 'dart:typed_data';

import 'package:dio/dio.dart';

const dispatchGuardKey = 'shouyin.canDispatch';

final class DispatchInvalidatedException implements Exception {
  const DispatchInvalidatedException();
}

void checkDispatch(RequestOptions options) {
  final guard = options.extra[dispatchGuardKey];
  if (guard is! bool Function()) return;
  try {
    if (guard()) return;
  } on Object {
    // A failed authority check is never permission to send.
  }
  throw const DispatchInvalidatedException();
}

final class ResponseTooLargeException implements Exception {
  const ResponseTooLargeException();
}

int? trustedContentLength(Map<String, List<String>> headers) {
  List<String>? values;
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() != Headers.contentLengthHeader) continue;
    if (values != null) return null;
    values = entry.value;
  }
  if (values == null || values.length != 1) return null;
  final value = int.tryParse(values.single.trim());
  return value != null && value >= 0 ? value : null;
}

Stream<Uint8List> limitByteStream(
  Stream<Uint8List> source, {
  required int maxBytes,
  required void Function() onExceeded,
}) async* {
  var receivedBytes = 0;
  await for (final chunk in source) {
    receivedBytes += chunk.length;
    if (receivedBytes > maxBytes) {
      onExceeded();
      throw const ResponseTooLargeException();
    }
    yield chunk;
  }
}

final class LimitedResponseAdapter implements HttpClientAdapter {
  LimitedResponseAdapter(this._delegate, this._maxRawResponseBytes);

  final HttpClientAdapter _delegate;
  int _maxRawResponseBytes;

  void tightenLimit(int candidate) {
    if (candidate < _maxRawResponseBytes) _maxRawResponseBytes = candidate;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    checkDispatch(options);
    final response = await _delegate.fetch(
      options,
      requestStream,
      cancelFuture,
    );
    final contentLength = trustedContentLength(response.headers);
    if (contentLength != null && contentLength > _maxRawResponseBytes) {
      _closeResponse(response);
      throw const ResponseTooLargeException();
    }

    response.stream = limitByteStream(
      response.stream,
      maxBytes: _maxRawResponseBytes,
      onExceeded: () => _closeResponse(response),
    );
    return response;
  }

  void _closeResponse(ResponseBody response) {
    // Dio exposes this internal close hook specifically for adapter cleanup.
    // ignore: invalid_use_of_internal_member
    response.close();
  }

  @override
  void close({bool force = false}) => _delegate.close(force: force);
}
