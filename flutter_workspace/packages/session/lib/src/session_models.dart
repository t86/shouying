import 'package:protocol/protocol.dart';

enum MachineAccessMode {
  orgManager(1, ClientKind.orgManager),
  booking(2, ClientKind.booking),
  order(4, ClientKind.order),
  cashier(8, ClientKind.cashier),
  vip(16, ClientKind.vip),
  erp(32, ClientKind.erp),
  erpAdmin(64, ClientKind.erpAdmin),
  wine(256, ClientKind.wine),
  queueDisplay(512, ClientKind.queueDisplay);

  const MachineAccessMode(this.wireValue, this.client);

  final int wireValue;
  final ClientKind client;

  /// Maps exact integer and canonical integer-string wire values.
  ///
  /// On JavaScript/DDC, JSON decoding represents an integral `1.0` as an
  /// `int`, so its original numeric lexeme cannot be distinguished from `1`
  /// here. Enforcing that lexical distinction on Web requires raw-token type
  /// metadata from the protocol layer. Native runtimes reject doubles; Web
  /// rejects all malformed forms whose representation remains distinguishable.
  static MachineAccessMode? fromWire(Object? value) {
    final intValue = switch (value) {
      int() when value.runtimeType == int => value,
      String()
          when value.length <= 3 && RegExp(r'^[1-9]\d*$').hasMatch(value) =>
        int.tryParse(value),
      _ => null,
    };
    if (intValue == null) return null;
    for (final mode in values) {
      if (mode.wireValue == intValue) return mode;
    }
    return null;
  }
}

enum EmployeeLoginType {
  account(1),
  card(2);

  const EmployeeLoginType(this.wireValue);

  final int wireValue;
}

final class MachineSession {
  const MachineSession({
    required this.machineId,
    required this.machineName,
    required this.client,
  });

  final String machineId;
  final String machineName;
  final ClientKind client;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MachineSession &&
          machineId == other.machineId &&
          machineName == other.machineName &&
          client == other.client;

  @override
  int get hashCode => Object.hash(machineId, machineName, client);

  @override
  String toString() =>
      'MachineSession(machineId: $machineId, machineName: $machineName, '
      'client: ${client.name})';
}

final class UserSession {
  const UserSession({
    required this.employeeId,
    required this.name,
    required this.stationId,
  });

  final String employeeId;
  final String name;
  final String stationId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSession &&
          employeeId == other.employeeId &&
          name == other.name &&
          stationId == other.stationId;

  @override
  int get hashCode => Object.hash(employeeId, name, stationId);

  @override
  String toString() =>
      'UserSession(employeeId: $employeeId, name: $name, '
      'stationId: $stationId)';
}
