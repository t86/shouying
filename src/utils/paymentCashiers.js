// Match payment orders, never payment channels or the currently logged-in employee.
export async function loadPaymentCashiers(fetchPage, key, paymentIds, isCurrent) {
  const pending = new Set(paymentIds.map(String));
  const names = {};
  let page = 1;
  while (pending.size && isCurrent()) {
    const res = await fetchPage({ key, page_num: page, page_size: 100 });
    if (!isCurrent()) return {};
    if (res.code !== 1) throw new Error(res.msg || "获取结账人失败");
    const data = res.data || {};
    const records = data.records || [];
    records.forEach((record) => {
      const id = String(record.id);
      if (!pending.has(id)) return;
      names[id] = record.pe || "";
      pending.delete(id);
    });
    const pageSize = Number(data.page_size) || 100;
    const pageCount = Number(data.page_cnt) || Math.ceil(Number(data.row_cnt) / pageSize);
    if (!records.length || (pageCount ? page >= pageCount : records.length < pageSize)) break;
    page += 1;
  }
  return names;
}

export function formatPaymentCashier(name, isOnline) {
  const value = (name || "").trim();
  if (value && value !== "-" && value !== "--") return value;
  return isOnline ? "自助收银" : "--";
}
