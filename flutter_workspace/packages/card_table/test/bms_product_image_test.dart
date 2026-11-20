import 'dart:ui' as ui;

import 'package:card_table/src/bms_api.dart';
import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_product_image.dart';
import 'package:card_table/src/bms_product_image_picker_native.dart' as picker;
import 'package:card_table/src/bms_product_image_uploader.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

import 'bms_loader_guard_test.dart' show loginSession;
import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;

const signed = {
  'host': 'https://bucket.example.test',
  'dir': 'images/',
  'policy': 'synthetic-policy',
  'accessid': 'synthetic-id',
  'signature': 'synthetic-signature',
};

class OssAdapter implements HttpClientAdapter {
  late RequestOptions request;
  int status = 200;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    if (stream != null) await stream.drain<void>();
    return ResponseBody.fromString('', status);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Uint8List png;
  setUp(() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const ui.Color(0xff000000), ui.BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(2, 3);
    png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();
    image.dispose();
    picture.dispose();
  });
  test('real PNG validates; size, extension, magic and unsafe signed hosts fail closed', () async {
    expect(
      await BmsProductImageFile('商品.png', png).validateAndThumbnail(),
      isNotEmpty,
    );
    for (final file in [
      BmsProductImageFile('商品.exe', png),
      BmsProductImageFile('商品.jpg', png),
      BmsProductImageFile('商品.png', Uint8List(512000)),
      BmsProductImageFile(
        '商品.png',
        Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
      ),
    ]) {
      await expectLater(file.validateAndThumbnail(), throwsFormatException);
    }
    for (final host in [
      'http://bucket.example.test',
      'https://user:pass@bucket.example.test',
      'https://127.0.0.1',
      'https://bucket.example.test?a=1',
    ]) {
      expect(
        () => BmsImageSignature.fromWire({...signed, 'host': host}),
        throwsFormatException,
      );
    }
  });
  test(
    'OSS multipart exactly matches source and excludes session credentials',
    () async {
      final adapter = OssAdapter();
      await uploadBmsImageToOss(
        BmsImageSignature.fromWire(signed),
        'uuid.png',
        BmsProductImageFile('商品.png', png),
        adapter: adapter,
      );
      final form = adapter.request.data as FormData;
      expect(Map.fromEntries(form.fields), {
        'key': 'images/uuid.png',
        'policy': 'synthetic-policy',
        'OSSAccessKeyId': 'synthetic-id',
        'success_action_status': '200',
        'signature': 'synthetic-signature',
      });
      expect(form.files.single.key, 'file');
      expect(form.files.single.value.filename, 'uuid.png');
      expect(adapter.request.followRedirects, false);
      expect(
        adapter.request.headers.keys
            .map((e) => e.toLowerCase())
            .where(['tk', 'stk', 'authorization', 'cookie'].contains),
        isEmpty,
      );
    },
  );
  test(
    'all seven source endpoints and exact bind shapes, no old fake fields',
    () async {
      final adapter = Adapter()..data = <String, Object?>{};
      final api = ProtocolBmsApi(client: makeApi(adapter).client);
      final bodies = <BmsProductImageOperation, Map<String, Object?>>{
        BmsProductImageOperation.check: {
          'pic_names': ['商品'],
        },
        BmsProductImageOperation.missing: {},
        BmsProductImageOperation.signature: {},
        BmsProductImageOperation.bindBatch: {
          'ids': [7],
          'pic_names': ['uuid.png'],
        },
        BmsProductImageOperation.bindSingle: {
          'prd_id': 7,
          'prd_name': 'uuid.png',
        },
        BmsProductImageOperation.getDefault: {},
        BmsProductImageOperation.saveDefault: {'mode': 2, 'def_pic_name': ''},
      };
      for (final entry in bodies.entries) {
        expect(
          (await api.requestProductImage(
            ClientKind.orgManager,
            BmsProductImageRequest(entry.key, parameters: entry.value),
          )).failureOrNull,
          isNull,
        );
        expect(adapter.requests.last.uri.path.endsWith(entry.key.path), true);
        expect(adapter.requests.last.data, entry.value);
      }
      final before = adapter.requests.length;
      expect(
        (await api.requestProductImage(
          ClientKind.orgManager,
          const BmsProductImageRequest(
            BmsProductImageOperation.bindBatch,
            parameters: {
              'ids': [7, 8],
              'pic_names': ['uuid.png'],
            },
          ),
        )).failureOrNull,
        isNotNull,
      );
      expect(adapter.requests.length, before);
    },
  );
  test(
    'signature failure or epoch change never reaches external uploader',
    () async {
      final authAdapter = Adapter(), adapter = Adapter()..data = signed;
      final session = SessionRepository(
        api: SessionApi(client: makeApi(authAdapter).client),
        credentialStore: Credentials(),
      );
      addTearDown(session.close);
      await loginSession(session, authAdapter, 1);
      var epoch = 0, uploads = 0;
      final loader = ProtocolBmsLoader(
        api: ProtocolBmsApi(client: makeApi(adapter).client),
        sessionRepository: session,
        phase: () => ConnectionPhase.online,
        generation: () => epoch,
        imageUploader: (_, _, _) async {
          uploads++;
        },
      );
      adapter.code = 0;
      expect(
        (await loader.uploadProductImage(
          BmsProductImageFile('商品.png', png),
          isCurrent: () => true,
        )).failureOrNull,
        isNotNull,
      );
      expect(uploads, 0);
      adapter.code = 1;
      adapter.onFetch = () => epoch++;
      expect(
        (await loader.uploadProductImage(
          BmsProductImageFile('商品.png', png),
          isCurrent: () => true,
        )).failureOrNull,
        isNotNull,
      );
      expect(uploads, 0);
      adapter.onFetch = null;
      final result = await loader.uploadProductImage(
        BmsProductImageFile('商品.png', png),
        isCurrent: () => true,
      );
      expect(result.failureOrNull, isNull);
      expect(result.valueOrNull!.fileName, endsWith('.png'));
      expect(uploads, 1);
    },
  );
  test(
    'native picker lazy reads and releases only owned handles; cancel is null',
    () async {
      final calls = <MethodCall>[];
      var cancelled = true;
      const channel = MethodChannel('shouyin/product_images');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            switch (call.method) {
              case 'pickImages':
                return cancelled
                    ? null
                    : [
                        {'id': 'owned', 'name': '商品.png', 'size': null},
                      ];
              case 'readImage':
                return png;
              default:
                return null;
            }
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      expect(await picker.pick(multiple: true), isNull);
      expect(calls.length, 1);
      cancelled = false;
      final files = await picker.pick(multiple: false);
      expect(calls.where((c) => c.method == 'readImage'), isEmpty);
      expect(await files!.single.readBytes(), png);
      expect(calls.last.arguments, {'id': 'owned'});
      await files.single.release();
      expect(calls.last.method, 'releaseImages');
      expect(calls.last.arguments, {
        'ids': ['owned'],
      });
    },
  );
}
