import 'package:card_table/src/order_meal.dart';
import 'package:card_table/src/order_set_catalog.dart';
import 'package:card_table/src/order_set_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/services.dart';
import 'package:foundation/foundation.dart';

class OrderSetDialog extends StatefulWidget {
  const OrderSetDialog({
    required this.productId,
    required this.title,
    required this.configuration,
    required this.contextToken,
    required this.submit,
    this.oldItems = const [],
    this.replacing = false,
    this.allowAuthorization = false,
    super.key,
  });
  final String productId, title;
  final OrderSetConfiguration configuration;
  final ValueListenable<Object?> contextToken;
  final List<OrderSetItem> oldItems;
  final bool replacing, allowAuthorization;
  final Future<Result<void>> Function(
    OrderSetSelection,
    String,
    String,
    int,
    bool Function(),
  )
  submit;
  @override
  State<OrderSetDialog> createState() => _OrderSetDialogState();
}

class _SetChoiceEditor {
  _SetChoiceEditor(this.detail, this.serial)
    : count = TextEditingController(text: '1');
  final OrderSetDetail detail;
  final int serial;
  final TextEditingController count;
  final custom = TextEditingController();
  final requirements = <String, Set<String>>{};
  String requirement(List<OrderSetRequirementGroup> groups) => [
    for (final group in groups)
      for (final item in group.items)
        if (requirements[group.id]?.contains(item.id) == true) item.name,
    if (custom.text.trim().isNotEmpty) custom.text.trim(),
  ].join(';');
  void dispose() {
    count.dispose();
    custom.dispose();
  }
}

class _OrderSetDialogState extends State<OrderSetDialog> {
  late final Object? _token = widget.contextToken.value;
  final _count = TextEditingController(text: '1'),
      _code = TextEditingController(),
      _password = TextEditingController();
  final _choices = <_SetChoiceEditor>[];
  OrderSetItem? _old;
  bool _busy = false, _invalid = false, _authorization = false;
  int _attempt = 0, _serial = 0, _passType = 1;
  String? _error;
  bool get _current =>
      mounted &&
      !_invalid &&
      _token != null &&
      identical(_token, widget.contextToken.value);
  List<OrderSetDetail> get _candidates => widget.configuration.details
      .where(
        (d) =>
            !widget.replacing ||
            (_old != null && d.groupId == _old!.groupId && !d.fixed),
      )
      .toList();
  List<OrderSetRequirementGroup> _requirements(OrderSetDetail detail) =>
      widget.configuration.requirementsByProduct[detail.detailProductId] ??
      const [];
  String _oldName(OrderSetItem item) =>
      widget.configuration.details
          .where(
            (detail) =>
                detail.groupId == item.groupId &&
                detail.detailProductId == item.detailProductId,
          )
          .firstOrNull
          ?.name ??
      '商品${item.detailProductId}';
  @override
  void initState() {
    super.initState();
    widget.contextToken.addListener(_contextChanged);
    if (_token == null) _invalid = true;
    if (!widget.replacing) {
      for (final detail in _candidates.where((d) => d.fixed)) {
        _choices.add(_SetChoiceEditor(detail, _serial++));
      }
    }
  }

  void _clearCredentials() {
    _code.clear();
    _password.clear();
  }

  void _contextChanged() {
    if (!identical(_token, widget.contextToken.value)) {
      _attempt++;
      _clearCredentials();
      FocusManager.instance.primaryFocus?.unfocus();
      if (mounted) {
        setState(() {
          _invalid = true;
          _error = '操作上下文已变化，请重新打开套餐';
        });
      }
    }
  }

  @override
  void dispose() {
    _invalid = true;
    _attempt++;
    widget.contextToken.removeListener(_contextChanged);
    _clearCredentials();
    _code.dispose();
    _password.dispose();
    _count.dispose();
    for (final choice in _choices) {
      choice.dispose();
    }
    super.dispose();
  }

  void _close([bool success = false]) {
    _invalid = true;
    _attempt++;
    _clearCredentials();
    FocusManager.instance.primaryFocus?.unfocus();
    final route = ModalRoute.of(context);
    if (route?.isCurrent == true) {
      Navigator.pop(context, success);
    } else if (route?.isActive == true) {
      route!.navigator?.removeRoute(route, success);
    }
  }

  void _chooseOld(OrderSetItem old) {
    setState(() {
      _old = old;
      for (final choice in _choices) {
        choice.dispose();
      }
      _choices.clear();
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy || !_current) return;
    if (!widget.configuration.known) {
      setState(
        () => _error = widget.configuration.unavailableReason ?? '套餐配置未就绪',
      );
      return;
    }
    if (widget.replacing && _old == null) {
      setState(() => _error = '请先选择被替换的原明细');
      return;
    }
    final selection = OrderSetSelection(
      productId: widget.productId,
      candidates: _candidates,
      count: widget.replacing ? 1 : int.tryParse(_count.text) ?? 0,
      replacing: _old,
      choices: [
        for (final choice in _choices)
          OrderSetChoice(
            detail: choice.detail,
            selectCount: int.tryParse(choice.count.text) ?? 0,
            requirement: choice.requirement(_requirements(choice.detail)),
          ),
      ],
    );
    final invalid = selection.validate();
    if (invalid != null) {
      setState(() => _error = invalid.safeMessage);
      return;
    }
    if (_authorization &&
        (_code.text.trim().isEmpty || _password.text.isEmpty)) {
      setState(
        () => _error = _passType == 1 ? '请输入授权工号和密码' : '请输入已有读卡结果的卡码和卡密码',
      );
      return;
    }
    final code = _authorization ? _code.text.trim() : '',
        password = _authorization ? _password.text : '';
    _clearCredentials();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final attempt = ++_attempt;
    bool active() => mounted && attempt == _attempt && _busy && _current;
    try {
      final result = await widget.submit(
        selection,
        code,
        password,
        _authorization ? _passType : 1,
        active,
      );
      if (!active()) return;
      if (result.failureOrNull case final failure?) {
        setState(() {
          _error = failure.safeMessage;
          if (widget.allowAuthorization &&
              failure.code == orderSetAuthorizationRequiredCode) {
            _authorization = true;
          }
        });
      } else {
        _close(true);
      }
    } on Object {
      if (active()) setState(() => _error = '套餐操作失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _requirementsEditor(_SetChoiceEditor choice) {
    final groups = _requirements(choice.detail);
    if (groups.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      key: Key('set-requirements-${choice.serial}'),
      title: Text(
        choice.requirement(groups).isEmpty
            ? '定制要求'
            : choice.requirement(groups),
      ),
      children: [
        for (final group in groups)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${group.name}（${group.modeType == 1 ? '单选' : '多选'}）'),
              Wrap(
                spacing: 6,
                children: [
                  for (final item in group.items)
                    FilterChip(
                      key: Key(
                        'set-require-${choice.serial}-${group.id}-${item.id}',
                      ),
                      label: Text(item.name),
                      selected:
                          choice.requirements[group.id]?.contains(item.id) ==
                          true,
                      onSelected: _busy || !_current || _authorization
                          ? null
                          : (selected) => setState(() {
                              final values = choice.requirements.putIfAbsent(
                                group.id,
                                () => {},
                              );
                              if (group.modeType == 1) values.clear();
                              if (selected) {
                                values.add(item.id);
                              } else {
                                values.remove(item.id);
                              }
                            }),
                    ),
                ],
              ),
            ],
          ),
        TextField(
          key: Key('set-custom-${choice.serial}'),
          controller: choice.custom,
          maxLength: 30,
          enabled: !_busy && _current && !_authorization,
          decoration: const InputDecoration(labelText: '自定义要求（最多30字）'),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(_authorization ? '套餐变更授权' : widget.title),
    content: SizedBox(
      width: 680,
      height: MediaQuery.sizeOf(context).height * .68,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.replacing) ...[
              const Text('先选择被替换的原明细（固定组不可替换）'),
              for (final (index, item) in widget.oldItems.indexed)
                if (item.groupId != '1')
                  ListTile(
                    key: Key('set-old-$index'),
                    selected: identical(_old, item),
                    leading: Icon(
                      identical(_old, item)
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    onTap: _busy || !_current || _authorization
                        ? null
                        : () => _chooseOld(item),
                    title: Text('组${item.groupId} · ${_oldName(item)}'),
                    subtitle: Text(
                      '原选择次数${item.selectCount} · 明细数量${item.detailCount} · 要求：${item.requirement.isEmpty ? '无' : item.requirement}',
                    ),
                  ),
            ],
            if (!widget.replacing)
              TextField(
                key: const Key('set-package-count'),
                controller: _count,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !_busy && _current && !_authorization,
                decoration: const InputDecoration(labelText: '套餐数量'),
              ),
            if (!widget.replacing || _old != null) ...[
              for (final group in _candidates.map((d) => d.groupId).toSet())
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    group == '1'
                        ? '固定组（每项默认选中一次）'
                        : '可选组$group：须选${widget.replacing ? _old!.selectCount : _candidates.firstWhere((d) => d.groupId == group).groupSelectCount}次',
                  ),
                ),
              Wrap(
                spacing: 8,
                children: [
                  for (final detail in _candidates.where((d) => !d.fixed))
                    OutlinedButton(
                      key: Key(
                        'set-add-${detail.groupId}-${detail.detailProductId}',
                      ),
                      onPressed: _busy || !_current || _authorization
                          ? null
                          : () => setState(
                              () => _choices.add(
                                _SetChoiceEditor(detail, _serial++),
                              ),
                            ),
                      child: Text('添加 ${detail.name}'),
                    ),
                ],
              ),
              for (final choice in _choices)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(choice.detail.name)),
                            if (!choice.detail.fixed)
                              IconButton(
                                key: Key('set-remove-${choice.serial}'),
                                onPressed: _busy || !_current || _authorization
                                    ? null
                                    : () => setState(() {
                                        _choices.remove(choice);
                                        choice.dispose();
                                      }),
                                icon: const Icon(Icons.delete_outline),
                              ),
                          ],
                        ),
                        Text(
                          '组${choice.detail.groupId} · 每次${choice.detail.detailCount}份',
                        ),
                        TextField(
                          key: Key('set-choice-count-${choice.serial}'),
                          controller: choice.count,
                          enabled:
                              !choice.detail.fixed &&
                              !_busy &&
                              _current &&
                              !_authorization,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(labelText: '选择次数'),
                        ),
                        _requirementsEditor(choice),
                      ],
                    ),
                  ),
                ),
            ],
            if (_authorization) ...[
              const Text('本人权限不足；他人授权密码不会保存'),
              Wrap(
                spacing: 8,
                children: [
                  for (final type in [1, 2])
                    ChoiceChip(
                      label: Text(type == 1 ? '账号密码' : '卡码输入'),
                      selected: _passType == type,
                      onSelected: _busy || !_current
                          ? null
                          : (_) => setState(() {
                              _passType = type;
                              _clearCredentials();
                            }),
                    ),
                ],
              ),
              if (_passType == 2) const Text('未接自动读卡，请输入已有读卡结果中的卡码及卡密码'),
              TextField(
                key: const Key('set-auth-code'),
                controller: _code,
                enabled: !_busy && _current,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: _passType == 1 ? '授权工号' : '卡码',
                ),
              ),
              TextField(
                key: const Key('set-auth-password'),
                controller: _password,
                enabled: !_busy && _current,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: _passType == 1 ? '授权密码' : '卡密码',
                ),
              ),
            ],
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_busy) const Text('已发出的请求不会因关闭窗口而撤回'),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => _close(), child: const Text('取消')),
      FilledButton(
        onPressed: _busy || !_current ? null : _submit,
        child: Text(_authorization ? '授权提交' : '确认'),
      ),
    ],
  );
}
