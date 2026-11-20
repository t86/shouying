import 'dart:async';

import 'package:card_table/src/erp_loader.dart';
import 'package:card_table/src/erp_models.dart';
import 'package:card_table/src/erp_sout_workflow.dart';
import 'package:foundation/foundation.dart';
import 'package:flutter/material.dart';

/// Shared manual stock-entry form. The two directions keep distinct source
/// endpoints and payloads; no material is created or guessed in this form.
class ErpStockEntryDialog extends StatefulWidget {
  const ErpStockEntryDialog({
    required this.loader,
    required this.outgoing,
    this.copySourceId,
    super.key,
  });
  final ErpLoader loader;
  final bool outgoing;
  final String? copySourceId;
  @override
  State<ErpStockEntryDialog> createState() => _ErpStockEntryDialogState();
}

class _ErpStockEntryDialogState extends State<ErpStockEntryDialog> {
  final _search = TextEditingController(), _remark = TextEditingController();
  List<ErpStoreItem> _stores = [];
  List<ErpSupplierItem> _suppliers = [];
  List<ErpStockMaterial> _candidates = [];
  final _lines = <_StockEntryLine>[];
  String? _store, _supplier, _error;
  int? _type, _invoice;
  bool _busy = false, _optionsLoaded = false;
  Object? _session;
  bool _active = true, _uncertain = false;
  bool get _current => mounted && _active && (!widget.outgoing || widget.loader is! ErpSoutWorkflowLoader ||
    (_session != null && _session == (widget.loader as ErpSoutWorkflowLoader).soutContext));
  @override
  void initState() {
    super.initState();
    if(widget.loader is ErpSoutWorkflowLoader) _session=(widget.loader as ErpSoutWorkflowLoader).soutContext;
    unawaited(_loadOptions());
  }

  @override
  void dispose() {
    _active=false;
    _search.dispose();
    _remark.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.outgoing && widget.copySourceId != null) {
        if(widget.loader is! ErpSoutWorkflowLoader)throw const FormatException();
        final result=await (widget.loader as ErpSoutWorkflowLoader).loadOtherOutDocument(widget.copySourceId!,ErpSoutDocumentMode.copy);
        if(!_current)return;
        if(result.failureOrNull case final f?){_error=f.safeMessage;}else{
          final doc=result.valueOrNull!,data=result.valueOrNull!.data;
          final stores=erpSoutRows(data['stores']).map(ErpStoreItem.fromWire).toList();
          final store='${data['store_id']}',type=int.tryParse('${data['record_type']}');
          if(!stores.any((s)=>s.id==store)||![11,17,52,62,72].contains(type))throw const FormatException();
          final lines=<_StockEntryLine>[];
          for(final row in doc.lines){
            final candidates=await widget.loader.searchStockMaterials(outgoing:true,keyword:'${row['n']??''}',storeId:store);
            if(!_current)return;
            if(candidates.failureOrNull!=null)throw const FormatException();
            final matches=(candidates.valueOrNull??[]).where((m)=>m.id=='${row['id']}').toList();
            if(matches.length!=1)throw const FormatException();
            final stock=matches.single.stockCount,count=double.tryParse('${row['c']}'),price=double.tryParse('${row['sa']}');
            if(!stock.isFinite||stock<0||count==null||!count.isFinite||count<0||price==null||!price.isFinite||price<0)throw const FormatException();
            final line=_StockEntryLine(ErpStockMaterial(id:'${row['id']}',name:'${row['n']??''}',oneCateName:'${row['moc']??''}',twoCateName:'${row['mtc']??''}',unitName:'${row['un']??''}',stockCount:stock,stockAmount:stock*price),true);
            line.quantity.text='$count';line.value.text='$price';lines.add(line);
          }
          for(final l in _lines){l.dispose();}
          _lines..clear()..addAll(lines);_stores=stores;_store=store;_type=type;_remark.text='${data['remark']??''}';
        }
      } else if (widget.outgoing) {
        final result = await widget.loader.loadSoutStores();
        if (!_current) return;
        _error = result.failureOrNull?.safeMessage;
        _stores = result.valueOrNull ?? [];
      } else {
        final result = await widget.loader.loadSinOptions();
        if (!mounted) return;
        _error = result.failureOrNull?.safeMessage;
        _stores = result.valueOrNull?.stores ?? [];
        _suppliers = result.valueOrNull?.suppliers ?? [];
      }
      _optionsLoaded = _error == null;
    } on Object {
      if (mounted) _error = '仓库数据加载失败，请重试';
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _findMaterials() async {
    if (_busy || !_current) return;
    if (_search.text.trim().isEmpty) {
      setState(() {
        _candidates = [];
        _error = '请输入物料名称或拼音关键字';
      });
      return;
    }
    if (widget.outgoing && _store == null) {
      setState(() => _error = '请先选择出库仓库');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.loader.searchStockMaterials(
        outgoing: widget.outgoing,
        keyword: _search.text.trim(),
        storeId: _store ?? '',
      );
      if (!_current) return;
      setState(() {
        _candidates = result.valueOrNull ?? [];
        _error = result.failureOrNull?.safeMessage;
      });
    } on Object {
      if (mounted) setState(() => _error = '物料查询失败，请重试');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _setStore(String? id) async {
    if (id == _store) return;
    if (widget.outgoing && _lines.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('切换出库仓库'),
          content: const Text('物料库存与仓库关联，切换将清空已选物料。是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('继续'),
            ),
          ],
        ),
      );
      if (confirmed != true || !_current) return;
      for (final line in _lines) {
        line.dispose();
      }
      _lines.clear();
    }
    if (mounted) {
      setState(() {
        _store = id;
        _candidates = [];
      });
    }
  }

  void _addMaterial(ErpStockMaterial material) {
    if (_busy || _lines.any((line) => line.material.id == material.id)) return;
    if ((int.tryParse(material.id) ?? 0) <= 0 ||
        !material.stockCount.isFinite ||
        !material.unitCost.isFinite) {
      setState(() => _error = '物料数据无效，请重新查询');
      return;
    }
    setState(() {
      _lines.add(_StockEntryLine(material, widget.outgoing));
      _candidates = [];
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy || !_optionsLoaded || _uncertain) return;
    if(!_current){if(mounted)setState(()=>_error='登录或连接已变化，请重新打开');return;}
    final storeId = int.tryParse(_store ?? '');
    if (storeId == null ||
        storeId <= 0 ||
        _type == null ||
        (!widget.outgoing &&
            (_invoice == null ||
                (_type != 7 && (int.tryParse(_supplier ?? '') ?? 0) <= 0)))) {
      setState(() => _error = '必选框不能为空');
      return;
    }
    if (_lines.isEmpty) {
      setState(() => _error = '请先搜索并选择真实物料');
      return;
    }
    final counts = <double>[], amounts = <String>[], sourceAmounts = <String>[];
    for (final line in _lines) {
      final quantity = double.tryParse(line.quantity.text),
          value = double.tryParse(line.value.text);
      if (quantity == null ||
          !quantity.isFinite ||
          quantity <= 0 ||
          value == null ||
          !value.isFinite ||
          value < 0) {
        setState(() => _error = '数量必须大于0，金额或价格必须为非负数字');
        return;
      }
      if (widget.outgoing && quantity > line.material.stockCount) {
        setState(() => _error = '最大数量不可超过库存数量');
        return;
      }
      final amount = widget.outgoing ? quantity * value : value;
      if (!amount.isFinite) {
        setState(() => _error = '金额超出有效范围');
        return;
      }
      counts.add(quantity);
      sourceAmounts.add(amount.toStringAsFixed(2));
      amounts.add(
        (!widget.outgoing && _invoice == 2 ? amount / 1.13 : amount)
            .toStringAsFixed(2),
      );
    }
    final payload = <String, Object?>{
      'store_id': storeId,
      'record_type': _type,
      'remark': _remark.text,
      'mat_ids': _lines.map((line) => int.parse(line.material.id)).toList(),
      'cnts': counts,
      'amts': amounts,
      if (!widget.outgoing)
        'supplier_id': _type == 7 ? '' : int.parse(_supplier!),
      if (!widget.outgoing) 'fapiao_type': _invoice,
      if (!widget.outgoing) 'src_amts': sourceAmounts,
    };
    final route = ModalRoute.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = widget.outgoing
          ? await widget.loader.createSoutOrder(payload)
          : await widget.loader.createSinOrder(payload);
      if (!mounted || !_current) return;
      if (result.failureOrNull != null) {
        final f=result.failureOrNull!;
        if(widget.outgoing&&f.kind!=FailureKind.business){_uncertain=true;}
        setState(() => _error = _uncertain?'提交结果不确定，请关闭后查询列表核实，勿重复创建':f.safeMessage);
      } else if (route?.isActive == true) {
        _active = false;
        Navigator.of(context).removeRoute(route!, true);
        return;
      }
    } on Object {
      if (mounted) setState(() {_uncertain=widget.outgoing;_error=widget.outgoing?'提交结果不确定，请查询列表核实，勿重复创建':'创建失败，请重试';});
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final types = widget.outgoing
        ? const {11: '销售出库', 17: '其他出库', 52: '盘亏出库', 62: '报损出库', 72: '供应商回收'}
        : const {1: '采购入库', 7: '其他入库', 51: '盘盈入库', 21: '充公入库'};
    return PopScope<bool>(onPopInvokedWithResult:(didPop,_){if(didPop)_active=false;},child:Dialog(
      child: SizedBox(
        width: 1100,
        height: MediaQuery.sizeOf(context).height * .85,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.copySourceId!=null?'类似创建其他出库':widget.outgoing ? '新建其他出库单' : '新建其他入库单',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_busy) const LinearProgressIndicator(),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (!_optionsLoaded && !_busy)
                TextButton(
                  onPressed: _loadOptions,
                  child: const Text('重试加载仓库'),
                ),
              Wrap(
                spacing: 18,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<String>(
                    key: const Key('erp-stock-store'),
                    value: _store,
                    hint: const Text('请选择仓库'),
                    items: _stores
                        .map(
                          (store) => DropdownMenuItem(
                            value: store.id,
                            child: Text(store.name),
                          ),
                        )
                        .toList(),
                    onChanged: _busy ? null : _setStore,
                  ),
                  DropdownButton<int>(
                    key: const Key('erp-stock-type'),
                    value: _type,
                    hint: Text(widget.outgoing ? '出库类型' : '入库类型'),
                    items: types.entries
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.key,
                            child: Text(item.value),
                          ),
                        )
                        .toList(),
                    onChanged: _busy
                        ? null
                        : (v) => setState(() {
                            _type = v;
                            if (v == 7) _supplier = null;
                          }),
                  ),
                  if (!widget.outgoing)
                    DropdownButton<int>(
                      key: const Key('erp-stock-invoice'),
                      value: _invoice,
                      hint: const Text('发票类型'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('普票')),
                        DropdownMenuItem(value: 2, child: Text('专票')),
                      ],
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _invoice = v),
                    ),
                  if (!widget.outgoing)
                    DropdownButton<String>(
                      key: const Key('erp-stock-supplier'),
                      value: _supplier,
                      hint: const Text('供应商'),
                      items: _suppliers
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: _busy || _type == 7
                          ? null
                          : (v) => setState(() => _supplier = v),
                    ),
                ],
              ),
              TextField(
                controller: _remark,
                enabled: !_busy,
                decoration: const InputDecoration(labelText: '备注'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('erp-stock-search'),
                      controller: _search,
                      enabled: !_busy && _optionsLoaded,
                      decoration: const InputDecoration(
                        labelText: '物料名称/拼音关键字',
                      ),
                      onSubmitted: (_) => unawaited(_findMaterials()),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy || !_optionsLoaded ? null : _findMaterials,
                    child: const Text('搜索物料'),
                  ),
                ],
              ),
              if (_candidates.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView(
                    children: [
                      for (final material in _candidates)
                        ListTile(
                          key: Key('erp-stock-candidate-${material.id}'),
                          title: Text(material.name),
                          subtitle: Text(
                            '${material.oneCateName} / ${material.twoCateName} · ${material.unitName} · 库存 ${material.stockCount}',
                          ),
                          enabled: !_lines.any(
                            (line) => line.material.id == material.id,
                          ),
                          onTap: () => _addMaterial(material),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: _lines.isEmpty
                    ? const Center(child: Text('请搜索并选择真实物料'))
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final line in _lines)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${line.material.name} · ${line.material.oneCateName}/${line.material.twoCateName} · 单位 ${line.material.unitName}${widget.outgoing ? ' · 当前库存 ${line.material.stockCount}' : ''}',
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: _busy
                                                ? null
                                                : () => setState(() {
                                                    _lines.remove(line);
                                                    line.dispose();
                                                  }),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              key: Key(
                                                'erp-stock-quantity-${line.material.id}',
                                              ),
                                              controller: line.quantity,
                                              enabled: !_busy,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: '数量',
                                              ),
                                              onChanged: (_) => setState(() {
                                                if (!widget.outgoing) {
                                                  final count = double.tryParse(
                                                    line.quantity.text,
                                                  );
                                                  if (count != null &&
                                                      count.isFinite) {
                                                    line.value.text =
                                                        (count * line.unitPrice)
                                                            .toStringAsFixed(2);
                                                  }
                                                }
                                              }),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: TextField(
                                              key: Key(
                                                'erp-stock-value-${line.material.id}',
                                              ),
                                              controller: line.value,
                                              enabled: !_busy,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: widget.outgoing
                                                    ? '出库价格'
                                                    : '入库小计（含税）',
                                              ),
                                              onChanged: (_) => setState(() {
                                                if (!widget.outgoing) {
                                                  final q = double.tryParse(
                                                        line.quantity.text,
                                                      ),
                                                      v = double.tryParse(
                                                        line.value.text,
                                                      );
                                                  if (q != null &&
                                                      q > 0 &&
                                                      v != null &&
                                                      v.isFinite) {
                                                    line.unitPrice =
                                                        double.parse(
                                                          (v / q)
                                                              .toStringAsFixed(
                                                                4,
                                                              ),
                                                        );
                                                  }
                                                }
                                              }),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        widget.outgoing
                                            ? '出库小计：${((double.tryParse(line.quantity.text) ?? 0) * (double.tryParse(line.value.text) ?? 0)).toStringAsFixed(2)}'
                                            : '入库单价：${(_invoice == 2 ? line.unitPrice / 1.13 : line.unitPrice).toStringAsFixed(2)}${_invoice == 2 ? ' · 裸价小计：${((double.tryParse(line.value.text) ?? 0) / 1.13).toStringAsFixed(2)}' : ''}',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {_active=false;Navigator.pop(context, false);},
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: _busy || !_optionsLoaded || _uncertain ? null : _submit,
                    child: Text(widget.outgoing ? '提交出库' : '提交入库'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class _StockEntryLine {
  _StockEntryLine(this.material, bool outgoing)
    : quantity = TextEditingController(text: '1'),
      value = TextEditingController(
        text: outgoing ? '' : material.unitCost.toStringAsFixed(2),
      ),
      unitPrice = double.parse(material.unitCost.toStringAsFixed(4));
  final ErpStockMaterial material;
  final TextEditingController quantity, value;
  double unitPrice;
  void dispose() {
    quantity.dispose();
    value.dispose();
  }
}

// =============================================================================
// S8.P2.T01 / T02 其他入库列表与新建其他入库/物料检索
// =============================================================================

class ErpAnotherInLibView extends StatefulWidget {
  const ErpAnotherInLibView({required this.loader, super.key});
  final ErpLoader loader;

  @override
  State<ErpAnotherInLibView> createState() => _ErpAnotherInLibViewState();
}

class _ErpAnotherInLibViewState extends State<ErpAnotherInLibView> {
  bool _loading = false;
  String? _error;
  List<ErpSinItem> _items = const [];
  int? _selectedStatus;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadSinList(status: _selectedStatus);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res.valueOrNull ?? [];
      _error = res.failureOrNull?.safeMessage;
    });
  }

  Future<void> _openNewSinDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) =>
          ErpStockEntryDialog(loader: widget.loader, outgoing: false),
    );
    if (created == true && mounted) await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          Row(
            children: [
              Text('其他入库', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              FilledButton.icon(
                onPressed: _openNewSinDialog,
                icon: const Icon(Icons.add),
                label: const Text('新建其他入库单'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ChoiceChip(
                label: const Text('全部'),
                selected: _selectedStatus == null,
                onSelected: (v) {
                  if (v) {
                    setState(() => _selectedStatus = null);
                    unawaited(_loadData());
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('已审核'),
                selected: _selectedStatus == 1,
                onSelected: (v) {
                  if (v) {
                    setState(() => _selectedStatus = 1);
                    unawaited(_loadData());
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('已红冲'),
                selected: _selectedStatus == 2,
                onSelected: (v) {
                  if (v) {
                    setState(() => _selectedStatus = 2);
                    unawaited(_loadData());
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('序号')),
                          DataColumn(label: Text('单号')),
                          DataColumn(label: Text('入库仓库')),
                          DataColumn(label: Text('入库日期')),
                          DataColumn(label: Text('制单人')),
                          DataColumn(label: Text('状态')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: [
                          for (var i = 0; i < _items.length; i++)
                            DataRow(
                              cells: [
                                DataCell(Text('${i + 1}')),
                                DataCell(Text(_items[i].code)),
                                DataCell(Text(_items[i].storeName)),
                                DataCell(Text(_items[i].billDay)),
                                DataCell(Text(_items[i].operName)),
                                DataCell(
                                  Text(
                                    _items[i].status == 1
                                        ? '已审核'
                                        : _items[i].status == 2
                                        ? '已红冲'
                                        : '—',
                                    style: TextStyle(
                                      color: _items[i].status == 1
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      if (_items[i].status == 1) ...[
                                        TextButton(
                                          onPressed: () async {
                                            await widget.loader.reverseSinOrder(
                                              _items[i].id,
                                            );
                                            unawaited(_loadData());
                                          },
                                          child: const Text('反审核'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await widget.loader
                                                .redPunchSinOrder(_items[i].id);
                                            unawaited(_loadData());
                                          },
                                          child: const Text(
                                            '红冲',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ],
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
      ),
    );
  }
}

// =============================================================================
// S8.P2.T03 调拨入库
// =============================================================================

class ErpChangeInLibView extends StatefulWidget {
  const ErpChangeInLibView({required this.loader, super.key});
  final ErpLoader loader;

  @override
  State<ErpChangeInLibView> createState() => _ErpChangeInLibViewState();
}

class _ErpChangeInLibViewState extends State<ErpChangeInLibView> {
  bool _loading = false;
  List<ErpSindItem> _items = const [];
  int? _selectedStatus; // 3: 未处理, 1: 已完成, 4: 异议中

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadSindList(status: _selectedStatus);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res.valueOrNull ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('调拨入库', style: Theme.of(context).textTheme.headlineSmall),
              FilledButton.icon(
                onPressed: () async {
                  final ids = _items
                      .where((i) => i.status == 3)
                      .map((i) => i.id)
                      .toList();
                  if (ids.isEmpty) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('暂无待入库的调拨单')));
                    return;
                  }
                  await widget.loader.batchSindIn(ids);
                  unawaited(_loadData());
                },
                icon: const Icon(Icons.done_all),
                label: const Text('批量全部入库'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ChoiceChip(
                label: const Text('全部'),
                selected: _selectedStatus == null,
                onSelected: (v) {
                  if (v) {
                    setState(() => _selectedStatus = null);
                    unawaited(_loadData());
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('未处理'),
                selected: _selectedStatus == 3,
                onSelected: (v) {
                  if (v) {
                    setState(() => _selectedStatus = 3);
                    unawaited(_loadData());
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('已完成'),
                selected: _selectedStatus == 1,
                onSelected: (v) {
                  if (v) {
                    setState(() => _selectedStatus = 1);
                    unawaited(_loadData());
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('异议中'),
                selected: _selectedStatus == 4,
                onSelected: (v) {
                  if (v) {
                    setState(() => _selectedStatus = 4);
                    unawaited(_loadData());
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('序号')),
                          DataColumn(label: Text('单号')),
                          DataColumn(label: Text('出库仓库')),
                          DataColumn(label: Text('入库仓库')),
                          DataColumn(label: Text('调拨日期')),
                          DataColumn(label: Text('制单人')),
                          DataColumn(label: Text('状态')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: [
                          for (var i = 0; i < _items.length; i++)
                            DataRow(
                              cells: [
                                DataCell(Text('${i + 1}')),
                                DataCell(Text(_items[i].code)),
                                DataCell(Text(_items[i].outStoreName)),
                                DataCell(Text(_items[i].inStoreName)),
                                DataCell(Text(_items[i].billDay)),
                                DataCell(Text(_items[i].operName)),
                                DataCell(
                                  Text(
                                    switch (_items[i].status) {
                                      3 => '未处理',
                                      1 => '已完成',
                                      4 => '异议中',
                                      _ => '未知',
                                    },
                                    style: TextStyle(
                                      color: switch (_items[i].status) {
                                        3 => Colors.orange,
                                        1 => Colors.green,
                                        4 => Colors.redAccent,
                                        _ => Colors.grey,
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      if (_items[i].status == 3) ...[
                                        TextButton(
                                          onPressed: () async {
                                            await widget.loader.batchSindIn([
                                              _items[i].id,
                                            ]);
                                            unawaited(_loadData());
                                          },
                                          child: const Text('确认入库'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await widget.loader.applySindSh({
                                              'id': _items[i].id,
                                              'memo': '申请入库异议',
                                            });
                                            unawaited(_loadData());
                                          },
                                          child: const Text(
                                            '申请异议',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
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
      ),
    );
  }
}

// =============================================================================
// S8.P2.T04 入库异议订单
// =============================================================================

class ErpApplyForInLibView extends StatefulWidget {
  const ErpApplyForInLibView({required this.loader, super.key});
  final ErpLoader loader;

  @override
  State<ErpApplyForInLibView> createState() => _ErpApplyForInLibViewState();
}

class _ErpApplyForInLibViewState extends State<ErpApplyForInLibView> {
  bool _loading = false;
  List<ErpDisputeItem> _items = const [];
  int _orderStatus = 3; // 0: 全部, 3: 待处理, 2: 已处理, 1: 已完成
  int _activeDays = 1; // 1: 7天, 2: 30天, 3: 90天

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadDisputeInList(
      status: _orderStatus == 0 ? null : _orderStatus,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res.valueOrNull ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('入库异议订单', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('状态：', style: TextStyle(fontWeight: FontWeight.bold)),
              for (final entry in [
                (0, '全部'),
                (3, '待处理'),
                (2, '已处理'),
                (1, '已完成'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.$2),
                    selected: _orderStatus == entry.$1,
                    onSelected: (v) {
                      if (v) {
                        setState(() => _orderStatus = entry.$1);
                        unawaited(_loadData());
                      }
                    },
                  ),
                ),
              const SizedBox(width: 16),
              const Text('跨度：', style: TextStyle(fontWeight: FontWeight.bold)),
              for (final entry in [(1, '近7天'), (2, '近30天'), (3, '近90天')])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.$2),
                    selected: _activeDays == entry.$1,
                    onSelected: (v) {
                      if (v) {
                        setState(() => _activeDays = entry.$1);
                        unawaited(_loadData());
                      }
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('序号')),
                          DataColumn(label: Text('单号')),
                          DataColumn(label: Text('子单号')),
                          DataColumn(label: Text('物料名称')),
                          DataColumn(label: Text('一级分类')),
                          DataColumn(label: Text('异议数量')),
                          DataColumn(label: Text('状态')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: [
                          for (var i = 0; i < _items.length; i++)
                            DataRow(
                              cells: [
                                DataCell(Text('${i + 1}')),
                                DataCell(Text(_items[i].code)),
                                DataCell(Text(_items[i].subCode)),
                                DataCell(Text(_items[i].matName)),
                                DataCell(Text(_items[i].oneCate)),
                                DataCell(
                                  Text(
                                    '${_items[i].diffCount}',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    switch (_items[i].status) {
                                      3 => '待处理',
                                      2 => '已处理',
                                      1 => '已完成',
                                      _ => '未知',
                                    },
                                    style: TextStyle(
                                      color: switch (_items[i].status) {
                                        3 => Colors.orange,
                                        2 => Colors.blue,
                                        1 => Colors.green,
                                        _ => Colors.grey,
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      if (_items[i].status == 3) ...[
                                        TextButton(
                                          onPressed: () async {
                                            await widget.loader
                                                .confirmDisputeIn(_items[i].id);
                                            unawaited(_loadData());
                                          },
                                          child: const Text('确认无异议'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await widget.loader.cancelDisputeIn(
                                              _items[i].id,
                                            );
                                            unawaited(_loadData());
                                          },
                                          child: const Text('撤销异议'),
                                        ),
                                      ],
                                    ],
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
      ),
    );
  }
}
