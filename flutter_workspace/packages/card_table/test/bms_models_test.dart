import 'package:card_table/card_table.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BMS Models Tests', () {
    test('BmsGenRule parses correctly and roundtrips toWire', () {
      final json = <String, Object?>{
        'passwd_use_code': 2,
        'fixed_passwd': '123456',
        'code_length': 5,
      };
      final rule = BmsGenRule.fromWire(json);
      expect(rule.passwdUseCode, 2);
      expect(rule.fixedPasswd, '123456');
      expect(rule.codeLength, 5);

      final wire = rule.toWire();
      expect(wire, json);
    });

    test('BmsStationItem parses aliases and fallback fields', () {
      final json = <String, Object?>{
        'station_id': 'st_99',
        'station_name': '店长经理',
        'remark': '负责全场统筹',
        'status': 1,
        'is_waiter': 1,
        'is_cashier': 0,
        'waiter_regions': ['reg_1', 'reg_2'],
      };
      final station = BmsStationItem.fromWire(json);
      expect(station.id, 'st_99');
      expect(station.name, '店长经理');
      expect(station.desc, '负责全场统筹');
      expect(station.isValid, true);
      expect(station.isWaiter, true);
      expect(station.isCashier, false);
      expect(station.waiterRegions, ['reg_1', 'reg_2']);
    });

    test('BmsEmployeeItem parses with employee fields', () {
      final json = <String, Object?>{
        'emp_id': 'emp_101',
        'emp_name': '张三',
        'no': 'E1001',
        'mobile': '13800000000',
        'station_id': 'st_1',
        'station_name': '领班',
        'status': 1,
      };
      final emp = BmsEmployeeItem.fromWire(json);
      expect(emp.id, 'emp_101');
      expect(emp.name, '张三');
      expect(emp.empNo, 'E1001');
      expect(emp.phone, '13800000000');
      expect(emp.stationName, '领班');
      expect(emp.isValid, true);
    });

    test('BmsProductItem parses and converts toWire', () {
      final json = <String, Object?>{
        'prd_id': 'prd_01',
        'prd_name': '香槟',
        'prd_code': 'XB01',
        'price': 980.0,
        'vip_price': 880.0,
        'unit': '瓶',
        'status': 1,
        'is_package': 0,
      };
      final prd = BmsProductItem.fromWire(json);
      expect(prd.id, 'prd_01');
      expect(prd.name, '香槟');
      expect(prd.price, 980.0);
      expect(prd.vipPrice, 880.0);
      expect(prd.unit, '瓶');
      expect(prd.isPackage, false);
      expect(prd.isValid, true);
    });

    test('BmsCardItem parses seat fields', () {
      final json = <String, Object?>{
        'seat_id': 'seat_A01',
        'seat_name': 'A01',
        'region_id': 'reg_vip',
        'min_charge': 2000.0,
        'seat_num': 8,
        'status': 1,
      };
      final card = BmsCardItem.fromWire(json);
      expect(card.id, 'seat_A01');
      expect(card.name, 'A01');
      expect(card.minCharge, 2000.0);
      expect(card.seatNum, 8);
      expect(card.isValid, true);
    });

    test('BmsStoreInfo parses address and contact details', () {
      final json = <String, Object?>{
        'store_id': 'store_001',
        'store_name': '总店旗舰店',
        'tel': '0755-12345678',
        'province': '广东省',
        'city': '深圳市',
        'district': '南山区',
        'address': '科技园路1号',
      };
      final store = BmsStoreInfo.fromWire(json);
      expect(store.id, 'store_001');
      expect(store.name, '总店旗舰店');
      expect(store.phone, '0755-12345678');
      expect(store.city, '深圳市');
      expect(store.address, '科技园路1号');
    });

    test('BmsReasonItem parses 4-in-1 reasons correctly', () {
      final json = <String, Object?>{
        'rsn_id': 'r_01',
        'type': 'YH',
        'text': '熟客赠送',
      };
      final rsn = BmsReasonItem.fromWire(json);
      expect(rsn.id, 'r_01');
      expect(rsn.reasonType, 'YH');
      expect(rsn.reasonText, '熟客赠送');
    });

    test('BmsWineConfig and BmsCutPrdItem parse properly', () {
      final wineCfg = BmsWineConfig.fromWire(<String, Object?>{
        'default_expired_days': 45,
        'max_save_days': 120,
        'is_allow_borrow': 1,
        'is_sms_notify': 1,
      });
      expect(wineCfg.defaultExpiredDays, 45);
      expect(wineCfg.maxSaveDays, 120);
      expect(wineCfg.isAllowBorrow, true);

      final cut = BmsCutPrdItem.fromWire(<String, Object?>{
        'id': 'cut_1',
        'prd_id': 'prd_01',
        'prd_name': '轩尼诗VSOP',
        'cut_type': 1,
        'cut_value': 10.0,
      });
      expect(cut.prdName, '轩尼诗VSOP');
      expect(cut.cutType, 1);
      expect(cut.cutValue, 10.0);
    });
  });
}
