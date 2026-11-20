import 'dart:async';

import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_report_configuration.dart';
import 'package:card_table/src/bms_statistics_configuration_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

class Loader implements BmsLoader, BmsReportConfigurationLoader {
  @override
  Object? configurationContext = Object();
  bool fail = false;
  bool productMode = false, badOwner = false;
  Completer<void>? preflight;
  final requests = <BmsReportConfigurationRequest>[];
  @override
  Future<Result<Map<String, Object?>>> requestReportConfiguration(
    BmsReportConfigurationRequest request,
  ) async {
    request
        .body; // Validate the same closed request contract used by production.
    requests.add(request);
    switch (request.operation) {
      case BmsReportConfigurationOperation.statistics:
        return Success({
          'records': [
            {
              'id': 1,
              'n': '统计甲',
              'b': 3,
              't': productMode ? 1 : 2,
              'tn': '分类',
              'ct': '酒水',
              'c': '创建',
              'u': '更新',
            },
            {'id': 2, 'n': '统计乙', 'b': 1, 't': 2, 'tn': '分类', 'ct': '其他'},
          ],
        });
      case BmsReportConfigurationOperation.channels:
        return const Success({
          'records': [
            {'id': 1, 'n': '现金类', 'cs': '现金', 'c': '创建', 'u': '更新'},
          ],
        });
      case BmsReportConfigurationOperation.channelItems:
        if (preflight != null) await preflight!.future;
        if (badOwner) {
          return const Success({
            'records': [
              {'id': 13, 'n': '扫码'},
            ],
          });
        }
        return const Success({
          'records': [
            {'id': 11, 'n': '现金', 'ci': 1, 'cn': '现金类'},
            {'id': 12, 'n': '卡', 'ci': 2, 'cn': '其他类'},
            {'id': 13, 'n': '扫码', 'ci': 0, 'cn': ''},
          ],
        });
      case BmsReportConfigurationOperation.statisticCategoryItems:
        return const Success({
          'cates': [
            {
              'id': 10,
              'n': '一级',
              'ss': [
                {'id': 11, 'n': '酒水', 'ji': 1, 'jc': '统计甲'},
                {'id': 12, 'n': '其他', 'ji': 2, 'jc': '统计乙'},
                {'id': 13, 'n': '新分类', 'ji': 0, 'jc': ''},
              ],
            },
          ],
        });
      case BmsReportConfigurationOperation.statisticProducts:
      case BmsReportConfigurationOperation.statisticProductItems:
        return Success({
          'cates': [
            {
              'id': 10,
              'n': '一级',
              'ss': [
                {'id': 11, 'n': '二级'},
              ],
            },
          ],
          'prds':
              request.operation ==
                  BmsReportConfigurationOperation.statisticProducts
              ? [
                  {
                    'id': 31,
                    'n': '已关联酒',
                    'oc': 10,
                    'tc': 11,
                    't': '普通商品',
                    'b': '主营',
                  },
                ]
              : [
                  {
                    'id': 32,
                    'n': '可添加酒',
                    'ji': 0,
                    'oi': 10,
                    'ti': 11,
                    't': '套餐',
                    'b': '非主营',
                  },
                  {
                    'id': 33,
                    'n': '他组酒',
                    'ji': 2,
                    'jc': '其他组',
                    'oi': 10,
                    'ti': 11,
                  },
                ],
        });
      default:
        return fail
            ? const FailureResult(
                AppFailure(
                  kind: FailureKind.business,
                  code: 'denied',
                  safeMessage: '保存失败',
                ),
              )
            : const Success({});
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'product filters use init 2; reset clears text and both category ids',
    (tester) async {
      final loader = Loader()..productMode = true;
      await tester.pumpWidget(
        MaterialApp(home: BmsStatisticalGroupConfigView(loader: loader)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('配置').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '酒');
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byType(DropdownButtonFormField<int>).first,
          )
          .onChanged!(10);
      await tester.pump();
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byType(DropdownButtonFormField<int>).last,
          )
          .onChanged!(11);
      await tester.pump();
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(loader.requests.last.parameters, {
        'id': 1,
        'init': 2,
        'one_cate_id': 10,
        'two_cate_id': 11,
        'name': '酒',
      });
      await tester.tap(find.text('重置'));
      await tester.pumpAndSettle();
      expect(loader.requests.last.parameters, {
        'id': 1,
        'init': 1,
        'one_cate_id': 0,
        'two_cate_id': 0,
        'name': '',
      });
    },
  );
  testWidgets(
    'statistics creates source defaults, renames, changes business type and reorders',
    (tester) async {
      final loader = Loader();
      await tester.pumpWidget(
        MaterialApp(home: BmsStatisticalGroupConfigView(loader: loader)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('新增类别'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('configuration-name')),
        '新统计',
      );
      await tester.tap(find.byKey(const Key('configuration-save')));
      await tester.pumpAndSettle();
      expect(
        loader.requests
            .where(
              (r) =>
                  r.operation ==
                  BmsReportConfigurationOperation.createStatistic,
            )
            .single
            .parameters,
        {'name': '新统计', 'type_id': 2, 'biz_type': 3},
      );
      await tester.tap(find.text('更改名称').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('configuration-name')), '改名');
      await tester.tap(find.byKey(const Key('configuration-save')));
      await tester.pumpAndSettle();
      expect(
        loader.requests
            .where(
              (r) =>
                  r.operation ==
                  BmsReportConfigurationOperation.renameStatistic,
            )
            .single
            .parameters,
        {'id': 1, 'name': '改名'},
      );
      await tester.tap(find.text('更改营业类型').first);
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byType(DropdownButtonFormField<int>),
          )
          .onChanged!(2);
      await tester.pump();
      await tester.tap(find.byKey(const Key('configuration-save')));
      await tester.pumpAndSettle();
      expect(
        loader.requests
            .where(
              (r) =>
                  r.operation ==
                  BmsReportConfigurationOperation.saveStatisticBusinessType,
            )
            .single
            .parameters,
        {'id': 1, 'biz_type': 2},
      );
      await tester.tap(find.byTooltip('下移').first);
      await tester.pumpAndSettle();
      expect(
        loader.requests
            .where(
              (r) =>
                  r.operation == BmsReportConfigurationOperation.moveStatistic,
            )
            .single
            .parameters,
        {'id': 1, 'dest_id': 2, 'down_up': 1},
      );
    },
  );
  testWidgets(
    'batch delete requires confirmation and cancel performs no write',
    (tester) async {
      final loader = Loader();
      await tester.pumpWidget(
        MaterialApp(home: BmsChannelGroupConfigView(loader: loader)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('现金类'));
      await tester.pump();
      await tester.tap(find.text('批量删除'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(
        loader.requests.where(
          (r) => r.operation == BmsReportConfigurationOperation.deleteChannels,
        ),
        isEmpty,
      );
      await tester.tap(find.text('批量删除'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定删除'));
      await tester.pumpAndSettle();
      expect(
        loader.requests
            .where(
              (r) =>
                  r.operation == BmsReportConfigurationOperation.deleteChannels,
            )
            .single
            .parameters,
        {
          'ids': [1],
        },
      );
    },
  );
  testWidgets(
    'missing channel ownership never becomes an unassigned candidate',
    (tester) async {
      final loader = Loader()..badOwner = true;
      await tester.pumpWidget(
        MaterialApp(home: BmsChannelGroupConfigView(loader: loader)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('新增类别'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(CheckboxListTile, '扫码'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('configuration-save')))
            .onPressed,
        isNull,
      );
    },
  );
  for (final channel in [true, false]) {
    testWidgets(
      '${channel ? 'channel' : 'category'} preserves own children and excludes other groups',
      (tester) async {
        final loader = Loader();
        await tester.pumpWidget(
          MaterialApp(
            home: channel
                ? BmsChannelGroupConfigView(loader: loader)
                : BmsStatisticalGroupConfigView(loader: loader),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(channel ? '编辑' : '配置').first);
        await tester.pumpAndSettle();
        final blocked = find.widgetWithText(
          CheckboxListTile,
          channel ? '卡 - 其他类' : '其他 - 统计乙',
        );
        expect(tester.widget<CheckboxListTile>(blocked).onChanged, isNull);
        await tester.tap(find.text(channel ? '扫码' : '新分类'));
        await tester.pump();
        await tester.tap(find.byKey(const Key('configuration-save')));
        await tester.pumpAndSettle();
        final write = loader.requests
            .where(
              (r) =>
                  r.operation ==
                  (channel
                      ? BmsReportConfigurationOperation.saveChannel
                      : BmsReportConfigurationOperation
                            .saveStatisticCategories),
            )
            .single;
        expect(write.parameters[channel ? 'pay_cnl_ids' : 'cate_ids'], [
          11,
          13,
        ]);
        expect(write.parameters['id'], 1);
      },
    );
  }
  testWidgets('cancel during channel ownership preflight never saves', (
    tester,
  ) async {
    final loader = Loader();
    await tester.pumpWidget(
      MaterialApp(home: BmsChannelGroupConfigView(loader: loader)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    loader.preflight = Completer<void>();
    await tester.tap(find.byKey(const Key('configuration-save')));
    await tester.pump();
    await tester.tap(find.text('取消'));
    await tester.pump();
    loader.preflight!.complete();
    await tester.pumpAndSettle();
    expect(
      loader.requests.where(
        (r) => r.operation == BmsReportConfigurationOperation.saveChannel,
      ),
      isEmpty,
    );
  });
  testWidgets('product mode adds allowed products then confirms removal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loader = Loader()..productMode = true;
    await tester.pumpWidget(
      MaterialApp(home: BmsStatisticalGroupConfigView(loader: loader)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('配置').first);
    await tester.pumpAndSettle();
    expect(
      loader.requests
          .where(
            (r) =>
                r.operation ==
                BmsReportConfigurationOperation.statisticProducts,
          )
          .last
          .parameters,
      {'id': 1, 'init': 1, 'one_cate_id': 0, 'two_cate_id': 0, 'name': ''},
    );
    expect(find.text('已关联酒'), findsOneWidget);
    expect(find.text('一级 > 二级\n商品类型：普通商品 · 营业类型：主营'), findsOneWidget);
    await tester.tap(find.text('添加商品'));
    await tester.pumpAndSettle();
    expect(find.text('一级 > 二级\n商品类型：套餐 · 营业类型：非主营'), findsOneWidget);
    expect(
      loader.requests
          .where(
            (r) =>
                r.operation ==
                BmsReportConfigurationOperation.statisticProductItems,
          )
          .last
          .parameters,
      {'init': 1, 'one_cate_id': 0, 'two_cate_id': 0, 'name': ''},
    );
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, '他组酒（已归属其他组）'),
          )
          .onChanged,
      isNull,
    );
    await tester.ensureVisible(find.text('可添加酒'));
    await tester.tap(find.text('可添加酒'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('configuration-save')));
    await tester.pumpAndSettle();
    expect(
      loader.requests
          .where(
            (r) =>
                r.operation ==
                BmsReportConfigurationOperation.addStatisticProducts,
          )
          .single
          .parameters,
      {
        'id': 1,
        'prd_ids': [32],
      },
    );
    await tester.ensureVisible(find.text('已关联酒'));
    await tester.tap(find.text('已关联酒'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('configuration-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定移除'));
    await tester.pumpAndSettle();
    expect(
      loader.requests
          .where(
            (r) =>
                r.operation ==
                BmsReportConfigurationOperation.deleteStatisticProducts,
          )
          .single
          .parameters,
      {
        'id': 1,
        'prd_ids': [31],
      },
    );
  });
  for (final channel in [false, true]) {
    testWidgets(
      '${channel ? 'channel' : 'statistics'} 390px reads, preserves failed draft and session cancels stale write',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final loader = Loader()..fail = true;
        await tester.pumpWidget(
          MaterialApp(
            home: channel
                ? BmsChannelGroupConfigView(loader: loader)
                : BmsStatisticalGroupConfigView(loader: loader),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(channel ? '现金类' : '统计甲'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('新增类别'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('configuration-name')),
          '新类别',
        );
        if (channel) {
          await tester.tap(find.text('扫码'));
          await tester.pump();
        }
        await tester.tap(find.byKey(const Key('configuration-save')));
        await tester.pumpAndSettle();
        expect(find.text('保存失败').hitTestable(), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('configuration-name')))
              .controller!
              .text,
          '新类别',
        );
        final count = loader.requests.length;
        loader.configurationContext = Object();
        await tester.tap(find.byKey(const Key('configuration-save')));
        await tester.pumpAndSettle();
        expect(loader.requests.length, count);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
