import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

int _integer(Object? value, {int minimum = 0}) {
  final n = value is num && value.isFinite && value % 1 == 0
      ? value.toInt()
      : value is String
      ? int.tryParse(value)
      : null;
  if (n == null || n < minimum || n.abs() > 9007199254740991) {
    throw const FormatException();
  }
  return n;
}

String _text(Object? value) {
  if (value == null) return '';
  if (value is! String && value is! num) throw const FormatException();
  return '$value';
}

String _aliasText(Map row, List<String> keys) {
  for (final key in keys) {
    final value = row[key];
    if (value != null && value != '' && value != 0 && value != false) {
      return _text(value);
    }
  }
  return '';
}

List<CashierMerchant> _merchants(Object? data, {String kindKey = 'g'}) {
  final items = _rows(data)
      .map((row) => CashierMerchant.fromWire(row, kindKey: kindKey))
      .toList();
  if (items.map((item) => item.id).toSet().length != items.length) {
    throw const FormatException();
  }
  return List.unmodifiable(items);
}

List<Map> _rows(Object? value) {
  if (value == null) return const [];
  if (value is! List || value.length > 10000) throw const FormatException();
  return [
    for (final row in value)
      if (row is Map) row else throw const FormatException(),
  ];
}

Set<int> _ids(Object? value) {
  if (value == null) return {};
  if (value is! List) throw const FormatException();
  return {for (final id in value) _integer(id, minimum: 1)};
}

Set<int>? _closed(Map data) {
  for (final key in const [
    'closed_cnl_cfg_ids',
    'close_cnl_cfg_ids',
    'close_cnls',
    'close_cnl_ids',
    'closed_cnl_ids',
  ]) {
    if (data.containsKey(key)) return _ids(data[key]);
  }
  return null;
}

final class CashierMerchant {
  const CashierMerchant({
    required this.id,
    required this.name,
    required this.kind,
    this.holder = '',
    this.bank = '',
  });
  final int id, kind;
  final String name, holder, bank;
  factory CashierMerchant.fromWire(Map row, {String kindKey = 'g'}) =>
      CashierMerchant(
        id: _integer(row['id'], minimum: 1),
        name: _text(row['n']),
        kind: _integer(row[kindKey] ?? row['gs'] ?? row['g'] ?? 0),
        holder: _aliasText(row, const ['un', 'u', 'hn']),
        bank: _aliasText(row, const ['bn', 'no', 'acct_no']),
      );
}

final class CashierMerchantAssignment {
  const CashierMerchantAssignment({
    required this.entityId,
    this.privateIds = const {},
    this.regionIds = const {},
    this.isDefault = false,
    this.closedIds,
  });
  final int entityId;
  final Set<int> privateIds, regionIds;
  final bool isDefault;
  final Set<int>? closedIds;
}

final class CashierMerchantGroups {
  const CashierMerchantGroups({
    this.merchants = const [],
    this.regions = const {},
    this.assignments = const [],
    this.closedIds = const {},
  });
  final List<CashierMerchant> merchants;
  final Map<int, String> regions;
  final List<CashierMerchantAssignment> assignments;
  final Set<int> closedIds;
  List<CashierMerchant> get entities =>
      merchants.where((m) => m.kind == 1).toList();
  CashierMerchantAssignment? assignment(int id) {
    for (final group in assignments) {
      if (group.entityId == id) return group;
    }
    return null;
  }

  Set<int> closedFor(int id) => assignment(id)?.closedIds ?? closedIds;
  List<CashierMerchant> onlineMerchants(int entityId) {
    final group = assignment(entityId);
    return group == null
        ? merchants
        : merchants
              .where((m) => m.id == entityId || group.privateIds.contains(m.id))
              .toList();
  }

  factory CashierMerchantGroups.fromWire(Map data) => CashierMerchantGroups(
    merchants: _merchants(data['cnl_cfg_def']),
    regions: {
      for (final row in _rows(data['region_def']))
        _integer(row['id'], minimum: 1): _text(row['n']),
    },
    assignments: [
      for (final row in _rows(data['cnl_cfg_grps']))
        CashierMerchantAssignment(
          entityId: _integer(row['id'], minimum: 1),
          privateIds: _ids(row['sids']),
          regionIds: _ids(row['rs']),
          isDefault: _integer(row['d'] ?? 2) == 1,
          closedIds: _closed(row),
        ),
    ],
    closedIds: _closed(data) ?? {},
  );
}

final class CashierMerchantHourRule {
  const CashierMerchantHourRule({
    required this.hour,
    required this.maxAmount,
    required this.merchantId,
  });
  final int hour, maxAmount, merchantId;
}

final class CashierMerchantSeat {
  const CashierMerchantSeat({
    required this.id,
    required this.name,
    this.merchantId = 0,
  });
  final int id, merchantId;
  final String name;
}

final class CashierMerchantRegion {
  const CashierMerchantRegion({
    required this.id,
    required this.name,
    this.seats = const [],
  });
  final int id;
  final String name;
  final List<CashierMerchantSeat> seats;
}

final class CashierMerchantConfig {
  const CashierMerchantConfig({
    required this.entityId,
    this.switchEnabled = false,
    this.maxAmount = 0,
    this.targetMerchantId = 0,
    this.defaultMerchantId = 0,
    this.merchants = const [],
    this.hours = const [],
    this.regions = const [],
  });
  final int entityId, maxAmount, targetMerchantId, defaultMerchantId;
  final bool switchEnabled;
  final List<CashierMerchant> merchants;
  final List<CashierMerchantHourRule> hours;
  final List<CashierMerchantRegion> regions;
  factory CashierMerchantConfig.fromWire(Map data, int entityId) {
    final mode = _integer(data['e_s']);
    if (mode != 1 && mode != 2) throw const FormatException();
    final hours = <int, CashierMerchantHourRule>{};
    for (final row in _rows(data['hour_cfgs'])) {
      final hour = _integer(row['h']);
      if (hour > 23 || hours.containsKey(hour)) throw const FormatException();
      hours[hour] = CashierMerchantHourRule(
        hour: hour,
        maxAmount: _integer(row['m'], minimum: -9007199254740991),
        merchantId: _integer(row['c']),
      );
    }
    return CashierMerchantConfig(
      entityId: entityId,
      switchEnabled: mode == 1,
      maxAmount: _integer(data['max_amt'], minimum: -9007199254740991),
      targetMerchantId: _integer(data['dest_cnl_cfg_id']),
      defaultMerchantId: _integer(data['def_cnl_cfg_id']),
      merchants: _merchants(data['cnl_cfgs'], kindKey: 'gs'),
      hours: [
        for (var h = 0; h < 24; h++)
          hours[h] ??
              CashierMerchantHourRule(hour: h, maxAmount: 0, merchantId: 0),
      ],
      regions: [
        for (final row in _rows(data['region_seats']))
          CashierMerchantRegion(
            id: _integer(row['id'], minimum: 1),
            name: _text(row['n']),
            seats: [
              for (final seat in _rows(row['ss']))
                CashierMerchantSeat(
                  id: _integer(seat['id'], minimum: 1),
                  name: _text(seat['n']),
                  merchantId: _integer(seat['c']),
                ),
            ],
          ),
      ],
    );
  }
}

final class CashierMerchantGroupsDraft {
  const CashierMerchantGroupsDraft({
    required this.entityIds,
    required this.defaultEntityId,
    required this.privateIdsByEntity,
    required this.regionIdsByEntity,
  });
  final List<int> entityIds;
  final int defaultEntityId;
  final Map<int, List<int>> privateIdsByEntity, regionIdsByEntity;
  Map<String, Object?> toWire() {
    if (entityIds.length != 2 ||
        entityIds.toSet().length != 2 ||
        !entityIds.contains(defaultEntityId)) {
      throw const FormatException();
    }
    for (final id in entityIds) {
      _integer(id, minimum: 1);
      if ((privateIdsByEntity[id] ?? []).isEmpty ||
          (regionIdsByEntity[id] ?? []).isEmpty) {
        throw const FormatException();
      }
    }
    for (final mapping in [privateIdsByEntity, regionIdsByEntity]) {
      final seen = <int>{};
      for (final id in entityIds) {
        for (final selected in mapping[id]!) {
          _integer(selected, minimum: 1);
          if (!seen.add(selected)) throw const FormatException();
        }
      }
    }
    return {
      'cnl_cfg_id1': entityIds[0],
      'cnl_cfg_id2': entityIds[1],
      'def_cnl_cfg_id': defaultEntityId,
      's_cfg_ids_1': privateIdsByEntity[entityIds[0]]!,
      's_cfg_ids_2': privateIdsByEntity[entityIds[1]]!,
      'region_ids_1': regionIdsByEntity[entityIds[0]]!,
      'region_ids_2': regionIdsByEntity[entityIds[1]]!,
    };
  }
}

final class CashierMerchantConfigDraft {
  const CashierMerchantConfigDraft({
    required this.entityId,
    required this.defaultMerchantId,
    required this.switchEnabled,
    required this.maxAmount,
    required this.targetMerchantId,
    required this.seatMerchants,
    required this.hours,
  });
  final int entityId, defaultMerchantId, maxAmount, targetMerchantId;
  final bool switchEnabled;
  final Map<int, int> seatMerchants;
  final List<CashierMerchantHourRule> hours;
  Map<String, Object?> toWire() {
    _integer(entityId);
    _integer(defaultMerchantId, minimum: 1);
    _integer(maxAmount, minimum: -9007199254740991);
    _integer(targetMerchantId, minimum: switchEnabled ? 1 : 0);
    if (hours.length != 24 || hours.map((h) => h.hour).toSet().length != 24) {
      throw const FormatException();
    }
    for (final h in hours) {
      if (h.hour < 0 || h.hour > 23) throw const FormatException();
      _integer(h.maxAmount, minimum: -9007199254740991);
      _integer(h.merchantId);
    }
    for (final seat in seatMerchants.entries) {
      _integer(seat.key, minimum: 1);
      _integer(seat.value);
    }
    final selected = seatMerchants.entries.where((e) => e.value != 0).toList();
    final ordered = [
      for (var h = 12; h < 24; h++) hours.singleWhere((r) => r.hour == h),
      for (var h = 0; h < 12; h++) hours.singleWhere((r) => r.hour == h),
    ];
    return {
      'cnl_cfg_id': entityId,
      'def_cnl_cfg_id': defaultMerchantId,
      'enable_switch': switchEnabled ? 1 : 2,
      'max_amt': switchEnabled ? maxAmount : 0,
      'dest_cnl_cfg_id': switchEnabled ? targetMerchantId : 0,
      'seat_ids': selected.map((e) => e.key).toList(),
      'seat_cnl_ids': selected.map((e) => e.value).toList(),
      'hour_ids': ordered.map((h) => h.hour).toList(),
      'hour_max_amts': ordered.map((h) => h.maxAmount).toList(),
      'hour_cnl_cfg_ids': ordered.map((h) => h.merchantId).toList(),
    };
  }
}

final class CashierMerchantHourAmount {
  const CashierMerchantHourAmount({
    required this.hour,
    required this.amount,
    required this.publicAmount,
    required this.total,
  });
  final int hour;
  final String amount, publicAmount, total;
}

final class CashierMerchantSwitchState {
  const CashierMerchantSwitchState({
    required this.enabled,
    required this.merchantId,
    required this.merchants,
  });
  final bool enabled;
  final int merchantId;
  final List<CashierMerchant> merchants;
}

const _shape = AppFailure(
  kind: FailureKind.protocol,
  code: 'merchant.invalid_data',
  safeMessage: '商户号数据格式不正确，请重新读取',
);
const _input = AppFailure(
  kind: FailureKind.business,
  code: 'merchant.invalid_input',
  safeMessage: '请核实商户、区域及金额配置（金额须为有界整数元）',
);
const _context = AppFailure(
  kind: FailureKind.authentication,
  code: 'merchant.context_changed',
  safeMessage: '登录、连接或页面状态已变化，请重新核实商户配置',
);
const _unknown = AppFailure(
  kind: FailureKind.unknown,
  code: 'merchant.result_unknown',
  safeMessage: '商户配置结果尚未确认，请读取服务端状态核实',
);

final class ProtocolCashierMerchantManagementApi {
  const ProtocolCashierMerchantManagementApi({required this.client});
  final ProtocolClient client;
  Future<Result<Map<String, Object?>>> _post(
    ClientKind kind,
    String path, {
    Map<String, Object?>? body,
    bool Function()? guard,
  }) async {
    if (kind != ClientKind.cashier) return const FailureResult(_context);
    try {
      final response = body == null
          ? await client.postWithoutBody(path, client: kind, canDispatch: guard)
          : await client.post(
              path,
              client: kind,
              body: body,
              canDispatch: guard,
            );
      if (response.failureOrNull case final f?) return FailureResult(f);
      final envelope = response.valueOrNull!;
      final code = _integer(envelope['code']);
      if (code != 1) {
        return const FailureResult(
          AppFailure(
            kind: FailureKind.business,
            code: 'merchant.rejected',
            safeMessage: '服务端拒绝操作，请核实配置',
          ),
        );
      }
      return Success(envelope);
    } on FormatException {
      return const FailureResult(_shape);
    } on Object {
      return const FailureResult(_unknown);
    }
  }

  Future<Result<T>> _read<T>(
    ClientKind kind,
    String path,
    T Function(Map) parse, {
    Map<String, Object?>? body,
  }) async {
    final result = await _post(kind, path, body: body);
    if (result.failureOrNull case final f?) return FailureResult(f);
    try {
      final data = result.valueOrNull!['data'];
      if (data is! Map) throw const FormatException();
      return Success(parse(data));
    } on Object {
      return const FailureResult(_shape);
    }
  }

  Future<Result<void>> _write(
    ClientKind kind,
    String path,
    Map<String, Object?>? Function() body,
    bool Function() guard,
  ) async {
    try {
      final result = await _post(kind, path, body: body(), guard: guard);
      return result.failureOrNull == null
          ? const Success(null)
          : FailureResult(result.failureOrNull!);
    } on FormatException {
      return const FailureResult(_input);
    } on Object {
      return const FailureResult(_unknown);
    }
  }

  Future<Result<CashierMerchantGroups>> groups(ClientKind kind) =>
      _read(kind, '/org/get_cnl_cfg_grp', CashierMerchantGroups.fromWire);
  Future<Result<CashierMerchantConfig>> config(
    ClientKind kind,
    int entityId,
  ) async {
    if (entityId < 0 || entityId > 9007199254740991) {
      return const FailureResult(_input);
    }
    return _read(
      kind,
      '/sel/get_cnl_cfg',
      (data) => CashierMerchantConfig.fromWire(data, entityId),
      body: entityId == 0 ? {} : {'cnl_cfg_id': entityId},
    );
  }

  Future<Result<void>> saveGroups(
    ClientKind kind,
    CashierMerchantGroupsDraft draft,
    bool Function() guard,
  ) => _write(kind, '/org/save_cnl_cfg_grp', draft.toWire, guard);
  Future<Result<void>> saveConfig(
    ClientKind kind,
    CashierMerchantConfigDraft draft,
    bool Function() guard,
  ) => _write(kind, '/sel/save_cnl_cfg', draft.toWire, guard);
  Future<Result<void>> setOnline(
    ClientKind kind,
    int id,
    bool enabled,
    bool Function() guard,
  ) => _write(
    kind,
    '/org/save_cnl_cfg_openclose',
    () => {'cnl_cfg_id': _integer(id, minimum: 1), 'close': enabled ? 2 : 1},
    guard,
  );
  Future<Result<List<CashierMerchantHourAmount>>> hours(
    ClientKind kind,
    int id,
  ) async {
    if (id <= 0 || id > 9007199254740991) return const FailureResult(_input);
    return _read(kind, '/sel/get_cnl_hour_amt', (data) {
      final result = <CashierMerchantHourAmount>[];
      for (final row in _rows(data['records'])) {
        final hour = _integer(row['h']);
        if (hour > 23) throw const FormatException();
        result.add(
          CashierMerchantHourAmount(
            hour: hour,
            amount: _text(row['c']),
            publicAmount: _text(row['g']),
            total: _text(row['t']),
          ),
        );
      }
      result.sort((a, b) => a.hour.compareTo(b.hour));
      return result;
    }, body: {'cnl_cfg_id': id});
  }

  Future<Result<CashierMerchantSwitchState>> switchState(ClientKind kind) =>
      _read(kind, '/sel/get_wkday_cnl_switch', (data) {
        final enabled = _integer(data['enabled']);
        return CashierMerchantSwitchState(
          enabled: enabled == 1,
          merchantId: _integer(data['id'] ?? 0),
          merchants: _merchants(data['cnl_cfgs'], kindKey: 'gs'),
        );
      });
  Future<Result<void>> enableSwitch(
    ClientKind kind,
    int id,
    bool Function() guard,
  ) => _write(
    kind,
    '/sel/enable_wkday_cnl_switch',
    () => {'cnl_cfg_id': _integer(id, minimum: 1)},
    guard,
  );
  Future<Result<void>> cancelSwitch(ClientKind kind, bool Function() guard) =>
      _write(kind, '/sel/cancel_wkday_cnl_switch', () => null, guard);
}

abstract interface class CashierMerchantManagementLoader {
  bool get needsVerification;
  Future<Result<void>> verify(bool Function() canAccept);
  Future<Result<CashierMerchantGroups>> groups();
  Future<Result<CashierMerchantConfig>> config(int entityId);
  Future<Result<void>> saveGroups(
    CashierMerchantGroupsDraft draft,
    bool Function() guard,
  );
  Future<Result<void>> saveConfig(
    CashierMerchantConfigDraft draft,
    bool Function() guard,
  );
  Future<Result<void>> setOnline(int id, bool enabled, bool Function() guard);
  Future<Result<List<CashierMerchantHourAmount>>> hours(int id);
  Future<Result<CashierMerchantSwitchState>> switchState();
  Future<Result<void>> enableSwitch(int id, bool Function() guard);
  Future<Result<void>> cancelSwitch(bool Function() guard);
}

final class SessionBoundCashierMerchantManagementLoader
    implements CashierMerchantManagementLoader {
  SessionBoundCashierMerchantManagementLoader({
    required this.session,
    required this.api,
    required this.phase,
    required this.generation,
  });
  final SessionRepository session;
  final ProtocolCashierMerchantManagementApi api;
  final ConnectionPhase Function() phase;
  final int Function() generation;
  bool _writing = false, _unknownResult = false;
  Future<Result<Object?>> Function(ClientKind)? _verificationRead;
  @override
  bool get needsVerification => _unknownResult;
  static const _busy = AppFailure(
    kind: FailureKind.business,
    code: 'merchant.verification_required',
    safeMessage: '商户操作正在处理或结果尚未确认，请显式读取核实后再操作',
  );
  bool Function() _capture([bool Function()? allowed]) {
    final user = session.currentUser, machine = session.currentMachine;
    final epoch = generation();
    return () =>
        !session.isClosed &&
        user != null &&
        machine?.client == ClientKind.cashier &&
        identical(user, session.currentUser) &&
        identical(machine, session.currentMachine) &&
        generation() == epoch &&
        phase() == ConnectionPhase.online &&
        (allowed?.call() ?? true);
  }

  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function(ClientKind, bool Function()) call, [
    bool Function()? allowed,
  ]) async {
    try {
      final current = _capture(allowed);
      if (!current()) return const FailureResult(_context);
      final result = await call(ClientKind.cashier, current);
      return current() ? result : const FailureResult(_context);
    } on Object {
      return const FailureResult(_unknown);
    }
  }

  Future<Result<void>> _mutate(
    Future<Result<void>> Function(ClientKind, bool Function()) call,
    bool Function() allowed,
    Future<Result<Object?>> Function(ClientKind) verifyRead,
  ) async {
    if (_writing || _unknownResult) return const FailureResult(_busy);
    final current = _capture(allowed);
    if (!current()) return const FailureResult(_context);
    _writing = true;
    _unknownResult = true;
    _verificationRead = verifyRead;
    try {
      final result = await call(ClientKind.cashier, current);
      if (!current()) return const FailureResult(_context);
      if (result.failureOrNull == null ||
          result.failureOrNull?.kind == FailureKind.business) {
        _unknownResult = false;
        _verificationRead = null;
      }
      return result;
    } on Object {
      return const FailureResult(_unknown);
    } finally {
      _writing = false;
    }
  }

  @override
  Future<Result<void>> verify(bool Function() canAccept) async {
    if (_writing) return const FailureResult(_busy);
    final current = _capture(canAccept);
    if (!current()) return const FailureResult(_context);
    if (!_unknownResult) return const Success(null);
    final check = _verificationRead;
    if (check == null) return const FailureResult(_context);
    _writing = true;
    try {
      final result = await check(ClientKind.cashier);
      if (!current()) return const FailureResult(_context);
      if (result.failureOrNull case final failure?)
        return FailureResult(failure);
      _unknownResult = false;
      _verificationRead = null;
      return const Success(null);
    } on Object {
      return const FailureResult(_unknown);
    } finally {
      _writing = false;
    }
  }

  @override
  Future<Result<CashierMerchantGroups>> groups() =>
      _guard((k, g) => api.groups(k));
  @override
  Future<Result<CashierMerchantConfig>> config(int id) =>
      _guard((k, g) => api.config(k, id));
  @override
  Future<Result<void>> saveGroups(
    CashierMerchantGroupsDraft d,
    bool Function() g,
  ) => _mutate((k, c) => api.saveGroups(k, d, c), g, api.groups);
  @override
  Future<Result<void>> saveConfig(
    CashierMerchantConfigDraft d,
    bool Function() g,
  ) => _mutate(
    (k, c) => api.saveConfig(k, d, c),
    g,
    (kind) => api.config(kind, d.entityId),
  );
  @override
  Future<Result<void>> setOnline(int id, bool enabled, bool Function() g) =>
      _mutate((k, c) => api.setOnline(k, id, enabled, c), g, api.groups);
  @override
  Future<Result<List<CashierMerchantHourAmount>>> hours(int id) =>
      _guard((k, g) => api.hours(k, id));
  @override
  Future<Result<CashierMerchantSwitchState>> switchState() =>
      _guard((k, g) => api.switchState(k));
  @override
  Future<Result<void>> enableSwitch(int id, bool Function() g) =>
      _mutate((k, c) => api.enableSwitch(k, id, c), g, api.switchState);
  @override
  Future<Result<void>> cancelSwitch(bool Function() g) =>
      _mutate((k, c) => api.cancelSwitch(k, c), g, api.switchState);
}
