// 58/59 号元数据的金额为分；订单和购物车价格使用元。null 表示未匹配方案。
export function getFcPrice(prdId, authorId, orderEmpId, metadata = {}) {
  const employeeId = Number(authorId) > 0 ? authorId : orderEmpId;
  if (!prdId || !(Number(employeeId) > 0)) return null;
  const employees = metadata.fcPlanEmployees || [];
  const prices = metadata.fcProductPrices || [];
  const employee = employees.find(row => Number(row.status) === 1 && String(row.emp_id) === String(employeeId));
  if (!employee) return null;
  const price = prices.find(row => Number(row.status) === 1 &&
    String(row.prd_id) === String(prdId) && String(row.plan_id) === String(employee.plan_id));
  if (!price || price.pay_amt === null || price.pay_amt === undefined || String(price.pay_amt).trim() === '') return null;
  const cents = Number(price.pay_amt);
  return Number.isSafeInteger(cents) && cents >= 0 ? cents / 100 : null;
}
