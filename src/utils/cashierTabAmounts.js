const numberOrNull = value => {
  if (value === undefined || value === null || value === '') return null;
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
};

// 按当前页签的订单快照汇总（元）；不读取当前方案，不重复累计退单或套餐子项。
export const summarizeCashierRows = rows => {
  let original = 0;
  let actual = 0;
  let gifts = 0;
  let discount = 0;
  const add = item => {
    if (!item || item.back) return;
    const count = numberOrNull(item.pc);
    if (!(count > 0)) return;
    const pp = numberOrNull(item.pp);
    const p2 = numberOrNull(item.p2);
    const pa = numberOrNull(item.pa);
    const originalCents = Math.round((pp > 0 ? pp * count : (pa || 0)) * 100);
    if (Number(item.at) === 2 || Number(item.at) === 3) {
      gifts += originalCents;
      return;
    }
    const actualCents = Math.round((pa !== null ? pa : (p2 !== null ? p2 : (pp || 0)) * count) * 100);
    original += originalCents;
    actual += actualCents;
    discount += Math.max(originalCents - actualCents, 0);
  };
  (rows || []).forEach(row => {
    if (!row || row.back) return;
    if (row.oid) {
      (row.resultNotPayData || row.os || []).forEach(add);
    } else {
      add(row);
    }
  });
  return {
    allAmt: (original / 100).toFixed(2),
    giveAmt: (gifts / 100).toFixed(2),
    discountAmt: (discount / 100).toFixed(2),
    notPayAmt: (actual / 100).toFixed(2),
  };
};
