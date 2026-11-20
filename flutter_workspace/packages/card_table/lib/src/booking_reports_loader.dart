import 'package:card_table/src/booking_reports.dart';
import 'package:card_table/src/wine_export_saver.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

typedef SeatOpenLogLoader =
    Future<Result<List<SeatOpenLogRow>>> Function({
      String key,
      int deptId,
      int typeId,
    });

typedef SeatChangeLogLoader = Future<Result<List<SeatChangeLogRow>>> Function();
typedef BookListLoader = Future<Result<List<BookListRow>>> Function();
typedef OnlineBookListLoader = Future<Result<List<OnlineBookListRow>>> Function();
typedef SeatOpeningLoader = Future<Result<List<SeatOpeningRow>>> Function();
typedef DeptRegionSeatOpenLoader =
    Future<Result<DeptRegionSeatOpenData>> Function();

typedef SeatOpenLogExporter =
    Future<Result<String>> Function({String key, int typeId});
typedef BookingReportExporter = Future<Result<String>> Function();
typedef BookingExportFileSaver =
    Future<Result<String>> Function(
      ProtocolBinaryFile file, {
      bool Function()? canSave,
    });

final class ProtocolBookingReportsLoader {
  const ProtocolBookingReportsLoader({
    required this.api,
    this.saver = saveWineExport,
  });
  final ProtocolBookingReportsApi api;
  final BookingExportFileSaver saver;

  Future<Result<List<SeatOpenLogRow>>> loadSeatOpenLog({
    String key = '',
    int deptId = 0,
    int typeId = 1,
    ClientKind client = ClientKind.booking,
  }) => api.getSeatOpenLog(
    client: client,
    key: key,
    deptId: deptId,
    typeId: typeId,
  );

  Future<Result<List<SeatChangeLogRow>>> loadSeatChangeLog({
    ClientKind client = ClientKind.booking,
  }) => api.getSeatChangeLog(client: client);

  Future<Result<List<BookListRow>>> loadBookList({
    ClientKind client = ClientKind.booking,
  }) => api.getBookList(client: client);

  Future<Result<List<OnlineBookListRow>>> loadOnlineBookList({
    ClientKind client = ClientKind.booking,
  }) => api.getOnlineBookList(client: client);

  Future<Result<List<SeatOpeningRow>>> loadSeatOpeningList({
    ClientKind client = ClientKind.booking,
  }) => api.getSeatOpeningList(client: client);

  Future<Result<DeptRegionSeatOpenData>> loadDeptRegionSeatOpenList({
    ClientKind client = ClientKind.booking,
  }) => api.getDeptRegionSeatOpenList(client: client);

  Future<Result<String>> exportSeatOpenLog({
    String key = '',
    int typeId = 1,
    ClientKind client = ClientKind.booking,
    bool Function()? canDispatch,
  }) => _exportAndSave(
    () => api.exportSeatOpenLog(
      client: client,
      key: key,
      typeId: typeId,
      canDispatch: canDispatch,
    ),
    canDispatch: canDispatch,
  );

  Future<Result<String>> exportBookList({
    ClientKind client = ClientKind.booking,
    bool Function()? canDispatch,
  }) => _exportAndSave(
    () => api.exportBookList(client: client, canDispatch: canDispatch),
    canDispatch: canDispatch,
  );

  Future<Result<String>> exportOnlineBookList({
    ClientKind client = ClientKind.booking,
    bool Function()? canDispatch,
  }) => _exportAndSave(
    () => api.exportOnlineBookList(client: client, canDispatch: canDispatch),
    canDispatch: canDispatch,
  );

  Future<Result<String>> exportSeatOpeningList({
    ClientKind client = ClientKind.booking,
    bool Function()? canDispatch,
  }) => _exportAndSave(
    () => api.exportSeatOpeningList(client: client, canDispatch: canDispatch),
    canDispatch: canDispatch,
  );

  Future<Result<String>> exportDeptRegionSeatOpenList({
    ClientKind client = ClientKind.booking,
    bool Function()? canDispatch,
  }) => _exportAndSave(
    () => api.exportDeptRegionSeatOpenList(
      client: client,
      canDispatch: canDispatch,
    ),
    canDispatch: canDispatch,
  );

  Future<Result<String>> _exportAndSave(
    Future<Result<ProtocolBinaryFile>> Function() download, {
    bool Function()? canDispatch,
  }) async {
    final result = await download();
    if (result.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    return saver(result.valueOrNull!, canSave: canDispatch);
  }
}
