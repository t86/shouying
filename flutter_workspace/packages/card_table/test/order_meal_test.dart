import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/order_meal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

void main() {
  test(
    'refund count is not capped below a valid remaining order quantity',
    () async {
      final adapter = _Adapter([
        {'code': 1},
      ]);
      final result = await ProtocolOrderMealApi(client: _client(adapter))
          .refundOrder(
            ClientKind.order,
            seatId: '100',
            orderId: '11',
            count: 10000,
            amount: '',
            remark: '理由',
            online: true,
          );
      expect(result.failureOrNull, isNull);
      expect((adapter.requests.single.data as Map)['back_cnt'], 10000);
    },
  );
  test(
    'refund code2 requests authorization without accepting a refund',
    () async {
      final adapter = _Adapter([
        {'code': 2, 'msg': 'private authorization details'},
      ]);
      final result = await ProtocolOrderMealApi(client: _client(adapter))
          .refundOrder(
            ClientKind.order,
            seatId: '100',
            orderId: '11',
            count: 1,
            amount: '',
            remark: '客人退单',
            online: false,
          );
      expect(result.failureOrNull?.code, orderRefundAuthorizationRequiredCode);
      expect(result.failureOrNull?.safeMessage, isNot(contains('private')));
      expect(adapter.requests.single.data, {
        'seat_id': 100,
        'order_id': 11,
        'back_cnt': 1,
        'back_amt': '',
        'back_remark': '客人退单',
        'auth_emp_code': '',
        'auth_emp_passwd': '',
        'pass_type': 1,
      });
    },
  );
  test('refund account and card authorization hash transient plaintext exactly once', () async {
    for (final passType in [1, 2]) {
      final adapter = _Adapter([
        {'code': 1},
      ]);
      final result = await ProtocolOrderMealApi(client: _client(adapter))
          .refundOrder(
            ClientKind.order,
            seatId: '100',
            orderId: '11',
            count: 4,
            amount: '150.25',
            remark: '客人退单',
            online: passType == 2,
            authEmpCode: passType == 1 ? '00012' : 'CARD123',
            authEmpPasswd: 'password',
            passType: passType,
          );
      expect(result.failureOrNull, isNull);
      expect(
        adapter.requests.single.uri.path,
        passType == 1 ? '/server/wo/back' : '/server/wo/ol_unpay_back',
      );
      expect(adapter.requests.single.data, {
        'seat_id': 100,
        'order_id': 11,
        'back_cnt': 4,
        'back_amt': '150.25',
        'back_remark': '客人退单',
        'auth_emp_code': passType == 1 ? '00012' : 'CARD123',
        'auth_emp_passwd': '5F4DCC3B5AA765D61D8327DEB882CF99',
        'pass_type': passType,
      });
    }
  });
  test(
    'refund invalid authorization or nonfinite amount never reaches network',
    () async {
      final adapter = _Adapter([]);
      final api = ProtocolOrderMealApi(client: _client(adapter));
      for (final input in [
        ('', '', 2, ''),
        ('00012', '', 1, ''),
        ('', 'secret', 1, ''),
        ('00012', 'secret', 3, ''),
        ('', '', 1, 'NaN'),
        ('', '', 1, '-1'),
      ]) {
        expect(
          (await api.refundOrder(
            ClientKind.order,
            seatId: '100',
            orderId: '11',
            count: 1,
            amount: input.$4,
            remark: '理由',
            online: false,
            authEmpCode: input.$1,
            authEmpPasswd: input.$2,
            passType: input.$3,
          )).failureOrNull,
          isNotNull,
        );
      }
      expect(adapter.requests, isEmpty);
    },
  );
  test(
    'amount visibility is server code1/code2 decision, with failures preserved',
    () async {
      for (final code in [1, 2, 0]) {
        final adapter = _Adapter([
          {'code': code, 'msg': 'private-body'},
        ]);
        final result = await ProtocolOrderMealApi(client: _client(adapter))
            .checkOrderAmounts(ClientKind.order, seatId: '100');
        expect(
          adapter.requests.single.uri.path,
          '/server/wo/chk_order_can_see',
        );
        expect(adapter.requests.single.data, {'seat_id': 100});
        if (code == 0) {
          expect(result.failureOrNull, isNotNull);
        } else {
          expect(result.valueOrNull, code == 1);
        }
      }
    },
  );
  test(
    'compensation amount survives an independently selected scheme price',
    () async {
      final adapter = _Adapter([
        {'code': 1},
      ]);
      final result = await ProtocolOrderMealApi(client: _client(adapter))
          .addProduct(
            ClientKind.order,
            seatId: '100',
            productId: '105',
            count: 1,
            price: '0.00',
            amount: '123.45',
          );
      expect(result.failureOrNull, isNull);
      expect(adapter.requests.single.data, {
        'seat_id': 100,
        'prd_id': 105,
        'prd_cnt': 1,
        'prd_price': '0.00',
        'auth_type': 0,
        'prd_amt': '123.45',
        'requirement': '',
      });
    },
  );
  test(
    'adds a regular product with numeric ids and empty optional amounts',
    () async {
      final adapter = _Adapter([
        {'code': 1, 'data': <String, Object?>{}},
      ]);
      final result = await ProtocolOrderMealApi(client: _client(adapter))
          .addProduct(
            ClientKind.order,
            seatId: '100',
            productId: '101',
            count: 2,
            price: '38',
          );
      expect(result.failureOrNull, isNull);
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.uri.path, '/server/wsc/add_prd');
      expect(adapter.requests.single.data, {
        'seat_id': 100,
        'prd_id': 101,
        'prd_cnt': 2,
        'prd_price': '38',
        'auth_type': 0,
        'prd_amt': '',
        'requirement': '',
      });
    },
  );

  test('reads cart count with numeric seat id', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': 3},
    ]);
    final count = (await ProtocolOrderMealApi(
      client: _client(adapter),
    ).cartCount(ClientKind.order, seatId: '100')).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/server/wsc/get_item_cnt');
    expect(adapter.requests.single.data, {'id': 100});
    expect(count, 3);
  });

  test('lists cart items with numeric seat id', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': [
          {'id': 9, 'pid': 101, 'pc': 2, 'pp': '38', 'pa': '76'},
        ],
      },
    ]);
    final rows = (await ProtocolOrderMealApi(
      client: _client(adapter),
    ).listItems(ClientKind.order, seatId: '100')).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/server/wsc/get_items');
    expect(adapter.requests.single.data, {'id': 100});
    expect(rows.single.id, '9');
    expect(rows.single.productId, '101');
    expect(rows.single.count, 2);
    expect(rows.single.unitPrice, '38');
    expect(rows.single.amount, '76');
  });

  test('changes cart quantity including delete as zero', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final api = ProtocolOrderMealApi(client: _client(adapter));
    await api.setCount(ClientKind.order, seatId: '100', itemId: '9', count: 3);
    await api.setCount(ClientKind.order, seatId: '100', itemId: '9', count: 0);
    expect(adapter.requests[0].uri.path, '/server/wsc/set_cnt');
    expect(adapter.requests[0].data, {'seat_id': 100, 'id': 9, 'cnt': 3});
    expect(adapter.requests[1].data, {'seat_id': 100, 'id': 9, 'cnt': 0});
  });

  test(
    'treats a rejected add as a business failure without leaking payload',
    () async {
      final failure =
          (await ProtocolOrderMealApi(
                client: _client(
                  _Adapter([
                    {'code': 2, 'msg': 'private seat 100'},
                  ]),
                ),
              ).addProduct(
                ClientKind.order,
                seatId: '100',
                productId: '101',
                count: 1,
                price: '38',
              ))
              .failureOrNull!;
      expect(failure.kind, FailureKind.business);
      expect(failure.safeMessage, isNot(contains('private')));
    },
  );

  test('binds current waiter with numeric seat id', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .bindWaiter(ClientKind.order, seatId: '100');
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wo/set_csm_waiter');
    expect(adapter.requests.single.data, {'seat_id': 100});
  });

  test('searches guests and binds with poll success', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'records': [
            {'p': '13800001111', 'n': '张三'},
          ],
        },
      },
      {
        'code': 1,
        'data': {'order_id': 88},
      },
      {
        'code': 1,
        'data': {'s': 5, 'm': 'ok'},
      },
    ]);
    final api = ProtocolOrderMealApi(client: _client(adapter));
    final hits = (await api.searchGuests(
      ClientKind.order,
      phone: '1111',
    )).valueOrNull!;
    expect(adapter.requests[0].uri.path, '/server/wo/get_cust_items_for_csm');
    expect(hits.single.phone, '13800001111');
    final bind = await api.bindGuest(
      ClientKind.order,
      seatId: '100',
      phone: '13800001111',
      pollInterval: Duration.zero,
    );
    expect(bind.failureOrNull, isNull);
    expect(adapter.requests[1].uri.path, '/server/wo/set_csm_cust');
    expect(adapter.requests[2].uri.path, '/server/wo/get_set_csm_cust_rst');
  });

  test('lists placed orders with seat and turnover', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'records': [
            {
              'id': 9,
              'pid': 101,
              'pc': 2,
              'pp': '38',
              'pa': '76',
              'ot': '12:00',
              'n': '莫吉托',
            },
          ],
        },
      },
    ]);
    final rows =
        (await ProtocolOrderMealApi(client: _client(adapter)).listOrders(
          ClientKind.order,
          seatId: '100',
          turnoverCount: 0,
        )).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/server/wo/list');
    expect(adapter.requests.single.data, {'seat_id': 100, 'turnover_cnt': 0});
    expect(rows.single.name, '莫吉托');
    expect(rows.single.count, 2);
  });

  test('places selected cart items with numeric ids', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .placeOrder(
          ClientKind.order,
          seatId: '100',
          cartItemIds: const ['9', '10'],
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wsc/order');
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'shopping_cart_ids': [9, 10],
    });
  });

  test(
    'treats place-order code 5 as paid-success without leaking payload',
    () async {
      final result = await ProtocolOrderMealApi(
        client: _client(
          _Adapter([
            {'code': 5, 'msg': 'private seat 100'},
          ]),
        ),
      ).placeOrder(ClientKind.order, seatId: '100', cartItemIds: const ['9']);
      expect(result.failureOrNull, isNull);
    },
  );

  test('rejects empty cart ids before posting', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .placeOrder(ClientKind.order, seatId: '100', cartItemIds: const []);
    expect(result.failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
  });

  test('adds a time-price drink with amount and no relate csm', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .addTimed(
          ClientKind.order,
          seatId: '100',
          productId: '201',
          count: 1,
          amount: '88',
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wsc/add_hl');
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'prd_id': 201,
      'prd_cnt': 1,
      'prd_amt': '88',
      'requirement': '',
      'relate_csm_id': 0,
    });
  });

  test('adds a fixed-price drink with empty amount', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .addTimed(
          ClientKind.order,
          seatId: '100',
          productId: '202',
          count: 1,
          amount: '',
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'prd_id': 202,
      'prd_cnt': 1,
      'prd_amt': '',
      'requirement': '',
      'relate_csm_id': 0,
    });
  });

  test('adds a set with required and optional group selections', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter)).addSet(
      ClientKind.order,
      seatId: '100',
      productId: '301',
      count: 1,
      priceFen: 8800,
      groupIds: const ['1', '2'],
      detailProductIds: const ['11', '12'],
      detailCounts: const [1, 1],
      selectCounts: const [1, 1],
      requirements: const ['', '少冰'],
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wsc/add_set');
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'prd_id': 301,
      'prd_cnt': 1,
      'prd_price': 8800,
      'grp_ids': [1, 2],
      'dtl_prd_ids': [11, 12],
      'dtl_prd_cnts': [1, 1],
      'sel_cnts': [1, 1],
      'requirements': ['', '少冰'],
      'auth_type': 0,
    });
  });

  test(
    'refunds an unpaid local order with remark and empty self auth',
    () async {
      final adapter = _Adapter([
        {'code': 1, 'data': <String, Object?>{}},
      ]);
      final result = await ProtocolOrderMealApi(client: _client(adapter))
          .refundOrder(
            ClientKind.order,
            seatId: '100',
            orderId: '9',
            count: 1,
            amount: '',
            remark: '客人不满意',
            online: false,
          );
      expect(result.failureOrNull, isNull);
      expect(adapter.requests.single.uri.path, '/server/wo/back');
      expect(adapter.requests.single.data, {
        'seat_id': 100,
        'order_id': 9,
        'back_cnt': 1,
        'back_amt': '',
        'back_remark': '客人不满意',
        'auth_emp_code': '',
        'auth_emp_passwd': '',
        'pass_type': 1,
      });
    },
  );

  test('refunds an unpaid online order without changing count', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .refundOrder(
          ClientKind.order,
          seatId: '100',
          orderId: '9',
          count: 1,
          amount: '',
          remark: '客人不满意',
          online: true,
        );
    expect(adapter.requests.single.uri.path, '/server/wo/ol_unpay_back');
    expect(result.failureOrNull, isNull);
  });

  test('rejects refund without a remark before posting', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .refundOrder(
          ClientKind.order,
          seatId: '100',
          orderId: '9',
          count: 1,
          amount: '',
          remark: '',
          online: false,
        );
    expect(result.failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
  });

  test('converts a cart line to discount with self authorization', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .convertCartToYh(
          ClientKind.order,
          seatId: '100',
          cartItemIds: const ['9'],
          counts: const [1],
          reason: '招待',
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wsc/to_yh');
    expect(adapter.requests.single.data, {
      'auth_emp_code': '',
      'auth_emp_passwd': '',
      'auth_reason': '招待',
      'seat_id': 100,
      'shopping_cart_ids': [9],
      'auth_cnts': [1],
      'pass_type': 1,
    });
  });

  test('adds a gifted product with auth_type 2', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .addProduct(
          ClientKind.order,
          seatId: '100',
          productId: '101',
          count: 1,
          price: '38',
          authType: 2,
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'prd_id': 101,
      'prd_cnt': 1,
      'prd_price': '38',
      'auth_type': 2,
      'prd_amt': '',
      'requirement': '',
    });
  });

  test('adds a discount product through add_yh with self auth', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter)).addYh(
      ClientKind.order,
      seatId: '100',
      productId: '101',
      count: 1,
      amount: '',
      price: '38.00',
      reason: '招待',
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wsc/add_prd');
    expect(adapter.requests.single.data, {
      'auth_emp_code': '',
      'auth_emp_passwd': '',
      'auth_reason': '招待',
      'seat_id': 100,
      'prd_id': 101,
      'prd_cnt': 1,
      'prd_amt': '',
      'requirement': '',
      'pass_type': 1,
      'prd_price': '38.00',
      'auth_type': 2,
    });
  });

  test('rejects add_yh without a reason before posting', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter)).addYh(
      ClientKind.order,
      seatId: '100',
      productId: '101',
      count: 1,
      amount: '',
      price: '38.00',
      reason: '',
    );
    expect(result.failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
  });

  test('adds yh2 to cart with sales employee and dest seat', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter)).addYh2(
      ClientKind.order,
      seatId: '100',
      productId: '101',
      count: 1,
      salesEmpId: '8',
      yh2SeatId: '200',
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wsc/add_yh2');
    expect(adapter.requests.single.data, {
      'auth_emp_code': '',
      'auth_emp_passwd': '',
      'auth_reason': '',
      'seat_id': 100,
      'prd_id': 101,
      'prd_cnt': 1,
      'requirement': '',
      'pass_type': 1,
      'yh2_sales_emp_id': 8,
      'yh2_seat_id': 200,
    });
  });

  test('adds a cart item requirement', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .addRequirement(
          ClientKind.order,
          seatId: '100',
          itemId: '9',
          requirement: '少冰;去糖',
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wsc/add_requirement');
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'id': 9,
      'requirement': '少冰;去糖',
    });
  });

  test('adds a set-item requirement', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .addSetRequirement(
          ClientKind.order,
          seatId: '100',
          itemId: '9',
          groupId: '2',
          detailProductId: '12',
          detailCount: 1,
          selectCount: 1,
          sourceRequirement: '',
          requirement: '少冰',
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wsc/add_set_requirement');
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'id': 9,
      'grp_id': 2,
      'dtl_prd_id': 12,
      'dtl_prd_cnts': 1,
      'sel_cnts': 1,
      'src_requirement': '',
      'requirement': '少冰',
    });
  });

  test('changes a cart set detail', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .changeSetDetail(
          ClientKind.order,
          seatId: '100',
          itemId: '9',
          groupId: '2',
          detailProductId: '12',
          destDetailProductIds: const ['13'],
          destSelectCounts: const [1],
          requirement: '',
          destRequirements: const [''],
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wsc/chg_set_dtl');
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'id': 9,
      'grp_ids': 2,
      'dtl_prd_ids': 12,
      'dest_dtl_prd_ids': [13],
      'dest_sel_cnts': [1],
      'requirement': '',
      'dest_requirements': [''],
    });
  });

  test('converts cart lines to yh2', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .convertCartToYh2(
          ClientKind.order,
          seatId: '100',
          cartItemIds: const ['9'],
          counts: const [1],
          salesEmpId: '8',
          yh2SeatId: '200',
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wsc/to_yh2');
    expect(adapter.requests.single.data, {
      'auth_emp_code': '',
      'auth_emp_passwd': '',
      'auth_reason': '',
      'seat_id': 100,
      'shopping_cart_ids': [9],
      'auth_cnts': [1],
      'pass_type': 1,
      'yh2_sales_emp_id': 8,
      'yh2_seat_id': 200,
    });
  });

  test('gifts an unpaid order line', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .giftOrdered(
          ClientKind.order,
          seatId: '100',
          orderIds: const ['9'],
          counts: const [1],
          reason: '招待',
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wo/yh_prd');
    expect(adapter.requests.single.data, {
      'auth_emp_code': '',
      'auth_emp_passwd': '',
      'auth_reason': '招待',
      'seat_id': 100,
      'order_ids': [9],
      'auth_cnts': [1],
      'pass_type': 1,
    });
  });

  test('changes an ordered set detail', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .changeOrderedSet(
          ClientKind.order,
          seatId: '100',
          orderId: '9',
          orderDetailId: '91',
          destDetailProductIds: const ['13'],
          destSelectCounts: const [1],
          destRequirements: const [''],
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wo/set_chg');
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'auth_emp_code': '',
      'auth_emp_passwd': '',
      'order_id': 9,
      'order_dtl_id': 91,
      'dest_dtl_prd_ids': [13],
      'dest_dtl_prd_sel_cnts': [1],
      'dest_requirements': [''],
      'pass_type': 1,
    });
  });

  test('converts ordered lines to yh2', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .convertOrderToYh2(
          ClientKind.order,
          seatId: '100',
          orderIds: const ['9'],
          counts: const [1],
          salesEmpId: '8',
          yh2SeatId: '200',
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wo/yh2_prd');
    expect(adapter.requests.single.data, {
      'auth_emp_code': '',
      'auth_emp_passwd': '',
      'auth_reason': '',
      'seat_id': 100,
      'order_ids': [9],
      'auth_cnts': [1],
      'pass_type': 1,
      'yh2_sales_emp_id': 8,
      'yh2_seat_id': 200,
    });
  });

  test('reprints a kitchen ticket by order id', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .reprintKitchen(ClientKind.order, orderId: '9');
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wo/reprt_cp');
    expect(adapter.requests.single.data, {'order_id': 9});
  });

  test('prints an unpaid consumption bill from my-order', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .printBill(
          ClientKind.order,
          seatId: '100',
          unpaid: true,
          includeHl: false,
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wo/prt_csm_bill');
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'total_type': 2,
      'include_hl': 2,
    });
  });

  test('reprints a consumption bill from cashier unpaid list', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .reprintBill(
          ClientKind.order,
          seatId: '100',
          turnoverCount: 1,
          unpaid: true,
          includeHl: true,
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/sel/sy_prt_csm_bill');
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'turnover_cnt': 1,
      'pay_id': 0,
      'range_type': 2,
      'include_hl': 1,
    });
  });

  test('cleans a seat', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .cleanSeat(ClientKind.order, seatId: '100');
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/sel/seat_clean');
    expect(adapter.requests.single.data, {'seat_id': 100});
  });

  test('merges yh2 orders onto another seat', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .mergeYh2(
          ClientKind.order,
          seatId: '100',
          orderIds: const ['9'],
          destSeatId: '200',
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/sel/move_order');
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'order_ids': [9],
      'dest_seat_id': 200,
    });
  });

  test('loads waiter unpaid orders then creates a pay qr', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'oos': [
            {
              'id': 1,
              'os': [
                {'id': 9, 'pid': 101, 'pc': 1, 'ot': '12:00'},
              ],
            },
          ],
        },
      },
      {
        'code': 1,
        'data': {'ol_pay_id': 88, 'pay_amt': 3800, 'pay_url': 'https://pay'},
      },
    ]);
    final api = ProtocolOrderMealApi(client: _client(adapter));
    final rows = (await api.waiterTodoOrders(
      ClientKind.order,
      seatId: '100',
    )).valueOrNull!;
    expect(
      adapter.requests.first.uri.path,
      '/server/wo/get_waiter_olpay_todo_orders',
    );
    expect(adapter.requests.first.data, {'seat_id': 100});
    expect(rows.single.id, '9');
    final qr = (await api.createWaiterPay(
      ClientKind.order,
      seatId: '100',
      payType: 1,
      orderIds: const ['9'],
    )).valueOrNull!;
    expect(
      adapter.requests.last.uri.path,
      '/server/wo/do_waiter_olpay_with_orders',
    );
    expect(adapter.requests.last.data, {
      'seat_id': 100,
      'pay_type': 1,
      'auth_code': '',
      'order_ids': [9],
    });
    expect(qr.payUrl, 'https://pay');
    expect(qr.payId, '88');
    expect(qr.amountFen, 3800);
  });

  test('redeems a coupon code on the current seat', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolOrderMealApi(client: _client(adapter))
        .redeemCoupon(ClientKind.order, authCode: 'ABC123');
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/sel/kq_csm_by_code');
    expect(adapter.requests.single.data, {
      'auth_code': 'ABC123',
      'relate_csm_id': 0,
    });
  });
}

ProtocolClient _client(_Adapter adapter) {
  var now = DateTime.utc(2026, 9, 9);
  return ProtocolClient(
    dio: Dio()..httpClientAdapter = adapter,
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

final class _Adapter implements HttpClientAdapter {
  _Adapter(this.responses);
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
    return ResponseBody.fromString(
      jsonEncode(responses.removeAt(0)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
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
