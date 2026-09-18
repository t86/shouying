const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const Vue = require('vue');
const compiler = require('vue-template-compiler');
const file = 'src/components/order/footerCardAmountMixin.js';
function fixture() {
  const mixin = Function(fs.readFileSync(file, 'utf8').replace('export default', 'return'))();
  const store = Vue.observable({ state: { orderInfo: { currentCardInfo: { seatId: 1, turnoverCnt: 2, orderAmt: 1000, payed_val_amt: 1000 } }, cardPageInfo: { resResultDataObj: { businessData: [{ seatId: 1, turnoverCnt: 2, orderAmt: 1000, payed_val_amt: 1000 }] } } } });
  const view = new Vue({ mixins: [mixin], data: () => ({ cardInfo: {} }), beforeCreate() { this.$store = store; } });
  return { view, store };
}
test('footer updates from current server summary after authorization changes while the selected card snapshot stays stale', async () => {
  const { view, store } = fixture();
  try {
    view.refreshFooterCardAmounts();
    store.state.cardPageInfo.resResultDataObj.businessData[0].payed_val_amt = 200;
    await Vue.nextTick();
    assert.equal(view.cardInfo.payed_val_amt, 200);
    assert.equal(store.state.orderInfo.currentCardInfo.payed_val_amt, 1000);
    store.state.cardPageInfo.resResultDataObj.businessData[0].payed_val_amt = 0;
    await Vue.nextTick();
    assert.equal(view.cardInfo.payed_val_amt, 0);
  } finally { view.$destroy(); }
});
test('historical totals stay stable and returning to current turnover reads the latest summary', async () => {
  const { view, store } = fixture();
  try {
    view.footerHistoricalAmounts = true;
    view.cardInfo = { orderAmt: 55, payed_val_amt: 45 };
    store.state.cardPageInfo.resResultDataObj.businessData[0].payed_val_amt = 200;
    await Vue.nextTick();
    assert.equal(view.cardInfo.payed_val_amt, 45);
    view.footerHistoricalAmounts = false;
    view.refreshFooterCardAmounts();
    assert.equal(view.cardInfo.payed_val_amt, 200);
    store.state.cardPageInfo.resResultDataObj.businessData[0] = { seatId: 1, turnoverCnt: 3, payed_val_amt: 999 };
    view.refreshFooterCardAmounts();
    assert.equal(view.cardInfo.payed_val_amt, 1000, 'next turnover cannot leak into the selected turnover');
  } finally { view.$destroy(); }
});
test('both footers wire current and historical events and compile', () => {
  for (const name of ['footBar', 'newFootBar']) {
    const source = compiler.parseComponent(fs.readFileSync('src/components/order/' + name + '.vue', 'utf8'));
    assert.match(source.script.content, /mixins:\s*\[[^\]]*footerCardAmountMixin/);
    assert.match(source.script.content, /this\.footerHistoricalAmounts = true/);
    assert.match(source.script.content, /this\.footerHistoricalAmounts = false/);
    assert.match(source.script.content, /order_zy_amt \+= el\.amts\.oz/);
    assert.deepEqual(compiler.compile(source.template.content).errors, []);
  }
});
