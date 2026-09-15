export function yuanToCents(value) {
  const text = String(value).trim();
  if (!/^\d+(\.\d{1,2})?$/.test(text)) throw new Error('请输入非负金额，最多两位小数');
  const parts = text.split('.');
  const cents = Number(parts[0]) * 100 + Number(((parts[1] || '') + '00').slice(0, 2));
  if (!Number.isSafeInteger(cents)) throw new Error('金额过大');
  return cents;
}

export function centsToYuan(value) {
  const cents = Number(value);
  return `${Math.floor(cents / 100)}.${String(cents % 100).padStart(2, '0')}`;
}

export function priceFor(product, plan, prices) {
  const price = prices.find(row => String(row.id) === String(product.id) && String(row.p) === String(plan.id));
  return price && price.a !== null && price.a !== undefined ? price.a : product.p;
}

export function isUnavailable(row, kind, selected) {
  return (kind === 'products' ? Number(row.c) === 1 : Number(row.s) === 2) ||
    selected.some(item => String(item.id) === String(row.id));
}

export function addSelection(selected, rows, kind) {
  const result = selected.slice();
  rows.forEach(row => {
    if (!isUnavailable(row, kind, result)) result.push(row);
  });
  return result;
}

export function responseData(response) {
  if (!response || response.code !== 1) throw new Error((response && response.msg) || '操作失败');
  return response.data || {};
}
