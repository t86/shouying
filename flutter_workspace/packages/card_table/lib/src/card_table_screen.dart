import 'dart:async';

import 'package:card_table/src/cashier_credit_accounts.dart';
import 'package:card_table/src/cashier_credit_accounts_screen.dart';
import 'package:card_table/src/cashier_merchant_management.dart';
import 'package:card_table/src/cashier_merchant_management_screen.dart';
import 'package:card_table/src/cashier_merchant_amounts.dart';

import 'package:card_table/src/cashier_voucher_records_screen.dart';

import 'package:card_table/src/cashier_profit_loss_screen.dart';
import 'package:card_table/src/cashier_profit_loss_metadata.dart';

import 'package:card_table/src/business_route_observer.dart';
import 'package:flutter/foundation.dart';

import 'package:card_table/src/booking_card_api.dart';
import 'package:card_table/src/booking_card_display.dart';
import 'package:card_table/src/booking_detail_access.dart';
import 'package:card_table/src/booking_form_widgets.dart';
import 'package:card_table/src/business_day_close_screen.dart';
import 'package:card_table/src/booking_queue.dart';
import 'package:card_table/src/booking_queue_loader.dart';
import 'package:card_table/src/booking_queue_screen.dart';
import 'package:card_table/src/booking_reports_loader.dart';
import 'package:card_table/src/booking_report_screens.dart';
import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/card_page_menus.dart';
import 'package:card_table/src/card_region_selector.dart';
import 'package:card_table/src/cocktail_detail_report.dart';
import 'package:card_table/src/cocktail_detail_report_screen.dart';
import 'package:card_table/src/minimum_consumption_report.dart';
import 'package:card_table/src/minimum_consumption_report_screen.dart';
import 'package:card_table/src/sold_out_products_screen.dart';
import 'package:card_table/src/account_password_screen.dart';
import 'package:card_table/src/order_card_display.dart';
import 'package:card_table/src/order_meal_screen.dart';
import 'package:card_table/src/order_late_deposit.dart';
import 'package:card_table/src/order_late_deposit_screen.dart';
import 'package:card_table/src/pay_order_screen.dart';
import 'package:card_table/src/vip_nav_screen.dart';
import 'package:card_table/src/vip_pages.dart';
import 'package:card_table/src/wine_order_screen.dart';
import 'package:card_table/src/sold_out_products.dart';
import 'package:card_table/src/vip_recharge_screen.dart';
import 'package:card_table/src/legacy_card_table_store.dart';
import 'package:card_table/src/live_order_operation_scope.dart';
import 'package:card_table/src/fc_price.dart';
import 'package:card_table/src/cashier_objection_drawer.dart';
import 'package:card_table/src/cashier_reports.dart';
import 'package:card_table/src/cashier_reports_screens.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

typedef CardTableSessionAction = Future<Result<void>> Function();
typedef BookingBookDetailLoader = Future<Result<BookingBookDetail>> Function(
  String bookId,
);

final class CardTableScreen extends StatefulWidget {
  const CardTableScreen({
    this.businessRouteObserver,
    required this.system,
    required this.events,
    required this.connectionPhase,
    this.connectionPhases,
    this.lastFailure,
    this.onLogout,
    this.onSwitchSystem,
    this.onOpenBusinessDay,
    this.onCloseBusinessDay,
    this.onPrintShiftBill,
    this.onLoadAutoClose,
    this.onSaveAutoClose,
    this.onRefresh,
    this.onOpenDiagnostics,
    this.onLoadMinimumConsumption,
    this.onLoadCocktailDetail,
    this.onListSoldOutProducts,
    this.onSetSoldOutProduct,
    this.onDeleteSoldOutProduct,
    this.onSearchVipCards,
    this.onLoadVipMember,
    this.onLoadVipRules,
    this.onCreateVipOrder,
    this.onCreateVipPay,
    this.onLoadVipLastSales,
    this.onPollVipOrderStatus,
    this.onChangePassword,
    this.onLoadAuthPasswordEnabled,
    this.onChangeAuthPassword,
    this.onAddOrderProduct,
    this.onOrderCartCount,
    this.onOrderCartItems,
    this.onSetOrderCartCount,
    this.onBindOrderWaiter,
    this.onSearchOrderGuests,
    this.onBindOrderGuest,
    this.onLoadOrderItems,
    this.onLoadOrderDetails,
    this.onCheckOrderAmounts,
    this.onPlaceOrder,
    this.onAddTimedProduct,
    this.onAddSet,
    this.onRefundOrder,
    this.onConvertCartToYh,
    this.onAddYh,
    this.onAddYh2,
    this.onAddRequirement,
    this.onChangeSetDetail,
    this.onConvertCartToYh2,
    this.onGiftOrdered,
    this.onChangeOrderedSet,
    this.onConvertOrderToYh2,
    this.onReprintKitchen,
    this.onPrintBill,
    this.onCleanSeat,
    this.onMergeYh2,
    this.onWaiterTodoOrders,
    this.onCreateWaiterPay,
    this.onRedeemCoupon,
    this.onListWineCsms,
    this.onSubmitSaveWine,
    this.onSubmitTakeWine,
    this.onSubmitConfiscateWine,
    this.onBookingCardWrite,
    this.onLoadBookingDetailConfig,
    this.initialBookingDetailConfig,
    this.onLoadBookDetail,
    this.onLoadSeatOpenLog,
    this.onExportSeatOpenLog,
    this.onLoadSeatChangeLog,
    this.onLoadBookList,
    this.onExportBookList,
    this.onLoadOnlineBookList,
    this.onExportOnlineBookList,
    this.onLoadSeatOpening,
    this.onExportSeatOpening,
    this.onLoadDeptRegionSeatOpen,
    this.onExportDeptRegionSeatOpen,
    this.onQueueCall,
    this.onQueueArrive,
    this.onQueueExpired,
    this.onExportQueueList,
    this.onLoadTurnoverSales,
    this.onChangeTurnoverSales,
    this.onLoadTurnbackList,
    this.onConfirmTurnback,
    this.onLoadOrderDetail,
    this.onOpenReserved,
    this.onOpenPayOrder,
    this.onLoadPayOrders,
    this.onMovePayOrder,
    this.onMovePaidPayOrder,
    this.paidTransfersNeedingVerification,
    this.onVerifyPaidTransfer,
    this.onBatchUpdateOrderWaiter,
    this.onBatchUpdateOrderAuther,
    this.onRefundPaidOrder,
    this.onPayCartItems,
    this.onAddPayChannel,
    this.onDeletePayChannel,
    this.onSubmitPayOrder,
    this.onPayCleanSeat,
    this.onPaySettleMode,
    this.onPayPrintBill,
    this.onPayAuthChannel,
    this.onPayLateChannel,
    this.onPayMemberChannel,
    this.onPayPrepayChannel,
    this.onOpenVipSystem,
    this.onListVipCards,
    this.onVipNewCardParams,
    this.onCreateVipCard,
    this.onVipPhoneCards,
    this.onVipMakeCardBegin,
    this.onVipMakeCardEnd,
    this.onVipSendSms,
    this.vipPages,
    this.onLoadObjectionList,
    this.onExecuteObjectionCommand,
    this.onLoadCashierReport,
    this.onLoadCashierReportPage,
    this.onLoadProfitLoss,
    this.onSubmitProfitLoss,
    this.onLoadCashierDepartments,
    this.onExportCashierReport,
    this.onPrintCashierReport,
    this.onPrintCashierReportQuery,
    this.onLoadVouchers,
    this.createCreditAccountsLoader,
    this.createMerchantManagementLoader,
    this.onCancelVoucher,
    this.onExportVouchers,
    this.onFindCashierPaymentCustomer,
    this.onChangeCashierPaymentCustomer,
    this.onOpenLateManagement,
    this.orderLateDepositLoader,
    this.userName,
    this.showCustomerDetails = false,
    this.machineId,
    this.stationId,
    this.employeeId,
    super.key,
  });

  static const Key searchKey = Key('card-table-search');
  static const Key gridKey = Key('card-table-grid');
  static const Key logoutKey = Key('card-table-logout');
  static const Key switchSystemKey = Key('card-table-switch-system');
  static const Key openBusinessDayKey = Key('card-table-open-business-day');
  static const Key refreshKey = Key('card-table-refresh');
  static const Key moreFunctionsKey = Key('card-table-more-functions');
  static const Key openDiagnosticsKey = Key('card-table-open-diagnostics');
  static const Key accountMenuKey = Key('card-table-account');
  static const Key mineKey = Key('card-table-mine');
  static const Key wineModeKey = Key('card-table-wine-mode');
  static const Key vipRechargeKey = Key('card-table-vip-recharge');
  static const Key cardMenuKey = Key('card-table-card-menu');
  static const Key bookingFormFieldKey = Key('card-table-booking-form-field');
  static const Key bookingFormPhoneKey = Key('card-table-booking-form-phone');
  static const Key bookingTransferDestKey = Key(
    'card-table-booking-transfer-dest',
  );
  static const Key bookingTransferMinConsumeKey = Key(
    'card-table-booking-transfer-min-consume',
  );
  static const Key objectionListKey = Key('card-table-objection-list');
  static const Key lateManagementKey = Key('card-table-late-management');
  static Key cardKey(String id) => ValueKey<String>('card-table-$id');

  final BusinessSystem system;
  final Stream<SyncEnvelope> events;
  final ConnectionPhase connectionPhase;
  final Stream<ConnectionPhase>? connectionPhases;
  final AppFailure? lastFailure;
  final CardTableSessionAction? onLogout;
  final CardTableSessionAction? onSwitchSystem;
  final CardTableSessionAction? onOpenBusinessDay;
  final CloseBusinessDay? onCloseBusinessDay;
  final PrintShiftBill? onPrintShiftBill;
  final LoadAutoClose? onLoadAutoClose;
  final SaveAutoClose? onSaveAutoClose;
  final CardTableSessionAction? onRefresh;
  final VoidCallback? onOpenDiagnostics;
  final MinimumConsumptionLoader? onLoadMinimumConsumption;
  final CocktailDetailLoader? onLoadCocktailDetail;
  final SoldOutListLoader? onListSoldOutProducts;
  final SoldOutSetLoader? onSetSoldOutProduct;
  final SoldOutDeleteLoader? onDeleteSoldOutProduct;
  final VipRechargeSearch? onSearchVipCards;
  final VipRechargeDetail? onLoadVipMember;
  final VipRechargeRules? onLoadVipRules;
  final VipRechargeCreateOrder? onCreateVipOrder;
  final VipRechargeCreatePay? onCreateVipPay;
  final VipRechargeLastSales? onLoadVipLastSales;
  final VipRechargePollStatus? onPollVipOrderStatus;
  final ChangePasswordSubmit? onChangePassword;
  final AuthPasswordEnabled? onLoadAuthPasswordEnabled;
  final AuthPasswordSubmit? onChangeAuthPassword;
  final OrderMealAddProduct? onAddOrderProduct;
  final OrderMealCartCount? onOrderCartCount;
  final OrderMealCartItems? onOrderCartItems;
  final OrderMealSetCartCount? onSetOrderCartCount;
  final OrderMealBindWaiter? onBindOrderWaiter;
  final OrderMealSearchGuests? onSearchOrderGuests;
  final OrderMealBindGuest? onBindOrderGuest;
  final OrderMealListOrders? onLoadOrderItems;
  final OrderMealLoadOrderDetails? onLoadOrderDetails;
  final Future<Result<bool>> Function(String seatId)? onCheckOrderAmounts;
  final OrderMealPlaceOrder? onPlaceOrder;
  final OrderMealAddTimed? onAddTimedProduct;
  final OrderMealAddSet? onAddSet;
  final OrderMealRefund? onRefundOrder;
  final OrderMealConvertYh? onConvertCartToYh;
  final OrderMealAddYh? onAddYh;
  final OrderMealAddYh2? onAddYh2;
  final OrderMealAddRequirement? onAddRequirement;
  final OrderMealChangeSetDetail? onChangeSetDetail;
  final OrderMealConvertYh2? onConvertCartToYh2;
  final OrderMealGiftOrdered? onGiftOrdered;
  final OrderMealChangeOrderedSet? onChangeOrderedSet;
  final OrderMealConvertOrderYh2? onConvertOrderToYh2;
  final OrderMealReprintKitchen? onReprintKitchen;
  final OrderMealPrintBill? onPrintBill;
  final OrderMealCleanSeat? onCleanSeat;
  final OrderMealMergeYh2? onMergeYh2;
  final OrderMealWaiterTodos? onWaiterTodoOrders;
  final OrderMealCreateWaiterPay? onCreateWaiterPay;
  final OrderMealRedeemCoupon? onRedeemCoupon;
  final WineListCsms? onListWineCsms;
  final WineSubmitSave? onSubmitSaveWine;
  final WineSubmitTake? onSubmitTakeWine;
  final WineSubmitConfiscate? onSubmitConfiscateWine;
  final BookingCardWrite? onBookingCardWrite;
  final BookingDetailConfigLoader? onLoadBookingDetailConfig;
  final BookingDetailConfig? initialBookingDetailConfig;
  final BookingBookDetailLoader? onLoadBookDetail;
  final SeatOpenLogLoader? onLoadSeatOpenLog;
  final SeatOpenLogExporter? onExportSeatOpenLog;
  final SeatChangeLogLoader? onLoadSeatChangeLog;
  final BookListLoader? onLoadBookList;
  final BookingReportExporter? onExportBookList;
  final OnlineBookListLoader? onLoadOnlineBookList;
  final BookingReportExporter? onExportOnlineBookList;
  final SeatOpeningLoader? onLoadSeatOpening;
  final BookingReportExporter? onExportSeatOpening;
  final DeptRegionSeatOpenLoader? onLoadDeptRegionSeatOpen;
  final BookingReportExporter? onExportDeptRegionSeatOpen;
  final BookingQueueAction? onQueueCall;
  final BookingQueueAction? onQueueArrive;
  final BookingQueueAction? onQueueExpired;
  final BookingQueueExporter? onExportQueueList;
  final Future<Result<List<TurnoverSaleHistoryItem>>> Function(String seatId)?
  onLoadTurnoverSales;
  final Future<Result<void>> Function({
    required String seatId,
    required String csmId,
    required String salesEmpId,
    String secondSalesEmpId,
    required String reason,
  })?
  onChangeTurnoverSales;
  final Future<Result<List<SeatTurnbackItem>>> Function(String seatId)?
  onLoadTurnbackList;
  final Future<Result<void>> Function(String csmId)? onConfirmTurnback;
  final Future<Result<BookingOrderDetailData>> Function({
    required String seatId,
    required int turnoverCount,
  })?
  onLoadOrderDetail;
  final VoidCallback? onOpenReserved;
  final void Function(CardTable table)? onOpenPayOrder;
  final PayOrderLoad? onLoadPayOrders;
  final PayOrderMove? onMovePayOrder;
  final PayOrderMovePayed? onMovePaidPayOrder;
  final Set<String> Function(String)? paidTransfersNeedingVerification;
  final PayOrderVerifyPaidTransfer? onVerifyPaidTransfer;
  final PayOrderBatchWaiter? onBatchUpdateOrderWaiter;
  final PayOrderBatchAuther? onBatchUpdateOrderAuther;
  final PayOrderRefundPayed? onRefundPaidOrder;
  final PayOrderCart? onPayCartItems;
  final PayOrderAddChannel? onAddPayChannel;
  final PayOrderDeleteChannel? onDeletePayChannel;
  final PayOrderPay? onSubmitPayOrder;
  final PayOrderClean? onPayCleanSeat;
  final PayOrderSettle? onPaySettleMode;
  final PayOrderPrint? onPayPrintBill;
  final PayOrderAuthZero? onPayAuthChannel;
  final PayOrderLateChannel? onPayLateChannel;
  final PayOrderMemberChannel? onPayMemberChannel;
  final PayOrderPrepayChannel? onPayPrepayChannel;
  final VoidCallback? onOpenVipSystem;
  final VipListCards? onListVipCards;
  final VipNewParams? onVipNewCardParams;
  final VipCreateCard? onCreateVipCard;
  final VipPhoneCards? onVipPhoneCards;
  final VipMakeBegin? onVipMakeCardBegin;
  final VipMakeEnd? onVipMakeCardEnd;
  final VipSendSms? onVipSendSms;
  final VipPages? vipPages;
  final Future<Result<CashierObjectionData>> Function()? onLoadObjectionList;
  final Future<Result<void>> Function(String id, String commandKey)?
  onExecuteObjectionCommand;
  final Future<Result<List<CashierReportRow>>> Function(
    String title,
    String startDate,
    String endDate,
    String keyword,
  )?
  onLoadCashierReport;
  final Future<Result<CashierReportPage>> Function(CashierReportQuery)?
  onLoadCashierReportPage;
  final CashierProfitLossLoad? onLoadProfitLoss;
  final CashierProfitLossSubmit? onSubmitProfitLoss;
  final Future<Result<Map<int, String>>> Function()? onLoadCashierDepartments;
  final Future<Result<String>> Function(CashierReportQuery)?
  onExportCashierReport;
  final Future<Result<void>> Function(String)? onPrintCashierReport;
  final Future<Result<void>> Function(CashierReportQuery)?
  onPrintCashierReportQuery;
  final CashierVoucherLoad? onLoadVouchers;
  final CashierCreditAccountsLoader Function()? createCreditAccountsLoader;
  final CashierMerchantManagementLoader Function()?
  createMerchantManagementLoader;
  final CashierVoucherCancel? onCancelVoucher;
  final CashierVoucherExport? onExportVouchers;
  final Future<Result<CashierPaymentCustomer?>> Function(String)?
  onFindCashierPaymentCustomer;
  final Future<Result<void>> Function(String, String)?
  onChangeCashierPaymentCustomer;
  final VoidCallback? onOpenLateManagement;
  final OrderLateDepositLoader? orderLateDepositLoader;
  final String? userName;
  final bool showCustomerDetails;
  final String? machineId;
  final String? stationId;
  final String? employeeId;
  final BusinessRouteObserver? businessRouteObserver;

  @override
  State<CardTableScreen> createState() => _CardTableScreenState();
}

/// A delayed dialog response can remove only its own route, never a newer one.
void _closeBusinessRoute<T>(BuildContext context, [T? result]) {
  if (!context.mounted) return;
  final route = ModalRoute.of(context);
  if (route?.isCurrent == true) {
    route!.navigator?.pop(result);
  } else if (route?.isActive == true) {
    route!.navigator?.removeRoute(route, result);
  }
}

final class _CardTableScreenState extends State<CardTableScreen> {
  Route<dynamic>? _businessOwner;
  BusinessRouteObserver? _registeredBusinessObserver;

  void _registerBusinessOwner() {
    final route = ModalRoute.of(context);
    if (identical(route, _businessOwner) &&
        identical(widget.businessRouteObserver, _registeredBusinessObserver)) {
      return;
    }
    if (_businessOwner case final old?)
      _registeredBusinessObserver?.unregisterOwner(old);
    _businessOwner = route;
    _registeredBusinessObserver = widget.businessRouteObserver;
    if (route != null) _registeredBusinessObserver?.registerOwner(route);
  }

  late LegacyCardTableStore _store;
  final _orderOperationPhases = StreamController<ConnectionPhase>.broadcast(
    sync: true,
  );
  final _orderOperationScopes = <LiveOrderOperationScope>{};

  LiveOrderOperationScope _createOrderOperationScope(
    CardTable table, {
    bool orderEntry = false,
  }) {
    final scope = LiveOrderOperationScope(
      table: table,
      events: widget.events,
      phases: _orderOperationPhases.stream,
      initialPhase: _livePhase ?? widget.connectionPhase,
      initialSnapshot: _store.replayEnvelope,
      invalidateOnStatusChange: false,
      // Vue order entry excludes only 1/2/8. Deleted 22/33 rows are removed by
      // the store. Payment retains the narrower existing default policy.
      canOperateInStatus: orderEntry
          ? (status) => !const {1, 2, 8}.contains(status)
          : null,
    );
    _orderOperationScopes.add(scope);
    return scope;
  }

  void _disposeOrderOperationScopes() {
    for (final scope in _orderOperationScopes) {
      unawaited(scope.dispose()); // Invalidates its token synchronously.
    }
    _orderOperationScopes.clear();
  }

  ValueNotifier<CardTable?> _liveTableAmounts = ValueNotifier(null);
  final ValueNotifier<int> _productPricingChanges = ValueNotifier(0);
  String? _amountSeatId, _amountDayId;
  int? _amountTurnover;
  bool _amountsBlocked = false;

  void _publishLiveTableAmounts() {
    final snapshot = _store.currentSnapshot;
    _liveTableAmounts.value =
        _amountsBlocked ||
            _fcAwaitingFull ||
            (_livePhase ?? widget.connectionPhase) != ConnectionPhase.online ||
            snapshot?.businessDayId != _amountDayId
        ? null
        : snapshot?.tables
              .where(
                (table) =>
                    table.id == _amountSeatId &&
                    table.turnoverCount == _amountTurnover,
              )
              .firstOrNull;
  }

  ValueNotifier<Object?> _refundContext = ValueNotifier(null);
  String? _refundSeatId;
  String? _refundOpenedScope;
  bool _refundNeedsFull = false;

  String _refundTableScope(CardTableSnapshot snapshot, CardTable table) =>
      '${snapshot.businessDayId}|${table.id}|${table.turnoverCount}|${table.businessStatus}';

  void _publishRefundContext() {
    final snapshot = _store.currentSnapshot;
    CardTable? current;
    if (snapshot != null) {
      for (final table in snapshot.tables) {
        if (table.id == _refundSeatId) current = table;
      }
    }
    final available =
        !_fcAwaitingFull &&
        !_refundNeedsFull &&
        (_livePhase ?? widget.connectionPhase) == ConnectionPhase.online &&
        snapshot != null &&
        snapshot.businessOpen &&
        current != null &&
        current.businessStatus != 1 &&
        _refundOpenedScope == _refundTableScope(snapshot, current);
    if (!available) {
      _refundContext.value = null;
    } else {
      // A reconnect gets a new token; existing authorization dialogs cannot
      // become valid again. Price-only updates preserve the historical scope.
      _refundContext.value ??= Object();
    }
  }

  ValueNotifier<FcPriceCatalog> _fcPrices = ValueNotifier(
    FcPriceCatalog.unknown,
  );
  ValueNotifier<bool> _orderSummaryVisible = ValueNotifier(false);
  ValueNotifier<bool> _footerAmountsVisible = ValueNotifier(false);
  String? _footerSeatId;
  String? _footerScope;
  bool? _footerServerAllowed;
  int _footerRequest = 0;
  bool _footerMetadataValid = false;
  bool _footerWide = true;
  bool _fcAwaitingFull = false;

  void _publishFcPrices() {
    if (!_orderOperationPhases.isClosed) {
      _orderOperationPhases.add(_livePhase ?? widget.connectionPhase);
    }
    _publishLiveTableAmounts();
    _productPricingChanges.value++;
    _publishRefundContext();
    _orderSummaryVisible.value =
        !_fcAwaitingFull &&
        (_livePhase ?? widget.connectionPhase) == ConnectionPhase.online &&
        OrderCardDisplay.canShowOrderSummary(
          permissions: _store.currentSnapshot?.pagePermissions,
          isPc:
              defaultTargetPlatform != TargetPlatform.android &&
              defaultTargetPlatform != TargetPlatform.iOS,
        );
    _fcPrices.value =
        !_fcAwaitingFull &&
            (_livePhase ?? widget.connectionPhase) == ConnectionPhase.online
        ? _store.fcPriceCatalog
        : FcPriceCatalog.unknown;
    _publishFooterAccess();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registerBusinessOwner();
    _footerWide = MediaQuery.sizeOf(context).width >= 1024;
    _publishFooterAccess();
  }

  void _publishFooterAccess() {
    final snapshot = _store.currentSnapshot;
    final permissions = snapshot?.pagePermissions;
    final table = snapshot?.tables
        .where((table) => table.id == _footerSeatId)
        .firstOrNull;
    final data = _store.replayEnvelope?.data;
    final regions = data is List && data.length > 56 ? data[56] : null;
    final ready =
        !_fcAwaitingFull &&
        _footerMetadataValid &&
        (_livePhase ?? widget.connectionPhase) == ConnectionPhase.online &&
        permissions?.available == true &&
        table != null;
    final staffScope = snapshot?.employees
        .map((emp) => '${emp.id}:${emp.deptId}:${emp.upperEmpId}')
        .join('|');
    final scope =
        '$ready|${widget.employeeId}|${widget.system}|${table?.id}|${table?.regionId}|${table?.salesEmployeeId}|${table?.waiterEmployeeIds}|${table?.openTime}|${table?.turnoverCount}|$staffScope|${permissions?.hashCode}|$regions';
    if (scope != _footerScope) {
      _footerScope = scope;
      _footerServerAllowed = null;
      final request = ++_footerRequest;
      final check = widget.onCheckOrderAmounts;
      if (ready && widget.system != BusinessSystem.cashier && check != null) {
        unawaited(() async {
          bool allowed = false;
          try {
            allowed = (await check(table.id)).valueOrNull == true;
          } on Object {
            allowed = false;
          }
          if (!mounted || request != _footerRequest) return;
          _footerServerAllowed = allowed;
          _publishFooterAccess();
        }());
      }
    }
    _footerAmountsVisible.value =
        ready &&
        OrderCardDisplay.canShowFooterAmounts(
          permissions: permissions,
          isPc:
              defaultTargetPlatform != TargetPlatform.android &&
              defaultTargetPlatform != TargetPlatform.iOS,
          isCashier: widget.system == BusinessSystem.cashier,
          canLookOrderAmount: _footerServerAllowed,
          regionId: table.regionId,
          supervisorRegions: regions,
          isWide: _footerWide,
          safeModeEnabled: snapshot?.safeModeEnabled ?? true,
        );
  }

  void _resetFcPrices() {
    _disposeOrderOperationScopes();
    _liveTableAmounts.value = null;
    _liveTableAmounts.dispose();
    _liveTableAmounts = ValueNotifier(null);
    _amountSeatId = null;
    _amountDayId = null;
    _amountTurnover = null;
    _amountsBlocked = true;
    _refundNeedsFull = true;
    _refundContext.value = null;
    _refundContext.dispose();
    _refundContext = ValueNotifier(null);
    _refundSeatId = null;
    _refundOpenedScope = null;
    _footerRequest++;
    _footerSeatId = null;
    _footerScope = null;
    _footerMetadataValid = false;
    _footerAmountsVisible.value = false;
    _footerAmountsVisible.dispose();
    _footerAmountsVisible = ValueNotifier(false);
    _orderSummaryVisible.value = false;
    _orderSummaryVisible.dispose();
    _orderSummaryVisible = ValueNotifier(false);
    _fcAwaitingFull = true;
    _fcPrices.value = FcPriceCatalog.unknown;
    _fcPrices.dispose();
    _fcPrices = ValueNotifier(FcPriceCatalog.unknown);
  }

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _gridController = ScrollController();
  bool _mineOnly = false;
  bool _wineMode = false;
  bool _moreMenuOpen = false;
  bool _reportOpen = false;
  final ValueNotifier<bool> _reportCanRead = ValueNotifier(false);
  final CashierProfitLossMetadata _profitCatalog = CashierProfitLossMetadata();
  final ValueNotifier<bool> _soldOutCanMaintain = ValueNotifier(false);
  final _merchantAmounts = CashierMerchantAmounts();
  CashierCreditAccountsLoader? _creditAccountsLoader;
  CashierMerchantManagementLoader? _merchantManagementLoader;
  final ValueNotifier<bool> _paymentCanModify = ValueNotifier(false);
  ValueNotifier<bool>? _businessDayAccess;
  String? _openedBusinessDay;
  int _businessDayOwner = 0;
  final Set<VoidCallback> _bookingValidityChecks = {};

  void _invalidateBusinessDayOwner() {
    _businessDayOwner++;
    _businessDayAccess?.value = false;
  }

  void _updateBusinessDayAccess() {
    if ((_livePhase ?? widget.connectionPhase) != ConnectionPhase.online ||
        _snapshot == null ||
        _failure != null ||
        (_snapshot?.safeModeEnabled ?? true) ||
        _snapshot?.businessDayId != _openedBusinessDay) {
      _businessDayAccess?.value = false;
    }
  }

  StreamSubscription<ConnectionPhase>? _livePhaseSubscription;
  ConnectionPhase? _livePhase;
  int _phaseSubscriptionVersion = 0;
  StreamSubscription<SyncEnvelope>? _subscription;
  CardTableSnapshot? _snapshot;
  AppFailure? _failure;
  String? _regionId;
  int? _businessStatus;
  String? _businessDateId;
  bool _sessionActionInProgress = false;
  AppFailure? _sessionFailure;
  bool _businessDayOpening = false;
  AppFailure? _businessDayFailure;
  String? _businessDayMessage;
  BookingDetailConfig _bookingDetailConfig = BookingDetailConfig.restricted;
  int _bookingDetailConfigRequest = 0;

  BookingDetailConfig _defaultBookingDetailConfig() {
    if (widget.initialBookingDetailConfig != null) {
      return widget.initialBookingDetailConfig!;
    }
    if (widget.onLoadBookingDetailConfig == null) {
      return BookingDetailConfig.unrestrictedAll;
    }
    return BookingDetailConfig.restricted;
  }

  Future<void> _loadBookingDetailConfig() async {
    if (!_isBooking) return;
    final loader = widget.onLoadBookingDetailConfig;
    if (loader == null) {
      if (mounted) {
        setState(() {
          _bookingDetailConfig =
              widget.initialBookingDetailConfig ??
              BookingDetailConfig.unrestrictedAll;
        });
      }
      return;
    }
    final requestId = ++_bookingDetailConfigRequest;
    if ((_livePhase ?? widget.connectionPhase) != ConnectionPhase.online) {
      if (mounted) {
        setState(() => _bookingDetailConfig = BookingDetailConfig.restricted);
      }
      return;
    }
    try {
      final result = await loader();
      if (!mounted || requestId != _bookingDetailConfigRequest) return;
      setState(() {
        _bookingDetailConfig =
            result.valueOrNull ?? BookingDetailConfig.restricted;
      });
    } on Object {
      if (!mounted || requestId != _bookingDetailConfigRequest) return;
      setState(() => _bookingDetailConfig = BookingDetailConfig.restricted);
    }
  }

  @override
  void initState() {
    super.initState();
    _mineOnly = widget.system == BusinessSystem.order;
    _bookingDetailConfig = _defaultBookingDetailConfig();
    _store = LegacyCardTableStore(
      machineId: widget.machineId,
      stationId: widget.stationId,
      padDevice: _padDevice,
    );
    _reportCanRead.addListener(_updatePaymentAccess);
    _observeConnectionPhases();
    _subscribe();
    if (_isBooking && widget.onLoadBookingDetailConfig != null) {
      unawaited(_loadBookingDetailConfig());
    }
  }

  @override
  void didUpdateWidget(CardTableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connectionPhase != widget.connectionPhase &&
        widget.connectionPhase != ConnectionPhase.online) {
      _profitCatalog.invalidate();
      _merchantAmounts.invalidate();
    }
    _registerBusinessOwner();
    if (oldWidget.employeeId != widget.employeeId ||
        oldWidget.stationId != widget.stationId ||
        oldWidget.machineId != widget.machineId ||
        oldWidget.system != widget.system) {
      _invalidateBusinessDayOwner();
      if (_businessOwner case final owner?)
        _registeredBusinessObserver?.closeOwnedRoutes(owner);
    }
    if (oldWidget.onCheckOrderAmounts != widget.onCheckOrderAmounts)
      _footerScope = null;
    if (!identical(oldWidget.connectionPhases, widget.connectionPhases)) {
      _businessDayAccess?.value = false;
      _merchantAmounts.invalidate();
      _reportCanRead.value = false;
      _observeConnectionPhases();
    }
    if (oldWidget.system != widget.system ||
        oldWidget.employeeId != widget.employeeId) {
      _mineOnly = widget.system == BusinessSystem.order;
      _wineMode = false;
      _regionId = null;
      _businessStatus = null;
      _businessDateId = null;
      _searchController.clear();
      _reportCanRead.value = false;
    }
    if (oldWidget.system != widget.system ||
        oldWidget.machineId != widget.machineId ||
        oldWidget.stationId != widget.stationId ||
        oldWidget.employeeId != widget.employeeId) {
      _resetFcPrices();
      _profitCatalog.invalidate();
      _merchantAmounts.invalidate();
      _store = LegacyCardTableStore(
        machineId: widget.machineId,
        stationId: widget.stationId,
        padDevice: _padDevice,
      );
      _snapshot = null;
      _failure = null;
      _subscribe();
    } else if (!identical(oldWidget.events, widget.events)) {
      _businessDayAccess?.value = false;
      _profitCatalog.invalidate();
      _resetFcPrices();
      _merchantAmounts.invalidate();
      _subscribe();
    }
    if (oldWidget.system != widget.system ||
        oldWidget.machineId != widget.machineId ||
        oldWidget.stationId != widget.stationId ||
        oldWidget.employeeId != widget.employeeId ||
        oldWidget.onLoadBookingDetailConfig !=
            widget.onLoadBookingDetailConfig ||
        oldWidget.initialBookingDetailConfig !=
            widget.initialBookingDetailConfig) {
      _bookingDetailConfigRequest++;
      _bookingDetailConfig = _defaultBookingDetailConfig();
      if (_isBooking && widget.onLoadBookingDetailConfig != null) {
        unawaited(_loadBookingDetailConfig());
      }
    }
    if (oldWidget.connectionPhase != widget.connectionPhase &&
        widget.connectionPhase == ConnectionPhase.online &&
        _isBooking &&
        widget.onLoadBookingDetailConfig != null) {
      unawaited(_loadBookingDetailConfig());
    }
    _publishFcPrices();
    _updateReportAccess();
  }

  @override
  void dispose() {
    _invalidateBusinessDayOwner();
    _productPricingChanges.dispose();
    _disposeOrderOperationScopes();
    unawaited(_orderOperationPhases.close());
    if (_businessOwner case final owner?)
      _registeredBusinessObserver?.unregisterOwner(owner);
    _liveTableAmounts.value = null;
    _liveTableAmounts.dispose();
    _refundContext.value = null;
    _refundContext.dispose();
    _footerRequest++;
    _footerAmountsVisible.value = false;
    _footerAmountsVisible.dispose();
    _orderSummaryVisible.value = false;
    _orderSummaryVisible.dispose();
    _fcPrices.value = FcPriceCatalog.unknown;
    _fcPrices.dispose();
    _phaseSubscriptionVersion++;
    unawaited(_livePhaseSubscription?.cancel());
    _reportCanRead.value = false;
    _reportCanRead.removeListener(_updatePaymentAccess);
    _paymentCanModify.dispose();
    _reportCanRead.dispose();
    _profitCatalog.dispose();
    _merchantAmounts.dispose();
    _soldOutCanMaintain.dispose();
    unawaited(_subscription?.cancel());
    _searchController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  void _observeConnectionPhases() {
    final version = ++_phaseSubscriptionVersion;
    unawaited(_livePhaseSubscription?.cancel());
    _livePhase = widget.connectionPhases == null
        ? null
        : widget.connectionPhase;
    _livePhaseSubscription = widget.connectionPhases?.listen(
      (phase) {
        if (!mounted || version != _phaseSubscriptionVersion) return;
        _livePhase = phase;
        _publishFcPrices();
        // StreamProvider may coalesce two connection changes into one frame.
        // Observe the raw edge so already-displayed rows are invalidated too.
        if (phase != ConnectionPhase.online) {
          _reportCanRead.value = false;
          _profitCatalog.invalidate();
          _merchantAmounts.invalidate();
          if (_isBooking && widget.onLoadBookingDetailConfig != null) {
            _bookingDetailConfigRequest++;
            _bookingDetailConfig = BookingDetailConfig.restricted;
          }
        } else if (_isBooking && widget.onLoadBookingDetailConfig != null) {
          unawaited(_loadBookingDetailConfig());
        }
        _updateReportAccess();
      },
      onError: (Object _) {
        if (!mounted || version != _phaseSubscriptionVersion) return;
        _profitCatalog.invalidate();
        _merchantAmounts.invalidate();
        _livePhase = ConnectionPhase.blocked;
        _publishFcPrices();
        _reportCanRead.value = false;
        _businessDayAccess?.value = false;
      },
      onDone: () {
        if (mounted && version == _phaseSubscriptionVersion) {
          _profitCatalog.invalidate();
          _merchantAmounts.invalidate();
          _livePhase = ConnectionPhase.blocked;
          _publishFcPrices();
          _updateReportAccess();
          _businessDayAccess?.value = false;
        }
      },
    );
  }

  void _subscribe() {
    unawaited(_subscription?.cancel());
    _subscription = widget.events.listen(
      (event) {
        if (!mounted) return;
        _profitCatalog.add(event);
        _merchantAmounts.add(event);
        final lackedSnapshot = _store.currentSnapshot == null;
        final result = _store.applyEnvelope(event);
        if (!mounted) return;
        final payload = event.data;
        final amountTouched =
            payload is List ||
            (payload is Map &&
                (payload.containsKey(14) ||
                    payload.containsKey('14') ||
                    payload.containsKey(18) ||
                    payload.containsKey('18')));
        if (amountTouched) _amountsBlocked = result.failureOrNull != null;
        if (result.failureOrNull != null) {
          _refundNeedsFull = true;
        } else if (lackedSnapshot || event.data is List) {
          _refundNeedsFull = false;
        }
        if (result.failureOrNull != null) _footerMetadataValid = false;
        if (result.failureOrNull == null &&
            (lackedSnapshot || event.data is List)) {
          _footerMetadataValid = true;
          _fcAwaitingFull = false;
        }
        _publishFcPrices();
        final next = result.valueOrNull ?? _store.currentSnapshot ?? _snapshot;
        if (_snapshot?.businessDayId != next?.businessDayId ||
            _snapshot?.pagePermissions != next?.pagePermissions ||
            _visibleRegions(_snapshot).map((r) => r.id).join('|') !=
                _visibleRegions(next).map((r) => r.id).join('|')) {
          // Even if the report remains available, old rows were authorized under
          // a different scope. Require a fresh explicit query after this pulse.
          _reportCanRead.value = false;
        }
        if (_moreMenuOpen &&
            _moreLabels(_snapshot).join('|') != _moreLabels(next).join('|')) {
          _moreMenuOpen = false;
          if (_businessOwner case final owner?)
            _registeredBusinessObserver?.closeOwnedPopups(owner);
        }
        setState(() {
          _snapshot = next;
          _failure = result.failureOrNull;
          if (_regionId != null &&
              !_visibleRegions(_snapshot).any((r) => r.id == _regionId)) {
            _regionId = null;
            _mineOnly = _isOrder;
            _businessStatus = null;
            _searchController.clear();
          }
          if (!(_snapshot?.pagePermissions?.moduleIds.contains(1) ?? false)) {
            _wineMode = false;
          }
          final dates = _snapshot?.businessDates ?? const <CardBusinessDate>[];
          if (dates.isNotEmpty &&
              !dates.any((date) => date.id == _businessDateId)) {
            _businessDateId = dates.first.id;
          }
        });
        _updateReportAccess();
      },
      onError: (Object _) {
        if (!mounted) return;
        _profitCatalog.invalidate();
        _merchantAmounts.invalidate();
        _livePhase = ConnectionPhase.blocked;
        _publishFcPrices();
        _updateReportAccess();
        _businessDayAccess?.value = false;
      },
      onDone: () {
        if (!mounted) return;
        _profitCatalog.invalidate();
        _merchantAmounts.invalidate();
        _livePhase = ConnectionPhase.blocked;
        _publishFcPrices();
        _updateReportAccess();
        _businessDayAccess?.value = false;
      },
    );
  }

  void _updateReportAccess() {
    for (final check in _bookingValidityChecks.toList()) {
      check();
    }
    _updateBusinessDayAccess();
    if (_isBooking) {
      _reportCanRead.value =
          !_sessionActionInProgress &&
          (_livePhase ?? widget.connectionPhase) == ConnectionPhase.online;
      return;
    }
    _reportCanRead.value =
        (_isOrder || widget.system == BusinessSystem.cashier) &&
        !_sessionActionInProgress &&
        widget.employeeId?.isNotEmpty == true &&
        widget.stationId?.isNotEmpty == true &&
        (_livePhase ?? widget.connectionPhase) == ConnectionPhase.online &&
        _snapshot?.pagePermissions?.available == true &&
        !(_snapshot?.safeModeEnabled ?? true);
    _updatePaymentAccess();
  }

  void _updatePaymentAccess() {
    _soldOutCanMaintain.value =
        _reportCanRead.value &&
        (widget.system == BusinessSystem.cashier ||
            (_isOrder && _pageModules(_snapshot).contains(5)));
    _paymentCanModify.value =
        _reportCanRead.value &&
        (num.tryParse(_snapshot?.businessDayId ?? '') ?? 0) > 0;
  }

  Future<Result<CashierReportOptions>> _cashierReportOptions(
    String title,
  ) async {
    if (!_reportCanRead.value)
      return const FailureResult(
        AppFailure(
          kind: FailureKind.authentication,
          code: 'report.context_changed',
          safeMessage: '报表读取权限已改变',
        ),
      );
    final store = _store;
    final regions = store.cashierReportRegionOptions;
    Map<int, String> departments = const {};
    if (title == '业绩日报表') {
      final load = widget.onLoadCashierDepartments;
      if (load == null)
        return const FailureResult(
          AppFailure(
            kind: FailureKind.protocol,
            code: 'report.options_unavailable',
            safeMessage: '部门筛选服务未连接',
          ),
        );
      final result = await load();
      if (result.failureOrNull case final failure?)
        return FailureResult(failure);
      departments = result.valueOrNull!;
    }
    if (!mounted || !_reportCanRead.value || !identical(store, _store))
      return const FailureResult(
        AppFailure(
          kind: FailureKind.authentication,
          code: 'report.context_changed',
          safeMessage: '报表读取权限已改变',
        ),
      );
    return Success(
      CashierReportOptions(
        regions: regions,
        departments: departments,
        salesEmployees: store.cashierReportSalesOptions,
        salesSearchTerms: store.cashierReportSalesSearchTerms,
      ),
    );
  }

  bool _isMinimumReport(String label) =>
      _isOrder && label == '低消进度统计表' && widget.onLoadMinimumConsumption != null;

  bool _isCocktailReport(String label) =>
      _isOrder && label == '鸡尾酒明细表' && widget.onLoadCocktailDetail != null;

  bool _isSoldOutProducts(String label) =>
      (_isOrder || widget.system == BusinessSystem.cashier) &&
      label == '估清商品' &&
      widget.onListSoldOutProducts != null &&
      widget.onSetSoldOutProduct != null &&
      widget.onDeleteSoldOutProduct != null;

  bool _isProfitLoss(String label) =>
      widget.system == BusinessSystem.cashier &&
      label == '盘盈盘亏' &&
      widget.onLoadProfitLoss != null &&
      widget.onSubmitProfitLoss != null;

  bool _isCreditAccounts(String label) =>
      widget.system == BusinessSystem.cashier &&
      label == '挂账账户' &&
      widget.createCreditAccountsLoader != null;
  bool _isMerchantManagement(String label) =>
      widget.system == BusinessSystem.cashier &&
      label == '商户号管理' &&
      widget.createMerchantManagementLoader != null;
  Future<void> _openCreditAccounts() async {
    if (_reportOpen || !mounted) return;
    _updateReportAccess();
    if (!_reportCanRead.value) return;
    final factory = widget.createCreditAccountsLoader;
    if (factory == null) return;
    final loader = _creditAccountsLoader ??= factory();
    _reportOpen = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (_) => CashierCreditAccountsScreen(
            loader: loader,
            canOperate: _reportCanRead,
          ),
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openMerchantManagement([CashierMerchantAmount? amount]) async {
    if (_reportOpen || !mounted) return;
    _updateReportAccess();
    if (!_reportCanRead.value) return;
    final factory = widget.createMerchantManagementLoader;
    if (factory == null) return;
    final loader = _merchantManagementLoader ??= factory();
    _reportOpen = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (_) => amount == null
              ? CashierMerchantManagementScreen(
                  loader: loader,
                  canOperate: _reportCanRead,
                )
              : CashierMerchantInformationScreen(
                  loader: loader,
                  canOperate: _reportCanRead,
                  merchantId: amount.id,
                  amount: amount.amount,
                  publicAmount: amount.publicAmount,
                ),
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  bool _isVoucherRecords(String label) =>
      widget.system == BusinessSystem.cashier &&
      label == '当日卡券核销记录表' &&
      widget.onLoadVouchers != null &&
      widget.onCancelVoucher != null &&
      widget.onExportVouchers != null;

  Future<void> _openVoucherRecords() async {
    if (_reportOpen || !mounted || !_isVoucherRecords('当日卡券核销记录表')) return;
    _reportOpen = true;
    _updateReportAccess();
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (_) => CashierVoucherRecordsScreen(
            canOperate: _reportCanRead,
            load: widget.onLoadVouchers!,
            cancel: widget.onCancelVoucher!,
            export: widget.onExportVouchers!,
          ),
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openProfitLoss() async {
    if (_reportOpen || !mounted || !_isProfitLoss('盘盈盘亏')) return;
    _reportOpen = true;
    _updateReportAccess();
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (_) => CashierProfitLossScreen(
            catalog: _profitCatalog,
            canOperate: _reportCanRead,
            load: widget.onLoadProfitLoss!,
            submit: widget.onSubmitProfitLoss!,
          ),
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  bool _isOpenCardReport(String label) =>
      _isBooking && label == '开台记录' && widget.onLoadSeatOpenLog != null;

  bool _isTurnOverReport(String label) =>
      _isBooking && label == '转台记录' && widget.onLoadSeatChangeLog != null;

  bool _isReservedRecordReport(String label) =>
      _isBooking && label == '预留记录' && widget.onLoadBookList != null;

  bool _isOnlineBookingReport(String label) =>
      _isBooking && label == '线上预订记录' && widget.onLoadOnlineBookList != null;

  bool _isSeatOpeningReport(String label) =>
      _isBooking && label == '入客数据实时汇总' && widget.onLoadSeatOpening != null;

  bool _isDeptRegionReport(String label) =>
      _isBooking &&
      label == '部门实时订台/区域开台' &&
      widget.onLoadDeptRegionSeatOpen != null;

  bool _isQueueDetails(String label) => _isBooking && label == '排队详情';

  bool get _isVipRecharge =>
      _isOrder &&
      widget.onSearchVipCards != null &&
      widget.onLoadVipMember != null &&
      widget.onLoadVipRules != null &&
      widget.onCreateVipOrder != null &&
      widget.onCreateVipPay != null;

  bool _isWiredReport(String label) =>
      widget.system == BusinessSystem.cashier ||
      _isMinimumReport(label) ||
      _isCocktailReport(label) ||
      _isSoldOutProducts(label) ||
      _isOpenCardReport(label) ||
      _isTurnOverReport(label) ||
      _isReservedRecordReport(label) ||
      _isOnlineBookingReport(label) ||
      _isSeatOpeningReport(label) ||
      _isDeptRegionReport(label) ||
      _isQueueDetails(label);

  Future<void> _openMinimumReport() async {
    if (_reportOpen || !mounted) return;
    final load = widget.onLoadMinimumConsumption;
    if (load == null) return;
    _reportOpen = true;
    _updateReportAccess();
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (_) => MinimumConsumptionReportScreen(
            load: load,
            canRead: _reportCanRead,
          ),
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openCocktailReport() async {
    if (_reportOpen || !mounted) return;
    final load = widget.onLoadCocktailDetail;
    if (load == null) return;
    _reportOpen = true;
    _updateReportAccess();
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (_) =>
              CocktailDetailReportScreen(load: load, canRead: _reportCanRead),
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openSoldOutProducts() async {
    if (_reportOpen || !mounted) return;
    final list = widget.onListSoldOutProducts;
    final set = widget.onSetSoldOutProduct;
    final delete = widget.onDeleteSoldOutProduct;
    if (list == null || set == null || delete == null) return;
    _reportOpen = true;
    _updateReportAccess();
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (_) => SoldOutProductsScreen(
            catalog: _store.soldOutCatalog,
            list: list,
            set: set,
            delete: delete,
            canRead: _soldOutCanMaintain,
          ),
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openBookingSidePanel(Widget child) async {
    final tier = BookingViewportTier.of(context);
    if (tier.isPhone) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (_) => child,
        ),
      );
      return;
    }
    await showBookingDrawer<void>(
      context: context,
      desktopWidth: 980,
      tabletWidthFactor: 0.90,
      routeSettings: const RouteSettings(
        name: BusinessRouteObserver.childRouteName,
      ),
      builder: (_) => child,
    );
  }

  Future<void> _openSeatOpenLog() async {
    if (_reportOpen || !mounted) return;
    final load = widget.onLoadSeatOpenLog;
    if (load == null) return;
    _reportOpen = true;
    _updateReportAccess();
    try {
      await _openBookingSidePanel(
        SeatOpenLogScreen(
          load: load,
          onExport: widget.onExportSeatOpenLog,
          canRead: _reportCanRead,
          departments: _snapshot?.departments ?? const [],
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openSeatChangeLog() async {
    if (_reportOpen || !mounted) return;
    final load = widget.onLoadSeatChangeLog;
    if (load == null) return;
    _reportOpen = true;
    _updateReportAccess();
    try {
      await _openBookingSidePanel(
        SeatChangeLogScreen(load: load, canRead: _reportCanRead),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openBookList() async {
    if (_reportOpen || !mounted) return;
    final load = widget.onLoadBookList;
    if (load == null) return;
    _reportOpen = true;
    _updateReportAccess();
    try {
      await _openBookingSidePanel(
        BookListScreen(
          load: load,
          onExport: widget.onExportBookList,
          canRead: _reportCanRead,
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openOnlineBookList() async {
    if (_reportOpen || !mounted) return;
    final load = widget.onLoadOnlineBookList;
    if (load == null) return;
    _reportOpen = true;
    _updateReportAccess();
    try {
      await _openBookingSidePanel(
        OnlineBookListScreen(
          load: load,
          onExport: widget.onExportOnlineBookList,
          canRead: _reportCanRead,
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openSeatOpening() async {
    if (_reportOpen || !mounted) return;
    final load = widget.onLoadSeatOpening;
    if (load == null) return;
    _reportOpen = true;
    _updateReportAccess();
    try {
      await _openBookingSidePanel(
        SeatOpeningScreen(
          load: load,
          onExport: widget.onExportSeatOpening,
          canRead: _reportCanRead,
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openDeptRegionSeatOpen() async {
    if (_reportOpen || !mounted) return;
    final load = widget.onLoadDeptRegionSeatOpen;
    if (load == null) return;
    _reportOpen = true;
    _updateReportAccess();
    try {
      await _openBookingSidePanel(
        DeptRegionSeatOpenScreen(
          load: load,
          onExport: widget.onExportDeptRegionSeatOpen,
          canRead: _reportCanRead,
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openQueueDetails() async {
    if (_reportOpen || !mounted) return;
    _reportOpen = true;
    try {
      final queue = _snapshot?.queue ?? const CardTableQueueSnapshot();
      await _openBookingSidePanel(
        BookingQueueScreen(
          queue: queue,
          onCall: widget.onQueueCall,
          onArrive: widget.onQueueArrive,
          onExpired: widget.onQueueExpired,
          onExport: widget.onExportQueueList,
          onRefresh: widget.onRefresh != null
              ? () async {
                  await _runSessionAction(widget.onRefresh!);
                }
              : null,
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openBusinessDayClose({required bool automatic}) async {
    if (_reportOpen || !mounted) return;
    if ((_livePhase ?? widget.connectionPhase) != ConnectionPhase.online ||
        _snapshot == null ||
        _failure != null ||
        (_snapshot?.safeModeEnabled ?? true) ||
        (!automatic && !_snapshot!.businessOpen))
      return;
    final access = ValueNotifier<bool>(true);
    _businessDayAccess = access;
    _openedBusinessDay = _snapshot!.businessDayId;
    final owner = _businessDayOwner;
    final logout = widget.onLogout;
    _reportOpen = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (_) => BusinessDayCloseScreen(
            automatic: automatic,
            canOperate: access,
            onClosed: () async {
              if (mounted && owner == _businessDayOwner && logout != null) {
                await _runSessionAction(logout);
              }
            },
            closeDay: widget.onCloseBusinessDay,
            printShift: widget.onPrintShiftBill,
            loadAutoClose: widget.onLoadAutoClose,
            saveAutoClose: widget.onSaveAutoClose,
          ),
        ),
      );
    } finally {
      if (identical(_businessDayAccess, access)) _businessDayAccess = null;
      access.dispose();
      _reportOpen = false;
    }
  }

  Future<void> _openCashierReport(String label) async {
    if (_reportOpen || !mounted) return;
    _updateReportAccess();
    _reportOpen = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (_) => CashierReportScreen(
            title: label,
            onLoadData: widget.onLoadCashierReport,
            canRead: _reportCanRead,
            onLoadPage: widget.onLoadCashierReportPage,
            onLoadOptions: _cashierReportOptions,
            onExportData: widget.onExportCashierReport,
            onPrintData: widget.onPrintCashierReport,
            onPrintQuery: widget.onPrintCashierReportQuery,
            onFindPaymentCustomer: widget.onFindCashierPaymentCustomer,
            onChangePaymentCustomer: widget.onChangeCashierPaymentCustomer,
            canModifyPayment: _paymentCanModify,
          ),
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  void _openObjectionDrawer() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '异议单',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: CashierObjectionDrawer(
            onLoadList:
                widget.onLoadObjectionList ??
                () async => const Success(CashierObjectionData()),
            onExecuteCommand:
                widget.onExecuteObjectionCommand ??
                (id, cmd) async => const Success(null),
            onClose: () => _closeBusinessRoute(ctx),
          ),
        ),
      ),
      transitionBuilder: (ctx, anim1, anim2, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }

  void _openLateManagementDrawer() {
    if (widget.onOpenLateManagement != null) {
      widget.onOpenLateManagement!();
      return;
    }
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('滞留金管理'),
          content: const Text('滞留金管理抽屉已就绪，支持查询、补录、退还与跨台转移。'),
          actions: [
            FilledButton(
              onPressed: () => _closeBusinessRoute(ctx),
              child: const Text('知道了'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openVipRecharge() async {
    if (_reportOpen || !mounted || !_isVipRecharge) return;
    _reportOpen = true;
    _updateReportAccess();
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (_) => VipRechargeScreen(
            canRead: _reportCanRead,
            search: widget.onSearchVipCards!,
            detail: widget.onLoadVipMember!,
            rules: widget.onLoadVipRules!,
            lastSales: widget.onLoadVipLastSales,
            pollStatus: widget.onPollVipOrderStatus,
            createOrder: widget.onCreateVipOrder!,
            createPay: widget.onCreateVipPay!,
            employees: _store.employees,
          ),
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openChangePassword() async {
    if (_reportOpen || !mounted) return;
    final submit = widget.onChangePassword;
    if (submit == null) {
      await _pendingFeature('修改密码');
      return;
    }
    _reportOpen = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (_) => ChangePasswordScreen(
            submit: submit,
            darkTheme: _isBooking,
            onChanged: widget.onLogout == null
                ? null
                : () => unawaited(_runSessionAction(widget.onLogout!)),
          ),
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openAuthPassword() async {
    if (_reportOpen || !mounted) return;
    final loadEnabled = widget.onLoadAuthPasswordEnabled;
    final submit = widget.onChangeAuthPassword;
    if (loadEnabled == null || submit == null) {
      await _pendingFeature('授权密码');
      return;
    }
    _reportOpen = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (_) =>
              AuthPasswordScreen(loadEnabled: loadEnabled, submit: submit),
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openVipSystem() async {
    if (_reportOpen || !mounted) return;
    final list = widget.onListVipCards;
    if (list == null) {
      if (widget.onOpenVipSystem != null) {
        widget.onOpenVipSystem!();
        return;
      }
      await _pendingFeature('会员系统');
      return;
    }
    _reportOpen = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (routeContext) => VipNavScreen(
            onBack: () => _closeBusinessRoute(routeContext),
            listCards: list,
            newCardParams: widget.onVipNewCardParams,
            createCard: widget.onCreateVipCard,
            phoneCards: widget.onVipPhoneCards,
            makeCardBegin: widget.onVipMakeCardBegin,
            makeCardEnd: widget.onVipMakeCardEnd,
            sendSms: widget.onVipSendSms,
            pages: widget.vipPages ?? const VipPages(),
          ),
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openPayOrder(CardTable table) async {
    if (_reportOpen || !mounted) return;
    final load = widget.onLoadPayOrders;
    if (load == null) {
      if (widget.onOpenPayOrder != null) {
        widget.onOpenPayOrder!(table);
        return;
      }
      await _pendingFeature('消费明细与收款', table: table);
      return;
    }
    CardTable? nextOrderTable;
    final openedBusinessDay = _store.currentSnapshot?.businessDayId;
    CardTable? currentOrderTable() {
      final snapshot = _store.currentSnapshot;
      final current = snapshot?.tables
          .where((item) => item.id == table.id)
          .firstOrNull;
      if (!mounted ||
          _fcAwaitingFull ||
          _refundNeedsFull ||
          (_livePhase ?? widget.connectionPhase) != ConnectionPhase.online ||
          snapshot == null ||
          !snapshot.businessOpen ||
          snapshot.businessDayId != openedBusinessDay ||
          current == null ||
          current.turnoverCount != table.turnoverCount ||
          !const [4, 5, 6, 7].contains(current.businessStatus)) {
        return null;
      }
      return current;
    }

    final operationScope = _createOrderOperationScope(table);
    _reportOpen = true;
    _refundSeatId = table.id;
    _refundOpenedScope = _store.currentSnapshot == null
        ? null
        : _refundTableScope(_store.currentSnapshot!, table);
    _publishRefundContext();
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (routeContext) => PayOrderScreen(
            operationContext: operationScope.context,
            currentTableRevision: operationScope.currentTableRevision,
            table: table,
            loadOrders: load,
            moveOrder: widget.onMovePayOrder,
            movePayedOrder: widget.onMovePaidPayOrder,
            paidTransfersNeedingVerification: widget.paidTransfersNeedingVerification,
            verifyPaidTransfer: widget.onVerifyPaidTransfer,
            batchUpdateOrderWaiter: widget.onBatchUpdateOrderWaiter,
            batchUpdateOrderAuther: widget.onBatchUpdateOrderAuther,
            employees: () => _store.currentSnapshot?.employees ?? const [],
            tables: () => _store.currentSnapshot?.tables ?? const [],
            refundPayed: widget.system == BusinessSystem.cashier
                ? widget.onRefundPaidOrder
                : null,
            refundContext: _refundContext,
            productTypeFor: _store.productTypeFor,
            productNameFor: _store.productNameFor,
            refundReasons: _store.refundReasons,
            loadCart: widget.onPayCartItems,
            addChannel: widget.onAddPayChannel,
            deleteChannel: widget.onDeletePayChannel,
            payOrder: widget.onSubmitPayOrder,
            cleanSeat: widget.onPayCleanSeat,
            setSettleMode: widget.onPaySettleMode,
            printBill: widget.onPayPrintBill,
            addAuthChannel: widget.onPayAuthChannel,
            addLateChannel: widget.onPayLateChannel,
            addMemberCardChannel: widget.onPayMemberChannel,
            addPrepayChannel: widget.onPayPrepayChannel,
            onOpenOrderMeal: widget.onAddOrderProduct == null
                ? null
                : () {
                    if (!mounted ||
                        !routeContext.mounted ||
                        ModalRoute.of(routeContext)?.isCurrent != true) {
                      return;
                    }
                    final current = currentOrderTable();
                    if (current == null) {
                      ScaffoldMessenger.of(routeContext).showSnackBar(
                        const SnackBar(content: Text('卡台状态已变化，请返回卡台列表重新打开')),
                      );
                      return;
                    }
                    nextOrderTable = current;
                    _closeBusinessRoute(routeContext);
                  },
          ),
        ),
      );
    } finally {
      _reportOpen = false;
      _refundSeatId = null;
      _refundOpenedScope = null;
      if (mounted) _refundContext.value = null;
      _orderOperationScopes.remove(operationScope);
      unawaited(operationScope.dispose());
    }
    if (mounted && nextOrderTable != null) {
      final current = currentOrderTable();
      if (current != null) {
        await _openOrderMeal(current);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('卡台状态已变化，请返回卡台列表重新打开')));
      }
    }
  }

  Future<void> _openWine(String label, CardTable table) async {
    if (_reportOpen || !mounted) return;
    final action = switch (label) {
      '取酒' => WineOrderAction.take,
      '充公' => WineOrderAction.confiscate,
      _ => WineOrderAction.save,
    };
    if (action == WineOrderAction.save && widget.onSubmitSaveWine == null) {
      await _pendingFeature(label, table: table);
      return;
    }
    if (action == WineOrderAction.take && widget.onSubmitTakeWine == null) {
      await _pendingFeature(label, table: table);
      return;
    }
    if (action == WineOrderAction.confiscate &&
        widget.onSubmitConfiscateWine == null) {
      await _pendingFeature(label, table: table);
      return;
    }
    _reportOpen = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (_) => WineOrderScreen(
            table: table,
            action: action,
            listCsms: widget.onListWineCsms,
            submitSave: widget.onSubmitSaveWine,
            submitTake: widget.onSubmitTakeWine,
            submitConfiscate: widget.onSubmitConfiscateWine,
          ),
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Future<void> _openOrderMeal(CardTable table) async {
    if (_reportOpen || !mounted) return;
    final add = widget.onAddOrderProduct;
    if (add == null) {
      await _pendingFeature('点单', table: table);
      return;
    }
    final operationScope = _createOrderOperationScope(table, orderEntry: true);
    _reportOpen = true;
    _amountSeatId = table.id;
    _amountTurnover = table.turnoverCount;
    _amountDayId = _store.currentSnapshot?.businessDayId;
    _publishLiveTableAmounts();
    _footerSeatId = table.id;
    _footerScope = null;
    _publishFooterAccess();
    _refundSeatId = table.id;
    _refundOpenedScope = _store.currentSnapshot == null
        ? null
        : _refundTableScope(_store.currentSnapshot!, table);
    _publishRefundContext();
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: BusinessRouteObserver.childRouteName,
          ),
          fullscreenDialog: true,
          builder: (_) => OrderMealScreen(
            operationContext: operationScope.context,
            table: table,
            catalog: _store.catalogForRegion(table.regionId),
            liveTableAmounts: _liveTableAmounts,
            productPricingChanges: _productPricingChanges,
            productQuoteFor: (id) => _liveTableAmounts.value == null
                ? null
                : _store.productQuoteFor(table.id, id),
            fcPrices: _fcPrices,
            orderSummaryVisibility: _orderSummaryVisible,
            footerAmountsVisibility: _footerAmountsVisible,
            refundContext: _refundContext,
            productTypeFor: _store.productTypeFor,
            isCashier: widget.system == BusinessSystem.cashier,
            addProduct: add,
            loadCartCount: widget.onOrderCartCount,
            loadCartItems: widget.onOrderCartItems,
            setCartCount: widget.onSetOrderCartCount,
            bindGuestEnabled: _snapshot?.bindGuestEnabled ?? false,
            salesLabel: OrderCardDisplay.salesLabel(
              table: table,
              employees: _snapshot?.employees ?? const [],
              departments: _snapshot?.departments ?? const [],
            ).replaceFirst('散客', '').trim(),
            userName: widget.userName,
            employeeId: widget.employeeId,
            moduleIds: _pageModules(_snapshot),
            currentModuleIds: () => _pageModules(_store.currentSnapshot),
            bindWaiter: widget.onBindOrderWaiter,
            searchGuests: widget.onSearchOrderGuests,
            bindGuest: widget.onBindOrderGuest,
            loadOrders: widget.onLoadOrderItems,
            loadOrderDetails: widget.onLoadOrderDetails,
            placeOrder: widget.onPlaceOrder,
            addTimed: widget.onAddTimedProduct,
            addSet: widget.onAddSet,
            setDetails: _store.setDetails,
            currentSetCatalog: () => _store.orderSetCatalog,
            refundOrder: widget.onRefundOrder,
            refundReasons: _store.refundReasons,
            convertCartToYh: widget.onConvertCartToYh,
            yhReasons: _store.yhReasons,
            addYh: widget.onAddYh,
            addYh2: widget.onAddYh2,
            addRequirement: widget.onAddRequirement,
            changeSetDetail: widget.onChangeSetDetail,
            convertCartToYh2: widget.onConvertCartToYh2,
            giftOrdered: widget.onGiftOrdered,
            changeOrderedSet: widget.onChangeOrderedSet,
            convertOrderToYh2: widget.onConvertOrderToYh2,
            reprintKitchen: widget.onReprintKitchen,
            printBill: widget.onPrintBill,
            cleanSeat: widget.onCleanSeat,
            mergeYh2: widget.onMergeYh2,
            waiterTodoOrders: widget.onWaiterTodoOrders,
            createWaiterPay: widget.onCreateWaiterPay,
            redeemCoupon: widget.onRedeemCoupon,
            onOpenVipRecharge: widget.onSearchVipCards != null &&
                    widget.onLoadVipMember != null &&
                    widget.onCreateVipOrder != null &&
                    widget.onCreateVipPay != null
                ? () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(
                          name: BusinessRouteObserver.childRouteName,
                        ),
                        fullscreenDialog: true,
                        builder: (_) => VipRechargeScreen(
                          canRead: _reportCanRead,
                          search: widget.onSearchVipCards!,
                          detail: widget.onLoadVipMember!,
                          rules: widget.onLoadVipRules ??
                              (id) async => const Success([]),
                          lastSales: widget.onLoadVipLastSales,
                          pollStatus: widget.onPollVipOrderStatus,
                          createOrder: widget.onCreateVipOrder!,
                          createPay: widget.onCreateVipPay!,
                          employees: _store.employees,
                        ),
                      ),
                    )
                : null,
            onOpenLateDeposit: widget.orderLateDepositLoader != null
                ? () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(
                          name: BusinessRouteObserver.childRouteName,
                        ),
                        fullscreenDialog: true,
                        builder: (_) => OrderLateDepositScreen(
                          seatId: table.id,
                          loader: widget.orderLateDepositLoader!,
                          canOperate: _reportCanRead,
                        ),
                      ),
                    )
                : null,
            onTransferSeat: () async {
              final snapshot = _store.currentSnapshot;
              if (snapshot == null) return;
              final fields = await _promptTransferForm(
                table: table,
                snapshot: snapshot,
              );
              if (fields == null || !mounted) return;
              final submit = widget.onBookingCardWrite;
              if (submit == null) {
                _showSnack('转台尚未接入');
                return;
              }
              final result = await submit(
                action: BookingCardWriteAction.transferOpen,
                seatId: table.id,
                bookId: table.bookId,
                fields: fields,
                canDispatch: () => mounted && _reportCanRead.value,
              );
              if (!mounted) return;
              if (result.failureOrNull != null) {
                _showSnack(result.failureOrNull!.safeMessage);
                return;
              }
              _showSnack('转台成功');
              final refresh = widget.onRefresh;
              if (refresh != null) unawaited(_runSessionAction(refresh));
              Navigator.of(context).pop();
            },
            loadRemaining: widget.onListSoldOutProducts == null
                ? null
                : () async {
                    final result = await widget.onListSoldOutProducts!();
                    if (result.failureOrNull != null) {
                      return FailureResult(result.failureOrNull!);
                    }
                    return Success({
                      for (final item
                          in result.valueOrNull ?? const <SoldOutItem>[])
                        if (int.tryParse(item.remaining) != null)
                          item.id: int.parse(item.remaining),
                    });
                  },
          ),
        ),
      );
    } finally {
      _reportOpen = false;
      _footerRequest++;
      _footerSeatId = null;
      _footerScope = null;
      if (mounted) _footerAmountsVisible.value = false;
      _orderOperationScopes.remove(operationScope);
      unawaited(operationScope.dispose());
      _refundSeatId = null;
      _refundOpenedScope = null;
      if (mounted) _refundContext.value = null;
      _amountSeatId = null;
      _amountTurnover = null;
      _amountDayId = null;
      if (mounted) _liveTableAmounts.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      key: ValueKey<String>('${widget.system.label} · 卡台列表'),
      backgroundColor: _isOrder
          ? const Color(0xffDCE1EA)
          : const Color(0xff202C4A),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            if (widget.connectionPhase != ConnectionPhase.online)
              _connectionBanner(context),
            if (_sessionFailure case final failure?)
              ColoredBox(
                color: Theme.of(context).colorScheme.errorContainer,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      failure.safeMessage,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            if (snapshot == null) ...[
              Expanded(child: _waitingState(context)),
              Align(alignment: Alignment.centerRight, child: _accountMenu()),
            ] else ...<Widget>[
              if (widget.system == BusinessSystem.booking &&
                  snapshot.businessDates.isNotEmpty)
                _dateTabs(snapshot),
              _filters(snapshot),
              if (!snapshot.businessOpen) _closedBusinessDayBanner(context),
              Expanded(child: _tableGrid(snapshot)),
              _statusFooter(snapshot),
            ],
          ],
        ),
      ),
    );
  }

  bool get _isOrder => widget.system == BusinessSystem.order;
  bool get _padDevice =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isBooking => widget.system == BusinessSystem.booking;
  Color get _foreground => _isOrder ? const Color(0xff08080A) : Colors.white;
  Color get _toolbarBackground =>
      _isOrder ? const Color(0xffC4CBD7) : const Color(0xff222D47);

  Set<int> _pageModules(CardTableSnapshot? snapshot) =>
      snapshot?.pagePermissions?.available == true
      ? snapshot!.pagePermissions!.moduleIds
      : const <int>{};

  List<String> _moreLabels(CardTableSnapshot? snapshot) =>
      CardPageMenus.moreFor(
        widget.system,
        moduleIds: _pageModules(snapshot),
        safeModeEnabled: snapshot?.safeModeEnabled ?? true,
      );

  Widget _connectionBanner(BuildContext context) {
    final color = switch (widget.connectionPhase) {
      ConnectionPhase.online => Colors.green,
      ConnectionPhase.reconciling => Colors.orange,
      ConnectionPhase.blocked => Theme.of(context).colorScheme.error,
    };
    final label = switch (widget.connectionPhase) {
      ConnectionPhase.online => '服务端状态已同步',
      ConnectionPhase.reconciling => '正在同步卡台数据',
      ConnectionPhase.blocked => '网络不可用，业务操作已禁用',
    };
    return ColoredBox(
      color: color,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Future<void> _runSessionAction(CardTableSessionAction action) async {
    if (_sessionActionInProgress) return;
    setState(() {
      _sessionActionInProgress = true;
      _sessionFailure = null;
    });
    _updateReportAccess();
    Result<void> result;
    try {
      result = await action();
    } on Object {
      result = const FailureResult<void>(_sessionActionFailure);
    }
    if (!mounted) return;
    setState(() {
      _sessionActionInProgress = false;
      _sessionFailure = result.failureOrNull;
    });
    _updateReportAccess();
  }

  Widget _closedBusinessDayBanner(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.tertiaryContainer,
    child: SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: <Widget>[
            const Expanded(child: Text('营业日未开启')),
            if (_businessDayFailure case final failure?)
              Expanded(child: Text(failure.safeMessage))
            else if (_businessDayMessage case final message?)
              Expanded(child: Text(message)),
            if (widget.system == BusinessSystem.booking &&
                widget.onOpenBusinessDay != null)
              FilledButton(
                key: CardTableScreen.openBusinessDayKey,
                onPressed:
                    widget.connectionPhase.allowsWrites && !_businessDayOpening
                    ? _confirmOpenBusinessDay
                    : null,
                child: Text(_businessDayOpening ? '开启中…' : '开启营业日'),
              )
            else
              const Text('卡台仅供查看'),
          ],
        ),
      ),
    ),
  );

  Future<void> _confirmOpenBusinessDay() async {
    final confirmed = _isBooking
        ? await showBookingConfirmDialog(
            context: context,
            title: '开启营业日',
            message: '是否确认开启营业日？',
          )
        : await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('开启营业日'),
              content: const Text('是否确认开启营业日？'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => _closeBusinessRoute(context, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => _closeBusinessRoute(context, true),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
    if (confirmed != true || !mounted) return;
    setState(() {
      _businessDayOpening = true;
      _businessDayFailure = null;
      _businessDayMessage = null;
    });
    Result<void> result;
    try {
      result = await widget.onOpenBusinessDay!();
    } on Object {
      result = const FailureResult<void>(_businessDayActionFailure);
    }
    if (!mounted) return;
    setState(() {
      _businessDayOpening = false;
      _businessDayFailure = result.failureOrNull;
      _businessDayMessage = result.failureOrNull == null
          ? '开启请求已提交，等待服务端同步'
          : null;
    });
  }

  Widget _waitingState(BuildContext context) {
    final failure = _failure ?? widget.lastFailure;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(failure?.safeMessage ?? '正在等待完整卡台数据'),
            if (widget.onRefresh != null) ...<Widget>[
              const SizedBox(height: 12),
              TextButton.icon(
                key: CardTableScreen.refreshKey,
                onPressed: _sessionActionInProgress
                    ? null
                    : () => _runSessionAction(widget.onRefresh!),
                icon: const Icon(Icons.refresh),
                label: const Text('重新同步'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dateTabs(CardTableSnapshot snapshot) => ColoredBox(
    color: BookingTokens.surfaceToolbar,
    child: SizedBox(
      width: double.infinity,
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        scrollDirection: Axis.horizontal,
        itemCount: snapshot.businessDates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = snapshot.businessDates[index];
          final selected = date.id == _businessDateId;
          return ChoiceChip(
            label: Text(date.label),
            selected: selected,
            showCheckmark: false,
            backgroundColor: BookingTokens.surfaceFooter,
            selectedColor: BookingTokens.surfaceIceWhite,
            side: BorderSide(
              color: selected
                  ? BookingTokens.surfaceIceAccent
                  : BookingTokens.dividerBlue,
            ),
            labelStyle: TextStyle(
              color: selected
                  ? BookingTokens.textOnIce
                  : BookingTokens.textPrimary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
            onSelected: (_) => setState(() {
              _businessDateId = date.id;
              _businessStatus = null;
              _searchController.clear();
            }),
          );
        },
      ),
    ),
  );

  void _selectRegion(CardRegionSelection selection) {
    setState(() {
      _mineOnly = selection.kind == CardRegionSelectionKind.mine;
      _regionId = selection.regionId;
      _businessStatus = null;
      _searchController.clear();
    });
    if (_gridController.hasClients) _gridController.jumpTo(0);
  }

  List<CardRegion> _visibleRegions(CardTableSnapshot? snapshot) =>
      snapshot == null
      ? const []
      : snapshot.regions
            .where(
              (region) =>
                  !snapshot.safeModeEnabled || !region.name.contains('特饮'),
            )
            .toList(growable: false);

  Widget _filters(CardTableSnapshot snapshot) => ColoredBox(
    color: _toolbarBackground,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inlineSearch = _isBooking && constraints.maxWidth >= 900;
          final searchField = SizedBox(
            height: 38,
            width: inlineSearch ? 280 : null,
            child: TextField(
              key: CardTableScreen.searchKey,
              controller: _searchController,
              style: TextStyle(color: _foreground, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                filled: _isBooking,
                fillColor: _isBooking ? BookingTokens.surfaceInput : null,
                hintText: widget.showCustomerDetails
                    ? widget.system == BusinessSystem.booking
                          ? '卡台/客人/拼音/手机/订位人/部门'
                          : '卡台名称/客人姓名/手机尾号后四位'
                    : widget.system == BusinessSystem.booking
                    ? '卡台名称/订位人/工号/部门'
                    : '卡台名称',
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white70,
                  size: 18,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        tooltip: '清除搜索',
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white60,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => setState(() {
                _regionId = null;
                _businessStatus = null;
              }),
            ),
          );
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: CardRegionSelector(
                      regions: _visibleRegions(snapshot),
                      selectedRegionId: _regionId,
                      mineSelected: _mineOnly,
                      showMine: _isOrder,
                      lightTheme: _isOrder,
                      onSelected: _selectRegion,
                    ),
                  ),
                  if (inlineSearch) ...[
                    const SizedBox(width: 8),
                    searchField,
                  ],
                  IconButton(
                    tooltip: '向下翻页',
                    onPressed: () => _scrollCards(1),
                    icon: Icon(Icons.keyboard_arrow_down, color: _foreground),
                  ),
                  IconButton(
                    tooltip: '向上翻页',
                    onPressed: () => _scrollCards(-1),
                    icon: Icon(Icons.keyboard_arrow_up, color: _foreground),
                  ),
                ],
              ),
              if (!_isOrder && !inlineSearch) ...[
                const SizedBox(height: 6),
                searchField,
              ],
            ],
          );
        },
      ),
    ),
  );

  void _scrollCards(int direction) {
    if (!_gridController.hasClients) return;
    final position = _gridController.position;
    unawaited(
      _gridController.animateTo(
        (position.pixels + direction * position.viewportDimension * .8)
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble(),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      ),
    );
  }

  Iterable<CardTable> _scopeTables(CardTableSnapshot snapshot) =>
      snapshot.tablesForDate(_businessDateId).where((table) {
        if (snapshot.safeModeEnabled &&
            (table.businessType == 3 || table.businessType == 4)) {
          return false;
        }
        if (_isOrder &&
            _mineOnly &&
            !table.belongsToEmployee(widget.employeeId)) {
          return false;
        }
        return _regionId == null || table.regionId == _regionId;
      });

  Widget _tableGrid(CardTableSnapshot snapshot) {
    final keyword = _searchController.text.trim().toLowerCase();
    final tables = _scopeTables(snapshot)
        .where((table) {
          if (_businessStatus != null &&
              !_matchesStatusFilter(table.businessStatus, _businessStatus!)) {
            return false;
          }
          if (keyword.isEmpty) return true;
          if (_isBooking) {
            return BookingCardDisplay.matchesBookingSearch(
              table: table,
              keyword: keyword,
              employees: snapshot.employees,
              departments: snapshot.departments,
              showCustomerDetails: widget.showCustomerDetails,
            );
          }
          return table.name.toLowerCase().contains(keyword) ||
              (widget.showCustomerDetails &&
                  table.customerName.toLowerCase().contains(keyword));
        })
        .toList(growable: false);
    if (tables.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.table_restaurant_outlined,
                size: 48,
                color: _foreground.withValues(alpha: .3),
              ),
              const SizedBox(height: 16),
              Text(
                _isOrder && _mineOnly
                    ? '暂无服务过的卡台，快去点单吧！'
                    : _isOrder
                    ? '暂无卡台数据'
                    : '没有符合条件的卡台',
                style: TextStyle(color: _foreground),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    final names = {for (final r in snapshot.regions) r.id: r.name};
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = BookingViewportTier.fromWidth(
          constraints.maxWidth,
        ).isPhone;
        final columns = (constraints.maxWidth /
                (_isOrder ? 220 : (_isBooking && isPhone ? 168 : 178)))
            .floor()
            .clamp(2, 12);
        return GridView.builder(
          key: CardTableScreen.gridKey,
          controller: _gridController,
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: _wineMode
                ? 1.08
                : (_isOrder
                      ? 1.05
                      : (_isBooking ? (isPhone ? 0.90 : 0.96) : 1.2)),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            final table = tables[index];
            return Card(
              color: _cardColor(table.businessStatus),
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
                side: BorderSide(
                  color: _isOrder ? const Color(0xff9FA8BC) : Colors.white24,
                ),
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: _foreground),
                child: Builder(
                  builder: (cardContext) => InkWell(
                    key: CardTableScreen.cardKey(table.id),
                    onTap: () => _onCardTap(snapshot, table, cardContext),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _isBooking
                                    ? _bookingRegionLabel(
                                        names[table.regionId] ?? '未知区域',
                                        table,
                                      )
                                    : Text(
                                        names[table.regionId] ?? '未知区域',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                              ),
                              if (_isBooking)
                                ..._bookingHeaderTrailing(table)
                              else if (!_isOrder)
                                Text(
                                  '${table.capacity > 0 ? table.capacity : 1}人',
                                )
                              else if (!_wineMode) ...[
                                if (table.mark.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xffF1FF00),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        table.mark,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xff08080A),
                                        ),
                                      ),
                                    ),
                                  ),
                                Text(
                                  OrderCardDisplay.openTimeLabel(
                                    table.openTime,
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (!_isBooking)
                            Text(
                              table.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                height: 1.1,
                                color: _foreground,
                              ),
                            ),
                          if (_isBooking)
                            ..._bookingCardBody(snapshot, table)
                          else if (_isOrder && _wineMode)
                            Wrap(
                              spacing: 4,
                              children: [
                                if ([
                                      4,
                                      5,
                                      6,
                                      7,
                                    ].contains(table.businessStatus) ||
                                    table.turnoverCount > 0)
                                  _wineAction('存酒', table),
                                if ([4, 5, 6, 7].contains(table.businessStatus))
                                  _wineAction('取酒', table),
                                _wineAction('充公', table),
                              ],
                            )
                          else if (_isOrder)
                            ..._orderCardBody(snapshot, table)
                          else ...[
                            const Spacer(),
                            Text(_statusLabel(table.businessStatus)),
                            if (widget.showCustomerDetails &&
                                !snapshot.safeModeEnabled &&
                                table.customerName.isNotEmpty)
                              Text(
                                table.customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _orderCardBody(CardTableSnapshot snapshot, CardTable table) {
    final canLook = OrderCardDisplay.canLookOrder(
      table: table,
      permissions: snapshot.pagePermissions,
      employeeId: widget.employeeId,
      employees: snapshot.employees,
    );
    final showAmounts = OrderCardDisplay.showAmounts(
      table: table,
      wineMode: _wineMode,
      safeModeEnabled: snapshot.safeModeEnabled,
      canLook: canLook,
    );
    final showGift = OrderCardDisplay.showGiftAmount(
      showAmounts: showAmounts,
      permissions: snapshot.pagePermissions,
    );
    final lockTip = OrderCardDisplay.lockTip(table.businessStatus);
    final person = OrderCardDisplay.salesLabel(
      table: table,
      employees: snapshot.employees,
      departments: snapshot.departments,
    );
    final showTurnover = OrderCardDisplay.showTurnover(
      table: table,
      permissions: snapshot.pagePermissions,
    );
    return [
      const SizedBox(height: 6),
      SizedBox(
        height: 18,
        child: showAmounts
            ? Row(
                children: [
                  Expanded(
                    child: Text(
                      '点:￥${OrderCardDisplay.yuan(table.orderAmount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (table.minConsumeProgress.isNotEmpty)
                    Text(
                      table.minConsumeProgress,
                      style: const TextStyle(fontSize: 14),
                    ),
                ],
              )
            : const SizedBox.shrink(),
      ),
      SizedBox(
        height: 18,
        child: showGift
            ? Text(
                '惠:￥${OrderCardDisplay.yuan(table.giftAmount)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              )
            : const SizedBox.shrink(),
      ),
      const SizedBox(height: 4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: lockTip.isNotEmpty
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 14,
                      height: 14,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xffFFBD00),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        lockTip,
                        style: const TextStyle(fontSize: 10, height: 1),
                      ),
                    ),
                  )
                : Text(
                    person,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, height: 1.2),
                  ),
          ),
          if (showTurnover)
            Text(
              '翻${table.turnoverCount}',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
      if (table.remark.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            table.remark,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
    ];
  }

  Widget _bookingChip(
    String text, {
    required Color background,
    Color foreground = const Color(0xff08080A),
  }) => Container(
    height: 16,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        height: 1,
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _bookingRegionLabel(String region, CardTable table) => Row(
    children: [
      Flexible(
        child: Text(
          region,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: _foreground.withValues(alpha: .78),
          ),
        ),
      ),
      if (table.showOnlineText) ...[
        const SizedBox(width: 4),
        _bookingChip(
          '线',
          background: BookingTokens.badgeOnline,
        ),
      ],
      if (BookingCardDisplay.isPartialPaid(table.businessStatus)) ...[
        const SizedBox(width: 4),
        _bookingChip(
          '部分结',
          background: BookingTokens.warningAmber,
        ),
      ],
    ],
  );

  List<Widget> _bookingHeaderTrailing(CardTable table) {
    final openTime = BookingCardDisplay.openTime(table.openTime);
    return [
      if (table.mark.isNotEmpty) ...[
        _bookingChip(table.mark, background: const Color(0xffF1FF00)),
        const SizedBox(width: 4),
      ],
      if (openTime.isNotEmpty)
        Text(
          openTime,
          style: TextStyle(
            fontSize: 12,
            color: _foreground.withValues(alpha: .78),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      if (BookingCardDisplay.showsCapacity(table.businessStatus))
        Text(
          '${BookingCardDisplay.capacity(table)}人',
          style: TextStyle(
            fontSize: 12,
            color: _foreground.withValues(alpha: .78),
          ),
        ),
    ];
  }

  Widget _bookingAmount(String tag, num value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        tag,
        style: TextStyle(
          fontSize: 11,
          color: _foreground.withValues(alpha: .7),
        ),
      ),
      const SizedBox(width: 2),
      Text(
        '¥${OrderCardDisplay.yuan(value)}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );

  /// Booking card face, field for field with cardMachine.vue:84-205.
  /// Fixed-height rows keep every card in a row aligned.
  List<Widget> _bookingCardBody(CardTableSnapshot snapshot, CardTable table) {
    final status = table.businessStatus;
    final showAmounts =
        BookingCardDisplay.showsAmounts(status) &&
        !snapshot.safeModeEnabled &&
        snapshot.cardAmountsVisible;
    final progress = BookingCardDisplay.minConsumeProgress(table);
    final showGuest = BookingCardDisplay.showsGuest(status);
    final sales = showGuest
        ? OrderCardDisplay.salesLabel(
            table: table,
            employees: snapshot.employees,
            departments: snapshot.departments,
          )
        : '';
    final guest = showGuest && widget.showCustomerDetails
        ? BookingCardDisplay.guestLabel(table)
        : '';
    final lockTip = OrderCardDisplay.lockTip(status);
    final remark = BookingCardDisplay.shortRemark(table.remark);
    final transferText = BookingCardDisplay.formatTransferHistory(
      table.transferHistory,
    );
    final secondary = TextStyle(
      fontSize: 12,
      height: 1.2,
      color: _foreground.withValues(alpha: .86),
    );
    return [
      SizedBox(
        height: 30,
        child: Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  table.name,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: _foreground,
                  ),
                ),
              ),
            ),
            if (table.pinned)
              Tooltip(
                message: '已置顶',
                child: Icon(
                  Icons.push_pin,
                  size: 14,
                  color: _foreground.withValues(alpha: .8),
                ),
              ),
          ],
        ),
      ),
      SizedBox(
        height: 28,
        child: showAmounts
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _bookingAmount(
                                '主',
                                BookingCardDisplay.mainAmount(table),
                              ),
                              const SizedBox(width: 8),
                              _bookingAmount('惠', table.giftAmount),
                            ],
                          ),
                        ),
                      ),
                      if (progress != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          BookingCardDisplay.minConsumeLabel(table),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 3),
                    Tooltip(
                      message:
                          '低消进度 ${BookingCardDisplay.minConsumeLabel(table)}'
                          '（低消 ¥${OrderCardDisplay.yuan(table.assignedMinConsumeAmount)}）',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: _foreground.withValues(alpha: .2),
                          color: progress >= 1
                              ? BookingTokens.progressFull
                              : _foreground,
                        ),
                      ),
                    ),
                  ],
                ],
              )
            : null,
      ),
      SizedBox(
        height: 16,
        child: Text(
          sales,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: secondary,
        ),
      ),
      SizedBox(
        height: 16,
        child: Text(
          guest,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: secondary,
        ),
      ),
      if (transferText.isNotEmpty)
        SizedBox(
          height: 15,
          child: Tooltip(
            message: table.transferHistory,
            child: Text(
              '转台记录：$transferText',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.2,
                color: _foreground.withValues(alpha: .78),
              ),
            ),
          ),
        ),
      const Spacer(),
      SizedBox(
        height: 16,
        child: Row(
          children: [
            if (lockTip.isNotEmpty) ...[
              _bookingChip(lockTip, background: const Color(0xffFFBD00)),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                remark,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: _foreground.withValues(alpha: .7),
                ),
              ),
            ),
            if (table.turnoverCount > 0)
              Text(
                '翻${table.turnoverCount}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    ];
  }

  Widget _wineAction(String label, CardTable table) => InkWell(
    onTap: () => unawaited(_openWine(label, table)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    ),
  );

  void _onCardTap(
    CardTableSnapshot snapshot,
    CardTable table,
    BuildContext cardContext,
  ) {
    if (_isOrder) {
      if (_wineMode) return;
      if ([1, 2, 8].contains(table.businessStatus)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, 120),
            content: Text('空台/锁台/预定状态卡台不可点单！'),
          ),
        );
        return;
      }
      unawaited(_openOrderMeal(table));
      return;
    }
    if (widget.system == BusinessSystem.cashier) {
      if ([4, 5, 6, 7].contains(table.businessStatus)) {
        unawaited(_openPayOrder(table));
      } else if (table.businessStatus == 1 && table.turnoverCount > 0) {
        unawaited(_showCardMenu(snapshot, table, cardContext));
      }
      return;
    }
    if (_isBooking) {
      if (!snapshot.isRegionPermittedForSupervisor(table.regionId)) {
        _showSnack('您没有权限查看该区域的卡台！');
        return;
      }
      final isCurrentDate =
          _businessDateId == snapshot.businessDates.firstOrNull?.id;
      if (!isCurrentDate && table.businessStatus == 2) {
        _showSnack('未来日期无法解锁卡台！');
        return;
      }
      if (!isCurrentDate &&
          (table.businessStatus == 1 || table.businessStatus == 8) &&
          table.showOnlineText) {
        _showSnack('非营业日栏所在线上卡台，线下不可操作！');
        return;
      }
    }
    unawaited(_showCardMenu(snapshot, table, cardContext));
  }

  Future<void> _pendingFeature(
    String label, {
    CardTable? table,
  }) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(label),
      content: Text(
        '${table == null ? '' : '卡台：${table.name}\n'}该业务功能尚未接入 Flutter，当前仅恢复原系统入口。请继续使用原系统办理，本次不会提交业务数据。',
      ),
      actions: [
        TextButton(
          onPressed: () => _closeBusinessRoute(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );

  Color _cardColor(int status) {
    if (!_isOrder) return _statusColor(status);
    return switch (status) {
      3 || 8 => const Color(0xffA1E7C2),
      4 => const Color(0xffFFF6A5),
      5 => const Color(0xffF8A27A),
      6 || 7 => const Color(0xffBAB9F7),
      _ => const Color(0xffFAFAFC),
    };
  }

  Widget _statusFooter(CardTableSnapshot snapshot) {
    final scoped = _scopeTables(snapshot).toList(growable: false);
    final derived = <int, int>{};
    for (final table in scoped) {
      derived.update(table.businessStatus, (n) => n + 1, ifAbsent: () => 1);
    }
    final currentDate =
        _businessDateId == snapshot.businessDates.firstOrNull?.id;
    final counts = _isOrder && _mineOnly
        ? snapshot.personalStatusCounts(scoped)
        : currentDate
        ? snapshot.statusCountsForRegion(_regionId)
        : derived;
    int count(int key) => counts[key] ?? 0;
    final modules = _pageModules(snapshot);
    final more = CardPageMenus.moreFor(
      widget.system,
      moduleIds: modules,
      safeModeEnabled: snapshot.safeModeEnabled,
    );
    return ColoredBox(
      color: _isOrder ? const Color(0xffECEFF4) : const Color(0xff0D172D),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: _foreground),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screen = MediaQuery.sizeOf(context);
            final landscape = screen.width >= screen.height;
            final stackFooter = _isOrder
                ? !landscape && constraints.maxWidth < 850
                : constraints.maxWidth < 850;
            Widget legend({required bool expandItems}) {
              final items = [
                _legendItem('空台', count(1), 1),
                if (_isBooking) _legendItem('锁定', count(2), 2),
                _legendItem('预订', count(8), 8),
                _legendItem('开台', count(10), 4),
                _legendItem('点单', count(5) + count(6), 5),
                _legendItem('已结', count(7), 7),
                _legendItem('抵达数', count(20), 20),
                if (widget.onRefresh != null)
                  SizedBox(
                    width: 54,
                    child: TextButton(
                      key: CardTableScreen.refreshKey,
                      onPressed: _sessionActionInProgress
                          ? null
                          : () {
                              unawaited(_runSessionAction(widget.onRefresh!));
                              if (_isBooking &&
                                  widget.onLoadBookingDetailConfig != null) {
                                unawaited(_loadBookingDetailConfig());
                              }
                            },
                      style: TextButton.styleFrom(
                        foregroundColor: _foreground,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh),
                          Text('刷新', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ];
              return Row(
                mainAxisSize: expandItems ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  for (final item in items)
                    if (expandItems)
                      Expanded(child: item)
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: item,
                      ),
                ],
              );
            }

            final controls = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isOrder && modules.any([91, 92, 93].contains))
                  _footerAction(
                    '会员充值',
                    Icons.credit_card,
                    const Color(0xff2362D5),
                    _isVipRecharge
                        ? () => unawaited(_openVipRecharge())
                        : () => _pendingFeature('会员充值'),
                    key: CardTableScreen.vipRechargeKey,
                  ),
                if (_isOrder && modules.contains(1))
                  _footerAction(
                    _wineMode ? '点单模式' : '存酒模式',
                    Icons.swap_horiz,
                    const Color(0xff009370),
                    () => setState(() => _wineMode = !_wineMode),
                    key: CardTableScreen.wineModeKey,
                  ),
                if (widget.system == BusinessSystem.cashier &&
                    !snapshot.safeModeEnabled)
                  _footerAction(
                    '会员系统',
                    Icons.credit_card,
                    const Color(0xff2362D5),
                    () {
                      unawaited(_openVipSystem());
                    },
                  ),
                if (widget.system == BusinessSystem.cashier &&
                    !snapshot.safeModeEnabled &&
                    (_livePhase ?? widget.connectionPhase) ==
                        ConnectionPhase.online)
                  ValueListenableBuilder<List<CashierMerchantAmount>?>(
                    valueListenable: _merchantAmounts,
                    builder: (_, amounts, _) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final merchant
                            in amounts ?? const <CashierMerchantAmount>[])
                          Tooltip(
                            message: '商户号信息',
                            child: TextButton(
                              key: ValueKey(
                                'cashier-merchant-amount-${merchant.id}',
                              ),
                              onPressed:
                                  widget.createMerchantManagementLoader ==
                                          null ||
                                      _sessionActionInProgress
                                  ? null
                                  : () => unawaited(
                                      _openMerchantManagement(merchant),
                                    ),
                              child: Text(merchant.display),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (widget.system == BusinessSystem.cashier)
                  _footerAction(
                    '异议单列表',
                    Icons.receipt_long,
                    const Color(0xff263955),
                    _openObjectionDrawer,
                    key: CardTableScreen.objectionListKey,
                  ),
                if (widget.system == BusinessSystem.cashier)
                  _footerAction(
                    '滞留金管理',
                    Icons.account_balance_wallet_outlined,
                    const Color(0xff553366),
                    _openLateManagementDrawer,
                    key: CardTableScreen.lateManagementKey,
                  ),
                if (widget.system == BusinessSystem.booking &&
                    widget.onOpenReserved != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: BookingIceSwitchCard(
                      label: '预留信息',
                      icon: Icons.bookmark_border,
                      compact: true,
                      onTap: widget.onOpenReserved!,
                    ),
                  ),
                if (more.isNotEmpty) _moreMenu(more),
                _accountMenu(),
              ],
            );
            if (stackFooter) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 52, child: legend(expandItems: true)),
                  SizedBox(
                    height: 52,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: controls,
                      ),
                    ),
                  ),
                ],
              );
            }
            return SizedBox(
              height: 56,
              child: Row(
                children: [
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: legend(expandItems: false),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: controls,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _footerAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    Key? key,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: FilledButton.icon(
      key: key,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    ),
  );

  PopupMenuButton<String> _moreMenu(List<String> labels) =>
      PopupMenuButton<String>(
        key: CardTableScreen.moreFunctionsKey,
        tooltip: '更多功能',
        color: _isOrder ? const Color(0xffFAFAFC) : const Color(0xff0D172D),
        constraints: BoxConstraints(
          maxWidth: 320,
          maxHeight: MediaQuery.sizeOf(context).height * .7,
        ),
        onOpened: () => _moreMenuOpen = true,
        onCanceled: () => _moreMenuOpen = false,
        onSelected: (label) {
          _moreMenuOpen = false;
          unawaited(
            _isMinimumReport(label)
                ? _openMinimumReport()
                : _isCocktailReport(label)
                ? _openCocktailReport()
                : _isSoldOutProducts(label)
                ? _openSoldOutProducts()
                : _isProfitLoss(label)
                ? _openProfitLoss()
                : _isVoucherRecords(label)
                ? _openVoucherRecords()
                : _isCreditAccounts(label)
                ? _openCreditAccounts()
                : _isMerchantManagement(label)
                ? _openMerchantManagement()
                : _isOpenCardReport(label)
                ? _openSeatOpenLog()
                : _isTurnOverReport(label)
                ? _openSeatChangeLog()
                : _isReservedRecordReport(label)
                ? _openBookList()
                : _isOnlineBookingReport(label)
                ? _openOnlineBookList()
                : _isSeatOpeningReport(label)
                ? _openSeatOpening()
                : _isDeptRegionReport(label)
                ? _openDeptRegionSeatOpen()
                : _isQueueDetails(label)
                ? _openQueueDetails()
                : label == '结束营业日'
                ? _openBusinessDayClose(automatic: false)
                : label == '自动结束营业日'
                ? _openBusinessDayClose(automatic: true)
                : widget.system == BusinessSystem.cashier
                ? _openCashierReport(label)
                : _pendingFeature(label),
          );
        },
        itemBuilder: (_) => [
          for (final label in labels)
            PopupMenuItem<String>(
              value: label,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(color: _foreground, fontSize: 14),
                    ),
                  ),
                  if (!_isWiredReport(label)) ...[
                    const SizedBox(width: 8),
                    const Text(
                      '待接入',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, color: _foreground, size: 20),
              Text('更多功能', style: TextStyle(color: _foreground, fontSize: 12)),
            ],
          ),
        ),
      );

  PopupMenuButton<String> _accountMenu() => PopupMenuButton<String>(
    key: CardTableScreen.accountMenuKey,
    tooltip: '员工菜单',
    color: _isOrder ? const Color(0xffFAFAFC) : const Color(0xff0D172D),
    onSelected: (action) {
      switch (action) {
        case '退出登录':
          unawaited(_runSessionAction(widget.onLogout!));
        case '切换系统':
          unawaited(_runSessionAction(widget.onSwitchSystem!));
        case '设备诊断':
          widget.onOpenDiagnostics!();
        case '修改密码':
          unawaited(_openChangePassword());
        case '授权密码':
          unawaited(_openAuthPassword());
        default:
          unawaited(_pendingFeature(action));
      }
    },
    itemBuilder: (_) => [
      PopupMenuItem(
        value: '修改密码',
        child: Text('修改密码', style: TextStyle(color: _foreground)),
      ),
      if (widget.system != BusinessSystem.booking)
        PopupMenuItem(
          value: '授权密码',
          child: Text('授权密码', style: TextStyle(color: _foreground)),
        ),
      if (widget.onLogout != null)
        PopupMenuItem(
          key: CardTableScreen.logoutKey,
          value: '退出登录',
          enabled: !_sessionActionInProgress,
          child: Text('退出登录', style: TextStyle(color: _foreground)),
        ),
      if (widget.onSwitchSystem != null) ...[
        const PopupMenuDivider(),
        PopupMenuItem(
          key: CardTableScreen.switchSystemKey,
          value: '切换系统',
          enabled: !_sessionActionInProgress,
          child: Text('切换系统', style: TextStyle(color: _foreground)),
        ),
      ],
      if (widget.onOpenDiagnostics != null) ...[
        const PopupMenuDivider(),
        PopupMenuItem(
          key: CardTableScreen.openDiagnosticsKey,
          value: '设备诊断',
          child: Text('开发工具 · 设备诊断', style: TextStyle(color: _foreground)),
        ),
      ],
    ],
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, color: _foreground, size: 20),
          SizedBox(
            width: 76,
            child: Text(
              widget.userName ?? '账户',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: _foreground, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _showCardMenu(
    CardTableSnapshot snapshot,
    CardTable table,
    BuildContext cardContext,
  ) async {
    final actions = _cardActions(snapshot, table);
    if (actions.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('当前卡台没有可用操作')));
      return;
    }
    const menuColor = BookingTokens.menuText;
    final tier = BookingViewportTier.of(context);
    if (_isBooking && tier.isPhone) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: BookingTokens.surfaceDrawer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (sheetContext) => Material(
          key: CardTableScreen.cardMenuKey,
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${table.name} · ${_statusLabel(table.businessStatus)}',
                          style: const TextStyle(
                            color: BookingTokens.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _closeBusinessRoute(sheetContext),
                        child: const Text(
                          '关闭',
                          style: TextStyle(color: menuColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          for (final action in actions)
                            _buildPhoneMenuTile(
                              sheetContext,
                              action,
                              table,
                              snapshot,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    }
    final cardBox = cardContext.findRenderObject();
    if (cardBox is! RenderBox || !cardBox.hasSize) return;
    final overlay = Overlay.maybeOf(context)?.context.findRenderObject();
    final overlayBox = overlay is RenderBox ? overlay : null;
    final cardRect = Rect.fromPoints(
      cardBox.localToGlobal(Offset.zero, ancestor: overlayBox),
      cardBox.localToGlobal(
        cardBox.size.bottomRight(Offset.zero),
        ancestor: overlayBox,
      ),
    );
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭',
      barrierColor: const Color(0x00000000),
      transitionDuration: const Duration(milliseconds: 80),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final media = MediaQuery.of(dialogContext);
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                _closeBusinessRoute(dialogContext),
          },
          child: Focus(
            autofocus: true,
            child: CustomSingleChildLayout(
              delegate: _CardMenuLayoutDelegate(
                cardRect: cardRect,
                overlaySize: media.size,
                padding: media.padding,
              ),
              child: Material(
                key: CardTableScreen.cardMenuKey,
                color: BookingTokens.surfaceMenu,
                elevation: 8,
                shadowColor: BookingTokens.accentGlowShadow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: BookingTokens.accentGlowBorder),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 180,
                    maxWidth: 188,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (final action in actions)
                            _buildPopupMenuItem(
                              dialogContext,
                              action,
                              table,
                              snapshot,
                            ),
                          InkWell(
                            onTap: () => _closeBusinessRoute(dialogContext),
                            child: const Padding(
                              padding: EdgeInsets.only(top: 8, bottom: 4),
                              child: Text(
                                '关闭',
                                style: TextStyle(
                                  color: menuColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isActionDisabled(_CardMenuAction action, CardTable table) =>
      action.write == BookingCardWriteAction.disableMustOrder &&
      table.mustOrderDisabled;

  Widget _buildPopupMenuItem(
    BuildContext dialogContext,
    _CardMenuAction action,
    CardTable table,
    CardTableSnapshot snapshot,
  ) {
    const menuColor = BookingTokens.menuText;
    final disabled = _isActionDisabled(action, table);
    final row = InkWell(
      onTap: disabled
          ? null
          : () {
              _closeBusinessRoute(dialogContext);
              unawaited(_onBookingAction(action, table, snapshot));
            },
      child: Opacity(
        opacity: disabled ? 0.42 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                action.icon,
                size: 18,
                color: disabled ? BookingTokens.textMuted : menuColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  action.label,
                  style: TextStyle(
                    color: disabled ? BookingTokens.textMuted : menuColor,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
              ),
              if (disabled)
                const Text(
                  '不可用',
                  style: TextStyle(
                    color: BookingTokens.textMuted,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (!disabled) return row;
    return Tooltip(message: '当前区域无必点商品或已取消', child: row);
  }

  Widget _buildPhoneMenuTile(
    BuildContext sheetContext,
    _CardMenuAction action,
    CardTable table,
    CardTableSnapshot snapshot,
  ) {
    final disabled = _isActionDisabled(action, table);
    final width = (MediaQuery.sizeOf(sheetContext).width - 40) / 2;
    final tile = Opacity(
      opacity: disabled ? 0.42 : 1,
      child: Material(
        color: BookingTokens.surfaceFooter,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: disabled
              ? null
              : () {
                  _closeBusinessRoute(sheetContext);
                  unawaited(_onBookingAction(action, table, snapshot));
                },
          child: Container(
            width: width.clamp(120.0, 220.0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: disabled
                    ? BookingTokens.tableBorder
                    : const Color(0x5532B9FF),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  action.icon,
                  size: 18,
                  color: disabled
                      ? BookingTokens.textMuted
                      : BookingTokens.menuText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: disabled
                          ? BookingTokens.textMuted
                          : BookingTokens.menuText,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!disabled) return tile;
    return Tooltip(message: '当前区域无必点商品或已取消', child: tile);
  }

  List<_CardMenuAction> _cardActions(
    CardTableSnapshot snapshot,
    CardTable table,
  ) {
    final isCurrentDate =
        _businessDateId == snapshot.businessDates.firstOrNull?.id;
    final actions = switch (widget.system) {
      BusinessSystem.booking => _bookingCardActions(
        table,
        businessOpen: snapshot.businessOpen,
        isCurrentDate: isCurrentDate,
        canClearSeat: snapshot.canClearSeat,
        detailConfig: _bookingDetailConfig,
      ),
      BusinessSystem.order => <_CardMenuAction>[
        if (<int>{4, 5, 6, 7}.contains(table.businessStatus)) ...const [
          _CardMenuAction('存酒', Icons.wine_bar_outlined),
          _CardMenuAction('取酒', Icons.output_outlined),
        ],
        const _CardMenuAction('充公', Icons.inventory_2_outlined),
      ],
      BusinessSystem.cashier => <_CardMenuAction>[
        if (table.businessStatus == 1 && table.turnoverCount > 0) ...const [
          _CardMenuAction('复台', Icons.restore, form: _CardForm.turnback),
          _CardMenuAction('查看卡台记录', Icons.receipt_long_outlined),
        ],
      ],
      BusinessSystem.wine => const <_CardMenuAction>[],
      BusinessSystem.queue => const <_CardMenuAction>[],
      BusinessSystem.bms => const <_CardMenuAction>[],
      BusinessSystem.erp => const <_CardMenuAction>[],
      BusinessSystem.erpWarehouse => const <_CardMenuAction>[],
      BusinessSystem.vip => const <_CardMenuAction>[],
      BusinessSystem.superAdmin => const <_CardMenuAction>[],
    };
    return List<_CardMenuAction>.of(actions);
  }

  static List<_CardMenuAction> _bookingCardActions(
    CardTable table, {
    required bool businessOpen,
    required bool isCurrentDate,
    required bool canClearSeat,
    BookingDetailConfig detailConfig = BookingDetailConfig.unrestrictedAll,
  }) {
    final actions = switch (table.businessStatus) {
      1 when !businessOpen || !isCurrentDate => <_CardMenuAction>[
        const _CardMenuAction(
          '预留',
          Icons.history_toggle_off,
          write: BookingCardWriteAction.createReserve,
          form: _CardForm.reserve,
        ),
      ],
      1 when table.showOnlineText => <_CardMenuAction>[
        const _CardMenuAction(
          '转为线下卡台',
          Icons.swap_horiz,
          write: BookingCardWriteAction.convertOffline,
        ),
      ],
      1 => <_CardMenuAction>[
        const _CardMenuAction(
          '预留',
          Icons.history_toggle_off,
          write: BookingCardWriteAction.createReserve,
          form: _CardForm.reserve,
        ),
        const _CardMenuAction(
          '开台',
          Icons.play_arrow,
          write: BookingCardWriteAction.openEmpty,
          form: _CardForm.open,
        ),
        const _CardMenuAction(
          '锁定',
          Icons.lock_outline,
          write: BookingCardWriteAction.lock,
        ),
        if (table.turnoverCount > 0 && canClearSeat) ...const [
          _CardMenuAction(
            '修改翻台订位人',
            Icons.manage_accounts_outlined,
            form: _CardForm.turnoverSales,
          ),
          _CardMenuAction('复台', Icons.restore, form: _CardForm.turnback),
        ],
      ],
      2 when businessOpen && isCurrentDate => <_CardMenuAction>[
        const _CardMenuAction(
          '取消锁定',
          Icons.lock_open,
          write: BookingCardWriteAction.unlock,
        ),
      ],
      4 => <_CardMenuAction>[
        const _CardMenuAction(
          '修改低消',
          Icons.price_change_outlined,
          write: BookingCardWriteAction.updateMinConsume,
          form: _CardForm.minConsume,
        ),
        const _CardMenuAction(
          '修改订位人',
          Icons.person_outline,
          write: BookingCardWriteAction.updateSales,
          form: _CardForm.sales,
        ),
        const _CardMenuAction(
          '转台',
          Icons.swap_horiz,
          write: BookingCardWriteAction.transferOpen,
          form: _CardForm.transfer,
        ),
        const _CardMenuAction(
          '撤台',
          Icons.undo,
          write: BookingCardWriteAction.cancelOpen,
        ),
        const _CardMenuAction(
          '查看卡台详情',
          Icons.receipt_long_outlined,
          form: _CardForm.detail,
        ),
        const _CardMenuAction(
          '修改翻台订位人',
          Icons.manage_accounts_outlined,
          form: _CardForm.turnoverSales,
        ),
        const _CardMenuAction(
          '修改卡台标记',
          Icons.flag_outlined,
          write: BookingCardWriteAction.updateMark,
          form: _CardForm.mark,
        ),
        const _CardMenuAction(
          '修改备注',
          Icons.edit_note_outlined,
          write: BookingCardWriteAction.updateRemark,
          form: _CardForm.remark,
        ),
        const _CardMenuAction(
          '修改服务员',
          Icons.badge_outlined,
          write: BookingCardWriteAction.updateWaiter,
          form: _CardForm.waiter,
        ),
        const _CardMenuAction(
          '取消必点商品',
          Icons.remove_shopping_cart_outlined,
          write: BookingCardWriteAction.disableMustOrder,
        ),
      ],
      5 || 6 || 7 => <_CardMenuAction>[
        const _CardMenuAction(
          '修改低消',
          Icons.price_change_outlined,
          write: BookingCardWriteAction.updateMinConsume,
          form: _CardForm.minConsume,
        ),
        const _CardMenuAction(
          '修改订位人',
          Icons.person_outline,
          write: BookingCardWriteAction.updateSales,
          form: _CardForm.sales,
        ),
        const _CardMenuAction(
          '转台',
          Icons.swap_horiz,
          write: BookingCardWriteAction.transferOpen,
          form: _CardForm.transfer,
        ),
        const _CardMenuAction(
          '查看卡台详情',
          Icons.receipt_long_outlined,
          form: _CardForm.detail,
        ),
        const _CardMenuAction(
          '修改翻台订位人',
          Icons.manage_accounts_outlined,
          form: _CardForm.turnoverSales,
        ),
        const _CardMenuAction(
          '修改卡台标记',
          Icons.flag_outlined,
          write: BookingCardWriteAction.updateMark,
          form: _CardForm.mark,
        ),
        const _CardMenuAction(
          '修改备注',
          Icons.edit_note_outlined,
          write: BookingCardWriteAction.updateRemark,
          form: _CardForm.remark,
        ),
        const _CardMenuAction(
          '修改服务员',
          Icons.badge_outlined,
          write: BookingCardWriteAction.updateWaiter,
          form: _CardForm.waiter,
        ),
        if (table.businessStatus == 7 && canClearSeat)
          const _CardMenuAction(
            '清台',
            Icons.cleaning_services_outlined,
            write: BookingCardWriteAction.clearSeat,
          ),
      ],
      8 when !businessOpen || !isCurrentDate => <_CardMenuAction>[
        const _CardMenuAction(
          '修改预留',
          Icons.edit_calendar_outlined,
          write: BookingCardWriteAction.updateReserve,
          form: _CardForm.editReserve,
        ),
        const _CardMenuAction(
          '取消预留',
          Icons.event_busy_outlined,
          write: BookingCardWriteAction.cancelReserve,
        ),
      ],
      8 => <_CardMenuAction>[
        const _CardMenuAction(
          '开台',
          Icons.play_arrow,
          write: BookingCardWriteAction.openReserve,
          form: _CardForm.open,
        ),
        const _CardMenuAction(
          '转台',
          Icons.swap_horiz,
          write: BookingCardWriteAction.transferReserve,
          form: _CardForm.transfer,
        ),
        if (table.platformId == 0) ...const [
          _CardMenuAction(
            '取消预留',
            Icons.event_busy_outlined,
            write: BookingCardWriteAction.cancelReserve,
          ),
          _CardMenuAction(
            '修改预留',
            Icons.edit_calendar_outlined,
            write: BookingCardWriteAction.updateReserve,
            form: _CardForm.editReserve,
          ),
          _CardMenuAction(
            '修改翻台订位人',
            Icons.manage_accounts_outlined,
            form: _CardForm.turnoverSales,
          ),
        ],
      ],
      _ => <_CardMenuAction>[],
    };

    // Match Vue `syncBookingDetailOptions` (`cardMachine.vue:474-482`):
    // splice consumption (26) / wine (27) right after 查看卡台详情 (13) if present,
    // otherwise append before 置顶.
    final detailOptionIds = isCurrentDate && businessOpen
        ? BookingDetailAccess.optionIds(
            detailConfig,
            status: table.businessStatus,
            turnoverCount: table.turnoverCount,
          )
        : const <int>[];
    final detailActions = <_CardMenuAction>[
      for (final id in detailOptionIds)
        if (id == BookingDetailAccess.consumptionOptionId)
          const _CardMenuAction(
            '查看消费明细',
            Icons.receipt_outlined,
            form: _CardForm.consumption,
          )
        else if (id == BookingDetailAccess.wineOptionId)
          const _CardMenuAction(
            '查看存取酒明细',
            Icons.liquor_outlined,
            form: _CardForm.wineOps,
          ),
    ];

    final merged = List<_CardMenuAction>.of(actions);
    if (detailActions.isNotEmpty) {
      final detailIdx = merged.indexWhere(
        (item) => item.form == _CardForm.detail,
      );
      if (detailIdx >= 0) {
        merged.insertAll(detailIdx + 1, detailActions);
      } else {
        merged.addAll(detailActions);
      }
    }

    return <_CardMenuAction>[
      ...merged,
      const _CardMenuAction(
        '置顶',
        Icons.vertical_align_top,
        write: BookingCardWriteAction.pin,
      ),
      if (table.pinned)
        const _CardMenuAction(
          '取消置顶',
          Icons.vertical_align_bottom,
          write: BookingCardWriteAction.unpin,
        ),
    ];
  }

  Future<void> _onBookingAction(
    _CardMenuAction action,
    CardTable table,
    CardTableSnapshot snapshot,
  ) async {
    final identity = (
      widget.employeeId,
      widget.machineId,
      widget.stationId,
      widget.system,
    );
    final events = widget.events, phases = widget.connectionPhases;
    final selectedDate = _businessDateId;
    final day = snapshot.businessDayId;
    var expired = false;
    Map<String, Object?> fields = const {};
    Object tableScope(CardTable item) => (
      item.businessStatus,
      item.turnoverCount,
      item.bookId,
      item.openTime,
      item.salesEmployeeId,
      item.secondSalesEmployeeId,
      item.waiterEmployeeId,
      item.assignedMinConsumeAmount,
      item.remark,
      item.mark,
      item.pinned,
      item.mustOrderDisabled,
    );
    bool matches(CardTable original) {
      final current = _snapshot?.tables
          .where((item) => item.id == original.id)
          .firstOrNull;
      return current != null && tableScope(current) == tableScope(original);
    }

    bool current() {
      if (expired ||
          !mounted ||
          _sessionActionInProgress ||
          _failure != null ||
          (_livePhase ?? widget.connectionPhase) != ConnectionPhase.online ||
          identity !=
              (
                widget.employeeId,
                widget.machineId,
                widget.stationId,
                widget.system,
              ) ||
          !identical(events, widget.events) ||
          !identical(phases, widget.connectionPhases) ||
          _snapshot?.businessDayId != day ||
          _businessDateId != selectedDate ||
          !matches(table))
        return false;
      final latest = _snapshot!;
      final liveTable = latest.tables.firstWhere((item) => item.id == table.id);
      if (!_cardActions(latest, liveTable).any(
        (item) =>
            item.write == action.write &&
            item.form == action.form &&
            item.label == action.label,
      ))
        return false;
      final destinationId = '${fields['dest_seat_id'] ?? ''}';
      if (destinationId.isNotEmpty) {
        final destination = snapshot.tables
            .where((item) => item.id == destinationId)
            .firstOrNull;
        if (destination == null || !matches(destination)) return false;
      }
      return true;
    }

    void check() {
      if (!current()) expired = true;
    }

    if (!current()) return;
    _bookingValidityChecks.add(check);
    try {
      await _performBookingAction(
        action,
        table,
        snapshot,
        current,
        (value) => fields = value,
      );
    } finally {
      expired = true;
      _bookingValidityChecks.remove(check);
    }
  }

  Future<void> _performBookingAction(
    _CardMenuAction action,
    CardTable table,
    CardTableSnapshot snapshot,
    bool Function() canDispatch,
    void Function(Map<String, Object?>) captureFields,
  ) async {
    if (action.form == _CardForm.turnoverSales) {
      if (table.turnoverCount == 0) {
        _showSnack('当前卡台没有翻过台！');
        return;
      }
      await _showTurnoverSales(table, snapshot);
      return;
    }
    if (action.form == _CardForm.turnback) {
      await _showTurnback(table);
      return;
    }
    if (action.form == _CardForm.consumption) {
      await _showBookingOrderDetail(table, snapshot, mode: 'consumption');
      return;
    }
    if (action.form == _CardForm.wineOps) {
      await _showBookingOrderDetail(table, snapshot, mode: 'wine');
      return;
    }
    if (action.form == _CardForm.detail) {
      await _showBookingDetail(table, snapshot);
      return;
    }
    var fields = const <String, Object?>{};
    if (action.form != null) {
      final collected = await _collectBookingForm(
        action.form!,
        table,
        snapshot,
      );
      if (collected == null || !mounted) return;
      fields = collected;
      captureFields(fields);
      if (!canDispatch()) {
        _showSnack('卡台、营业日或连接已变化，请重新打开操作');
        return;
      }
    }
    final write = action.write;
    if (action.label == '查看卡台记录') {
      if (widget.onOpenPayOrder != null) {
        widget.onOpenPayOrder!(table);
      } else {
        await _pendingFeature(action.label, table: table);
      }
      return;
    }
    if (write == null) {
      await _pendingFeature(action.label, table: table);
      return;
    }
    if (write == BookingCardWriteAction.disableMustOrder &&
        table.mustOrderDisabled) {
      return;
    }
    if (write == BookingCardWriteAction.cancelReserve &&
        (table.bookId.isEmpty || table.bookId == '0')) {
      _showSnack('当前卡台没有预留记录');
      return;
    }
    if (write == BookingCardWriteAction.updateWaiter &&
        '${fields['waiter_emp_id'] ?? ''}'.isEmpty) {
      _showSnack('请选择服务员');
      return;
    }
    final confirm = _bookingConfirm(write);
    if (confirm != null) {
      final ok = await showBookingConfirmDialog(
        context: context,
        title: confirm.title,
        message: confirm.body,
        destructive:
            write == BookingCardWriteAction.lock ||
            write == BookingCardWriteAction.cancelOpen ||
            write == BookingCardWriteAction.cancelReserve ||
            write == BookingCardWriteAction.clearSeat,
      );
      if (ok != true || !mounted) return;
    }
    if (!canDispatch()) {
      _showSnack('卡台、营业日或连接已变化，请重新打开操作');
      return;
    }
    final submit = widget.onBookingCardWrite;
    if (submit == null) {
      await _pendingFeature(action.label, table: table);
      return;
    }
    bool dispatchCurrent() =>
        canDispatch() && ModalRoute.of(context)?.isCurrent == true;
    if (!dispatchCurrent()) return;
    final result = await submit(
      action: write,
      seatId: table.id,
      bookId: table.bookId,
      fields: fields,
      canDispatch: dispatchCurrent,
    );
    if (!dispatchCurrent()) return;
    if (result.failureOrNull != null) {
      _showSnack(result.failureOrNull!.safeMessage);
      return;
    }
    _showSnack(switch (write) {
      BookingCardWriteAction.pin => '置顶成功',
      BookingCardWriteAction.unpin => '取消置成功',
      BookingCardWriteAction.disableMustOrder => '取消必点商品成功',
      BookingCardWriteAction.updateMinConsume => '修改低消金额操作成功！',
      BookingCardWriteAction.updateSales => '修改订位人成功！',
      BookingCardWriteAction.updateMark => '修改卡台标签成功！',
      BookingCardWriteAction.updateRemark => '修改卡台备注成功！',
      BookingCardWriteAction.updateWaiter => '修改服务员成功！',
      BookingCardWriteAction.convertOffline => '转线下操作中，请稍后...',
      BookingCardWriteAction.openEmpty ||
      BookingCardWriteAction.openReserve => '开台成功！',
      BookingCardWriteAction.createReserve => '新增成功',
      BookingCardWriteAction.updateReserve => '修改成功',
      BookingCardWriteAction.transferOpen ||
      BookingCardWriteAction.transferReserve => '转台成功',
      _ => '操作成功！',
    });
    final refresh = widget.onRefresh;
    if (refresh != null) unawaited(_runSessionAction(refresh));
  }

  ({String title, String body})? _bookingConfirm(BookingCardWriteAction write) {
    return switch (write) {
      BookingCardWriteAction.lock => (
        title: '锁定卡台',
        body: '是否确认锁定卡台，锁定后该卡台除取消锁定外，其他功能均不能使用',
      ),
      BookingCardWriteAction.unlock => (title: '取消锁定', body: '是否确认取消锁定？'),
      BookingCardWriteAction.cancelOpen => (title: '撤台', body: '是否确认撤台操作？'),
      BookingCardWriteAction.cancelReserve => (title: '取消预留', body: '是否确认取消预留'),
      BookingCardWriteAction.disableMustOrder => (
        title: '取消必点商品',
        body: '是否确认取消必点商品?',
      ),
      BookingCardWriteAction.clearSeat => (title: '清台', body: '是否确认清台'),
      BookingCardWriteAction.convertOffline => (
        title: '临时转为线下卡台',
        body: '是否确认将此卡台临时转为线下卡台',
      ),
      BookingCardWriteAction.pin ||
      BookingCardWriteAction.unpin ||
      BookingCardWriteAction.updateMinConsume ||
      BookingCardWriteAction.updateSales ||
      BookingCardWriteAction.updateMark ||
      BookingCardWriteAction.updateRemark ||
      BookingCardWriteAction.updateWaiter ||
      BookingCardWriteAction.openEmpty ||
      BookingCardWriteAction.openReserve ||
      BookingCardWriteAction.createReserve ||
      BookingCardWriteAction.updateReserve ||
      BookingCardWriteAction.transferOpen ||
      BookingCardWriteAction.transferReserve => null,
    };
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showBookingDetail(CardTable table, CardTableSnapshot snapshot) {
    final sales = _employeeNamed(snapshot, table.salesEmployeeId);
    final second = _employeeNamed(snapshot, table.secondSalesEmployeeId);
    final arriveText = BookingCardDisplay.formatArriveTime(
      table.expectedArriveTime,
    );
    final customerPhone = table.effectiveBookingPhone;
    Widget detailCell(String label, String value) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: BookingTokens.surfaceFooter,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BookingTokens.tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: BookingTokens.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '---' : value,
            style: const TextStyle(
              color: BookingTokens.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Theme(
        data: BookingTheme.dark(),
        child: CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                _closeBusinessRoute(dialogContext),
          },
          child: Focus(
            autofocus: true,
            child: AlertDialog(
              backgroundColor: BookingTokens.surfaceDialog,
              surfaceTintColor: Colors.transparent,
              titlePadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0x9932B9FF)),
              ),
              title: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                decoration: const BoxDecoration(
                  color: BookingTokens.surfaceHeader,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                  border: Border(
                    bottom: BorderSide(color: BookingTokens.dividerBlue),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        '查看卡台详情',
                        style: TextStyle(
                          color: BookingTokens.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: () => _closeBusinessRoute(dialogContext),
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: BookingTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 300, maxWidth: 540),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: BookingTokens.surfaceHeader,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: BookingTokens.dividerBlue),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                '卡台名称：${table.name}',
                                style: const TextStyle(
                                  color: BookingTokens.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(table.businessStatus),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _statusLabel(table.businessStatus),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: detailCell('订位人', sales?.name ?? ''),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: detailCell('订位人电话', sales?.phone ?? ''),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: detailCell(
                              '最低消费',
                              '¥${table.assignedMinConsumeAmount}',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: detailCell('人数', '${table.customerCount}人'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: detailCell('客人', table.customerName),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: detailCell('客人电话', customerPhone),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: detailCell('联合订位人', second?.name ?? ''),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: detailCell('联合订位人电话', second?.phone ?? ''),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      detailCell('预订到达时间', arriveText),
                      const SizedBox(height: 8),
                      detailCell('转台信息', table.transferHistory),
                      const SizedBox(height: 8),
                      detailCell('备注', table.remark),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: BookingTokens.brandSecondary,
                    foregroundColor: BookingTokens.textPrimary,
                    minimumSize: const Size(104, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                    ),
                  ),
                  onPressed: () => _closeBusinessRoute(dialogContext),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTurnoverSales(
    CardTable table,
    CardTableSnapshot snapshot,
  ) async {
    final refreshed = await showDialog<bool>(
      context: context,
      builder: (context) => _TurnoverSalesDialog(
        table: table,
        snapshot: snapshot,
        onLoadTurnoverSales: widget.onLoadTurnoverSales,
        onChangeTurnoverSales: widget.onChangeTurnoverSales,
        onShowSnack: _showSnack,
      ),
    );
    if (refreshed == true && mounted) {
      final refresh = widget.onRefresh;
      if (refresh != null) unawaited(_runSessionAction(refresh));
    }
  }

  Future<void> _showTurnback(CardTable table) async {
    final refreshed = await showDialog<bool>(
      context: context,
      builder: (context) => _TurnbackDialog(
        table: table,
        onLoadTurnbackList: widget.onLoadTurnbackList,
        onConfirmTurnback: widget.onConfirmTurnback,
        onShowSnack: _showSnack,
      ),
    );
    if (refreshed == true && mounted) {
      final refresh = widget.onRefresh;
      if (refresh != null) unawaited(_runSessionAction(refresh));
    }
  }

  Future<void> _showBookingOrderDetail(
    CardTable table,
    CardTableSnapshot snapshot, {
    required String mode,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => _BookingOrderDetailDialog(
        table: table,
        snapshot: snapshot,
        mode: mode,
        onLoadOrderDetail: widget.onLoadOrderDetail,
        onShowSnack: _showSnack,
      ),
    );
  }

  Future<Map<String, Object?>?> _collectBookingForm(
    _CardForm form,
    CardTable table,
    CardTableSnapshot snapshot,
  ) {
    return switch (form) {
      _CardForm.minConsume => _promptText(
        title: '修改低消',
        label: '最低消费',
        value: '${table.assignedMinConsumeAmount}',
        field: 'min_csm_amt',
      ),
      _CardForm.remark => _promptText(
        title: '修改备注',
        label: '备注',
        value: table.remark,
        field: 'remark',
        maxLines: 3,
      ),
      _CardForm.mark => _promptChoice(
        title: '修改卡台标记',
        value: table.mark,
        field: 'mark',
        options: ['', ...snapshot.seatMarks],
        labels: ['请选择', ...snapshot.seatMarks],
      ),
      _CardForm.sales => _promptEmployee(
        title: '修改订位人',
        employees: snapshot.employees,
        departments: snapshot.departments,
        selectedId: table.salesEmployeeId,
        idField: 'sales_emp_id',
        nameField: 'sales_name',
        extra: (_) => <String, Object?>{
          'second_sales_emp_id': table.secondSalesEmployeeId,
          'second_sales_name':
              _employeeNamed(snapshot, table.secondSalesEmployeeId)?.name ?? '',
        },
      ),
      _CardForm.waiter => _promptEmployee(
        title: '修改服务员',
        employees: snapshot.employees,
        departments: snapshot.departments,
        selectedId: table.waiterEmployeeId,
        idField: 'waiter_emp_id',
        nameField: 'waiter_name',
        extra: (_) => <String, Object?>{'turnover_cnt': table.turnoverCount},
      ),
      _CardForm.open || _CardForm.reserve || _CardForm.editReserve =>
        _promptOpenOrReserveForm(form: form, table: table, snapshot: snapshot),
      _CardForm.transfer => _promptTransferForm(
        table: table,
        snapshot: snapshot,
      ),
      _ => Future<Map<String, Object?>?>.value(null),
    };
  }

  Future<Map<String, Object?>?> _promptOpenOrReserveForm({
    required _CardForm form,
    required CardTable table,
    required CardTableSnapshot snapshot,
  }) async {
    BookingBookDetail? detail;
    final shouldLoadBookDetail =
        (form == _CardForm.editReserve ||
            (form == _CardForm.open && table.businessStatus == 8)) &&
        widget.onLoadBookDetail != null &&
        table.bookId.isNotEmpty &&
        table.bookId != '0';
    if (shouldLoadBookDetail) {
      final result = await widget.onLoadBookDetail!(table.bookId);
      if (!mounted) return null;
      if (result.failureOrNull case final failure?) {
        _showSnack(failure.safeMessage);
        return null;
      }
      detail = result.valueOrNull;
    }

    if (!mounted) return null;

    return showBookingDrawer<Map<String, Object?>>(
      context: context,
      desktopWidth: 540,
      tabletWidthFactor: 0.78,
      routeSettings: const RouteSettings(
        name: BusinessRouteObserver.childRouteName,
      ),
      builder: (drawerContext) => _BookingOpenOrReserveDialog(
        form: form,
        table: table,
        snapshot: snapshot,
        businessDateId: _businessDateId,
        initialDetail: detail,
        onShowSnack: _showSnack,
      ),
    );
  }

  Future<Map<String, Object?>?> _promptTransferForm({
    required CardTable table,
    required CardTableSnapshot snapshot,
  }) async {
    final scopedTables = snapshot.tablesForDate(_businessDateId);
    final candidateTables = scopedTables
        .where((t) => t.id != table.id && t.businessStatus == 1)
        .toList();
    if (candidateTables.isEmpty) {
      _showSnack('当前暂无可转入的空卡台');
      return null;
    }
    return showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => _BookingTransferDialog(
        table: table,
        allTables: scopedTables,
        regions: _visibleRegions(snapshot),
        candidateTables: candidateTables,
      ),
    );
  }

  Future<Map<String, Object?>?> _promptText({
    required String title,
    required String label,
    required String value,
    required String field,
    int maxLines = 1,
  }) async {
    var text = value;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Theme(
        data: BookingTheme.dark(),
        child: CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                _closeBusinessRoute(dialogContext, false),
            if (maxLines == 1) ...{
              const SingleActivator(LogicalKeyboardKey.enter): () =>
                  _closeBusinessRoute(dialogContext, true),
              const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
                  _closeBusinessRoute(dialogContext, true),
            },
          },
          child: AlertDialog(
            backgroundColor: BookingTokens.surfaceDialog,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0x8832B9FF)),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: BookingTokens.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SizedBox(
              width: 360,
              child: TextFormField(
                key: CardTableScreen.bookingFormFieldKey,
                initialValue: value,
                autofocus: true,
                maxLines: maxLines,
                style: const TextStyle(color: BookingTokens.textPrimary),
                keyboardType: maxLines == 1
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.multiline,
                decoration: InputDecoration(labelText: label),
                onChanged: (next) => text = next,
                onFieldSubmitted: maxLines == 1
                    ? (_) => _closeBusinessRoute(dialogContext, true)
                    : null,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => _closeBusinessRoute(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => _closeBusinessRoute(dialogContext, true),
                child: const Text('确定'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return null;
    return <String, Object?>{field: text};
  }

  Future<Map<String, Object?>?> _promptChoice({
    required String title,
    required String value,
    required String field,
    required List<String> options,
    required List<String> labels,
  }) async {
    var current = value;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Theme(
        data: BookingTheme.dark(),
        child: StatefulBuilder(
          builder: (context, setState) => CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  _closeBusinessRoute(dialogContext, false),
              const SingleActivator(LogicalKeyboardKey.enter): () =>
                  _closeBusinessRoute(dialogContext, true),
              const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
                  _closeBusinessRoute(dialogContext, true),
            },
            child: Focus(
              autofocus: true,
              child: AlertDialog(
                backgroundColor: BookingTokens.surfaceDialog,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0x8832B9FF)),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    color: BookingTokens.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: SizedBox(
                  width: 360,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    dropdownColor: BookingTokens.surfaceDialog,
                    initialValue: options.contains(current) ? current : '',
                    items: [
                      for (var i = 0; i < options.length; i++)
                        DropdownMenuItem(
                          value: options[i],
                          child: Text(labels[i]),
                        ),
                    ],
                    onChanged: (next) => setState(() => current = next ?? ''),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => _closeBusinessRoute(dialogContext, false),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: () => _closeBusinessRoute(dialogContext, true),
                    child: const Text('确定'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (ok != true) return null;
    return <String, Object?>{field: current};
  }

  Future<Map<String, Object?>?> _promptEmployee({
    required String title,
    required List<CardEmployee> employees,
    required String selectedId,
    required String idField,
    required String nameField,
    List<CardDepartment> departments = const <CardDepartment>[],
    Map<String, Object?> Function(CardEmployee? employee)? extra,
  }) async {
    final pickedId = await showBookingEmployeePickerDialog(
      context: context,
      title: title,
      employees: employees,
      departments: departments,
      selectedId: selectedId,
      allowClear: true,
    );
    if (pickedId == null) return null;
    CardEmployee? employee;
    for (final item in employees) {
      if (item.id == pickedId) {
        employee = item;
        break;
      }
    }
    return <String, Object?>{
      idField: employee?.id ?? '',
      nameField: employee?.name ?? '',
      ...?extra?.call(employee),
    };
  }

  static CardEmployee? _employeeNamed(CardTableSnapshot snapshot, String id) {
    if (id.isEmpty) return null;
    for (final employee in snapshot.employees) {
      if (employee.id == id) return employee;
    }
    return null;
  }

  Widget _legendItem(String label, int count, int status) => InkWell(
    onTap: status == 20 || widget.system == BusinessSystem.cashier
        ? null
        : () => setState(() {
            _businessStatus = _businessStatus == status ? null : status;
          }),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 10,
            decoration: BoxDecoration(
              color: status == 20 ? Colors.transparent : _cardColor(status),
              border: status == 20
                  ? null
                  : Border.all(color: const Color(0xff939bad)),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$label $count',
              style: TextStyle(color: _foreground, fontSize: 13),
            ),
          ),
        ],
      ),
    ),
  );

  static Color _statusColor(int status) => switch (status) {
    1 => const Color(0xff465675),
    2 => const Color(0xff7d6a33),
    3 || 8 => const Color(0xff008f95),
    4 => const Color(0xffd08322),
    5 || 6 => const Color(0xffc83758),
    7 => const Color(0xff5c3bc1),
    _ => const Color(0xff465675),
  };

  static bool _matchesStatusFilter(int actual, int selected) =>
      switch (selected) {
        8 => actual == 3 || actual == 8,
        5 => actual == 5 || actual == 6,
        _ => actual == selected,
      };

  static String _statusLabel(int status) => switch (status) {
    1 => '空台',
    2 => '锁定',
    3 => '预订',
    4 => '开台',
    5 => '点单未结',
    6 => '部分结账',
    7 => '已结账',
    8 => '线上预订',
    _ => '未知状态',
  };

  static const AppFailure _sessionActionFailure = AppFailure(
    kind: FailureKind.unknown,
    code: 'session.action_failed',
    safeMessage: '登录状态切换失败，请重试',
  );
  static const AppFailure _businessDayActionFailure = AppFailure(
    kind: FailureKind.unknown,
    code: 'business_day.action_failed',
    safeMessage: '开启营业日失败，请重试',
  );
}

enum _CardForm {
  minConsume,
  sales,
  mark,
  remark,
  waiter,
  detail,
  turnoverSales,
  turnback,
  consumption,
  wineOps,
  open,
  reserve,
  editReserve,
  transfer,
}

final class _CardMenuAction {
  const _CardMenuAction(this.label, this.icon, {this.write, this.form});

  final String label;
  final IconData icon;
  final BookingCardWriteAction? write;
  final _CardForm? form;
}

final class _CardMenuLayoutDelegate extends SingleChildLayoutDelegate {
  const _CardMenuLayoutDelegate({
    required this.cardRect,
    required this.overlaySize,
    required this.padding,
  });

  final Rect cardRect;
  final Size overlaySize;
  final EdgeInsets padding;

  static const double _menuWidth = 172;
  static const double _horizontalOffset = 164;
  static const double _gap = 8;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxHeight = overlaySize.height - padding.vertical - _gap * 2;
    return BoxConstraints(
      minWidth: _menuWidth,
      maxWidth: _menuWidth,
      maxHeight: maxHeight < 80 ? 80 : maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final minX = padding.left + _gap;
    final maxX = overlaySize.width - padding.right - childSize.width - _gap;
    var x = cardRect.left + _horizontalOffset;
    if (x > maxX) {
      x = cardRect.right - _horizontalOffset - childSize.width;
    }
    x = x.clamp(minX, maxX < minX ? minX : maxX);
    final minY = padding.top + _gap;
    final maxY = overlaySize.height - padding.bottom - childSize.height - _gap;
    var y = cardRect.center.dy - childSize.height / 2;
    y = y.clamp(minY, maxY < minY ? minY : maxY);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(covariant _CardMenuLayoutDelegate oldDelegate) =>
      oldDelegate.cardRect != cardRect ||
      oldDelegate.overlaySize != overlaySize ||
      oldDelegate.padding != padding;
}

final class _BookingTransferDialog extends StatefulWidget {
  const _BookingTransferDialog({
    required this.table,
    required this.allTables,
    required this.regions,
    required this.candidateTables,
  });

  final CardTable table;
  final List<CardTable> allTables;
  final List<CardRegion> regions;
  final List<CardTable> candidateTables;

  @override
  State<_BookingTransferDialog> createState() => _BookingTransferDialogState();
}

final class _BookingTransferDialogState extends State<_BookingTransferDialog> {
  late String _selectedDestSeatId;
  late final TextEditingController _newMinConsumeController;

  @override
  void initState() {
    super.initState();
    _selectedDestSeatId = widget.candidateTables.first.id;
    final initialMin = widget.candidateTables.first.assignedMinConsumeAmount;
    _newMinConsumeController = TextEditingController(
      text: initialMin == 0 ? '0' : '$initialMin',
    );
  }

  @override
  void dispose() {
    _newMinConsumeController.dispose();
    super.dispose();
  }

  void _onDestSeatChanged(String? newSeatId) {
    if (newSeatId == null || newSeatId == _selectedDestSeatId) return;
    setState(() {
      _selectedDestSeatId = newSeatId;
      final destTable = widget.candidateTables.firstWhere(
        (t) => t.id == newSeatId,
        orElse: () => widget.candidateTables.first,
      );
      final initialMin = destTable.assignedMinConsumeAmount;
      _newMinConsumeController.text = initialMin == 0 ? '0' : '$initialMin';
    });
  }

  void _submit() {
    final newMin = num.tryParse(_newMinConsumeController.text.trim()) ?? 0;
    _closeBusinessRoute(context, <String, Object?>{
      'dest_seat_id': _selectedDestSeatId,
      'new_min_csm_amt': newMin,
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final isPhone = BookingViewportTier.of(context).isPhone;
    final dialogWidth = isPhone
        ? media.width * 0.96
        : (media.width * 0.86).clamp(560.0, 960.0);
    final dialogHeight = isPhone
        ? media.height * 0.90
        : (media.height * 0.84).clamp(440.0, 680.0);
    return Theme(
      data: BookingTheme.dark(),
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              _closeBusinessRoute(context),
          const SingleActivator(LogicalKeyboardKey.enter): _submit,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _submit,
        },
        child: Dialog(
          backgroundColor: BookingTokens.surfaceDialog,
          insetPadding: EdgeInsets.all(isPhone ? 8 : 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x9932B9FF)),
          ),
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                  decoration: const BoxDecoration(
                    color: BookingTokens.surfaceHeader,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    border: Border(
                      bottom: BorderSide(color: BookingTokens.dividerBlue),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Text(
                        '转台',
                        style: TextStyle(
                          color: BookingTokens.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          '原卡台：${widget.table.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BookingTokens.accentGlowBorder,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '关闭',
                        onPressed: () => _closeBusinessRoute(context),
                        icon: const Icon(
                          Icons.close,
                          color: BookingTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: BookingSeatPickerGrid(
                      regions: widget.regions,
                      tables: widget.allTables,
                      currentSeatId: widget.table.id,
                      selectedIds: <String>{_selectedDestSeatId},
                      onToggleSeat: (seat) => _onDestSeatChanged(seat.id),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  decoration: const BoxDecoration(
                    color: BookingTokens.surfaceDrawerFooter,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(14),
                    ),
                    border: Border(
                      top: BorderSide(color: BookingTokens.tableBorder),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: isPhone ? 150 : 180,
                            child: DropdownButtonFormField<String>(
                              key: CardTableScreen.bookingTransferDestKey,
                              initialValue: _selectedDestSeatId,
                              dropdownColor: BookingTokens.surfaceDialog,
                              decoration: const InputDecoration(
                                labelText: '目标卡台',
                                isDense: true,
                              ),
                              isExpanded: true,
                              items: [
                                for (final dest in widget.candidateTables)
                                  DropdownMenuItem(
                                    value: dest.id,
                                    child: Text(dest.name),
                                  ),
                              ],
                              onChanged: _onDestSeatChanged,
                            ),
                          ),
                          SizedBox(
                            width: isPhone ? 130 : 150,
                            child: TextFormField(
                              initialValue:
                                  '${widget.table.assignedMinConsumeAmount}',
                              decoration: const InputDecoration(
                                labelText: '原卡台低消',
                                suffixText: '元',
                                isDense: true,
                              ),
                              enabled: false,
                            ),
                          ),
                          SizedBox(
                            width: isPhone ? 140 : 170,
                            child: TextFormField(
                              key: CardTableScreen.bookingTransferMinConsumeKey,
                              controller: _newMinConsumeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: '新卡台低消',
                                suffixText: '元',
                                isDense: true,
                              ),
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TextButton(
                            onPressed: () => _closeBusinessRoute(context),
                            child: const Text('取消'),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            onPressed: _submit,
                            child: const Text('确认转台'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _BookingOpenOrReserveDialog extends StatefulWidget {
  const _BookingOpenOrReserveDialog({
    required this.form,
    required this.table,
    required this.snapshot,
    required this.businessDateId,
    required this.onShowSnack,
    this.initialDetail,
  });

  final _CardForm form;
  final CardTable table;
  final CardTableSnapshot snapshot;
  final String? businessDateId;
  final BookingBookDetail? initialDetail;
  final void Function(String message) onShowSnack;

  @override
  State<_BookingOpenOrReserveDialog> createState() =>
      _BookingOpenOrReserveDialogState();
}

final class _BookingOpenOrReserveDialogState
    extends State<_BookingOpenOrReserveDialog> {
  late final TextEditingController _phoneController;
  late final TextEditingController _nameController;
  late final TextEditingController _countController;
  late final TextEditingController _minConsumeController;
  late final TextEditingController _remarkController;

  String? _selectedSalesId;
  String? _selectedSecondSalesId;
  String? _selectedWaiterId;
  String _selectedMark = '';
  int _autoSendMsg = 2; // 2: 否（默认），1: 是
  String _expArriveTime = '';
  final List<String> _extraSeatIds = <String>[];

  @override
  void initState() {
    super.initState();
    final detail = widget.initialDetail;
    final table = widget.table;

    final initialPhone = detail != null && detail.customerPhone.isNotEmpty
        ? detail.customerPhone
        : table.effectiveBookingPhone;
    _phoneController = TextEditingController(text: initialPhone);

    final initialName = detail != null && detail.customerName.isNotEmpty
        ? detail.customerName
        : table.customerName;
    _nameController = TextEditingController(text: initialName);

    final initialCount = detail != null && detail.customerExpCnt > 0
        ? detail.customerExpCnt
        : (table.customerCount > 0
              ? table.customerCount
              : (table.capacity > 0 ? table.capacity : 1));
    _countController = TextEditingController(text: '$initialCount');

    final initialMin = detail != null && detail.expMinCsmAmt > 0
        ? detail.expMinCsmAmt
        : table.assignedMinConsumeAmount;
    _minConsumeController = TextEditingController(
      text: initialMin == 0 ? '0' : '$initialMin',
    );

    final initialRemark = detail != null && detail.remark.isNotEmpty
        ? detail.remark
        : table.remark;
    _remarkController = TextEditingController(text: initialRemark);

    _selectedSalesId = detail != null && detail.salesEmpId.isNotEmpty
        ? detail.salesEmpId
        : table.salesEmployeeId;

    _selectedSecondSalesId =
        detail != null && detail.secondSalesEmpId.isNotEmpty
        ? detail.secondSalesEmpId
        : table.secondSalesEmployeeId;

    _selectedWaiterId = table.waiterEmployeeId;

    _selectedMark = detail != null && detail.mark.isNotEmpty
        ? detail.mark
        : table.mark;

    _autoSendMsg = detail?.autoSendMsg == 1 ? 1 : 2;
    _expArriveTime = detail != null && detail.expArriveTime.isNotEmpty
        ? detail.expArriveTime
        : table.expectedArriveTime;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _countController.dispose();
    _minConsumeController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  String _validMark(String mark) {
    if (widget.snapshot.seatMarks.contains(mark)) return mark;
    return '';
  }

  void _submit() {
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty && phone.length != 11) {
      widget.onShowSnack('请输入正确的手机号');
      return;
    }

    final name = _nameController.text.trim();
    final rawCnt = int.tryParse(_countController.text.trim()) ?? 0;
    if (rawCnt <= 0 || rawCnt > 100) {
      widget.onShowSnack(
        widget.form == _CardForm.open
            ? '请输入有效的到店人数 (1-100)'
            : '请输入有效的预定人数 (1-100)',
      );
      return;
    }
    final cnt = rawCnt;
    final minCsm =
        num.tryParse(_minConsumeController.text.trim()) ??
        widget.table.assignedMinConsumeAmount;
    final remark = _remarkController.text.trim();

    final salesName =
        _CardTableScreenState._employeeNamed(
          widget.snapshot,
          _selectedSalesId ?? '',
        )?.name ??
        '';
    final secondSalesName =
        _CardTableScreenState._employeeNamed(
          widget.snapshot,
          _selectedSecondSalesId ?? '',
        )?.name ??
        '';
    final waiterName =
        _CardTableScreenState._employeeNamed(
          widget.snapshot,
          _selectedWaiterId ?? '',
        )?.name ??
        '';

    final dateId = widget.businessDateId;
    String bookDay = '';
    if (dateId != null && dateId.length == 8) {
      bookDay =
          '${dateId.substring(0, 4)}-${dateId.substring(4, 6)}-${dateId.substring(6, 8)}';
    } else if (dateId != null && dateId.contains('-')) {
      bookDay = dateId;
    } else {
      final now = DateTime.now();
      final y = now.year.toString().padLeft(4, '0');
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');
      bookDay = '$y-$m-$d';
    }

    final isCurrentDate =
        dateId == widget.snapshot.businessDates.firstOrNull?.id;
    final isThisWkday = isCurrentDate ? 1 : 2;

    final oldSalesEmpId = (widget.initialDetail?.salesEmpId.isNotEmpty == true)
        ? widget.initialDetail!.salesEmpId
        : widget.table.salesEmployeeId;

    final Map<String, Object?> fields = widget.form == _CardForm.open
        ? <String, Object?>{
            'seat_id': widget.table.id,
            'id': widget.table.bookId,
            'customer_phone': phone,
            'customer_name': name,
            'customer_cnt': cnt,
            'min_csm_amt': minCsm,
            'sales_emp_id': _selectedSalesId ?? '',
            'sales_name': salesName,
            'second_sales_emp_id': _selectedSecondSalesId ?? '',
            'second_sales_name': secondSalesName,
            'waiter_emp_id': _selectedWaiterId ?? '',
            'waiter_name': waiterName,
            'remark': remark,
            'mark': _selectedMark,
            'old_sales_emp_id': oldSalesEmpId,
            if (_expArriveTime.trim().isNotEmpty)
              'exp_arrive_time': _expArriveTime.trim(),
          }
        : <String, Object?>{
            'exp_seat_id': widget.table.id,
            'exp_seat_ids': <String>[widget.table.id, ..._extraSeatIds],
            'id': widget.table.bookId,
            'book_day': bookDay,
            'is_this_wkday': isThisWkday,
            'customer_phone': phone,
            'customer_name': name,
            'customer_exp_cnt': cnt,
            'exp_min_csm_amt': minCsm,
            'sales_emp_id': _selectedSalesId ?? '',
            'sales_name': salesName,
            'second_sales_emp_id': _selectedSecondSalesId ?? '',
            'second_sales_name': secondSalesName,
            'remark': remark,
            'mark': _selectedMark,
            'auto_send_msg': _autoSendMsg,
            'exp_arrive_time': _expArriveTime.trim(),
          };

    _closeBusinessRoute(context, fields);
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = widget.form == _CardForm.open;
    final isReservedOpen = isOpen && widget.table.businessStatus == 8;
    final title = switch (widget.form) {
      _CardForm.open => '开台',
      _CardForm.editReserve => '修改预留',
      _CardForm.reserve => '新建预留',
      _ => '',
    };

    return Theme(
      data: BookingTheme.dark(),
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              _closeBusinessRoute(context),
          const SingleActivator(LogicalKeyboardKey.enter): _submit,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _submit,
        },
        child: BookingDrawerScaffold(
          title: title,
          subtitle: '卡台：${widget.table.name}',
          onClose: () => _closeBusinessRoute(context),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: CardTableScreen.bookingFormPhoneKey,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '客人电话',
                    hintText: '11位手机号（选填）',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '客人姓名'),
                ),
                if (!isOpen) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        '是否发送短信：',
                        style: TextStyle(
                          color: BookingTokens.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        key: const Key('booking-sms-no'),
                        label: const Text('否'),
                        selected: _autoSendMsg == 2,
                        showCheckmark: false,
                        selectedColor: BookingTokens.brandPrimary,
                        backgroundColor: BookingTokens.surfaceFooter,
                        labelStyle: TextStyle(
                          color: _autoSendMsg == 2
                              ? Colors.white
                              : BookingTokens.textSecondary,
                        ),
                        onSelected: (_) => setState(() => _autoSendMsg = 2),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        key: const Key('booking-sms-yes'),
                        label: const Text('是'),
                        selected: _autoSendMsg == 1,
                        showCheckmark: false,
                        selectedColor: BookingTokens.brandPrimary,
                        backgroundColor: BookingTokens.surfaceFooter,
                        labelStyle: TextStyle(
                          color: _autoSendMsg == 1
                              ? Colors.white
                              : BookingTokens.textSecondary,
                        ),
                        onSelected: (_) => setState(() => _autoSendMsg = 1),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                BookingArriveTimeField(
                  value: _expArriveTime,
                  onChanged: (next) => setState(() => _expArriveTime = next),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isOpen ? '到店人数' : '预定人数',
                    helperText: '范围 1-100 人',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minConsumeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: isOpen ? '最低消费' : '预期最低消费',
                    suffixText: '元',
                    helperText: isReservedOpen
                        ? '卡台低消 ¥${widget.table.assignedMinConsumeAmount}'
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                BookingEmployeePickerField(
                  fieldKey: const Key('booking-form-sales'),
                  label: '订位人',
                  employees: widget.snapshot.employees,
                  departments: widget.snapshot.departments,
                  selectedId: _selectedSalesId,
                  onChanged: (val) => setState(() => _selectedSalesId = val),
                ),
                const SizedBox(height: 12),
                BookingEmployeePickerField(
                  fieldKey: const Key('booking-form-second-sales'),
                  label: '联合订位人',
                  employees: widget.snapshot.employees,
                  departments: widget.snapshot.departments,
                  selectedId: _selectedSecondSalesId,
                  onChanged: (val) =>
                      setState(() => _selectedSecondSalesId = val),
                ),
                if (isOpen) ...[
                  const SizedBox(height: 12),
                  BookingEmployeePickerField(
                    fieldKey: const Key('booking-form-waiter'),
                    label: '服务员',
                    employees: widget.snapshot.employees,
                    departments: widget.snapshot.departments,
                    selectedId: _selectedWaiterId,
                    onChanged: (val) => setState(() => _selectedWaiterId = val),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _validMark(_selectedMark),
                  dropdownColor: BookingTokens.surfaceDialog,
                  decoration: const InputDecoration(labelText: '卡台标签'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('请选择')),
                    for (final mark in widget.snapshot.seatMarks)
                      DropdownMenuItem(value: mark, child: Text(mark)),
                  ],
                  onChanged: (val) => setState(() => _selectedMark = val ?? ''),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _remarkController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '备注'),
                ),
                if (widget.form == _CardForm.reserve) ...[
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '多台预订：',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: BookingTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          InputChip(
                            label: Text(widget.table.name),
                            selected: true,
                            onPressed: null,
                          ),
                          for (final id in _extraSeatIds)
                            InputChip(
                              label: Text(
                                widget.snapshot.tables
                                    .firstWhere(
                                      (t) => t.id == id,
                                      orElse: () => widget.table,
                                    )
                                    .name,
                              ),
                              onDeleted: () =>
                                  setState(() => _extraSeatIds.remove(id)),
                            ),
                          ActionChip(
                            avatar: const Icon(Icons.add, size: 16),
                            label: const Text('添加卡台'),
                            onPressed: _showAddTablePicker,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: BookingTokens.brandSecondary,
                  foregroundColor: BookingTokens.textPrimary,
                  minimumSize: const Size(104, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => _closeBusinessRoute(context),
                child: const Text('取消'),
              ),
              const SizedBox(width: 12),
              BookingPrimaryPillButton(label: '确认', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddTablePicker() async {
    final scopedTables = widget.snapshot.tablesForDate(widget.businessDateId);
    final availableTables = scopedTables
        .where((t) => t.id != widget.table.id && t.businessStatus == 1)
        .toList();
    if (availableTables.isEmpty) {
      widget.onShowSnack('暂无其他可用空台');
      return;
    }
    final selected = Set<String>.from(_extraSeatIds);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: BookingTheme.dark(),
        child: StatefulBuilder(
          builder: (ctx, setPickerState) {
            final media = MediaQuery.sizeOf(ctx);
            final isPhone = BookingViewportTier.of(ctx).isPhone;
            return CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.escape): () =>
                    _closeBusinessRoute(ctx, false),
                const SingleActivator(LogicalKeyboardKey.enter): () =>
                    _closeBusinessRoute(ctx, true),
                const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
                    _closeBusinessRoute(ctx, true),
              },
              child: AlertDialog(
                backgroundColor: BookingTokens.surfaceDialog,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0x8832B9FF)),
                ),
                title: Text(
                  '选择预留卡台（已选 ${selected.length} 台）',
                  style: const TextStyle(color: BookingTokens.textPrimary),
                ),
                content: SizedBox(
                  width: isPhone ? media.width * 0.9 : 680,
                  height: isPhone ? media.height * 0.65 : 460,
                  child: BookingSeatPickerGrid(
                    regions: widget.snapshot.regions,
                    tables: scopedTables,
                    currentSeatId: widget.table.id,
                    selectedIds: selected,
                    multiSelect: true,
                    onToggleSeat: (seat) {
                      setPickerState(() {
                        if (selected.contains(seat.id)) {
                          selected.remove(seat.id);
                        } else {
                          selected.add(seat.id);
                        }
                      });
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => _closeBusinessRoute(ctx, false),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: () => _closeBusinessRoute(ctx, true),
                    child: const Text('确定'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _extraSeatIds
          ..clear()
          ..addAll(selected);
      });
    }
  }
}

final class _TurnoverSalesDialog extends StatefulWidget {
  const _TurnoverSalesDialog({
    required this.table,
    required this.snapshot,
    required this.onLoadTurnoverSales,
    required this.onChangeTurnoverSales,
    required this.onShowSnack,
  });

  final CardTable table;
  final CardTableSnapshot snapshot;
  final Future<Result<List<TurnoverSaleHistoryItem>>> Function(String seatId)?
  onLoadTurnoverSales;
  final Future<Result<void>> Function({
    required String seatId,
    required String csmId,
    required String salesEmpId,
    String secondSalesEmpId,
    required String reason,
  })?
  onChangeTurnoverSales;
  final void Function(String message) onShowSnack;

  @override
  State<_TurnoverSalesDialog> createState() => _TurnoverSalesDialogState();
}

final class _TurnoverSalesDialogState extends State<_TurnoverSalesDialog> {
  int _subStatus = 1;
  bool _loading = true;
  List<TurnoverSaleHistoryItem> _items = const [];
  TurnoverSaleHistoryItem? _selectedItem;

  String? _newSalesId;
  String? _newSecondSalesId;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.onLoadTurnoverSales == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final res = await widget.onLoadTurnoverSales!(widget.table.id);
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      widget.onShowSnack(f.safeMessage);
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _items = res.valueOrNull ?? const [];
      _loading = false;
    });
  }

  void _startEdit(TurnoverSaleHistoryItem item) {
    setState(() {
      _selectedItem = item;
      _subStatus = 2;
      _newSalesId = item.salesEmpId.isNotEmpty ? item.salesEmpId : null;
      _newSecondSalesId = item.secondSalesEmpId.isNotEmpty
          ? item.secondSalesEmpId
          : null;
      _reasonController.clear();
    });
  }

  Future<void> _submitChange() async {
    final item = _selectedItem;
    if (item == null) return;
    final salesId = _newSalesId?.trim() ?? '';
    if (salesId.isEmpty) {
      widget.onShowSnack('请选择订位人！');
      return;
    }
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      widget.onShowSnack('请输入修改理由！');
      return;
    }
    if (widget.onChangeTurnoverSales == null) {
      widget.onShowSnack('未接入修改翻台订位人接口');
      return;
    }
    final res = await widget.onChangeTurnoverSales!(
      seatId: widget.table.id,
      csmId: item.id,
      salesEmpId: salesId,
      secondSalesEmpId: _newSecondSalesId ?? '',
      reason: reason,
    );
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      widget.onShowSnack(f.safeMessage);
      return;
    }
    widget.onShowSnack('修改成功！');
    _closeBusinessRoute(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_subStatus == 2) {
      return _buildEditForm(context);
    }
    return _buildHistoryTable(context);
  }

  Widget _buildHistoryTable(BuildContext context) {
    return Theme(
      data: BookingTheme.dark(),
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              _closeBusinessRoute(context),
        },
        child: AlertDialog(
          backgroundColor: BookingTokens.surfaceDialog,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x8832B9FF)),
          ),
          title: Text('修改翻台订位人 - ${widget.table.name}'),
          content: SizedBox(
            width: 850,
            height: 420,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? const Center(child: Text('暂无数据'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('序号')),
                          DataColumn(label: Text('卡台')),
                          DataColumn(label: Text('预定时间')),
                          DataColumn(label: Text('开台时间')),
                          DataColumn(label: Text('订位人')),
                          DataColumn(label: Text('联系方式')),
                          DataColumn(label: Text('联合订位人')),
                          DataColumn(label: Text('联合联系方式')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: [
                          for (int i = 0; i < _items.length; i++) ...[
                            _buildRow(i, _items[i]),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => _closeBusinessRoute(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(int index, TurnoverSaleHistoryItem item) {
    final sales = _CardTableScreenState._employeeNamed(
      widget.snapshot,
      item.salesEmpId,
    );
    final second = _CardTableScreenState._employeeNamed(
      widget.snapshot,
      item.secondSalesEmpId,
    );
    return DataRow(
      cells: [
        DataCell(Text('${index + 1}')),
        DataCell(Text(widget.table.name)),
        DataCell(Text(item.bookTime.isEmpty ? '---' : item.bookTime)),
        DataCell(Text(item.openTime.isEmpty ? '---' : item.openTime)),
        DataCell(Text(sales?.name ?? '---')),
        DataCell(Text(sales?.phone.isEmpty ?? true ? '---' : sales!.phone)),
        DataCell(Text(second?.name ?? '---')),
        DataCell(Text(second?.phone.isEmpty ?? true ? '---' : second!.phone)),
        DataCell(
          TextButton(
            onPressed: () => _startEdit(item),
            child: const Text('修改订位人'),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(BuildContext context) {
    final item = _selectedItem;
    return Theme(
      data: BookingTheme.dark(),
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              setState(() => _subStatus = 1),
          const SingleActivator(LogicalKeyboardKey.enter): _submitChange,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _submitChange,
        },
        child: AlertDialog(
          backgroundColor: BookingTokens.surfaceDialog,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x8832B9FF)),
          ),
          title: const Text('修改翻台订位人'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('台号：${widget.table.name}'),
                  const SizedBox(height: 8),
                  Text(
                    '预定时间：${item?.bookTime.isEmpty ?? true ? '---' : item!.bookTime}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '开台时间：${item?.openTime.isEmpty ?? true ? '---' : item!.openTime}',
                  ),
                  const SizedBox(height: 16),
                  BookingEmployeePickerField(
                    label: '* 订位人',
                    employees: widget.snapshot.employees,
                    departments: widget.snapshot.departments,
                    selectedId: _newSalesId,
                    allowClear: false,
                    onChanged: (val) => setState(() => _newSalesId = val),
                  ),
                  const SizedBox(height: 16),
                  BookingEmployeePickerField(
                    label: '联合订位人',
                    employees: widget.snapshot.employees,
                    departments: widget.snapshot.departments,
                    selectedId: _newSecondSalesId,
                    onChanged: (val) => setState(
                      () => _newSecondSalesId = val.isEmpty ? null : val,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: '* 修改理由',
                      hintText: '请输入修改理由',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => setState(() => _subStatus = 1),
              child: const Text('取消'),
            ),
            FilledButton(onPressed: _submitChange, child: const Text('确认')),
          ],
        ),
      ),
    );
  }
}

final class _TurnbackDialog extends StatefulWidget {
  const _TurnbackDialog({
    required this.table,
    required this.onLoadTurnbackList,
    required this.onConfirmTurnback,
    required this.onShowSnack,
  });

  final CardTable table;
  final Future<Result<List<SeatTurnbackItem>>> Function(String seatId)?
  onLoadTurnbackList;
  final Future<Result<void>> Function(String csmId)? onConfirmTurnback;
  final void Function(String message) onShowSnack;

  @override
  State<_TurnbackDialog> createState() => _TurnbackDialogState();
}

final class _TurnbackDialogState extends State<_TurnbackDialog> {
  bool _loading = true;
  List<SeatTurnbackItem> _items = const [];
  String? _selectedCsmId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.onLoadTurnbackList == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final res = await widget.onLoadTurnbackList!(widget.table.id);
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      widget.onShowSnack(f.safeMessage);
      setState(() => _loading = false);
      return;
    }
    final list = (res.valueOrNull ?? const []).toList();
    list.sort((a, b) => b.openTime.compareTo(a.openTime));
    setState(() {
      _items = list;
      if (list.isNotEmpty) {
        _selectedCsmId = list.first.id;
      }
      _loading = false;
    });
  }

  Future<void> _confirm() async {
    final csmId = _selectedCsmId;
    if (csmId == null || csmId.isEmpty) {
      widget.onShowSnack('请选择要复台的流水');
      return;
    }
    if (widget.onConfirmTurnback == null) {
      widget.onShowSnack('未接入复台接口');
      return;
    }
    final res = await widget.onConfirmTurnback!(csmId);
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      widget.onShowSnack(f.safeMessage);
      return;
    }
    widget.onShowSnack('复台成功');
    _closeBusinessRoute(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: BookingTheme.dark(),
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              _closeBusinessRoute(context),
          const SingleActivator(LogicalKeyboardKey.enter): _confirm,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _confirm,
        },
        child: AlertDialog(
          backgroundColor: BookingTokens.surfaceDialog,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x8832B9FF)),
          ),
          title: Text('复台 - ${widget.table.name}'),
          content: SizedBox(
            width: 500,
            height: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '* 请选择要复台的流水：',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _items.isEmpty
                      ? const Center(child: Text('暂无可复台流水'))
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final item = _items[idx];
                            return ListTile(
                              leading: Radio<String>(
                                value: item.id,
                                groupValue: _selectedCsmId,
                                onChanged: (val) =>
                                    setState(() => _selectedCsmId = val),
                              ),
                              title: Text('开台时间：${item.openTime}'),
                              subtitle: Text('订位人：${item.salesPerson}'),
                              onTap: () =>
                                  setState(() => _selectedCsmId = item.id),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _closeBusinessRoute(context),
              child: const Text('取消'),
            ),
            FilledButton(onPressed: _confirm, child: const Text('确定')),
          ],
        ),
      ),
    );
  }
}

final class _BookingOrderDetailDialog extends StatefulWidget {
  const _BookingOrderDetailDialog({
    required this.table,
    required this.snapshot,
    required this.mode,
    required this.onLoadOrderDetail,
    required this.onShowSnack,
  });

  final CardTable table;
  final CardTableSnapshot snapshot;
  final String mode;
  final Future<Result<BookingOrderDetailData>> Function({
    required String seatId,
    required int turnoverCount,
  })?
  onLoadOrderDetail;
  final void Function(String message) onShowSnack;

  @override
  State<_BookingOrderDetailDialog> createState() =>
      _BookingOrderDetailDialogState();
}

final class _BookingOrderDetailDialogState
    extends State<_BookingOrderDetailDialog> {
  late final List<BookingTurnoverTab> _tabs;
  late int _selectedTurnover;
  bool _loading = true;
  BookingOrderDetailData _detail = const BookingOrderDetailData();

  @override
  void initState() {
    super.initState();
    _tabs = BookingDetailAccess.buildTurnoverTabs(
      widget.table.name,
      widget.table.turnoverCount,
      status: widget.table.businessStatus,
    );
    _selectedTurnover = _tabs.first.turnoverCount;
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.onLoadOrderDetail == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final res = await widget.onLoadOrderDetail!(
      seatId: widget.table.id,
      turnoverCount: _selectedTurnover,
    );
    if (!mounted) return;
    if (res.failureOrNull case final f?) {
      widget.onShowSnack(f.safeMessage);
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _detail = res.valueOrNull ?? const BookingOrderDetailData();
      _loading = false;
    });
  }

  void _onSelectTab(int turnoverCount) {
    if (_selectedTurnover == turnoverCount) return;
    setState(() => _selectedTurnover = turnoverCount);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == 'wine' ? '查看存取酒明细' : '查看消费明细';
    final isPhone = BookingViewportTier.of(context).isPhone;
    return Theme(
      data: BookingTheme.dark(),
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              _closeBusinessRoute(context),
        },
        child: AlertDialog(
          backgroundColor: BookingTokens.surfaceDialog,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x8832B9FF)),
          ),
          title: Text('$title - ${widget.table.name}'),
          content: SizedBox(
            width: isPhone ? double.maxFinite : 860,
            height: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final t in _tabs) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(t.label),
                            selected: _selectedTurnover == t.turnoverCount,
                            onSelected: (_) => _onSelectTab(t.turnoverCount),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.mode == 'consumption') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: BookingTokens.surfaceFooter,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: BookingTokens.tableBorder),
                    ),
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceAround,
                      children: [
                        Text(
                          '总消费：¥${_detail.totalAmount}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '优惠金额：¥${_detail.discountAmount}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '待支付：¥${_detail.unpaidAmount}',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : widget.mode == 'consumption'
                      ? _buildConsumptionTable()
                      : _buildWineOpsTable(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _closeBusinessRoute(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionTable() {
    if (_detail.consumptionRows.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('状态')),
            DataColumn(label: Text('名称')),
            DataColumn(label: Text('数量')),
            DataColumn(label: Text('单价(元)')),
            DataColumn(label: Text('小计(元)')),
            DataColumn(label: Text('服务员')),
            DataColumn(label: Text('点单时间')),
          ],
          rows: [
            for (final r in _detail.consumptionRows)
              DataRow(
                cells: [
                  DataCell(_buildStatusBadge(r)),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(r.productName),
                        for (final sub in r.packageItems)
                          Text(
                            '  └ $sub',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  DataCell(Text('${r.count}')),
                  DataCell(Text(r.price)),
                  DataCell(Text(r.subtotal)),
                  DataCell(Text(r.waiterName)),
                  DataCell(Text(r.orderTime)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingConsumptionRow r) {
    if (r.isReturned) {
      return const _BadgeWidget(text: '退', color: Colors.red);
    }
    if (r.discountType == 2 || r.discountType == 3) {
      return const _BadgeWidget(text: '惠', color: Colors.orange);
    }
    if (r.isSettled) {
      return const _BadgeWidget(text: '结', color: Colors.green);
    }
    return const SizedBox.shrink();
  }

  Widget _buildWineOpsTable() {
    if (_detail.wineRows.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('类型')),
            DataColumn(label: Text('名称')),
            DataColumn(label: Text('规格')),
            DataColumn(label: Text('数量')),
            DataColumn(label: Text('存/取酒操作人')),
            DataColumn(label: Text('存/取酒操作时间')),
          ],
          rows: [
            for (final r in _detail.wineRows)
              DataRow(
                cells: [
                  DataCell(
                    _BadgeWidget(
                      text: r.type == 1 ? '存' : '取',
                      color: r.type == 1 ? Colors.blue : Colors.deepOrange,
                    ),
                  ),
                  DataCell(Text(r.productName)),
                  DataCell(Text(r.spec.isEmpty ? '---' : r.spec)),
                  DataCell(Text(r.count)),
                  DataCell(
                    Text(r.operatorName.isEmpty ? '---' : r.operatorName),
                  ),
                  DataCell(Text(r.operateTime.isEmpty ? '---' : r.operateTime)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

final class _BadgeWidget extends StatelessWidget {
  const _BadgeWidget({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
