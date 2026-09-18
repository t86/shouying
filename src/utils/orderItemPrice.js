const toNumber = (val) => {
  if (val === undefined || val === null || val === "") return null;
  const num = Number(val);
  return Number.isNaN(num) ? null : num;
};

export const buildPriceContextFromStore = (store) => {
  if (!store || !store.state) return {};
  const orderInfo = store.state.orderInfo || {};
  const cardInfo = orderInfo.currentCardInfo || {};
  const cardPageInfo = store.state.cardPageInfo || {};
  const resData = cardPageInfo.resResultDataObj || {};
  const businessData = resData.businessData || [];
  const businessEmpList = resData.businessEmpList || [];
  return {
    cardInfo,
    businessData,
    businessEmpList,
    fcProductPrices: resData.fcProductPrices || [],
    fcPlanEmployees: resData.fcPlanEmployees || [],
  };
};

/** 已下单价格只读取订单快照，不随当前商品、会员或员工方案变化。 */
export const resolveUnitPrice = (item, ctx = {}) => {
  if (!item) return null;
  if (toNumber(item.pp) === 0) return null;
  const p2 = toNumber(item.p2);
  return p2 !== null ? p2 : toNumber(item.pp);
};

/**
 * 获取订单项的会员价（仅用于展示，不参与计算）
 * @returns {number|null} 会员价，如果没有配置则返回 null
 */
export const getMemberPrice = (item) => {
  if (!item) return null;
  const pm = toNumber(item.pm);
  // pm = 0 表示没有配置会员价
  if (pm !== null && pm > 0) {
    return pm;
  }
  return null;
};

// 方案价不改变时价商品的身份，仍保留不可拆分结账的数量限制。
export const isTimePriceItem = (item) => toNumber(item ? item.pp : null) === 0;

export const calcItemAmount = (item, ctx = {}) => {
  if (!item) return 0;
  if (item.at == 2 || item.at == 3) return 0;

  // 时价商品：pp = 0 时，直接使用 pa（实际金额）作为小计
  const pp = toNumber(item.pp);
  if (pp === 0) {
    const pa = toNumber(item.pa);
    return pa === null ? 0 : pa;
  }

  // 完整行沿用接口实收金额；只有拆分数量时使用记录单价。
  const recordedAmount = toNumber(item.pa);
  if (recordedAmount !== null && (item.changeCount === undefined || item.changeCount === null || Number(item.changeCount) === Number(item.pc))) {
    return Number(item.pc) === 0 ? 0 : recordedAmount;
  }

  const unitPrice = resolveUnitPrice(item, ctx);
  if (unitPrice === null || Number.isNaN(unitPrice)) {
    const pa = toNumber(item.pa);
    return pa === null ? 0 : pa;
  }

  const countVal =
    item.changeCount !== undefined && item.changeCount !== null
      ? item.changeCount
      : item.pc;
  const count = toNumber(countVal) || 0;

  return (unitPrice || 0) * count;
};

// 未结账总额按剩余数量汇总，不受本次结账的勾选状态和拆分数量影响。
export const calcUnpaidOrderAmount = (orderList, ctx = {}) => {
  let totalCents = 0;
  const addItem = (item) => {
    if (!item || item.back || Number(item.pc) === 0) return;
    const amount = calcItemAmount({ ...item, changeCount: item.pc }, ctx);
    totalCents += Math.round(amount * 100);
  };

  (orderList || []).forEach((order) => {
    if (!order || order.back) return;
    if (order.oid) {
      // 线上订单的退款明细已经展开，只计未退商品，套餐明细不重复计费。
      (order.resultNotPayData || order.os || []).forEach(addItem);
    } else {
      addItem(order);
    }
  });
  return totalCents / 100;
};

/**
 * 计算退单金额（与 calcItemAmount 类似，但不排除 at=2/at=3 的商品）
 * 用于退单场景，需要计算优惠商品的实际退款金额
 */
export const calcRefundAmount = (item, ctx = {}) => {
  if (!item) return 0;

  // 时价商品：pp = 0 时，直接使用 pa（实际金额）作为小计
  const pp = toNumber(item.pp);
  if (pp === 0) {
    const pa = toNumber(item.pa);
    return pa === null ? 0 : pa;
  }

  // 整行退款不能超过订单记录金额；拆分退款才按记录单价计算。
  const recordedAmount = toNumber(item.pa);
  if (recordedAmount !== null && (item.changeCount === undefined || item.changeCount === null || Number(item.changeCount) === Number(item.pc))) {
    return Number(item.pc) === 0 ? 0 : recordedAmount;
  }

  // 退款沿用订单已记录的价格，不能因当前方案调价而重新计算历史退款。
  const unitPrice = resolveUnitPrice(item, ctx);
  if (unitPrice === null || Number.isNaN(unitPrice)) {
    const pa = toNumber(item.pa);
    return pa === null ? 0 : pa;
  }

  const countVal =
    item.changeCount !== undefined && item.changeCount !== null
      ? item.changeCount
      : item.pc;
  const count = toNumber(countVal) || 0;

  return (unitPrice || 0) * count;
};
