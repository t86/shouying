import 'dart:async';

import 'package:card_table/src/wine_loader.dart';
import 'package:card_table/src/wine_models.dart';
import 'package:flutter/material.dart';

/// S5.P10 存酒报表综合主页面
final class WineReportsScreen extends StatefulWidget {
  const WineReportsScreen({
    required this.loader,
    this.initialReportIndex = 0,
    super.key,
  });

  final WineLoader loader;
  final int initialReportIndex;

  @override
  State<WineReportsScreen> createState() => _WineReportsScreenState();
}

final class _WineReportsScreenState extends State<WineReportsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    '存取记录',
    '延期记录',
    '充公出库记录',
    '存酒入库统计',
    '存酒出库统计',
    '充公出库统计',
    '存酒查询',
    '日实时库存',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialReportIndex.clamp(0, _tabs.length - 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xff182037),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.lightBlueAccent,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.lightBlueAccent,
            tabs: [
              for (final title in _tabs) Tab(text: title),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 1. 存取记录报表
              _WineGenericReportView(
                loader: widget.loader,
                apiPath: '/wine/get_wine_in_and_out_report',
                title: '存取记录报表',
                columns: const ['流水号', '客人姓名', '手机号码', '商品', '规格', '数量', '类型', '操作时间', '卡台', '操作人'],
                fieldKeys: const ['i', 'cn', 'p', 'n', 'u', 'c', 't_name', 't', 's', 'w'],
                enablePrint: true,
              ),
              // 2. 延期记录报表
              _WineGenericReportView(
                loader: widget.loader,
                apiPath: '/wine/get_wine_delay_report',
                title: '延期记录报表',
                columns: const ['流水号', '客人姓名', '商品', '延期天数', '原到期日', '新到期日', '操作人', '操作时间'],
                fieldKeys: const ['i', 'cn', 'n', 'day', 'old_e', 'new_e', 'w', 't'],
              ),
              // 3. 充公出库记录报表
              _WineGenericReportView(
                loader: widget.loader,
                apiPath: '/wine/get_cg_out_report',
                title: '充公出库记录报表',
                columns: const ['出库单号', '商品名称', '规格', '数量', '出库去向', '操作人', '出库时间'],
                fieldKeys: const ['id', 'n', 'u', 'c', 'target', 'w', 't'],
              ),
              // 4. 存酒入库统计报表
              _WineGenericReportView(
                loader: widget.loader,
                apiPath: '/wine/get_save_wine_report',
                title: '存酒入库统计报表',
                columns: const ['商品名称', '规格', '总入库瓶数', '整瓶数', '散瓶数', '入库笔数'],
                fieldKeys: const ['n', 'u', 'total_c', 'whole_c', 'part_c', 'order_cnt'],
              ),
              // 5. 存酒出库统计报表
              _WineGenericReportView(
                loader: widget.loader,
                apiPath: '/wine/get_out_wine_report',
                title: '存酒出库统计报表',
                columns: const ['商品名称', '规格', '总出库瓶数', '正常取酒', '充公出库', '出库笔数'],
                fieldKeys: const ['n', 'u', 'total_c', 'normal_c', 'cg_c', 'order_cnt'],
              ),
              // 6. 充公出库统计报表
              _WineGenericReportView(
                loader: widget.loader,
                apiPath: '/wine/get_cg_wine_report',
                title: '充公出库统计报表',
                columns: const ['商品名称', '规格', '充公数量', '出库去向', '统计周期'],
                fieldKeys: const ['n', 'u', 'c', 'target', 'period'],
              ),
              // 7. 存酒查询报表
              _WineGenericReportView(
                loader: widget.loader,
                apiPath: '/wine/search_wine_invt',
                title: '存酒查询报表',
                columns: const ['流水号', '客人姓名', '手机', '酒水', '规格', '库存', '存酒时间', '到期时间', '卡台', '订位人'],
                fieldKeys: const ['i', 'cn', 'p', 'n', 'u', 'c', 'st', 'et', 's', 'se'],
              ),
              // 8. 日实时库存报表
              _WineGenericReportView(
                loader: widget.loader,
                apiPath: '/wine/get_wine_now_invt_report',
                title: '日实时库存报表',
                columns: const ['商品编码', '商品名称', '规格', '整瓶库存', '散瓶库存', '折合总瓶数'],
                fieldKeys: const ['code', 'n', 'u', 'whole_cnt', 'part_cnt', 'total_cnt'],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WineGenericReportView extends StatefulWidget {
  const _WineGenericReportView({
    required this.loader,
    required this.apiPath,
    required this.title,
    required this.columns,
    required this.fieldKeys,
    this.enablePrint = false,
  });

  final WineLoader loader;
  final String apiPath;
  final String title;
  final List<String> columns;
  final List<String> fieldKeys;
  final bool enablePrint;

  @override
  State<_WineGenericReportView> createState() => _WineGenericReportViewState();
}

class _WineGenericReportViewState extends State<_WineGenericReportView> {
  final _searchController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  List<WineReportRow> _rows = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final fmt = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _startDateController.text = fmt;
    _endDateController.text = fmt;
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await widget.loader.loadReportData(
      path: widget.apiPath,
      params: {
        'start_day': _startDateController.text.trim(),
        'end_day': _endDateController.text.trim(),
        'key': _searchController.text.trim(),
      },
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.failureOrNull case final f?) {
        _error = f.safeMessage;
      } else {
        _rows = res.valueOrNull ?? [];
      }
    });
  }

  Future<void> _printTicket(String id) async {
    final res = await widget.loader.printSaveAndGetWineList(id);
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('补打小票失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('补打小票指令已发送')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xff182037),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _startDateController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(isDense: true, labelText: '开始日期', border: OutlineInputBorder()),
                ),
              ),
              const Text('至', style: TextStyle(color: Colors.white)),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _endDateController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(isDense: true, labelText: '结束日期', border: OutlineInputBorder()),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: '搜索关键词',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => unawaited(_load()),
                ),
              ),
              FilledButton.icon(
                onPressed: () => unawaited(_load()),
                icon: const Icon(Icons.search, size: 18),
                label: const Text('查询'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  unawaited(_load());
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重置'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
              ),
            ],
          ),
        ),
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.red.withAlpha(50),
            child: Text('加载错误: $_error', style: const TextStyle(color: Colors.redAccent)),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _rows.isEmpty
                  ? Center(child: Text('暂无${widget.title}数据', style: const TextStyle(color: Colors.white38)))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xff182037)),
                          dataRowColor: WidgetStateProperty.all(const Color(0xff0D172D)),
                          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
                          columns: [
                            const DataColumn(label: Text('序号')),
                            for (final col in widget.columns) DataColumn(label: Text(col)),
                            if (widget.enablePrint) const DataColumn(label: Text('操作')),
                          ],
                          rows: [
                            for (var i = 0; i < _rows.length; i++)
                              DataRow(
                                cells: [
                                  DataCell(Text('${i + 1}')),
                                  for (final key in widget.fieldKeys)
                                    DataCell(Text(_rows[i].get(key, '-'))),
                                  if (widget.enablePrint)
                                    DataCell(
                                      TextButton.icon(
                                        onPressed: () => unawaited(_printTicket(_rows[i].get('id', _rows[i].get('i')))),
                                        icon: const Icon(Icons.print, size: 14),
                                        label: const Text('补打小票'),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}
