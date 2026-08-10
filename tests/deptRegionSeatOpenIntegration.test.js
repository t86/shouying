const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

function readSource(relativePath) {
  return fs.readFileSync(path.join(__dirname, '..', relativePath), 'utf8');
}

test('book API exposes dept-region seat report read and export endpoints', () => {
  const source = readSource('src/api/Book/index.js');

  assert.match(
    source,
    /reqGetDeptRegionSeatOpenList:\s*params\s*=>\s*axios\.post\(`\$\{base\.htgl\}\/sel\/rpt\/get_dept_region_seat_open_list`,\s*params\)/
  );
  assert.match(
    source,
    /reqExportDeptRegionSeatOpenList:\s*params\s*=>\s*axios\.binaryFilePost\(`\$\{base\.htgl\}\/sel\/rpt\/exp_dept_region_seat_open_list`,\s*params\)/
  );
});
