import 'dart:async';
import 'dart:typed_data';

import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:protocol/src/limited_response_adapter.dart';

HttpClientAdapter configureProtocolAdapter(
  HttpClientAdapter current,
  int maxRawResponseBytes,
) {
  if (current is FetchHttpClientAdapter) {
    current.tightenLimit(maxRawResponseBytes);
    return current;
  }
  if (current is BrowserHttpClientAdapter) {
    return FetchHttpClientAdapter(maxRawResponseBytes: maxRawResponseBytes);
  }
  if (current is LimitedResponseAdapter) {
    current.tightenLimit(maxRawResponseBytes);
    return current;
  }
  return LimitedResponseAdapter(current, maxRawResponseBytes);
}

final class FetchHttpClientAdapter implements HttpClientAdapter {
  factory FetchHttpClientAdapter({
    http.Client? client,
    required int maxRawResponseBytes,
  }) =>
      FetchHttpClientAdapter._(client ?? BrowserClient(), maxRawResponseBytes);

  FetchHttpClientAdapter._(this._client, this._maxRawResponseBytes);

  final http.Client _client;
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
    final abortTrigger = Completer<void>();

    void abort() {
      if (!abortTrigger.isCompleted) abortTrigger.complete();
    }

    if (cancelFuture case final cancellation?) {
      unawaited(cancellation.whenComplete(abort));
    }

    final bodyBytes = await _collectBody(requestStream, options, abort);
    final request =
        http.AbortableRequest(
            options.method,
            options.uri,
            abortTrigger: abortTrigger.future,
          )
          ..followRedirects = options.followRedirects
          ..maxRedirects = options.maxRedirects
          ..persistentConnection = options.persistentConnection
          ..headers.addAll(_requestHeaders(options.headers))
          ..bodyBytes = bodyBytes;

    final http.StreamedResponse response;
    try {
      final pendingResponse = _client.send(request);
      final connectTimeout = options.connectTimeout;
      response = connectTimeout != null && connectTimeout > Duration.zero
          ? await pendingResponse.timeout(
              connectTimeout,
              onTimeout: () {
                abort();
                throw DioException.connectionTimeout(
                  requestOptions: options,
                  timeout: connectTimeout,
                );
              },
            )
          : await pendingResponse;
    } on DioException {
      rethrow;
    } on http.RequestAbortedException catch (error, stackTrace) {
      throw DioException.requestCancelled(
        requestOptions: options,
        reason: error,
        stackTrace: stackTrace,
      );
    } on http.ClientException catch (error, stackTrace) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'Fetch request failed',
        error: error,
        stackTrace: stackTrace,
      );
    } on Object catch (error, stackTrace) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'Fetch request failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final contentLength = _responseContentLength(response);
    if (contentLength != null && contentLength > _maxRawResponseBytes) {
      abort();
      throw const ResponseTooLargeException();
    }

    final byteStream = response.stream.map<Uint8List>(
      (chunk) => chunk is Uint8List ? chunk : Uint8List.fromList(chunk),
    );
    final limitedStream = limitByteStream(
      _mapResponseErrors(byteStream, options),
      maxBytes: _maxRawResponseBytes,
      onExceeded: abort,
    );
    return ResponseBody(
      limitedStream,
      response.statusCode,
      statusMessage: response.reasonPhrase,
      isRedirect: response.isRedirect,
      onClose: abort,
      headers: <String, List<String>>{
        for (final entry in response.headers.entries)
          entry.key.toLowerCase(): <String>[entry.value],
      },
    );
  }

  Future<Uint8List> _collectBody(
    Stream<Uint8List>? requestStream,
    RequestOptions options,
    void Function() abort,
  ) async {
    if (requestStream == null) return Uint8List(0);

    Future<Uint8List> collect() async {
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in requestStream) {
        bytes.add(chunk);
      }
      return bytes.takeBytes();
    }

    final sendTimeout = options.sendTimeout;
    if (sendTimeout == null || sendTimeout <= Duration.zero) return collect();
    return collect().timeout(
      sendTimeout,
      onTimeout: () {
        abort();
        throw DioException.sendTimeout(
          requestOptions: options,
          timeout: sendTimeout,
        );
      },
    );
  }

  Map<String, String> _requestHeaders(Map<String, Object?> headers) =>
      <String, String>{
        for (final entry in headers.entries)
          if (entry.value != null)
            entry.key: entry.value is Iterable
                ? (entry.value! as Iterable<Object?>).join(', ')
                : entry.value.toString(),
      };

  int? _responseContentLength(http.StreamedResponse response) {
    final contentLength = response.contentLength;
    if (contentLength != null && contentLength >= 0) return contentLength;
    final rawValue = response.headers[Headers.contentLengthHeader];
    if (rawValue == null) return null;
    final parsed = int.tryParse(rawValue.trim());
    return parsed != null && parsed >= 0 ? parsed : null;
  }

  Stream<Uint8List> _mapResponseErrors(
    Stream<Uint8List> source,
    RequestOptions options,
  ) async* {
    try {
      await for (final chunk in source) {
        yield chunk;
      }
    } on http.RequestAbortedException catch (error, stackTrace) {
      throw DioException.requestCancelled(
        requestOptions: options,
        reason: error,
        stackTrace: stackTrace,
      );
    } on http.ClientException catch (error, stackTrace) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'Fetch response failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void close({bool force = false}) => _client.close();
}
