const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const Vue = require('vue');
const compiler = require('vue-template-compiler');

const root = path.join(__dirname, '..');
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');
const fcScope = {};
vm.runInNewContext(read('src/utils/fcPrice.js').replace(/export /g, ''), fcScope);
function loadOptions(source, dependencies = {}) {
  const scope = { ...dependencies, module: { exports: {} } };
  vm.runInNewContext(source.replace(/^import .*;\s*$/gm, '').replace('export default', 'module.exports ='), scope);
  return scope.module.exports;
}
const fcPriceMixin = loadOptions(read('src/components/order/fcPriceMixin.js'), { getFcPrice: fcScope.getFcPrice });
const payOrderPriceMixin = loadOptions(read('src/components/order/payOrderPriceMixin.js'), { fcPriceMixin });
const variants = ['drawerShowOrderList', 'newDrawerShowOrderList'];
function component(name, api_order = {}) {
  const source = compiler.parseComponent(read('src/components/order/' + name + '.vue'));
  return {
    source,
    options: loadOptions(source.script.content, {
      payOrderPriceMixin, api_order, api_money: {}, common_book: {}, common_order: {}, console: { log() {} },
    }),
  };
}
function metadata() {
  return {
    fcPlanEmployees: [{ emp_id: 11, plan_id: 1, status: 1 }, { emp_id: 22, plan_id: 2, status: 1 }],
    fcProductPrices: [{ prd_id: 9, plan_id: 1, pay_amt: 77700, status: 1 }, { prd_id: 9, plan_id: 2, pay_amt: 60000, status: 1 }],
  };
}
function screenshotRows() {
  return [
    { id: 1, pid: 9, ae: 11, wei: 11, pp: '800', p2: '800', pa: '777', pc: 1, checked: true },
    { id: 2, pid: 10, ae: 0, wei: 11, pp: '0.10', p2: '0.10', pa: '0.10', pc: 1, checked: true },
    { id: 3, pid: 9, ae: 22, wei: 22, pp: '800', p2: '800', pa: '800', pc: 1, checked: true },
  ];
}
function store() {
  return Vue.observable({ state: {
    orderInfo: { currentCardInfo: { seatId: '31' } },
    cardPageInfo: { resResultDataObj: metadata() },
  } });
}
function createView(options = { mixins: [payOrderPriceMixin] }) {
  const state = store();
  return new Vue({ ...options, beforeCreate() { this.$store = state; } });
}

for (const name of variants) {
  test(name + ' uses the actual shared mixin for screenshot prices without changing backend rows', () => {
    const view = createView(component(name).options);
    const rows = screenshotRows();
    const before = JSON.stringify(rows);
    try {
      assert.deepEqual(rows.map(row => view.getDisplayPrice(row)), ['777.00', '0.10', '600.00']);
      assert.deepEqual(rows.map(row => view.getSubtotal(row)), ['777.00', '0.10', '600.00']);
      assert.equal(rows.reduce((sum, row) => sum + Number(view.getSubtotal(row)), 0).toFixed(2), '1377.10');
      assert.equal(view.fcOrderOriginal(rows[0], view.getDisplayPrice(rows[0])), true);
      assert.equal(view.fcSubtotalOriginal(rows[2], view.getSubtotal(rows[2])), true);
      assert.equal(view.fcOrderOriginal(rows[1], view.getDisplayPrice(rows[1])), false);
      assert.equal(JSON.stringify(rows), before);
    } finally {
      view.$destroy();
    }
  });

  test(name + ' compiles both online and offline amount cells with original-price indicators', () => {
    const { source } = component(name);
    assert.deepEqual(compiler.compile(source.template.content).errors, []);
    for (const row of ['item', 'items']) {
      assert.match(source.template.content, new RegExp('\\{\\{\\s*getDisplayPrice\\(' + row + '\\)\\s*\\}\\}'));
      assert.match(source.template.content, new RegExp('\\{\\{\\s*getSubtotal\\(' + row + '\\)\\s*\\}\\}'));
      assert.match(source.template.content, new RegExp('!'+ row + '\\.back && fcOrderOriginal\\(' + row));
      assert.match(source.template.content, new RegExp('!'+ row + '\\.back && '+ row +'\\.at != 2 && '+ row +'\\.at != 3 && fcSubtotalOriginal\\(' + row));
    }
  });

  test(name + ' submits deduplicated selected order IDs without client-side amounts', () => {
    const view = createView(component(name).options);
    const events = [];
    view.$emit = (...args) => events.push(args);
    view.$message = { warning(message) { assert.fail(message); } };
    view.tableData = [
      ...screenshotRows(),
      { id: 4, parentOrderId: 1, checked: true, back: true, opc: 1, pa: '800' },
      { id: 5, checked: false, pa: '100' },
      { id: 6, oid: 99, checked: true, pa: '100' },
    ];
    try {
      view.onSubmit();
      assert.deepEqual(JSON.parse(JSON.stringify(events)), [
        ['setNeedPayOrderIdHandle', [1, 2, 3]],
        ['input', false],
      ]);
    } finally {
      view.$destroy();
    }
  });
}

test('Vue 2 updates displayed amounts when scheme metadata, author, quantity or metadata arrays change', async () => {
  const view = createView({
    mixins: [payOrderPriceMixin],
    data: () => ({ row: screenshotRows()[2] }),
    computed: {
      displayPrice() { return this.getDisplayPrice(this.row); },
      subtotal() { return this.getSubtotal(this.row); },
    },
  });
  try {
    assert.equal(view.displayPrice, '600.00');
    assert.equal(view.subtotal, '600.00');
    view.$store.state.cardPageInfo.resResultDataObj.fcProductPrices[1].pay_amt = 50000;
    await Vue.nextTick();
    assert.equal(view.displayPrice, '500.00');
    assert.equal(view.subtotal, '500.00');
    view.row.pc = 2;
    await Vue.nextTick();
    assert.equal(view.subtotal, '1000.00');
    view.row.ae = 11;
    await Vue.nextTick();
    assert.equal(view.displayPrice, '777.00');
    assert.equal(view.subtotal, '1554.00');
    view.row.ae = 0;
    await Vue.nextTick();
    assert.equal(view.displayPrice, '500.00', 'absent author uses the ordering employee');
    view.row.ae = 99;
    await Vue.nextTick();
    assert.equal(view.displayPrice, '800.00', 'an unmatched author must not fall back to the ordering employee');
    assert.equal(view.subtotal, '800.00', 'no matching scheme keeps the recorded subtotal');
    view.row.ae = 22;
    view.$store.state.cardPageInfo.resResultDataObj.fcProductPrices = [];
    await Vue.nextTick();
    assert.equal(view.displayPrice, '800.00');
    view.$store.state.cardPageInfo.resResultDataObj = metadata();
    await Vue.nextTick();
    assert.equal(view.displayPrice, '600.00');
    assert.equal(view.subtotal, '1200.00');
  } finally {
    view.$destroy();
  }
});

test('missing schemes preserve recorded p2/pa values and the existing numeric-zero p2 fallback', () => {
  const view = createView();
  try {
    const row = { pid: 99, ae: 11, wei: 22, pp: 100, p2: 80, pa: 150, pc: 2 };
    assert.equal(view.getDisplayPrice(row), '80.00');
    assert.equal(view.getSubtotal(row), '150.00');
    row.pa = 0;
    assert.equal(view.getSubtotal(row), '0.00', 'recorded zero subtotal is valid');
    delete row.pa;
    assert.equal(view.getSubtotal(row), '160.00');
    row.p2 = 0;
    assert.equal(view.getDisplayPrice(row), '100.00');
    assert.equal(view.getSubtotal(row), '200.00');
    row.p2 = '0';
    assert.equal(view.getDisplayPrice(row), '0.00', 'preserve the established string-zero p2 behavior');
    assert.equal(view.getSubtotal(row), '0.00');
    assert.equal(view.getDisplayPrice(null), '0.00');
    assert.equal(view.getSubtotal(null), '0.00');
  } finally {
    view.$destroy();
  }
});

test('time prices retain their label and recorded subtotal unless a valid scheme supplies a price', () => {
  const view = createView();
  try {
    const row = { pid: 99, ae: 11, pp: '0', p2: 80, pc: 2, pa: '12.34' };
    assert.equal(view.getDisplayPrice(row), '时价');
    assert.equal(view.getSubtotal(row), '12.34');
    delete row.pa;
    assert.equal(view.getSubtotal(row), '0.00');
    row.pid = 9;
    assert.equal(view.getDisplayPrice(row), '777.00');
    assert.equal(view.getSubtotal(row), '1554.00');
  } finally {
    view.$destroy();
  }
});

test('zero scheme prices and zero quantities are valid while gift amounts remain excluded', () => {
  const view = createView();
  try {
    const row = { pid: 9, ae: 11, wei: 22, pp: 800, pa: 1600, pc: 2, at: 0 };
    view.$store.state.cardPageInfo.resResultDataObj.fcProductPrices[0].pay_amt = 0;
    assert.equal(view.getDisplayPrice(row), '0.00');
    assert.equal(view.getSubtotal(row), '0.00');
    view.$store.state.cardPageInfo.resResultDataObj.fcProductPrices[0].pay_amt = 29;
    row.pc = 3;
    assert.equal(view.getSubtotal(row), '0.87');
    row.pc = 0;
    assert.equal(view.getSubtotal(row), '0.00');
    row.pc = 2;
    for (const at of [2, 3, '2', '3']) {
      row.at = at;
      assert.equal(view.getSubtotal(row), '0.00');
      row.pid = 99;
      assert.equal(view.getSubtotal(row), '0.00', 'gift exclusion also applies without a scheme');
      row.pid = 9;
    }
  } finally {
    view.$destroy();
  }
});

test('refund rows keep their recorded unit price and subtotal when current schemes change', () => {
  const view = createView();
  try {
    const row = { pid: 9, ae: 22, wei: 22, pp: 800, p2: 700, pa: 1400, pc: 2, back: true };
    assert.equal(view.getDisplayPrice(row), '700.00');
    assert.equal(view.getSubtotal(row), '1400.00');
    view.$store.state.cardPageInfo.resResultDataObj.fcProductPrices[1].pay_amt = 50000;
    assert.equal(view.getDisplayPrice(row), '700.00');
    assert.equal(view.getSubtotal(row), '1400.00');
  } finally {
    view.$destroy();
  }
});

test('continue payment passes through the backend amount instead of recalculating the payment request', async () => {
  const requests = [];
  const events = [];
  const api_order = {
    async do_continue_waiter_olpay_with_orders(params) {
      requests.push(params);
      return { code: 1, data: { ol_pay_id: 123, pay_amt: '1577.10', pay_url: 'test-payment-url' } };
    },
  };
  const view = createView(component('newDrawerShowOrderList', api_order).options);
  view.tableData = screenshotRows();
  view.$emit = (...args) => events.push(args);
  view.$message = { warning(message) { assert.fail(message); }, error(message) { assert.fail(message); } };
  try {
    await view.continuePayHandle();
    assert.deepEqual(JSON.parse(JSON.stringify(requests)), [{ seat_id: 31 }]);
    assert.deepEqual(JSON.parse(JSON.stringify(events)), [
      ['input', false],
      ['showPayQRDrawer', {
        payType: 3,
        orderInfoDetail: { ol_pay_id: 123, pay_amt: '1577.10', pay_url: 'test-payment-url', force: 2 },
      }],
    ]);
  } finally {
    view.$destroy();
  }
});
