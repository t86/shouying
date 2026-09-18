const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const parser = require('@babel/parser');
const root = path.join(__dirname, '../src');
const priceScope = {};
vm.runInNewContext(fs.readFileSync(path.join(root, 'utils/fcPrice.js'), 'utf8').replace(/export /g, ''), priceScope);
const { getFcPrice } = priceScope;
const mixinScope = { getFcPrice, module: {exports:{}} };
vm.runInNewContext(fs.readFileSync(path.join(root,'components/order/fcPriceMixin.js'),'utf8').replace(/^import .*;$/m,'').replace('export default','module.exports ='),mixinScope);
const mixin = mixinScope.module.exports.methods;
function methods(file, injected = {}, section = "methods") {
  const text = fs.readFileSync(path.join(root,file),'utf8');
  const script = text.match(/<script>([\s\S]*?)<\/script>/)[1];
  const ast = parser.parse(script,{sourceType:'module'});
  const options = ast.program.body.find(node => node.type === 'ExportDefaultDeclaration').declaration;
  const prop = options.properties.find(node => node.key.name === section);
  const methodCode = script.slice(prop.value.start, prop.value.end);
  const context = { getProductPrice: () => '999.00', ...injected };
  return vm.runInNewContext('('+methodCode+')',context);
}
function context() {
  return { ...mixin, $store:{state:{userInfo:{emp_id:2},orderInfo:{currentCardInfo:{seatId:1}},cardPageInfo:{resResultDataObj:{
    fcPlanEmployees:[{emp_id:2,plan_id:3,status:1},{emp_id:4,plan_id:5,status:1}],
    fcProductPrices:[{prd_id:1,plan_id:3,pay_amt:0,status:1},{prd_id:1,plan_id:5,pay_amt:1234,status:1}],
  }}},dispatch(){}}, $message:{success(){},warning(){}},onCancelDrawer(){} };
}
test('uses row author ahead of ordering employee without fallback for unmatched author',()=>{
  const ctx=context();
  assert.equal(ctx.fcOrderPrice({pid:1,ae:4,wei:2}),12.34);
  assert.equal(ctx.fcOrderPrice({pid:1,ae:9,wei:2}),null);
  assert.equal(ctx.fcOrderPrice({pid:1,ae:0,wei:2}),0);
  ctx.$store.state.cardPageInfo.resResultDataObj.fcProductPrices[0].pay_amt=450;
  assert.equal(ctx.fcOrderPrice({pid:1,ae:0,wei:2}),4.5);
});
test('add_hl sends only prd_amt: fixed prices stay empty, time prices use scheme totals including zero',()=>{
  const ctx=context();
  for (const prdType of [13,14]) {
    const fixed=ctx.fcApplyAmount({prd_cnt:2,prd_amt:'999',prd_price:'100'},{id:1,prdType});
    assert.equal(Object.hasOwn(fixed,'prd_price'),false);assert.equal(fixed.prd_amt,'');
  }
  const zero=ctx.fcApplyAmount({prd_cnt:1,prd_amt:'100'},{id:1,prdType:4});
  assert.equal(zero.prd_amt,'0.00');assert.equal(Object.hasOwn(zero,'prd_price'),false);
  ctx.$store.state.cardPageInfo.resResultDataObj.fcProductPrices[0].pay_amt=29;
  const timed=ctx.fcApplyAmount({prd_cnt:3,prd_amt:'999',relate_csm_id:7},{id:1,prdType:3});
  assert.equal(Object.hasOwn(timed,'prd_price'),false);assert.equal(timed.prd_amt,'0.87');
  assert.equal(timed.relate_csm_id,7);
  const unchanged=ctx.fcApplyAmount({prd_cnt:1,prd_amt:'88',prd_price:'77'},{id:999,prdType:3});
  assert.equal(unchanged.prd_amt,'88');assert.equal(Object.hasOwn(unchanged,'prd_price'),false);
});
test('ordinary add_prd still sends its documented prd_price',()=>{
  const ctx=context();
  assert.equal(ctx.fcApplyPrice({prd_cnt:2,prd_amt:''},{id:1,prdType:7}).prd_price,'0.00');
  const plain={prd_price:'77',prd_amt:'88'};
  assert.strictEqual(ctx.fcApplyPrice(plain,{id:999,prdType:3}),plain);
  assert.equal(plain.prd_price,'77');
});
for(const variant of ['drawerMeal','newDrawerMeal']) {
  test(variant+' actual add_hl caller sends contract-compliant fixed and time-price amounts',async()=>{
    let payload;
    const ctx=context();
    const api_order={reqAddAmtToShopping:async params=>{payload=params;return {code:1};}};
    const method=methods('components/order/'+variant+'/singleProduct.vue',{api_order}).orderMealToShoppingCart;
    Object.assign(ctx,{productInfo:{id:1,prdType:13},count:2,requestInfoArr:[],amt:'',isSubmitting:true});
    await method.call(ctx,2,false);
    assert.equal(Object.hasOwn(payload,'prd_price'),false);assert.equal(payload.prd_cnt,2);
    assert.equal(payload.prd_amt,'');
    ctx.productInfo.prdType=3;
    ctx.$store.state.cardPageInfo.resResultDataObj.fcProductPrices[0].pay_amt=3300;
    await method.call(ctx,2,false);
    assert.equal(payload.prd_amt,'66.00');
    assert.equal(Object.hasOwn(payload,'prd_price'),false);
  });
}
for(const page of ['shoppingCart','newShoppingCart','myOrder','newMyOrder']) {
 test(page+' displays recorded p2/pa despite current employee scheme',()=>{
   const ctx=context();Object.assign(ctx,methods('views/Order/orderMeal/'+page+'.vue'));
   const row={pid:1,ae:4,wei:2,pc:2,pp:'100',p2:'80',pa:'160',at:0,productInfo:{price:100}};
   assert.equal(ctx.getDisplayPrice(row),'80.00');
   assert.equal(ctx.getSubtotal(row),'160.00');
   assert.equal(row.p2,'80');assert.equal(row.pa,'160');
   row.ae=0;assert.equal(ctx.getDisplayPrice(row),'80.00');assert.equal(ctx.getSubtotal(row),'160.00');
 });
}
for (const page of ['shoppingCart','newShoppingCart']) {
 test(page+' payable total uses recorded amounts while preserving gift exclusions',()=>{
   const file='views/Order/orderMeal/'+page+'.vue';
   const ctx=context();Object.assign(ctx,methods(file));
   ctx.shoppingCartList=[{pid:1,ae:4,wei:2,pc:2,pp:'100',pa:'200',at:0},{pid:1,ae:0,wei:2,pc:5,pp:'100',pa:'500',at:0},{pid:1,ae:4,wei:2,pc:1,pa:'100',at:2}];
   assert.equal(methods(file,{},'computed').amt.call(ctx).allAmt,'700.00');
 });
}
test('original-price indication compares values without rewriting product or order data',()=>{
  const ctx=context(),row={pid:1,ae:4,wei:2,pp:'12.34'};
  assert.equal(ctx.fcOrderOriginal(row,'12.34'),false);
  row.pp='100';assert.equal(ctx.fcOrderOriginal(row,'12.34'),true);
  const product={id:1,prdType:13,price:'100'};
  ctx.fcApplyPrice({prd_cnt:1},product);
  assert.equal(product.price,'100');assert.equal(row.pp,'100');
});
for(const page of ['shoppingCart','newShoppingCart','myOrder','newMyOrder']) {
 test(page+' preserves gift pricing and zero quantity with a matching scheme',()=>{
   const ctx=context();Object.assign(ctx,methods('views/Order/orderMeal/'+page+'.vue'));
   const row={pid:1,ae:4,wei:2,pc:2,pp:'100',pa:'200',at:2};
   assert.equal(ctx.getSubtotal(row),'0.00');
   row.at=3;assert.equal(ctx.getSubtotal(row),'0.00');
   if(ctx.calculateOrderItemAmount) assert.equal(ctx.calculateOrderItemAmount(row),0);
   row.at=0;row.pc=0;assert.equal(ctx.getSubtotal(row),'0.00');
   if(ctx.calculateOrderItemAmount) assert.equal(ctx.calculateOrderItemAmount(row),0);
 });
}
test('original subtotal uses unit price times actual quantity or original time-price amount',()=>{
 const ctx=context();const row={pid:1,ae:4,wei:2,pc:2,pp:'100',pa:'175'};
 assert.equal(ctx.fcOriginalSubtotal(row),200);
 assert.equal(ctx.fcSubtotalOriginal(row,'24.68'),true);
 assert.equal(ctx.fcSubtotalOriginal(row,'200'),false);
 row.pp='0';assert.equal(ctx.fcOrderOriginal(row,'12.34'),false);
 assert.equal(ctx.fcOriginalSubtotal(row),175);
 row.pc=0;row.pp='100';assert.equal(ctx.fcOriginalSubtotal(row),0);
});
test('product real original price survives the prior business-price promotion',()=>{
 const ctx=context();assert.equal(ctx.fcProductOriginalPrice({price:'60',vipPrice:'100'}),100);
 assert.equal(ctx.fcProductOriginalPrice({price:'60'}),60);
 const method=methods('components/order/productList.vue',{getProductPriceInfo:()=>({originalPrice:'60'})}).getProductPriceInfoData;
 const info=method.call(ctx,{id:1,price:'60',vipPrice:'100'});
 assert.equal(info.originalPrice,'100.00');assert.equal(info.memberPrice,'0.00');
});
for (const page of ['myOrder', 'newMyOrder']) {
 test(page+' preserves recorded zero price when no scheme exists', () => {
   const ctx=context();Object.assign(ctx,methods('views/Order/orderMeal/'+page+'.vue'));
   assert.equal(ctx.getDisplayPrice({pid:999,ae:0,wei:2,pp:100,p2:0}),'0.00');
 });
}
