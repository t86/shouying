const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),compiler=require('vue-template-compiler');
function helpers(){const s={};vm.runInNewContext(fs.readFileSync('src/utils/hlReportAmounts.js','utf8').replace(/export /g,''),s);return s;}
test('report displays recorded original and scheme amounts with zero and missing originals handled',()=>{
 const {reportAmounts}=helpers();
 assert.equal(reportAmounts({sa:'1000',a:'900'}).original,'1000.00');
 assert.equal(reportAmounts({sa:'1000',a:'900'}).actual,'900.00');
 assert.equal(reportAmounts({sa:'1000',a:'0'}).changed,true);
 assert.equal(reportAmounts({sa:'900.00',a:900}).changed,false);
 assert.equal(reportAmounts({a:'900'}).changed,false);
 assert.equal(reportAmounts({sa:null,a:'900'}).original,'900.00');
 assert.equal(reportAmounts({sa:0,a:0}).changed,false);
});
test('totals sum both stored amounts in cents without mutating source rows',()=>{
 const rows=[{sa:'1000',a:'900'},{a:'0.10'},{sa:'0.30',a:'0.20'}];
 const result=helpers().sumReportAmounts(rows);
 assert.equal(result.sa,'1000.40');assert.equal(result.a,'900.30');assert.equal(rows.length,3);
});
for(const name of ['drawerTYDetail','newDrawerTYDetail','drawerTYHZ'])test(name+' renders both values and preserves original amounts returned by API',()=>{
 const p=compiler.parseComponent(fs.readFileSync('src/components/money/'+name+'.vue','utf8'));
 assert.match(p.template.content,/reportAmounts\(item\)\.changed/);
 assert.match(p.template.content,/reportAmounts\(item\)\.original/);
 assert.match(p.template.content,/方案价/);
 assert.deepEqual(compiler.compile(p.template.content).errors,[]);
 if(name!=='drawerTYHZ')assert.match(p.script.content,/sumReportAmounts\(this\.tableData\)/);
});
for(const name of ['drawerTYDetail','newDrawerTYDetail','drawerTYHZ'])test(name+' loads recorded prices and detail total without mutating the response',async()=>{
 const parsed=compiler.parseComponent(fs.readFileSync('src/components/money/'+name+'.vue','utf8'));
 const records=[{a:'900',sa:'1000'},{a:'50'}];const response={code:1,data:{records}};
 const scope={...helpers(),module:{exports:{}},api_money:{reqGetTYList:async()=>response,reqGetTYHZList:async()=>response},api_order:{reqGetYHListByord:async()=>response},console:{log(){}}};
 vm.runInNewContext(parsed.script.content.replace(/^import .*;\s*$/gm,'').replace('export default','module.exports ='),scope);
 const c={...scope.module.exports.methods,keyword:'',keyboardLeave(){},isOrder:()=>true,$message:{warning:assert.fail}};
 await c.getTableData();assert.equal(c.tableData[0].sa,'1000');assert.equal(records.length,2);
 if(name!=='drawerTYHZ') {assert.equal(c.tableData[2].sa,'1050.00');assert.equal(c.tableData[2].a,'950.00');}
});
