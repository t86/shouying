/// S9 超管系统数据模型
int _wireInteger(Object? value, {int minimum = 0}) {
  final parsed = switch (value) {
    int() => value,
    num() when value.isFinite && value % 1 == 0 => value.toInt(),
    String() when RegExp(r'^\d+$').hasMatch(value) => int.tryParse(value),
    _ => null,
  };
  if (parsed == null || parsed < minimum || parsed > 9007199254740991) {
    throw const FormatException();
  }
  return parsed;
}

String _wireText(Object? value, {bool required = false}) {
  if (value == null && !required) return '';
  if (value is! String || (required && value.trim().isEmpty)) {
    throw const FormatException();
  }
  return value;
}

List<Map<String, Object?>> _wireRows(Object? value) {
  if (value == null) return const [];
  if (value is! List || value.length > 10000) throw const FormatException();
  return [
    for (final row in value)
      if (row is Map)
        Map<String, Object?>.from(row)
      else
        throw const FormatException(),
  ];
}

final class SmgrDeptItem {
  const SmgrDeptItem({
    this.id = 0,
    this.name = '',
    this.children = const <SmgrDeptItem>[],
  });

  factory SmgrDeptItem.fromWire(Map<String, Object?> map) {
    final list = _wireRows(map['subs']).map(SmgrDeptItem.fromWire).toList();
    return SmgrDeptItem(
      id: _wireInteger(map['id'], minimum: 1),
      name: _wireText(map['n']),
      children: list,
    );
  }

  final int id;
  final String name;
  final List<SmgrDeptItem> children;

  Map<String, Object?> toWire() => {
    'id': id,
    'n': name,
    'subs': children.map((c) => c.toWire()).toList(),
  };
}

final class SmgrStationItem {
  const SmgrStationItem({this.id = 0, this.name = ''});

  factory SmgrStationItem.fromWire(Map<String, Object?> map) => SmgrStationItem(
    id: _wireInteger(map['id'], minimum: 1),
    name: _wireText(map['n']),
  );

  final int id;
  final String name;

  Map<String, Object?> toWire() => {'id': id, 'n': name};
}

final class SmgrEmpItem {
  const SmgrEmpItem({
    this.id = 0,
    this.code = '',
    this.name = '',
    this.deptName = '',
    this.status = '有效',
  });

  factory SmgrEmpItem.fromWire(Map<String, Object?> map) => SmgrEmpItem(
    id: _wireInteger(map['id'], minimum: 1),
    code: _wireText(map['c']),
    name: _wireText(map['n']),
    deptName: _wireText(map['d']),
    status: _wireText(map['s'], required: true),
  );

  final int id;
  final String code;
  final String name;
  final String deptName;
  final String status;

  Map<String, Object?> toWire() => {
    'id': id,
    'c': code,
    'n': name,
    'd': deptName,
    's': status,
  };
}

final class SmgrStationRow {
  const SmgrStationRow({
    this.id = 0,
    this.name = '',
    this.empCount = 0,
    this.status = '有效',
    this.isAdmin = false,
    this.employees = const <SmgrEmpItem>[],
    this.isExpanded = false,
  });

  factory SmgrStationRow.fromWire(Map<String, Object?> map) {
    final list = _wireRows(map['es']).map(SmgrEmpItem.fromWire).toList();
    return SmgrStationRow(
      id: _wireInteger(map['id'], minimum: 1),
      name: _wireText(map['n']),
      empCount: _wireInteger(map['c']),
      status: _wireText(map['s'], required: true),
      isAdmin: _wireInteger(map['a']) == 1,
      employees: list,
      isExpanded: map['show'] == true,
    );
  }

  final int id;
  final String name;
  final int empCount;
  final String status;
  final bool isAdmin;
  final List<SmgrEmpItem> employees;
  final bool isExpanded;

  SmgrStationRow copyWith({
    int? id,
    String? name,
    int? empCount,
    String? status,
    bool? isAdmin,
    List<SmgrEmpItem>? employees,
    bool? isExpanded,
  }) => SmgrStationRow(
    id: id ?? this.id,
    name: name ?? this.name,
    empCount: empCount ?? this.empCount,
    status: status ?? this.status,
    isAdmin: isAdmin ?? this.isAdmin,
    employees: employees ?? this.employees,
    isExpanded: isExpanded ?? this.isExpanded,
  );

  Map<String, Object?> toWire() => {
    'id': id,
    'n': name,
    'c': empCount,
    's': status,
    'a': isAdmin ? 1 : 0,
    'es': employees.map((e) => e.toWire()).toList(),
    'show': isExpanded,
  };
}

final class SmgrInitData {
  const SmgrInitData({
    this.departments = const <SmgrDeptItem>[],
    this.stations = const <SmgrStationItem>[],
    this.stationRows = const <SmgrStationRow>[],
  });

  factory SmgrInitData.fromWire(Map<String, Object?> map) {
    return SmgrInitData(
      departments: _wireRows(map['depts']).map(SmgrDeptItem.fromWire).toList(),
      stations: _wireRows(map['stations'])
          .map(SmgrStationItem.fromWire)
          .toList(),
      stationRows: _wireRows(map['station_emps'])
          .map(SmgrStationRow.fromWire)
          .toList(),
    );
  }

  final List<SmgrDeptItem> departments;
  final List<SmgrStationItem> stations;
  final List<SmgrStationRow> stationRows;
}

final class SuperAdminLoginResult {
  const SuperAdminLoginResult({
    this.token = '',
    this.empId = 2,
    this.client = 'appinfo',
  });

  factory SuperAdminLoginResult.fromWire(Map<String, Object?> map) {
    final token = _wireText(map['data'], required: true);
    if (RegExp(r'\s').hasMatch(token)) throw const FormatException();
    return SuperAdminLoginResult(token: token);
  }

  final String token;
  final int empId;
  final String client;
}

final class TerminalRegisterResult {
  const TerminalRegisterResult({this.authMode = 0, this.message = '注册成功'});

  factory TerminalRegisterResult.fromWire(Map<String, Object?> map) =>
      TerminalRegisterResult(
        authMode: _wireInteger(map['auth_mode']),
        message: map['msg'] == null ? '注册成功' : _wireText(map['msg']),
      );

  final int authMode;
  final String message;
}
