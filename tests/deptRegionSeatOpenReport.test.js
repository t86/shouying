const test = require('node:test');
const assert = require('node:assert/strict');

const {
  formatDepartmentName,
  isTotalRow,
  toSafeCount,
} = require('../src/utils/deptRegionSeatOpenReport');

test('formatDepartmentName preserves an unindented department name', () => {
  assert.deepEqual(formatDepartmentName('订台一部'), {
    name: '订台一部',
    indent: 0
  });
});

test('formatDepartmentName counts ordinary leading spaces as indentation', () => {
  assert.deepEqual(formatDepartmentName('  订台一部'), {
    name: '订台一部',
    indent: 2
  });
});

test('formatDepartmentName counts a full-width leading space as two indentation spaces', () => {
  assert.deepEqual(formatDepartmentName('\u3000订台一部'), {
    name: '订台一部',
    indent: 2
  });
});

test('toSafeCount normalizes valid finite counts', () => {
  assert.equal(toSafeCount(6), 6);
  assert.equal(toSafeCount('4'), 4);
});

test('toSafeCount converts absent, invalid, and infinite counts to zero', () => {
  assert.equal(toSafeCount(undefined), 0);
  assert.equal(toSafeCount('invalid'), 0);
  assert.equal(toSafeCount(Infinity), 0);
});

test('isTotalRow identifies numeric and string zero identifiers', () => {
  assert.equal(isTotalRow({ id: 0 }), true);
  assert.equal(isTotalRow({ id: '0' }), true);
});

test('isTotalRow rejects non-total and missing rows', () => {
  assert.equal(isTotalRow({ id: 1 }), false);
  assert.equal(isTotalRow(null), false);
});
