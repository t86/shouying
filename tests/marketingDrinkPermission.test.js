const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('fs');
const vm=require('vm');
const compiler=require('vue-template-compiler');
const component=compiler.parseComponent(fs.readFileSync('src/views/ManagementSystem/BMS/stationConfig/stationConfigCom/drawerRoleAuth.vue','utf8'));
const options=vm.runInNewContext(component.script.content.replace('export default','(').trim().replace(/;$/, '')+')');
// The ID is synthetic; the production ID and default are supplied by the server.
const permissionId=900136;
async function fixture(state=2){
 let saved;
 const ctx={...options.data(),...options.methods,checkedList:[{id:100}],$message:{success(){},warning(){assert.fail('unexpected warning');}},$emit(){},$api:{BMS:{station:{
 reGetSysRolesAndAuthModule:async()=>({code:1,data:{sys_roles:[{id:3,n:'营销',st:1}],sys_role_modules:[{id:permissionId,n:'手机端查看特饮业绩',r:'营销',st:state}]}}),
 reSetSysRolesAuthModule:async p=>{saved=p;return {code:1};},
 }}}};
 await ctx.getDetail();
 return {ctx,saved:()=>saved};
}
test('server-provided marketing drink permission appears unchecked by default and only saves when enabled',async()=>{
 const {ctx,saved}=await fixture();const group=ctx.subList[0],item=group.val[0];
 assert.equal(group.t,'营销权限');assert.equal(item.n,'手机端查看特饮业绩');assert.equal(item.checked,false);
 assert.equal(ctx.isHiddenSpecialPermission(group.t,item.id),false);
 await ctx.onSubmit();assert.equal(saved().sel_sys_modules.includes(permissionId),false);
 item.checked=true;ctx.subCheckboxHandle(item);await ctx.onSubmit();assert.equal(saved().sel_sys_modules.includes(permissionId),true);
 item.checked=false;ctx.subCheckboxHandle(item);await ctx.onSubmit();assert.equal(saved().sel_sys_modules.includes(permissionId),false);
});
test('already configured permission is restored from server rather than forcibly reset',async()=>{
 const {ctx}=await fixture(1);assert.equal(ctx.subList[0].val[0].checked,true);
});
