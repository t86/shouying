import 'package:card_table/src/booking_queue.dart';
import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/fc_price.dart';
import 'package:card_table/src/product_pricing.dart';
import 'package:card_table/src/order_set_catalog.dart';
import 'package:card_table/src/order_meal.dart';
import 'package:card_table/src/sold_out_products.dart';
import 'package:card_table/src/vip_recharge.dart';
import 'package:foundation/foundation.dart';
import 'package:permissions/permissions.dart';
import 'package:realtime_sync/realtime_sync.dart';

final class LegacyCardTableStore {
  factory LegacyCardTableStore({
    String? machineId,
    String? stationId,
    bool padDevice = true,
  }) => LegacyCardTableStore._(machineId, stationId, padDevice);

  LegacyCardTableStore._(this._machineId, this._stationId, this._padDevice);
  final bool _padDevice;

  static const Set<int> _requiredDatasets = <int>{0, 1, 14, 18};

  final String? _machineId;
  final String? _stationId;
  Map<String, List<Object?>> _regions = <String, List<Object?>>{};
  Map<String, List<Object?>> _seats = <String, List<Object?>>{};
  Map<String, List<Object?>> _business = <String, List<Object?>>{};
  Map<String, List<Object?>> _businessDates = <String, List<Object?>>{};
  Map<String, List<Object?>> _futureBookings = <String, List<Object?>>{};
  Map<String, List<Object?>> _statusCounts = <String, List<Object?>>{};
  Map<String, List<Object?>> _machineAccess = <String, List<Object?>>{};
  Map<String, List<Object?>> _roles = <String, List<Object?>>{};
  Map<String, List<Object?>> _modules = <String, List<Object?>>{};
  Map<String, List<Object?>> _safeModes = <String, List<Object?>>{};
  bool _rolesKnown = false;
  bool _modulesKnown = false;
  bool _safeModeKnown = false;
  bool _permissionsInvalidated = false;
  Map<String, List<Object?>> _supervisorRegions = <String, List<Object?>>{};
  Map<String, List<Object?>> _firstCategories = <String, List<Object?>>{};
  Map<String, List<Object?>> _secondCategories = <String, List<Object?>>{};
  Map<String, List<Object?>> _goods = <String, List<Object?>>{};
  bool _productTypesKnown = false;
  bool _businessPricingKnown = false;
  final Map<String, int> _businessPriceEmployees = {};

  ProductPriceQuote? productQuoteFor(String seatId, String productId) {
    if (!_businessPricingKnown || !_productTypesKnown) return null;
    final table = _currentSnapshot?.tables
        .where((row) => row.id == seatId)
        .firstOrNull;
    if (table == null) return null;
    final product = catalogForRegion(table.regionId).products
        .where((row) => row.id == productId)
        .firstOrNull;
    if (product == null) return null;
    return quoteProductPrice(
      product,
      context: ProductPricingContext(
        isMember: table.customerPhone.trim().isNotEmpty,
        isBox: table.seatType == 4,
        isBusiness: _businessPriceEmployees[table.salesEmployeeId] == 1,
      ),
    );
  }

  void _applyBusinessPricing(Map<int, Object?> datasets, bool full) {
    if (full) {
      _businessPricingKnown = false;
      _businessPriceEmployees.clear();
    }
    if (!datasets.containsKey(57)) return;
    try {
      final rows = _rows(datasets[57], minimumLength: 2);
      final next = Map<String, int>.of(_businessPriceEmployees);
      for (final row in rows) {
        final id = _permissionInteger(row[0], positive: true);
        next['$id'] = _permissionInteger(row[1], positive: false);
      }
      if (next.length > 10000) throw const FormatException();
      _businessPriceEmployees
        ..clear()
        ..addAll(next);
      if (full) _businessPricingKnown = true;
    } on Object {
      _businessPricingKnown = false;
      _businessPriceEmployees.clear();
    }
  }

  Map<String, List<Object?>> _setDetails = <String, List<Object?>>{};
  Map<String, List<Object?>> _reasons = <String, List<Object?>>{};
  Map<String, List<Object?>> _areaProducts = <String, List<Object?>>{};
  Map<String, List<Object?>> _employees = <String, List<Object?>>{};
  Map<String, List<Object?>> _departments = <String, List<Object?>>{};
  Map<String, List<Object?>> _showAmt = <String, List<Object?>>{};
  Map<String, List<Object?>> _topCards = <String, List<Object?>>{};
  Map<String, List<Object?>> _seatMarks = <String, List<Object?>>{};
  Map<String, List<Object?>> _onlineSeats = <String, List<Object?>>{};
  Map<String, List<Object?>> _offlineConverted = <String, List<Object?>>{};
  Map<String, List<Object?>> _queueTypes = <String, List<Object?>>{};
  Map<String, List<Object?>> _queueRecords = <String, List<Object?>>{};
  Map<String, List<Object?>> _queueCurNumbers = <String, List<Object?>>{};
  List<Object?>? _queueConfig;
  SoldOutProductCatalog _soldOutCatalog = SoldOutProductCatalog.empty;
  List<Object?>? _businessDay;
  CardTableSnapshot? _currentSnapshot;

  CardTableSnapshot? get currentSnapshot => _currentSnapshot;

  SoldOutProductCatalog get soldOutCatalog => _soldOutCatalog;

  FcPriceCatalog _fcPriceCatalog = FcPriceCatalog.unknown;
  FcPriceCatalog get fcPriceCatalog => _fcPriceCatalog;
  OrderSetCatalog _orderSetCatalog = OrderSetCatalog.unknown;
  OrderSetCatalog get orderSetCatalog => _orderSetCatalog;

  List<OrderSetDetail> get setDetails {
    try {
      return <OrderSetDetail>[
        for (final row in _setDetails.values)
          if (_integer(row[1]) == 1)
            OrderSetDetail(
              productId: _id(row[0]),
              groupId: _id(row[2]),
              detailProductId: _id(row[4]),
              detailCount: _integer(row[5]),
              groupSelectCount: _integer(row[6]),
              name: _goodsName(_id(row[4])),
              typeId: _integer(row[7]).toString(),
              seqId: _integer(row[3]),
            ),
      ];
    } on Object {
      return const <OrderSetDetail>[];
    }
  }

  List<String> get yhReasons => _reasonNames(1);

  List<String> get refundReasons => _reasonNames(2);
  String? productNameFor(String id) {
    final name = _goodsName(id);
    return name.isEmpty ? null : name;
  }

  /// Historical refunds must not infer product type from the region-filtered
  /// sale menu. Inactive products remain useful; deleted/unknown products do not.
  int? productTypeFor(String productId) {
    if (!_productTypesKnown) return null;
    final row = _goods[productId];
    if (row == null || row.length < 10) return null;
    try {
      final type = _integer(row[9]);
      return type > 0 ? type : null;
    } on Object {
      return null;
    }
  }

  SoldOutProductCatalog catalogForRegion(String regionId) {
    try {
      return SoldOutProductCatalog.forRegion(
        regionId: regionId,
        firstCategories: _firstCategories.values,
        secondCategories: _secondCategories.values,
        products: _goods.values,
        areaProducts: _areaProducts.values,
        padDevice: _padDevice,
      );
    } on Object {
      return SoldOutProductCatalog.empty;
    }
  }

  List<VipRechargeEmployee> get employees =>
      List<VipRechargeEmployee>.unmodifiable([
        for (final row in _employees.values)
          VipRechargeEmployee(
            id: _id(row[0]),
            name: _text(row[1]),
            code: row.length > 8 ? _employeeCode(row[8]) : '',
          ),
      ]);

  /// Cashier KPI drawer searches all synced employees by name, code and pinyin.
  Map<int, String> get cashierReportSalesOptions => Map.unmodifiable({
    for (final row in _employees.values) _integer(row[0]): _text(row[1]),
  });
  Map<int, String> get cashierReportSalesSearchTerms => Map.unmodifiable({
    for (final row in _employees.values)
      _integer(row[0]): '${_text(row[7])} ${_employeeCode(row[8])}',
  });

  /// Unlike the card grid, the source revenue report includes active empty
  /// regions and regions outside this terminal's visible-seat selection.
  Map<int, String> get cashierReportRegionOptions {
    final rows = _regions.values.where((row) => _integer(row[2]) == 1).toList()
      ..sort((a, b) => _integer(a[3]).compareTo(_integer(b[3])));
    return Map.unmodifiable({
      for (final row in rows) _integer(row[0]): _text(row[1]),
    });
  }

  /// Reconstructs only the datasets consumed by this card-table store.
  /// This is not a general-purpose replay of all business domains.
  SyncEnvelope? get replayEnvelope {
    final snapshot = _currentSnapshot;
    if (snapshot == null) return null;
    final data = List<Object?>.filled(60, const <Object?>[]);
    data[58] = _fcPriceCatalog.priceRows;
    data[59] = _fcPriceCatalog.employeeRows;
    data[0] = _regions.values.toList(growable: false);
    data[1] = _seats.values.toList(growable: false);
    data[13] = _rolesKnown && !_permissionsInvalidated
        ? _roles.values.toList(growable: false)
        : null;
    data[14] = _business.values.toList(growable: false);
    data[18] = <Object?>[_businessDay];
    data[24] = _businessDates.values.toList(growable: false);
    data[25] = _futureBookings.values.toList(growable: false);
    data[39] = _statusCounts.values.toList(growable: false);
    data[40] = _machineAccess.values.toList(growable: false);
    // Null preserves unknown/invalid authority data; an empty list is known.
    data[41] = _modulesKnown && !_permissionsInvalidated
        ? _modules.values.toList(growable: false)
        : null;
    data[54] = _safeModeKnown
        ? _safeModes.values.toList(growable: false)
        : null;
    data[56] = _supervisorRegions.values.toList(growable: false);
    data[57] = _businessPricingKnown
        ? [
            for (final row in _businessPriceEmployees.entries)
              [row.key, row.value],
          ]
        : null;
    data[2] = _firstCategories.values.toList(growable: false);
    data[3] = _secondCategories.values.toList(growable: false);
    data[4] = _productTypesKnown ? _goods.values.toList(growable: false) : null;
    for (final dataset in [8, 9, 19, 20, 21, 52]) {
      data[dataset] = _orderSetCatalog.rowsForReplay(dataset);
    }
    data[32] = _reasons.values.toList(growable: false);
    data[5] = _employees.values.toList(growable: false);
    data[6] = _departments.values.toList(growable: false);
    data[16] = _areaProducts.values.toList(growable: false);
    data[35] = _showAmt.values.toList(growable: false);
    data[29] = _topCards.values.toList(growable: false);
    data[31] = _seatMarks.values.toList(growable: false);
    data[26] = _onlineSeats.values.toList(growable: false);
    data[28] = _offlineConverted.values.toList(growable: false);
    return SyncEnvelope.fromValidatedReconciliation(
      cursor: snapshot.cursor,
      data: data,
    );
  }

  Result<CardTableSnapshot> applyEnvelope(SyncEnvelope envelope) {
    if (envelope.type != SyncEventType.data) {
      final current = _currentSnapshot;
      return current == null
          ? const FailureResult(_snapshotRequiredFailure)
          : Success(current);
    }

    final datasets = _datasets(envelope.data);
    if (datasets == null) {
      _businessPricingKnown = false;
      _orderSetCatalog = OrderSetCatalog.unknown;
      _productTypesKnown = false;
      _fcPriceCatalog = FcPriceCatalog.unknown;
      final data = envelope.data;
      if (data is Map) {
        final touchedMetadata = <int, Object?>{};
        for (final key in data.keys) {
          final index = switch (key) {
            int() => key,
            String() => int.tryParse(key),
            _ => null,
          };
          if (index == 13 || index == 41 || index == 54) {
            touchedMetadata[index!] = null;
          }
        }
        _invalidatePageMetadata(touchedMetadata, isFull: false);
      }
      return const FailureResult(_shapeFailure);
    }
    final isFull = envelope.data is List || _currentSnapshot == null;
    if (isFull && !_requiredDatasets.every(datasets.containsKey)) {
      _businessPricingKnown = false;
      _orderSetCatalog = OrderSetCatalog.unknown;
      _productTypesKnown = false;
      _fcPriceCatalog = FcPriceCatalog.unknown;
      _invalidatePageMetadata(datasets, isFull: true);
      return const FailureResult(_snapshotRequiredFailure);
    }

    final nextRegions = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_regions);
    final nextSeats = isFull ? <String, List<Object?>>{} : _copyRows(_seats);
    final nextBusiness = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_business);
    final nextBusinessDates = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_businessDates);
    final nextFutureBookings = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_futureBookings);
    final nextStatusCounts = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_statusCounts);
    final nextMachineAccess = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_machineAccess);
    final nextRoles = isFull ? <String, List<Object?>>{} : _copyRows(_roles);
    final nextModules = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_modules);
    final nextSafeModes = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_safeModes);
    var nextRolesKnown = isFull ? false : _rolesKnown;
    var nextModulesKnown = isFull ? false : _modulesKnown;
    var nextSafeModeKnown = isFull ? false : _safeModeKnown;
    final nextSupervisorRegions = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_supervisorRegions);
    final nextFirstCategories = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_firstCategories);
    final nextSecondCategories = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_secondCategories);
    final nextGoods = isFull ? <String, List<Object?>>{} : _copyRows(_goods);
    var nextProductTypesKnown = isFull
        ? datasets.containsKey(4)
        : _productTypesKnown;
    final nextSetDetails = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_setDetails);
    final nextReasons = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_reasons);
    final nextAreaProducts = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_areaProducts);
    final nextEmployees = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_employees);
    final nextDepartments = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_departments);
    final nextShowAmt = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_showAmt);
    final nextTopCards = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_topCards);
    final nextSeatMarks = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_seatMarks);
    final nextOnlineSeats = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_onlineSeats);
    final nextOfflineConverted = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_offlineConverted);
    final nextQueueTypes = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_queueTypes);
    final nextQueueRecords = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_queueRecords);
    final nextQueueCurNumbers = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_queueCurNumbers);
    var nextQueueConfig = isFull
        ? null
        : _queueConfig == null
        ? null
        : List<Object?>.of(_queueConfig!);
    var nextBusinessDay = isFull
        ? null
        : _businessDay == null
        ? null
        : List<Object?>.of(_businessDay!);

    try {
      if (datasets.containsKey(0)) {
        _mergeRows(nextRegions, _rows(datasets[0], minimumLength: 4), 2);
      }
      if (datasets.containsKey(1)) {
        _mergeRows(nextSeats, _rows(datasets[1], minimumLength: 8), 2);
      }
      if (datasets.containsKey(13)) {
        if (datasets[13] == null) {
          nextRolesKnown = false;
        } else {
          _mergeRowsByKey(
            nextRoles,
            _permissionRows(datasets[13]),
            (row) => '${_id(row[0])}|${_integer(row[1])}',
          );
          if (isFull) nextRolesKnown = true;
        }
      }
      if (datasets.containsKey(14)) {
        _mergeRows(
          nextBusiness,
          _rows(datasets[14], minimumLength: 38),
          19,
          deletedStatuses: const <int>{22, 33},
        );
      }
      if (datasets.containsKey(18)) {
        final rows = _rows(datasets[18], minimumLength: 3);
        if (rows.isEmpty) throw const FormatException();
        nextBusinessDay = List<Object?>.unmodifiable(rows.first);
      }
      if (datasets.containsKey(24)) {
        _mergeRowsByKey(
          nextBusinessDates,
          _rows(datasets[24], minimumLength: 2),
          (row) => _id(row[1]),
        );
      }
      if (datasets.containsKey(25)) {
        _mergeRowsByKey(
          nextFutureBookings,
          _rows(datasets[25], minimumLength: 14),
          (row) => '${_id(row[0])}|${_id(row[1])}',
        );
      }
      if (datasets.containsKey(39)) {
        _mergeRowsByKey(
          nextStatusCounts,
          _rows(datasets[39], minimumLength: 3),
          (row) => '${_integer(row[0])}|${_id(row[1])}',
        );
      }
      if (datasets.containsKey(40)) {
        _mergeRowsByKey(
          nextMachineAccess,
          _rows(datasets[40], minimumLength: 4),
          (row) => '${_id(row[0])}|${_integer(row[1])}|${_id(row[3])}',
        );
      }
      if (datasets.containsKey(41)) {
        if (datasets[41] == null) {
          nextModulesKnown = false;
        } else {
          _mergeRowsByKey(
            nextModules,
            _permissionRows(datasets[41]),
            (row) => '${_id(row[0])}|${_integer(row[1])}',
          );
          if (isFull) nextModulesKnown = true;
        }
      }
      if (datasets.containsKey(54)) {
        if (datasets[54] == null) {
          nextSafeModeKnown = false;
        } else {
          final rows = _rows(datasets[54], minimumLength: 2);
          for (final row in rows) {
            _permissionInteger(row[0], positive: true);
            _permissionInteger(row[1], positive: false);
          }
          _mergeRowsByKey(nextSafeModes, rows, (row) => _id(row[0]));
          if (isFull || rows.any((row) => _integer(row[0]) == 1)) {
            nextSafeModeKnown = true;
          }
        }
      }
      if (datasets.containsKey(56)) {
        _mergeRowsByKey(
          nextSupervisorRegions,
          _rows(datasets[56], minimumLength: 3),
          (row) => '${_id(row[0])}|${_id(row[1])}',
        );
      }
      try {
        if (datasets.containsKey(2)) {
          _mergeRows(
            nextFirstCategories,
            _rows(datasets[2], minimumLength: 4),
            2,
          );
        }
        if (datasets.containsKey(3)) {
          _mergeRows(
            nextSecondCategories,
            _rows(datasets[3], minimumLength: 5),
            2,
          );
        }
        if (datasets.containsKey(4)) {
          _mergeRows(nextGoods, _rows(datasets[4], minimumLength: 10), 2);
        }
        if (datasets.containsKey(9)) {
          // Unknown/bad package configuration must not erase otherwise valid
          // product types used by non-package operations. Catalog tracks its
          // own dataset readiness, including null in session replays.
          try {
            if (datasets[9] == null) {
              nextSetDetails.clear();
            } else {
              _mergeSetDetails(
                nextSetDetails,
                _rows(datasets[9], minimumLength: 8),
              );
            }
          } on Object {
            nextSetDetails.clear();
          }
        }
        if (datasets.containsKey(32)) {
          _mergeRows(nextReasons, _rows(datasets[32], minimumLength: 4), 2);
        }
        if (datasets.containsKey(16)) {
          _mergeRowsByKey(
            nextAreaProducts,
            _rows(datasets[16], minimumLength: 3),
            (row) => '${_id(row[0])}|${_id(row[2])}',
          );
          for (final entry in [...nextAreaProducts.entries]) {
            if (_integer(entry.value[1]) == 3) {
              nextAreaProducts.remove(entry.key);
            }
          }
        }
      } on Object {
        nextProductTypesKnown = false;
        if (isFull) {
          nextFirstCategories.clear();
          nextSecondCategories.clear();
          nextGoods.clear();
          nextSetDetails.clear();
          nextReasons.clear();
          nextAreaProducts.clear();
        }
      }
      try {
        if (datasets.containsKey(5)) {
          _mergeRows(nextEmployees, _rows(datasets[5], minimumLength: 9), 2);
        }
      } on Object {
        if (isFull) {
          nextEmployees.clear();
        }
      }
      try {
        if (datasets.containsKey(6)) {
          _mergeRows(nextDepartments, _rows(datasets[6], minimumLength: 4), 2);
        }
      } on Object {
        if (isFull) {
          nextDepartments.clear();
        }
      }
      try {
        if (datasets.containsKey(35)) {
          _mergeRowsByKey(
            nextShowAmt,
            _rows(datasets[35], minimumLength: 2),
            (row) => _id(row[0]),
          );
        }
      } on Object {
        if (isFull) {
          nextShowAmt.clear();
        }
      }
      try {
        if (datasets.containsKey(29)) {
          _mergeRows(nextTopCards, _rows(datasets[29], minimumLength: 3), 2);
        }
      } on Object {
        if (isFull) {
          nextTopCards.clear();
        }
      }
      try {
        if (datasets.containsKey(31)) {
          _mergeRows(nextSeatMarks, _rows(datasets[31], minimumLength: 3), 2);
        }
      } on Object {
        if (isFull) {
          nextSeatMarks.clear();
        }
      }
      try {
        if (datasets.containsKey(26)) {
          _mergeRowsByKey(
            nextOnlineSeats,
            _rows(datasets[26], minimumLength: 2),
            (row) => _id(row[0]),
          );
        }
      } on Object {
        if (isFull) {
          nextOnlineSeats.clear();
        }
      }
      try {
        if (datasets.containsKey(28)) {
          _mergeRows(
            nextOfflineConverted,
            _rows(datasets[28], minimumLength: 2),
            1,
          );
        }
      } on Object {
        if (isFull) {
          nextOfflineConverted.clear();
        }
      }
      try {
        if (datasets.containsKey(46)) {
          final rows = _rows(datasets[46], minimumLength: 5);
          if (rows.isNotEmpty) nextQueueConfig = rows.first;
        }
      } on Object {
        if (isFull) nextQueueConfig = null;
      }
      try {
        if (datasets.containsKey(47)) {
          _mergeRows(nextQueueTypes, _rows(datasets[47], minimumLength: 4), 1);
        }
      } on Object {
        if (isFull) nextQueueTypes.clear();
      }
      try {
        if (datasets.containsKey(48)) {
          _mergeRowsByKey(
            nextQueueRecords,
            _rows(datasets[48], minimumLength: 6),
            (row) => '${_id(row[3])}|${_integer(row[4])}',
          );
        }
      } on Object {
        if (isFull) nextQueueRecords.clear();
      }
      try {
        if (datasets.containsKey(49)) {
          _mergeRowsByKey(
            nextQueueCurNumbers,
            _rows(datasets[49], minimumLength: 6),
            (row) => _id(row[1]),
          );
        }
      } on Object {
        if (isFull) nextQueueCurNumbers.clear();
      }
      if (nextBusinessDay == null) throw const FormatException();
      // Unknown authority is also fail-closed. Only a complete, valid role
      // and module snapshot can clear a prior invalidation, including replay.
      final nextPermissionsInvalidated =
          !nextRolesKnown ||
          !nextModulesKnown ||
          (!isFull && _permissionsInvalidated);
      final snapshot = _buildSnapshot(
        cursor: envelope.cursor!,
        regions: nextRegions,
        seats: nextSeats,
        business: nextBusiness,
        businessDay: nextBusinessDay,
        businessDates: nextBusinessDates,
        futureBookings: nextFutureBookings,
        statusCountRows: nextStatusCounts,
        machineId: _machineId,
        machineAccess: nextMachineAccess,
        stationId: _stationId,
        roles: nextRoles,
        rolesKnown: nextRolesKnown && !nextPermissionsInvalidated,
        supervisorRegions: nextSupervisorRegions,
        pagePermissions: _pagePermissions(
          nextRoles,
          nextModules,
          available:
              nextRolesKnown && nextModulesKnown && !nextPermissionsInvalidated,
        ),
        safeModeEnabled: !nextSafeModeKnown || _safeModeEnabled(nextSafeModes),
        employees: nextEmployees,
        departments: nextDepartments,
        showAmt: nextShowAmt,
        topCards: nextTopCards,
        seatMarks: nextSeatMarks,
        onlineSeats: nextOnlineSeats,
        offlineConverted: nextOfflineConverted,
        queueConfig: nextQueueConfig,
        queueTypes: nextQueueTypes,
        queueRecords: nextQueueRecords,
        queueCurNumbers: nextQueueCurNumbers,
      );
      _regions = nextRegions;
      _seats = nextSeats;
      _business = nextBusiness;
      _businessDates = nextBusinessDates;
      _futureBookings = nextFutureBookings;
      _statusCounts = nextStatusCounts;
      _machineAccess = nextMachineAccess;
      _roles = nextRoles;
      _modules = nextModules;
      _safeModes = nextSafeModes;
      _rolesKnown = nextRolesKnown;
      _modulesKnown = nextModulesKnown;
      _safeModeKnown = nextSafeModeKnown;
      _permissionsInvalidated = nextPermissionsInvalidated;
      _supervisorRegions = nextSupervisorRegions;
      _firstCategories = nextFirstCategories;
      _secondCategories = nextSecondCategories;
      _goods = nextGoods;
      _productTypesKnown = nextProductTypesKnown;
      _setDetails = nextSetDetails;
      _reasons = nextReasons;
      _areaProducts = nextAreaProducts;
      _employees = nextEmployees;
      _departments = nextDepartments;
      _showAmt = nextShowAmt;
      _topCards = nextTopCards;
      _seatMarks = nextSeatMarks;
      _onlineSeats = nextOnlineSeats;
      _offlineConverted = nextOfflineConverted;
      _queueTypes = nextQueueTypes;
      _queueRecords = nextQueueRecords;
      _queueCurNumbers = nextQueueCurNumbers;
      _queueConfig = nextQueueConfig;
      _soldOutCatalog = _catalogFrom(
        firstCategories: nextFirstCategories,
        secondCategories: nextSecondCategories,
        goods: nextGoods,
        areaProducts: nextAreaProducts,
      );
      _businessDay = nextBusinessDay;
      _currentSnapshot = snapshot;
      _applyBusinessPricing(datasets, isFull);
      _fcPriceCatalog = _fcPriceCatalog.apply(envelope.data, isFull: isFull);
      _orderSetCatalog = _orderSetCatalog.apply(envelope.data, isFull: isFull);
      return Success(snapshot);
    } on Object {
      if (isFull || [1, 4, 14, 57].any(datasets.containsKey)) {
        _businessPricingKnown = false;
      }
      if (isFull || [4, 8, 9, 19, 20, 21, 52].any(datasets.containsKey)) {
        _orderSetCatalog = OrderSetCatalog.unknown;
      }
      if (isFull || datasets.containsKey(4)) _productTypesKnown = false;
      if (isFull || datasets.containsKey(58) || datasets.containsKey(59)) {
        _fcPriceCatalog = FcPriceCatalog.unknown;
      }
      _invalidatePageMetadata(datasets, isFull: isFull);
      return const FailureResult(_shapeFailure);
    }
  }

  PermissionSnapshot _pagePermissions(
    Map<String, List<Object?>> roles,
    Map<String, List<Object?>> modules, {
    required bool available,
  }) => PermissionNormalizer.normalize(
    stationId: _stationId,
    sysRole: available
        ? <Map<String, Object?>>[
            for (final row in roles.values)
              <String, Object?>{
                'station_id': row[0],
                'sys_role_id': row[1],
                'status': row[2],
              },
          ]
        : null,
    sysRoleDetail: available
        ? <Map<String, Object?>>[
            for (final row in modules.values)
              <String, Object?>{
                'station_id': row[0],
                'sys_module_id': row[1],
                'status': row[2],
              },
          ]
        : null,
  );

  void _invalidatePageMetadata(
    Map<int, Object?> datasets, {
    required bool isFull,
  }) {
    final permissionsTouched =
        isFull || datasets.containsKey(13) || datasets.containsKey(41);
    final safetyTouched = isFull || datasets.containsKey(54);
    if (!permissionsTouched && !safetyTouched) return;
    if (permissionsTouched) _permissionsInvalidated = true;
    if (safetyTouched) _safeModeKnown = false;
    final previous = _currentSnapshot;
    if (previous == null || _businessDay == null) return;
    // Card rows remain atomic on rejection, but authority cannot keep stale
    // grants. The invalidated flag survives unrelated events and heartbeats.
    _currentSnapshot = _buildSnapshot(
      cursor: previous.cursor,
      regions: _regions,
      seats: _seats,
      business: _business,
      businessDay: _businessDay!,
      businessDates: _businessDates,
      futureBookings: _futureBookings,
      statusCountRows: _statusCounts,
      machineId: _machineId,
      machineAccess: _machineAccess,
      stationId: _stationId,
      roles: _roles,
      rolesKnown: _rolesKnown && !_permissionsInvalidated,
      supervisorRegions: _supervisorRegions,
      pagePermissions: _pagePermissions(
        _roles,
        _modules,
        available: _rolesKnown && _modulesKnown && !_permissionsInvalidated,
      ),
      safeModeEnabled: !_safeModeKnown || _safeModeEnabled(_safeModes),
      employees: _employees,
      departments: _departments,
      showAmt: _showAmt,
      topCards: _topCards,
      seatMarks: _seatMarks,
      onlineSeats: _onlineSeats,
      offlineConverted: _offlineConverted,
    );
  }

  static bool _safeModeEnabled(Map<String, List<Object?>> rows) =>
      rows.values.any((row) => _integer(row[0]) == 1 && _integer(row[1]) == 1);

  static List<List<Object?>> _permissionRows(Object? value) {
    final rows = _rows(value, minimumLength: 3);
    if (rows.length > 10000) throw const FormatException();
    for (final row in rows) {
      _permissionInteger(row[0], positive: true);
      _permissionInteger(row[1], positive: true);
      _permissionInteger(row[2], positive: false);
    }
    return rows;
  }

  static int _permissionInteger(Object? value, {required bool positive}) {
    if (value is String &&
        (value.length > 32 || !RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(value))) {
      throw const FormatException();
    }
    final result = _integer(value);
    if (positive ? result <= 0 : result < 0) throw const FormatException();
    return result;
  }

  static Map<int, Object?>? _datasets(Object? value) {
    if (value is List) {
      return <int, Object?>{
        for (var index = 0; index < value.length; index += 1)
          index: value[index],
      };
    }
    if (value is Map) {
      final result = <int, Object?>{};
      for (final entry in value.entries) {
        final index = switch (entry.key) {
          int() => entry.key as int,
          String() => int.tryParse(entry.key as String),
          _ => null,
        };
        if (index == null || index < 0 || index > 1024) return null;
        result[index] = entry.value;
      }
      return result;
    }
    return null;
  }

  static List<List<Object?>> _rows(
    Object? value, {
    required int minimumLength,
  }) {
    if (value is! List) throw const FormatException();
    return <List<Object?>>[
      for (final row in value)
        if (row is List && row.length >= minimumLength)
          List<Object?>.of(row)
        else
          throw const FormatException(),
    ];
  }

  static void _mergeSetDetails(
    Map<String, List<Object?>> target,
    List<List<Object?>> rows,
  ) {
    for (final row in rows) {
      final key = '${_id(row[0])}|${_id(row[2])}|${_integer(row[3])}';
      if (_integer(row[1]) == 3) {
        target.remove(key);
      } else {
        target[key] = List<Object?>.unmodifiable(row);
      }
    }
  }

  static void _mergeRows(
    Map<String, List<Object?>> target,
    List<List<Object?>> rows,
    int statusIndex, {
    Set<int> deletedStatuses = const <int>{3},
  }) {
    for (final row in rows) {
      final id = _id(row[0]);
      final status = _integer(row[statusIndex]);
      if (deletedStatuses.contains(status)) {
        target.remove(id);
      } else {
        target[id] = List<Object?>.unmodifiable(row);
      }
    }
  }

  static void _mergeRowsByKey(
    Map<String, List<Object?>> target,
    List<List<Object?>> rows,
    String Function(List<Object?> row) keyOf,
  ) {
    for (final row in rows) {
      target[keyOf(row)] = List<Object?>.unmodifiable(row);
    }
  }

  static CardTableSnapshot _buildSnapshot({
    required String cursor,
    required Map<String, List<Object?>> regions,
    required Map<String, List<Object?>> seats,
    required Map<String, List<Object?>> business,
    required List<Object?> businessDay,
    required Map<String, List<Object?>> businessDates,
    required Map<String, List<Object?>> futureBookings,
    required Map<String, List<Object?>> statusCountRows,
    required String? machineId,
    required Map<String, List<Object?>> machineAccess,
    required String? stationId,
    required Map<String, List<Object?>> roles,
    required bool rolesKnown,
    required Map<String, List<Object?>> supervisorRegions,
    required PermissionSnapshot pagePermissions,
    required bool safeModeEnabled,
    required Map<String, List<Object?>> employees,
    required Map<String, List<Object?>> departments,
    required Map<String, List<Object?>> showAmt,
    required Map<String, List<Object?>> topCards,
    required Map<String, List<Object?>> seatMarks,
    required Map<String, List<Object?>> onlineSeats,
    required Map<String, List<Object?>> offlineConverted,
    Map<String, List<Object?>> queueTypes = const {},
    Map<String, List<Object?>> queueRecords = const {},
    Map<String, List<Object?>> queueCurNumbers = const {},
    List<Object?>? queueConfig,
  }) {
    // The session-owned feed has no station and only preserves raw data.
    // A user-scoped store must not interpret unknown or invalidated role
    // authority as "not supervisor", including after subsequent valid deltas.
    final roleScopeKnown = stationId == null || rolesKnown;
    final normalizedRegions =
        <CardRegion>[
          for (final row in regions.values)
            if (_integer(row[2]) == 1)
              CardRegion(
                id: _id(row[0]),
                name: _text(row[1]),
                displayOrder: _integer(row[3]),
              ),
        ]..sort((left, right) {
          final order = left.displayOrder.compareTo(right.displayOrder);
          return order != 0 ? order : left.id.compareTo(right.id);
        });
    final activeRegionIds = normalizedRegions
        .map((region) => region.id)
        .toSet();
    final normalizedTables =
        <CardTable>[
          for (final row in seats.values)
            if (roleScopeKnown &&
                _integer(row[2]) == 1 &&
                activeRegionIds.contains(_id(row[3])) &&
                _isSeatPermitted(row, machineId, machineAccess) &&
                _isSupervisorRegionPermitted(
                  row,
                  stationId,
                  roles,
                  supervisorRegions,
                ))
              _table(
                row,
                business[_id(row[0])],
                region: regions[_id(row[3])],
                pinOrder: _pinOrder(topCards, _id(row[0])),
                showOnlineText: _showOnlineText(
                  seatId: _id(row[0]),
                  business: business[_id(row[0])],
                  onlineSeats: onlineSeats,
                  offlineConverted: offlineConverted,
                ),
              ),
        ]..sort((left, right) {
          final pin = right.pinOrder.compareTo(left.pinOrder);
          if (pin != 0) return pin;
          final region = normalizedRegions
              .indexWhere((value) => value.id == left.regionId)
              .compareTo(
                normalizedRegions.indexWhere(
                  (value) => value.id == right.regionId,
                ),
              );
          if (region != 0) return region;
          final order = left.displayOrder.compareTo(right.displayOrder);
          return order != 0 ? order : left.name.compareTo(right.name);
        });
    final normalizedDates = <CardBusinessDate>[
      for (final row in businessDates.values)
        CardBusinessDate(id: _id(row[1]), label: _text(row[0])),
    ];
    final tablesByDate = <String, Iterable<CardTable>>{};
    for (final date in normalizedDates.skip(1)) {
      tablesByDate[date.id] =
          <CardTable>[
            for (final seat in seats.values)
              if (roleScopeKnown &&
                  _integer(seat[2]) == 1 &&
                  activeRegionIds.contains(_id(seat[3])) &&
                  _isSeatPermitted(seat, machineId, machineAccess) &&
                  _isSupervisorRegionPermitted(
                    seat,
                    stationId,
                    roles,
                    supervisorRegions,
                  ))
                _futureTable(
                  seat,
                  business[_id(seat[0])],
                  futureBookings['${date.id}|${_id(seat[0])}'],
                  pinOrder: _pinOrder(topCards, _id(seat[0])),
                  onlineSeats: onlineSeats,
                  offlineConverted: offlineConverted,
                ),
          ]..sort((left, right) {
            final pin = right.pinOrder.compareTo(left.pinOrder);
            if (pin != 0) return pin;
            final region = normalizedRegions
                .indexWhere((value) => value.id == left.regionId)
                .compareTo(
                  normalizedRegions.indexWhere(
                    (value) => value.id == right.regionId,
                  ),
                );
            if (region != 0) return region;
            final order = left.displayOrder.compareTo(right.displayOrder);
            return order != 0 ? order : left.name.compareTo(right.name);
          });
    }
    final supervisorScope = _supervisorRegionScope(
      stationId,
      roles,
      supervisorRegions,
    );
    final visibleRegionIds = normalizedTables
        .map((table) => table.regionId)
        .toSet();
    normalizedRegions.removeWhere(
      (region) => !visibleRegionIds.contains(region.id),
    );
    final normalizedStatusCounts = _normalizeStatusCounts(
      roleScopeKnown ? statusCountRows : const <String, List<Object?>>{},
    );
    return CardTableSnapshot(
      cursor: cursor,
      businessDayId: _id(businessDay[0]),
      storeName: _text(businessDay[2]),
      regions: normalizedRegions,
      tables: normalizedTables,
      businessDates: normalizedDates,
      tablesByDate: tablesByDate,
      statusCounts: normalizedStatusCounts.totals,
      statusCountsByRegion: normalizedStatusCounts.byRegion,
      pagePermissions: pagePermissions,
      safeModeEnabled: safeModeEnabled,
      bindGuestEnabled: showAmt.values.any(
        (row) => _id(row[0]) == '13' && _optionalNumber(row[1]) == 1,
      ),
      canClearSeat: showAmt.values.any(
        (row) => _id(row[0]) == '5' && _optionalNumber(row[1]) == 2,
      ),
      cardAmountsVisible: !showAmt.values.any(
        (row) => _id(row[0]) == '3' && _optionalNumber(row[1]) != 2,
      ),
      supervisorRegionRestricted: supervisorScope.restricted,
      supervisorAllowedRegionIds: supervisorScope.allowedRegionIds,
      seatMarks: [
        for (final row in seatMarks.values)
          if (_integer(row[2]) == 1) _optionalText(row[1]),
      ],
      employees: [
        for (final row in employees.values)
          CardEmployee(
            id: _id(row[0]),
            name: _optionalText(row[1]),
            namePy: _optionalText(row[7]),
            status: _integer(row[2]),
            deptId: row.length > 3 ? _optionalId(row[3]) : '',
            upperEmpId: row.length > 9 ? _optionalId(row[9]) : '',
            phone: row.length > 6 ? _optionalLooseText(row[6]) : '',
            code: row.length > 8 ? _employeeCode(row[8]) : '',
          ),
      ],
      departments: [
        for (final row in departments.values)
          if (_integer(row[2]) == 1)
            CardDepartment(id: _id(row[0]), name: _optionalText(row[1])),
      ],
      queue: CardTableQueueSnapshot(
        config: queueConfig != null
            ? QueueConfig.fromWire(queueConfig)
            : const QueueConfig(),
        types: [for (final row in queueTypes.values) QueueType.fromWire(row)],
        records: [
          for (final row in queueRecords.values) QueueRecord.fromWire(row),
        ],
        curNumbers: [
          for (final row in queueCurNumbers.values)
            QueueCurNumber.fromWire(row),
        ],
      ),
    );
  }

  static bool _mustOrderDisabled({
    required List<Object?>? region,
    required List<Object?>? business,
  }) {
    final hasMust =
        region != null &&
        (_optionalNumber(region.length > 4 ? region[4] : null) > 0 ||
            _optionalNumber(region.length > 5 ? region[5] : null) > 0 ||
            _optionalNumber(region.length > 6 ? region[6] : null) > 0);
    if (!hasMust) return true;
    return business != null &&
        business.length > 37 &&
        _optionalNumber(business[37]) == 1;
  }

  static bool _showOnlineText({
    required String seatId,
    required List<Object?>? business,
    required Map<String, List<Object?>> onlineSeats,
    required Map<String, List<Object?>> offlineConverted,
  }) {
    final converted = offlineConverted[seatId];
    if (converted != null && _integer(converted[1]) == 1) return false;
    final status = business == null ? 1 : _integer(business[19]);
    if (status > 2) {
      return business != null &&
          business.length > 22 &&
          _optionalNumber(business[22]) == 1;
    }
    final online = onlineSeats[seatId];
    return online != null && _optionalNumber(online[1]) == 1;
  }

  static int _pinOrder(Map<String, List<Object?>> topCards, String seatId) {
    final row = topCards[seatId];
    if (row == null) return 0;
    if (_integer(row[2]) != 1) return 0;
    final seq = _optionalNumber(row[1]).toInt();
    return seq > 0 ? seq : 0;
  }

  static CardTable _table(
    List<Object?> seat,
    List<Object?>? business, {
    List<Object?>? region,
    int pinOrder = 0,
    bool showOnlineText = false,
  }) => CardTable(
    id: _id(seat[0]),
    name: _text(seat[1]),
    regionId: _id(seat[3]),
    seatType: _integer(seat[4]),
    businessType: _integer(seat[5]),
    capacity: _integer(seat[6]),
    displayOrder: _integer(seat[7]),
    businessStatus: business == null ? 1 : _integer(business[19]),
    orderAmount: business == null ? 0 : _number(business[6]),
    discountAmount: business == null
        ? 0
        : _optionalNumber(business.length > 38 ? business[38] : null),
    paidAmount: business == null ? 0 : _number(business[8]),
    customerName: business == null ? '' : _optionalText(business[16]),
    customerCount: business == null ? 0 : _integer(business[18]),
    reservationTime: business == null ? '' : _optionalText(business[2]),
    expectedArriveTime: business == null ? '' : _optionalLooseText(business[4]),
    openTime: business == null ? '' : _optionalText(business[5]),
    remark: business == null ? '' : _optionalText(business[24]),
    mark: business == null ? '' : _optionalText(business[25]),
    salesEmployeeId:
        business == null || business[14] == null || business[14] == ''
        ? ''
        : _id(business[14]),
    waiterEmployeeIds: business == null || business[20] == null
        ? const <String>{}
        : _waiterEmployeeIds(business[20]),
    turnoverCount: business == null || business[13] == null
        ? 0
        : _integer(business[13]),
    giftAmount: business == null
        ? 0
        : _optionalNumber(business[11]) + _optionalNumber(business[12]),
    groupMinConsumeAmount: business == null ? 0 : _optionalNumber(business[9]),
    assignedMinConsumeAmount: business == null
        ? 0
        : _optionalNumber(business[10]),
    mainOrderAmount: business == null
        ? 0
        : _optionalNumber(business.length > 31 ? business[31] : null),
    paidMainFreeAmount: business == null
        ? 0
        : _optionalNumber(business.length > 30 ? business[30] : null),
    paidValAmount: business == null
        ? 0
        : _optionalNumber(business.length > 27 ? business[27] : null),
    waiterEmployeeId: business == null || business.length <= 34
        ? ''
        : _optionalId(business[34]),
    customerPhone: business == null || business.length <= 35
        ? ''
        : _optionalLooseText(business[35]),
    bookingCustomerPhone: business == null
        ? ''
        : _optionalLooseText(business[17]),
    customerNamePy: business == null || business.length <= 23
        ? ''
        : _optionalLooseText(business[23]),
    transferHistory: business == null || business.length <= 32
        ? ''
        : _optionalLooseText(business[32]),
    boundCustomerName: business == null || business.length <= 36
        ? ''
        : _optionalLooseText(business[36]),
    bookId: business == null || business[1] == null || business[1] == ''
        ? ''
        : _id(business[1]),
    platformId: business == null || business.length <= 22
        ? 0
        : _optionalNumber(business[22]).toInt(),
    secondSalesEmployeeId: business == null || business.length <= 15
        ? ''
        : _optionalId(business[15]),
    pinned: pinOrder > 0,
    pinOrder: pinOrder,
    mustOrderDisabled: _mustOrderDisabled(region: region, business: business),
    showOnlineText: showOnlineText,
  );

  static Set<String> _waiterEmployeeIds(Object? value) {
    if (value is! String || value.length > 65536) throw const FormatException();
    return <String>{
      for (final id in value.split(';'))
        if (id.isNotEmpty) _id(id),
    };
  }

  static CardTable _futureTable(
    List<Object?> seat,
    List<Object?>? currentBusiness,
    List<Object?>? booking, {
    int pinOrder = 0,
    Map<String, List<Object?>> onlineSeats = const <String, List<Object?>>{},
    Map<String, List<Object?>> offlineConverted =
        const <String, List<Object?>>{},
  }) {
    final currentStatus = currentBusiness == null
        ? 1
        : _integer(currentBusiness[19]);
    final activeBooking = booking != null && _integer(booking[9]) == 1;
    return CardTable(
      id: _id(seat[0]),
      name: _text(seat[1]),
      regionId: _id(seat[3]),
      seatType: _integer(seat[4]),
      businessType: _integer(seat[5]),
      capacity: _integer(seat[6]),
      displayOrder: _integer(seat[7]),
      businessStatus: activeBooking ? 8 : (currentStatus == 2 ? 2 : 1),
      orderAmount: 0,
      paidAmount: 0,
      customerName: activeBooking ? _optionalText(booking[6]) : '',
      bookingCustomerPhone: activeBooking ? _optionalLooseText(booking[7]) : '',
      customerNamePy: activeBooking && booking.length > 13
          ? _optionalLooseText(booking[13])
          : '',
      customerCount: activeBooking ? _integer(booking[8]) : 0,
      reservationTime: activeBooking ? _optionalText(booking[3]) : '',
      expectedArriveTime: activeBooking ? _optionalLooseText(booking[4]) : '',
      salesEmployeeId: activeBooking ? _optionalId(booking[5]) : '',
      secondSalesEmployeeId: activeBooking && booking.length > 11
          ? _optionalId(booking[11])
          : '',
      groupMinConsumeAmount: currentBusiness == null
          ? 0
          : _optionalNumber(currentBusiness[9]),
      openTime: '',
      remark: activeBooking ? _optionalText(booking[12]) : '',
      mark: '',
      bookId: activeBooking ? _id(booking[2]) : '',
      platformId: activeBooking && booking.length > 10
          ? _optionalNumber(booking[10]).toInt()
          : 0,
      pinned: pinOrder > 0,
      pinOrder: pinOrder,
      showOnlineText: activeBooking
          ? booking.length > 10 && _optionalNumber(booking[10]) == 1
          : _showOnlineText(
              seatId: _id(seat[0]),
              business: currentBusiness,
              onlineSeats: onlineSeats,
              offlineConverted: offlineConverted,
            ),
    );
  }

  static bool _isSeatPermitted(
    List<Object?> seat,
    String? machineId,
    Map<String, List<Object?>> accessRows,
  ) {
    if (machineId == null) return true;
    final normalizedMachineId = _id(machineId);
    final rows = accessRows.values.where(
      (row) => _id(row[0]) == normalizedMachineId && _integer(row[2]) == 1,
    );
    if (rows.any((row) => _integer(row[1]) == 3)) return true;
    final allowedRegions = <String>{
      for (final row in rows)
        if (_integer(row[1]) == 1) _id(row[3]),
    };
    final allowedSeats = <String>{
      for (final row in rows)
        if (_integer(row[1]) == 2) _id(row[3]),
    };
    final regionId = _id(seat[3]);
    final seatId = _id(seat[0]);
    if (allowedRegions.isNotEmpty && !allowedRegions.contains(regionId)) {
      return false;
    }
    return allowedSeats.isEmpty || allowedSeats.contains(seatId);
  }

  static ({bool restricted, Set<String> allowedRegionIds})
  _supervisorRegionScope(
    String? stationId,
    Map<String, List<Object?>> roleRows,
    Map<String, List<Object?>> supervisorRegionRows,
  ) {
    if (stationId == null) {
      return (restricted: false, allowedRegionIds: const <String>{});
    }
    final normalizedStationId = _id(stationId);
    final isSupervisor = roleRows.values.any(
      (row) =>
          _id(row[0]) == normalizedStationId &&
          _integer(row[1]) == 11 &&
          _integer(row[2]) == 1,
    );
    if (!isSupervisor) {
      return (restricted: false, allowedRegionIds: const <String>{});
    }
    final rows = supervisorRegionRows.values.where(
      (row) => _id(row[0]) == normalizedStationId && _integer(row[2]) == 1,
    );
    if (rows.any((row) => _id(row[1]) == '0')) {
      return (restricted: false, allowedRegionIds: const <String>{});
    }
    return (
      restricted: true,
      allowedRegionIds: rows.map((row) => _id(row[1])).toSet(),
    );
  }

  static bool _isSupervisorRegionPermitted(
    List<Object?> seat,
    String? stationId,
    Map<String, List<Object?>> roleRows,
    Map<String, List<Object?>> supervisorRegionRows,
  ) {
    final scope = _supervisorRegionScope(
      stationId,
      roleRows,
      supervisorRegionRows,
    );
    if (!scope.restricted) return true;
    return scope.allowedRegionIds.contains(_id(seat[3]));
  }

  static ({Map<int, int> totals, Map<String, Map<int, int>> byRegion})
  _normalizeStatusCounts(Map<String, List<Object?>> rows) {
    final totals = <int, int>{};
    final regionTotals = <int, int>{};
    final byRegion = <String, Map<int, int>>{};
    for (final row in rows.values) {
      final status = _integer(row[0]);
      final regionId = _id(row[1]);
      final count = _integer(row[2]);
      if (count < 0) throw const FormatException();
      if (regionId == '0') {
        totals[status] = count;
      } else {
        byRegion.putIfAbsent(regionId, () => <int, int>{})[status] = count;
        regionTotals.update(
          status,
          (value) => value + count,
          ifAbsent: () => count,
        );
      }
    }
    for (final entry in regionTotals.entries) {
      totals.putIfAbsent(entry.key, () => entry.value);
    }
    return (totals: totals, byRegion: byRegion);
  }

  static Map<String, List<Object?>> _copyRows(
    Map<String, List<Object?>> source,
  ) => <String, List<Object?>>{
    for (final entry in source.entries)
      entry.key: List<Object?>.unmodifiable(entry.value),
  };

  SoldOutProductCatalog _catalogFrom({
    required Map<String, List<Object?>> firstCategories,
    required Map<String, List<Object?>> secondCategories,
    required Map<String, List<Object?>> goods,
    required Map<String, List<Object?>> areaProducts,
  }) {
    try {
      return SoldOutProductCatalog.fromWire(
        firstCategories: firstCategories.values,
        secondCategories: secondCategories.values,
        products: goods.values,
        areaProducts: areaProducts.values,
        padDevice: _padDevice,
      );
    } on Object {
      return SoldOutProductCatalog.empty;
    }
  }

  static String _id(Object? value) {
    if (value is String &&
        value.isNotEmpty &&
        value.length <= 64 &&
        value.trim() == value &&
        RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
      return value;
    }
    if (value is num && value.isFinite && value % 1 == 0) {
      return value.toInt().toString();
    }
    throw const FormatException();
  }

  static int _integer(Object? value) {
    final number = _number(value);
    if (number % 1 != 0 || number.abs() > 9007199254740991) {
      throw const FormatException();
    }
    return number.toInt();
  }

  static num _number(Object? value) {
    final number = switch (value) {
      num() => value,
      String() when value.trim() == value => num.tryParse(value),
      _ => null,
    };
    if (number == null || !number.isFinite) throw const FormatException();
    return number;
  }

  static String _text(Object? value) {
    final text = _optionalText(value);
    if (text.isEmpty) throw const FormatException();
    return text;
  }

  static String _optionalText(Object? value) {
    if (value == null) return '';
    if (value is! String ||
        value.length > 256 ||
        RegExp(r'[\x00-\x1F\x7F]').hasMatch(value)) {
      throw const FormatException();
    }
    return value;
  }

  static num _optionalNumber(Object? value) {
    if (value == null || value == '') return 0;
    return _number(value);
  }

  static String _optionalId(Object? value) {
    if (value == null || value == '' || value == 0) return '';
    return _id(value);
  }

  static String _optionalLooseText(Object? value) {
    if (value == null || value == '') return '';
    if (value is num && value.isFinite) return value.toString();
    return _optionalText(value);
  }

  static String _employeeCode(Object? value) {
    if (value == null || value == '') return '';
    if (value is num && value.isFinite) return value.toString();
    return _optionalText(value);
  }

  String _goodsName(String id) {
    final row = _goods[id];
    if (row == null || row.length < 2) return '';
    return _optionalLooseText(row[1]);
  }

  List<String> _reasonNames(int typeId) {
    try {
      return <String>[
        for (final row in _reasons.values)
          if (_integer(row[2]) == 1 && _integer(row[3]) == typeId)
            _text(row[1]),
      ];
    } on Object {
      return const <String>[];
    }
  }

  static const AppFailure _shapeFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.card_table_shape',
    safeMessage: '卡台数据格式无法识别',
  );
  static const AppFailure _snapshotRequiredFailure = AppFailure(
    kind: FailureKind.realtime,
    code: 'protocol.card_table_snapshot_required',
    safeMessage: '正在等待完整卡台数据',
  );
}
