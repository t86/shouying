import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/card_table.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

void main() {
  test('booking confirm writes use Vue seat or book ids', () async {
    final adapter = _StubAdapter(<Map<String, Object?>>[
      for (var i = 0; i < 7; i++) <String, Object?>{'code': 1},
    ]);
    final api = ProtocolBookingCardApi(client: _client(adapter));
    expect(
      (await api.lock(ClientKind.booking, seatId: '101')).failureOrNull,
      isNull,
    );
    expect(
      (await api.unlock(ClientKind.booking, seatId: '101')).failureOrNull,
      isNull,
    );
    expect(
      (await api.cancelOpen(ClientKind.booking, seatId: '100')).failureOrNull,
      isNull,
    );
    expect(
      (await api.cancelReserve(ClientKind.booking, bookId: '88')).failureOrNull,
      isNull,
    );
    expect(
      (await api.pin(ClientKind.booking, seatId: '101')).failureOrNull,
      isNull,
    );
    expect(
      (await api.unpin(ClientKind.booking, seatId: '101')).failureOrNull,
      isNull,
    );
    expect(
      (await api.disableMustOrder(
        ClientKind.booking,
        seatId: '100',
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests.map((request) => request.uri.path), [
      '/server/bk/lock',
      '/server/bk/unlock',
      '/server/bk/cancel_open',
      '/server/bk/cancel',
      '/server/bk/top_seat_dsp',
      '/server/bk/cancel_top_seat_dsp',
      '/server/bk/disable_csm_must_ord',
    ]);
    expect(adapter.requests[0].data, {'id': 101});
    expect(adapter.requests[3].data, {'id': 88});
    expect(adapter.requests[6].data, {'id': 100});
  });

  test('booking form writes use Vue field payloads', () async {
    final adapter = _StubAdapter(<Map<String, Object?>>[
      for (var i = 0; i < 7; i++) <String, Object?>{'code': 1},
    ]);
    final api = ProtocolBookingCardApi(client: _client(adapter));
    expect(
      (await api.updateMinConsume(
        ClientKind.booking,
        seatId: '100',
        amount: 200,
      )).failureOrNull,
      isNull,
    );
    expect(
      (await api.updateSales(
        ClientKind.booking,
        seatId: '100',
        salesEmpId: '23',
        salesName: '大师兄',
        secondSalesEmpId: '34',
        secondSalesName: '沙师弟',
      )).failureOrNull,
      isNull,
    );
    expect(
      (await api.updateMark(
        ClientKind.booking,
        seatId: '100',
        mark: '抖',
      )).failureOrNull,
      isNull,
    );
    expect(
      (await api.updateRemark(
        ClientKind.booking,
        seatId: '100',
        remark: '转台测试',
      )).failureOrNull,
      isNull,
    );
    expect(
      (await api.updateWaiter(
        ClientKind.booking,
        seatId: '100',
        waiterEmpId: '45',
        turnoverCount: 2,
      )).failureOrNull,
      isNull,
    );
    expect(
      (await api.clearSeat(ClientKind.booking, seatId: '100')).failureOrNull,
      isNull,
    );
    expect(
      (await api.convertOffline(
        ClientKind.booking,
        seatId: '101',
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests.map((request) => request.uri.path), [
      '/server/bk/chg_csm_mca',
      '/server/bk/chg_sales',
      '/server/bk/set_seat_mark',
      '/server/bk/chg_open_seat_remark',
      '/server/sel/chg_csm_waiter',
      '/server/sel/seat_clean',
      '/server/bk/conv_ol_seat_local',
    ]);
    expect(adapter.requests[0].data, {'id': 100, 'min_csm_amt': '200'});
    expect(adapter.requests[1].data, {
      'id': 100,
      'sales_emp_id': 23,
      'sales_name': '大师兄',
      'second_sales_emp_id': 34,
      'second_sales_name': '沙师弟',
    });
    expect(adapter.requests[2].data, {'id': 100, 'mark': '抖'});
    expect(adapter.requests[3].data, {'id': 100, 'remark': '转台测试'});
    expect(adapter.requests[4].data, {
      'seat_id': 100,
      'waiter_emp_id': 45,
      'turnover_cnt': 2,
    });
    expect(adapter.requests[5].data, {'seat_id': 100});
    expect(adapter.requests[6].data, {'id': 101});
  });

  test(
    'booking confirm writes keep rejected messages without leaking ids',
    () async {
      final failure = (await ProtocolBookingCardApi(
        client: _client(
          _StubAdapter([
            {'code': 2, 'msg': 'private seat 101'},
          ]),
        ),
      ).lock(ClientKind.booking, seatId: '101')).failureOrNull!;
      expect(failure.kind, isNotNull);
      expect(failure.safeMessage, isNot(contains('101')));
    },
  );

  test(
    'booking write does not mask short numeric business errors like 0 or 1',
    () async {
      final failure = (await ProtocolBookingCardApi(
        client: _client(
          _StubAdapter([
            {'code': -20004, 'msg': '传入预订人数不在[1,999]范围内'},
          ]),
        ),
      ).openEmpty(
        ClientKind.booking,
        seatId: '101',
        fields: const {'customer_cnt': 0, 'min_csm_amt': 0},
      )).failureOrNull!;
      expect(failure.safeMessage, '传入预订人数不在[1,999]范围内');
    },
  );

  test('booking transfer writes use Vue chg seat payloads', () async {
    final adapter = _StubAdapter(<Map<String, Object?>>[
      for (var i = 0; i < 4; i++) <String, Object?>{'code': 1},
    ]);
    final api = ProtocolBookingCardApi(client: _client(adapter));
    expect(
      (await api.transferOpenSeat(
        ClientKind.booking,
        seatId: '100',
        destSeatId: '101',
        newMinConsumeAmount: 500,
      )).failureOrNull,
      isNull,
    );
    expect(
      (await api.transferReservedSeat(
        ClientKind.booking,
        bookId: '88',
        destSeatId: '102',
        newMinConsumeAmount: 300,
      )).failureOrNull,
      isNull,
    );
    expect(
      (await api.write(
        ClientKind.booking,
        action: BookingCardWriteAction.transferOpen,
        seatId: '100',
        fields: const {'dest_seat_id': '101', 'new_min_csm_amt': 600},
      )).failureOrNull,
      isNull,
    );
    expect(
      (await api.write(
        ClientKind.booking,
        action: BookingCardWriteAction.transferReserve,
        seatId: '100',
        bookId: '88',
        fields: const {'dest_seat_id': '102', 'new_min_csm_amt': 400},
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests.map((request) => request.uri.path), [
      '/server/bk/chg_csm_seat',
      '/server/bk/chg_seat',
      '/server/bk/chg_csm_seat',
      '/server/bk/chg_seat',
    ]);
    expect(adapter.requests[0].data, {
      'id': 100,
      'dest_seat_id': 101,
      'new_min_csm_amt': 500,
    });
    expect(adapter.requests[1].data, {
      'id': 88,
      'dest_seat_id': 102,
      'new_min_csm_amt': 300,
    });
    expect(adapter.requests[2].data, {
      'id': 100,
      'dest_seat_id': 101,
      'new_min_csm_amt': 600,
    });
    expect(adapter.requests[3].data, {
      'id': 88,
      'dest_seat_id': 102,
      'new_min_csm_amt': 400,
    });
  });

  test('booking open and reserve writes use Vue open and book payloads', () async {
    final adapter = _StubAdapter(<Map<String, Object?>>[
      for (var i = 0; i < 4; i++) <String, Object?>{'code': 1},
      {
        'code': 1,
        'data': {
          'customer_name': '张三',
          'customer_phone': '13800000000',
          'auto_send_msg': 2,
          'exp_arrive_time': '202608281200',
          'sales_emp_id': 23,
          'second_sales_emp_id': 0,
          'customer_exp_cnt': 6,
          'exp_min_csm_amt': 800,
          'remark': '窗边',
          'mark': '抖',
        },
      },
    ]);
    final api = ProtocolBookingCardApi(client: _client(adapter));
    expect(
      (await api.openEmpty(
        ClientKind.booking,
        seatId: '101',
        fields: const <String, Object?>{
          'customer_cnt': 4,
          'min_csm_amt': 0,
          'customer_phone': '',
          'customer_name': '',
        },
      )).failureOrNull,
      isNull,
    );
    expect(
      (await api.openReserve(
        ClientKind.booking,
        bookId: '88',
        fields: const <String, Object?>{
          'customer_cnt': 6,
          'min_csm_amt': 800,
          'old_sales_emp_id': '23',
        },
      )).failureOrNull,
      isNull,
    );
    expect(
      (await api.createReserve(
        ClientKind.booking,
        fields: const <String, Object?>{
          'is_this_wkday': 1,
          'book_day': '2026-08-28',
          'exp_seat_id': '101',
          'exp_seat_ids': <int>[101],
          'auto_send_msg': 2,
          'customer_exp_cnt': 4,
          'exp_min_csm_amt': 0,
        },
      )).failureOrNull,
      isNull,
    );
    expect(
      (await api.updateReserve(
        ClientKind.booking,
        bookId: '88',
        fields: const <String, Object?>{
          'is_this_wkday': 1,
          'book_day': '2026-08-28',
          'exp_seat_id': '101',
          'customer_name': '张三',
        },
      )).failureOrNull,
      isNull,
    );
    final detail = (await api.getBookDetail(
      ClientKind.booking,
      bookId: '88',
    )).valueOrNull!;
    expect(detail.customerName, '张三');
    expect(detail.salesEmpId, '23');
    expect(detail.customerExpCnt, 6);
    expect(adapter.requests.map((request) => request.uri.path), [
      '/server/bk/direct_open',
      '/server/bk/open',
      '/server/bk/batch_new',
      '/server/bk/save',
      '/server/bk/get',
    ]);
    expect(adapter.requests[0].data['seat_id'], 101);
    expect(adapter.requests[1].data['id'], 88);
    expect(adapter.requests[2].data['exp_seat_id'], 101);
    expect(adapter.requests[2].data['is_this_wkday'], 1);
    expect(adapter.requests[3].data['id'], 88);
    expect(adapter.requests[4].data, {'id': 88});
  });

  test('complete reservation detail survives an edit in the actual save body', () async {
    final fields = <String, Object?>{
      'customer_name': '详情客户', 'customer_phone': '13800000000',
      'is_this_wkday': 2, 'book_day': '2026-11-28',
      'auto_send_msg': 1, 'exp_arrive_time': '202611281930',
      'sales_emp_id': 23, 'second_sales_emp_id': 24,
      'customer_exp_cnt': 6, 'exp_min_csm_amt': 880.5,
      'exp_region_id': 7, 'exp_seat_id': 108, 'exp_seat_ids': [108, 109],
      'remark': '原备注', 'mark': 'VIP',
    };
    final adapter = _StubAdapter([
      {'code': 1, 'data': fields}, {'code': 1},
    ]);
    final api = ProtocolBookingCardApi(client: _client(adapter));
    final detail = (await api.getBookDetail(ClientKind.booking, bookId: '88')).valueOrNull!;
    expect(detail.reservationFields, fields);
    await api.updateReserve(ClientKind.booking, bookId: '88', fields: {
      ...detail.reservationFields!, 'remark': '修改备注',
    });
    expect(adapter.requests.last.data, {...fields, 'id': 88, 'remark': '修改备注'});
    for (final key in fields.keys) {
      final partial = Map<String, Object?>.of(fields)..remove(key);
      expect(BookingBookDetail.fromWire(partial).reservationFields, isNull,
          reason: 'missing $key must disable destructive editing');
    }
    for (final invalid in <Map<String, Object?>>[
      {'exp_seat_ids': ['not-an-id']}, {'is_this_wkday': 0},
      {'book_day': ''}, {'auto_send_msg': null}, {'exp_min_csm_amt': 'NaN'},
    ]) {
      expect(BookingBookDetail.fromWire({...fields, ...invalid}).reservationFields, isNull);
    }
  });

  test('turnover sales and turnback APIs call expected endpoints', () async {
    final adapter = _StubAdapter(<Map<String, Object?>>[
      <String, Object?>{
        'code': 1,
        'data': [
          <String, Object?>{
            'id': 1,
            'csm_id': 200,
            'sales_emp_id': 10,
            'sales_name': '销售A',
          },
        ],
      },
      <String, Object?>{'code': 1},
      <String, Object?>{
        'code': 1,
        'data': {
          'records': [
            <String, Object?>{'csm_id': 300, 'sales_name': '销售B'},
          ],
        },
      },
      <String, Object?>{'code': 1},
      <String, Object?>{
        'code': 1,
        'data': {
          't_a': '100',
          'd_a': '10',
          'w_p': '90',
          'd': [
            <String, Object?>{'p': '可乐', 'c': 2, 'm': '10', 's': '20'},
          ],
          'w': [
            <String, Object?>{'p': '轩尼诗', 'c': '1', 't': 1},
          ],
        },
      },
    ]);
    final api = ProtocolBookingCardApi(client: _client(adapter));

    final hisSales = await api.getHisSales(ClientKind.booking, seatId: '101');
    expect(hisSales.failureOrNull, isNull);
    expect(hisSales.valueOrNull?.length, 1);

    final chgSales = await api.chgHisSales(
      ClientKind.booking,
      seatId: '101',
      csmId: '200',
      salesEmpId: '10',
      reason: '测试理由',
    );
    expect(chgSales.failureOrNull, isNull);

    final turnbacks = await api.getSeatTurnbackList(
      ClientKind.booking,
      seatId: '101',
    );
    expect(turnbacks.failureOrNull, isNull);
    expect(turnbacks.valueOrNull?.length, 1);

    final doTurnback = await api.seatTurnBack(ClientKind.booking, csmId: '300');
    expect(doTurnback.failureOrNull, isNull);

    final orderDetail = await api.getOrderDetail(
      ClientKind.booking,
      seatId: '101',
      turnoverCount: 1,
    );
    expect(orderDetail.failureOrNull, isNull);
    expect(orderDetail.valueOrNull?.consumptionRows.length, 1);
    expect(orderDetail.valueOrNull?.wineRows.length, 1);

    expect(adapter.requests.map((r) => r.uri.path), [
      '/server/bk/get_his_sales',
      '/server/bk/chg_his_sales',
      '/server/sel/get_seat_turnback_list',
      '/server/sel/seat_turn_back',
      '/server/wo/list',
    ]);
  });

  test('reserved list and allocation APIs call expected endpoints', () async {
    final adapter = _StubAdapter(<Map<String, Object?>>[
      <String, Object?>{
        'code': 1,
        'data': [
          <String, Object?>{
            'id': 1001,
            'customer_name': '张三',
            'customer_phone': '13800000000',
          },
        ],
      },
      <String, Object?>{'code': 1},
      <String, Object?>{'code': 1},
      <String, Object?>{'code': 1},
    ]);
    final api = ProtocolBookingCardApi(client: _client(adapter));

    final reservedList = await api.getReservedList(
      ClientKind.booking,
      isToday: true,
    );
    expect(reservedList.failureOrNull, isNull);
    expect(reservedList.valueOrNull?.length, 1);
    expect(reservedList.valueOrNull?.first.customerName, '张三');

    final cancelRes = await api.cancelReservedInfo(
      ClientKind.booking,
      bookIds: ['1001'],
    );
    expect(cancelRes.failureOrNull, isNull);

    final singleAlloc = await api.singleAllocation(
      ClientKind.booking,
      id: '1001',
      seatId: '50',
    );
    expect(singleAlloc.failureOrNull, isNull);

    final manyAlloc = await api.manyAllocation(
      ClientKind.booking,
      bookIds: ['1001', '1002'],
    );
    expect(manyAlloc.failureOrNull, isNull);

    expect(adapter.requests.map((r) => r.uri.path), [
      '/server/sel/rpt/get_book_list',
      '/server/bk/cancel',
      '/server/bk/single_allocation',
      '/server/bk/many_allocation',
    ]);
  });

  test('parseBookingDateTime handles various date string formats', () {
    expect(
      parseBookingDateTime('2026-09-28 20:00:00'),
      DateTime(2026, 9, 28, 20, 0, 0),
    );
    expect(
      parseBookingDateTime('2026/09/28 19:30'),
      DateTime(2026, 9, 28, 19, 30),
    );
    expect(
      parseBookingDateTime('2026-09-28'),
      DateTime(2026, 9, 28),
    );
    expect(
      parseBookingDateTime('20260928200000'),
      DateTime(2026, 9, 28),
    );
    expect(parseBookingDateTime(''), isNull);
    expect(parseBookingDateTime('invalid-date'), isNull);
  });

  test('BookingReservedItem.fromWire extracts ResGetBookListItem fields correctly', () {
    final wire = <String, Object?>{
      'id': 2001,
      'b': '2026-09-28 20:00',
      'n': '王总',
      'p': '13800001111',
      'd': '营销一部',
      'e': '李四',
      'sn': 'V01',
      'rm': '需要冰块',
      'm': '优质',
      's': '预留',
      'c': '2026-09-28 10:00',
      'ma': '1000',
      'customer_exp_cnt': '5',
    };
    final item = BookingReservedItem.fromWire(wire, isToday: true);
    expect(item.id, '2001');
    expect(item.customerName, '王总');
    expect(item.customerPhone, '13800001111');
    expect(item.departmentName, '营销一部');
    expect(item.orderPersonName, '李四');
    expect(item.seatName, 'V01');
    expect(item.expArriveTime, '2026-09-28 20:00');
    expect(item.remark, '需要冰块');
    expect(item.minConsumeYuan, '1000');
    expect(item.customerCount, '5');
  });

  test('getReservedList filters items by today, tomorrow, 7 days, and all', () async {
    final mixedRecords = <Map<String, Object?>>[
      <String, Object?>{
        'id': 1,
        'customer_name': '今日客人1',
        'b': '2026-09-28 19:00',
      },
      <String, Object?>{
        'id': 2,
        'customer_name': '明天客人2',
        'b': '2026-09-29 20:00',
      },
      <String, Object?>{
        'id': 3,
        'customer_name': '4天后客人3',
        'b': '2026-10-02 21:00',
      },
      <String, Object?>{
        'id': 4,
        'customer_name': '12天后客人4',
        'b': '2026-10-10 18:00',
      },
      <String, Object?>{
        'id': 5,
        'customer_name': '无日期客人5',
      },
    ];

    final fixedNow = DateTime(2026, 9, 28, 12, 0, 0);

    // 1. isToday == true
    {
      final adapter = _StubAdapter(<Map<String, Object?>>[
        <String, Object?>{
          'code': 1,
          'data': {'records': mixedRecords},
        },
      ]);
      final api = ProtocolBookingCardApi(
        client: _client(adapter),
        nowProvider: () => fixedNow,
      );
      final res = await api.getReservedList(ClientKind.booking, isToday: true);
      expect(res.failureOrNull, isNull);
      final items = res.valueOrNull!;
      expect(items.map((i) => i.customerName).toList(), [
        '今日客人1',
        '无日期客人5',
      ]);
    }

    // 2. futureType == 1 (明天)
    {
      final adapter = _StubAdapter(<Map<String, Object?>>[
        <String, Object?>{
          'code': 1,
          'data': {'records': mixedRecords},
        },
      ]);
      final api = ProtocolBookingCardApi(
        client: _client(adapter),
        nowProvider: () => fixedNow,
      );
      final res = await api.getReservedList(
        ClientKind.booking,
        isToday: false,
        futureType: 1,
      );
      expect(res.failureOrNull, isNull);
      final items = res.valueOrNull!;
      expect(items.map((i) => i.customerName).toList(), ['明天客人2']);
    }

    // 3. futureType == 2 (未来7天)
    {
      final adapter = _StubAdapter(<Map<String, Object?>>[
        <String, Object?>{
          'code': 1,
          'data': {'records': mixedRecords},
        },
      ]);
      final api = ProtocolBookingCardApi(
        client: _client(adapter),
        nowProvider: () => fixedNow,
      );
      final res = await api.getReservedList(
        ClientKind.booking,
        isToday: false,
        futureType: 2,
      );
      expect(res.failureOrNull, isNull);
      final items = res.valueOrNull!;
      expect(items.map((i) => i.customerName).toList(), [
        '明天客人2',
        '4天后客人3',
      ]);
    }

    // 4. futureType == 3 (全部其它)
    {
      final adapter = _StubAdapter(<Map<String, Object?>>[
        <String, Object?>{
          'code': 1,
          'data': {'records': mixedRecords},
        },
      ]);
      final api = ProtocolBookingCardApi(
        client: _client(adapter),
        nowProvider: () => fixedNow,
      );
      final res = await api.getReservedList(
        ClientKind.booking,
        isToday: false,
        futureType: 3,
      );
      expect(res.failureOrNull, isNull);
      final items = res.valueOrNull!;
      expect(items.map((i) => i.customerName).toList(), [
        '明天客人2',
        '4天后客人3',
        '12天后客人4',
      ]);
    }
  });

  test('getReservedList falls back to bk endpoints if report fails', () async {
    final fixedNow = DateTime(2026, 9, 28, 12, 0, 0);
    final adapter = _StubAdapter(<Map<String, Object?>>[
      <String, Object?>{'code': 0, 'msg': 'report failed'},
      <String, Object?>{
        'code': 1,
        'data': [
          <String, Object?>{
            'id': 99,
            'customer_name': '降级明天条目',
            'exp_arrive_time': '2026-09-29 18:00',
          },
        ],
      },
    ]);
    final api = ProtocolBookingCardApi(
      client: _client(adapter),
      nowProvider: () => fixedNow,
    );
    final res = await api.getReservedList(
      ClientKind.booking,
      isToday: false,
      futureType: 1,
    );
    expect(res.failureOrNull, isNull);
    expect(res.valueOrNull?.length, 1);
    expect(res.valueOrNull?.first.customerName, '降级明天条目');
    expect(adapter.requests.map((r) => r.uri.path), [
      '/server/sel/rpt/get_book_list',
      '/server/bk/get_future_day_list',
    ]);
    expect(adapter.requests[1].data, {'ti': 1});
  });
}

ProtocolClient _client(HttpClientAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  var now = DateTime.utc(2026, 9, 10);
  return ProtocolClient(
    dio: dio,
    config: ApiConfig(
      apiBase: Uri.parse('https://api.example.test/server'),
      onlineBase: Uri.parse('https://online.example.test/server'),
      websocketBase: Uri.parse('wss://socket.example.test/server'),
    ),
    credentialStore: _CredentialStore(),
    requestGate: RequestGate(
      clock: () {
        now = now.add(const Duration(milliseconds: 101));
        return now;
      },
    ),
  );
}

final class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.responses);

  final List<Map<String, Object?>> responses;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) await requestStream.drain<void>();
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(responses.removeAt(0)),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

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
