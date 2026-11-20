import 'dart:async';

import 'package:card_table/src/cashier_reports.dart';
import 'package:card_table/src/cashier_quota_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:foundation/foundation.dart';

/// Source-backed read-only reports; unported menu entries remain unavailable.
final class CashierReportScreen extends StatefulWidget {
  const CashierReportScreen({
    required this.title,
    this.onLoadData,
    this.onPrint,
    this.onExport,
    this.canRead,
    this.onLoadPage,
    this.onLoadOptions,
    this.onExportData,
    this.onPrintData,
    this.onPrintQuery,
    this.onFindPaymentCustomer,
    this.onChangePaymentCustomer,
    this.canModifyPayment,
    this.now,
    super.key,
  });

  final String title;
  final DateTime Function()? now;
  final ValueListenable<bool>? canRead;
  final ValueListenable<bool>? canModifyPayment;
  final Future<Result<CashierReportPage>> Function(CashierReportQuery)?
  onLoadPage;
  final Future<Result<CashierReportOptions>> Function(String)? onLoadOptions;
  final Future<Result<String>> Function(CashierReportQuery)? onExportData;
  final Future<Result<void>> Function(String)? onPrintData;
  final Future<Result<void>> Function(CashierReportQuery)? onPrintQuery;
  final Future<Result<CashierPaymentCustomer?>> Function(String)?
  onFindPaymentCustomer;
  final Future<Result<void>> Function(String, String)? onChangePaymentCustomer;
  final Future<Result<List<CashierReportRow>>> Function(
    String title,
    String startDate,
    String endDate,
    String keyword,
  )?
  onLoadData;
  final VoidCallback? onPrint;
  final VoidCallback? onExport;

  @override
  State<CashierReportScreen> createState() => _CashierReportScreenState();
}

class _TypedCashierReportScreen extends StatefulWidget {
  const _TypedCashierReportScreen({required this.owner, super.key});
  final CashierReportScreen owner;
  @override
  State<_TypedCashierReportScreen> createState() => _TypedCashierReportState();
}

class _TypedCashierReportState extends State<_TypedCashierReportScreen> {
  CashierReportScreen get owner => widget.owner;
  CashierReportMeta get meta => _customerId != null
      ? CashierReportCatalog.depositDetail
      : CashierReportCatalog.reports[owner.title]!;
  bool get _depositReport => owner.title == '预订金流水表' || owner.title == '预订金余额表';
  bool get _balanceList => owner.title == '预订金余额表' && _customerId == null;
  bool get _paginated =>
      owner.title == '支付记录' || (_depositReport && _customerId == null);
  String? _customerId;
  void _leaveDepositDetail() {
    if (_customerId == null) return;
    _customerId = null;
    _notice = null;
    unawaited(_load());
  }

  bool _pageClosed = false;
  bool get allowed => !_pageClosed && (owner.canRead?.value ?? true);
  bool get _needsSourceOptions =>
      owner.title == '历史点单记录' || owner.title == '套餐统计表';
  bool _sourceOptionsReady = false;
  Map<int, String> _historyDays = const {};
  List<CashierSetReportCategory> _setCategories = const [];
  int? _wkdayId;
  int _setStatus = 0;
  final _setCategoryIds = <int>{}, _setProductIds = <int>{};
  bool get _canQuery =>
      !_needsSourceOptions ||
      (_sourceOptionsReady && (owner.title != '历史点单记录' || _wkdayId != null));
  bool get editable => allowed && (owner.canModifyPayment?.value ?? false);
  final _keyword = TextEditingController();
  final _startDay = TextEditingController(), _endDay = TextEditingController();
  void _resetDates() {
    final date = (owner.now?.call() ?? DateTime.now()).subtract(
      const Duration(hours: 8),
    );
    final text =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    _startDay.text = text;
    _endDay.text = text;
  }

  CashierReportOptions _options = const CashierReportOptions();
  CashierReportPage _data = const CashierReportPage();
  int _region = 0,
      _group = 1,
      _dept = 0,
      _sales = 0,
      _discount = 0,
      _page = 1,
      _pageSize = 20;
  int _version = 0, _resetKey = 0;
  int? _productType, _businessType, _paymentType, _customerType;
  bool _busy = false, _optionsReady = false;
  String? _error, _notice;
  String _refreshTime = '';
  DialogRoute<bool>? _paymentDialogRoute;
  bool get needsOptions => owner.title == '区域实时营收' || owner.title == '业绩日报表';
  CashierReportQuery get query => _query();
  CashierReportQuery _query({bool Function()? canDispatch}) =>
      CashierReportQuery(
        title: owner.title,
        keyword: _keyword.text.trim(),
        page: _page,
        pageSize: _pageSize,
        regionId: _region,
        groupType: _group,
        deptId: _dept,
        salesEmpId: _sales,
        discountType: _discount,
        startDay: _startDay.text.trim(),
        endDay: _endDay.text.trim(),
        productType: _productType,
        businessType: _businessType,
        paymentType: _paymentType,
        customerType: _customerType,
        customerId: _customerId,
        wkdayId: _wkdayId,
        setAll: _setCategories.every((cat) => _setCategoryIds.contains(cat.id)),
        setCategoryIds:
            _setCategories.every((cat) => _setCategoryIds.contains(cat.id))
            ? const []
            : List.unmodifiable(_setCategoryIds),
        setProductIds:
            _setCategories.every((cat) => _setCategoryIds.contains(cat.id))
            ? const []
            : List.unmodifiable(
                _setProductIds.where(
                  (id) => !_setCategories.any(
                    (cat) =>
                        _setCategoryIds.contains(cat.id) &&
                        cat.products.containsKey(id),
                  ),
                ),
              ),
        setStatus: _setStatus,
        canDispatch: canDispatch,
      );
  @override
  void initState() {
    super.initState();
    if (_depositReport) _pageSize = 10;
    if (meta.requiresDateRange) _resetDates();
    owner.canRead?.addListener(_accessChanged);
    owner.canModifyPayment?.addListener(_editChanged);
    unawaited(_load());
  }

  @override
  void dispose() {
    _pageClosed = true;
    _version++;
    owner.canRead?.removeListener(_accessChanged);
    owner.canModifyPayment?.removeListener(_editChanged);
    _keyword.dispose();
    _startDay.dispose();
    _endDay.dispose();
    super.dispose();
  }

  void _accessChanged() {
    _sourceOptionsReady = false;
    _historyDays = const {};
    _setCategories = const [];
    _wkdayId = null;
    _setCategoryIds.clear();
    _setProductIds.clear();
    final dialog = _paymentDialogRoute;
    if (!allowed && dialog != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (dialog.isActive) dialog.navigator?.removeRoute(dialog, false);
      });
    }
    _optionsReady = false;
    unawaited(_load());
  }

  void _editChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(_TypedCashierReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.owner.canRead, owner.canRead)) {
      oldWidget.owner.canRead?.removeListener(_accessChanged);
      owner.canRead?.addListener(_accessChanged);
      _accessChanged();
    }
    if (!identical(oldWidget.owner.canModifyPayment, owner.canModifyPayment)) {
      oldWidget.owner.canModifyPayment?.removeListener(_editChanged);
      owner.canModifyPayment?.addListener(_editChanged);
    }
  }

  bool _current(int version) => mounted && version == _version && allowed;
  Future<void> _load() async {
    final version = ++_version;
    if (!allowed || owner.onLoadPage == null) {
      setState(() {
        _busy = false;
        _data = const CashierReportPage();
        _error = !allowed ? '当前无法读取报表，请检查登录和连接状态' : '报表筛选查询服务未连接';
      });
      return;
    }
    setState(() {
      _busy = true;
      _data = const CashierReportPage();
      _error = null;
      if (owner.title == '转台记录') {
        _refreshTime = (owner.now?.call() ?? DateTime.now())
            .toString()
            .substring(0, 19);
      }
    });
    try {
      if (_needsSourceOptions && !_sourceOptionsReady) {
        final initialized = await owner.onLoadPage!(
          CashierReportQuery(title: owner.title, initialize: true),
        );
        if (!_current(version)) return;
        if (initialized.failureOrNull case final failure?) {
          setState(() {
            _busy = false;
            _error = failure.safeMessage;
          });
          return;
        }
        final options = initialized.valueOrNull!;
        _historyDays = options.historyDays;
        _wkdayId = _historyDays.keys.firstOrNull;
        _setCategories = options.setCategories;
        _setCategoryIds
          ..clear()
          ..addAll(_setCategories.map((cat) => cat.id));
        _setProductIds
          ..clear()
          ..addAll(_setCategories.expand((cat) => cat.products.keys));
        _sourceOptionsReady = true;
        if (owner.title == '套餐统计表' || _wkdayId == null) {
          setState(() {
            _busy = false;
            _data = const CashierReportPage();
          });
          return;
        }
      }
      if (!_canQuery) {
        setState(() => _busy = false);
        return;
      }
      if (needsOptions && !_optionsReady) {
        final load = owner.onLoadOptions;
        if (load == null) throw const FormatException('options');
        final result = await load(owner.title);
        if (!_current(version)) return;
        if (result.failureOrNull case final failure?) {
          setState(() {
            _busy = false;
            _error = failure.safeMessage;
          });
          return;
        }
        _options = result.valueOrNull!;
        _optionsReady = true;
      }
      final result = await owner.onLoadPage!(query);
      if (!_current(version)) return;
      setState(() {
        _busy = false;
        _error = result.failureOrNull?.safeMessage;
        _data = result.valueOrNull ?? const CashierReportPage();
        if (result.valueOrNull != null && _customerId == null) {
          _page = _data.page;
          _pageSize = _data.pageSize;
        }
      });
    } on Object {
      if (_current(version)) {
        setState(() {
          _busy = false;
          _error = needsOptions && !_optionsReady
              ? '筛选选项未就绪，请重试'
              : '报表查询失败，请重试';
        });
      }
    }
  }

  Future<void> _document(bool export) async {
    if (!allowed || _busy || !_canQuery) return;
    final version = _version;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      if (export) {
        final result = await owner.onExportData!(_query(canDispatch: () => _current(version)));
        if (_current(version)) {
          setState(
            () => _notice =
                result.failureOrNull?.safeMessage ??
                '导出完成：${result.valueOrNull}',
          );
        }
      } else if (owner.title == '套餐统计表') {
        final result = await owner.onPrintQuery!(
          _query(canDispatch: () => _current(version)),
        );
        if (_current(version)) {
          setState(() => _notice = result.failureOrNull?.safeMessage ?? '打印成功');
        }
      } else {
        final result = await owner.onPrintData!(owner.title);
        if (_current(version)) {
          setState(() => _notice = result.failureOrNull?.safeMessage ?? '打印成功');
        }
      }
    } on Object {
      if (_current(version)) setState(() => _notice = '操作失败，请重试');
    } finally {
      if (_current(version)) setState(() => _busy = false);
    }
  }

  bool _canChange(CashierReportRow row) =>
      editable &&
      !_busy &&
      !row['支付方式'].contains('自助') &&
      owner.onChangePaymentCustomer != null;
  Future<void> _unbind(CashierReportRow row) async {
    if (!_canChange(row) || ['', '-'].contains(row['订单绑定会员'].trim())) return;
    final version = _version;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('取消绑定'),
        content: const Text('确认取消绑定？该支付记录的会员信息将置空。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed == true && _current(version) && _canChange(row)) {
      final changed = await _change(row.id, '', version);
      if (changed && _current(version)) await _load();
    }
  }

  Future<bool> _change(String id, String phone, int version) async {
    if (!_current(version) || !editable) return false;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final result = await owner.onChangePaymentCustomer!(id, phone);
      if (!_current(version) || !editable) return false;
      setState(
        () => _notice =
            result.failureOrNull?.safeMessage ??
            (phone.isEmpty ? '解绑成功' : '更改成功'),
      );
      if (result.failureOrNull != null) return false;
      return true;
    } on Object {
      if (_current(version)) setState(() => _notice = '更改失败，请重试');
      return false;
    } finally {
      if (_current(version)) setState(() => _busy = false);
    }
  }

  Future<void> _edit(CashierReportRow row) async {
    if (!_canChange(row)) return;
    final version = _version;
    final phone = TextEditingController();
    CashierPaymentCustomer? member;
    String? error;
    bool searching = false, saving = false;
    final dialog = DialogRoute<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, update) => AlertDialog(
            title: const Text('修改订单绑定会员'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const Key('payment-member-phone'),
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: '会员手机号'),
                    onChanged: (_) => update(() {
                      member = null;
                      error = null;
                    }),
                  ),
                  TextButton(
                    onPressed:
                        searching ||
                            saving ||
                            owner.onFindPaymentCustomer == null
                        ? null
                        : () async {
                            if (!RegExp(r'^\d{11}$')
                                .hasMatch(phone.text.trim())) {
                              update(() => error = '请输入11位数字手机号');
                              return;
                            }
                            update(() {
                              searching = true;
                              error = null;
                            });
                            try {
                              final searchedPhone = phone.text.trim();
                              final result = await owner.onFindPaymentCustomer!(
                                searchedPhone,
                              );
                              if (!ctx.mounted ||
                                  !_current(version) ||
                                  phone.text.trim() != searchedPhone) {
                                return;
                              }
                              update(() {
                                member = result.valueOrNull;
                                error =
                                    result.failureOrNull?.safeMessage ??
                                    (member == null
                                        ? '当前手机号未注册会员，仍可绑定此手机号'
                                        : null);
                              });
                            } on Object {
                              if (ctx.mounted && _current(version)) {
                                update(() => error = '会员查询失败，请重试');
                              }
                            } finally {
                              if (ctx.mounted) update(() => searching = false);
                            }
                          },
                    child: const Text('搜索会员'),
                  ),
                  if (member != null)
                    Text(
                      '姓名：${member!.name}\n手机号：${member!.phone}\n总余额：${member!.balance}\n积分：${member!.points}',
                    ),
                  if (error != null) Text(error!),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: saving || searching
                    ? null
                    : () async {
                        if (!RegExp(r'^\d{11}$').hasMatch(phone.text.trim())) {
                          update(() => error = '请输入11位数字手机号');
                          return;
                        }
                        if (!_current(version) || !editable) {
                          update(() => error = '营业或登录状态已改变，请重新打开');
                          return;
                        }
                        update(() => saving = true);
                        final success = await _change(
                          row.id,
                          phone.text.trim(),
                          version,
                        );
                        if (!ctx.mounted) return;
                        if (success) {
                          Navigator.pop(ctx, true);
                        } else {
                          update(() {
                            saving = false;
                            error = _notice ?? '操作未完成，请检查登录状态';
                          });
                        }
                      },
                child: const Text('确认更改'),
              ),
            ],
          ),
        );
      },
    );
    _paymentDialogRoute = dialog;
    final changed = await Navigator.of(context).push<bool>(dialog);
    _paymentDialogRoute = null;
    if (changed == true && _current(version)) await _load();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    phone.dispose();
  }

  Widget _select(
    String label,
    int value,
    Map<int, String> options,
    void Function(int) changed,
  ) => SizedBox(
    width: 210,
    child: DropdownButtonFormField<int>(
      key: ValueKey('$label-$_resetKey'),
      initialValue: options.containsKey(value) ? value : 0,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: options.entries
          .map(
            (e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: _busy || !allowed ? null : (v) => setState(() => changed(v!)),
    ),
  );

  Widget _orderFilter(
    String label,
    int? value,
    Map<int, String> options,
    void Function(int?) changed,
  ) => SizedBox(
    width: 210,
    child: DropdownButtonFormField<int>(
      key: ValueKey('$label-$_resetKey-$value-${options.keys.join(',')}'),
      initialValue: options.containsKey(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, hintText: '请选择$label'),
      items: [
        for (final option in options.entries)
          DropdownMenuItem(value: option.key, child: Text(option.value)),
      ],
      onChanged: !allowed || _busy ? null : (v) => setState(() => changed(v)),
    ),
  );

  Widget _historyRecords() => ListView(
    children: [
      if (_data.rows.isEmpty)
        const Padding(padding: EdgeInsets.all(12), child: Text('暂无记录')),
      for (final row in _data.rows)
        ExpansionTile(
          key: ValueKey('history-$_version-${row.id}'),
          title: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final column in meta.columns) Text('$column：${row[column]}'),
            ],
          ),
          children: [
            _relatedTable(
              '点单明细',
              CashierReportCatalog.historyDetailColumns,
              row.details,
            ),
          ],
        ),
    ],
  );

  Widget _setTree() {
    final all = _setCategories.every((cat) => _setCategoryIds.contains(cat.id));
    final enabled = allowed && !_busy && _sourceOptionsReady;
    return SizedBox(
      height: 220,
      child: ListView(
        children: [
          CheckboxListTile(
            key: const Key('report-set-all'),
            title: const Text('全部套餐'),
            tristate: true,
            value: all
                ? true
                : _setProductIds.isEmpty && _setCategoryIds.isEmpty
                ? false
                : null,
            onChanged: !enabled
                ? null
                : (_) => setState(() {
                    _setCategoryIds.clear();
                    _setProductIds.clear();
                    if (!all) {
                      _setCategoryIds.addAll(
                        _setCategories.map((cat) => cat.id),
                      );
                      _setProductIds.addAll(
                        _setCategories.expand((cat) => cat.products.keys),
                      );
                    }
                  }),
          ),
          for (final cat in _setCategories) ...[
            CheckboxListTile(
              key: ValueKey('report-set-category-${cat.id}'),
              title: Text(cat.name),
              tristate: true,
              value: _setCategoryIds.contains(cat.id)
                  ? true
                  : cat.products.keys.any(_setProductIds.contains)
                  ? null
                  : false,
              onChanged: !enabled
                  ? null
                  : (_) => setState(() {
                      if (_setCategoryIds.remove(cat.id)) {
                        _setProductIds.removeAll(cat.products.keys);
                      } else {
                        _setCategoryIds.add(cat.id);
                        _setProductIds.addAll(cat.products.keys);
                      }
                    }),
            ),
            for (final product in cat.products.entries)
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: CheckboxListTile(
                  key: ValueKey('report-set-product-${cat.id}-${product.key}'),
                  title: Text(product.value),
                  value: _setProductIds.contains(product.key),
                  onChanged: !enabled
                      ? null
                      : (selected) => setState(() {
                          if (selected == true) {
                            _setProductIds.add(product.key);
                          } else {
                            _setProductIds.remove(product.key);
                          }
                          if (cat.products.keys.every(
                            _setProductIds.contains,
                          )) {
                            _setCategoryIds.add(cat.id);
                          } else {
                            _setCategoryIds.remove(cat.id);
                          }
                        }),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _categoryChannels() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowMinHeight: 48,
            dataRowMaxHeight: double.infinity,
            columns: [
              const DataColumn(label: Text('序号')),
              const DataColumn(label: Text('类别')),
              for (final label in _data.channelColumns.values)
                DataColumn(label: Text(label)),
              const DataColumn(label: Text('合计')),
            ],
            rows: [
              for (final (index, row) in _data.rows.indexed)
                DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(row['类别'])),
                    for (final key in _data.channelColumns.keys)
                      DataCell(Text(row[key].isEmpty ? '0.00' : row[key])),
                    DataCell(Text(row['合计'])),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text('总合计: ${_data.grandTotal ?? '--'}'),
        ),
        if (_data.rows.isEmpty)
          const Padding(padding: EdgeInsets.all(12), child: Text('暂无记录')),
      ],
    ),
  );

  Widget _relatedTable(
    String title,
    List<String> columns,
    List<CashierReportRow> rows,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.all(12), child: Text(title)),
      if (rows.isEmpty)
        const Padding(padding: EdgeInsets.all(12), child: Text('暂无记录'))
      else
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowMinHeight: 48,
            dataRowMaxHeight: double.infinity,
            columns: [
              for (final column in columns) DataColumn(label: Text(column)),
            ],
            rows: [
              for (final row in rows)
                DataRow(
                  cells: [
                    for (final column in columns) DataCell(Text(row[column])),
                  ],
                ),
            ],
          ),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: _customerId == null,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) {
        _pageClosed = true;
        _version++;
      }
      if (!didPop && _customerId != null) _leaveDepositDetail();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(_customerId == null ? owner.title : meta.title),
        leading: _customerId == null
            ? null
            : BackButton(onPressed: _leaveDepositDetail),
        actions: [
          if (meta.exportPath.isNotEmpty && owner.onExportData != null)
            TextButton(
              onPressed: _busy || !allowed || _error != null || !_canQuery
                  ? null
                  : () => unawaited(_document(true)),
              child: const Text('导出Excel'),
            ),
          if (owner.title == '线上支付汇总' && owner.onPrintData != null)
            TextButton(
              onPressed: _busy || !allowed || _error != null
                  ? null
                  : () => unawaited(_document(false)),
              child: const Text('打印'),
            ),
          if (owner.title == '套餐统计表' && owner.onPrintQuery != null)
            TextButton(
              onPressed: _busy || !allowed || !_canQuery
                  ? null
                  : () => unawaited(_document(false)),
              child: const Text('打印'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_customerId == null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (meta.requiresDateRange) ...[
                    SizedBox(
                      width: 165,
                      child: TextField(
                        key: const Key('cashier-report-start-day'),
                        controller: _startDay,
                        enabled: allowed && !_busy,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                          labelText: '开始营业日期',
                          hintText: 'yyyy-MM-dd',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 165,
                      child: TextField(
                        key: const Key('cashier-report-end-day'),
                        controller: _endDay,
                        enabled: allowed && !_busy,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                          labelText: '结束营业日期',
                          hintText: 'yyyy-MM-dd',
                        ),
                      ),
                    ),
                  ],
                  if (meta.supportsKeyword)
                    SizedBox(
                      width: 230,
                      child: TextField(
                        key: const Key('cashier-report-keyword'),
                        controller: _keyword,
                        enabled: allowed && !_busy,
                        decoration: InputDecoration(
                          labelText: ['现抽明细表', '现抽汇总表'].contains(owner.title)
                              ? '商品名称/点单人'
                              : _depositReport
                              ? '客户姓名/电话'
                              : const [
                                  '优惠明细表',
                                  '点单记录',
                                  '历史点单记录',
                                  '非鸡尾酒类补交报表',
                                ].contains(owner.title)
                              ? '订台人/优惠人/商品名称'
                              : const ['商品出库表', '商品卡台销售表'].contains(owner.title)
                              ? '商品名称/简写'
                              : '搜索关键词/卡台',
                        ),
                        onSubmitted: (_) {
                          if (!_depositReport) _page = 1;
                          unawaited(_load());
                        },
                      ),
                    ),
                  if (owner.title == '历史点单记录')
                    _orderFilter('营业日', _wkdayId, _historyDays, (v) {
                      _wkdayId = v;
                      unawaited(_load());
                    }),
                  if (owner.title == '套餐统计表')
                    _select('订单类型', _setStatus, const {
                      0: '全部订单',
                      1: '未结订单',
                      5: '已结订单',
                    }, (v) => _setStatus = v),
                  if (owner.title == '区域实时营收')
                    _select('区域', _region, {
                      0: '全部',
                      ..._options.regions,
                    }, (v) => _region = v),
                  if (owner.title == '点单记录') ...[
                    _orderFilter(
                      '商品类型',
                      _productType,
                      _data.productTypes,
                      (v) => _productType = v,
                    ),
                    _orderFilter('是否自助', _customerType, const {
                      0: '全部',
                      1: '是',
                      2: '否',
                    }, (v) => _customerType = v),
                    _orderFilter('支付方式', _paymentType, const {
                      0: '全部',
                      1: '线上支付',
                      2: '线上客人自助',
                    }, (v) => _paymentType = v),
                    _orderFilter(
                      '营业类型',
                      _businessType,
                      _data.businessTypes,
                      (v) => _businessType = v,
                    ),
                  ],
                  if (owner.title == '业绩日报表') ...[
                    _select('类型', _group, const {
                      1: '不分组',
                      2: '按部门分组',
                      3: '按区域分组',
                      4: '按直属部门分组',
                      5: '按订位人排名汇总',
                    }, (v) => _group = v),
                    _select('订位部门', _dept, {
                      0: '全部',
                      ..._options.departments,
                    }, (v) => _dept = v),
                    SizedBox(
                      width: 230,
                      child: Autocomplete<int>(
                        key: ValueKey('sales-$_resetKey'),
                        optionsBuilder: (text) {
                          final term = text.text.toLowerCase();
                          return _options.salesEmployees.keys.where(
                            (id) =>
                                '${_options.salesEmployees[id]} ${_options.salesSearchTerms[id] ?? ''} $id'
                                    .toLowerCase()
                                    .contains(term),
                          );
                        },
                        displayStringForOption: (id) =>
                            _options.salesEmployees[id] ?? '',
                        onSelected: (id) => setState(() => _sales = id),
                        fieldViewBuilder: (ctx, controller, focus, submit) =>
                            TextField(
                              controller: controller,
                              focusNode: focus,
                              enabled: allowed && !_busy,
                              decoration: const InputDecoration(
                                labelText: '订位人（姓名/工号/拼音）',
                              ),
                              onChanged: (_) => _sales = 0,
                            ),
                      ),
                    ),
                  ],
                  if (owner.title == '优惠明细表')
                    _select('优惠类型', _discount, const {
                      0: '全部',
                      1: '优惠',
                      2: '优惠2',
                    }, (v) => _discount = v),
                  FilledButton(
                    onPressed: _busy || !allowed || !_canQuery
                        ? null
                        : () {
                            if (!_depositReport) _page = 1;
                            unawaited(_load());
                          },
                    child: Text(owner.title == '套餐统计表' ? '统计' : '查询'),
                  ),
                  if (owner.title != '套餐统计表')
                    TextButton(
                      onPressed: _busy || !allowed
                          ? null
                          : () {
                              if (meta.requiresDateRange) {
                                _resetDates();
                              } else if (!_depositReport) {
                                _keyword.clear();
                              }
                              if (_depositReport) _pageSize = 10;
                              _region = _dept = _sales = _discount = 0;
                              _productType = _businessType = _paymentType =
                                  _customerType = null;
                              _group = _page = 1;
                              if (owner.title == '历史点单记录') {
                                _wkdayId = _historyDays.keys.firstOrNull;
                              }
                              _resetKey++;
                              unawaited(_load());
                            },
                      child: const Text('重置'),
                    ),
                ],
              ),
            ),
          if (owner.title == '套餐统计表' && allowed) _setTree(),
          if (owner.title == '历史点单记录' &&
              _sourceOptionsReady &&
              _historyDays.isEmpty &&
              allowed)
            const Text('暂无可查询营业日'),
          if (owner.title == '转台记录' && allowed) Text('最近刷新时间：$_refreshTime'),
          if (owner.title == '支付记录' && !editable)
            const Text('营业日已结束或当前无操作权限，仅可查看记录'),
          if (_notice != null) Text(_notice!),
          Expanded(
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        if (allowed)
                          TextButton(
                            onPressed: () => unawaited(_load()),
                            child: const Text('重试'),
                          ),
                      ],
                    ),
                  )
                : owner.title == '历史点单记录'
                ? _historyRecords()
                : owner.title == '分类渠道汇总表'
                ? _categoryChannels()
                : owner.title == '非鸡尾酒类补交报表'
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        _relatedTable('补交明细', meta.columns, _data.rows),
                        _relatedTable('渠道汇总', const [
                          '渠道',
                          '笔数',
                          '金额',
                        ], _data.paymentRows),
                      ],
                    ),
                  )
                : _data.rows.isEmpty
                ? const Center(child: Text('暂无记录'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        dataRowMinHeight: 48,
                        dataRowMaxHeight: double.infinity,
                        columns: [
                          for (final col in meta.columns)
                            DataColumn(label: Text(col)),
                          if (owner.title == '支付记录' || _balanceList)
                            const DataColumn(label: Text('操作')),
                        ],
                        rows: [
                          for (final (index, row) in _data.rows.indexed)
                            DataRow(
                              cells: [
                                for (final col in meta.columns)
                                  DataCell(
                                    Text(
                                      col == '序号'
                                          ? '${(_depositReport ? 0 : (_page - 1) * _pageSize) + index + 1}'
                                          : row[col],
                                    ),
                                  ),
                                if (owner.title == '支付记录')
                                  DataCell(
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed:
                                              _canChange(row) &&
                                                  !['', '-'].contains(
                                                    row['订单绑定会员'].trim(),
                                                  )
                                              ? () => unawaited(_unbind(row))
                                              : null,
                                          child: const Text('取消绑定'),
                                        ),
                                        TextButton(
                                          onPressed: _canChange(row)
                                              ? () => unawaited(_edit(row))
                                              : null,
                                          child: const Text('修改订单绑定会员'),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_balanceList)
                                  DataCell(
                                    TextButton(
                                      onPressed:
                                          !allowed ||
                                              _busy ||
                                              (int.tryParse(row.id) ?? 0) <= 0
                                          ? null
                                          : () {
                                              _customerId = row.id;
                                              _notice = null;
                                              unawaited(_load());
                                            },
                                      child: const Text('查看详情'),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
          if (_paginated)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _busy || !allowed || _page <= 1
                      ? null
                      : () {
                          _page--;
                          unawaited(_load());
                        },
                  child: const Text('上一页'),
                ),
                Text('第 $_page 页，共 ${_data.total} 条'),
                TextButton(
                  onPressed:
                      _busy || !allowed || _page * _pageSize >= _data.total
                      ? null
                      : () {
                          _page++;
                          unawaited(_load());
                        },
                  child: const Text('下一页'),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

final class _CashierReportScreenState extends State<CashierReportScreen> {
  final TextEditingController _keywordCtrl = TextEditingController();
  final ScrollController _horizontalCtrl = ScrollController();
  final ScrollController _verticalCtrl = ScrollController();

  List<CashierReportRow> _rows = const [];
  bool _loading = false;
  String? _error;
  int _requestVersion = 0;
  bool get _canRead => widget.canRead?.value ?? true;
  String _startDate = '';
  String _endDate = '';

  CashierReportMeta get _meta =>
      CashierReportCatalog.reports[widget.title] ??
      CashierReportMeta(
        title: widget.title,
        columns: const ['序号', '名称', '数据', '时间', '备注'],
      );

  @override
  void initState() {
    super.initState();
    widget.canRead?.addListener(_accessChanged);
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _startDate = dateStr;
    _endDate = dateStr;
    unawaited(_load());
  }

  @override
  void dispose() {
    _requestVersion++;
    widget.canRead?.removeListener(_accessChanged);
    _keywordCtrl.dispose();
    _horizontalCtrl.dispose();
    _verticalCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_meta.usesQuery) return;
    final version = ++_requestVersion;
    if (!_canRead || !_meta.supported || widget.onLoadData == null) {
      setState(() {
        _loading = false;
        _rows = const [];
        _error = !_canRead
            ? '当前无法读取报表，请检查登录和连接状态'
            : !_meta.supported
            ? '此报表尚未完成迁移，暂不可用'
            : '报表查询服务未连接';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _rows = const [];
    });
    Result<List<CashierReportRow>> res;
    try {
      res = await widget.onLoadData!(
        widget.title,
        _startDate,
        _endDate,
        _keywordCtrl.text.trim(),
      );
    } catch (_) {
      res = const FailureResult(
        AppFailure(
          kind: FailureKind.network,
          code: 'report.load_failed',
          safeMessage: '报表查询失败，请重试',
        ),
      );
    }
    if (!mounted || version != _requestVersion || !_canRead) return;
    setState(() {
      _loading = false;
      _error = res.failureOrNull?.safeMessage;
      if (res.valueOrNull != null) {
        _rows = res.valueOrNull!;
      }
    });
  }

  void _accessChanged() => unawaited(_load());

  @override
  void didUpdateWidget(CashierReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.canRead, widget.canRead)) {
      oldWidget.canRead?.removeListener(_accessChanged);
      widget.canRead?.addListener(_accessChanged);
    }
    if (oldWidget.title != widget.title ||
        oldWidget.onLoadData != widget.onLoadData ||
        !identical(oldWidget.canRead, widget.canRead)) {
      unawaited(_load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    if (widget.title == '查询优惠额度') {
      return CashierQuotaScreen(
        load: widget.onLoadPage,
        canRead: widget.canRead,
      );
    }
    if (meta.usesQuery) {
      return _TypedCashierReportScreen(
        key: ValueKey(widget.title),
        owner: widget,
      );
    }

    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff0D172D),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff141D35),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white70,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (widget.onExport != null)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xff4B89FF),
                ),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('导出Excel'),
                onPressed:
                    _canRead && meta.supported && !_loading && _error == null
                    ? widget.onExport
                    : null,
              ),
            if (widget.onPrint != null)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xff4B89FF),
                ),
                icon: const Icon(Icons.print, size: 18),
                label: const Text('打印报表'),
                onPressed:
                    _canRead && meta.supported && !_loading && _error == null
                    ? widget.onPrint
                    : null,
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // 筛选操作条
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xff141D35),
                border: Border(bottom: BorderSide(color: Color(0xff263352))),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                children: [
                  // 日期范围指示
                  if (meta.requiresDateRange)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff1F2B48),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xff263352)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_startDate 至 $_endDate',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 12),
                  // 关键词搜索
                  if (meta.supportsKeyword)
                    SizedBox(
                      width: 220,
                      height: 36,
                      child: TextField(
                        controller: _keywordCtrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: '搜索关键词/单号/卡台',
                          hintStyle: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          filled: true,
                          fillColor: const Color(0xff1F2B48),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(
                              color: Color(0xff263352),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(
                              color: Color(0xff263352),
                            ),
                          ),
                        ),
                        onSubmitted: (_) => unawaited(_load()),
                      ),
                    ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff2362D5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('查询'),
                    onPressed: _loading || !_canRead || !meta.supported
                        ? null
                        : () => unawaited(_load()),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    tooltip: '刷新',
                    onPressed: _loading || !_canRead || !meta.supported
                        ? null
                        : () => unawaited(_load()),
                  ),
                ],
              ),
            ),

            if (meta.scopeNote.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(meta.scopeNote),
              ),
            // 数据表格区域
            Expanded(
              child: _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!),
                          if (_canRead &&
                              meta.supported &&
                              widget.onLoadData != null)
                            TextButton(
                              onPressed: () => unawaited(_load()),
                              child: const Text('重试'),
                            ),
                        ],
                      ),
                    )
                  : _loading && _rows.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff4B89FF),
                      ),
                    )
                  : _rows.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inbox,
                            size: 48,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${widget.title}暂无相关记录',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Scrollbar(
                      controller: _horizontalCtrl,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _horizontalCtrl,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: meta.columns.length * 120.0 > 800
                              ? meta.columns.length * 120.0
                              : 800,
                          child: Scrollbar(
                            controller: _verticalCtrl,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: _verticalCtrl,
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
                                dividerThickness: 1,
                                columnSpacing: 14,
                                columns: [
                                  for (final col in meta.columns)
                                    DataColumn(label: Text(col)),
                                ],
                                rows: [
                                  for (var i = 0; i < _rows.length; i++)
                                    DataRow(
                                      cells: [
                                        for (final col in meta.columns)
                                          DataCell(
                                            Text(
                                              col == '序号'
                                                  ? '${i + 1}'
                                                  : _rows[i][col],
                                            ),
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),

            // 底部统计汇总栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xff141D35),
                border: Border(top: BorderSide(color: Color(0xff263352))),
              ),
              child: Row(
                children: [
                  Text(
                    '共计 ${_rows.length} 条记录',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '返回卡台大盘',
                      style: TextStyle(color: Color(0xff4B89FF)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
