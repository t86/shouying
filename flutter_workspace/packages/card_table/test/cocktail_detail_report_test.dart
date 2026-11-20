import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/cocktail_detail_report.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

void main() {
  test('historical original and scheme amounts include independently rounded totals', () async {
    final adapter = _ReportAdapter([
      _success([
        {'a': '77.335', 'sa': '100.335'},
        {'a': '0', 'sa': '20'},
        {'a': '5.10'},
        {'a': '3', 'sa': ''},
        {'a': '2', 'sa': 'invalid'},
      ]),
    ]);
    final rows = (await ProtocolCocktailDetailReportApi(
      client: _client(adapter),
    ).load(ClientKind.order, keyword: '')).valueOrNull!;
    expect(rows.first.cells[13], '原价：100.34\n方案价：77.33');
    expect(rows[1].cells[13], '原价：20.00\n方案价：0.00');
    expect(rows[2].cells[13], '5.10');
    expect(rows.last.cells[13], '原价：130.44\n方案价：87.43');
  });
  test('uses the order keyword POST and selected client headers', () async {
    final adapter = _ReportAdapter([_success([]), _success([])]);
    final api = ProtocolCocktailDetailReportApi(client: _client(adapter));

    expect(
      (await api.load(ClientKind.order, keyword: '')).failureOrNull,
      isNull,
    );
    expect(
      (await api.load(ClientKind.order, keyword: ' 特饮A ')).failureOrNull,
      isNull,
    );
    expect(
      adapter.requests.map((request) => request.method),
      everyElement('POST'),
    );
    expect(
      adapter.requests.map((request) => request.uri.path),
      everyElement('/server/sel/rpt/get_hl_list_byord'),
    );
    expect(
      adapter.requests.map((request) => request.uri.query),
      everyElement(isEmpty),
    );
    expect(adapter.requests.map((request) => request.data), [
      {'key': ''},
      {'key': ' 特饮A '},
    ]);
    expect(adapter.requests.map((request) => request.headers['tt']), [
      '4',
      '4',
    ]);
    expect(
      adapter.requests.map((request) => request.headers['tk']),
      everyElement('test-tk'),
    );
  });

  test('preserves the twenty-one source columns and twenty wire fields', () {
    expect(CocktailDetailReportRow.columnLabels, [
      '序号',
      '区域',
      '卡台名称',
      '下单/补交时间',
      '结账时间',
      '点单人',
      '点单人部门',
      '点单人岗位',
      '授权人',
      '授权人部门',
      '授权人岗位',
      '商品一级分类',
      '商品二级分类',
      '商品名称',
      '点单金额',
      '订台人',
      '订位部门',
      '订位人岗位',
      '关联功能台',
      '补交营业日',
      '支付信息描述',
    ]);
    expect(CocktailDetailReportRow.wireFields, [
      'rn',
      's',
      'o',
      'pt',
      'w',
      'wd',
      'ws',
      'ae',
      'ad',
      'as',
      'on',
      'tn',
      'n',
      'a',
      'se',
      'sd',
      'ss',
      'bs',
      'bb',
      'p',
    ]);
    expect(CocktailDetailReportRow.scrollIndicator, '>>');
  });

  test(
    'keeps backend text and finite numbers and appends the order total row',
    () async {
      final adapter = _ReportAdapter([
        _success([
          {
            'rn': 'A 区',
            's': 'A01',
            'o': '19:30',
            'pt': '20:00',
            'w': '点单人',
            'wd': '一部',
            'ws': '服务员',
            'ae': '授权人',
            'ad': '授权部',
            'as': '主管',
            'on': '特饮',
            'tn': '鸡尾酒',
            'n': '莫吉托',
            'a': '10.5',
            'se': '订台人',
            'sd': '预订部',
            'ss': '咨客',
            'bs': '功能台',
            'bb': '20260831',
            'p': '微信',
          },
          {'a': 20},
        ], code: '1'),
      ]);
      final rows = (await ProtocolCocktailDetailReportApi(
        client: _client(adapter),
      ).load(ClientKind.order, keyword: '')).valueOrNull!;

      expect(rows, hasLength(3));
      expect(rows.first.cells, [
        'A 区',
        'A01',
        '19:30',
        '20:00',
        '点单人',
        '一部',
        '服务员',
        '授权人',
        '授权部',
        '主管',
        '特饮',
        '鸡尾酒',
        '莫吉托',
        '10.50',
        '订台人',
        '预订部',
        '咨客',
        '功能台',
        '20260831',
        '微信',
      ]);
      expect(rows[1].cells[13], '20.00');
      expect(rows.last.cells.first, '合计');
      expect(rows.last.cells[13], '30.50');
      expect(rows.first.toString(), isNot(contains('莫吉托')));
      expect(rows.first.toString(), isNot(contains('10.5')));
      expect(() => rows.clear(), throwsUnsupportedError);
      expect(() => rows.first.cells[0] = 'changed', throwsUnsupportedError);
    },
  );

  test('empty records still append a zero total row', () async {
    final adapter = _ReportAdapter([
      _success([]),
      {
        'code': 1,
        'data': {'records': null},
      },
      {'code': 1, 'data': <String, Object?>{}},
      {'code': 1},
      {'code': 1, 'data': null},
    ]);
    final api = ProtocolCocktailDetailReportApi(client: _client(adapter));
    for (var i = 0; i < 3; i++) {
      final rows = (await api.load(ClientKind.order, keyword: '')).valueOrNull!;
      expect(rows, hasLength(1));
      expect(rows.single.cells.first, '合计');
      expect(rows.single.cells[13], '0.00');
    }
    for (var i = 0; i < 2; i++) {
      expect(
        (await api.load(ClientKind.order, keyword: '')).failureOrNull?.kind,
        FailureKind.protocol,
      );
    }
  });

  test('row snapshots cannot be changed by mutating their source', () {
    final source = <String, Object?>{'rn': '原区域'};
    final row = CocktailDetailReportRow.fromWire(source);
    source['rn'] = 'changed';
    expect(row.cells.first, '原区域');
    expect(
      () => CocktailDetailReportRow.wireFields.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => CocktailDetailReportRow.columnLabels.clear(),
      throwsUnsupportedError,
    );
  });

  test('null and blank amounts count as zero in the order total', () async {
    final adapter = _ReportAdapter([
      _success([
        {'a': null},
        {'a': ''},
        {'a': 0},
      ]),
    ]);
    final rows = (await ProtocolCocktailDetailReportApi(
      client: _client(adapter),
    ).load(ClientKind.order, keyword: '')).valueOrNull!;
    expect(rows.last.cells[13], '0.00');
  });

  test(
    'rejects malformed rows and cells without exposing server values',
    () async {
      for (final records in <Object?>[
        'private response',
        {'rn': 'private response'},
        [null],
        [false],
        [
          {'a': 'not-a-number private response'},
        ],
        [
          {'n': true},
        ],
        [
          {
            'n': {'private': 'private response'},
          },
        ],
        [
          {'p': List.filled(2049, 'x').join()},
        ],
        [Map.fromEntries(List.generate(65, (i) => MapEntry('field$i', i)))],
        List.filled(10001, <String, Object?>{}),
      ]) {
        final failure = (await ProtocolCocktailDetailReportApi(
          client: _client(
            _ReportAdapter([_success(records)]),
            expandedLimits: true,
          ),
        ).load(ClientKind.order, keyword: '')).failureOrNull;
        expect(failure?.kind, FailureKind.protocol);
        expect(failure?.code, 'protocol.cocktail_detail_report_shape');
        expect(failure?.safeMessage, isNot(contains('private response')));
      }
    },
  );

  test('rejects nonfinite values and oversized keyword safely', () async {
    for (final value in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        () => CocktailDetailReportRow.fromWire({'a': value}),
        throwsFormatException,
      );
    }
    final failure =
        (await ProtocolCocktailDetailReportApi(
              client: _client(_ReportAdapter([])),
            ).load(ClientKind.order, keyword: List.filled(2049, 'x').join()))
            .failureOrNull;
    expect(failure?.kind, FailureKind.protocol);
    expect(failure?.safeMessage, isNot(contains('xxx')));
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
        {'code': 1},
        {'code': 1, 'data': null},
      ]);
      final api = ProtocolCocktailDetailReportApi(client: _client(adapter));
      for (var i = 0; i < 8; i++) {
        final failure = (await api.load(
          ClientKind.order,
          keyword: '',
        )).failureOrNull!;
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
      final api = ProtocolCocktailDetailReportApi(client: _client(adapter));
      for (final kind in [
        FailureKind.network,
        FailureKind.authentication,
        FailureKind.protocol,
      ]) {
        final failure = (await api.load(
          ClientKind.order,
          keyword: '',
        )).failureOrNull!;
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

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
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
