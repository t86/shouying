const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const parser = require('@babel/parser');

function load(page, injected = {}) {
  const source = fs.readFileSync(path.join(__dirname, '../src/views/Order/orderMeal', page + '.vue'), 'utf8');
  const script = source.match(/<script>([\s\S]*?)<\/script>/)[1];
  const options = parser.parse(script, { sourceType: 'module' }).program.body.find(n => n.type === 'ExportDefaultDeclaration').declaration;
  const section = name => {
    const value = options.properties.find(n => n.key.name === name).value;
    return vm.runInNewContext('(' + script.slice(value.start, value.end) + ')', injected);
  };
  return { methods: section('methods'), computed: section('computed') };
}

for (const page of ['shoppingCart', 'newShoppingCart']) {
  test(page + ' keeps recorded prices after metadata and product changes', () => {
    const { methods, computed } = load(page);
    const ctx = { ...methods, fcOrderPrice() { throw new Error('must not recalculate metadata'); } };
    const row = { pp: '800', p2: '777', pa: '1554', pc: 2, at: 0, productInfo: { price: 800 } };
    ctx.shoppingCartList = [row];
    assert.equal(ctx.getDisplayPrice(row), '777.00');
    assert.equal(ctx.getSubtotal(row), '1554.00');
    row.productInfo.price = 999;
    assert.equal(ctx.getDisplayPrice(row), '777.00');
    assert.equal(computed.amt.call(ctx).allAmt, '1554.00');
    // A fresh response after explicitly changing author is the new recorded price.
    Object.assign(row, { ae: 20, p2: '600', pa: '1200' });
    assert.equal(ctx.getDisplayPrice(row), '600.00');
    assert.equal(ctx.getSubtotal(row), '1200.00');
  });
  test(page + ' trusts recorded amount and handles zero, time prices and missing fields', () => {
    const { methods } = load(page);
    const ctx = { ...methods, fcOrderPrice() { throw new Error('must not recalculate metadata'); } };
    assert.equal(ctx.getSubtotal({ pp: 800, p2: 777, pa: 1500, pc: 2 }), '1500.00');
    assert.equal(ctx.getDisplayPrice({ pp: 800, p2: 0, pa: 0, pc: 2 }), '0.00');
    assert.equal(ctx.getSubtotal({ pp: 800, p2: 0, pa: 0, pc: 2 }), '0.00');
    assert.equal(ctx.getSubtotal({ pp: 800, p2: '777', pc: 0 }), '0.00');
    assert.equal(ctx.getSubtotal({ pp: 800, p2: '777', pc: 2 }), '1554.00');
    assert.equal(ctx.getDisplayPrice({ pp: 800, p2: null }), '800.00');
    assert.equal(ctx.getDisplayPrice({ pp: 0, pa: 350 }), '时价');
    assert.equal(ctx.getSubtotal({ pp: 0, pa: 350, pc: 1 }), '350.00');
    assert.equal(ctx.getSubtotal({ pp: 800, p2: 777, pa: 1554, pc: 2, at: 2 }), '0.00');
  });
  test(page + ' quantity update uses response amount without repricing', async () => {
    const { methods } = load(page, { api_order: { reqUpdateShoppingCount: async () => ({ code: 1, data: { prd_amt: 2331 } }) } });
    const ctx = { ...methods, $store: { state: { orderInfo: { currentCardInfo: { seatId: 1 } }, cardPageInfo: { resResultDataObj: { prdOutOfSomething: [] } } }, dispatch() {} } };
    const row = { id: 2, pp: 800, p2: 777, pc: 2, pa: 1554, at: 0 };
    await ctx.changeCount('add', row);
    assert.equal(row.pc, 3);
    assert.equal(row.p2, 777);
    assert.equal(ctx.getSubtotal(row), '2331.00');
  });
}

test('cart original total uses recorded pp while actual total retains pa', () => {
  const {methods,computed}=load('newShoppingCart');
  const ctx={...methods,shoppingCartList:[{pp:1000,p2:900,pa:900,pc:1},{pp:1000,p2:900,pa:900,pc:1}]};
  assert.equal(computed.amt.call(ctx).oriAmt,'2000.00');
  assert.equal(computed.amt.call(ctx).allAmt,'1800.00');
  ctx.shoppingCartList=[{pp:1000,p2:0,pa:0,pc:1},{pp:0,pa:123,pc:1},{pp:1000,pa:900,pc:0},{pp:1000,pa:900,pc:1,at:2}];
  assert.equal(computed.amt.call(ctx).oriAmt,'1123.00');
  assert.equal(computed.amt.call(ctx).allAmt,'123.00');
});
test('cart total labels avoid membership wording',()=>{
 const source=fs.readFileSync(path.join(__dirname,'../src/views/Order/orderMeal/newShoppingCart.vue'),'utf8');
 const template=source.split('</template>')[0];
 assert.doesNotMatch(template,/购物车金额\((?:非会员价|会员价)\)/);
});
