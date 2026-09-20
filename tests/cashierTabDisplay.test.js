const test=require('node:test');const assert=require('node:assert/strict');const fs=require('fs');const vm=require('node:vm');const parser=require('@babel/parser');const compiler=require('vue-template-compiler');
const source=compiler.parseComponent(fs.readFileSync('src/views/Money/payOrder.vue','utf8'));
const options=parser.parse(source.script.content,{sourceType:'module'}).program.body.find(n=>n.type==='ExportDefaultDeclaration').declaration;
const computed=options.properties.find(n=>n.key.name==='computed').value;
const helpers={};
if(fs.existsSync('src/utils/cashierTabAmounts.js'))vm.runInNewContext(fs.readFileSync('src/utils/cashierTabAmounts.js','utf8').replace(/export /g,''),helpers);
vm.runInNewContext(fs.readFileSync('src/utils/orderSummary.js','utf8').replace(/export /g,''),helpers);
const getters=vm.runInNewContext('('+source.script.content.slice(computed.start,computed.end)+')',helpers);
function ctx(){const c={payTabInfo:{activePayId:0},turnOverInfo:{activeTurnOverCount:0},$store:{state:{orderInfo:{currentCardInfo:{seatId:1}}}},cashierRowsKey:'[1,0]',notPayData:{notPayOrderList:[]},orderSummaryInfo:{order_amt:80000,discount_amt:10000,payed_amt:80000},orderSummaryKey:'[1,0]',payedData:{payedOrderInfo:{amts:{o:'800',pv:'800'}},payedOrderList:[{pp:900,p2:800,pa:800,pc:1},{pp:700,pa:700,pc:1,back:true}]}};
for(const name of ['orderSummary','unpaidOrderAmount','paidOrderOriginalAmount','paidOrderDiscount']) if(getters[name]) Object.defineProperty(c,name,{get:()=>getters[name].call(c)});return c;}
test('empty unpaid tab shows zeros while all-consumption tab retains full summary',()=>{const c=ctx();assert.equal(c.orderSummary.allAmt,'0.00');assert.equal(c.orderSummary.discountAmt,'0.00');c.payTabInfo.activePayId=-1;assert.equal(c.orderSummary.allAmt,'900.00');assert.equal(c.orderSummary.discountAmt,'100.00');});
test('paid tab displays recorded original 900 and discount 100, excludes return rows',()=>{const c=ctx();c.payTabInfo.activePayId=8;assert.equal(c.paidOrderOriginalAmount,'900.00');assert.equal(c.paidOrderDiscount,'100.00');c.payedData.payedOrderList=[{pp:500,pa:450,pc:1}];c.payedData.payedOrderInfo.amts={o:'450',pv:'430'};assert.equal(c.paidOrderOriginalAmount,'500.00');assert.equal(c.paidOrderDiscount,'70.00');});
test('unpaid tab uses remaining quantity rather than current checkout selection',()=>{const c=ctx();c.notPayData.notPayOrderList=[{pp:900,p2:800,pa:1600,pc:2,checkout:false,changeCount:1}];assert.equal(c.orderSummary.allAmt,'1800.00');assert.equal(c.unpaidOrderAmount,'1600.00');c.cashierRowsKey='';assert.equal(c.orderSummary.allAmt,'--');});
test('paid template binds to the row-based original amount',()=>{assert.match(source.template.content,/paidOrderOriginalAmount/);assert.deepEqual(compiler.compile(source.template.content).errors,[]);});
test('real tab-switch handlers change paid amounts and return to zero on empty unpaid tab',async()=>{
 const methodsNode=options.properties.find(n=>n.key.name==='methods').value;
 const methods=vm.runInNewContext('('+source.script.content.slice(methodsNode.start,methodsNode.end)+')',{setTimeout(){},console:{log(){}}});
 const c=Object.assign(ctx(),methods);
 c.cardAllOrderInfo=[{pid:0,list:[]},{pid:8,list:[{id:1,pp:900,pa:800,pc:1,bs:[{id:2,pp:700,pa:700,pc:1}]}],amts:{o:800,pv:800}},{pid:9,list:[{id:3,pp:500,pa:450,pc:1}],amts:{o:450,pv:450}}];
 await c.changeTab('order',8,false);assert.equal(c.paidOrderOriginalAmount,'900.00');assert.equal(c.paidOrderDiscount,'100.00');
 await c.changeTab('order',9,false);assert.equal(c.paidOrderOriginalAmount,'500.00');assert.equal(c.paidOrderDiscount,'50.00');
 await c.changeTab('order',0,false);assert.equal(c.orderSummary.allAmt,'0.00');assert.equal(c.orderSummary.discountAmt,'0.00');
});
