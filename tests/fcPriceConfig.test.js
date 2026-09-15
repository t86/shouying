const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const root = path.join(__dirname, '../src/views/ManagementSystem/BMS/fcPriceConfig');
const model = {};
vm.runInNewContext(fs.readFileSync(path.join(root, 'model.js'), 'utf8').replace(/export /g, ''), model);
const vue = fs.readFileSync(path.join(root, 'fcPriceConfig.vue'), 'utf8');
function component(api = {}) {
  const sandbox = { ...model, api, deptApi: {}, module: { exports: {} } };
  vm.runInNewContext(vue.match(/<script>([\s\S]*?)<\/script>/)[1].replace(/^import .*;$/gm, '').replace('export default', 'module.exports ='), sandbox);
  const config = sandbox.module.exports;
  const messages = [];
  const ctx = { ...config.data(), ...config.methods, $message: { error: x => messages.push(x), warning: x => messages.push(x), success: x => messages.push(x) },
    $nextTick: fn => fn(), $refs: { candidates: { clearSelection() {}, toggleRowSelection() {} } }, $set: (obj, key, value) => { obj[key] = value; } };
  ctx.error = ctx.error.bind(ctx);
  return { ctx, messages };
}
test('converts yuan to exact cents and rejects invalid amounts', () => {
  assert.equal(model.yuanToCents('0.29'), 29);
  assert.equal(model.yuanToCents('10.01'), 1001);
  assert.equal(model.yuanToCents('0'), 0);
  assert.equal(model.centsToYuan(1001), '10.01');
  for (const value of ['', '-1', '1.001', '1e2', 'Infinity', '9999999999999999999']) assert.throws(() => model.yuanToCents(value));
});
test('keeps explicit zero and falls back only for missing prices', () => {
  const product = { id: 1, p: 150 }, plan = { id: 2 };
  assert.equal(model.priceFor(product, plan, [{ id: 1, p: 2, a: 0 }]), 0);
  assert.equal(model.priceFor(product, plan, []), 150);
  assert.equal(model.priceFor(product, plan, [{ id: 1, p: 2, a: null }]), 150);
});
test('retains selections across filters, blocks occupied rows, permits removed own employees', () => {
  let selected = model.addSelection([{ id: 1, s: 1 }], [{ id: 2, s: 2 }, { id: 3, s: 0 }], 'plans');
  assert.equal(JSON.stringify(selected.map(x => x.id)), '[1,3]');
  selected = selected.filter(x => x.id !== 1);
  selected = model.addSelection(selected, [{ id: 1, s: 1 }], 'plans');
  assert.equal(JSON.stringify(selected.map(x => x.id)), '[3,1]');
  assert.equal(model.addSelection([], [{ id: 1, c: 1 }], 'products').length, 0);
});
test('editing first loads all current members and filtered results do not discard them', async () => {
  const calls = [];
  const {ctx} = component({ employeeItems: async params => { calls.push(params); return { code: 1, data: { records: params.key ? [{id:3,s:0}] : [{id:1,s:1},{id:2,s:1}] } }; } });
  Object.assign(ctx.editor, { visible: true, kind: 'plans', id: 9 });
  await ctx.searchCandidates(true);
  ctx.editor.keyword = 'new';
  await ctx.searchCandidates(false);
  assert.equal(calls[0].plan_id, 9);
  assert.equal(calls[0].dept_id, 0);
  assert.equal(JSON.stringify(ctx.editor.selected.map(x => x.id)), '[1,2]');
});
test('stale candidate responses cannot overwrite a reopened dialog', async () => {
  let resolve;
  const {ctx} = component({ productItems: () => new Promise(done => { resolve = done; }) });
  ctx.editor.visible = true;
  const old = ctx.editor;
  const request = ctx.searchCandidates(true);
  ctx.editor = { ...old, visible: true, candidates: [{id:8}], request: 0 };
  resolve({ code: 1, data: { records: [{id:1}] } });
  await request;
  assert.equal(ctx.editor.candidates[0].id, 8);
});
test('failed initial member fetch cannot enable a destructive empty save', async () => {
  const {ctx} = component({ employeeItems: async () => ({code:0,msg:'读取失败'}) });
  Object.assign(ctx.editor, { visible: true, kind: 'plans', id: 1 });
  await ctx.searchCandidates(true);
  assert.equal(ctx.editor.ready, false);
  assert.equal(ctx.editor.initializing, false);
});
test('save failure keeps the editor and full selection for retry', async () => {
  let payload;
  const {ctx, messages} = component({ savePlan: async params => { payload = params; return {code:0,msg:'保存失败'}; } });
  Object.assign(ctx.editor, {visible:true,kind:'plans',id:4,name:'方案',ready:true,selected:[{id:1},{id:2}],candidates:[{id:2}]});
  await ctx.submitEditor();
  assert.equal(JSON.stringify(payload.emp_ids), '[1,2]');
  assert.equal(ctx.editor.visible, true);
  assert.equal(ctx.editor.saving, false);
  assert.deepEqual(messages, ['保存失败']);
});
test('price save sends integer cents and does not report rejected writes as success', async () => {
  let payload;
  const {ctx,messages} = component({ savePrice: async params => { payload = params; return {code:0,msg:'价格保存失败'}; } });
  await ctx.savePrice({id:1,drafts:{2:'0.29'}},{id:2});
  assert.equal(payload.pay_amt,29);
  assert.deepEqual(messages,['价格保存失败']);
});

test('candidate checkboxes mirror configured and selected rows without enabling add for locked rows', () => {
  const {ctx} = component();
  const tableSelection = [];
  let events = 0;
  ctx.$refs.candidates.toggleRowSelection = (row, checked) => {
    const index = tableSelection.indexOf(row);
    if (checked && index === -1) tableSelection.push(row);
    if (!checked && index !== -1) tableSelection.splice(index, 1);
    events++;
    ctx.candidateSelectionChanged(tableSelection);
  };
  const configured = {id:1,c:1}, chosen = {id:2,c:2}, available = {id:3,c:2};
  Object.assign(ctx.editor, {visible:true,kind:'products',candidates:[configured,chosen,available],selected:[chosen]});
  ctx.syncCandidateSelection();
  assert.deepEqual(tableSelection.map(row => row.id), [1,2]);
  assert.equal(ctx.editor.checked.length, 0);
  ctx.removeSelected(chosen);
  assert.deepEqual(tableSelection.map(row => row.id), [1]);
  assert.equal(ctx.canSelect(chosen), true);
  ctx.$refs.candidates.toggleRowSelection(available,true);
  assert.equal(ctx.editor.checked.length,1);
  ctx.addChecked();
  assert.deepEqual(tableSelection.map(row => row.id), [1,3]);
  assert.equal(ctx.editor.checked.length,0);
  assert.ok(events < 20, 'selection events do not recursively toggle rows');
});

test('own plan members are checked while other-plan employees remain disabled and unchecked', () => {
  const {ctx} = component();
  const checked = [];
  ctx.$refs.candidates.toggleRowSelection = (row, value) => { if(value) checked.push(row.id); };
  const own={id:1,s:1},other={id:2,s:2};
  Object.assign(ctx.editor,{visible:true,kind:'plans',candidates:[own,other],selected:[own]});
  ctx.syncCandidateSelection();
  assert.deepEqual(checked,[1]);
  assert.equal(ctx.canSelect(own),false);
  assert.equal(ctx.canSelect(other),false);
});
