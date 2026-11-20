import 'dart:async';

import 'package:card_table/src/cashier_merchant_management.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:foundation/foundation.dart';

abstract class _MerchantState<T extends StatefulWidget> extends State<T> {
  ValueListenable<bool> get access;
  CashierMerchantManagementLoader get loader;
  Future<void> loadData(int epoch);
  bool busy = false, ready = false, uncertain = false, closed = false;
  int epoch = 0;
  String? message;
  bool get allowed => mounted && !closed && access.value;
  bool get editable =>
      allowed && ready && !busy && !uncertain && !loader.needsVerification;
  bool current(int token) => allowed && token == epoch;
  void update(VoidCallback change) {
    change();
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  void invalidate() {
    epoch++;
    update(() {
      ready = false;
      message = '登录、连接或页面数据已变化，请重新读取配置';
    });
  }

  void accessChanged() {
    if (!access.value) {
      invalidate();
    } else {
      update(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    access.addListener(accessChanged);
    unawaited(Future<void>.microtask(reload));
  }

  @override
  void dispose() {
    closed = true;
    epoch++;
    access.removeListener(accessChanged);
    super.dispose();
  }

  Future<R?> read<R>(Future<Result<R>> call, int token) async {
    final result = await call;
    if (!current(token)) return null;
    if (result.failureOrNull case final failure?) throw failure;
    return result.valueOrNull;
  }

  Future<void> reload({bool verify = false}) async {
    if (!allowed || busy) return;
    final token = ++epoch;
    update(() {
      busy = true;
      ready = false;
      message = null;
    });
    try {
      if (verify) {
        final result = await loader.verify(() => current(token));
        if (!current(token)) return;
        if (result.failureOrNull case final failure?) throw failure;
      }
      await loadData(token);
      if (current(token)) {
        update(() {
          ready = true;
          uncertain = loader.needsVerification;
          if (uncertain) message = '商户操作结果尚未确认，请点击重新读取配置核实';
        });
      }
    } on Object catch (error) {
      if (current(token)) {
        update(
          () => message = error is AppFailure
              ? error.safeMessage
              : '读取商户配置失败，请重试',
        );
      }
    } finally {
      if (mounted) update(() => busy = false);
    }
  }

  Future<void> write(
    String label,
    Future<Result<void>> Function(bool Function()) invoke,
  ) async {
    if (!editable) return;
    final token = epoch;
    var submitted = false;
    update(() => busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(label),
          content: const Text('此操作会即时影响线上收款，请核实商户、范围和金额后确认。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('确认生效'),
            ),
          ],
        ),
      );
      if (confirmed != true || !current(token)) return;
      uncertain = true;
      submitted = true;
      final result = await invoke(() => current(token) && ready);
      if (!current(token)) return;
      if (result.failureOrNull case final failure?) {
        update(() {
          if (failure.kind == FailureKind.business) uncertain = false;
          message = uncertain
              ? '操作结果尚未确认，请重新读取服务端配置核实，勿重复提交'
              : failure.safeMessage;
        });
        return;
      }
      uncertain = false;
      ready = false;
      await loadData(token);
      if (current(token)) {
        update(() {
          ready = true;
          message = '设置成功，已重新读取服务端配置';
        });
      }
    } on Object catch (error) {
      if (current(token)) {
        update(() {
          if (submitted) {
            uncertain = true;
            message = '操作结果尚未确认，请重新读取服务端配置核实，勿重复提交';
          } else {
            message = error is AppFailure ? error.safeMessage : '操作失败';
          }
        });
      }
    } finally {
      if (mounted) update(() => busy = false);
    }
  }

  Widget shell(String title, Widget body) => PopScope<void>(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) {
        closed = true;
        epoch++;
      }
    },
    child: Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Wrap(
            spacing: 12,
            children: [
              TextButton(
                onPressed: allowed && !busy ? () => reload(verify: true) : null,
                child: const Text('重新读取配置'),
              ),
              if (busy)
                const Padding(padding: EdgeInsets.all(10), child: Text('处理中…')),
            ],
          ),
          if (!access.value) const Text('连接或权限不可用，禁止修改商户配置'),
          if (message != null)
            Padding(padding: const EdgeInsets.all(8), child: Text(message!)),
          Expanded(child: body),
        ],
      ),
    ),
  );
}

final class CashierMerchantManagementScreen extends StatefulWidget {
  const CashierMerchantManagementScreen({
    required this.loader,
    required this.canOperate,
    super.key,
  });
  final CashierMerchantManagementLoader loader;
  final ValueListenable<bool> canOperate;
  @override
  State<CashierMerchantManagementScreen> createState() => _ManagementState();
}

class _ManagementState extends _MerchantState<CashierMerchantManagementScreen> {
  @override
  ValueListenable<bool> get access => widget.canOperate;
  @override
  CashierMerchantManagementLoader get loader => widget.loader;
  CashierMerchantGroups? groups;
  CashierMerchantConfig? config;
  int? tab;
  int defaultEntity = 0,
      defaultMerchant = 0,
      targetMerchant = 0,
      seatMerchant = 0;
  bool switchEnabled = false;
  final privateIds = <int, Set<int>>{},
      regionIds = <int, Set<int>>{},
      seatIds = <int, int>{},
      hourMerchantIds = <int, int>{};
  final maxAmount = TextEditingController();
  final hourAmounts = <int, TextEditingController>{};
  @override
  void didUpdateWidget(CashierMerchantManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.canOperate, access)) {
      oldWidget.canOperate.removeListener(accessChanged);
      access.addListener(accessChanged);
      invalidate();
    }
    if (!identical(oldWidget.loader, widget.loader)) invalidate();
  }

  @override
  void dispose() {
    maxAmount.dispose();
    for (final c in hourAmounts.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Future<void> loadData(int token) async {
    final fresh = await read(widget.loader.groups(), token);
    if (fresh == null) return;
    final entities = fresh.entities;
    var selected = tab;
    if (entities.length <= 1) {
      selected = 0;
    } else if (selected != null && !entities.any((e) => e.id == selected)) {
      selected = null;
    }
    final detail = selected == null
        ? null
        : await read(widget.loader.config(selected), token);
    if (!current(token)) return;
    groups = fresh;
    tab = selected;
    config = detail;
    defaultEntity =
        fresh.assignments.where((g) => g.isDefault).firstOrNull?.entityId ??
        entities.firstOrNull?.id ??
        0;
    privateIds.clear();
    regionIds.clear();
    for (final entity in entities) {
      privateIds[entity.id] = {
        ...fresh.assignment(entity.id)?.privateIds ?? {},
      };
      regionIds[entity.id] = {...fresh.assignment(entity.id)?.regionIds ?? {}};
    }
    for (final controller in hourAmounts.values) {
      controller.dispose();
    }
    hourAmounts.clear();
    hourMerchantIds.clear();
    seatIds.clear();
    if (detail != null) {
      switchEnabled = detail.switchEnabled;
      maxAmount.text = '${detail.maxAmount}';
      defaultMerchant = detail.defaultMerchantId;
      targetMerchant = detail.targetMerchantId;
      for (final hour in detail.hours) {
        hourAmounts[hour.hour] = TextEditingController(
          text: '${hour.maxAmount}',
        );
        hourMerchantIds[hour.hour] = hour.merchantId;
      }
      for (final region in detail.regions) {
        for (final seat in region.seats) {
          seatIds[seat.id] = seat.merchantId;
        }
      }
      seatMerchant = seatIds.values.where((id) => id != 0).firstOrNull ?? 0;
    }
  }

  Future<void> selectTab(int? id) async {
    if (!allowed || busy || uncertain) return;
    tab = id;
    await reload();
  }

  Widget select(
    String label,
    int value,
    List<CashierMerchant> options,
    void Function(int) changed, {
    bool zero = false,
  }) => DropdownButtonFormField<int>(
    key: ValueKey('$label-$tab-$value'),
    initialValue: options.any((o) => o.id == value)
        ? value
        : zero
        ? 0
        : null,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      if (zero) const DropdownMenuItem(value: 0, child: Text('未配置')),
      for (final option in options)
        DropdownMenuItem(
          value: option.id,
          child: Text(option.name, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: editable ? (v) => update(() => changed(v!)) : null,
  );
  void own(Map<int, Set<int>> values, int entityId, int id, bool selected) {
    update(() {
      if (selected) {
        for (final entry in values.entries) {
          entry.value.remove(id);
        }
        values[entityId]!.add(id);
      } else {
        values[entityId]!.remove(id);
      }
    });
  }

  Future<void> saveGroups() async {
    final data = groups!;
    if (data.entities.length != 2) {
      update(() => message = '当前接口仅支持两个主体，请核实主体配置');
      return;
    }
    final draft = CashierMerchantGroupsDraft(
      entityIds: data.entities.map((e) => e.id).toList(),
      defaultEntityId: defaultEntity,
      privateIdsByEntity: {
        for (final entry in privateIds.entries) entry.key: entry.value.toList(),
      },
      regionIdsByEntity: {
        for (final entry in regionIds.entries) entry.key: entry.value.toList(),
      },
    );
    try {
      draft.toWire();
    } on Object {
      update(() => message = '请选择默认主体，每个主体至少选择一个互斥对私商户和区域');
      return;
    }
    await write('保存全局商户配置', (guard) => widget.loader.saveGroups(draft, guard));
  }

  Future<void> saveConfig() async {
    final data = config;
    if (data == null) return;
    final amount = int.tryParse(maxAmount.text.trim());
    final amounts = <int, int>{};
    for (final entry in hourAmounts.entries) {
      final value = entry.value.text.trim().isEmpty
          ? 0
          : int.tryParse(entry.value.text.trim());
      if (value == null || value.abs() > 9007199254740991) {
        update(() => message = '时段额度必须是有界整数元');
        return;
      }
      amounts[entry.key] = value;
    }
    final ids = data.merchants.map((m) => m.id).toSet(),
        privates = data.merchants
            .where((m) => m.kind == 2)
            .map((m) => m.id)
            .toSet();
    if (!ids.contains(defaultMerchant) ||
        (switchEnabled &&
            (amount == null ||
                amount.abs() > 9007199254740991 ||
                !privates.contains(targetMerchant))) ||
        hourMerchantIds.values.any((id) => id != 0 && !privates.contains(id)) ||
        seatIds.values.any((id) => id != 0 && !ids.contains(id))) {
      update(() => message = '请核实默认商户、对私目标商户及整数元阈值');
      return;
    }
    final draft = CashierMerchantConfigDraft(
      entityId: data.entityId,
      defaultMerchantId: defaultMerchant,
      switchEnabled: switchEnabled,
      maxAmount: switchEnabled ? amount! : 0,
      targetMerchantId: switchEnabled ? targetMerchant : 0,
      seatMerchants: Map.of(seatIds),
      hours: [
        for (var hour = 0; hour < 24; hour++)
          CashierMerchantHourRule(
            hour: hour,
            maxAmount: amounts[hour] ?? 0,
            merchantId: hourMerchantIds[hour] ?? 0,
          ),
      ],
    );
    try {
      draft.toWire();
    } on Object {
      update(() => message = '请核实商户配置输入');
      return;
    }
    await write('保存商户配置', (guard) => widget.loader.saveConfig(draft, guard));
  }

  @override
  Widget build(BuildContext context) {
    final data = groups;
    if (data == null || !ready || !allowed) {
      return shell('商户号管理', const Center(child: Text('等待读取商户配置')));
    }
    final entities = data.entities, detail = config;
    final online = entities.length > 1 && tab == null
        ? <CashierMerchant>[]
        : data.onlineMerchants(tab ?? 0);
    return shell(
      '商户号管理',
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (entities.length > 1)
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('全局配置'),
                  selected: tab == null,
                  onSelected: !busy && !uncertain
                      ? (_) => selectTab(null)
                      : null,
                ),
                for (final entity in entities.take(2))
                  ChoiceChip(
                    label: Text('主体(${entity.name})组'),
                    selected: tab == entity.id,
                    onSelected: !busy && !uncertain
                        ? (_) => selectTab(entity.id)
                        : null,
                  ),
              ],
            ),
          if (entities.length > 2) const Text('检测到超过两个主体，当前接口无法完整保存，请核实'),
          for (final merchant in online)
            SwitchListTile(
              key: ValueKey('merchant-online-${merchant.id}'),
              title: Text(
                [
                  merchant.name,
                  merchant.holder,
                  merchant.bank,
                ].where((v) => v.isNotEmpty).join(' -- '),
              ),
              subtitle: const Text('线上收款功能（确认后即时生效）'),
              value: !data.closedFor(tab ?? 0).contains(merchant.id),
              onChanged: editable
                  ? (enabled) => write(
                      enabled ? '开启线上收款' : '关闭线上收款',
                      (guard) =>
                          widget.loader.setOnline(merchant.id, enabled, guard),
                    )
                  : null,
            ),
          if (entities.length > 1 && tab == null) ...[
            select('默认主体', defaultEntity, entities, (v) => defaultEntity = v),
            const Text('未绑定商户号的区域，线上收款计入默认主体'),
            for (final entity in entities)
              ExpansionTile(
                initiallyExpanded: true,
                title: Text('主体(${entity.name})组'),
                children: [
                  const Text('对私商户号（各主体互斥）'),
                  for (final merchant in data.merchants.where(
                    (m) => m.kind == 2,
                  ))
                    CheckboxListTile(
                      key: ValueKey(
                        'merchant-private-${entity.id}-${merchant.id}',
                      ),
                      title: Text(merchant.name),
                      value:
                          privateIds[entity.id]?.contains(merchant.id) ?? false,
                      onChanged: editable
                          ? (v) => own(privateIds, entity.id, merchant.id, v!)
                          : null,
                    ),
                  const Text('区域（各主体互斥）'),
                  for (final region in data.regions.entries)
                    CheckboxListTile(
                      key: ValueKey(
                        'merchant-region-${entity.id}-${region.key}',
                      ),
                      title: Text(region.value),
                      value:
                          regionIds[entity.id]?.contains(region.key) ?? false,
                      onChanged: editable
                          ? (v) => own(regionIds, entity.id, region.key, v!)
                          : null,
                    ),
                ],
              ),
            FilledButton(
              onPressed: editable && entities.length == 2 ? saveGroups : null,
              child: const Text('保存全局配置'),
            ),
          ] else if (detail != null) ...[
            SwitchListTile(
              key: const ValueKey('merchant-auto-switch'),
              title: const Text('自动切换商户号'),
              subtitle: const Text('需保存后生效'),
              value: switchEnabled,
              onChanged: editable
                  ? (v) => update(() => switchEnabled = v)
                  : null,
            ),
            if (switchEnabled) ...[
              TextField(
                controller: maxAmount,
                enabled: editable,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: const InputDecoration(labelText: '公账金额阈值（整数元）'),
              ),
              select(
                '阈值切换目标商户',
                targetMerchant,
                detail.merchants.where((m) => m.kind == 2).toList(),
                (v) => targetMerchant = v,
              ),
              const Text('达到公账阈值后，全场线上收款自动切到目标商户；保存完成即时生效。'),
            ],
            select(
              '默认商户号',
              defaultMerchant,
              detail.merchants,
              (v) => defaultMerchant = v,
              zero: true,
            ),
            ExpansionTile(
              title: const Text('时段额度控制（24小时）'),
              children: [
                for (final h in [
                  for (var i = 12; i < 24; i++) i,
                  for (var i = 0; i < 12; i++) i,
                ])
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text(
                          '${h.toString().padLeft(2, '0')}:00-${((h + 1) % 24).toString().padLeft(2, '0')}:00',
                        ),
                        TextField(
                          key: ValueKey('merchant-hour-amount-$h'),
                          controller: hourAmounts[h],
                          enabled: editable,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: '额度金额（整数元）',
                          ),
                          onChanged: (_) {
                            final private = detail.merchants
                                .where((m) => m.kind == 2)
                                .toList();
                            if (private.isNotEmpty &&
                                !private.any(
                                  (m) => m.id == hourMerchantIds[h],
                                )) {
                              update(
                                () => hourMerchantIds[h] = private.first.id,
                              );
                            }
                          },
                        ),
                        select(
                          '时段$h商户号',
                          hourMerchantIds[h] ?? 0,
                          detail.merchants.where((m) => m.kind == 2).toList(),
                          (v) => hourMerchantIds[h] = v,
                          zero: true,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            select(
              '卡台分配商户号',
              seatMerchant,
              detail.merchants,
              (v) => seatMerchant = v,
              zero: true,
            ),
            const Text('未绑定商户号的卡台使用默认商户号；请先选择商户后分配卡台。'),
            for (final region in detail.regions)
              ExpansionTile(
                initiallyExpanded: true,
                title: Text(region.name),
                children: [
                  CheckboxListTile(
                    title: const Text('全选/反选区域卡台'),
                    tristate: true,
                    value:
                        region.seats.every((s) => seatIds[s.id] == seatMerchant)
                        ? true
                        : region.seats.any((s) => seatIds[s.id] == seatMerchant)
                        ? null
                        : false,
                    onChanged: editable && seatMerchant != 0
                        ? (v) => update(() {
                            for (final seat in region.seats) {
                              seatIds[seat.id] = v == true ? seatMerchant : 0;
                            }
                          })
                        : null,
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final seat in region.seats)
                        ChoiceChip(
                          label: Text(
                            '${seat.name} · ${detail.merchants.where((m) => m.id == seatIds[seat.id]).firstOrNull?.name ?? '未配置'}',
                          ),
                          selected:
                              seatMerchant != 0 &&
                              seatIds[seat.id] == seatMerchant,
                          onSelected: editable && seatMerchant != 0
                              ? (_) => update(
                                  () => seatIds[seat.id] =
                                      seatIds[seat.id] == seatMerchant
                                      ? 0
                                      : seatMerchant,
                                )
                              : null,
                        ),
                    ],
                  ),
                ],
              ),
            FilledButton(
              onPressed: editable ? saveConfig : null,
              child: const Text('保存修改'),
            ),
          ],
        ],
      ),
    );
  }
}

final class CashierMerchantInformationScreen extends StatefulWidget {
  const CashierMerchantInformationScreen({
    required this.loader,
    required this.canOperate,
    required this.merchantId,
    this.amount = 0,
    this.publicAmount = 0,
    super.key,
  });
  final CashierMerchantManagementLoader loader;
  final ValueListenable<bool> canOperate;
  final int merchantId;
  final num amount, publicAmount;
  @override
  State<CashierMerchantInformationScreen> createState() => _InformationState();
}

class _InformationState
    extends _MerchantState<CashierMerchantInformationScreen> {
  @override
  ValueListenable<bool> get access => widget.canOperate;
  @override
  CashierMerchantManagementLoader get loader => widget.loader;
  List<CashierMerchantHourAmount> hours = [];
  CashierMerchantSwitchState? state;
  int target = 0;
  bool choosing = false;
  num amount = 0, publicAmount = 0;
  @override
  void didUpdateWidget(CashierMerchantInformationScreen old) {
    super.didUpdateWidget(old);
    if (!identical(old.canOperate, access)) {
      old.canOperate.removeListener(accessChanged);
      access.addListener(accessChanged);
      invalidate();
    }
    if (old.merchantId != widget.merchantId ||
        !identical(old.loader, widget.loader)) {
      invalidate();
    }
  }

  @override
  Future<void> loadData(int token) async {
    final rows = await read(widget.loader.hours(widget.merchantId), token);
    if (rows == null) return;
    final fresh = await read(widget.loader.switchState(), token);
    if (fresh == null || !current(token)) return;
    num numeric(String text) {
      final value = num.tryParse(text);
      if (value == null || !value.isFinite) throw const FormatException();
      return value;
    }

    var a = widget.amount, g = widget.publicAmount;
    if (!a.isFinite || !g.isFinite) throw const FormatException();
    if (a == 0 && g == 0 && rows.isNotEmpty) {
      a = rows.fold<num>(0, (sum, row) => sum + numeric(row.amount));
      g = rows.fold<num>(0, (sum, row) => sum + numeric(row.publicAmount));
    }
    hours = rows;
    state = fresh;
    amount = a;
    publicAmount = g;
    target = fresh.enabled ? fresh.merchantId : 0;
    choosing = false;
  }

  Future<void> choose() async {
    if (!editable) return;
    final token = epoch;
    update(() => busy = true);
    try {
      final fresh = await read(widget.loader.switchState(), token);
      if (fresh != null && current(token)) {
        update(() {
          state = fresh;
          target = fresh.enabled ? fresh.merchantId : 0;
          choosing = true;
        });
      }
    } on Object catch (error) {
      if (current(token)) {
        update(
          () =>
              message = error is AppFailure ? error.safeMessage : '获取商户切换配置失败',
        );
      }
    } finally {
      if (mounted) update(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = state;
    if (!ready || !allowed) {
      return shell('商户号信息', const Center(child: Text('等待读取商户号信息')));
    }
    return shell(
      '商户号信息',
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(((amount - publicAmount) / 10000).toStringAsFixed(2)),
          Text('G ${(publicAmount / 10000).toStringAsFixed(2)}'),
          if (data == null)
            const Text('等待读取商户号信息')
          else if (choosing) ...[
            DropdownButtonFormField<int>(
              initialValue: data.merchants.any((m) => m.id == target)
                  ? target
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '切换目标商户'),
              items: [
                for (final merchant in data.merchants)
                  DropdownMenuItem(
                    value: merchant.id,
                    child: Text(merchant.name),
                  ),
              ],
              onChanged: editable ? (v) => update(() => target = v!) : null,
            ),
            FilledButton(
              onPressed: editable && data.merchants.any((m) => m.id == target)
                  ? () => write(
                      '手工一键切换商户',
                      (guard) => widget.loader.enableSwitch(target, guard),
                    )
                  : null,
              child: const Text('确定切换'),
            ),
            TextButton(
              onPressed: !busy ? () => update(() => choosing = false) : null,
              child: const Text('上一步'),
            ),
          ] else ...[
            if (data.enabled)
              Text(
                '当前切换商户：${data.merchants.where((m) => m.id == data.merchantId).firstOrNull?.name ?? data.merchantId}',
              ),
            for (final hour in [
              ...hours.where((h) => h.hour >= 12),
              ...hours.where((h) => h.hour < 12),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '${hour.hour}　${hour.amount}　${hour.publicAmount}　${hour.total}',
                ),
              ),
            FilledButton(
              onPressed: editable
                  ? (data.enabled
                        ? () => write(
                            '取消商户切换',
                            (guard) => widget.loader.cancelSwitch(guard),
                          )
                        : choose)
                  : null,
              child: Text(data.enabled ? '取消切换' : '商户号一键切换'),
            ),
          ],
        ],
      ),
    );
  }
}
