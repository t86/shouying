import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_models.dart';
import 'package:card_table/src/bms_staff_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  testWidgets('failed code rule load cannot overwrite with defaults', (
    tester,
  ) async {
    final loader = StaffLoader()..failLoad = true;
    await tester.pumpWidget(
      MaterialApp(home: BmsCodeRulesView(loader: loader)),
    );
    await tester.pumpAndSettle();
    expect(find.text('加载失败'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const Key('bms-code-rules-save-btn')),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets(
    'onboarding editor retains fields on rejection and saves exact form',
    (tester) async {
      final loader = StaffLoader()..fail = true;
      await tester.pumpWidget(
        MaterialApp(home: BmsOnboardingApprovalView(loader: loader)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      expect(find.text('经理岗位'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, '姓名'), '新姓名');
      await tester.enterText(find.widgetWithText(TextField, '搜索直属上级'), '经理');
      await tester.tap(find.text('搜索上级'));
      await tester.pumpAndSettle();
      expect(loader.upperQuery, '经理');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(loader.saved, {
        'id': '9',
        'name': '新姓名',
        'dept_id': 3,
        'station_id': 4,
        'sex': 2,
        'upper_emp_id': 5,
        'real_name': '真名',
      });
      expect(find.text('操作失败'), findsOneWidget);
      expect(find.text('编辑入职申请'), findsOneWidget);
      loader.fail = false;
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('编辑入职申请'), findsNothing);
      await tester.pump(const Duration(milliseconds: 400));
    },
  );
  testWidgets('employee selected reset reports the failure and selected ids', (
    tester,
  ) async {
    final loader = StaffLoader()..fail = true;
    await tester.pumpWidget(
      MaterialApp(home: BmsEmployeeListView(loader: loader)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bms-emp-item-12')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bms-emp-batch-reset-pwd-btn')));
    await tester.pumpAndSettle();
    expect(loader.resetIds, ['12']);
    expect(find.textContaining('操作失败'), findsOneWidget);
  });
  testWidgets('code rules edit validates and sends source fields', (
    tester,
  ) async {
    final loader = StaffLoader();
    await tester.pumpWidget(
      MaterialApp(home: BmsCodeRulesView(loader: loader)),
    );
    await tester.pumpAndSettle();
    expect(find.text('工号前缀'), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, '工号位数'), '9');
    await tester.tap(find.text('保存规则'));
    await tester.pumpAndSettle();
    expect(find.text('工号位数范围为2-8'), findsOneWidget);
    expect(loader.saved, isNull);
    await tester.enterText(find.widgetWithText(TextField, '工号位数'), '8');
    await tester.tap(find.text('保存规则'));
    await tester.pumpAndSettle();
    expect(loader.saved, {
      'passwd_use_code': 2,
      'fixed_passwd': '123456',
      'code_length': 8,
    });
  });
  testWidgets('onboarding selects batch, confirms and keeps failure visible', (
    tester,
  ) async {
    final loader = StaffLoader()..fail = true;
    await tester.pumpWidget(
      MaterialApp(home: BmsOnboardingApprovalView(loader: loader)),
    );
    await tester.pumpAndSettle();
    expect(find.text('批量通过'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bms-onboarding-item-9')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('批量通过'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(loader.audited, ['9']);
    expect(find.textContaining('操作失败'), findsWidgets);
    await tester.tap(find.text('已通过'));
    await tester.pumpAndSettle();
    expect(loader.status, 5);
    expect(find.text('批量通过'), findsNothing);
  });
  testWidgets('business has candidate selection and actual batch add/remove', (
    tester,
  ) async {
    final loader = StaffLoader();
    await tester.pumpWidget(
      MaterialApp(home: BmsBusinessEmpView(loader: loader)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('查询待选员工'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bms-business-candidate-12')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加选中'));
    await tester.pumpAndSettle();
    expect(loader.added, ['12']);
    await tester.tap(find.byKey(const Key('bms-business-remove-7')));
    await tester.pumpAndSettle();
    expect(loader.removed, '7');
  });
}

class StaffLoader implements BmsLoader {
  String? upperQuery;
  @override
  Future<Result<List<BmsEmployeeItem>>> loadUpperEmployees(String name) async {
    upperQuery = name;
    return const Success([BmsEmployeeItem(id: '5', name: '经理')]);
  }

  Map<String, Object?>? saved;
  List<String>? audited, added, resetIds;
  String? removed;
  bool fail = false, failLoad = false;
  int status = 1;
  Result<void> get result => fail
      ? const FailureResult(
          AppFailure(
            kind: FailureKind.business,
            code: 'test',
            safeMessage: '操作失败',
          ),
        )
      : const Success(null);
  @override
  Future<Result<BmsGenRule>> loadGenRule() async => failLoad
      ? const FailureResult(
          AppFailure(
            kind: FailureKind.network,
            code: 'test',
            safeMessage: '加载失败',
          ),
        )
      : const Success(BmsGenRule(passwdUseCode: 2, fixedPasswd: '123456'));
  @override
  Future<Result<void>> saveGenRule(Map<String, Object?> fields) async {
    saved = fields;
    return result;
  }

  @override
  Future<Result<BmsOnboardingPage>> loadOnboardingPage({
    int status = 1,
    int page = 1,
    int pageSize = 20,
  }) async {
    this.status = status;
    return const Success(
      BmsOnboardingPage(
        items: [
          BmsOnboardingApprovalItem(
            id: '9',
            name: '小张',
            deptId: '3',
            stationId: '4',
            upperEmpId: '5',
            sex: 2,
            realName: '真名',
          ),
        ],
        total: 1,
      ),
    );
  }

  @override
  Future<Result<void>> auditOnboardingBatch(List<String> ids, bool pass) async {
    audited = ids;
    return result;
  }

  @override
  Future<Result<List<BmsDepartmentOption>>> loadDepartments() async =>
      const Success([BmsDepartmentOption('3', '部门')]);
  @override
  Future<Result<List<BmsStationItem>>> loadStations({
    String keyword = '',
  }) async => Success([
    BmsStationItem.fromWire({'id': 4, 'n': '经理岗位'}),
  ]);
  @override
  Future<Result<void>> saveOnboarding(Map<String, Object?> fields) async {
    saved = fields;
    return result;
  }

  @override
  Future<Result<List<BmsEmployeeItem>>> loadEmployees({
    String keyword = '',
    String stationId = '',
  }) async => const Success([BmsEmployeeItem(id: '12', name: '小王')]);
  @override
  Future<Result<void>> batchResetEmpPwd(List<String> ids) async {
    resetIds = ids;
    return result;
  }

  @override
  Future<Result<List<BmsBusinessEmpItem>>> loadBusinessEmployees({
    String keyword = '',
    List<String> deptIds = const [],
  }) async => const Success([BmsBusinessEmpItem(id: '7', name: '小李')]);
  @override
  Future<Result<List<BmsEmployeeItem>>> loadBusinessCandidates({
    String keyword = '',
    List<String> deptIds = const [],
  }) async => const Success([BmsEmployeeItem(id: '12', name: '小王')]);
  @override
  Future<Result<void>> addBusinessEmployees(List<String> ids) async {
    added = ids;
    return result;
  }

  @override
  Future<Result<void>> setBusinessEmp(String id, bool isBusiness) async {
    removed = id;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
