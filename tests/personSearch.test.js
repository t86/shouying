const assert = require('assert');
const test = require('node:test');

const {
  getActivePersonOptions,
  isActivePerson,
} = require('../src/utils/personSearch');

const people = [
  { id: 1, name: '张三', code: '1001', namePy: 'zs', status: 1 },
  { id: 2, name: '李四', code: '1002', namePy: 'ls', status: 2 },
  { id: 3, name: '王五', code: '2001', namePy: 'ww', status: 3 },
  { id: 4, name: '赵六', code: '3001', namePy: 'zl', status: '1' },
  { id: 5, name: '钱七', code: '3002', namePy: 'qq', status: '无效' },
];

test('detects active personnel from status values', () => {
  assert.strictEqual(isActivePerson({ status: 1 }), true);
  assert.strictEqual(isActivePerson({ status: '1' }), true);
  assert.strictEqual(isActivePerson({ status: 2 }), false);
  assert.strictEqual(isActivePerson({ status: 3 }), false);
  assert.strictEqual(isActivePerson({ status: '无效' }), false);
});

test('filters inactive personnel before fuzzy matching', () => {
  const options = getActivePersonOptions(people, '100');

  assert.deepStrictEqual(options.map(item => item.id), [1]);
});

test('keeps existing contains and prefix match modes', () => {
  assert.deepStrictEqual(
    getActivePersonOptions(people, 'z').map(item => item.id),
    [1, 4]
  );
  assert.deepStrictEqual(
    getActivePersonOptions(people, 's', { matchMode: 'startsWith' }).map(item => item.id),
    []
  );
  assert.deepStrictEqual(
    getActivePersonOptions(people, 'z', { matchMode: 'startsWith' }).map(item => item.id),
    [1, 4]
  );
});

test('excludes selected ids after filtering active personnel', () => {
  const options = getActivePersonOptions(people, '', { excludeIds: [1, '4'] });

  assert.deepStrictEqual(options.map(item => item.id), []);
});
