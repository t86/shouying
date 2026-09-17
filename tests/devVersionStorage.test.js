const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

// 执行启动入口的版本处理代码，确认开发热更新不会清掉设备授权。
const source = fs.readFileSync(path.join(__dirname, '../src/main.js'), 'utf8');
const start = source.indexOf('const version = packageJson.version;');
const end = source.indexOf('Vue.prototype.$websocket', start);
const code = source.slice(start, end);

function runVersionCheck(environment, previousVersion) {
  const values = new Map([['deviceAuth', 'test-device'], ['tk', 'test-session']]);
  if (previousVersion) values.set('projectVersion', previousVersion);
  vm.runInNewContext(code, {
    process: { env: { NODE_ENV: environment } },
    packageJson: { version: 'new-version' },
    localStorage: {
      getItem: key => values.get(key),
      setItem: (key, value) => values.set(key, value),
      clear: () => values.clear(),
    },
  });
  return values;
}

test('development version changes and first initialization retain device and session storage', () => {
  for (const previousVersion of ['old-version', undefined]) {
    const values = runVersionCheck('development', previousVersion);
    assert.equal(values.get('deviceAuth'), 'test-device');
    assert.equal(values.get('tk'), 'test-session');
    assert.equal(values.get('projectVersion'), 'new-version');
  }
});

test('production upgrades retain the existing cache invalidation behavior', () => {
  const values = runVersionCheck('production', 'old-version');
  assert.equal(values.size, 1);
  assert.equal(values.get('projectVersion'), 'new-version');
});

test('unchanged versions retain storage in both environments', () => {
  for (const environment of ['development', 'production']) {
    assert.equal(runVersionCheck(environment, 'new-version').get('deviceAuth'), 'test-device');
  }
});
