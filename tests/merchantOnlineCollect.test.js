const assert = require('assert');
const test = require('node:test');

const {
  buildOnlineCollectMerchants,
  getClosedMerchantIds,
  applyOnlineCollectSaveSuccess,
  rollbackOnlineCollectMerchant,
} = require('../src/utils/merchantOnlineCollect');

test('builds online collect merchants from group response and marks closed ids disabled', () => {
  const response = {
    close_cnl_cfg_ids: ['12', 15],
    cnl_cfg_def: [
      { id: 11, n: 'G商户', g: 1 },
      { id: '12', n: 'S商户A', g: 2 },
      { id: 15, n: 'S商户B', g: 2 },
    ],
  };

  const merchants = buildOnlineCollectMerchants(response);

  assert.deepStrictEqual(
    merchants.map(item => ({
      id: item.id,
      onlineCollectEnabled: item.onlineCollectEnabled,
      savingOpenClose: item.savingOpenClose,
    })),
    [
      { id: 11, onlineCollectEnabled: true, savingOpenClose: false },
      { id: '12', onlineCollectEnabled: false, savingOpenClose: false },
      { id: 15, onlineCollectEnabled: false, savingOpenClose: false },
    ]
  );
});

test('reads closed merchant ids from supported response field names', () => {
  assert.deepStrictEqual(getClosedMerchantIds({ closed_cnl_cfg_ids: ['1', 2] }), [1, 2]);
  assert.deepStrictEqual(getClosedMerchantIds({ close_cnl_cfg_ids: ['3', 4] }), [3, 4]);
  assert.deepStrictEqual(getClosedMerchantIds({}), []);
});

test('updates closed merchant ids after successful save', () => {
  assert.deepStrictEqual(applyOnlineCollectSaveSuccess([12], 12, true), []);
  assert.deepStrictEqual(applyOnlineCollectSaveSuccess([], 12, false), [12]);
  assert.deepStrictEqual(applyOnlineCollectSaveSuccess([12], 12, false), [12]);
});

test('rolls merchant state back after failed save', () => {
  const merchant = {
    id: 12,
    onlineCollectEnabled: false,
    savingOpenClose: true,
  };

  rollbackOnlineCollectMerchant(merchant, true);

  assert.strictEqual(merchant.onlineCollectEnabled, true);
  assert.strictEqual(merchant.savingOpenClose, false);
});
