import 'package:card_table/src/erp_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import 'bms_staff_contract_test.dart' show Adapter, Credentials;

ProtocolErpApi erpApi(
  Adapter adapter, [
  ClientKind kind = ClientKind.erpAdmin,
]) => ProtocolErpApi(
  clientKind: kind,
  client: ProtocolClient(
    dio: Dio()..httpClientAdapter = adapter,
    config: ApiConfig(
      apiBase: Uri.parse('https://example.test/server'),
      onlineBase: Uri.parse('https://online.example.test'),
      websocketBase: Uri.parse('wss://example.test'),
    ),
    credentialStore: Credentials(),
    requestGate: RequestGate(clock: DateTime.now),
  ),
);

void main() {
  test('sin/sout submit exact parallel arrays with ERP client headers', () async {
    for (final outgoing in [false, true]) {
      final adapter = Adapter(); final api = erpApi(adapter, outgoing ? ClientKind.erp : ClientKind.erpAdmin);
      final payload = <String,Object?>{'store_id':2,'record_type':outgoing?17:7,'remark':'备注','mat_ids':[31],'cnts':[2],'amts':['100.00'],if(!outgoing)'supplier_id':'',if(!outgoing)'fapiao_type':2,if(!outgoing)'src_amts':['113.00']};
      final result = outgoing ? await api.createSoutOrder(payload) : await api.createSinOrder(payload);
      expect(result.failureOrNull,isNull);expect(adapter.requests.single.uri.path,outgoing?'/server/sout/new':'/server/sin/new');expect(adapter.requests.single.data,payload);expect(adapter.requests.single.headers['tt'],(outgoing?ClientKind.erp:ClientKind.erpAdmin).termType.toString());
    }
  });
  test('new entry options and warehouse-specific materials follow source endpoints', () async {
    final adapter = Adapter()
      ..data = {
        'stores': [
          {'id': 2, 'n': '一仓'},
        ],
        'suppliers': [
          {'id': 9, 'n': '供应商'},
        ],
      };
    final api = erpApi(adapter, ClientKind.erp);
    final options = await api.getSinOptions();
    expect(adapter.requests.last.uri.path, '/server/sin/new_sin_items');
    expect(adapter.requests.last.data, isNull);
    expect(options.valueOrNull!.stores.single.name, '一仓');
    expect(options.valueOrNull!.suppliers.single.name, '供应商');
    adapter.data = [
      {'id': 2, 'n': '一仓'},
    ];
    expect((await api.getSoutStores()).valueOrNull!.single.name, '一仓');
    expect(adapter.requests.last.uri.path, '/server/sout/store_items');
    expect(adapter.requests.last.data, isNull);
    adapter.data = [
      {
        'id': 31,
        'n': '真实物料',
        'moc': '酒水',
        'mtc': '啤酒',
        'un': '瓶',
        'c': '5',
        'a': '100',
      },
    ];
    final mats = await api.getStockMaterialItems(
      outgoing: true,
      keyword: '啤',
      storeId: '2',
    );
    expect(adapter.requests.last.uri.path, '/server/sout/mat_items');
    expect(adapter.requests.last.data, {
      'store_id': 2,
      'name': '啤',
      'page_num': 1,
      'page_size': 9999999,
    });
    expect(
      adapter.requests.last.headers['tt'],
      ClientKind.erp.termType.toString(),
    );
    expect(mats.valueOrNull!.single.stockCount, 5);
    expect(mats.valueOrNull!.single.unitName, '瓶');
    adapter.data = {'records': adapter.data};
    expect(
      (await api.getStockMaterialItems(
        outgoing: false,
        keyword: '啤',
      )).valueOrNull!.single.unitCost,
      20,
    );
    expect(adapter.requests.last.data, {
      'name': '啤',
      'page_num': 1,
      'page_size': 9999999,
    });
  });
  test('sin material search uses Vue name/paging and reads records', () async {
    final adapter = Adapter()
      ..data = {
        'records': [
          {
            'id': 31,
            'n': '真实物料',
            'moc': '酒水',
            'mtc': '啤酒',
            'un': '瓶',
            'c': 5,
            'a': 100,
          },
        ],
      };
    final result = await erpApi(adapter).getSinMatItems('啤');
    expect(adapter.requests.last.data, {
      'name': '啤',
      'page_num': 1,
      'page_size': 9999999,
    });
    expect(result.valueOrNull!.single.id, '31');
  });
  test('ERP business refusal is never a successful stock write', () async {
    final adapter = Adapter()
      ..code = 0
      ..msg = 'private-token';
    final result = await erpApi(adapter).createSinOrder({'store_id': 2});
    expect(result.failureOrNull, isNotNull);
    expect(result.failureOrNull!.safeMessage, isNot(contains('private-token')));
  });
  test('source compact list st is timestamp not numeric status', () async {
    final adapter = Adapter()
      ..data = {
        'datas': [
          {
            'id': 2,
            'cd': 'QT001',
            'sn': '一仓',
            'st': '2026-09-20',
            'en': '小王',
            'r': '备注',
          },
        ],
      };
    final result = await erpApi(adapter).getSinList();
    expect(result.valueOrNull!.single.code, 'QT001');
    expect(result.valueOrNull!.single.billDay, '2026-09-20');
  });
}
