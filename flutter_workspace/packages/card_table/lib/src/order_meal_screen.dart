import 'dart:async';

import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/fc_price.dart';
import 'package:card_table/src/order_card_display.dart';
import 'package:card_table/src/qr_code_pane.dart';
import 'package:card_table/src/order_meal.dart';
import 'package:card_table/src/order_set_catalog.dart';
import 'package:card_table/src/order_set_selection.dart';
import 'package:card_table/src/order_set_dialog.dart';
import 'package:card_table/src/order_refund.dart';
import 'package:card_table/src/order_refund_dialog.dart';
import 'package:card_table/src/pay_order_models.dart';
import 'package:card_table/src/sold_out_products.dart';
import 'package:card_table/src/product_pricing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:foundation/foundation.dart';

typedef OrderMealAddProduct = Future<Result<void>> Function({
  required String seatId,
  required String productId,
  required int count,
  required String price,
  String amount,
});

typedef OrderMealCartCount = Future<Result<int>> Function(String seatId);

typedef OrderMealCartItems = Future<Result<List<OrderCartItem>>> Function(
  String seatId,
);

typedef OrderMealSetCartCount = Future<Result<void>> Function({
  required String seatId,
  required String itemId,
  required int count,
});

typedef OrderMealBindWaiter = Future<Result<void>> Function(String seatId);

typedef OrderMealSearchGuests = Future<Result<List<OrderGuestHit>>> Function(
  String phone,
);

typedef OrderMealBindGuest = Future<Result<void>> Function({
  required String seatId,
  required String phone,
});

typedef OrderMealListOrders = Future<Result<List<OrderPlacedItem>>> Function({
  required String seatId,
  required int turnoverCount,
});

typedef OrderMealLoadOrderDetails = Future<Result<OrderPlacedData>> Function({
  required String seatId,
  required int turnoverCount,
});

typedef OrderMealPlaceOrder = Future<Result<void>> Function({
  required String seatId,
  required List<String> cartItemIds,
});

typedef OrderMealAddTimed = Future<Result<void>> Function({
  required String seatId,
  required String productId,
  required int count,
  required String amount,
});

typedef OrderMealAddSet = Future<Result<void>> Function({
  required String seatId,
  required String productId,
  required int count,
  required int priceFen,
  required List<String> groupIds,
  required List<String> detailProductIds,
  required List<int> detailCounts,
  required List<int> selectCounts,
  List<String> requirements,
});

typedef OrderMealRefund = Future<Result<void>> Function({
  required String seatId,
  required String orderId,
  required int count,
  required String amount,
  required String remark,
  required bool online,
  String authEmpCode,
  String authEmpPasswd,
  int passType,
});

typedef OrderMealConvertYh = Future<Result<void>> Function({
  required String seatId,
  required List<String> cartItemIds,
  required List<int> counts,
  required String reason,
});

typedef OrderMealAddYh = Future<Result<void>> Function({
  required String seatId,
  required String productId,
  required int count,
  required String amount,
  required String price,
  required String reason,
});

typedef OrderMealAddYh2 = Future<Result<void>> Function({
  required String seatId,
  required String productId,
  required int count,
  required String salesEmpId,
  required String yh2SeatId,
});

typedef OrderMealAddRequirement = Future<Result<void>> Function({
  required String seatId,
  required String itemId,
  required String requirement,
});

typedef OrderMealChangeSetDetail = Future<Result<void>> Function({
  required String seatId,
  required String itemId,
  required String groupId,
  required String detailProductId,
  required List<String> destDetailProductIds,
  required List<int> destSelectCounts,
  required String requirement,
  required List<String> destRequirements,
});

typedef OrderMealConvertYh2 = Future<Result<void>> Function({
  required String seatId,
  required List<String> cartItemIds,
  required List<int> counts,
  required String salesEmpId,
  required String yh2SeatId,
});

typedef OrderMealGiftOrdered = Future<Result<void>> Function({
  required String seatId,
  required List<String> orderIds,
  required List<int> counts,
  required String reason,
});

typedef OrderMealChangeOrderedSet = Future<Result<void>> Function({
  required String seatId,
  required String orderId,
  required String orderDetailId,
  required List<String> destDetailProductIds,
  required List<int> destSelectCounts,
  required List<String> destRequirements,
  String authEmpCode,
  String authEmpPasswd,
  int passType,
});

typedef OrderMealConvertOrderYh2 = Future<Result<void>> Function({
  required String seatId,
  required List<String> orderIds,
  required List<int> counts,
  required String salesEmpId,
  required String yh2SeatId,
});

typedef OrderMealReprintKitchen = Future<Result<void>> Function(String orderId);

typedef OrderMealPrintBill = Future<Result<void>> Function({
  required String seatId,
  required bool unpaid,
  required bool includeHl,
});

typedef OrderMealCleanSeat = Future<Result<void>> Function(String seatId);

typedef OrderMealMergeYh2 = Future<Result<void>> Function({
  required String seatId,
  required List<String> orderIds,
  required String destSeatId,
});

typedef OrderMealWaiterTodos = Future<Result<List<OrderPlacedItem>>> Function(
  String seatId,
);

typedef OrderMealCreateWaiterPay = Future<Result<WaiterPayQr>> Function({
  required String seatId,
  required int payType,
  required List<String> orderIds,
});

typedef OrderMealRedeemCoupon = Future<Result<void>> Function(String authCode);

final class OrderMealScreen extends StatefulWidget {
  const OrderMealScreen({
    required this.table,
    required this.catalog,
    required this.addProduct,
    this.fcPriceCatalog = FcPriceCatalog.unknown,
    this.fcPrices,
    this.productQuoteFor,
    this.productPricingChanges,
    this.pricingContext,
    this.showOrderSummary = false,
    this.orderSummaryVisibility,
    this.showFooterAmounts = false,
    this.footerAmountsVisibility,
    this.liveTableAmounts,
    this.operationContext,
    this.productTypeFor,
    this.isCashier = false,
    this.refundContext,
    this.remaining = const <String, int>{},
    this.cartCount = 0,
    this.loadRemaining,
    this.loadCartCount,
    this.loadCartItems,
    this.setCartCount,
    this.bindGuestEnabled = false,
    this.salesLabel = '',
    this.userName,
    this.employeeId,
    this.moduleIds = const <int>{},
    this.currentModuleIds,
    this.bindWaiter,
    this.searchGuests,
    this.bindGuest,
    this.loadOrders,
    this.loadOrderDetails,
    this.placeOrder,
    this.addTimed,
    this.addSet,
    this.setDetails = const [],
    this.currentSetCatalog,
    this.refundOrder,
    this.refundReasons = const [],
    this.convertCartToYh,
    this.yhReasons = const [],
    this.addYh,
    this.addYh2,
    this.addRequirement,
    this.changeSetDetail,
    this.convertCartToYh2,
    this.giftOrdered,
    this.changeOrderedSet,
    this.convertOrderToYh2,
    this.reprintKitchen,
    this.printBill,
    this.cleanSeat,
    this.mergeYh2,
    this.waiterTodoOrders,
    this.createWaiterPay,
    this.redeemCoupon,
    this.onOpenVipRecharge,
    this.onOpenLateDeposit,
    this.onTransferSeat,
    super.key,
  });

  static const Key searchKey = Key('order-meal-search');
  static const Key countKey = Key('order-meal-count');
  static const Key cartTabKey = Key('order-meal-cart-tab');
  static const Key myOrderTabKey = Key('order-meal-my-order-tab');
  static const Key bindGuestKey = Key('order-meal-bind-guest');
  static const Key bindWaiterKey = Key('order-meal-bind-waiter');
  static const Key moreKey = Key('order-meal-more');
  static const Key waiterQrKey = Key('order-meal-waiter-qr');
  static const Key placeOrderKey = Key('order-meal-place-order');
  static const Key amountKey = Key('order-meal-amount');
  static const Key chosenTabKey = Key('order-meal-chosen-tab');
  static const Key requirementKey = Key('order-meal-requirement');
  static const Key redeemFieldKey = Key('order-meal-redeem');
  static const Key yh2SalesKey = Key('order-meal-yh2-sales');
  static const Key yh2SeatKey = Key('order-meal-yh2-seat');

  final CardTable table;
  final SoldOutProductCatalog catalog;
  final FcPriceCatalog fcPriceCatalog;
  final ValueListenable<FcPriceCatalog>? fcPrices;
  final ProductPriceQuote? Function(String productId)? productQuoteFor;
  final Listenable? productPricingChanges;

  /// Explicit isolated context; production uses a live quote provider instead.
  final ProductPricingContext? pricingContext;
  final bool showOrderSummary;
  final ValueListenable<bool>? orderSummaryVisibility;
  final bool showFooterAmounts;
  final ValueListenable<bool>? footerAmountsVisibility;
  final ValueListenable<CardTable?>? liveTableAmounts;
  final ValueListenable<Object?>? operationContext;
  final int? Function(String productId)? productTypeFor;
  final bool isCashier;
  final ValueListenable<Object?>? refundContext;
  final Map<String, int> remaining;
  final int cartCount;
  final OrderMealAddProduct addProduct;
  final Future<Result<Map<String, int>>> Function()? loadRemaining;
  final OrderMealCartCount? loadCartCount;
  final OrderMealCartItems? loadCartItems;
  final OrderMealSetCartCount? setCartCount;
  final bool bindGuestEnabled;
  final String salesLabel;
  final String? userName;
  final String? employeeId;
  final Set<int> moduleIds;
  final Set<int> Function()? currentModuleIds;
  final OrderMealBindWaiter? bindWaiter;
  final OrderMealSearchGuests? searchGuests;
  final OrderMealBindGuest? bindGuest;
  final OrderMealListOrders? loadOrders;
  final OrderMealLoadOrderDetails? loadOrderDetails;
  final OrderMealPlaceOrder? placeOrder;
  final OrderMealAddTimed? addTimed;
  final OrderMealAddSet? addSet;
  final List<OrderSetDetail> setDetails;
  final OrderSetCatalog Function()? currentSetCatalog;
  final OrderMealRefund? refundOrder;
  final List<String> refundReasons;
  final OrderMealConvertYh? convertCartToYh;
  final List<String> yhReasons;
  final OrderMealAddYh? addYh;
  final OrderMealAddYh2? addYh2;
  final OrderMealAddRequirement? addRequirement;
  final OrderMealChangeSetDetail? changeSetDetail;
  final OrderMealConvertYh2? convertCartToYh2;
  final OrderMealGiftOrdered? giftOrdered;
  final OrderMealChangeOrderedSet? changeOrderedSet;
  final OrderMealConvertOrderYh2? convertOrderToYh2;
  final OrderMealReprintKitchen? reprintKitchen;
  final OrderMealPrintBill? printBill;
  final OrderMealCleanSeat? cleanSeat;
  final OrderMealMergeYh2? mergeYh2;
  final OrderMealWaiterTodos? waiterTodoOrders;
  final OrderMealCreateWaiterPay? createWaiterPay;
  final OrderMealRedeemCoupon? redeemCoupon;
  final Future<void> Function()? onOpenVipRecharge;
  final Future<void> Function()? onOpenLateDeposit;
  final Future<void> Function()? onTransferSeat;

  @override
  State<OrderMealScreen> createState() => _OrderMealScreenState();
}

final class _OrderMealScreenState extends State<OrderMealScreen> {
  late Map<String, int> _remaining = Map<String, int>.of(widget.remaining);
  late int _cartCount = widget.cartCount;
  List<OrderCartItem> _items = const [];
  List<OrderPlacedItem> _orders = const [];
  OrderSummary? _orderSummary;
  int _orderReadVersion = 0;
  int _operationGeneration = 0;
  Object? _busyOwner;
  DialogRoute<void>? _waiterPayDialog;
  Timer? _waiterPayExpiry;

  void _closeWaiterPayDialog() {
    _waiterPayExpiry?.cancel();
    _waiterPayExpiry = null;
    final route = _waiterPayDialog;
    _waiterPayDialog = null;
    if (route == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (route.isActive) route.navigator?.removeRoute(route);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _operationChanged() {
    _operationGeneration++;
    _closeWaiterPayDialog();
    if (mounted) setState(() {});
  }

  int? _beginOperation() {
    if (_busy) return null;
    if (!mounted || widget.operationContext?.value == null) {
      if (mounted) _show('当前卡台操作上下文未就绪或已失效，请返回重新打开');
      return null;
    }
    return _operationGeneration;
  }

  bool _acquireBusy(Object owner) {
    if (!mounted || (_busyOwner != null && !identical(_busyOwner, owner))) {
      return false;
    }
    _busyOwner = owner;
    setState(() => _busy = true);
    return true;
  }

  void _releaseBusy(Object owner) {
    if (!identical(_busyOwner, owner)) return;
    _busyOwner = null;
    if (mounted) setState(() => _busy = false);
  }

  bool _operationCurrent(int generation) =>
      mounted &&
      generation == _operationGeneration &&
      widget.operationContext?.value != null;
  String _keyword = '';
  String? _firstId;
  String? _secondId;
  bool _busy = false;
  int _tab = 0;
  bool _waiterBound = false;
  String _guestLabel = '';

  @override
  void initState() {
    super.initState();
    widget.fcPrices?.addListener(_pricesChanged);
    widget.productPricingChanges?.addListener(_pricesChanged);
    widget.orderSummaryVisibility?.addListener(_pricesChanged);
    widget.footerAmountsVisibility?.addListener(_pricesChanged);
    widget.liveTableAmounts?.addListener(_pricesChanged);
    widget.operationContext?.addListener(_operationChanged);
    final firsts = widget.catalog.firstCategories;
    if (firsts.isNotEmpty) {
      _firstId = firsts.first.id;
      final seconds = widget.catalog.secondsOf(_firstId!);
      if (seconds.isNotEmpty) _secondId = seconds.first.id;
    }
    _waiterBound = widget.table.waiterEmployeeId.isNotEmpty;
    _guestLabel = widget.table.boundCustomerName;
    unawaited(_load());
  }

  void _pricesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant OrderMealScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(
      oldWidget.productPricingChanges,
      widget.productPricingChanges,
    )) {
      oldWidget.productPricingChanges?.removeListener(_pricesChanged);
      widget.productPricingChanges?.addListener(_pricesChanged);
    }
    if (!identical(oldWidget.operationContext, widget.operationContext)) {
      oldWidget.operationContext?.removeListener(_operationChanged);
      widget.operationContext?.addListener(_operationChanged);
      _operationGeneration++;
      _closeWaiterPayDialog();
    }
    if (oldWidget.table.id != widget.table.id ||
        oldWidget.table.turnoverCount != widget.table.turnoverCount ||
        oldWidget.employeeId != widget.employeeId ||
        oldWidget.isCashier != widget.isCashier) {
      _operationGeneration++;
      _closeWaiterPayDialog();
    }
    if (!identical(oldWidget.liveTableAmounts, widget.liveTableAmounts)) {
      oldWidget.liveTableAmounts?.removeListener(_pricesChanged);
      widget.liveTableAmounts?.addListener(_pricesChanged);
    }
    if (!identical(
      oldWidget.footerAmountsVisibility,
      widget.footerAmountsVisibility,
    )) {
      oldWidget.footerAmountsVisibility?.removeListener(_pricesChanged);
      widget.footerAmountsVisibility?.addListener(_pricesChanged);
    }
    if (!identical(
      oldWidget.orderSummaryVisibility,
      widget.orderSummaryVisibility,
    )) {
      oldWidget.orderSummaryVisibility?.removeListener(_pricesChanged);
      widget.orderSummaryVisibility?.addListener(_pricesChanged);
    }
    if (!identical(oldWidget.fcPrices, widget.fcPrices)) {
      oldWidget.fcPrices?.removeListener(_pricesChanged);
      widget.fcPrices?.addListener(_pricesChanged);
    }
  }

  @override
  void dispose() {
    _operationGeneration++;
    _closeWaiterPayDialog();
    widget.operationContext?.removeListener(_operationChanged);
    widget.fcPrices?.removeListener(_pricesChanged);
    widget.productPricingChanges?.removeListener(_pricesChanged);
    widget.orderSummaryVisibility?.removeListener(_pricesChanged);
    widget.footerAmountsVisibility?.removeListener(_pricesChanged);
    widget.liveTableAmounts?.removeListener(_pricesChanged);
    super.dispose();
  }

  FcPriceCatalog get _prices => widget.fcPrices?.value ?? widget.fcPriceCatalog;
  ProductPriceQuote? _quote(SoldOutProduct product) {
    try {
      if (widget.productQuoteFor case final quote?) return quote(product.id);
      if (widget.pricingContext case final context?) {
        return quoteProductPrice(product, context: context);
      }
    } on Object {
      return null;
    }
    return null;
  }

  String? _actualProductPrice(SoldOutProduct product) {
    final scheme = _schemePrice(product);
    if (scheme != null) return scheme.toStringAsFixed(2);
    // Preserve the existing manual-amount protocol for time-priced products.
    if (const {3, 4, 5}.contains(product.prdType)) return product.price;
    final price = _quote(product)?.actualPrice;
    final value = price == null ? null : double.tryParse(price);
    return value != null && value.isFinite && value >= 0 ? price : null;
  }

  bool _pricesReady() {
    if (_prices.known) return true;
    _show('价格方案尚未同步，请稍后再添加商品');
    return false;
  }

  double? _schemePrice(SoldOutProduct product) => product.prdType == 2
      ? null // Vue groupProduct uses add_set without fcApplyPrice.
      : _prices.resolve(
          productId: product.id,
          orderEmployeeId: widget.employeeId,
        );

  Future<void> _load() async {
    final readOperation = _operationGeneration;
    final remaining = widget.loadRemaining;
    if (remaining != null) {
      final result = await remaining();
      if (!mounted || readOperation != _operationGeneration) return;
      if (result.valueOrNull != null) {
        setState(() => _remaining = Map<String, int>.of(result.valueOrNull!));
      }
    }
    await _reloadCart();
  }

  Future<void> _reloadCart() async {
    final readOperation = _operationGeneration;
    final cartCount = widget.loadCartCount;
    if (cartCount != null) {
      final result = await cartCount(widget.table.id);
      if (!mounted || readOperation != _operationGeneration) return;
      if (result.valueOrNull != null) {
        setState(() => _cartCount = result.valueOrNull!);
      }
    }
    final items = widget.loadCartItems;
    if (items != null) {
      final result = await items(widget.table.id);
      if (!mounted || readOperation != _operationGeneration) return;
      if (result.valueOrNull != null) {
        setState(() => _items = result.valueOrNull!);
      }
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        content: Text(message),
      ),
    );
  }

  ({bool known, int? count}) _productRemaining(SoldOutProduct product) {
    final getCatalog = widget.currentSetCatalog;
    if (product.prdType != 2 || getCatalog == null) {
      return (known: true, count: _remaining[product.id]);
    }
    try {
      final catalog = getCatalog();
      final limits = catalog.saleLimits;
      final configuration = catalog.configurationFor(product.id);
      if (limits == null || !configuration.known) {
        return (known: false, count: null);
      }
      int? count = limits[product.id];
      final fixedNeeds = <String, int>{};
      for (final detail in configuration.details.where((d) => d.fixed)) {
        if (detail.detailCount <= 0) return (known: false, count: null);
        fixedNeeds.update(
          detail.detailProductId,
          (quantity) => quantity + detail.detailCount,
          ifAbsent: () => detail.detailCount,
        );
      }
      for (final entry in fixedNeeds.entries) {
        final available = limits[entry.key];
        if (available == null) continue;
        final packages = available ~/ entry.value;
        if (count == null || packages < count) count = packages;
      }
      return (known: true, count: count);
    } on Object {
      return (known: false, count: null);
    }
  }

  bool _soldOut(SoldOutProduct product) {
    final remaining = _productRemaining(product);
    return !remaining.known || remaining.count == 0;
  }

  bool _regular(SoldOutProduct product) =>
      product.prdType != 2 &&
      product.prdType != 3 &&
      product.prdType != 4 &&
      product.prdType != 5 &&
      product.prdType != 8 &&
      product.prdType != 13 &&
      product.prdType != 14;

  bool _needsAmount(SoldOutProduct product) =>
      product.prdType == 3 ||
      product.prdType == 4 ||
      product.prdType == 5 ||
      product.prdType == 8;

  bool _timed(SoldOutProduct product) =>
      product.prdType == 3 ||
      product.prdType == 4 ||
      product.prdType == 8 ||
      product.prdType == 13 ||
      product.prdType == 14;

  int _ordered(String productId) {
    var total = 0;
    for (final item in _items) {
      if (item.productId == productId) total += item.count;
    }
    return total;
  }

  String _productName(String productId) {
    for (final product in widget.catalog.products) {
      if (product.id == productId) return product.name;
    }
    return productId;
  }

  Future<void> _openProduct(SoldOutProduct product) async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      if (_soldOut(product)) {
        _show('当前商品已售罄');
        return;
      }
      if (product.prdType == 2) {
        await _addSet(product);
        return;
      }
      if (!_pricesReady()) return;
      if (_timed(product) || product.prdType == 5) {
        await _addSpecial(product);
        return;
      }
      if (!_regular(product)) {
        _show('时价商品加购尚未接入');
        return;
      }
      final count = await showDialog<int>(
        context: context,
        builder: (context) => _QuantityDialog(product: product),
      );
      if (count == null || !_operationCurrent(operation)) return;
      await _add(product, count);
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Future<void> _addSpecial(SoldOutProduct product) async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      final result = await showDialog<({int count, String amount})>(
        context: context,
        builder: (context) => _AmountDialog(
          product: product,
          requireAmount:
              product.prdType == 5 ||
              (_needsAmount(product) && _schemePrice(product) == null),
        ),
      );
      if (result == null || !_operationCurrent(operation)) return;
      if (!_pricesReady()) return;
      final scheme = _schemePrice(product);
      final amount = product.prdType == 5
          ? result.amount
          : [3, 4, 8].contains(product.prdType)
          ? (scheme == null
                ? result.amount
                : (scheme * result.count).toStringAsFixed(2))
          : '';
      if ((product.prdType == 5 || (_needsAmount(product) && scheme == null)) &&
          amount.isEmpty) {
        _show('请输入金额');
        return;
      }
      if (_timed(product)) {
        final addTimed = widget.addTimed;
        if (addTimed == null) {
          _show('时价商品加购尚未接入');
          return;
        }
        if (!_acquireBusy(busyOwner)) return;
        final posted = await addTimed(
          seatId: widget.table.id,
          productId: product.id,
          count: result.count,
          amount: amount,
        );
        if (!_operationCurrent(operation)) return;
        _releaseBusy(busyOwner);
        if (posted.failureOrNull != null) {
          _show(posted.failureOrNull!.safeMessage);
          return;
        }
        _show('加入购物车成功');
        await _reloadCart();
        return;
      }
      await _add(product, result.count, amount: amount);
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  static const _setContextFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'order_set.context_changed',
    safeMessage: '套餐操作已取消或上下文已变化，请重新打开',
  );
  static const _setChangedFailure = AppFailure(
    kind: FailureKind.business,
    code: 'order_set.source_changed',
    safeMessage: '原套餐明细或配置已变化，请刷新后重新选择',
  );
  OrderSetConfiguration _setConfiguration(String productId) {
    try {
      final catalog = widget.currentSetCatalog;
      if (catalog != null) return catalog().configurationFor(productId);
      return OrderSetConfiguration(
        known: true,
        details: widget.setDetails.where(
          (detail) => detail.productId == productId,
        ),
      );
    } on Object {
      return OrderSetConfiguration(
        known: false,
        unavailableReason: '套餐配置读取失败，请刷新',
      );
    }
  }

  Map<Object, int> _setConfigurationSnapshot(OrderSetConfiguration config) {
    final rows = <Object, int>{};
    void add(Object key) => rows.update(key, (n) => n + 1, ifAbsent: () => 1);
    for (final d in config.details) {
      add((
        d.productId,
        d.groupId,
        d.detailProductId,
        d.detailCount,
        d.groupSelectCount,
        d.typeId,
        d.seqId,
        d.templateResolved,
      ));
    }
    for (final entry in config.requirementsByProduct.entries) {
      for (final group in entry.value) {
        add((entry.key, group.id, group.name, group.modeType));
        for (final item in group.items) {
          add((entry.key, group.id, item.id, item.name));
        }
      }
    }
    return rows;
  }

  bool _sameSetConfiguration(
    OrderSetConfiguration a,
    OrderSetConfiguration b,
  ) =>
      a.known &&
      b.known &&
      mapEquals(_setConfigurationSnapshot(a), _setConfigurationSnapshot(b));
  bool _sameSetItem(OrderSetItem a, OrderSetItem b) =>
      a.id == b.id &&
      a.groupId == b.groupId &&
      a.detailProductId == b.detailProductId &&
      a.detailCount == b.detailCount &&
      a.selectCount == b.selectCount &&
      a.requirement == b.requirement;
  bool _setAttemptCurrent(int operation, bool Function() active) =>
      _operationCurrent(operation) && active();
  AppFailure? _validateSetSelection(
    OrderSetSelection selection,
    OrderSetConfiguration config,
  ) => OrderSetSelection(
    productId: selection.productId,
    candidates: config.details
        .where(
          (row) =>
              selection.replacing == null ||
              row.groupId == selection.replacing!.groupId,
        )
        .toList(),
    choices: selection.choices,
    count: selection.count,
    replacing: selection.replacing,
  ).validate();
  Future<AppFailure?> _checkSetInventory(
    OrderSetSelection selection,
    int parentCount,
    int operation,
    bool Function() active,
  ) async {
    Map<String, int> remaining;
    if (widget.currentSetCatalog != null) {
      return _checkLiveSetInventory(selection, parentCount);
    }
    if (widget.loadRemaining case final load?) {
      final result = await load();
      if (!_setAttemptCurrent(operation, active)) return _setContextFailure;
      if (result.failureOrNull case final failure?) return failure;
      final values = result.valueOrNull;
      if (values == null) {
        return const AppFailure(
          kind: FailureKind.protocol,
          code: 'order_set.remaining_unknown',
          safeMessage: '估清数量未知，无法确认套餐明细',
        );
      }
      remaining = values;
    } else {
      return const AppFailure(
        kind: FailureKind.business,
        code: 'order_set.remaining_unknown',
        safeMessage: '估清查询服务未连接，无法确认套餐明细数量',
      );
    }
    return _validateSetInventory(selection, parentCount, remaining);
  }

  AppFailure? _checkLiveSetInventory(
    OrderSetSelection selection,
    int parentCount,
  ) {
    final getCatalog = widget.currentSetCatalog;
    if (getCatalog == null) return null;
    try {
      return _validateSetInventory(
        selection,
        parentCount,
        getCatalog().saleLimits,
      );
    } on Object {
      return const AppFailure(
        kind: FailureKind.protocol,
        code: 'order_set.remaining_unknown',
        safeMessage: '套餐估清元数据不可用，请刷新',
      );
    }
  }

  AppFailure? _validateSetInventory(
    OrderSetSelection selection,
    int parentCount,
    Map<String, int>? remaining,
  ) {
    if (remaining == null) {
      return const AppFailure(
        kind: FailureKind.protocol,
        code: 'order_set.remaining_unknown',
        safeMessage: '套餐估清元数据未同步，请刷新后重试',
      );
    }
    final needed = <String, int>{};
    for (final choice in selection.choices) {
      needed.update(
        choice.detail.detailProductId,
        (count) =>
            count +
            choice.detail.detailCount * choice.selectCount * parentCount,
        ifAbsent: () =>
            choice.detail.detailCount * choice.selectCount * parentCount,
      );
    }
    for (final entry in needed.entries) {
      final available = remaining[entry.key];
      if (available != null && available < 0) {
        return const AppFailure(
          kind: FailureKind.protocol,
          code: 'order_set.remaining_invalid',
          safeMessage: '估清数据无效，请刷新',
        );
      }
      if (available != null && entry.value > available) {
        return const AppFailure(
          kind: FailureKind.business,
          code: 'order_set.remaining_exceeded',
          safeMessage: '套餐明细需求超过当前估清剩余数量，请重新选择',
        );
      }
    }
    return null;
  }

  Future<Result<void>> _runSetWrite(
    int operation,
    bool Function() active,
    Future<Result<void>> Function() run, {
    required OrderSetSelection selection,
    required int parentCount,
  }) async {
    if (!_setAttemptCurrent(operation, active)) {
      return const FailureResult(_setContextFailure);
    }
    final inventoryFailure = _checkLiveSetInventory(selection, parentCount);
    if (inventoryFailure != null) return FailureResult(inventoryFailure);
    final owner = Object();
    if (!_acquireBusy(owner)) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'order_set.busy',
          safeMessage: '其他请求仍在处理中，请稍后重试',
        ),
      );
    }
    try {
      final result = await run();
      return _setAttemptCurrent(operation, active)
          ? result
          : const FailureResult(_setContextFailure);
    } finally {
      _releaseBusy(owner);
    }
  }

  Future<void> _addSet(SoldOutProduct product) async {
    final operation = _beginOperation();
    if (operation == null) return;
    final config = _setConfiguration(product.id);
    if (!config.known || config.details.isEmpty || widget.addSet == null) {
      _show(config.unavailableReason ?? '套餐没有可用明细或服务未连接');
      return;
    }
    final success = await showDialog<bool>(
      context: context,
      builder: (_) => OrderSetDialog(
        productId: product.id,
        title: product.name,
        configuration: config,
        contextToken: widget.operationContext!,
        submit: (selection, code, password, passType, active) async {
          if (!_setAttemptCurrent(operation, active)) {
            return const FailureResult(_setContextFailure);
          }
          final fresh = _setConfiguration(product.id);
          if (!_sameSetConfiguration(config, fresh)) {
            return const FailureResult(_setChangedFailure);
          }
          final failure = _validateSetSelection(selection, fresh);
          if (failure != null) return FailureResult(failure);
          final inventoryFailure = await _checkSetInventory(
            selection,
            selection.count,
            operation,
            active,
          );
          if (inventoryFailure != null) return FailureResult(inventoryFailure);
          if (!_sameSetConfiguration(config, _setConfiguration(product.id))) {
            return const FailureResult(_setChangedFailure);
          }
          final actualPrice = _actualProductPrice(product);
          final price = actualPrice == null ? null : num.tryParse(actualPrice);
          if (price == null || !price.isFinite || price < 0) {
            return const FailureResult(_setChangedFailure);
          }
          return _runSetWrite(
            operation,
            active,
            () => widget.addSet!(
              seatId: widget.table.id,
              productId: product.id,
              count: selection.count,
              priceFen: (price * 100).round(),
              groupIds: selection.groupIds,
              detailProductIds: selection.detailProductIds,
              detailCounts: selection.detailCounts,
              selectCounts: selection.selectCounts,
              requirements: selection.requirements,
            ),
            selection: selection,
            parentCount: selection.count,
          );
        },
      ),
    );
    if (success != true || !_operationCurrent(operation)) return;
    _show('加入购物车成功');
    await _reloadCart();
  }

  Future<void> _refund(OrderPlacedItem item) async {
    final operation = _beginOperation();
    if (operation == null) return;
    if (item.paid || item.refunded) {
      _show('已付款的不支持退单');
      return;
    }
    if (widget.refundOrder == null) {
      _show('退单尚未接入');
      return;
    }
    final liveContext = widget.refundContext;
    final token = liveContext?.value;
    if (liveContext == null || token == null) {
      _show('当前登录或连接状态不可退单');
      return;
    }
    final productType = widget.productTypeFor?.call(item.productId);
    if (productType == null) {
      _show('商品类型未同步，无法确定退单规则');
      return;
    }
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => OrderRefundDialog(
        draft: OrderRefundDraft.fromOrder(
          order: item,
          productType: productType,
          isCashier: widget.isCashier,
        ),
        reasons: widget.refundReasons,
        contextToken: liveContext,
        submit: (draft, code, password, passType, isCurrentAttempt) async {
          if (!isCurrentAttempt() || !_operationCurrent(operation)) {
            return const FailureResult(
              AppFailure(
                kind: FailureKind.business,
                code: 'order_refund.cancelled',
                safeMessage: '退单已取消',
              ),
            );
          }
          if (!mounted || !identical(token, liveContext.value)) {
            return const FailureResult(
              AppFailure(
                kind: FailureKind.authentication,
                code: 'order_refund.context_changed',
                safeMessage: '登录或卡台状态已改变',
              ),
            );
          }
          if (widget.productTypeFor?.call(item.productId) !=
              draft.productType) {
            return const FailureResult(
              AppFailure(
                kind: FailureKind.business,
                code: 'order_refund.product_changed',
                safeMessage: '商品类型已变化，请刷新后重新退单',
              ),
            );
          }
          List<OrderPlacedItem>? latestOrders;
          AppFailure? readFailure;
          if (widget.loadOrderDetails case final load?) {
            final result = await load(
              seatId: widget.table.id,
              turnoverCount: widget.table.turnoverCount,
            );
            latestOrders = result.valueOrNull?.items;
            readFailure = result.failureOrNull;
          } else if (widget.loadOrders case final load?) {
            final result = await load(
              seatId: widget.table.id,
              turnoverCount: widget.table.turnoverCount,
            );
            latestOrders = result.valueOrNull;
            readFailure = result.failureOrNull;
          } else {
            return const FailureResult(
              AppFailure(
                kind: FailureKind.business,
                code: 'order_refund.recheck_unavailable',
                safeMessage: '订单复核服务未连接，无法退单',
              ),
            );
          }
          if (!isCurrentAttempt() || !_operationCurrent(operation)) {
            return const FailureResult(
              AppFailure(
                kind: FailureKind.business,
                code: 'order_refund.cancelled',
                safeMessage: '退单已取消',
              ),
            );
          }
          if (!mounted || !identical(token, liveContext.value)) {
            return const FailureResult(
              AppFailure(
                kind: FailureKind.authentication,
                code: 'order_refund.context_changed',
                safeMessage: '登录或卡台状态已改变',
              ),
            );
          }
          if (readFailure != null) return FailureResult(readFailure);
          final current = latestOrders
              ?.where(
                (order) => order.id == item.id && order.online == item.online,
              )
              .firstOrNull;
          if (widget.productTypeFor?.call(item.productId) !=
                  draft.productType ||
              current == null ||
              current.paid ||
              current.refunded ||
              current.productId != item.productId ||
              current.count != item.count ||
              current.status != item.status ||
              current.originalUnitPrice != item.originalUnitPrice ||
              current.recordedUnitPrice != item.recordedUnitPrice ||
              current.recordedAmount != item.recordedAmount) {
            return const FailureResult(
              AppFailure(
                kind: FailureKind.business,
                code: 'order_refund.order_changed',
                safeMessage: '订单已变化，请刷新后重新退单',
              ),
            );
          }
          if (!isCurrentAttempt() || !_operationCurrent(operation)) {
            return const FailureResult(
              AppFailure(
                kind: FailureKind.business,
                code: 'order_refund.cancelled',
                safeMessage: '退单已取消',
              ),
            );
          }
          final busyOwner = Object();
          if (!_acquireBusy(busyOwner)) {
            return const FailureResult(
              AppFailure(
                kind: FailureKind.business,
                code: 'order.operation_busy',
                safeMessage: '其他请求仍在处理中，请稍后重试',
              ),
            );
          }
          try {
            return await widget.refundOrder!(
              seatId: widget.table.id,
              orderId: item.id,
              count: draft.count,
              amount: draft.backAmount,
              remark: draft.reason,
              online: item.online,
              authEmpCode: code,
              authEmpPasswd: password,
              passType: passType,
            );
          } finally {
            _releaseBusy(busyOwner);
          }
        },
      ),
    );
    if (!_operationCurrent(operation) ||
        success != true ||
        !identical(token, liveContext.value)) {
      return;
    }
    _show('退单成功');
    await _loadOrders();
  }

  Future<void> _convertYh(OrderCartItem item) async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      if (widget.convertCartToYh == null) {
        _show('优惠尚未接入');
        return;
      }
      final reason = await showDialog<String>(
        context: context,
        builder: (context) => _ReasonDialog(
          title: '优惠',
          reasons: widget.yhReasons,
          missingMessage: '请选择优惠理由',
        ),
      );
      if (!_operationCurrent(operation)) return;
      if (reason == null) return;
      if (reason.isEmpty) {
        _show('请选择优惠理由');
        return;
      }
      if (!_acquireBusy(busyOwner)) return;
      final result = await widget.convertCartToYh!(
        seatId: widget.table.id,
        cartItemIds: [item.id],
        counts: [item.count],
        reason: reason,
      );
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      _show('优惠成功');
      await _reloadCart();
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Future<void> _addYhProduct(SoldOutProduct product) async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      if (!_pricesReady()) return;
      if (widget.addYh == null) {
        _show('优惠尚未接入');
        return;
      }
      final reason = await showDialog<String>(
        context: context,
        builder: (context) => _ReasonDialog(
          title: '优惠',
          reasons: widget.yhReasons,
          missingMessage: '请选择优惠理由',
        ),
      );
      if (!_operationCurrent(operation)) return;
      if (reason == null) return;
      if (reason.isEmpty) {
        _show('请选择优惠理由');
        return;
      }
      if (!_acquireBusy(busyOwner)) return;
      if (!_pricesReady()) {
        _releaseBusy(busyOwner);
        return;
      }
      final result = await widget.addYh!(
        seatId: widget.table.id,
        productId: product.id,
        count: 1,
        amount: '',
        price: product.price,
        reason: reason,
      );
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      _show('加入购物车成功');
      await _reloadCart();
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Future<void> _addYh2Product(SoldOutProduct product) async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      if (!_pricesReady()) return;
      if (widget.addYh2 == null) {
        _show('优惠2尚未接入');
        return;
      }
      final dest = await _askYh2Dest();
      if (dest == null || !_operationCurrent(operation)) return;
      if (!_acquireBusy(busyOwner)) return;
      if (!_pricesReady()) {
        _releaseBusy(busyOwner);
        return;
      }
      final result = await widget.addYh2!(
        seatId: widget.table.id,
        productId: product.id,
        count: 1,
        salesEmpId: dest.salesEmpId,
        yh2SeatId: dest.yh2SeatId,
      );
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      _show('加入购物车成功');
      await _reloadCart();
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Future<void> _addRequirement(OrderCartItem item) async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      if (widget.addRequirement == null) {
        _show('要求尚未接入');
        return;
      }
      final text = await showDialog<String>(
        context: context,
        builder: (context) => const _TextDialog(
          title: '要求',
          fieldKey: OrderMealScreen.requirementKey,
          label: '请输入要求',
        ),
      );
      if (text == null || text.isEmpty || !_operationCurrent(operation)) return;
      if (!_acquireBusy(busyOwner)) return;
      final result = await widget.addRequirement!(
        seatId: widget.table.id,
        itemId: item.id,
        requirement: text,
      );
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      _show('修改成功');
      await _reloadCart();
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Future<void> _changeCartSet(OrderCartItem item) async {
    final operation = _beginOperation();
    if (operation == null) return;
    if (!item.setEditable ||
        widget.changeSetDetail == null ||
        widget.loadCartItems == null) {
      _show('缺少真实套餐明细或购物车复核服务，无法更改');
      return;
    }
    final config = _setConfiguration(item.productId);
    if (!config.known || config.details.isEmpty) {
      _show(config.unavailableReason ?? '套餐配置不可用');
      return;
    }
    final success = await showDialog<bool>(
      context: context,
      builder: (_) => OrderSetDialog(
        productId: item.productId,
        title: '更改购物车套餐明细',
        configuration: config,
        contextToken: widget.operationContext!,
        replacing: true,
        oldItems: item.setItems,
        submit: (selection, code, password, passType, active) async {
          if (!_setAttemptCurrent(operation, active)) {
            return const FailureResult(_setContextFailure);
          }
          final inventoryFailure = await _checkSetInventory(
            selection,
            item.count,
            operation,
            active,
          );
          if (inventoryFailure != null) return FailureResult(inventoryFailure);
          if (!_setAttemptCurrent(operation, active)) {
            return const FailureResult(_setContextFailure);
          }
          final result = await widget.loadCartItems!(widget.table.id);
          if (!_setAttemptCurrent(operation, active)) {
            return const FailureResult(_setContextFailure);
          }
          if (result.failureOrNull case final failure?) {
            return FailureResult(failure);
          }
          final parents =
              result.valueOrNull?.where((row) => row.id == item.id).toList() ??
              [];
          final fresh = _setConfiguration(item.productId);
          if (parents.length != 1 ||
              !parents.single.setEditable ||
              parents.single.productId != item.productId ||
              parents.single.count != item.count ||
              parents.single.unitPrice != item.unitPrice ||
              parents.single.amount != item.amount ||
              !_sameSetConfiguration(config, fresh)) {
            return const FailureResult(_setChangedFailure);
          }
          final old = selection.replacing!;
          final matches = parents.single.setItems
              .where(
                (row) =>
                    row.groupId == old.groupId &&
                    row.detailProductId == old.detailProductId &&
                    row.requirement == old.requirement,
              )
              .toList();
          if (matches.length != 1 || !_sameSetItem(old, matches.single)) {
            return const FailureResult(_setChangedFailure);
          }
          final failure = _validateSetSelection(selection, fresh);
          if (failure != null) return FailureResult(failure);
          return _runSetWrite(
            operation,
            active,
            () => widget.changeSetDetail!(
              seatId: widget.table.id,
              itemId: item.id,
              groupId: old.groupId,
              detailProductId: old.detailProductId,
              requirement: old.requirement,
              destDetailProductIds: selection.detailProductIds,
              destSelectCounts: selection.selectCounts,
              destRequirements: selection.requirements,
            ),
            selection: selection,
            parentCount: item.count,
          );
        },
      ),
    );
    if (success != true || !_operationCurrent(operation)) return;
    _show('修改明细成功');
    await _reloadCart();
  }

  Future<void> _convertYh2(OrderCartItem item) async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      if (widget.convertCartToYh2 == null) {
        _show('优惠2尚未接入');
        return;
      }
      final dest = await _askYh2Dest();
      if (dest == null || !_operationCurrent(operation)) return;
      if (!_acquireBusy(busyOwner)) return;
      final result = await widget.convertCartToYh2!(
        seatId: widget.table.id,
        cartItemIds: [item.id],
        counts: [item.count],
        salesEmpId: dest.salesEmpId,
        yh2SeatId: dest.yh2SeatId,
      );
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      _show('批量优惠2成功');
      await _reloadCart();
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Future<void> _giftOrder(OrderPlacedItem item) async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      if (item.paid || item.refunded) {
        _show('已付款的不支持优惠');
        return;
      }
      if (widget.giftOrdered == null) {
        _show('赠送尚未接入');
        return;
      }
      final reason = await showDialog<String>(
        context: context,
        builder: (context) => _ReasonDialog(
          title: '优惠',
          reasons: widget.yhReasons,
          missingMessage: '请选择优惠理由',
        ),
      );
      if (!_operationCurrent(operation)) return;
      if (reason == null || reason.isEmpty) return;
      if (!_acquireBusy(busyOwner)) return;
      final result = await widget.giftOrdered!(
        seatId: widget.table.id,
        orderIds: [item.id],
        counts: [item.count],
        reason: reason,
      );
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      _show('优惠成功');
      await _loadOrders();
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Future<void> _yh2Order(OrderPlacedItem item) async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      if (widget.convertOrderToYh2 == null) {
        _show('优惠2尚未接入');
        return;
      }
      final dest = await _askYh2Dest();
      if (dest == null || !_operationCurrent(operation)) return;
      if (!_acquireBusy(busyOwner)) return;
      final result = await widget.convertOrderToYh2!(
        seatId: widget.table.id,
        orderIds: [item.id],
        counts: [item.count],
        salesEmpId: dest.salesEmpId,
        yh2SeatId: dest.yh2SeatId,
      );
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      _show('批量优惠2成功');
      await _loadOrders();
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Future<void> _changeOrdered(OrderPlacedItem item) async {
    final operation = _beginOperation();
    if (operation == null) return;
    if (!item.setEditable ||
        widget.changeOrderedSet == null ||
        (widget.loadOrders == null && widget.loadOrderDetails == null)) {
      _show('缺少真实子订单明细或订单复核服务，无法更改');
      return;
    }
    final config = _setConfiguration(item.productId);
    if (!config.known || config.details.isEmpty) {
      _show(config.unavailableReason ?? '套餐配置不可用');
      return;
    }
    final success = await showDialog<bool>(
      context: context,
      builder: (_) => OrderSetDialog(
        productId: item.productId,
        title: '更改已下单套餐明细',
        configuration: config,
        contextToken: widget.operationContext!,
        replacing: true,
        oldItems: item.setItems,
        allowAuthorization: !widget.isCashier,
        submit: (selection, code, password, passType, active) async {
          if (!_setAttemptCurrent(operation, active)) {
            return const FailureResult(_setContextFailure);
          }
          final inventoryFailure = await _checkSetInventory(
            selection,
            item.count,
            operation,
            active,
          );
          if (inventoryFailure != null) return FailureResult(inventoryFailure);
          if (!_setAttemptCurrent(operation, active)) {
            return const FailureResult(_setContextFailure);
          }
          List<OrderPlacedItem>? rows;
          AppFailure? readFailure;
          if (widget.loadOrderDetails case final load?) {
            final result = await load(
              seatId: widget.table.id,
              turnoverCount: widget.table.turnoverCount,
            );
            rows = result.valueOrNull?.items;
            readFailure = result.failureOrNull;
          } else {
            final result = await widget.loadOrders!(
              seatId: widget.table.id,
              turnoverCount: widget.table.turnoverCount,
            );
            rows = result.valueOrNull;
            readFailure = result.failureOrNull;
          }
          if (!_setAttemptCurrent(operation, active)) {
            return const FailureResult(_setContextFailure);
          }
          if (readFailure != null) return FailureResult(readFailure);
          final parents =
              rows
                  ?.where(
                    (row) => row.id == item.id && row.online == item.online,
                  )
                  .toList() ??
              [];
          final fresh = _setConfiguration(item.productId);
          if (parents.length != 1 ||
              !parents.single.setEditable ||
              parents.single.status != item.status ||
              parents.single.productId != item.productId ||
              parents.single.count != item.count ||
              parents.single.originalUnitPrice != item.originalUnitPrice ||
              parents.single.recordedUnitPrice != item.recordedUnitPrice ||
              parents.single.recordedAmount != item.recordedAmount ||
              !_sameSetConfiguration(config, fresh)) {
            return const FailureResult(_setChangedFailure);
          }
          final old = selection.replacing!;
          final matches = parents.single.setItems
              .where((row) => row.id == old.id)
              .toList();
          if (old.id.isEmpty ||
              matches.length != 1 ||
              !_sameSetItem(old, matches.single)) {
            return const FailureResult(_setChangedFailure);
          }
          final failure = _validateSetSelection(selection, fresh);
          if (failure != null) return FailureResult(failure);
          return _runSetWrite(
            operation,
            active,
            () => widget.changeOrderedSet!(
              seatId: widget.table.id,
              orderId: item.id,
              orderDetailId: old.id,
              destDetailProductIds: selection.detailProductIds,
              destSelectCounts: selection.selectCounts,
              destRequirements: selection.requirements,
              authEmpCode: code,
              authEmpPasswd: password,
              passType: passType,
            ),
            selection: selection,
            parentCount: item.count,
          );
        },
      ),
    );
    if (success != true || !_operationCurrent(operation)) return;
    _show('修改明细成功');
    await _loadOrders();
  }

  Future<void> _reprint(OrderPlacedItem item) async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      if (widget.reprintKitchen == null) {
        _show('补打出品尚未接入');
        return;
      }
      if (!_acquireBusy(busyOwner)) return;
      final result = await widget.reprintKitchen!(item.id);
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      _show('打印成功');
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Future<void> _printBill() async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      if (widget.printBill == null) {
        _show('打印消费单尚未接入');
        return;
      }
      final includeHl = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('打印消费单'),
          content: const Text('是否包含鸡尾酒类商品?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('不包含'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('包含'),
            ),
          ],
        ),
      );
      if (includeHl == null || !_operationCurrent(operation)) return;
      if (!_acquireBusy(busyOwner)) return;
      final result = await widget.printBill!(
        seatId: widget.table.id,
        unpaid: true,
        includeHl: includeHl,
      );
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      _show('打印成功');
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Future<void> _cleanSeat() async {
    final operation = _beginOperation();
    if (operation == null) return;
    final ownerRoute = ModalRoute.of(context);
    final busyOwner = Object();
    try {
      if (widget.cleanSeat == null) {
        _show('清台尚未接入');
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('清台'),
          content: const Text('确定要进行清台操作吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      if (confirmed != true || !_operationCurrent(operation)) return;
      if (!_acquireBusy(busyOwner)) return;
      final result = await widget.cleanSeat!(widget.table.id);
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      _show('清台成功');
      if (ownerRoute != null && !ownerRoute.isFirst) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ownerRoute.isActive && !ownerRoute.isFirst) {
            ownerRoute.navigator?.removeRoute(ownerRoute);
          }
        });
        WidgetsBinding.instance.ensureVisualUpdate();
      }
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Future<void> _mergeYh2() async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      if (widget.mergeYh2 == null) {
        _show('并台尚未接入');
        return;
      }
      if (_orders.isEmpty) await _loadOrders();
      if (!mounted || !_operationCurrent(operation)) return;
      final dest = await showDialog<String>(
        context: context,
        builder: (context) => const _TextDialog(
          title: '并台',
          fieldKey: OrderMealScreen.yh2SeatKey,
          label: '目标卡台Id',
        ),
      );
      if (dest == null || dest.isEmpty || !_operationCurrent(operation)) return;
      if (!_acquireBusy(busyOwner)) return;
      final result = await widget.mergeYh2!(
        seatId: widget.table.id,
        orderIds: [for (final item in _orders) item.id],
        destSeatId: dest,
      );
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      _show('转优惠2成功');
      await _loadOrders();
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Future<void> _waiterPay() async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      if (widget.waiterTodoOrders == null || widget.createWaiterPay == null) {
        _show('服务员买单尚未接入');
        return;
      }
      if (!_acquireBusy(busyOwner)) return;
      final listed = await widget.waiterTodoOrders!(widget.table.id);
      if (!_operationCurrent(operation)) return;
      if (listed.failureOrNull != null) {
        _releaseBusy(busyOwner);
        _show(listed.failureOrNull!.safeMessage);
        return;
      }
      final rows = listed.valueOrNull ?? const <OrderPlacedItem>[];
      if (rows.isEmpty) {
        _releaseBusy(busyOwner);
        _show('没有待付款订单');
        return;
      }
      final created = await widget.createWaiterPay!(
        seatId: widget.table.id,
        payType: 1,
        orderIds: [for (final item in rows) item.id],
      );
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (created.failureOrNull != null) {
        _show(created.failureOrNull!.safeMessage);
        return;
      }
      final qr = created.valueOrNull!;
      if (!mounted || !_operationCurrent(operation)) return;
      final route = DialogRoute<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('买单二维码'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrCodePane(
                data: qr.payUrl,
                paintKey: OrderMealScreen.waiterQrKey,
                size: 240,
              ),
              const SizedBox(height: 12),
              Text('金额：￥${(qr.amountFen / 100).toStringAsFixed(2)}'),
              const Text('二维码页面15分钟后自动关闭，请重新获取'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
      _waiterPayDialog = route;
      _waiterPayExpiry?.cancel();
      _waiterPayExpiry = Timer(const Duration(minutes: 15), () {
        if (identical(_waiterPayDialog, route)) _closeWaiterPayDialog();
      });
      await Navigator.of(context).push<void>(route);
      if (identical(_waiterPayDialog, route)) {
        _waiterPayDialog = null;
        _waiterPayExpiry?.cancel();
        _waiterPayExpiry = null;
      }
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Future<({String salesEmpId, String yh2SeatId})?> _askYh2Dest() {
    return showDialog<({String salesEmpId, String yh2SeatId})>(
      context: context,
      builder: (context) => const _Yh2DestDialog(),
    );
  }

  Future<void> _placeOrder() async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      if (_items.isEmpty) {
        _show('购物车商品为空，请添加商品至购物车再下单！');
        return;
      }
      final place = widget.placeOrder;
      if (place == null) {
        _show('下单尚未接入');
        return;
      }
      if (!_acquireBusy(busyOwner)) return;
      final result = await place(
        seatId: widget.table.id,
        cartItemIds: [for (final item in _items) item.id],
      );
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      _show('下单成功');
      await _reloadCart();
      if (!_operationCurrent(operation)) return;
      setState(() => _tab = 2);
      await _loadOrders();
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Future<void> _add(
    SoldOutProduct product,
    int count, {
    String amount = '',
  }) async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      if (!_pricesReady()) return;
      final actualPrice = _actualProductPrice(product);
      if (actualPrice == null) {
        _show('商品价格上下文尚未同步，请稍后再试');
        return;
      }
      if (!_acquireBusy(busyOwner)) return;
      final result = await widget.addProduct(
        seatId: widget.table.id,
        productId: product.id,
        count: count,
        price: actualPrice,
        amount: amount,
      );
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      _show('加入购物车成功');
      if (widget.loadCartItems == null && widget.loadCartCount == null) {
        setState(() => _cartCount += count);
      }
      await _reloadCart();
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Future<void> _changeItem(OrderCartItem item, int count) async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      final setCount = widget.setCartCount;
      if (setCount == null) return;
      if (!_acquireBusy(busyOwner)) return;
      final result = await setCount(
        seatId: widget.table.id,
        itemId: item.id,
        count: count,
      );
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      await _reloadCart();
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  List<SoldOutProduct> get _visible {
    final firstId = _firstId;
    final secondId = _secondId;
    if (firstId == null || secondId == null) return const [];
    if (_keyword.isEmpty) {
      return widget.catalog.productsIn(firstId: firstId, secondId: secondId);
    }
    return widget.catalog.search(
      keyword: _keyword,
      firstId: firstId,
      secondId: secondId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3373E8)),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xffF3F4F6),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              if (_tab == 2 &&
                  (widget.orderSummaryVisibility?.value ??
                      widget.showOrderSummary))
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      for (final entry in {
                        '折前金额': _orderSummary?.allAmt,
                        '优惠金额': _orderSummary?.giveAmt,
                        '折扣金额': _orderSummary?.discountAmt,
                        '未结账金额': _orderSummary?.notPayAmt,
                      }.entries)
                        Text(
                          '${entry.key} ${entry.value == null ? '--' : '￥${entry.value}'}',
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: switch (_tab) {
                  1 => _cartPane(),
                  2 => _myOrderPane(),
                  3 => _chosenPane(),
                  _ => _menuPane(),
                },
              ),
              _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  bool get _showBindWaiter => widget.table.businessType == 1 && !_waiterBound;

  String get _openTime {
    final value = widget.table.openTime;
    if (value.length < 12) return '';
    return '${value.substring(8, 10)}:${value.substring(10, 12)}';
  }

  Widget _header() {
    return ColoredBox(
      color: const Color(0xffDCE1EA),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.table.name}${widget.salesLabel.isEmpty ? '' : '/${widget.salesLabel}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_openTime.isNotEmpty) ...[
                  const Text('开台时间：', style: TextStyle(fontSize: 14)),
                  Text(
                    _openTime,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                if (widget.bindGuestEnabled)
                  Flexible(
                    child: TextButton.icon(
                      key: OrderMealScreen.bindGuestKey,
                      onPressed: _busy ? null : _openBindGuest,
                      icon: const Icon(Icons.person_add_alt, size: 16),
                      label: Text(
                        _guestLabel.isEmpty ? '绑定客人' : _guestLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                const Spacer(),
                if (_showBindWaiter)
                  TextButton.icon(
                    key: OrderMealScreen.bindWaiterKey,
                    onPressed: _busy ? null : _openBindWaiter,
                    icon: const Icon(Icons.badge_outlined, size: 16),
                    label: const Text('绑定当台服务员'),
                  )
                else if (widget.userName != null && widget.userName!.isNotEmpty)
                  Text(widget.userName!, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuPane() {
    final firsts = widget.catalog.firstCategories;
    final seconds = _firstId == null
        ? const <SoldOutCategory>[]
        : widget.catalog.secondsOf(_firstId!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            key: OrderMealScreen.searchKey,
            decoration: const InputDecoration(
              hintText: '请输入商品首字母缩写',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _keyword = value),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final item in firsts)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(item.name),
                    selected: item.id == _firstId,
                    onSelected: (_) {
                      final nextSeconds = widget.catalog.secondsOf(item.id);
                      setState(() {
                        _firstId = item.id;
                        _secondId = nextSeconds.firstOrNull?.id;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final item in seconds)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(item.name),
                    selected: item.id == _secondId,
                    onSelected: (_) => setState(() => _secondId = item.id),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _visible.isEmpty
              ? const Center(child: Text('暂无商品'))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: _visible.length,
                  itemBuilder: (context, index) =>
                      _productCard(_visible[index]),
                ),
        ),
      ],
    );
  }

  Widget _productCard(SoldOutProduct product) {
    final availability = _productRemaining(product);
    final remaining = availability.count;
    final ordered = _ordered(product.id);
    final soldOut = !availability.known || remaining == 0;
    final schemePrice = _prices.known ? _schemePrice(product) : null;
    final quote = _quote(product);
    final originalPrice = double.tryParse(
      quote?.baseOriginalPrice ??
          (widget.productQuoteFor == null ? product.price : ''),
    );
    final showOriginal =
        schemePrice != null &&
        originalPrice != null &&
        originalPrice.isFinite &&
        originalPrice > 0 &&
        originalPrice != schemePrice;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _busy || (product.prdType == 2 && soldOut)
            ? null
            : () => unawaited(_openProduct(product)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (product.nameEng.isNotEmpty)
                Text(
                  product.nameEng,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              const Spacer(),
              if (showOriginal)
                Text(
                  '原价：￥${originalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff999999),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                (_prices.known || product.prdType == 2)
                    ? (schemePrice != null
                          ? '${showOriginal ? '方案价：' : ''}￥${schemePrice.toStringAsFixed(2)}'
                          : quote == null
                          ? '价格待同步'
                          : quote.actualDisplayPrice == '时价'
                          ? '时价'
                          : '￥${quote.actualPrice}')
                    : '价格待同步',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: showOriginal
                      ? const Color(0xffE63122)
                      : const Color(0xff009370),
                ),
              ),
              const SizedBox(height: 6),
              if (schemePrice == null && quote?.hasMemberPrice == true)
                Text(
                  '会员提示价：￥${quote!.memberPrice}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff666666),
                  ),
                ),
              Row(
                children: [
                  if (!availability.known) const Text('库存待同步'),
                  if (remaining != null)
                    Text(
                      remaining == 0 ? '售罄' : '余:$remaining',
                      style: TextStyle(
                        color: remaining == 0
                            ? Colors.red
                            : Colors.grey.shade700,
                      ),
                    ),
                  if (ordered > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '已点：$ordered',
                      style: const TextStyle(color: Color(0xff2563EB)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: [
                  FilledButton(
                    onPressed: _busy || soldOut
                        ? null
                        : () => unawaited(_openProduct(product)),
                    child: const Text('加入'),
                  ),
                  TextButton(
                    onPressed: _busy || soldOut
                        ? null
                        : () => unawaited(_addYhProduct(product)),
                    child: const Text('优惠'),
                  ),
                  TextButton(
                    onPressed: _busy || soldOut
                        ? null
                        : () => unawaited(_addYh2Product(product)),
                    child: const Text('优惠2'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cartPane() {
    if (_items.isEmpty) {
      return const Center(child: Text('购物车是空的'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _productName(item.productId),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text('￥${item.unitPrice}  小计￥${item.amount}'),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _busy || item.count <= 1
                          ? null
                          : () => unawaited(_changeItem(item, item.count - 1)),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('${item.count}', style: const TextStyle(fontSize: 16)),
                    IconButton(
                      onPressed: _busy
                          ? null
                          : () => unawaited(_changeItem(item, item.count + 1)),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => unawaited(_convertYh(item)),
                      child: const Text('优惠'),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => unawaited(_convertYh2(item)),
                      child: const Text('优惠2'),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => unawaited(_addRequirement(item)),
                      child: const Text('要求'),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => unawaited(_changeCartSet(item)),
                      child: const Text('更改明细'),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => unawaited(_changeItem(item, 0)),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _myOrderPane() {
    if (_orders.isEmpty) {
      return const Center(child: Text('暂无点单'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _orders[index];
        final name = item.name.isEmpty
            ? _productName(item.productId)
            : item.name;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(name),
                Text(
                  '数量 ${item.count}  ￥${item.unitPrice}  ${item.orderedAt}  ￥${item.amount}',
                ),
                Wrap(
                  children: [
                    if (!item.paid && !item.refunded)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => unawaited(_refund(item)),
                        child: const Text('退单'),
                      ),
                    if (!item.paid && !item.refunded)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => unawaited(_giftOrder(item)),
                        child: const Text('赠送'),
                      ),
                    if (!item.paid && !item.refunded)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => unawaited(_yh2Order(item)),
                        child: const Text('优惠2'),
                      ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => unawaited(_changeOrdered(item)),
                      child: const Text('改明细'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => unawaited(_reprint(item)),
                      child: const Text('补打出品'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  CardTable get _footerTable {
    final live = widget.liveTableAmounts?.value;
    return live != null &&
            live.id == widget.table.id &&
            live.turnoverCount == widget.table.turnoverCount
        ? live
        : widget.table;
  }

  Widget _bottomBar() {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('返回首页'),
                  ),
                  _navButton('商品菜单', 0),
                  _navButton('购物车', 1, key: OrderMealScreen.cartTabKey),
                  _navButton('我的点单', 2, key: OrderMealScreen.myOrderTabKey),
                  _navButton('已选', 3, key: OrderMealScreen.chosenTabKey),
                  TextButton(
                    onPressed: _busy ? null : _openRedeem,
                    child: const Text('核销卡券'),
                  ),
                  PopupMenuButton<String>(
                    key: OrderMealScreen.moreKey,
                    tooltip: '更多功能',
                    onSelected: _onMore,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'recharge', child: Text('充值')),
                      PopupMenuItem(value: 'book', child: Text('滞留金')),
                      PopupMenuItem(value: 'clear', child: Text('清台')),
                      PopupMenuItem(value: 'move', child: Text('转台')),
                      PopupMenuItem(value: 'print', child: Text('打印消费单')),
                      PopupMenuItem(value: 'pay', child: Text('买单二维码')),
                      PopupMenuItem(value: 'merge', child: Text('并台')),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text('更多功能'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (_tab == 1)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: OrderMealScreen.placeOrderKey,
                  onPressed: _busy ? null : () => unawaited(_placeOrder()),
                  child: const Text('立即下单'),
                ),
              ),
            if (_tab == 1) const SizedBox(height: 4),
            if (widget.footerAmountsVisibility?.value ??
                widget.showFooterAmounts)
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      '折前金额:￥${OrderCardDisplay.yuan(_footerTable.originalAmount())}',
                    ),
                    Text(
                      '折后金额:￥${OrderCardDisplay.yuan(_footerTable.paidValAmount)}',
                    ),
                    Text(
                      '主营点单金额:￥${OrderCardDisplay.yuan(_footerTable.mainOrderAmount)}',
                    ),
                    Text(
                      '已收金额:￥${OrderCardDisplay.yuan(_footerTable.paidAmount)}',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(String label, int tab, {Key? key}) {
    Widget child = Text(
      label,
      style: TextStyle(
        fontWeight: _tab == tab ? FontWeight.w700 : FontWeight.w400,
      ),
    );
    if (tab == 1) {
      child = Badge(
        isLabelVisible: _cartCount > 0,
        label: Text('$_cartCount'),
        child: child,
      );
    }
    return TextButton(
      key: key,
      onPressed: () {
        setState(() => _tab = tab);
        if (tab == 1 || tab == 3) unawaited(_reloadCart());
        if (tab == 2) unawaited(_loadOrders());
      },
      child: child,
    );
  }

  Future<void> _loadOrders() async {
    final readOperation = _operationGeneration;
    final version = ++_orderReadVersion;
    setState(() => _orderSummary = null);
    final loadDetails = widget.loadOrderDetails;
    if (loadDetails != null) {
      final result = await loadDetails(
        seatId: widget.table.id,
        turnoverCount: widget.table.turnoverCount,
      );
      if (!mounted ||
          readOperation != _operationGeneration ||
          version != _orderReadVersion) {
        return;
      }
      if (result.valueOrNull case final data?) {
        setState(() {
          _orders = data.items;
          _orderSummary = data.summary;
        });
      } else if (result.failureOrNull case final failure?) {
        _show(failure.safeMessage);
      }
      return;
    }
    final load = widget.loadOrders;
    if (load == null) return;
    final result = await load(
      seatId: widget.table.id,
      turnoverCount: widget.table.turnoverCount,
    );
    if (!mounted ||
        readOperation != _operationGeneration ||
        version != _orderReadVersion) {
      return;
    }
    if (result.valueOrNull != null) {
      setState(() => _orders = result.valueOrNull!);
    } else if (result.failureOrNull != null) {
      _show(result.failureOrNull!.safeMessage);
    }
  }

  Future<void> _openBindWaiter() async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('提示'),
          content: const Text('绑定当台服务员？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('关闭'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      if (confirmed != true || !_operationCurrent(operation)) return;
      final bind = widget.bindWaiter;
      if (bind == null) {
        _show('绑定当台服务员尚未接入');
        return;
      }
      if (!_acquireBusy(busyOwner)) return;
      final result = await bind(widget.table.id);
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      setState(() => _waiterBound = true);
      _show('绑定成功');
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Future<void> _openBindGuest() async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      final phone = await showDialog<String>(
        context: context,
        builder: (context) => _BindGuestDialog(
          searchGuests: widget.searchGuests == null
              ? null
              : (phone) async {
                  const failure = AppFailure(
                    kind: FailureKind.authentication,
                    code: 'order.operation_changed',
                    safeMessage: '当前操作已失效，请返回重新打开',
                  );
                  if (!_operationCurrent(operation)) {
                    return const FailureResult(failure);
                  }
                  final result = await widget.searchGuests!(phone);
                  if (!_operationCurrent(operation)) {
                    return const FailureResult(failure);
                  }
                  return result;
                },
        ),
      );
      if (phone == null || phone.isEmpty || !_operationCurrent(operation)) {
        return;
      }
      final bind = widget.bindGuest;
      if (bind == null) {
        _show('绑定客人尚未接入');
        return;
      }
      if (!_acquireBusy(busyOwner)) return;
      final result = await bind(seatId: widget.table.id, phone: phone);
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      setState(() => _guestLabel = phone);
      _show('绑定成功');
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  Set<int> get _currentModuleIds {
    try {
      return widget.currentModuleIds?.call() ?? widget.moduleIds;
    } on Object {
      return const <int>{};
    }
  }

  Future<void> _openRedeem() async {
    final operation = _beginOperation();
    if (operation == null) return;
    final busyOwner = Object();
    try {
      if (!_currentModuleIds.contains(86)) {
        _show('无核销权限，请联系后台人员配置相关权限！');
        return;
      }
      if (widget.redeemCoupon == null) {
        _show('核销卡券尚未接入');
        return;
      }
      final code = await showDialog<String>(
        context: context,
        builder: (context) => const _TextDialog(
          title: '核销卡券',
          fieldKey: OrderMealScreen.redeemFieldKey,
          label: '券码',
        ),
      );
      if (code == null || code.isEmpty || !_operationCurrent(operation)) return;
      if (!_currentModuleIds.contains(86)) {
        _show('无核销权限，请联系后台人员配置相关权限！');
        return;
      }
      if (!_acquireBusy(busyOwner)) return;
      final result = await widget.redeemCoupon!(code);
      if (!_operationCurrent(operation)) return;
      _releaseBusy(busyOwner);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      _show('卡券核销成功');
    } finally {
      _releaseBusy(busyOwner);
    }
  }

  void _onMore(String value) {
    switch (value) {
      case 'clear':
        unawaited(_cleanSeat());
      case 'print':
        unawaited(_printBill());
      case 'pay':
        unawaited(_waiterPay());
      case 'merge':
        unawaited(_mergeYh2());
      case 'recharge':
        if (widget.onOpenVipRecharge != null) {
          unawaited(widget.onOpenVipRecharge!());
        } else {
          _show('会员充值尚未接入点单页');
        }
      case 'book':
        if (widget.onOpenLateDeposit != null) {
          unawaited(widget.onOpenLateDeposit!());
        } else {
          _show('滞留金尚未接入');
        }
      case 'move':
        if (widget.onTransferSeat != null) {
          unawaited(widget.onTransferSeat!());
        } else {
          _show('转台尚未接入');
        }
      default:
        _show('该业务功能尚未接入');
    }
  }

  Widget _chosenPane() {
    if (_items.isEmpty) {
      return const Center(child: Text('暂无已选'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          child: ListTile(
            title: Text(_productName(item.productId)),
            subtitle: Text(
              '数量 ${item.count}  ￥${item.unitPrice}  小计￥${item.amount}',
            ),
          ),
        );
      },
    );
  }
}

final class _BindGuestDialog extends StatefulWidget {
  const _BindGuestDialog({this.searchGuests});

  final OrderMealSearchGuests? searchGuests;

  @override
  State<_BindGuestDialog> createState() => _BindGuestDialogState();
}

final class _BindGuestDialogState extends State<_BindGuestDialog> {
  final TextEditingController _phone = TextEditingController();
  List<OrderGuestHit> _hits = const [];
  String? _selected;
  int _searchRequest = 0;
  bool _searching = false;
  String? _searchError;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _search(String value) async {
    final request = ++_searchRequest;
    final search = widget.searchGuests;
    final canSearch =
        search != null && (value.length == 4 || value.length == 11);
    setState(() {
      _selected = null;
      _hits = const [];
      _searchError = null;
      _searching = canSearch;
    });
    if (!canSearch) return;
    try {
      final result = await search(value);
      if (!mounted || request != _searchRequest) return;
      setState(() {
        _searching = false;
        _hits = result.valueOrNull ?? const [];
        _searchError = result.failureOrNull?.safeMessage;
      });
    } on Object {
      if (!mounted || request != _searchRequest) return;
      setState(() {
        _searching = false;
        _searchError = '搜索失败，请重试';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('绑定客人'),
      scrollable: true,
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: '客人手机号',
                hintText: '输入客人手机号后四位搜索',
              ),
              onChanged: (value) => unawaited(_search(value)),
            ),
            if (_searching) const LinearProgressIndicator(),
            if (_searchError != null) Text(_searchError!),
            for (final hit in _hits)
              CheckboxListTile(
                dense: true,
                value: _selected == hit.phone,
                title: Text('${hit.name}  ${hit.phone}'),
                onChanged: (_) => setState(() {
                  ++_searchRequest;
                  _searching = false;
                  _selected = hit.phone;
                  _phone.text = hit.phone;
                }),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _phone.text.trim()),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

final class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({required this.product});

  final SoldOutProduct product;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

final class _QuantityDialogState extends State<_QuantityDialog> {
  final TextEditingController _count = TextEditingController(text: '1');

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('默认商品数量1'),
          const SizedBox(height: 8),
          TextField(
            key: OrderMealScreen.countKey,
            controller: _count,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final count = int.tryParse(_count.text.trim()) ?? 0;
            if (count < 1) return;
            Navigator.pop(context, count);
          },
          child: const Text('确认'),
        ),
      ],
    );
  }
}

final class _AmountDialog extends StatefulWidget {
  const _AmountDialog({required this.product, required this.requireAmount});

  final SoldOutProduct product;
  final bool requireAmount;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

final class _AmountDialogState extends State<_AmountDialog> {
  final TextEditingController _count = TextEditingController(text: '1');
  final TextEditingController _amount = TextEditingController();

  @override
  void dispose() {
    _count.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.requireAmount) const Text('请输入金额'),
          if (widget.requireAmount) const SizedBox(height: 8),
          if (widget.requireAmount)
            TextField(
              key: OrderMealScreen.amountKey,
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          const SizedBox(height: 8),
          const Text('默认商品数量1'),
          const SizedBox(height: 8),
          TextField(
            key: OrderMealScreen.countKey,
            controller: _count,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final count = int.tryParse(_count.text.trim()) ?? 0;
            if (count < 1) return;
            Navigator.pop(context, (count: count, amount: _amount.text.trim()));
          },
          child: const Text('确认'),
        ),
      ],
    );
  }
}

final class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.reasons,
    required this.missingMessage,
  });

  final String title;
  final List<String> reasons;
  final String missingMessage;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

final class _ReasonDialogState extends State<_ReasonDialog> {
  String? _selected;
  bool _missing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_missing) Text(widget.missingMessage),
          for (final reason in widget.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ChoiceChip(
                label: Text(reason),
                selected: _selected == reason,
                onSelected: (_) => setState(() {
                  _selected = reason;
                  _missing = false;
                }),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final value = _selected ?? '';
            if (value.isEmpty) {
              setState(() => _missing = true);
              return;
            }
            Navigator.pop(context, value);
          },
          child: const Text('确认'),
        ),
      ],
    );
  }
}

final class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.fieldKey,
    required this.label,
  });

  final String title;
  final Key fieldKey;
  final String label;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

final class _TextDialogState extends State<_TextDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: widget.fieldKey,
        controller: _controller,
        decoration: InputDecoration(labelText: widget.label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('确认'),
        ),
      ],
    );
  }
}

final class _Yh2DestDialog extends StatefulWidget {
  const _Yh2DestDialog();

  @override
  State<_Yh2DestDialog> createState() => _Yh2DestDialogState();
}

final class _Yh2DestDialogState extends State<_Yh2DestDialog> {
  final TextEditingController _sales = TextEditingController();
  final TextEditingController _seat = TextEditingController();

  @override
  void dispose() {
    _sales.dispose();
    _seat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('优惠2'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: OrderMealScreen.yh2SalesKey,
            controller: _sales,
            decoration: const InputDecoration(labelText: '订位人Id'),
          ),
          TextField(
            key: OrderMealScreen.yh2SeatKey,
            controller: _seat,
            decoration: const InputDecoration(labelText: '优惠2卡台Id'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final salesEmpId = _sales.text.trim();
            final yh2SeatId = _seat.text.trim();
            if (salesEmpId.isEmpty || yh2SeatId.isEmpty) return;
            Navigator.pop(context, (
              salesEmpId: salesEmpId,
              yh2SeatId: yh2SeatId,
            ));
          },
          child: const Text('确认'),
        ),
      ],
    );
  }
}
