const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const parser=require('@babel/parser');
const compiler=require('vue-template-compiler');
const source=compiler.parseComponent(fs.readFileSync('src/components/order/myOrder/drawerMyOrder.vue','utf8'));
const options=parser.parse(source.script.content,{sourceType:'module'}).program.body.find(n=>n.type==='ExportDefaultDeclaration').declaration;
const watchNode=options.properties.find(n=>n.key.name==='watch').value;
const watcher=vm.runInNewContext('('+source.script.content.slice(watchNode.start,watchNode.end)+')',{eventVue:{$on(){},$off(){}},window:{stopLoopReadCard(){}}}).showDrawer;
function context(item){return {status:99,currentItemInfo:item,formData:{reason:'',originAe:'旧人',aes:{sales_name:'上次选择',sales_emp_id:9,sales_phone:'',sales_info_option:[{id:9}]}}};}
test('original author binds to displayed authorization name, not ordering person',()=>{
 const ctx=context({ae:2,authInfo:{name:'授权人甲'},personInfo:{name:'下单人乙'}});
 watcher.call(ctx,true);
 assert.equal(ctx.formData.originAe,'授权人甲');
 assert.match(source.template.content,/label="原授权人：">\{\{\s*formData\.originAe/);
 assert.equal(ctx.formData.aes.sales_emp_id,'');
 assert.equal(ctx.formData.aes.sales_name,'');
});
test('reopening an order without author clears previous name without throwing',()=>{
 const ctx=context({ae:2,authInfo:{name:'授权人甲'}});watcher.call(ctx,true);
 ctx.currentItemInfo={ae:0,personInfo:{name:'下单人乙'}};
 watcher.call(ctx,true);
 assert.equal(ctx.formData.originAe,'');
 assert.equal(ctx.formData.aes.sales_info_option.length,0);
 assert.match(source.template.content,/formData\.originAe\s*\|\|\s*'—'/);
});
test('authorization drawer template compiles',()=>assert.deepEqual(compiler.compile(source.template.content).errors,[]));
