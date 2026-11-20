import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:card_table/src/erp_sout_workflow.dart';

bool canPrintErpSout(ErpSoutDocument document) =>
    document.mode == ErpSoutDocumentMode.view &&
    document.data['status'] == '已完成';

/// The legacy print contract. Amounts are already yuan, and the footer sums
/// original detail subtotals without subtracting reversal records.
final class ErpSoutPdfContent {
  ErpSoutPdfContent(ErpSoutDocument document) {
    if (!canPrintErpSout(document)) {
      throw StateError('只有已完成的出库单详情可以打印');
    }
    final data = document.data;
    headerValues = [for (final key in headerKeys) _text(data[key])];
    final details = _rows(data['dtls']);
    detailRows = [
      for (var i = 0; i < details.length; i++)
        [
          '${i + 1}',
          for (final key in ['n', 'moc', 'mtc', 'un', 'c'])
            _text(details[i][key]),
          _number(details[i]['c']) == 0
              ? '—'
              : (_number(details[i]['sa']) / _number(details[i]['c']))
                    .toStringAsFixed(2),
          _text(details[i]['a']),
          _text(details[i]['sa']),
        ],
    ];
    final reversals = _rows(data['hc_dtls']);
    reversalRows = [
      for (var i = 0; i < reversals.length; i++)
        [
          '${i + 1}',
          for (final key in [
            'n',
            'oen',
            'c',
            'a',
            'un',
            'bc',
            'ac',
            'ot',
            'sa',
          ])
            _text(reversals[i][key]),
        ],
    ];
    total = details
        .fold<double>(0, (sum, row) => sum + _number(row['sa']))
        .toStringAsFixed(2);
  }

  static const headerKeys = [
    'code',
    'store_name',
    'record_type',
    'store_time',
    'oper_emp_name',
    'total_amt',
    'sell_total_amt',
    'status',
    'remark',
  ];
  static const headerLabels = [
    '单号',
    '出库仓库',
    '出库类型',
    '出库时间',
    '出库操作员名称',
    '出库单总成本',
    '出库单总出库金额',
    '状态',
    '备注',
  ];
  static const detailLabels = [
    '序号',
    '物料名称',
    '一级分类',
    '二级分类',
    '出库单位',
    '出库数量',
    '出库单价',
    '出库成本金额',
    '出库小计',
  ];
  static const reversalLabels = [
    '序号',
    '物料名称',
    '红冲操作员名称',
    '红冲数量',
    '红冲成本小计',
    '红冲单位名称',
    '红冲前数量',
    '红冲后数量',
    '红冲操作时间',
    '红冲小计',
  ];

  late final List<String> headerValues;
  late final List<List<String>> detailRows;
  late final List<List<String>> reversalRows;
  late final String total;
}

String _text(Object? value) => value?.toString() ?? '';

double _number(Object? value) {
  if (value == null || value == '') return 0;
  final parsed = double.tryParse('$value');
  if (parsed == null || !parsed.isFinite) {
    throw const FormatException('出库单包含无效数值');
  }
  return parsed;
}

List<Map<String, Object?>> _rows(Object? value) {
  if (value == null) return [];
  if (value is! List || value.any((row) => row is! Map)) {
    throw const FormatException('出库明细无效');
  }
  // Print records, notably hc_dtls, do not require a database id.
  return [for (final row in value) Map<String, Object?>.from(row as Map)];
}

// Table rows cannot span a page in package:pdf. Split oversized cells into
// continuation rows, preserving every character rather than clipping them.
List<String> _chunks(String text, int length) {
  final characters = text.runes.toList();
  if (characters.isEmpty) return [''];
  return [
    for (var i = 0; i < characters.length; i += length)
      String.fromCharCodes(characters.skip(i).take(length)),
  ];
}

pw.Table _table(
  List<String> headers,
  List<List<String>> rows,
  List<double> widths,
) {
  pw.TableRow row(List<String> cells, {bool header = false}) => pw.TableRow(
    repeat: header,
    decoration: header
        ? const pw.BoxDecoration(color: PdfColors.grey200)
        : null,
    children: [
      for (final cell in cells)
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(cell, style: const pw.TextStyle(fontSize: 8.5)),
        ),
    ],
  );
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey500, width: .5),
    columnWidths: {
      for (var i = 0; i < widths.length; i++) i: pw.FlexColumnWidth(widths[i]),
    },
    children: [
      row(headers, header: true),
      for (final cells in rows)
        ...(() {
          final parts = [for (final cell in cells) _chunks(cell, 72)];
          final count = parts.fold<int>(
            1,
            (n, p) => p.length > n ? p.length : n,
          );
          return [
            for (var i = 0; i < count; i++)
              row([
                i == 0 ? cells.first : '${cells.first}续',
                for (final part in parts.skip(1))
                  i < part.length ? part[i] : '',
              ]),
          ];
        })(),
    ],
  );
}

Future<Uint8List> buildErpSoutPdf(
  ErpSoutDocument document, {
  ByteData? fontBytes,
}) async {
  final content = ErpSoutPdfContent(document);
  final font = pw.Font.ttf(
    fontBytes ??
        await rootBundle.load(
          'packages/card_table/assets/fonts/NotoSansSC-Regular.ttf',
        ),
  );
  final pdf = pw.Document(title: '其他出库单', author: '收银系统');
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      theme: pw.ThemeData.withFont(base: font, bold: font),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '第 ${context.pageNumber} / ${context.pagesCount} 页',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      build: (context) => [
        pw.Center(
          child: pw.Text('其他出库单', style: const pw.TextStyle(fontSize: 18)),
        ),
        pw.SizedBox(height: 12),
        for (var i = 0; i < content.headerValues.length; i++)
          for (final chunk in _chunks(
            '${ErpSoutPdfContent.headerLabels[i]}：${content.headerValues[i]}',
            180,
          ))
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(chunk, style: const pw.TextStyle(fontSize: 9)),
            ),
        if (content.detailRows.isNotEmpty) ...[
          pw.Header(level: 1, text: '明细单列表'),
          _table(ErpSoutPdfContent.detailLabels, content.detailRows, [
            .5,
            2.6,
            1,
            1,
            .7,
            .8,
            .9,
            1.2,
            1,
          ]),
        ],
        if (content.reversalRows.isNotEmpty) ...[
          pw.Header(level: 1, text: '红冲记录'),
          _table(ErpSoutPdfContent.reversalLabels, content.reversalRows, [
            .5,
            2,
            1.2,
            .8,
            1,
            .8,
            .8,
            .8,
            1.7,
            1,
          ]),
        ],
        pw.SizedBox(height: 12),
        pw.Text(
          '总金额：${content.total}元',
          style: const pw.TextStyle(fontSize: 11),
        ),
        pw.SizedBox(height: 14),
        pw.Text(
          '签收人：________________          送货人：________________',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    ),
  );
  return pdf.save();
}
