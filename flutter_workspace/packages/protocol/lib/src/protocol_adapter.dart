import 'package:dio/dio.dart';
import 'package:protocol/src/protocol_adapter_native.dart'
    if (dart.library.js_interop) 'package:protocol/src/protocol_adapter_web.dart'
    as platform;

void installProtocolAdapter(Dio dio, int maxRawResponseBytes) {
  dio.httpClientAdapter = platform.configureProtocolAdapter(
    dio.httpClientAdapter,
    maxRawResponseBytes,
  );
}
