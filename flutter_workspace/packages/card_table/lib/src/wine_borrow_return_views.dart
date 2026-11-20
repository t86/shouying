import 'dart:async';

import 'package:card_table/src/wine_borrow_form_dialog.dart';

import 'package:card_table/src/wine_loader.dart';
import 'package:card_table/src/wine_models.dart';
import 'package:flutter/material.dart';

/// S5.P11 存酒借还综合视图
final class WineBorrowReturnView extends StatefulWidget {
  const WineBorrowReturnView({required this.loader, super.key});
  final WineLoader loader;

  @override
  State<WineBorrowReturnView> createState() => _WineBorrowReturnViewState();
}

final class _WineBorrowReturnViewState extends State<WineBorrowReturnView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            tabs: const [
              Tab(text: '借酒记录'),
              Tab(text: '还酒记录'),
              Tab(text: '未还酒水统计'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              WineBorrowView(loader: widget.loader),
              WineReturnView(loader: widget.loader),
              WineUnreturnedView(loader: widget.loader),
            ],
          ),
        ),
      ],
    );
  }
}

/// S5.P11.T01 借酒记录与开单
final class WineBorrowView extends StatelessWidget {
  const WineBorrowView({required this.loader, this.now, super.key});
  final WineLoader loader;
  final DateTime Function()? now;
  @override
  Widget build(BuildContext context) =>
      _WineBorrowRecords(loader: loader, returning: false, now: now);
}

/// S5.P11.T02 还酒记录与开单
final class WineReturnView extends StatelessWidget {
  const WineReturnView({required this.loader, this.now, super.key});
  final WineLoader loader;
  final DateTime Function()? now;
  @override
  Widget build(BuildContext context) =>
      _WineBorrowRecords(loader: loader, returning: true, now: now);
}

class _WineBorrowRecords extends StatefulWidget {
  const _WineBorrowRecords({
    required this.loader,
    required this.returning,
    this.now,
  });
  final WineLoader loader;
  final bool returning;
  final DateTime Function()? now;
  @override
  State<_WineBorrowRecords> createState() => _WineBorrowRecordsState();
}

class _WineBorrowRecordsState extends State<_WineBorrowRecords> {
  final _search = TextEditingController(),
      _begin = TextEditingController(),
      _end = TextEditingController();
  List<WineBorrowReturnItem> _items = [];
  int _page = 1, _version = 0, _days = 7;
  static const _pageSize = 20;
  int? _total;
  bool _loading = false;
  String? _error;
  String _appliedBegin = '', _appliedEnd = '', _appliedKeyword = '';
  String get _action => widget.returning ? '还酒' : '借酒';
  static String _day(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  static DateTime? _parseDay(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed != null && _day(parsed) == value ? parsed : null;
  }

  @override
  void initState() {
    super.initState();
    _setDays(7);
    _query();
  }

  @override
  void didUpdateWidget(covariant _WineBorrowRecords oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.loader, widget.loader) ||
        oldWidget.returning != widget.returning) {
      _version++;
      _search.clear();
      _setDays(7);
      _query();
    }
  }

  @override
  void dispose() {
    _version++;
    _search.dispose();
    _begin.dispose();
    _end.dispose();
    super.dispose();
  }

  void _setDays(int days) {
    final now = widget.now?.call() ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _days = days;
    _begin.text = _day(today.subtract(Duration(days: days)));
    _end.text = _day(today);
  }

  void _query() {
    final begin = _parseDay(_begin.text.trim()),
        end = _parseDay(_end.text.trim());
    if (begin == null || end == null || begin.isAfter(end)) {
      // Invalidate an older in-flight query before displaying a validation error.
      _version++;
      setState(() {
        _loading = false;
        _items = [];
        _total = null;
        _error = '请输入有效起止日期（YYYY-MM-DD），开始日期不能晚于结束日期';
      });
      return;
    }
    _appliedBegin = _begin.text.trim();
    _appliedEnd = _end.text.trim();
    _appliedKeyword = _search.text.trim();
    unawaited(_load(1));
  }

  Future<void> _load(int page) async {
    final request = ++_version;
    final loader = widget.loader;
    final contextToken = loader is WineBorrowFormContext
        ? (loader as WineBorrowFormContext).borrowFormContext
        : null;
    setState(() {
      _page = page;
      _loading = true;
      _error = null;
      _items = [];
      _total = null;
    });
    try {
      List<WineBorrowReturnItem> items;
      int? total;
      if (loader is WineBorrowPageLoader) {
        final result = await (loader as WineBorrowPageLoader)
            .loadWineBorrowReturnPage(
              type: widget.returning ? 2 : 1,
              page: page,
              pageSize: _pageSize,
              beginDay: _appliedBegin,
              endDay: _appliedEnd,
              keyword: _appliedKeyword,
            );
        if (!mounted || request != _version) return;
        if (result.failureOrNull case final failure?) {
          setState(() => _error = failure.safeMessage);
          return;
        }
        final data = result.valueOrNull;
        if (data == null) {
          setState(() => _error = '借还记录分页数据无法识别');
          return;
        }
        items = data.items;
        total = data.total;
      } else {
        // Compatibility for existing isolated loaders; never invent a total.
        final result = await loader.loadWineBorrowReturnList(
          type: widget.returning ? 2 : 1,
          page: page,
          pageSize: _pageSize,
          keyword: _appliedKeyword,
        );
        if (!mounted || request != _version) return;
        if (result.failureOrNull case final failure?) {
          setState(() => _error = failure.safeMessage);
          return;
        }
        items = result.valueOrNull ?? [];
      }
      if (!mounted ||
          request != _version ||
          !identical(loader, widget.loader)) {
        return;
      }
      if (loader is WineBorrowFormContext &&
          (contextToken == null ||
              contextToken !=
                  (loader as WineBorrowFormContext).borrowFormContext)) {
        setState(() => _error = '登录或连接状态已改变，请重新查询');
        return;
      }
      setState(() {
        _items = items;
        _total = total;
      });
    } on Object {
      if (mounted && request == _version) {
        setState(() => _error = '借还记录查询失败，请重试');
      }
    } finally {
      if (mounted && request == _version) setState(() => _loading = false);
    }
  }

  Future<void> _pickDay(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _parseDay(controller.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() {
      controller.text = _day(picked);
      _days = 0;
    });
  }

  Future<void> _newRecord() async {
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WineBorrowFormDialog(
        loader: widget.loader,
        returning: widget.returning,
      ),
    );
    if (!mounted || success != true) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$_action成功')));
    await _load(_page);
  }

  Widget _dateField(
    TextEditingController controller,
    String key,
    String label,
  ) => SizedBox(
    width: 160,
    child: TextField(
      key: Key(key),
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        isDense: true,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: '选择$label',
          onPressed: () => _pickDay(controller),
          icon: const Icon(Icons.calendar_today, size: 18),
        ),
      ),
      onChanged: (_) => setState(() => _days = 0),
      onSubmitted: (_) => _query(),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        color: const Color(0xff182037),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final days in [7, 30, 90])
              ChoiceChip(
                label: Text(days == 90 ? '近3个月' : '近$days天'),
                selected: _days == days,
                onSelected: (_) {
                  setState(() => _setDays(days));
                  _query();
                },
              ),
            _dateField(_begin, 'wine-list-begin', '开始日期'),
            _dateField(_end, 'wine-list-end', '结束日期'),
            SizedBox(
              width: 240,
              child: TextField(
                key: const Key('wine-list-search'),
                controller: _search,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '酒水名称或备注信息',
                  hintStyle: TextStyle(color: Colors.white70),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _query(),
              ),
            ),
            FilledButton(onPressed: _query, child: const Text('查询')),
            OutlinedButton(
              onPressed: () {
                _search.clear();
                setState(() => _setDays(7));
                _query();
              },
              child: const Text('重置'),
            ),
            FilledButton.icon(
              onPressed: _newRecord,
              icon: const Icon(Icons.add, size: 18),
              label: Text('新增$_action'),
            ),
          ],
        ),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            '加载错误: $_error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? const SizedBox.shrink()
            : _items.isEmpty
            ? Center(
                child: Text(
                  '暂无$_action记录',
                  style: const TextStyle(color: Colors.white38),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    dataTextStyle: const TextStyle(color: Colors.white),
                    columns: [
                      for (final label in [
                        '序号',
                        '单号',
                        '商品名称',
                        '规格',
                        '$_action数量',
                        '$_action人',
                        '操作人',
                        '$_action时间',
                        '备注',
                      ])
                        DataColumn(label: Text(label)),
                    ],
                    rows: [
                      for (var i = 0; i < _items.length; i++)
                        DataRow(
                          cells: [
                            DataCell(
                              Text('${(_page - 1) * _pageSize + i + 1}'),
                            ),
                            DataCell(Text(_items[i].orderNo)),
                            DataCell(Text(_items[i].wineName)),
                            DataCell(Text(_items[i].unit)),
                            DataCell(Text('${_items[i].count}')),
                            DataCell(Text(_items[i].borrowerName)),
                            DataCell(Text(_items[i].operatorName)),
                            DataCell(Text(_items[i].operateTime)),
                            DataCell(
                              Text(
                                _items[i].remark.isEmpty
                                    ? '-'
                                    : _items[i].remark,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
      ),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          TextButton(
            onPressed: _loading || _page <= 1 ? null : () => _load(_page - 1),
            child: const Text('上一页'),
          ),
          Text(
            _total == null ? '第$_page页 · 总数待确认' : '第$_page页 · 共$_total条',
            style: const TextStyle(color: Colors.white70),
          ),
          TextButton(
            onPressed:
                _loading || _total == null || _page * _pageSize >= _total!
                ? null
                : () => _load(_page + 1),
            child: const Text('下一页'),
          ),
        ],
      ),
    ],
  );
}

/// S5.P11.T03 未还酒水统计与导出
final class WineUnreturnedView extends StatefulWidget {
  const WineUnreturnedView({required this.loader, super.key});
  final WineLoader loader;

  @override
  State<WineUnreturnedView> createState() => _WineUnreturnedViewState();
}

final class _WineUnreturnedViewState extends State<WineUnreturnedView> {
  final _searchController = TextEditingController();
  List<WineBorrowReturnItem> _items = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await widget.loader.loadWineBorrowInvtList(
      keyword: _searchController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.failureOrNull case final f?) {
        _error = f.safeMessage;
      } else {
        _items = res.valueOrNull ?? [];
      }
    });
  }

  Future<void> _export() async {
    final res = await widget.loader.exportUnreturnedWineList(
      keyword: _searchController.text.trim(),
    );
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('导出失败: ${f.safeMessage}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(wineExportSuccessMessage(widget.loader))),
      );
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
                width: 240,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: '商品名称',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white70,
                      size: 20,
                    ),
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff00897B),
                ),
                onPressed: _export,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('导出'),
              ),
            ],
          ),
        ),
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.red.withAlpha(50),
            child: Text(
              '加载错误: $_error',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? const Center(
                  child: Text(
                    '暂无未还酒水统计',
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xff182037),
                      ),
                      dataRowColor: WidgetStateProperty.all(
                        const Color(0xff0D172D),
                      ),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      dataTextStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      columns: const [
                        DataColumn(label: Text('序号')),
                        DataColumn(label: Text('商品名称')),
                        DataColumn(label: Text('规格')),
                        DataColumn(label: Text('未还数量')),
                      ],
                      rows: [
                        for (var i = 0; i < _items.length; i++)
                          DataRow(
                            cells: [
                              DataCell(Text('${i + 1}')),
                              DataCell(Text(_items[i].wineName)),
                              DataCell(Text(_items[i].unit)),
                              DataCell(Text('${_items[i].count}')),
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
