import 'package:card_table/src/booking_queue.dart';
import 'package:card_table/src/booking_reports_loader.dart';
import 'package:card_table/src/wine_export_saver.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

typedef BookingQueueAction =
    Future<Result<void>> Function({
      required int queueTypeId,
      required int queueNo,
    });

typedef BookingQueueExporter =
    Future<Result<String>> Function({int queueTypeId, int status});

final class ProtocolBookingQueueLoader {
  const ProtocolBookingQueueLoader({
    required this.api,
    this.saver = saveWineExport,
  });
  final ProtocolBookingQueueApi api;
  final BookingExportFileSaver saver;

  Future<Result<void>> call({
    required int queueTypeId,
    required int queueNo,
    ClientKind client = ClientKind.booking,
  }) => api.call(
    queueTypeId: queueTypeId,
    queueNo: queueNo,
    client: client,
  );

  Future<Result<void>> arrive({
    required int queueTypeId,
    required int queueNo,
    ClientKind client = ClientKind.booking,
  }) => api.arrive(
    queueTypeId: queueTypeId,
    queueNo: queueNo,
    client: client,
  );

  Future<Result<void>> expired({
    required int queueTypeId,
    required int queueNo,
    ClientKind client = ClientKind.booking,
  }) => api.expired(
    queueTypeId: queueTypeId,
    queueNo: queueNo,
    client: client,
  );

  Future<Result<String>> exportQueueList({
    int queueTypeId = 0,
    int status = 0,
    ClientKind client = ClientKind.booking,
    bool Function()? canDispatch,
  }) async {
    final result = await api.exportQueueList(
      queueTypeId: queueTypeId,
      status: status,
      client: client,
      canDispatch: canDispatch,
    );
    if (result.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    return saver(result.valueOrNull!, canSave: canDispatch);
  }
}
