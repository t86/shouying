import 'package:card_table/card_table.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ERP Models Tests', () {
    test('ErpNegStoreAlert and ErpNegStoreMat parse and roundtrip toWire', () {
      final json = <String, Object?>{
        'id': 'st_1',
        'n': '主仓库',
        'ms': [
          {
            'id': 'm_1',
            'sn': '百威啤酒',
            'mn': '百威瓶装',
            'on': '酒水类',
            'tn': '啤酒',
            'un': '瓶',
            'c': -12.0,
            'b': 3.0,
          }
        ],
      };

      final alert = ErpNegStoreAlert.fromWire(json);
      expect(alert.id, 'st_1');
      expect(alert.storeName, '主仓库');
      expect(alert.materials.length, 1);
      expect(alert.materials.first.productName, '百威啤酒');
      expect(alert.materials.first.count, -12.0);

      final wire = alert.toWire();
      expect(wire['n'], '主仓库');
      final roundtrip = ErpNegStoreAlert.fromWire(wire);
      expect(roundtrip.materials.first.matName, '百威瓶装');
    });

    test('ErpStoreItem parses and toWire matches', () {
      final json = <String, Object?>{
        'id': 'wh_1',
        'code': 'WH001',
        'name': '总仓',
        'st': 1,
        'memo': '总仓备注',
      };

      final store = ErpStoreItem.fromWire(json);
      expect(store.id, 'wh_1');
      expect(store.code, 'WH001');
      expect(store.name, '总仓');
      expect(store.isValid, true);
      expect(store.memo, '总仓备注');

      final wire = store.toWire();
      expect(wire['st'], 1);
    });

    test('ErpMatCate and ErpMatItem parse and serialize', () {
      final cateJson = <String, Object?>{
        'id': 'c_1',
        'n': '酒水一级',
        'pid': '0',
        'sub': [
          {'id': 'c_1_1', 'n': '洋酒二级', 'pid': 'c_1'}
        ],
      };

      final cate = ErpMatCate.fromWire(cateJson);
      expect(cate.id, 'c_1');
      expect(cate.name, '酒水一级');
      expect(cate.children.length, 1);
      expect(cate.children.first.name, '洋酒二级');

      final matJson = <String, Object?>{
        'id': 'mat_101',
        'c': 'M101',
        'n': '黑方威士忌',
        'on': '酒水一级',
        'tn': '洋酒二级',
        'un': '瓶',
        'p': 180.5,
        'spec': '700ml',
        'st': 1,
      };

      final mat = ErpMatItem.fromWire(matJson);
      expect(mat.id, 'mat_101');
      expect(mat.code, 'M101');
      expect(mat.name, '黑方威士忌');
      expect(mat.price, 180.5);
      expect(mat.isValid, true);
    });

    test('ErpComparePrdItem and ErpSupplierItem parse correctly', () {
      final compareJson = <String, Object?>{
        'id': 'p_1',
        'pn': '黑方套餐',
        'on': '洋酒',
        'tn': '调和威士忌',
        'mat_id': 'm_1',
        'mn': '黑方原液',
        'is_close': 0,
      };

      final compare = ErpComparePrdItem.fromWire(compareJson);
      expect(compare.productName, '黑方套餐');
      expect(compare.matName, '黑方原液');
      expect(compare.isClosed, 0);

      final supplierJson = <String, Object?>{
        'id': 'sup_1',
        'code': 'SUP01',
        'name': '供应商A',
        'linkman': '张三',
        'tel': '13800138000',
        'address': '广东省深圳市',
        'st': 1,
      };

      final supplier = ErpSupplierItem.fromWire(supplierJson);
      expect(supplier.name, '供应商A');
      expect(supplier.linkman, '张三');
      expect(supplier.isValid, true);
    });

    test('ErpSinItem and ErpSindItem parse correctly with details', () {
      final sinJson = <String, Object?>{
        'id': 'sin_1',
        'code': 'RK20260915001',
        'sn': '一号仓库',
        'bill_day': '2026-09-15',
        'st': 1,
        'oper_name': '李四',
        'items': [
          {
            'id': 'dtl_1',
            'mat_id': 'm_1',
            'mn': '红牛',
            'un': '罐',
            'c': 24.0,
            'p': 5.0,
            'a': 120.0,
          }
        ],
      };

      final sin = ErpSinItem.fromWire(sinJson);
      expect(sin.code, 'RK20260915001');
      expect(sin.items.length, 1);
      expect(sin.items.first.matName, '红牛');
      expect(sin.items.first.amount, 120.0);

      final sindJson = <String, Object?>{
        'id': 'sind_1',
        'code': 'DB20260915001',
        'out_store_name': '总仓',
        'in_store_name': '吧台仓',
        'bill_day': '2026-09-15',
        'st': 3,
      };

      final sind = ErpSindItem.fromWire(sindJson);
      expect(sind.outStoreName, '总仓');
      expect(sind.inStoreName, '吧台仓');
      expect(sind.status, 3);
    });

    test('ErpEmptyInItem and ErpEmptyInvtItem handle empty bottle ops', () {
      final emptyInJson = <String, Object?>{
        'id': 'ei_1',
        'code': 'KP20260915',
        'day': '2026-09-15',
        'cnt': 50,
        'st': 1,
        'oper_name': '王五',
      };

      final emptyIn = ErpEmptyInItem.fromWire(emptyInJson);
      expect(emptyIn.count, 50);
      expect(emptyIn.status, 1);

      final emptyInvtJson = <String, Object?>{
        'id': 'invt_1',
        'n': '青岛啤酒空瓶',
        'c': 120,
      };

      final emptyInvt = ErpEmptyInvtItem.fromWire(emptyInvtJson);
      expect(emptyInvt.name, '青岛啤酒空瓶');
      expect(emptyInvt.count, 120);
      expect(emptyInvt.checked, false);

      final checkedCopy = emptyInvt.copyWith(checked: true);
      expect(checkedCopy.checked, true);
    });

    test('ErpPsiItem and ErpReportParams parse report data correctly', () {
      final psiJson = <String, Object?>{
        'id': 'psi_1',
        'sn': '一号仓库',
        'mn': '可口可乐',
        'un': '罐',
        'begin_c': 100.0,
        'in_c': 50.0,
        'out_c': 30.0,
        'end_c': 120.0,
        'end_a': 360.0,
      };

      final psi = ErpPsiItem.fromWire(psiJson);
      expect(psi.storeName, '一号仓库');
      expect(psi.beginCount, 100.0);
      expect(psi.endCount, 120.0);
      expect(psi.endAmount, 360.0);

      final paramJson = <String, Object?>{
        'stores': [
          {'id': 's1', 'n': '总仓'}
        ],
        'cates': [
          {'id': 'c1', 'n': '饮料'}
        ],
      };

      final params = ErpReportParams.fromWire(paramJson);
      expect(params.storeOptions.length, 1);
      expect(params.storeOptions.first['n'], '总仓');
      expect(params.cateOptions.length, 1);
    });
  });
}
