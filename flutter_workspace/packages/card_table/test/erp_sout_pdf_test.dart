import 'dart:io';

import 'package:card_table/src/erp_sout_pdf.dart';
import 'package:card_table/src/erp_sout_workflow.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const data = <String, Object?>{
    'code': 'CK-20260922',
    'store_name': '总仓',
    'record_type': '其他出库',
    'store_time': '2026-09-22 15:30:00',
    'oper_emp_name': '张三',
    'total_amt': 90,
    'sell_total_amt': 999,
    'status': '已完成',
    'remark': '测试备注',
    'dtls': [
      {
        'n': '商品甲',
        'moc': '饮品',
        'mtc': '果汁',
        'un': '瓶',
        'c': 3,
        'a': 80,
        'sa': '100.5',
      },
      {'n': '商品乙', 'c': 0, 'a': 10, 'sa': 2.25},
    ],
    'hc_dtls': [
      {
        'n': '商品甲',
        'oen': '李四',
        'c': 1,
        'a': 20,
        'un': '瓶',
        'bc': 3,
        'ac': 2,
        'ot': '2026-09-22 16:00:00',
        'sa': 33.5,
      },
    ],
  };
  const doc = ErpSoutDocument(data, ErpSoutDocumentMode.view);

  test('only exact completed view documents may print', () async {
    expect(canPrintErpSout(doc), isTrue);
    for (final mode in [
      ErpSoutDocumentMode.copy,
      ErpSoutDocumentMode.reversal,
    ]) {
      final blocked = ErpSoutDocument(data, mode);
      expect(canPrintErpSout(blocked), isFalse);
      await expectLater(buildErpSoutPdf(blocked), throwsStateError);
    }
    for (final status in [null, '待完成', '已完成 ']) {
      final blocked = ErpSoutDocument({
        ...data,
        'status': status,
      }, ErpSoutDocumentMode.view);
      expect(canPrintErpSout(blocked), isFalse);
      await expectLater(buildErpSoutPdf(blocked), throwsStateError);
    }
  });

  test('empty document loads bundled font without injected bytes', () async {
    final pdf = await buildErpSoutPdf(
      const ErpSoutDocument({'status': '已完成'}, ErpSoutDocumentMode.view),
    );
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
  });

  test('invalid amount fails rather than printing a misleading total', () {
    expect(
      () => ErpSoutPdfContent(
        ErpSoutDocument({
          ...data,
          'dtls': [
            {'c': 1, 'sa': 'NaN'},
          ],
        }, ErpSoutDocumentMode.view),
      ),
      throwsFormatException,
    );
  });

  test(
    'print fields preserve yuan and sum dtls only; reversal needs no id',
    () {
      final content = ErpSoutPdfContent(doc);
      expect(content.headerValues, [
        'CK-20260922',
        '总仓',
        '其他出库',
        '2026-09-22 15:30:00',
        '张三',
        '90',
        '999',
        '已完成',
        '测试备注',
      ]);
      expect(content.detailRows.first, [
        '1',
        '商品甲',
        '饮品',
        '果汁',
        '瓶',
        '3',
        '33.50',
        '80',
        '100.5',
      ]);
      expect(content.detailRows.last[6], '—');
      expect(content.reversalRows.single, [
        '1',
        '商品甲',
        '李四',
        '1',
        '20',
        '瓶',
        '3',
        '2',
        '2026-09-22 16:00:00',
        '33.5',
      ]);
      expect(content.total, '102.75');
      final empty = ErpSoutPdfContent(
        const ErpSoutDocument({'status': '已完成'}, ErpSoutDocumentMode.view),
      );
      expect(empty.detailRows, isEmpty);
      expect(empty.reversalRows, isEmpty);
      expect(empty.total, '0.00');
    },
  );

  test(
    'bundled Chinese font generates a multipage PDF with long text',
    () async {
      final font = ByteData.sublistView(
        await File('assets/fonts/NotoSansSC-Regular.ttf').readAsBytes(),
      );
      final large = ErpSoutDocument({
        ...data,
        'remark': List.filled(40, '完整中文长备注，不截断。').join(),
        'dtls': List.generate(
          90,
          (i) => {
            'n': '第${i + 1}项${List.filled(12, '中文长物料名称').join()}',
            'moc': '饮品',
            'mtc': '果汁',
            'un': '瓶',
            'c': i == 0 ? 0 : 3,
            'a': 80,
            'sa': 100.5,
          },
        ),
      }, ErpSoutDocumentMode.view);
      final pdf = await buildErpSoutPdf(large, fontBytes: font);
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
      expect(pdf.length, greaterThan(10000));
      if (Platform.environment['ERP_PDF_QA_OUTPUT'] case final String path) {
        await File(path).writeAsBytes(pdf);
      }
    },
  );
}
