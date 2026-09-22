// 报表 a、sa 均为记录金额（元），不使用当前商品或价格方案重算。
const cents = value => value !== undefined && value !== null && value !== '' && Number.isFinite(Number(value)) ? Math.round(Number(value) * 100) : null;
export function reportAmounts(row) {
  const actual = cents(row.a) || 0;
  const source = cents(row.sa);
  const original = source === null ? actual : source;
  return { original: (original / 100).toFixed(2), actual: (actual / 100).toFixed(2), changed: original !== actual };
}
export function sumReportAmounts(rows) {
  let actual = 0;
  let original = 0;
  (rows || []).forEach(row => {
    const amount = cents(row.a) || 0;
    const source = cents(row.sa);
    actual += amount;
    original += source === null ? amount : source;
  });
  return { a: (actual / 100).toFixed(2), sa: (original / 100).toFixed(2) };
}
