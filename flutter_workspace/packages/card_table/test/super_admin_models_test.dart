import 'package:card_table/src/super_admin_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('S9 SuperAdmin Models Tests', () {
    test(
      'recursive departments preserve descendant IDs and optional child lists',
      () {
        final data = SmgrInitData.fromWire({
          'depts': [
            {
              'id': '10',
              'n': '总部',
              'subs': [
                {
                  'id': 20,
                  'n': '门店',
                  'subs': [
                    {'id': '30', 'n': '夜班'},
                  ],
                },
              ],
            },
          ],
        });
        final child = data.departments.single.children.single.children.single;
        expect(child.id, 30);
        expect(child.children, isEmpty);
        expect(data.stationRows, isEmpty);
        expect(
          SmgrDeptItem.fromWire(data.departments.single.toWire())
              .children
              .single
              .id,
          20,
        );
      },
    );
    test('SmgrDeptItem and SmgrStationItem parse and serialize', () {
      final deptMap = {
        'id': 10,
        'n': '总经办',
        'subs': [
          {'id': 11, 'n': '财务部', 'subs': []},
          {'id': 12, 'n': '营运部', 'subs': []},
        ],
      };
      final dept = SmgrDeptItem.fromWire(deptMap);
      expect(dept.id, 10);
      expect(dept.name, '总经办');
      expect(dept.children.length, 2);
      expect(dept.children[0].name, '财务部');
      expect(dept.toWire()['n'], '总经办');

      final station = SmgrStationItem.fromWire({'id': 101, 'n': '店长'});
      expect(station.id, 101);
      expect(station.name, '店长');
      expect(station.toWire()['n'], '店长');
    });

    test('SmgrEmpItem parses and toWire roundtrips', () {
      final map = {'id': 201, 'c': 'EMP001', 'n': '李四', 'd': '吧台部', 's': '有效'};
      final emp = SmgrEmpItem.fromWire(map);
      expect(emp.id, 201);
      expect(emp.code, 'EMP001');
      expect(emp.name, '李四');
      expect(emp.deptName, '吧台部');
      expect(emp.status, '有效');
      expect(emp.toWire()['c'], 'EMP001');
    });

    test(
      'SmgrStationRow parses nested employees and copyWith behaves correctly',
      () {
        final rowMap = {
          'id': 301,
          'n': '收银组长',
          'c': 2,
          's': '有效',
          'a': 1,
          'show': false,
          'es': [
            {'id': 1, 'c': '001', 'n': '张三', 'd': '收银部', 's': '有效'},
            {'id': 2, 'c': '002', 'n': '王五', 'd': '收银部', 's': '无效'},
          ],
        };
        final row = SmgrStationRow.fromWire(rowMap);
        expect(row.id, 301);
        expect(row.name, '收银组长');
        expect(row.empCount, 2);
        expect(row.isAdmin, true);
        expect(row.isExpanded, false);
        expect(row.employees.length, 2);

        final expanded = row.copyWith(isExpanded: true);
        expect(expanded.isExpanded, true);
        expect(expanded.name, '收银组长');
        expect(expanded.toWire()['show'], true);
      },
    );

    test('SmgrInitData parses full structure', () {
      final initMap = {
        'depts': [
          {'id': 1, 'n': '管理中心', 'subs': []},
        ],
        'stations': [
          {'id': 10, 'n': '管理员'},
        ],
        'station_emps': [
          {
            'id': 10,
            'n': '管理员',
            'c': 1,
            's': '有效',
            'a': 1,
            'es': [
              {'id': 1, 'c': '999', 'n': '超级账号', 'd': '管理中心', 's': '有效'},
            ],
          },
        ],
      };
      final data = SmgrInitData.fromWire(initMap);
      expect(data.departments.length, 1);
      expect(data.stations.length, 1);
      expect(data.stationRows.length, 1);
      expect(data.stationRows[0].employees.first.name, '超级账号');
    });

    test('SuperAdminLoginResult and TerminalRegisterResult parse cleanly', () {
      final login = SuperAdminLoginResult.fromWire({
        'data': 'token-super-admin-xyz',
        'emp_id': 2,
        'client': 'appinfo',
      });
      expect(login.token, 'token-super-admin-xyz');
      expect(login.empId, 2);
      expect(login.client, 'appinfo');

      final reg = TerminalRegisterResult.fromWire({
        'auth_mode': 1,
        'msg': '授权成功',
      });
      expect(reg.authMode, 1);
      expect(reg.message, '授权成功');
    });
  });
}
