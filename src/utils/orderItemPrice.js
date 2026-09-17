import { getProductPrice } from "./priceCalculator";
import { getFcPrice } from "./fcPrice";

const toNumber = (val) => {
  if (val === undefined || val === null || val === "") return null;
  const num = Number(val);
  return Number.isNaN(num) ? null : num;
};

const getCurrentBusiness = (cardInfo, businessData) => {
  if (!cardInfo || !businessData || !businessData.length) return null;
  const seatId = cardInfo.seatId || cardInfo.id;
  if (!seatId) return null;
  return businessData.find((item) => item.seatId * 1 === seatId * 1);
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

/**
 * 获取当前订单项单价（方案价 > p2 实际价 > 商务价 > 原价pp）
 * 注意：pm 会员价仅用于展示，不参与计算
 * 返回 null 表示使用"时价"展示
 */
export const resolveUnitPrice = (item, ctx = {}) => {
  if (!item) return null;

  const schemePrice = getFcPrice(item.pid || (item.productInfo && item.productInfo.id), item.ae, item.wei, ctx);
  if (schemePrice !== null) return schemePrice;

  // 时价商品：pp = 0 时，返回 null 表示使用"时价"展示
  const pp = toNumber(item.pp);
  if (pp === 0) {
    return null;
  }

  // 优先使用 p2（实际价格，后端已根据会员状态计算好）
  const hasP2 = Object.prototype.hasOwnProperty.call(item, "p2");
  const p2 = toNumber(item.p2);
  if (hasP2 && p2 !== null) {
    return p2;
  }

  // 如果没有 p2，使用商务价计算
  const cardInfo = ctx.cardInfo;
  const businessData = ctx.businessData;
  const businessEmpList = ctx.businessEmpList || [];
  const currentBusiness = getCurrentBusiness(cardInfo, businessData);

  if (item.productInfo && cardInfo && currentBusiness) {
    const calcPrice = getProductPrice(
      item.productInfo,
      cardInfo,
      currentBusiness,
      businessEmpList
    );
    const calcNumber = toNumber(calcPrice);
    if (calcNumber !== null && calcNumber !== 0) {
      return calcNumber;
    }
  }

  // 最后使用原价 pp（不使用 pm 会员价，因为会员价仅用于展示）
  if (pp === null || pp === 0) {
    return null;
  }

  return pp;
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

  const schemePrice = getFcPrice(item.pid || (item.productInfo && item.productInfo.id), item.ae, item.wei, ctx);
  if (schemePrice !== null) {
    const count = item.changeCount !== undefined && item.changeCount !== null ? item.changeCount : item.pc;
    return Math.round(schemePrice * 100 * (toNumber(count) || 0)) / 100;
  }

  // 时价商品：pp = 0 时，直接使用 pa（实际金额）作为小计
  const pp = toNumber(item.pp);
  if (pp === 0) {
    const pa = toNumber(item.pa);
    return pa === null ? 0 : pa;
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

  // 退款沿用订单已记录的价格，不能因当前方案调价而重新计算历史退款。
  const unitPrice = resolveUnitPrice(item, { ...ctx, fcProductPrices: [] });
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
