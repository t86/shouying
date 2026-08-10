const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const componentPath = path.join(
  __dirname,
  '../src/views/ManagementSystem/BMS/terminalRules/terminalRules.vue',
);
const source = fs.readFileSync(componentPath, 'utf8');

test('renders booking-detail switches only while amounts remain visible', () => {
  assert.match(source, /class="booking-detail-switches"\s+v-if="!notShowAmt"/);
  assert.match(source, /预订系统查看消费明细[\s\S]*?v-model="bookingConsumptionEnabled"/);
  assert.match(source, /预订系统查看存取酒明细[\s\S]*?v-model="bookingWineEnabled"/);
  assert.match(source, /active-text="开"[\s\S]*?inactive-text="关"/);
  assert.match(
    source,
    /\.booking-detail-switches\s*\{\s*display:\s*inline-block;\s*margin-left:\s*100px;\s*vertical-align:\s*top;[\s\S]*?> div\s*\{\s*min-width:\s*360px;[\s\S]*?span\s*\{\s*display:\s*inline-block;\s*width:\s*220px;/,
  );
});

test('normalizes booking-detail configuration returned by getTime', () => {
  assert.match(
    source,
    /import bookingDetailAccess from ['"]@\/utils\/bookingDetailAccess['"]/,
  );
  assert.match(
    source,
    /const \{ normalizeBookingDetailConfig, getBookingDetailSaveFields \} = bookingDetailAccess/,
  );
  assert.match(source, /notShowAmt:\s*true/);
  assert.match(source, /const data = res\.data \|\| \{\}/);
  assert.match(source, /const bookingDetailConfig = normalizeBookingDetailConfig\(data\)/);
  assert.match(source, /this\.notShowAmt = bookingDetailConfig\.amountsRestricted/);
  assert.doesNotMatch(source, /this\.notShowAmt = res\.data\.limit_book_csm_amt/);
  assert.match(source, /this\.bookingConsumptionEnabled = bookingDetailConfig\.consumptionEnabled/);
  assert.match(source, /this\.bookingWineEnabled = bookingDetailConfig\.wineEnabled/);
  assert.doesNotMatch(source, /res\.data\./);

  const accessLoadOrder = [
    'const data = res.data || {}',
    'const bookingDetailConfig = normalizeBookingDetailConfig(data)',
    'this.notShowAmt = bookingDetailConfig.amountsRestricted',
    'this.bookingConsumptionEnabled = bookingDetailConfig.consumptionEnabled',
    'this.bookingWineEnabled = bookingDetailConfig.wineEnabled',
    'this.time = data.local_settle_timeout_mins',
  ].map((token) => source.indexOf(token));
  assert.equal(accessLoadOrder.every((index) => index >= 0), true);
  assert.deepEqual(accessLoadOrder, [...accessLoadOrder].sort((a, b) => a - b));
});

test('serializes both booking-detail settings through the save helper', () => {
  assert.match(
    source,
    /getBookingDetailSaveFields\(\{\s*notShowAmt: this\.notShowAmt,\s*consumptionEnabled: this\.bookingConsumptionEnabled,\s*wineEnabled: this\.bookingWineEnabled,?\s*\}\)/,
  );
  assert.match(source, /\.\.\.bookingDetailSaveFields/);
  const { getBookingDetailSaveFields } = require('../src/utils/bookingDetailAccess');
  assert.deepEqual(
    getBookingDetailSaveFields({
      notShowAmt: false,
      consumptionEnabled: true,
      wineEnabled: true,
    }),
    { enable_book_csm_dtl: 1, enable_book_wine_dtl: 1 },
  );
});

test('clears booking-detail switches when amount display is restricted', () => {
  assert.match(
    source,
    /notShowAmt\(newVal\)\s*\{\s*if \(newVal\) \{\s*this\.bookingConsumptionEnabled = false;\s*this\.bookingWineEnabled = false;/,
  );
});
