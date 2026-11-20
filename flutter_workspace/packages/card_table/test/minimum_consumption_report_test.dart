import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/minimum_consumption_report.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

void main() {
  test('uses the source no-body POST and selected client headers', () async {
    final adapter = _ReportAdapter([_success([]), _success([])]);
    final api = ProtocolMinimumConsumptionReportApi(client: _client(adapter));

    expect((await api.load(ClientKind.order)).failureOrNull, isNull);
    expect((await api.load(ClientKind.booking)).failureOrNull, isNull);
    expect(adapter.requests.map((r) => r.method), everyElement('POST'));
    expect(
      adapter.requests.map((r) => r.uri.path),
      everyElement('/server/wo/get_seat_zy_csm_list'),
    );
    expect(adapter.requests.map((r) => r.uri.query), everyElement(isEmpty));
    expect(adapter.requests.map((r) => r.data), everyElement(isNull));
    expect(adapter.hadRequestStream, everyElement(isFalse));
    expect(adapter.requests.map((r) => r.headers['tt']), ['4', '2']);
    expect(
      adapter.requests.map((r) => r.headers['tk']),
      everyElement('test-tk'),
    );
  });

  test('preserves the twelve source columns and eleven wire fields', () {
    expect(MinimumConsumptionReportRow.columnLabels, [
      '序号',
      '区域',
      '卡台名称',
      '开台时间',
      '订位人部门',
      '订位人',
      '最低消费',
      '主营金额',
      '差额',
      '低消进度',
      '清台时间',
      '标签',
    ]);
    expect(MinimumConsumptionReportRow.wireFields, [
      'rn',
      'sn',
      'o',
      'sd',
      'se',
      'm',
      'za',
      'ga',
      'p',
      't',
      'mk',
    ]);
  });

  test(
    'keeps backend text and finite numbers without recomputing values',
    () async {
      final adapter = _ReportAdapter([
        _success([
          {
            'rn': 'A 区',
            'sn': '001',
            'o': '2026-08-31 19:30',
            'sd': '预订部',
            'se': '测试订位人',
            'm': '000800.00',
            'za': 100.5,
            'ga': -700,
            'p': '12.5625%',
            't': null,
            'mk': '标签原文',
          },
          <String, Object?>{},
        ], code: '1'),
      ]);
      final rows = (await ProtocolMinimumConsumptionReportApi(
        client: _client(adapter),
      ).load(ClientKind.order)).valueOrNull!;

      expect(rows.first.cells, [
        'A 区',
        '001',
        '2026-08-31 19:30',
        '预订部',
        '测试订位人',
        '000800.00',
        '100.5',
        '-700',
        '12.5625%',
        '',
        '标签原文',
      ]);
      expect(rows.last.cells, List<String>.filled(11, ''));
      expect(rows.first.toString(), isNot(contains('测试订位人')));
      expect(rows.first.toString(), isNot(contains('000800.00')));
      expect(() => rows.clear(), throwsUnsupportedError);
      expect(() => rows.first.cells[0] = 'changed', throwsUnsupportedError);
    },
  );

  test('row snapshots cannot be changed by mutating their source', () {
    final source = <String, Object?>{'rn': '原区域'};
    final row = MinimumConsumptionReportRow.fromWire(source);
    source['rn'] = 'changed';
    expect(row.cells.first, '原区域');
    expect(
      () => MinimumConsumptionReportRow.wireFields.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => MinimumConsumptionReportRow.columnLabels.clear(),
      throwsUnsupportedError,
    );
  });

  test(
    'finite integral doubles use Vue numeric display without changing strings',
    () {
      final row = MinimumConsumptionReportRow.fromWire({
        'rn': 1000.0,
        'sn': -1000.0,
        'm': -0.0,
        'za': 0.0,
        'ga': 1.5,
        'p': '1000.0',
      });
      expect(row.cells, [
        '1000',
        '-1000',
        '',
        '',
        '',
        '0',
        '0',
        '1.5',
        '1000.0',
        '',
        '',
      ]);
    },
  );

  test('loads all 10000 supported unpaged rows without truncating', () async {
    final adapter = _ReportAdapter([
      _success(List.generate(10000, (i) => {'rn': '区域$i'})),
    ]);
    final rows = (await ProtocolMinimumConsumptionReportApi(
      client: _client(adapter, expandedLimits: true),
    ).load(ClientKind.order)).valueOrNull!;
    expect(rows, hasLength(10000));
    expect(rows.last.cells.first, '区域9999');
  });

  test(
    'missing and null records are empty only within a valid data map',
    () async {
      final adapter = _ReportAdapter([
        {'code': 1, 'data': <String, Object?>{}},
        {
          'code': 1,
          'data': {'records': null},
        },
        {'code': 1},
        {'code': 1, 'data': null},
        {'code': 1, 'data': []},
      ]);
      final api = ProtocolMinimumConsumptionReportApi(client: _client(adapter));
      expect((await api.load(ClientKind.order)).valueOrNull, isEmpty);
      expect((await api.load(ClientKind.order)).valueOrNull, isEmpty);
      for (var i = 0; i < 3; i++) {
        expect(
          (await api.load(ClientKind.order)).failureOrNull?.kind,
          FailureKind.protocol,
        );
      }
    },
  );

  test(
    'rejects malformed rows and cells without exposing server values',
    () async {
      for (final records in <Object?>[
        'private response',
        {'rn': 'private response'},
        [null],
        [false],
        [
          ['private response'],
        ],
        [
          {'se': true},
        ],
        [
          {
            'se': {'private': 'private response'},
          },
        ],
        [
          {
            'se': ['private response'],
          },
        ],
        [
          {'mk': List.filled(2049, 'x').join()},
        ],
        [Map.fromEntries(List.generate(65, (i) => MapEntry('field$i', i)))],
        List.filled(10001, <String, Object?>{}),
      ]) {
        final failure = (await ProtocolMinimumConsumptionReportApi(
          client: _client(
            _ReportAdapter([_success(records)]),
            expandedLimits: true,
          ),
        ).load(ClientKind.order)).failureOrNull;
        expect(failure?.kind, FailureKind.protocol);
        expect(failure?.code, 'protocol.minimum_consumption_report_shape');
        expect(failure?.safeMessage, isNot(contains('private response')));
      }
    },
  );

  test('rejects nonfinite values and oversized direct row input safely', () {
    for (final value in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        () => MinimumConsumptionReportRow.fromWire({'m': value}),
        throwsFormatException,
      );
    }
    try {
      MinimumConsumptionReportRow.fromWire({
        'se': ['private response'],
      });
      fail('Expected a format rejection');
    } on FormatException catch (error) {
      expect(error.toString(), isNot(contains('private response')));
    }
  });

  test(
    'business rejection and invalid response codes remain typed and safe',
    () async {
      final adapter = _ReportAdapter([
        {'code': 2, 'msg': 'private response'},
        {'code': '2', 'msg': 'private response'},
        {'code': true, 'msg': 'private response'},
        {'code': 1.5, 'msg': 'private response'},
        {'code': 'invalid private response'},
        {'msg': 'private response'},
      ]);
      final api = ProtocolMinimumConsumptionReportApi(client: _client(adapter));
      for (var i = 0; i < 6; i++) {
        final failure = (await api.load(ClientKind.order)).failureOrNull!;
        expect(
          failure.kind,
          i < 2 ? FailureKind.business : FailureKind.protocol,
        );
        expect(failure.safeMessage, isNot(contains('private response')));
      }
    },
  );

  test(
    'transport and authentication failures remain typed with safe messages',
    () async {
      final adapter = _ReportAdapter([
        _TransportFailure(),
        {'code': 11, 'msg': 'private response'},
        'not-json private response',
      ]);
      final api = ProtocolMinimumConsumptionReportApi(client: _client(adapter));
      for (final kind in [
        FailureKind.network,
        FailureKind.authentication,
        FailureKind.protocol,
      ]) {
        final failure = (await api.load(ClientKind.order)).failureOrNull!;
        expect(failure.kind, kind);
        expect(failure.safeMessage, isNot(contains('private response')));
      }
    },
  );
}

Map<String, Object?> _success(Object? records, {Object code = 1}) => {
  'code': code,
  'data': {'records': records},
};

ProtocolClient _client(
  HttpClientAdapter adapter, {
  bool expandedLimits = false,
}) {
  var now = DateTime.utc(2026, 8, 31);
  return ProtocolClient(
    dio: Dio()..httpClientAdapter = adapter,
    config: ApiConfig(
      apiBase: Uri.parse('https://api.example.test/server'),
      onlineBase: Uri.parse('https://online.example.test/server'),
      websocketBase: Uri.parse('wss://socket.example.test/server'),
    ),
    credentialStore: _CredentialStore(),
    responseLimits: expandedLimits
        ? const ProtocolResponseLimits(
            maxRawResponseBytes: 16 * 1024 * 1024,
            maxNodes: 200000,
          )
        : const ProtocolResponseLimits(),
    requestGate: RequestGate(
      clock: () {
        now = now.add(const Duration(milliseconds: 101));
        return now;
      },
    ),
  );
}

final class _ReportAdapter implements HttpClientAdapter {
  _ReportAdapter(this.responses);
  final List<Object?> responses;
  final List<RequestOptions> requests = [];
  final List<bool> hadRequestStream = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    hadRequestStream.add(requestStream != null);
    if (requestStream != null) await requestStream.drain<void>();
    final response = responses.removeAt(0);
    if (response is _TransportFailure) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'private response',
      );
    }
    return ResponseBody.fromString(
      response is String ? response : jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _TransportFailure {}

final class _CredentialStore implements CredentialStore {
  @override
  Future<void> clearStk() async {}
  @override
  Future<void> clearStkIfMatches(String? expected) async {}
  @override
  Future<void> clearTk() async {}
  @override
  Future<void> clearTkIfMatches(String? expected) async {}
  @override
  Future<String?> readStk() async => null;
  @override
  Future<CredentialSnapshot> readSnapshot() async =>
      const CredentialSnapshot(tk: 'test-tk', stk: null);
  @override
  Future<String?> readTk() async => 'test-tk';
  @override
  Future<void> writeStk(String value) async {}
  @override
  Future<void> writeTk(String value) async {}
}
