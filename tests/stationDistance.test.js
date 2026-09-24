const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('src/views/ManagementSystem/BMS/stationConfig/stationConfig.vue', 'utf8');
const script = source.match(/<script>([\s\S]*?)<\/script>/)[1].replace(/^import [^\n]*\n/gm, '').replace('export default', 'module.exports =');
const sandbox = { module: { exports: {} }, CharactersButton: {}, IconButton: {}, drawerAddOrUpdateStation: {}, drawerNextDrawer: {} };
vm.runInNewContext(script, sandbox);
const component = sandbox.module.exports;
function setup(response = { code: 1 }) {
  const state = component.data();
  const calls = []; const notices = [];
  Object.keys(component.methods).forEach(key => state[key] = component.methods[key].bind(state));
  state.$message = { warning: msg => notices.push(msg), success: msg => notices.push(msg) };
  state.$api = { BMS: { station: { requestStationSetDistance: async payload => { calls.push(payload); return response; } } } };
  state.getTableData = () => { state.refreshed = true; };
  return { state, calls, notices };
}
test('distance labels and selection are initialized from saved station settings', () => {
  const { state, notices } = setup();
  for (const value of [undefined, null, '', '0', 0]) assert.equal(state.formatDistance(value), '不限制');
  assert.equal(state.formatDistance('200'), '200米');
  state.openDistanceDialog(); assert.equal(state.showDistanceDialog, false); assert.equal(notices.length, 1);
  state.tableData = [{ id: 1, checked: true, d: '200' }, { id: 2, checked: false, d: '300' }];
  state.openDistanceDialog(); assert.equal(state.distanceInput, ''); assert.equal(state.distanceStations.length, 1);
  state.tableData[1].checked = true; state.openDistanceDialog(); assert.equal(state.distanceInput, '');
});
test('invalid distances never reach API', async () => {
  const { state, calls } = setup(); state.distanceStations = [{ id: 1 }];
  for (const value of ['', '-1', '1.5', 'NaN', 'Infinity', '1e3', '9007199254740992']) {
    state.distanceInput = value; await state.saveDistance();
  }
  assert.equal(calls.length, 0);
});
test('save snapshots selected stations, submits integer meters and refreshes on success', async () => {
  const { state, calls } = setup();
  state.tableData = [{ id: '123', checked: true, d: '20' }]; state.openDistanceDialog(); state.distanceInput = '0';
  await state.saveDistance(); assert.equal(JSON.stringify(calls), '[{"station_ids":["123"],"distance":0}]');
  assert.equal(state.showDistanceDialog, false); assert.equal(state.refreshed, true); assert.equal(state.distanceSaving, false);
});
test('failed saves retain dialog and input, network errors allow retry', async () => {
  const { state } = setup({ code: 0, msg: '保存失败' }); state.distanceStations = [{ id: 1 }]; state.showDistanceDialog = true; state.distanceInput = '50';
  await state.saveDistance(); assert.equal(state.showDistanceDialog, true); assert.equal(state.distanceInput, '50'); assert.equal(state.refreshed, undefined);
  state.$api.BMS.station.requestStationSetDistance = async () => { throw new Error('offline'); };
  await state.saveDistance(); assert.equal(state.distanceSaving, false); assert.equal(state.showDistanceDialog, true);
});
test('pending save blocks duplicate submissions', async () => {
  const { state } = setup(); let finish; let calls = 0;
  state.distanceStations = [{ id: 1 }]; state.distanceInput = '20';
  state.$api.BMS.station.requestStationSetDistance = () => { calls++; return new Promise(resolve => { finish = resolve; }); };
  const pending = state.saveDistance(); await state.saveDistance(); assert.equal(calls, 1); finish({ code: 1 }); await pending;
});

test('input accepts only zero or positive integers', () => {
  const { state } = setup();
  state.onDistanceInput('0'); assert.equal(state.distanceInput, '0');
  state.onDistanceInput('12.5'); assert.equal(state.distanceInput, '12');
  state.onDistanceInput('-8'); assert.equal(state.distanceInput, '');
  state.onDistanceInput('abc'); assert.equal(state.distanceInput, '');
  assert.match(source, /placeholder=\"0:不限制\"/);
});
