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
  sandbox.resolveUnitPrice = item => Number(item.p2 !== undefined ? item.p2 : item.pp);
  sandbox.calcItemAmount = item => Number(item.p2 !== undefined ? item.p2 : item.pp) * Number(item.changeCount || item.pc);
  vm.runInNewContext(script, sandbox);
  const context = { ...sandbox.module.exports.methods, $store: {state: {cardPageInfo: {resResultDataObj: {price: 60}}}} };
  context.getPriceContext = () => ({});
  return { context, parsed };
}

for (const name of ['notPayOrder', 'payedOrder']) {
  test(`${name}: recorded prices survive metadata changes and show historical discount`, () => {
    const {context: c, parsed} = load(name, () => 200);
    const item = {pid:12, ae:22, pp:'1200', p2:'1000', pa:'2000', pc:2, changeCount:1, at:8};
    assert.equal(c.getDisplayPrice(item), '1000.00');
    assert.equal(c.getSubtotal(item), name === 'notPayOrder' ? '1000.00' : '2000.00');
    assert.equal(c.showOriginalUnit(item), true);
    assert.equal(c.showOriginalSubtotal(item), true);
    c.$store.state.cardPageInfo.resResultDataObj = {};
    assert.equal(c.getDisplayPrice(item), '1000.00');
    assert.equal(c.showOriginalUnit(item), true);
    item.p2='200'; item.pa='400';
    assert.equal(c.getDisplayPrice(item), '200.00');
    assert.equal(c.getSubtotal(item), name === 'notPayOrder' ? '200.00' : '400.00');
    assert.equal(compiler.compile(parsed.template.content).errors.length,0);
  });
  test(`${name}: zero recorded price and free items remain zero`, () => {
    const {context:c} = load(name, () => 500);
    const item = {pp:'100',p2:'0',pa:'0',pc:2,at:8};
    assert.equal(c.getDisplayPrice(item),'0.00');
    assert.equal(c.getSubtotal(item),'0.00');
    assert.equal(c.showOriginalUnit(item),true);
    item.p2='100'; item.pa='200';
    assert.equal(c.showOriginalUnit(item),false);
    assert.equal(c.showOriginalSubtotal(item),false);
    item.at=2;
    assert.equal(c.getSubtotal(item),'0.00');
    assert.equal(c.showOriginalSubtotal(item),false);
  });
}
test('paid display preserves online benefit-2 and time-price recorded amount', () => {
  const {context:c}=load('payedOrder', () => 100);
  const item={pp:0,pa:'120',pc:2,at:3,io:1};
  assert.equal(c.getDisplayPrice(item),'时价');
  assert.equal(c.getSubtotal(item),'120.00');
  assert.equal(c.getSubtotal(item,true),'0.00');
});
