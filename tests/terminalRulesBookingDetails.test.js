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
  assert.match(source, /const bookingDetailConfig = normalizeBookingDetailConfig\(res\.data\)/);
  assert.match(source, /this\.bookingConsumptionEnabled = bookingDetailConfig\.consumptionEnabled/);
  assert.match(source, /this\.bookingWineEnabled = bookingDetailConfig\.wineEnabled/);
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
