function getLookupValue(lookups, methodName, value) {
  if (!lookups || typeof lookups[methodName] !== 'function') return {};

  try {
    return lookups[methodName](value) || {};
  } catch (error) {
    return {};
  }
}

function transformPackageItems(items, lookups) {
  if (!Array.isArray(items)) return items;

  return items.map((item) => {
    const packageItem = item && typeof item === 'object' ? { ...item } : {};
    packageItem.groupInfo = getLookupValue(lookups, 'getProductInfoFromGroup', packageItem.i);
    return packageItem;
  });
}

function enrichConsumptionRecord(record, lookups) {
  const source = record && typeof record === 'object' ? record : {};
  const { bs, si, ...fields } = source;

  return {
    ...fields,
    si: transformPackageItems(si, lookups),
    productInfo: getLookupValue(lookups, 'getProductInfo', source.pid),
    personInfo: source.wei == 0
      ? { name: '自助' }
      : getLookupValue(lookups, 'getOrderPersonInfo', source.wei),
    authInfo: getLookupValue(lookups, 'getOrderPersonInfo', source.ae),
    showList: false,
  };
}

function transformConsumptionRecords(records, lookups) {
  if (!Array.isArray(records)) return [];

  return records.reduce((rows, record) => {
    const source = record && typeof record === 'object' ? record : {};
    const parent = enrichConsumptionRecord(source, lookups);
    const returns = Array.isArray(source.bs) ? source.bs : [];

    if (!returns.length) {
      rows.push(parent);
      return rows;
    }

    if (source.pc != 0) rows.push(parent);

    returns.forEach((returnRecord) => {
      const returned = returnRecord && typeof returnRecord === 'object' ? returnRecord : {};
      const returnRow = enrichConsumptionRecord({
        ...source,
        ...returned,
        si: Array.isArray(returned.si) ? returned.si : source.si,
      }, lookups);

      rows.push({ ...returnRow, back: true });
    });

    return rows;
  }, []);
}

function toAmount(value) {
  const amount = Number(value);
  return (Number.isFinite(amount) ? amount / 100 : 0).toFixed(2);
}

function normalizeOrderDetailResponse(data, lookups) {
  const response = data && typeof data === 'object' ? data : {};
  const payInfo = response.pay_info && typeof response.pay_info === 'object'
    ? response.pay_info
    : {};
  const orderAmount = Number(payInfo.order_amt);
  const payedAmount = Number(payInfo.payed_amt);
  const normalizedOrderAmount = Number.isFinite(orderAmount) ? orderAmount : 0;
  const normalizedPayedAmount = Number.isFinite(payedAmount) ? payedAmount : 0;

  return {
    consumptionRows: transformConsumptionRecords(response.records, lookups),
    wineRows: Array.isArray(response.wine_ops) ? [...response.wine_ops] : [],
    payInfo: {
      allAmt: toAmount(normalizedOrderAmount),
      giveAmt: toAmount(payInfo.yh_amt),
      notPayAmt: toAmount(normalizedOrderAmount - normalizedPayedAmount),
    },
  };
}

function getDetailCacheKey(seatId, turnoverCnt) {
  return `${seatId}:${turnoverCnt}`;
}

function createDetailRequestState() {
  const cache = new Map();
  let currentRequest = 0;

  return {
    startRequest() {
      currentRequest += 1;
      return currentRequest;
    },
    isCurrent(token) {
      return token === currentRequest;
    },
    get(key) {
      return cache.get(key);
    },
    set(key, value) {
      cache.set(key, value);
    },
    clear() {
      cache.clear();
      currentRequest += 1;
    },
  };
}

module.exports = {
  transformConsumptionRecords,
  normalizeOrderDetailResponse,
  getDetailCacheKey,
  createDetailRequestState,
};
