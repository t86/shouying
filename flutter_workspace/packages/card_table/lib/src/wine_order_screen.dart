import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/wine_order.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';

enum WineOrderAction { save, take, confiscate }

typedef WineListCsms = Future<Result<List<WineSaveCsm>>> Function(String seatId);

typedef WineSubmitSave =
    Future<Result<void>> Function({
      required List<String> cartIds,
      required String phone,
      required String name,
      required String authCode,
    });

typedef WineSubmitTake =
    Future<Result<void>> Function({
      required String seatId,
      required List<String> inventoryIds,
      required List<int> counts,
      required String phone,
      required String authCode,
    });

typedef WineSubmitConfiscate =
    Future<Result<void>> Function({
      required String seatId,
      required String date,
      required String salesEmpId,
      required List<String> productIds,
      required List<String> unitTypes,
      required List<int> counts,
      required List<int> grams,
    });

final class WineOrderScreen extends StatefulWidget {
  const WineOrderScreen({
    required this.table,
    required this.action,
    this.listCsms,
    this.submitSave,
    this.submitTake,
    this.submitConfiscate,
    super.key,
  });

  static const Key cartIdsKey = Key('wine-order-ids');
  static const Key authCodeKey = Key('wine-order-auth');
  static const Key phoneKey = Key('wine-order-phone');
  static const Key salesEmpKey = Key('wine-order-sales');

  final CardTable table;
  final WineOrderAction action;
  final WineListCsms? listCsms;
  final WineSubmitSave? submitSave;
  final WineSubmitTake? submitTake;
  final WineSubmitConfiscate? submitConfiscate;

  @override
  State<WineOrderScreen> createState() => _WineOrderScreenState();
}

final class _WineOrderScreenState extends State<WineOrderScreen> {
  final TextEditingController _ids = TextEditingController();
  final TextEditingController _auth = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _sales = TextEditingController();
  List<WineSaveCsm> _csms = const [];
  WineSaveCsm? _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.action == WineOrderAction.save) {
      _loadCsms();
    }
  }

  @override
  void dispose() {
    _ids.dispose();
    _auth.dispose();
    _phone.dispose();
    _sales.dispose();
    super.dispose();
  }

  String get _title => switch (widget.action) {
    WineOrderAction.save => '存酒',
    WineOrderAction.take => '取酒',
    WineOrderAction.confiscate => '充公',
  };

  Future<void> _loadCsms() async {
    final load = widget.listCsms;
    if (load == null) return;
    final result = await load(widget.table.id);
    if (!mounted) return;
    final rows = result.valueOrNull ?? const <WineSaveCsm>[];
    setState(() {
      _csms = rows;
      _selected = rows.isEmpty ? null : rows.first;
      if (_selected != null) {
        _phone.text = _selected!.phone;
      }
    });
    if (result.failureOrNull != null) {
      _show(result.failureOrNull!.safeMessage);
    }
  }

  List<String> get _idList =>
      _ids.text.split(RegExp(r'[,，\s]+')).where((id) => id.isNotEmpty).toList();

  Future<void> _submit() async {
    setState(() => _busy = true);
    final Result<void> result;
    switch (widget.action) {
      case WineOrderAction.save:
        final csm = _selected;
        final save = widget.submitSave;
        if (csm == null || save == null || _idList.isEmpty) {
          setState(() => _busy = false);
          _show('请选择流水并填写购物车Id');
          return;
        }
        result = await save(
          cartIds: _idList,
          phone: csm.phone,
          name: csm.name,
          authCode: _auth.text.trim(),
        );
      case WineOrderAction.take:
        final take = widget.submitTake;
        if (take == null || _idList.isEmpty || _phone.text.trim().isEmpty) {
          setState(() => _busy = false);
          _show('请填写手机号和库存Id');
          return;
        }
        result = await take(
          seatId: widget.table.id,
          inventoryIds: _idList,
          counts: List<int>.filled(_idList.length, 1),
          phone: _phone.text.trim(),
          authCode: _auth.text.trim(),
        );
      case WineOrderAction.confiscate:
        final confiscate = widget.submitConfiscate;
        if (confiscate == null ||
            _idList.isEmpty ||
            _sales.text.trim().isEmpty) {
          setState(() => _busy = false);
          _show('请填写订位人Id和商品Id');
          return;
        }
        final now = DateTime.now();
        final date =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        result = await confiscate(
          seatId: widget.table.id,
          date: date,
          salesEmpId: _sales.text.trim(),
          productIds: _idList,
          unitTypes: List<String>.filled(_idList.length, '1'),
          counts: List<int>.filled(_idList.length, 1),
          grams: List<int>.filled(_idList.length, 0),
        );
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.failureOrNull != null) {
      _show(result.failureOrNull!.safeMessage);
      return;
    }
    _show('$_title成功');
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3373E8)),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text('${widget.table.name} $_title')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.action == WineOrderAction.save)
              for (final csm in _csms)
                RadioListTile<WineSaveCsm>(
                  value: csm,
                  groupValue: _selected,
                  title: Text(csm.name),
                  subtitle: Text(csm.phone),
                  onChanged: (value) => setState(() {
                    _selected = value;
                    _phone.text = value?.phone ?? '';
                  }),
                ),
            if (widget.action == WineOrderAction.take)
              TextField(
                key: WineOrderScreen.phoneKey,
                controller: _phone,
                decoration: const InputDecoration(labelText: '客户手机号'),
              ),
            if (widget.action == WineOrderAction.confiscate)
              TextField(
                key: WineOrderScreen.salesEmpKey,
                controller: _sales,
                decoration: const InputDecoration(labelText: '订位人Id'),
              ),
            TextField(
              key: WineOrderScreen.cartIdsKey,
              controller: _ids,
              decoration: InputDecoration(
                labelText: switch (widget.action) {
                  WineOrderAction.save => '购物车Id',
                  WineOrderAction.take => '库存Id',
                  WineOrderAction.confiscate => '商品Id',
                },
              ),
            ),
            if (widget.action != WineOrderAction.confiscate)
              TextField(
                key: WineOrderScreen.authCodeKey,
                controller: _auth,
                decoration: const InputDecoration(labelText: '认证码'),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_title),
            ),
          ],
        ),
      ),
    );
  }
}
