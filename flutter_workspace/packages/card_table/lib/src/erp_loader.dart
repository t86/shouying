import 'package:card_table/src/erp_api.dart';
import 'package:card_table/src/erp_models.dart';
import 'package:card_table/src/erp_sout_workflow.dart';
import 'package:foundation/foundation.dart';
import 'package:session/session.dart';
import 'package:protocol/protocol.dart';

abstract interface class ErpLoader {
  // S8.P1 主数据
  Future<Result<List<ErpNegStoreAlert>>> loadNegStoreAlerts();
  Future<Result<List<ErpUnboundPrdAlert>>> loadUnboundPrdAlerts();
  Future<Result<List<ErpStoreItem>>> loadStores();
  Future<Result<void>> saveStore(ErpStoreItem store);
  Future<Result<void>> toggleStoreStatus(String storeId, bool enable);
  Future<Result<void>> deleteStore(String storeId);
  Future<Result<List<ErpMatCate>>> loadMatCateTree();
  Future<Result<List<ErpMatItem>>> loadMats({
    String? oneCateId,
    String? twoCateId,
    String? keyword,
  });
  Future<Result<void>> saveMat(ErpMatItem mat);
  Future<Result<void>> toggleMatStatus(String matId, bool enable);
  Future<Result<void>> deleteMat(String matId);
  Future<Result<List<ErpComparePrdItem>>> loadComparePrds(int type);
  Future<Result<void>> bindMatPrd({
    required String prdId,
    required String matId,
  });
  Future<Result<void>> closeBindPrds(List<String> prdIds);
  Future<Result<List<ErpSupplierItem>>> loadSuppliers();
  Future<Result<void>> saveSupplier(ErpSupplierItem supplier);
  Future<Result<void>> toggleSupplierStatus(String supplierId, bool enable);
  Future<Result<void>> deleteSupplier(String supplierId);

  // S8.P2 入库
  Future<Result<List<ErpSinItem>>> loadSinList({
    String? beginDay,
    String? endDay,
    int? status,
  });
  Future<Result<List<ErpMatItem>>> searchSinMats(String keyword);
  Future<Result<ErpStockOptions>> loadSinOptions();
  Future<Result<List<ErpStoreItem>>> loadSoutStores();
  Future<Result<List<ErpStockMaterial>>> searchStockMaterials({
    required bool outgoing,
    required String keyword,
    String storeId = '',
  });
  Future<Result<void>> createSinOrder(Map<String, Object?> payload);
  Future<Result<void>> reverseSinOrder(String billId);
  Future<Result<void>> redPunchSinOrder(String billId);
  Future<Result<List<ErpSindItem>>> loadSindList({
    String? beginDay,
    String? endDay,
    int? status,
  });
  Future<Result<void>> batchSindIn(List<String> billIds);
  Future<Result<void>> partSindIn(Map<String, Object?> payload);
  Future<Result<void>> applySindSh(Map<String, Object?> payload);
  Future<Result<List<ErpDisputeItem>>> loadDisputeInList({
    String? beginDay,
    String? endDay,
    int? status,
  });
  Future<Result<void>> confirmDisputeIn(String disputeId);
  Future<Result<void>> cancelDisputeIn(String disputeId);
  Future<Result<void>> rejectDisputeIn(String disputeId);

  // S8.P3 出库
  Future<Result<List<ErpSoutItem>>> loadSoutList({
    String? beginDay,
    String? endDay,
    int? status,
  });
  Future<Result<void>> createSoutOrder(Map<String, Object?> payload);
  Future<Result<void>> reverseSoutOrder(String billId);
  Future<Result<void>> redPunchSoutOrder(String billId);
  Future<Result<List<ErpSoutdItem>>> loadSoutdList({
    String? beginDay,
    String? endDay,
    int? status,
  });
  Future<Result<void>> createSoutdOrder(Map<String, Object?> payload);
  Future<Result<void>> reverseSoutdOrder(String billId);
  Future<Result<void>> redPunchSoutdOrder(String billId);
  Future<Result<List<ErpDisputeItem>>> loadDisputeOutList({
    String? beginDay,
    String? endDay,
    int? status,
  });
  Future<Result<void>> rejectDisputeOut(String disputeId);
  Future<Result<void>> redPunchDisputeOut(String disputeId);
  Future<Result<void>> breakLossDisputeOut(String disputeId);

  // S8.P4 空瓶
  Future<Result<List<ErpEmptyInItem>>> loadEmptyInList({
    String? beginDay,
    String? endDay,
  });
  Future<Result<void>> confirmEmptyIn(String billId);
  Future<Result<void>> redPunchEmptyIn(String billId);
  Future<Result<List<ErpEmptyInvtItem>>> loadEmptyInvtList({String? keyword});
  Future<Result<void>> submitEmptyOut(Map<String, Object?> payload);
  Future<Result<List<ErpEmptyOutItem>>> loadEmptyOutList({
    String? beginDay,
    String? endDay,
  });
  Future<Result<void>> redPunchEmptyOut(String billId);

  // S8.P5 报表
  Future<Result<ErpReportParams>> loadReportParams();
  Future<Result<List<ErpMatNowInvtItem>>> loadMatNowInvt({
    String? storeId,
    String? keyword,
  });
  Future<Result<List<ErpMatMonthInvtItem>>> loadMatMonthInvt({
    String? storeId,
    String? month,
  });
  Future<Result<List<ErpInOutRecItem>>> loadInRecs({
    String? storeId,
    String? beginDay,
    String? endDay,
  });
  Future<Result<List<ErpInOutRecItem>>> loadOutRecs({
    String? storeId,
    String? beginDay,
    String? endDay,
  });
  Future<Result<List<ErpInOutSumItem>>> loadInSum({
    String? storeId,
    String? beginDay,
    String? endDay,
  });
  Future<Result<List<ErpInOutSumItem>>> loadOutSum({
    String? storeId,
    String? beginDay,
    String? endDay,
  });
  Future<Result<List<ErpPsiItem>>> loadStorePsi({
    String? storeId,
    String? date,
  });
  Future<Result<List<ErpEmptyOperItem>>> loadEmptyInOperList({
    String? beginDay,
    String? endDay,
  });
  Future<Result<List<ErpEmptyOperItem>>> loadEmptyOutOperList({
    String? beginDay,
    String? endDay,
  });
}

abstract interface class ErpReportLoader {
  Object? get reportContext;
  Future<Result<ErpReportParams>> loadReportOptions({
    required bool Function() canDispatch,
  });
  Future<Result<ErpReportPage>> loadReport(
    ErpReportQuery query, {
    required bool Function() canDispatch,
  });
  Future<Result<ProtocolBinaryFile>> exportReport(
    ErpReportQuery query, {
    required bool Function() canDispatch,
  });
}

final class _ErpSoutContext {
  const _ErpSoutContext(this.user, this.machine, this.epoch);
  final Object user, machine;
  final int epoch;
  @override
  bool operator ==(Object other) =>
      other is _ErpSoutContext &&
      identical(user, other.user) &&
      identical(machine, other.machine) &&
      epoch == other.epoch;
  @override
  int get hashCode =>
      Object.hash(identityHashCode(user), identityHashCode(machine), epoch);
}

final class ProtocolErpLoader
    implements ErpLoader, ErpSoutWorkflowLoader, ErpReportLoader {
  const ProtocolErpLoader({
    required this.api,
    required this.session,
    this.isOnline,
    this.generation,
  });

  final ProtocolErpApi api;
  final SessionRepository session;
  final bool Function()? isOnline;
  final int Function()? generation;
  @override
  Object? get reportContext => soutContext;

  Future<Result<T>> _reportGuard<T>(
    bool Function() canDispatch,
    Future<Result<T>> Function(ProtocolErpApi, bool Function()) action,
  ) async {
    const stale = AppFailure(
      kind: FailureKind.authentication,
      code: 'erp.report_context_changed',
      safeMessage: '页面、权限、登录或连接已变化，请重新打开报表',
    );
    final token = reportContext;
    bool current() {
      try {
        return token != null && token == reportContext && canDispatch();
      } on Object {
        return false;
      }
    }

    if (!current()) return const FailureResult(stale);
    try {
      final bound = ProtocolErpApi(
        client: api.client,
        clientKind: session.currentMachine!.client,
      );
      final result = await action(bound, current);
      return current() ? result : const FailureResult(stale);
    } on Object {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.unknown,
          code: 'erp.report_failed',
          safeMessage: '报表操作失败，请重试',
        ),
      );
    }
  }

  @override
  Future<Result<ErpReportPage>> loadReport(
    ErpReportQuery query, {
    required bool Function() canDispatch,
  }) => _reportGuard(
    canDispatch,
    (bound, current) => bound.readReport(query, canDispatch: current),
  );
  @override
  Future<Result<ErpReportParams>> loadReportOptions({
    required bool Function() canDispatch,
  }) => _reportGuard(
    canDispatch,
    (bound, current) => bound.readReportOptions(canDispatch: current),
  );
  @override
  Future<Result<ProtocolBinaryFile>> exportReport(
    ErpReportQuery query, {
    required bool Function() canDispatch,
  }) => _reportGuard(
    canDispatch,
    (bound, current) => bound.exportReport(query, canDispatch: current),
  );
  @override
  Object? get soutContext {
    final user = session.currentUser,
        machine = session.currentMachine,
        epoch = generation?.call();
    return user == null ||
            machine == null ||
            session.isClosed ||
            ![ClientKind.erp, ClientKind.erpAdmin].contains(machine.client) ||
            isOnline?.call() != true ||
            epoch == null
        ? null
        : _ErpSoutContext(user, machine, epoch);
  }

  @override
  Future<Result<ErpSoutPage>> loadOtherOutPage({
    required String beginDay,
    required String endDay,
    int recordType = 0,
    String remark = '',
    int page = 1,
    int pageSize = 20,
  }) => _guard(
    (api) => api.getOtherOutPage(
      beginDay: beginDay,
      endDay: endDay,
      recordType: recordType,
      remark: remark,
      page: page,
      pageSize: pageSize,
    ),
  );
  @override
  Future<Result<ErpSoutDocument>> loadOtherOutDocument(
    String id,
    ErpSoutDocumentMode mode,
  ) => _guard((api) => api.getOtherOutDocument(id, mode));
  @override
  Future<Result<void>> reverseOtherOutWhole(String id) async {
    final result = await _guard((api) => api.reverseOtherOutWhole(id));
    return result.failureOrNull == null
        ? const Success(null)
        : FailureResult(result.failureOrNull!);
  }

  @override
  Future<Result<void>> reverseOtherOutLines(Map<int, double> counts) async {
    final result = await _guard((api) => api.reverseOtherOutLines(counts));
    return result.failureOrNull == null
        ? const Success(null)
        : FailureResult(result.failureOrNull!);
  }

  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function(ProtocolErpApi api) run,
  ) async {
    try {
      final machine = session.currentMachine, user = session.currentUser;
      if (machine == null ||
          user == null ||
          session.isClosed ||
          ![ClientKind.erp, ClientKind.erpAdmin].contains(machine.client)) {
        return const FailureResult(
          AppFailure(
            kind: FailureKind.authentication,
            code: 'erp.session_required',
            safeMessage: '请登录仓库系统后操作',
          ),
        );
      }
      final epoch = generation?.call();
      if (epoch == null || isOnline?.call() != true) {
        return const FailureResult(
          AppFailure(
            kind: FailureKind.network,
            code: 'erp.offline',
            safeMessage: '连接未就绪，请稍后重试',
          ),
        );
      }
      final result = await run(
        ProtocolErpApi(client: api.client, clientKind: machine.client),
      );
      if (session.isClosed ||
          !identical(user, session.currentUser) ||
          !identical(machine, session.currentMachine) ||
          epoch != generation?.call() ||
          isOnline?.call() != true) {
        return const FailureResult(
          AppFailure(
            kind: FailureKind.authentication,
            code: 'erp.context_changed',
            safeMessage: '登录或连接状态已变化，请重新打开',
          ),
        );
      }
      return result;
    } on Object {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.unknown,
          code: 'erp.failed',
          safeMessage: '操作失败，请稍后重试',
        ),
      );
    }
  }

  // S8.P1 主数据
  @override
  Future<Result<List<ErpNegStoreAlert>>> loadNegStoreAlerts() =>
      _guard((boundApi) => boundApi.getNegStoreAlerts());

  @override
  Future<Result<List<ErpUnboundPrdAlert>>> loadUnboundPrdAlerts() =>
      _guard((boundApi) => boundApi.getUnboundPrdAlerts());

  @override
  Future<Result<List<ErpStoreItem>>> loadStores() =>
      _guard((boundApi) => boundApi.getStoreList());

  @override
  Future<Result<void>> saveStore(ErpStoreItem store) async {
    final res = await _guard((boundApi) => boundApi.saveStore(store));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> toggleStoreStatus(String storeId, bool enable) async {
    final res = await _guard(
      (boundApi) => boundApi.toggleStoreStatus(storeId, enable),
    );
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteStore(String storeId) async {
    final res = await _guard((boundApi) => boundApi.deleteStore(storeId));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<List<ErpMatCate>>> loadMatCateTree() =>
      _guard((boundApi) => boundApi.getMatCateList());

  @override
  Future<Result<List<ErpMatItem>>> loadMats({
    String? oneCateId,
    String? twoCateId,
    String? keyword,
  }) => _guard(
    (boundApi) => boundApi.getMatList(
      oneCateId: oneCateId,
      twoCateId: twoCateId,
      keyword: keyword,
    ),
  );

  @override
  Future<Result<void>> saveMat(ErpMatItem mat) async {
    final res = await _guard((boundApi) => boundApi.saveMat(mat));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> toggleMatStatus(String matId, bool enable) async {
    final res = await _guard(
      (boundApi) => boundApi.toggleMatStatus(matId, enable),
    );
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteMat(String matId) async {
    final res = await _guard((boundApi) => boundApi.deleteMat(matId));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<List<ErpComparePrdItem>>> loadComparePrds(int type) =>
      _guard((boundApi) => boundApi.getComparePrdList(type));

  @override
  Future<Result<void>> bindMatPrd({
    required String prdId,
    required String matId,
  }) async {
    final res = await _guard(
      (boundApi) => boundApi.bindMatPrd(prdId: prdId, matId: matId),
    );
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> closeBindPrds(List<String> prdIds) async {
    final res = await _guard((boundApi) => boundApi.closeBindPrds(prdIds));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<List<ErpSupplierItem>>> loadSuppliers() =>
      _guard((boundApi) => boundApi.getSupplierList());

  @override
  Future<Result<void>> saveSupplier(ErpSupplierItem supplier) async {
    final res = await _guard((boundApi) => boundApi.saveSupplier(supplier));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> toggleSupplierStatus(
    String supplierId,
    bool enable,
  ) async {
    final res = await _guard(
      (boundApi) => boundApi.toggleSupplierStatus(supplierId, enable),
    );
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteSupplier(String supplierId) async {
    final res = await _guard((boundApi) => boundApi.deleteSupplier(supplierId));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  // S8.P2 入库
  @override
  Future<Result<List<ErpSinItem>>> loadSinList({
    String? beginDay,
    String? endDay,
    int? status,
  }) => _guard(
    (boundApi) =>
        boundApi.getSinList(beginDay: beginDay, endDay: endDay, status: status),
  );

  @override
  Future<Result<List<ErpMatItem>>> searchSinMats(String keyword) =>
      _guard((boundApi) => boundApi.getSinMatItems(keyword));
  @override
  Future<Result<ErpStockOptions>> loadSinOptions() =>
      _guard((boundApi) => boundApi.getSinOptions());
  @override
  Future<Result<List<ErpStoreItem>>> loadSoutStores() =>
      _guard((boundApi) => boundApi.getSoutStores());
  @override
  Future<Result<List<ErpStockMaterial>>> searchStockMaterials({
    required bool outgoing,
    required String keyword,
    String storeId = '',
  }) => _guard(
    (boundApi) => boundApi.getStockMaterialItems(
      outgoing: outgoing,
      keyword: keyword,
      storeId: storeId,
    ),
  );

  @override
  Future<Result<void>> createSinOrder(Map<String, Object?> payload) async {
    final res = await _guard((boundApi) => boundApi.createSinOrder(payload));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> reverseSinOrder(String billId) async {
    final res = await _guard((boundApi) => boundApi.reverseSinOrder(billId));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> redPunchSinOrder(String billId) async {
    final res = await _guard((boundApi) => boundApi.redPunchSinOrder(billId));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<List<ErpSindItem>>> loadSindList({
    String? beginDay,
    String? endDay,
    int? status,
  }) => _guard(
    (boundApi) => boundApi.getSindList(
      beginDay: beginDay,
      endDay: endDay,
      status: status,
    ),
  );

  @override
  Future<Result<void>> batchSindIn(List<String> billIds) async {
    final res = await _guard((boundApi) => boundApi.batchSindIn(billIds));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> partSindIn(Map<String, Object?> payload) async {
    final res = await _guard((boundApi) => boundApi.partSindIn(payload));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> applySindSh(Map<String, Object?> payload) async {
    final res = await _guard((boundApi) => boundApi.applySindSh(payload));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<List<ErpDisputeItem>>> loadDisputeInList({
    String? beginDay,
    String? endDay,
    int? status,
  }) => _guard(
    (boundApi) => boundApi.getDisputeInList(
      beginDay: beginDay,
      endDay: endDay,
      status: status,
    ),
  );

  @override
  Future<Result<void>> confirmDisputeIn(String disputeId) async {
    final res = await _guard(
      (boundApi) => boundApi.confirmDisputeIn(disputeId),
    );
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> cancelDisputeIn(String disputeId) async {
    final res = await _guard((boundApi) => boundApi.cancelDisputeIn(disputeId));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> rejectDisputeIn(String disputeId) async {
    final res = await _guard((boundApi) => boundApi.rejectDisputeIn(disputeId));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  // S8.P3 出库
  @override
  Future<Result<List<ErpSoutItem>>> loadSoutList({
    String? beginDay,
    String? endDay,
    int? status,
  }) => _guard(
    (boundApi) => boundApi.getSoutList(
      beginDay: beginDay,
      endDay: endDay,
      status: status,
    ),
  );

  @override
  Future<Result<void>> createSoutOrder(Map<String, Object?> payload) async {
    final res = await _guard((boundApi) => boundApi.createSoutOrder(payload));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> reverseSoutOrder(String billId) async {
    final res = await _guard((boundApi) => boundApi.reverseSoutOrder(billId));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> redPunchSoutOrder(String billId) async {
    final res = await _guard((boundApi) => boundApi.redPunchSoutOrder(billId));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<List<ErpSoutdItem>>> loadSoutdList({
    String? beginDay,
    String? endDay,
    int? status,
  }) => _guard(
    (boundApi) => boundApi.getSoutdList(
      beginDay: beginDay,
      endDay: endDay,
      status: status,
    ),
  );

  @override
  Future<Result<void>> createSoutdOrder(Map<String, Object?> payload) async {
    final res = await _guard((boundApi) => boundApi.createSoutdOrder(payload));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> reverseSoutdOrder(String billId) async {
    final res = await _guard((boundApi) => boundApi.reverseSoutdOrder(billId));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> redPunchSoutdOrder(String billId) async {
    final res = await _guard((boundApi) => boundApi.redPunchSoutdOrder(billId));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<List<ErpDisputeItem>>> loadDisputeOutList({
    String? beginDay,
    String? endDay,
    int? status,
  }) => _guard(
    (boundApi) => boundApi.getDisputeOutList(
      beginDay: beginDay,
      endDay: endDay,
      status: status,
    ),
  );

  @override
  Future<Result<void>> rejectDisputeOut(String disputeId) async {
    final res = await _guard(
      (boundApi) => boundApi.rejectDisputeOut(disputeId),
    );
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> redPunchDisputeOut(String disputeId) async {
    final res = await _guard(
      (boundApi) => boundApi.redPunchDisputeOut(disputeId),
    );
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> breakLossDisputeOut(String disputeId) async {
    final res = await _guard(
      (boundApi) => boundApi.breakLossDisputeOut(disputeId),
    );
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  // S8.P4 空瓶
  @override
  Future<Result<List<ErpEmptyInItem>>> loadEmptyInList({
    String? beginDay,
    String? endDay,
  }) => _guard(
    (boundApi) => boundApi.getEmptyInList(beginDay: beginDay, endDay: endDay),
  );

  @override
  Future<Result<void>> confirmEmptyIn(String billId) async {
    final res = await _guard((boundApi) => boundApi.confirmEmptyIn(billId));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<void>> redPunchEmptyIn(String billId) async {
    final res = await _guard((boundApi) => boundApi.redPunchEmptyIn(billId));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<List<ErpEmptyInvtItem>>> loadEmptyInvtList({String? keyword}) =>
      _guard((boundApi) => boundApi.getEmptyInvtList(keyword: keyword));

  @override
  Future<Result<void>> submitEmptyOut(Map<String, Object?> payload) async {
    final res = await _guard((boundApi) => boundApi.submitEmptyOut(payload));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  @override
  Future<Result<List<ErpEmptyOutItem>>> loadEmptyOutList({
    String? beginDay,
    String? endDay,
  }) => _guard(
    (boundApi) => boundApi.getEmptyOutList(beginDay: beginDay, endDay: endDay),
  );

  @override
  Future<Result<void>> redPunchEmptyOut(String billId) async {
    final res = await _guard((boundApi) => boundApi.redPunchEmptyOut(billId));
    final f = res.failureOrNull;
    if (f != null) return FailureResult(f);
    return const Success(null);
  }

  // S8.P5 报表
  @override
  Future<Result<ErpReportParams>> loadReportParams() =>
      _guard((boundApi) => boundApi.getReportParams());

  @override
  Future<Result<List<ErpMatNowInvtItem>>> loadMatNowInvt({
    String? storeId,
    String? keyword,
  }) => _guard(
    (boundApi) => boundApi.getMatNowInvt(storeId: storeId, keyword: keyword),
  );

  @override
  Future<Result<List<ErpMatMonthInvtItem>>> loadMatMonthInvt({
    String? storeId,
    String? month,
  }) => _guard(
    (boundApi) => boundApi.getMatMonthInvt(storeId: storeId, month: month),
  );

  @override
  Future<Result<List<ErpInOutRecItem>>> loadInRecs({
    String? storeId,
    String? beginDay,
    String? endDay,
  }) => _guard(
    (boundApi) => boundApi.getInRecs(
      storeId: storeId,
      beginDay: beginDay,
      endDay: endDay,
    ),
  );

  @override
  Future<Result<List<ErpInOutRecItem>>> loadOutRecs({
    String? storeId,
    String? beginDay,
    String? endDay,
  }) => _guard(
    (boundApi) => boundApi.getOutRecs(
      storeId: storeId,
      beginDay: beginDay,
      endDay: endDay,
    ),
  );

  @override
  Future<Result<List<ErpInOutSumItem>>> loadInSum({
    String? storeId,
    String? beginDay,
    String? endDay,
  }) => _guard(
    (boundApi) =>
        boundApi.getInSum(storeId: storeId, beginDay: beginDay, endDay: endDay),
  );

  @override
  Future<Result<List<ErpInOutSumItem>>> loadOutSum({
    String? storeId,
    String? beginDay,
    String? endDay,
  }) => _guard(
    (boundApi) => boundApi.getOutSum(
      storeId: storeId,
      beginDay: beginDay,
      endDay: endDay,
    ),
  );

  @override
  Future<Result<List<ErpPsiItem>>> loadStorePsi({
    String? storeId,
    String? date,
  }) =>
      _guard((boundApi) => boundApi.getStorePsi(storeId: storeId, date: date));

  @override
  Future<Result<List<ErpEmptyOperItem>>> loadEmptyInOperList({
    String? beginDay,
    String? endDay,
  }) => _guard(
    (boundApi) =>
        boundApi.getEmptyInOperList(beginDay: beginDay, endDay: endDay),
  );

  @override
  Future<Result<List<ErpEmptyOperItem>>> loadEmptyOutOperList({
    String? beginDay,
    String? endDay,
  }) => _guard(
    (boundApi) =>
        boundApi.getEmptyOutOperList(beginDay: beginDay, endDay: endDay),
  );
}
