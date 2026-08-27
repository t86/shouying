import 'package:dio/dio.dart';
import 'package:protocol/src/limited_response_adapter.dart';

HttpClientAdapter configureProtocolAdapter(
  HttpClientAdapter current,
  int maxRawResponseBytes,
) {
  if (current is LimitedResponseAdapter) {
    current.tightenLimit(maxRawResponseBytes);
    return current;
  }
  return LimitedResponseAdapter(current, maxRawResponseBytes);
}
