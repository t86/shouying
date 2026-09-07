const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const componentSource = fs.readFileSync(
  path.join(__dirname, '../src/components/money/notPayOrder.vue'),
  'utf8',
);
const styleSource = fs.readFileSync(
  path.join(__dirname, '../src/style/money/notPayOrder.less'),
  'utf8',
);
const template = componentSource.match(/<template>([\s\S]*?)<\/template>/)[1];

test('shows the authorizer between waiter and order time for unpaid orders', () => {
  assert.match(template, /服务员<\/div>[\s\S]*授权人<\/div>[\s\S]*点单时间<\/div>/);
  assert.match(template, /items\.personInfo[\s\S]*items\.authInfo[\s\S]*items\.ot\.slice\(7\)/);
  assert.match(template, /item\.personInfo[\s\S]*item\.authInfo[\s\S]*item\.ot\.slice\(7\)/);
});

test('keeps header, online and offline operation columns aligned after adding authorizer', () => {
  assert.match(styleSource, /\.th:nth-child\(11\)/);
  assert.match(styleSource, /\.td-td:nth-child\(10\)/);
  assert.match(styleSource, /\.td:nth-child\(11\)/);
});
