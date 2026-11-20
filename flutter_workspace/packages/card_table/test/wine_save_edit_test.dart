import 'package:card_table/src/wine_save_edit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

import 'live_order_operation_scope_test.dart' as fixture show event;

void main() {
  test('employee candidates retain all source supplied statuses 1 2 3', () {
    final store=WineSaveEditMetadata()..start()..setPhase(ConnectionPhase.online);
    final data=List<Object?>.filled(25,null);
    data[5]=[for(final status in [1,2,3]) [status,'员工$status',status,1,1,1,'','YG','$status']];
    data[24]=[];
    store.add(fixture.event(data));
    expect(store.snapshot.employees.map((e)=>e.id),[1,2,3]);
  });
  test('known empty date metadata follows source today fallback; malformed does not', () {
    final store = WineSaveEditMetadata()
      ..start()
      ..setPhase(ConnectionPhase.online);
    final data = List<Object?>.filled(25, null)
      ..[5] = []
      ..[24] = [];
    store.add(fixture.event(data));
    expect(store.snapshot.known, true);
    final today = DateTime.now();
    expect(
      DateTime.parse(store.snapshot.businessDates.first),
      DateTime(today.year, today.month, today.day),
    );
    store.add(
      fixture.event({
        '24': [
          ['bad', '20260231'],
        ],
      }),
    );
    expect(store.snapshot.known, false);
    store.add(fixture.event({'24': []}));
    expect(store.snapshot.known, false);
  });
  test('business metadata 5/24 independently tracks full delta invalidation and offline', () {
    final store = WineSaveEditMetadata()
      ..start()
      ..setPhase(ConnectionPhase.online);
    expect(store.snapshot.known, false);
    final data = List<Object?>.filled(25, null);
    data[5] = [
      [7, '员工', 1, 1, 1, 1, '', 'YG', '007'],
    ];
    data[24] = [
      ['今天', '20260920'],
    ];
    store.add(fixture.event(data));
    expect(store.snapshot.known, true);
    expect(store.snapshot.employees.single.id, 7);
    expect(store.snapshot.businessDates.first, '2026-09-20');
    expect(store.snapshot.businessDates.last, '2026-09-14');
    store.setPhase(ConnectionPhase.reconciling);
    expect(store.snapshot.known, false);
    store.add(
      fixture.event({
        '5': [
          [7, '员工', 3, 1, 1, 1, '', 'YG', '007'],
        ],
      }),
    );
    store.setPhase(ConnectionPhase.online);
      expect(store.snapshot.employees.single.id, 7);
    store.add(fixture.event({'5': 'bad'}));
    store.add(fixture.event({'5': []}));
    expect(store.snapshot.known, false);
    store.add(fixture.event(data));
    expect(store.snapshot.known, true);
    store.reset();
    expect(store.snapshot.known, false);
  });
  test('source save body retains all arrays and mode specific identity without invented auth', () {
    final record = WineSaveEditRecord.fromWire({
      'o': 71,
      'm': 81,
      'si': 91,
      's': 'A1',
      'd': '2026-09-20',
      'c': '客人',
      'p': '13800000000',
      't': '2026/09/20 12:00:00',
      'r': '备注',
      'ss': [
        {
          'id': 101,
          'p': 201,
          'n': '酒',
          'u': '整瓶',
          'g': 0,
          'c': 2,
          'ed': 0,
          'ce': 30,
          'a': '-',
          'ac': 2,
        },
      ],
    });
    final body = record.body(
      lines: record.lines,
      linked: true,
      csmId: 81,
      seatId: 91,
      salesEmployeeId: 7,
      customerName: record.customerName,
      phone: record.phone,
      remark: record.remark,
      storeTime: record.storeTime,
    );
    expect(body, {
      'bef_in_id': 71,
      'mode_type': 1,
      'bef_in_dtl_ids': [101],
      'unit_types': ['1'],
      'prd_cnts': [2],
      'expired_days': [30],
      'g_cnts': [0],
      'prd_ids': [201],
      'csm_id': 81,
      'seat_id': 0,
      'sales_emp_id': 0,
      'cust_name': '客人',
      'cust_phone': '13800000000',
      'remark': '备注',
      'store_time': '2026/09/20 12:00:00',
    });
    expect(
      record.body(
        lines: record.lines,
        linked: false,
        csmId: 81,
        seatId: 91,
        salesEmployeeId: 0,
        customerName: record.customerName,
        phone: record.phone,
        remark: '',
        storeTime: record.storeTime,
      )['csm_id'],
      0,
    );
  });
}
