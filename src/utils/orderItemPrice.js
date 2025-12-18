import { getProductPrice } from "./priceCalculator";

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
  };
};

/**
 * 获取订单项的实际单价（优先级：p2 实际价 > 商务价 > 原价pp）
 * 注意：pm 会员价仅用于展示，不参与计算
 * 返回 null 表示使用"时价"展示
 */
export const resolveUnitPrice = (item, ctx = {}) => {
  if (!item) return null;

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
  const pp = toNumber(item.pp);
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

export const isTimePriceItem = (item, ctx = {}) => {
  const unitPrice = resolveUnitPrice(item, ctx);
  if (unitPrice === null || Number.isNaN(unitPrice)) {
    const pp = toNumber(item ? item.pp : null);
    return pp === 0;
  }
  return false;
};

export const calcItemAmount = (item, ctx = {}) => {
  if (!item) return 0;
  if (item.at == 2 || item.at == 3) return 0;

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

