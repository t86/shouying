const test = require('node:test');
const assert = require('node:assert/strict');

const {
  BOOKING_DETAIL_OPTION_IDS,
  normalizeBookingDetailConfig,
  getBookingDetailSaveFields,
  isBookingDetailStatusVisible,
  getBookingDetailOptionIds,
  buildTurnoverTabs,
  getBookingDetailTurnoverCount,
} = require('../src/utils/bookingDetailAccess');

test('exports the stable booking-detail option IDs', () => {
  assert.deepEqual(BOOKING_DETAIL_OPTION_IDS, { consumption: 26, wine: 27 });
  assert.equal(Object.isFrozen(BOOKING_DETAIL_OPTION_IDS), true);
});

test('normalizes numeric or string unrestricted configuration and enabled child entries', () => {
  assert.deepEqual(
    normalizeBookingDetailConfig({
      limit_book_csm_amt: '2',
      enable_book_csm_dtl: 1,
      enable_book_wine_dtl: '1',
    }),
    { amountsRestricted: false, consumptionEnabled: true, wineEnabled: true },
  );
  assert.deepEqual(
    normalizeBookingDetailConfig({
      limit_book_csm_amt: 2,
      enable_book_csm_dtl: 1,
      enable_book_wine_dtl: 1,
    }),
    { amountsRestricted: false, consumptionEnabled: true, wineEnabled: true },
  );
});

test('fails closed when configuration values are missing or unsupported', () => {
  assert.deepEqual(
    normalizeBookingDetailConfig({}),
    { amountsRestricted: true, consumptionEnabled: false, wineEnabled: false },
  );
  assert.deepEqual(
    normalizeBookingDetailConfig(null),
    { amountsRestricted: true, consumptionEnabled: false, wineEnabled: false },
  );
  assert.deepEqual(
    normalizeBookingDetailConfig({
      limit_book_csm_amt: true,
      enable_book_csm_dtl: 1,
      enable_book_wine_dtl: 1,
    }),
    { amountsRestricted: true, consumptionEnabled: false, wineEnabled: false },
  );
});

test('disables child entries unless amount display is unrestricted', () => {
  assert.deepEqual(
    normalizeBookingDetailConfig({
      limit_book_csm_amt: 1,
      enable_book_csm_dtl: 1,
      enable_book_wine_dtl: 1,
    }),
    { amountsRestricted: true, consumptionEnabled: false, wineEnabled: false },
  );
});

test('fails closed for unsupported child values even when amount display is unrestricted', () => {
  for (const childValue of [undefined, 0, 2, 'other']) {
    assert.deepEqual(
      normalizeBookingDetailConfig({
        limit_book_csm_amt: 2,
        enable_book_csm_dtl: childValue,
        enable_book_wine_dtl: childValue,
      }),
      { amountsRestricted: false, consumptionEnabled: false, wineEnabled: false },
    );
  }
});

test('serializes detail settings and forces both off when amounts are hidden', () => {
  assert.deepEqual(
    getBookingDetailSaveFields(null),
    { enable_book_csm_dtl: 2, enable_book_wine_dtl: 2 },
  );
  assert.deepEqual(
    getBookingDetailSaveFields({
      notShowAmt: false,
      consumptionEnabled: true,
      wineEnabled: false,
    }),
    { enable_book_csm_dtl: 1, enable_book_wine_dtl: 2 },
  );
  assert.deepEqual(
    getBookingDetailSaveFields({
      notShowAmt: false,
      consumptionEnabled: false,
      wineEnabled: true,
    }),
    { enable_book_csm_dtl: 2, enable_book_wine_dtl: 1 },
  );
  assert.deepEqual(
    getBookingDetailSaveFields({
      notShowAmt: true,
      consumptionEnabled: true,
      wineEnabled: true,
    }),
    { enable_book_csm_dtl: 2, enable_book_wine_dtl: 2 },
  );
});

test('shows detail entries only in allowed card states', () => {
  assert.equal(isBookingDetailStatusVisible(1, 0), false);
  assert.equal(isBookingDetailStatusVisible(1, 1), true);
  assert.equal(isBookingDetailStatusVisible(2, 3), false);
  assert.equal(isBookingDetailStatusVisible(3, 0), false);
  assert.equal(isBookingDetailStatusVisible(3, 3), true);
  assert.equal(isBookingDetailStatusVisible(8, 0), false);
  assert.equal(isBookingDetailStatusVisible(8, 3), true);

  for (const status of [4, 5, 6, 7]) {
    assert.equal(isBookingDetailStatusVisible(status, 0), true);
  }
});

test('returns independent configured options only for visible and unrestricted states', () => {
  assert.deepEqual(getBookingDetailOptionIds(null, 4, 0), []);
  assert.deepEqual(
    getBookingDetailOptionIds(
      { amountsRestricted: false, consumptionEnabled: true, wineEnabled: false },
      4,
      0,
    ),
    [26],
  );
  assert.deepEqual(
    getBookingDetailOptionIds(
      { amountsRestricted: false, consumptionEnabled: false, wineEnabled: true },
      1,
      2,
    ),
    [27],
  );
  assert.deepEqual(
    getBookingDetailOptionIds(
      { amountsRestricted: true, consumptionEnabled: true, wineEnabled: true },
      4,
      0,
    ),
    [],
  );
  assert.deepEqual(
    getBookingDetailOptionIds(
      { amountsRestricted: false, consumptionEnabled: true, wineEnabled: true },
      4,
      0,
    ),
    [26, 27],
  );
  assert.deepEqual(
    getBookingDetailOptionIds(
      { amountsRestricted: false, consumptionEnabled: true, wineEnabled: true },
      3,
      2,
    ),
    [26, 27],
  );
});

test('uses the previous turnover for cleared cards whose current turnover is not open', () => {
  assert.equal(getBookingDetailTurnoverCount(7, 3), 2);
  assert.equal(getBookingDetailTurnoverCount(7, 2), 1);
  assert.equal(getBookingDetailTurnoverCount(7, 1), 0);
  assert.equal(getBookingDetailTurnoverCount(4, 3), 3);
  assert.equal(getBookingDetailTurnoverCount(8, 3), 3);
});

test('builds newest-first turnover tabs and an empty-table fallback', () => {
  assert.deepEqual(buildTurnoverTabs('A01', 3), [
    { turnoverCnt: 3, label: 'A01-003' },
    { turnoverCnt: 2, label: 'A01-002' },
    { turnoverCnt: 1, label: 'A01-001' },
  ]);
  assert.deepEqual(buildTurnoverTabs('A01', 0), [
    { turnoverCnt: 0, label: 'A01-001' },
  ]);
});
