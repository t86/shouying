import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

/// 排队配置
final class QueueConfig {
  const QueueConfig({
    this.status = 1,
    this.soundOn = 1,
    this.soundCnt = 1,
    this.soundText = '',
    this.numberType = 1,
  });

  factory QueueConfig.fromWire(List<Object?> row) {
    return QueueConfig(
      status: _int(row, 0, defaultVal: 1),
      soundOn: _int(row, 1, defaultVal: 1),
      soundCnt: _int(row, 2, defaultVal: 1),
      soundText: _str(row, 3),
      numberType: _int(row, 4, defaultVal: 1),
    );
  }

  final int status;
  final int soundOn;
  final int soundCnt;
  final String soundText;
  final int numberType;
}

/// 排队类型
final class QueueType {
  const QueueType({
    required this.id,
    required this.status,
    required this.name,
    required this.numPrefix,
    this.minCnt = 1,
    this.maxCnt = 10,
    this.minCsmAmt = 0,
  });

  factory QueueType.fromWire(List<Object?> row) {
    return QueueType(
      id: _int(row, 0),
      status: _int(row, 1, defaultVal: 1),
      name: _str(row, 2),
      numPrefix: _str(row, 3),
      minCnt: _int(row, 4, defaultVal: 1),
      maxCnt: _int(row, 5, defaultVal: 10),
      minCsmAmt: _num(row, 6),
    );
  }

  final int id;
  final int status;
  final String name;
  final String numPrefix;
  final int minCnt;
  final int maxCnt;
  final num minCsmAmt;
}

/// 排队记录
final class QueueRecord {
  const QueueRecord({
    required this.wkdayId,
    required this.phoneNum,
    required this.name,
    required this.queueTypeId,
    required this.queueNo,
    required this.status,
    required this.obtainTime,
    required this.updateTime,
  });

  factory QueueRecord.fromWire(List<Object?> row) {
    return QueueRecord(
      wkdayId: _str(row, 0),
      phoneNum: _str(row, 1),
      name: _str(row, 2),
      queueTypeId: _int(row, 3),
      queueNo: _int(row, 4),
      status: _int(row, 5, defaultVal: 1),
      obtainTime: _str(row, 6),
      updateTime: _str(row, 7),
    );
  }

  final String wkdayId;
  final String phoneNum;
  final String name;
  final int queueTypeId;
  final int queueNo;
  final int status; // 1: 排队中, 2: 已过号, 3: 已取消, 5: 已进店
  final String obtainTime;
  final String updateTime;
}

/// 当前取号
final class QueueCurNumber {
  const QueueCurNumber({
    required this.wkdayId,
    required this.queueTypeId,
    required this.lastGenNum,
    required this.currNo,
    required this.currNoStatus,
    required this.waitCnt,
    required this.waitNo,
  });

  factory QueueCurNumber.fromWire(List<Object?> row) {
    return QueueCurNumber(
      wkdayId: _str(row, 0),
      queueTypeId: _int(row, 1),
      lastGenNum: _int(row, 2),
      currNo: _int(row, 3),
      currNoStatus: _int(row, 4),
      waitCnt: _int(row, 5),
      waitNo: _int(row, 6),
    );
  }

  final String wkdayId;
  final int queueTypeId;
  final int lastGenNum;
  final int currNo;
  final int currNoStatus;
  final int waitCnt;
  final int waitNo;
}

/// 卡台快照中的排队聚合数据
final class CardTableQueueSnapshot {
  const CardTableQueueSnapshot({
    this.config = const QueueConfig(),
    this.types = const [],
    this.records = const [],
    this.curNumbers = const [],
  });

  final QueueConfig config;
  final List<QueueType> types;
  final List<QueueRecord> records;
  final List<QueueCurNumber> curNumbers;
}

/// 格式化排队号码
String formatQueueNumber(String prefix, int number, int numberType) {
  if (number <= 0) return '-';
  final padded = switch (numberType) {
    2 => number.toString().padLeft(2, '0'),
    3 => number.toString().padLeft(3, '0'),
    _ => number.toString(),
  };
  return '$prefix$padded';
}

/// 格式化时间戳 YYYYMMDDHHmmss -> YYYY-MM-DD HH:mm:ss
String formatTimestamp(String ts) {
  if (ts.length < 14) return ts;
  return '${ts.substring(0, 4)}-${ts.substring(4, 6)}-${ts.substring(6, 8)} '
      '${ts.substring(8, 10)}:${ts.substring(10, 12)}:${ts.substring(12, 14)}';
}

/// 计算等待时长
String formatWaitDuration(String obtainTime, String? updateTime, int status) {
  if (obtainTime.length < 14) return '0分钟';
  try {
    final oYear = int.parse(obtainTime.substring(0, 4));
    final oMonth = int.parse(obtainTime.substring(4, 6));
    final oDay = int.parse(obtainTime.substring(6, 8));
    final oHour = int.parse(obtainTime.substring(8, 10));
    final oMin = int.parse(obtainTime.substring(10, 12));
    final oSec = int.parse(obtainTime.substring(12, 14));
    final start = DateTime(oYear, oMonth, oDay, oHour, oMin, oSec);

    DateTime end = DateTime.now();
    if (status != 1 && updateTime != null && updateTime.length >= 14) {
      final uYear = int.parse(updateTime.substring(0, 4));
      final uMonth = int.parse(updateTime.substring(4, 6));
      final uDay = int.parse(updateTime.substring(6, 8));
      final uHour = int.parse(updateTime.substring(8, 10));
      final uMin = int.parse(updateTime.substring(10, 12));
      final uSec = int.parse(updateTime.substring(12, 14));
      end = DateTime(uYear, uMonth, uDay, uHour, uMin, uSec);
    }

    final diff = end.difference(start);
    final minutes = diff.inMinutes;
    if (minutes <= 0) return '1分钟';
    final hours = minutes ~/ 60;
    final remMin = minutes % 60;
    if (hours > 0) {
      return '$hours小时$remMin分钟';
    }
    return '$minutes分钟';
  } catch (_) {
    return '0分钟';
  }
}

/// 排队 API 客户端
final class ProtocolBookingQueueApi {
  const ProtocolBookingQueueApi({required this.client});
  final ProtocolClient client;

  /// 叫号
  Future<Result<void>> call({
    required int queueTypeId,
    required int queueNo,
    ClientKind client = ClientKind.booking,
  }) => _postAction(
    '/custq/call',
    <String, Object?>{
      'queue_type_id': queueTypeId,
      'queue_no': queueNo,
    },
    '叫号',
    client,
  );

  /// 进店
  Future<Result<void>> arrive({
    required int queueTypeId,
    required int queueNo,
    ClientKind client = ClientKind.booking,
  }) => _postAction(
    '/custq/arrive',
    <String, Object?>{
      'queue_type_id': queueTypeId,
      'queue_no': queueNo,
    },
    '进店',
    client,
  );

  /// 过号
  Future<Result<void>> expired({
    required int queueTypeId,
    required int queueNo,
    ClientKind client = ClientKind.booking,
  }) => _postAction(
    '/custq/expired',
    <String, Object?>{
      'queue_type_id': queueTypeId,
      'queue_no': queueNo,
    },
    '过号',
    client,
  );

  /// 导出排队列表 Excel
  Future<Result<ProtocolBinaryFile>> exportQueueList({
    int queueTypeId = 0,
    int status = 0,
    ClientKind client = ClientKind.booking,
    bool Function()? canDispatch,
  }) => this.client.postBinary(
    '/custq/exp_cust_queue_list',
    body: <String, Object?>{
      'queue_type_id': queueTypeId > 0 ? queueTypeId : 0,
      'status': status > 0 ? status : 0,
    },
    client: client,
    fallbackFileName: '排队列表.xlsx',
    canDispatch: canDispatch,
  );

  Future<Result<void>> _postAction(
    String path,
    Map<String, Object?> body,
    String actionName,
    ClientKind client,
  ) async {
    final response = await this.client.post(
      path,
      body: body,
      client: client,
    );
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null || code != 1) {
      final msg = envelope['msg'];
      return FailureResult(AppFailure(
        kind: FailureKind.business,
        code: 'business.queue_${path.split('/').last}_rejected',
        safeMessage: msg is String && msg.isNotEmpty ? msg : '$actionName失败，请稍后重试',
      ));
    }
    return const Success(null);
  }

  static int? _wireCode(Object? value) => switch (value) {
    num() when value.isFinite && value % 1 == 0 => value.toInt(),
    String() when RegExp(r'^-?\d{1,10}$').hasMatch(value) => int.tryParse(value),
    _ => null,
  };
}

int _int(List<Object?> row, int index, {int defaultVal = 0}) {
  if (index >= row.length) return defaultVal;
  final val = row[index];
  return switch (val) {
    num() => val.toInt(),
    String() => int.tryParse(val) ?? defaultVal,
    _ => defaultVal,
  };
}

num _num(List<Object?> row, int index, {num defaultVal = 0}) {
  if (index >= row.length) return defaultVal;
  final val = row[index];
  return switch (val) {
    num() => val,
    String() => num.tryParse(val) ?? defaultVal,
    _ => defaultVal,
  };
}

String _str(List<Object?> row, int index, {String defaultVal = ''}) {
  if (index >= row.length) return defaultVal;
  final val = row[index];
  return val == null ? defaultVal : val.toString();
}
