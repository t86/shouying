const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const compiler = require('vue-template-compiler');
const Vue = require('vue');

function load(name, getFcPrice) {
  const source = fs.readFileSync(`src/components/money/${name}.vue`, 'utf8');
  const parsed = compiler.parseComponent(source);
  const sandbox = { module: { exports: {} } };
  const script = parsed.script.content.replace(/import\s+([\s\S]*?)\s+from\s+['"][^'"]+['"];?/g, (_, names) => {
    names.replace(/[{}]/g, '').split(',').map(x => x.trim()).filter(Boolean).forEach(name => { sandbox[name] = function () {}; });
    return '';
  }).replace('export default', 'module.exports =');
  sandbox.getFcPrice = getFcPrice;
  sandbox.resolveUnitPrice = item => Number(item.p2 || item.pp);
  sandbox.calcItemAmount = item => Number(item.p2 || item.pp) * Number(item.changeCount || item.pc);
  vm.runInNewContext(script, sandbox);
  const context = { ...sandbox.module.exports.methods, $store: {state: {cardPageInfo: {resResultDataObj: {price: 60}}}} };
  context.getPriceContext = () => ({});
  return { context, parsed };
}

for (const name of ['notPayOrder', 'payedOrder']) {
  test(`${name}: matched scheme overrides old member price and displays original without mutating amounts`, () => {
    let args;
    const {context: c, parsed} = load(name, (...values) => {args = values; return values[3].price;});
    const item = {pid: 12, ae: 22, wei: 33, pp: '100', p2: '80', pa: '160', pc: 2, changeCount: 1, at: 8};
    const before = JSON.stringify(item);
    assert.equal(c.getDisplayPrice(item), '60.00');
    assert.equal(args[0],12); assert.equal(args[1],22); assert.equal(args[2],33);
    assert.equal(c.showOriginalUnit(item),true);
    assert.equal(c.originalUnit(item),'100.00');
    assert.equal(c.getSubtotal(item),name === 'notPayOrder' ? '60.00' : '120.00');
    assert.equal(c.originalSubtotal(item),name === 'notPayOrder' ? '100.00' : '200.00');
    assert.equal(c.showOriginalSubtotal(item),true);
    assert.equal(JSON.stringify(item),before);
    assert.equal(compiler.compile(parsed.template.content).errors.length,0);
    assert.equal((parsed.template.content.match(/class="fc-price-stack"/g)||[]).length,4);
  });
  test(`${name}: zero/equal/no-scheme and free-order states retain their semantics`, () => {
    const {context: c} = load(name, () => 0);
    const item = {pp:'100',p2:'80',pa:'160',pc:2,at:8};
    assert.equal(c.getDisplayPrice(item),'0.00');
    assert.equal(c.getSubtotal(item),'0.00');
    assert.equal(c.showOriginalUnit(item),true);
    c.schemePrice = () => 100;
    assert.equal(c.showOriginalUnit(item),false);
    assert.equal(c.showOriginalSubtotal(item),false);
    c.schemePrice = () => null;
    assert.equal(c.getDisplayPrice(item),'80.00');
    assert.equal(c.getSubtotal(item),'160.00');
    assert.equal(c.showOriginalUnit(item),false);
    assert.equal(c.showOriginalSubtotal(item),false);
    c.schemePrice = () => 60;
    item.at = 2;
    assert.equal(c.getSubtotal(item),'0.00');
    assert.equal(c.showOriginalSubtotal(item),false);
  });
  test(`${name}: rendering depends on current metadata and current author identity`, async () => {
    const {context: c} = load(name, (pid,ae,wei,metadata) => metadata.prices[ae || wei] === undefined ? null : metadata.prices[ae || wei]);
    const data = {item: {pid:12,ae:22,wei:33,pp:'100',p2:'80',pc:2}, metadata: {prices: {22:60,33:50}}};
    const instance = new Vue({data: () => data, computed: {price() {
      c.$store.state.cardPageInfo.resResultDataObj = this.metadata;
      return c.getDisplayPrice(this.item);
    }}});
    assert.equal(instance.price,'60.00');
    instance.metadata.prices[22] = 40;
    await Vue.nextTick();
    assert.equal(instance.price,'40.00');
    instance.item.ae = 0;
    await Vue.nextTick();
    assert.equal(instance.price,'50.00');
    instance.item.ae = 99;
    await Vue.nextTick();
    assert.equal(instance.price,'80.00');
    instance.$destroy();
  });
}

test('paid display preserves existing online benefit-2 handling and time-price fallback', () => {
  const {context: c} = load('payedOrder', () => null);
  const item = {pp:0,pa:'120',pc:2,at:3,io:1};
  assert.equal(c.getDisplayPrice(item),'时价');
  assert.equal(c.getSubtotal(item),'120.00');
  assert.equal(c.getSubtotal(item,true),'0.00');
});
