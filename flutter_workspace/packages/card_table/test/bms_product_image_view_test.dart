import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:card_table/src/bms_product_image.dart';
import 'package:card_table/src/bms_product_image_picker.dart';
import 'package:card_table/src/bms_product_image_view.dart';
import 'package:card_table/src/bms_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

class ImageLoader implements BmsLoader, BmsProductImageLoader {
  ImageLoader(this.png);
  final Uint8List png;
  @override
  Object? productImageContext = Object();
  final requests = <BmsProductImageRequest>[];
  final uploaded = <String>[];
  bool uploadFails = false, bindFails = false, missingFails = false;
  Completer<void>? uploadGate;
  String defaultName = '';
  int mode = 2;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<Result<Map<String, Object?>>> requestProductImage(
    BmsProductImageRequest request,
  ) async {
    requests.add(request);
    switch (request.operation) {
      case BmsProductImageOperation.check:
        return Success({
          'items': [
            for (final name in request.parameters['pic_names'] as List)
              {'n': name, 'id': name == '无商品' ? 0 : 7},
          ],
        });
      case BmsProductImageOperation.missing:
        return missingFails
            ? const FailureResult(
                AppFailure(
                  kind: FailureKind.network,
                  code: 'test',
                  safeMessage: '检测失败',
                ),
              )
            : const Success({
                'cates': [
                  {
                    'n': '酒水',
                    'p': [
                      {'id': 9, 'n': '商品甲'},
                    ],
                  },
                ],
              });
      case BmsProductImageOperation.getDefault:
        return Success({
          'mode': mode,
          'def_pic_name': defaultName,
          'pic_prefix': '',
        });
      case BmsProductImageOperation.saveDefault:
        if (!bindFails) {
          defaultName = request.parameters['def_pic_name'] as String;
          mode = request.parameters['mode'] as int;
        }
        break;
      default:
        break;
    }
    return bindFails
        ? const FailureResult(
            AppFailure(
              kind: FailureKind.business,
              code: 'test',
              safeMessage: '绑定失败',
            ),
          )
        : const Success({});
  }

  @override
  Future<Result<BmsUploadedImage>> uploadProductImage(
    BmsProductImageFile file, {
    required bool Function() isCurrent,
  }) async {
    uploaded.add(file.name);
    await uploadGate?.future;
    if (uploadFails) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.network,
          code: 'test',
          safeMessage: '存储上传失败',
        ),
      );
    }
    return Success(BmsUploadedImage('image-${uploaded.length}.png', png));
  }
}

void main() {
  late Uint8List png;
  setUp(() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const Color(0xff000000), ui.BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();
    image.dispose();
    picture.dispose();
  });
  Future<void> open(
    WidgetTester tester,
    ImageLoader loader,
    List<BmsPickedImage>? files,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BmsUploadProImgView(
            loader: loader,
            picker: ({required multiple}) async => files,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  BmsPickedImage file(String name, {int? size}) => BmsPickedImage(
    name: name,
    size: size ?? png.length,
    readBytes: () async => png,
    release: () async {},
  );
  testWidgets('201 files reject before reading bytes or any backend call', (
    tester,
  ) async {
    var reads = 0, releases = 0;
    final loader = ImageLoader(png);
    await open(tester, loader, [
      for (var i = 0; i < 201; i++)
        BmsPickedImage(
          name: '商品$i.png',
          size: null,
          readBytes: () async {
            reads++;
            return png;
          },
          release: () async {
            releases++;
          },
        ),
    ]);
    await tester.tap(find.text('批量上传'));
    await tester.pumpAndSettle();
    expect(reads, 0);
    expect(releases, 201);
    expect(loader.requests, isEmpty);
    expect(find.textContaining('最多200张'), findsWidgets);
  });
  testWidgets(
    'same name uses last file and storage failure is retryable without binding',
    (tester) async {
      final read = <int>[];
      final loader = ImageLoader(png)..uploadFails = true;
      await open(tester, loader, [
        for (var i = 0; i < 2; i++)
          BmsPickedImage(
            name: '商品.png',
            size: null,
            readBytes: () async {
              read.add(i);
              return png;
            },
            release: () async {},
          ),
      ]);
      await tester.tap(find.text('批量上传'));
      await tester.pumpAndSettle();
      expect(read, [1]);
      expect(find.text('存储上传失败'), findsOneWidget);
      expect(
        loader.requests.where(
          (r) => r.operation == BmsProductImageOperation.bindBatch,
        ),
        isEmpty,
      );
      loader.uploadFails = false;
      await tester.tap(find.text('重试匹配/上传'));
      await tester.pumpAndSettle();
      expect(read, [1, 1]);
      expect(find.text('已上传存储，待导入'), findsOneWidget);
    },
  );
  testWidgets('failed missing-image detection never claims completed', (
    tester,
  ) async {
    final loader = ImageLoader(png)..missingFails = true;
    await open(tester, loader, null);
    await tester.tap(find.text('图片检测'));
    await tester.pumpAndSettle();
    expect(find.text('检测失败'), findsOneWidget);
    expect(find.textContaining('检测完毕'), findsNothing);
  });
  testWidgets(
    'batch checks names, uploads storage then only selected bind signals success',
    (tester) async {
      final loader = ImageLoader(png)..bindFails = true;
      await open(tester, loader, [
        file('商品甲.png'),
        file('无商品.jpg'),
        file('超大.png', size: 512000),
      ]);
      await tester.tap(find.text('批量上传'));
      await tester.pumpAndSettle();
      expect(loader.requests.first.parameters, {
        'pic_names': ['商品甲', '无商品'],
      });
      expect(loader.uploaded, ['商品甲.png']);
      expect(find.textContaining('绑定成功'), findsNothing);
      expect(find.text('未检测到对应商品'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('product-image-bind')));
      await tester.tap(find.byKey(const Key('product-image-bind')));
      await tester.pumpAndSettle();
      expect(loader.requests.last.parameters, {
        'ids': [7],
        'pic_names': ['image-1.png'],
      });
      expect(find.text('绑定失败'), findsOneWidget);
      loader.bindFails = false;
      await tester.tap(find.byKey(const Key('product-image-bind')));
      await tester.pumpAndSettle();
      expect(find.text('选中商品图片已绑定成功'), findsOneWidget);
      expect(find.text('已绑定'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final cancel in [true, false]) {
    testWidgets(
      'pending storage ${cancel ? 'cancel' : 'session'} never binds',
      (tester) async {
        final loader = ImageLoader(png)..uploadGate = Completer<void>();
        await open(tester, loader, [file('商品甲.png')]);
        await tester.tap(find.text('批量上传'));
        await tester.pump();
        await tester.pump();
        if (cancel) {
          await tester.tap(find.text('取消当前批次'));
          await tester.pump();
        } else {
          loader.productImageContext = Object();
        }
        loader.uploadGate!.complete();
        await tester.pumpAndSettle();
        expect(
          loader.requests.where(
            (r) => r.operation == BmsProductImageOperation.bindBatch,
          ),
          isEmpty,
        );
        expect(find.textContaining('绑定成功'), findsNothing);
      },
    );
  }
  testWidgets(
    'missing product upload uses captured id and binding failure can retry',
    (tester) async {
      final loader = ImageLoader(png)..bindFails = true;
      await open(tester, loader, [file('任意名称.png')]);
      await tester.tap(find.text('图片检测'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('商品甲'));
      await tester.pumpAndSettle();
      expect(loader.requests.last.parameters, {
        'prd_id': 9,
        'prd_name': 'image-1.png',
      });
      expect(find.text('绑定失败'), findsOneWidget);
      loader.bindFails = false;
      await tester.ensureVisible(find.text('重试当前商品'));
      await tester.tap(find.text('重试当前商品'));
      await tester.pumpAndSettle();
      expect(loader.uploaded.length, 1);
      expect(find.text('商品图片已绑定成功'), findsOneWidget);
    },
  );
  testWidgets(
    'default image toggle/delete remain drafts until save; cancelled picker does nothing',
    (tester) async {
      final loader = ImageLoader(png);
      await open(tester, loader, null);
      await tester.tap(find.text('商品默认图片'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('选择默认图片'));
      await tester.pumpAndSettle();
      expect(loader.uploaded, isEmpty);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(
        loader.requests.where(
          (r) => r.operation == BmsProductImageOperation.saveDefault,
        ),
        isEmpty,
      );
      await tester.tap(find.byKey(const Key('product-image-default-save')));
      await tester.pumpAndSettle();
      expect(
        loader.requests
            .firstWhere(
              (r) => r.operation == BmsProductImageOperation.saveDefault,
            )
            .parameters,
        {'mode': 1, 'def_pic_name': ''},
      );
      expect(find.text('默认图片设置已保存'), findsOneWidget);
    },
  );
}
