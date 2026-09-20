const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const parser = require('@babel/parser');
const compiler = require('vue-template-compiler');
const parsed = compiler.parseComponent(fs.readFileSync('src/views/Money/payOrder.vue','utf8'));
const ast = parser.parse(parsed.script.content,{sourceType:'module'});
const options = ast.program.body.find(n=>n.type==='ExportDefaultDeclaration').declaration;
const computed = options.properties.find(n=>n.key.name==='computed').value;
function amount(amts) {
 const property = computed.properties.find(n=>n.key.name==='paidOrderDiscount');
 assert.ok(property, 'paid summary exposes the recorded discount');
 const code = parsed.script.content.slice(property.start,property.end);
 const methods = vm.runInNewContext('({' + code + '})');
 return methods.paidOrderDiscount.call({paidOrderOriginalAmount: amts.o,payedData:{payedOrderInfo:{amts}}});
}
test('paid discount combines the recorded original total and actual settlement total without adding free payments twice',()=>{
 assert.equal(amount({o:'1000',pv:'200',pf:'0'}),'800.00');
 assert.equal(amount({o:'1000',pv:'200',pf:'800'}),'800.00');
 assert.equal(amount({o:'0.30',pv:'0.10'}),'0.20');
 assert.equal(amount({o:'100',pv:'100'}),'0.00');
 assert.equal(amount({o:'100',pv:'120'}),'0.00');
});
test('paid discount summary has visible label and compilable template',()=>{
 assert.match(parsed.template.content,/折扣:[\s\S]*?paidOrderDiscount/);
 assert.equal(compiler.compile(parsed.template.content).errors.length,0);
});
