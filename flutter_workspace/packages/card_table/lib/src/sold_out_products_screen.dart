import 'dart:async';

import 'package:card_table/src/sold_out_products.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:foundation/foundation.dart';

typedef SoldOutListLoader = Future<Result<List<SoldOutItem>>> Function();
typedef SoldOutSetLoader = Future<Result<void>> Function({
  required String productId,
  required int count,
  bool Function()? canDispatch,
});
typedef SoldOutDeleteLoader = Future<Result<void>> Function(
  String productId, {
  bool Function()? canDispatch,
});

final class SoldOutProductsScreen extends StatefulWidget {
  const SoldOutProductsScreen({
    required this.catalog,
    required this.list,
    required this.set,
    required this.delete,
    required this.canRead,
    super.key,
  });

  static const Key searchKey = Key('sold-out-search');
  static const Key countKey = Key('sold-out-count');
  static const Key firstCategoryListKey = Key('sold-out-first-categories');
  static const Key secondCategoryListKey = Key('sold-out-second-categories');

  final SoldOutProductCatalog catalog;
  final SoldOutListLoader list;
  final SoldOutSetLoader set;
  final SoldOutDeleteLoader delete;
  final ValueListenable<bool> canRead;

  @override
  State<SoldOutProductsScreen> createState() => _SoldOutProductsScreenState();
}

final class _SoldOutProductsScreenState extends State<SoldOutProductsScreen> {
  final TextEditingController _keyword = TextEditingController();
  final TextEditingController _count = TextEditingController();
  List<SoldOutItem> _items = const [];
  AppFailure? _failure;
  bool _loading = false;
  bool _mutating = false;
  bool _closed = false;
  bool _readRefreshScheduled = false;
  int _requestVersion = 0;
  String? _firstId;
  String? _secondId;

  @override
  void initState() {
    super.initState();
    widget.canRead.addListener(_readAccessChanged);
    _selectDefaultCategory();
    if (widget.canRead.value) unawaited(_load());
  }

  @override
  void didUpdateWidget(SoldOutProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.canRead, widget.canRead)) {
      oldWidget.canRead.removeListener(_readAccessChanged);
      widget.canRead.addListener(_readAccessChanged);
      _invalidate();
    } else if (oldWidget.list != widget.list) {
      _invalidate();
    }
    if (oldWidget.catalog != widget.catalog) _selectDefaultCategory();
  }

  void _selectDefaultCategory() {
    _firstId = widget.catalog.firstCategories.isEmpty
        ? null
        : widget.catalog.firstCategories.first.id;
    final seconds = _firstId == null
        ? const <SoldOutCategory>[]
        : widget.catalog.secondsOf(_firstId!);
    _secondId = seconds.isEmpty ? null : seconds.first.id;
  }

  void _readAccessChanged() {
    if (!mounted) return;
    if (!widget.canRead.value) _invalidate();
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_readRefreshScheduled) return;
      _readRefreshScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _readRefreshScheduled = false;
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
  }

  void _invalidate() {
    _requestVersion++;
    _items = const [];
    _failure = null;
    _loading = false;
  }

  Future<void> _load() async {
    if (!mounted || !widget.canRead.value || _loading) return;
    final version = ++_requestVersion;
    setState(() {
      _loading = true;
      _failure = null;
    });
    Result<List<SoldOutItem>> result;
    try {
      result = await widget.list();
    } on Object {
      result = const FailureResult(_loadFailure);
    }
    if (!mounted || version != _requestVersion || !widget.canRead.value) return;
    setState(() {
      _loading = false;
      _failure = result.failureOrNull;
      _items = List<SoldOutItem>.unmodifiable(result.valueOrNull ?? const []);
    });
  }

  String _remainingFor(String productId) {
    for (final item in _items) {
      if (item.id == productId) return item.remaining;
    }
    return 'many';
  }

  Future<void> _delete(String productId) async {
    if (_closed || !widget.canRead.value || _mutating) return;
    final version = _requestVersion;
    bool current() =>
        mounted &&
        !_closed &&
        widget.canRead.value &&
        version == _requestVersion;
    setState(() => _mutating = true);
    Result<void> result;
    try {
      result = await widget.delete(productId, canDispatch: current);
    } on Object {
      result = const FailureResult(_loadFailure);
    }
    if (!mounted) return;
    setState(() => _mutating = false);
    if (!current()) return;
    if (result.failureOrNull case final failure?) {
      _show(failure.safeMessage);
      return;
    }
    await _load();
  }

  Future<void> _openQuantity(SoldOutProduct product) async {
    if (_closed || !widget.canRead.value || _mutating) return;
    final version = _requestVersion;
    _count.text = '0';
    final action = await showDialog<_QuantityAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('估清数量'),
        content: TextField(
          key: SoldOutProductsScreen.countKey,
          controller: _count,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, const _QuantityAction.delete()),
            child: const Text('解除沽清'),
          ),
          FilledButton(
            onPressed: () {
              final raw = _count.text;
              if (raw.contains('.')) {
                _show('商品数量必须为整数');
                return;
              }
              final parsed = raw.isEmpty ? 0 : int.tryParse(raw);
              if (parsed == null) {
                _show('请输入数字！');
                return;
              }
              Navigator.pop(context, _QuantityAction.set(parsed));
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (!mounted ||
        _closed ||
        action == null ||
        !widget.canRead.value ||
        version != _requestVersion) {
      return;
    }
    if (action.delete) {
      await _delete(product.id);
      return;
    }
    if (action.count case final count?) await _set(product.id, count);
  }

  Future<void> _set(String productId, int count) async {
    if (_closed || !widget.canRead.value || _mutating) return;
    final version = _requestVersion;
    bool current() =>
        mounted &&
        !_closed &&
        widget.canRead.value &&
        version == _requestVersion;
    setState(() => _mutating = true);
    Result<void> result;
    try {
      result = await widget.set(
        productId: productId,
        count: count,
        canDispatch: current,
      );
    } on Object {
      result = const FailureResult(_loadFailure);
    }
    if (!mounted) return;
    setState(() => _mutating = false);
    if (!current()) return;
    if (result.failureOrNull case final failure?) {
      _show(failure.safeMessage);
      return;
    }
    _show('添加估清商品成功');
    await _load();
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _close() => unawaited(Navigator.of(context).maybePop());

  @override
  void dispose() {
    _requestVersion++;
    widget.canRead.removeListener(_readAccessChanged);
    _keyword.dispose();
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readable = widget.canRead.value;
    final firstId = _firstId ?? '';
    final secondId = _secondId ?? '';
    final visible = readable
        ? widget.catalog.search(
            keyword: _keyword.text,
            firstId: firstId,
            secondId: secondId,
          )
        : const <SoldOutProduct>[];
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _closed = true;
          _invalidate();
        }
      },
      child: Theme(
        data: ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3373E8)),
        ),
        child: Scaffold(
          backgroundColor: const Color(0xffFAFAFC),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '估清商品',
                      style: TextStyle(fontSize: 24, color: Color(0xff08080A)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: readable
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              final stacked = constraints.maxWidth < 960;
                              final catalog = _catalog(visible);
                              final selected = _selected();
                              if (stacked) {
                                return Column(
                                  children: [
                                    Expanded(flex: 3, child: catalog),
                                    const SizedBox(height: 8),
                                    Expanded(flex: 2, child: selected),
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 3, child: catalog),
                                  const SizedBox(width: 8),
                                  Expanded(flex: 2, child: selected),
                                ],
                              );
                            },
                          )
                        : const Center(child: Text('当前不可维护估清商品')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _catalog(List<SoldOutProduct> visible) {
    final seconds = _firstId == null
        ? const <SoldOutCategory>[]
        : widget.catalog.secondsOf(_firstId!);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 84,
          child: _categoryColumn(
            key: SoldOutProductsScreen.firstCategoryListKey,
            items: widget.catalog.firstCategories,
            selectedId: _firstId,
            onSelect: (item) => setState(() {
              _firstId = item.id;
              final next = widget.catalog.secondsOf(item.id);
              _secondId = next.isEmpty ? null : next.first.id;
              _keyword.clear();
            }),
          ),
        ),
        SizedBox(
          width: 96,
          child: _categoryColumn(
            key: SoldOutProductsScreen.secondCategoryListKey,
            items: seconds,
            selectedId: _secondId,
            onSelect: (item) => setState(() => _secondId = item.id),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              TextField(
                key: SoldOutProductsScreen.searchKey,
                controller: _keyword,
                enabled: widget.canRead.value && !_loading,
                decoration: const InputDecoration(
                  hintText: '请输入商品名称或简写',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final product = visible[index];
                    final remaining = _remainingFor(product.id);
                    return Material(
                      color: remaining == '0'
                          ? const Color(0xffDCE1EA)
                          : const Color(0xffECEFF4),
                      child: InkWell(
                        onTap: () => unawaited(_openQuantity(product)),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xff08080A),
                                ),
                              ),
                              Text(
                                product.nameEng,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xff6B7280),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      remaining == 'many' ? '' : '余:$remaining',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    product.priceLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryColumn({
    required Key key,
    required List<SoldOutCategory> items,
    required String? selectedId,
    required ValueChanged<SoldOutCategory> onSelect,
  }) => ColoredBox(
    color: const Color(0xffECEFF4),
    child: ListView(
      key: key,
      children: [
        for (final item in items)
          Material(
            color: item.id == selectedId
                ? const Color(0xff3373E8)
                : Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
                child: Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: item.id == selectedId
                        ? Colors.white
                        : const Color(0xff08080A),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _selected() => ColoredBox(
    color: const Color(0xffFFFFFF),
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('估清商品', style: TextStyle(fontSize: 18)),
          ),
        ),
        const Row(
          children: [
            Expanded(
              child: Text('商品名称', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              child: Text(
                '剩余估清数量',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text('操作', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xff3373E8)),
                )
              : _failure != null
              ? Center(child: Text(_failure!.safeMessage))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item.remaining,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => unawaited(_delete(item.id)),
                                  child: const Text(
                                    '删除',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Color(0xff2170ff)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (item.require.isNotEmpty)
                            Text(
                              item.require,
                              style: const TextStyle(color: Color(0xff6B7280)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(onPressed: _close, child: const Text('取消')),
            const SizedBox(width: 8),
            FilledButton(onPressed: _close, child: const Text('确定')),
          ],
        ),
      ],
    ),
  );

  static const AppFailure _loadFailure = AppFailure(
    kind: FailureKind.unknown,
    code: 'sold_out_products.load_failed',
    safeMessage: '估清商品操作失败，请重试',
  );
}

final class _QuantityAction {
  const _QuantityAction.delete() : delete = true, count = null;
  const _QuantityAction.set(this.count) : delete = false;

  final bool delete;
  final int? count;
}
