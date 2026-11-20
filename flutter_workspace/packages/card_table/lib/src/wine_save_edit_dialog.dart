import 'package:flutter/material.dart';
import 'package:card_table/src/wine_loader.dart';
import 'package:card_table/src/wine_save_edit.dart';

class _SaveLine {
  _SaveLine(this.source)
    : unit = source.unit,
      count = TextEditingController(text: '${source.count}'),
      grams = TextEditingController(text: '${source.grams}'),
      days = TextEditingController(text: '${source.days}');
  final WineSaveEditLine source;
  String unit;
  final TextEditingController count, grams, days;
  WineSaveEditLine value() => source.copy(
    unit: unit,
    count: int.parse(count.text),
    grams: int.parse(grams.text),
    days: int.parse(days.text),
  );
  void dispose() {
    count.dispose();
    grams.dispose();
    days.dispose();
  }
}

final class WineSaveEditDialog extends StatefulWidget {
  const WineSaveEditDialog({
    super.key,
    required this.loader,
    required this.record,
    required this.needsAuthorization,
  });
  final WineLoader loader;
  final WineSaveEditRecord record;
  final bool needsAuthorization;
  @override
  State<WineSaveEditDialog> createState() => _WineSaveEditDialogState();
}

final class _WineSaveEditDialogState extends State<WineSaveEditDialog> {
  WineSaveEditLoader get _loader => widget.loader as WineSaveEditLoader;
  late final Object? _session;
  late final List<_SaveLine> _lines;
  late final TextEditingController _name, _phone, _time, _remark;
  final _employeeSearch = TextEditingController(),
      _account = TextEditingController(),
      _secret = TextEditingController();
  bool _linked = true, _busy = false, _invalid = false;
  int _request = 0, _passType = 1;
  int? _employee;
  late int _seat, _csm;
  late String _seatName, _day;
  String? _error;
  List<Map<String, Object?>> _seats = [], _orders = [];
  bool get _current =>
      mounted &&
      !_invalid &&
      _session != null &&
      _session == _loader.saveEditSession;
  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _session = _loader.saveEditSession;
    _lines = [for (final l in r.lines) _SaveLine(l)];
    _name = TextEditingController(text: r.customerName);
    _phone = TextEditingController(text: r.phone);
    _time = TextEditingController(text: r.storeTime);
    _remark = TextEditingController(text: r.remark);
    _seat = r.seatId;
    _csm = r.csmId;
    _seatName = r.seatName;
    _day = _loader.saveEditSnapshot.businessDates.firstOrNull ?? '';
  }

  @override
  void dispose() {
    _invalid = true;
    for (final l in _lines) {
      l.dispose();
    }
    for (final c in [
      _name,
      _phone,
      _time,
      _remark,
      _employeeSearch,
      _account,
      _secret,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fail(String value) {
    if (mounted) setState(() => _error = value);
  }

  Future<void> _loadSeats() async {
    if (!_current || _busy) return;
    final request = ++_request;
    setState(() => _busy = true);
    final result = await _loader.loadSaveEditSeats(day: _linked ? _day : null);
    if (!_current || request != _request) return;
    setState(() => _busy = false);
    if (result.failureOrNull case final f?) {
      _fail(f.safeMessage);
      return;
    }
    setState(() => _seats = result.valueOrNull!);
  }

  Future<void> _chooseSeat(Map<String, Object?> seat) async {
    if (!_current || _busy) return;
    final id = int.tryParse('${seat['id']}');
    if (id == null || id <= 0) return;
    setState(() {
      _seat = id;
      _seatName = '${seat['n']}';
      _seats = [];
      _orders = [];
      _csm = 0;
    });
    if (!_linked) return;
    final request = ++_request;
    setState(() => _busy = true);
    final result = await _loader.loadSaveEditOrders(_day, id);
    if (!_current || request != _request) return;
    setState(() => _busy = false);
    if (result.failureOrNull case final f?) {
      _fail(f.safeMessage);
      return;
    }
    final rows = result.valueOrNull!;
    if (rows.any((row) => (int.tryParse('${row['id']}') ?? 0) <= 0)) {
      _fail('流水数据无效');
      return;
    }
    setState(() => _orders = rows);
    if (rows.isEmpty) _fail('该卡台没有可关联流水');
  }

  Future<void> _submit() async {
    if (_busy || !_current) return;
    final metadata = _loader.saveEditSnapshot;
    if (!metadata.known) {
      _fail('订位人及营业日尚未同步');
      return;
    }
    if (!_linked &&
        (_employee == null ||
            _employee != 0 &&
                !metadata.employees.any((e) => e.id == _employee))) {
      _fail('请选择有效订位人或散客');
      return;
    }
    if (widget.needsAuthorization &&
        (_account.text.trim().isEmpty || _secret.text.isEmpty)) {
      _fail('请填写服务员授权信息');
      return;
    }
    final name = _name.text.trim(), phone = _phone.text.trim();
    if (name != widget.record.customerName || phone != widget.record.phone) {
      final length = name.codeUnits.fold<int>(
        0,
        (n, c) => n + (c > 127 || c == 94 ? 2 : 1),
      );
      if (name.isEmpty || length > 20 || phone.length != 11) {
        _fail('客人姓名不能为空且不超过20字符，手机号须为11位');
        return;
      }
    }
    if (_time.text != widget.record.storeTime) {
      final raw = _time.text;
      final date = DateTime.tryParse(raw.replaceAll('/', '-'));
      final formatted = date == null
          ? ''
          : '${date.year.toString().padLeft(4, '0')}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
      if (formatted != raw || date == null || date.isAfter(DateTime.now())) {
        _fail('存酒时间须为 yyyy/MM/dd HH:mm:ss 且不晚于现在');
        return;
      }
    }
    late final Map<String, Object?> body;
    try {
      body = widget.record.body(
        lines: [for (final l in _lines) l.value()],
        linked: _linked,
        csmId: _csm,
        seatId: _seat,
        salesEmployeeId: _employee ?? 0,
        customerName: name,
        phone: phone,
        remark: _remark.text,
        storeTime: _time.text,
      );
    } on Object {
      _fail('请检查卡台流水、商品规格、整数数量/克数/有效期及授权数量上限');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final fresh = await _loader.loadSaveEditContext();
      if (!_current) return;
      if (fresh.failureOrNull case final f?) {
        _fail(f.safeMessage);
        return;
      }
      final latest = fresh.valueOrNull!;
      final row = latest.records
          .where((r) => r.id == widget.record.id)
          .firstOrNull;
      if (row == null ||
          row.fingerprint != widget.record.fingerprint ||
          latest.needsAuthorization != widget.needsAuthorization) {
        _fail('单据或授权配置已变化，请重新查询后编辑');
        return;
      }
      final now = _loader.saveEditSnapshot;
      if (!now.known ||
          (!_linked &&
              _employee != 0 &&
              !now.employees.any((e) => e.id == _employee))) {
        _fail('订位人资料已变化，请重新查询');
        return;
      }
      if (!_current) return;
      final result = await widget.loader.chgSaveNeedToLib(body);
      if (!mounted || !_current) return;
      if (result.failureOrNull case final f?) {
        _fail(f.safeMessage);
        return;
      }
      final route = ModalRoute.of(context);
      if (route?.isActive == true) {
        Navigator.of(context).removeRoute(route!, true);
      }
    } on Object {
      _fail('改单请求失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metadata = _loader.saveEditSnapshot;
    final query = _employeeSearch.text.toLowerCase();
    return PopScope<bool>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _invalid = true;
      },
      child: AlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('存酒仓库改单'),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        insetPadding: const EdgeInsets.all(12),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  title: const Text('关联卡台流水'),
                  value: _linked,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() {
                          _linked = v;
                          _seats = [];
                          _orders = [];
                          _request++;
                        }),
                ),
                Text('卡台：$_seatName　流水：${_csm == 0 ? "未选择" : _csm}'),
                if (_linked)
                  DropdownButtonFormField<String>(
                    key: ValueKey('save-day-$_day'),
                    initialValue: metadata.businessDates.contains(_day)
                        ? _day
                        : null,
                    items: [
                      for (final day in metadata.businessDates)
                        DropdownMenuItem(value: day, child: Text(day)),
                    ],
                    onChanged: _busy
                        ? null
                        : (v) => setState(() {
                            _day = v!;
                            _csm = 0;
                            _seats = [];
                            _orders = [];
                          }),
                  ),
                TextButton(
                  onPressed: _busy || !metadata.known ? null : _loadSeats,
                  child: Text(_linked ? '更改关联卡台流水' : '更改卡台'),
                ),
                for (final seat in _seats)
                  TextButton(
                    onPressed: _busy ? null : () => _chooseSeat(seat),
                    child: Text('${seat['n']}'),
                  ),
                for (final order in _orders)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _csm = int.parse('${order['id']}');
                            _orders = [];
                          }),
                    child: Text('流水 ${order['id']} 订位人 ${order['s'] ?? ''}'),
                  ),
                if (!_linked) ...[
                  TextField(
                    controller: _employeeSearch,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: '搜索订位人姓名/工号/拼音',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  DropdownButtonFormField<int>(
                    key: ValueKey('save-employee-$_employee-$query'),
                    initialValue:
                        _employee == 0 ||
                            metadata.employees.any((e) => e.id == _employee)
                        ? _employee
                        : null,
                    decoration: const InputDecoration(labelText: '订位人'),
                    items: [
                      const DropdownMenuItem(value: 0, child: Text('散客')),
                      for (final e in metadata.employees.where(
                        (e) =>
                            e.id == _employee ||
                            '${e.name} ${e.code} ${e.namePy}'
                                .toLowerCase()
                                .contains(query),
                      ))
                        DropdownMenuItem(
                          value: e.id,
                          child: Text('${e.name} (${e.code})'),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _employee = v),
                  ),
                ],
                TextField(
                  key: const Key('save-edit-name'),
                  controller: _name,
                  enabled: !_busy,
                  decoration: const InputDecoration(labelText: '客人姓名'),
                ),
                TextField(
                  controller: _phone,
                  enabled: !_busy,
                  decoration: const InputDecoration(labelText: '手机号'),
                ),
                TextField(
                  controller: _time,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: '存酒时间 yyyy/MM/dd HH:mm:ss',
                  ),
                ),
                TextField(
                  key: const Key('save-edit-remark'),
                  controller: _remark,
                  enabled: !_busy,
                  decoration: const InputDecoration(labelText: '备注'),
                ),
                for (final line in _lines)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Text(line.source.name),
                          DropdownButtonFormField<String>(
                            initialValue: line.unit,
                            items: [
                              for (final unit in [
                                '整瓶',
                                '0.1',
                                '0.2',
                                '0.3',
                                '0.4',
                                '0.5',
                                '0.6',
                                '0.7',
                                '0.8',
                                '0.9',
                              ])
                                DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                ),
                            ],
                            onChanged: _busy
                                ? null
                                : (v) => setState(() => line.unit = v!),
                          ),
                          if (line.unit != '整瓶')
                            TextField(
                              controller: line.grams,
                              enabled: !_busy,
                              decoration: const InputDecoration(
                                labelText: '每瓶克数',
                              ),
                            ),
                          TextField(
                            controller: line.count,
                            enabled: !_busy,
                            decoration: InputDecoration(
                              labelText:
                                  '数量${line.source.maximum == null ? '' : '（最多${line.source.maximum}）'}',
                            ),
                          ),
                          TextField(
                            controller: line.days,
                            enabled: !_busy,
                            decoration: const InputDecoration(
                              labelText: '有效期（天）',
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () {
                                        try {
                                          setState(
                                            () => _lines.add(
                                              _SaveLine(line.value()),
                                            ),
                                          );
                                        } on Object {
                                          _fail('请先填写有效明细');
                                        }
                                      },
                                child: const Text('复制'),
                              ),
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () {
                                        setState(() => _lines.remove(line));
                                        line.dispose();
                                      },
                                child: const Text('删除'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (widget.needsAuthorization) ...[
                  const Text('原系统要求服务员确认；该改单接口不接收授权凭据，不代表已完成服务端身份验证。'),
                  DropdownButton<int>(
                    value: _passType,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('账号密码')),
                      DropdownMenuItem(value: 2, child: Text('员工卡（手工输入）')),
                    ],
                    onChanged: _busy
                        ? null
                        : (v) => setState(() {
                            _passType = v!;
                            _account.clear();
                            _secret.clear();
                          }),
                  ),
                  if (_passType == 2) const Text('自动读卡尚未接入'),
                  TextField(
                    controller: _account,
                    enabled: !_busy,
                    decoration: InputDecoration(
                      labelText: _passType == 1 ? '服务员工号' : '员工卡号',
                    ),
                  ),
                  TextField(
                    controller: _secret,
                    enabled: !_busy,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: _passType == 1 ? '服务员密码' : '原始卡数据',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _invalid = true;
              Navigator.of(context).pop(false);
            },
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('save-edit-submit'),
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? '提交中…' : '确认修改信息'),
          ),
        ],
      ),
    );
  }
}
