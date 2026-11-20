const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');
const page = read('src/views/Order/newOrderCard.vue');
const sourceReport = read('src/components/money/newDrawerMinDetail.vue');
const dartReport = read('flutter_workspace/packages/card_table/lib/src/minimum_consumption_report.dart');
const api = read('src/api/money/index.js');

function dartArray(source, name) {
  const body = source.match(new RegExp(`static const List<String> ${name} = \\[([\\s\\S]*?)\\]`));
  assert(body, `missing Dart ${name}`);
  return [...body[1].matchAll(/'([^']+)'/g)].map(match => match[1]);
}

test('minimum report targets the actually routed new order component', () => {
  assert.match(read('src/router/order/index.js'), /@\/views\/Order\/newOrderCard\.vue/);
  assert.match(page, /import drawerMinDetail from ["']@\/components\/money\/newDrawerMinDetail\.vue/);
  assert.match(sourceReport, /v-if="!isOrder\(\)"/);
  assert.match(sourceReport, /sessionStorage\.getItem\("client"\) == "order"/);
});

test('Flutter minimum report retains every original column and wire field in source order', () => {
  const labels = [...sourceReport.matchAll(/<div class="th">([^<]+)<\/div>/g)].map(match => match[1]);
  const fields = [...sourceReport.matchAll(/<div class="td">{{\s*item\.(\w+)\s*}}<\/div>/g)].map(match => match[1]);
  assert.equal(labels.length, 12);
  assert.equal(fields.length, 11);
  assert.deepEqual(dartArray(dartReport, 'columnLabels'), labels);
  assert.deepEqual(dartArray(dartReport, 'wireFields'), fields);
  // Guard that changing a key is observable by this contract, not a tautology.
  assert.notDeepEqual(dartArray(dartReport.replace("'ga'", "'wrong_key'"), 'wireFields'), fields);
});

test('Flutter report uses the same no-argument POST query, not export or synthetic data', () => {
  const query = api.match(/reqGetMinDetail:[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/);
  assert(query);
  assert.equal(query[1], '/wo/get_seat_zy_csm_list');
  assert.match(sourceReport, /await api_money\.reqGetMinDetail\(\)/);
  assert.match(dartReport, /postWithoutBody\(\s*'\/wo\/get_seat_zy_csm_list'/);
  assert.match(dartReport, /data\['records'\]/);
});

const cocktailPage = read('src/components/money/newDrawerTYDetail.vue');
const orderApi = read('src/api/order/index.js');
const dartCocktailPath =
  'flutter_workspace/packages/card_table/lib/src/cocktail_detail_report.dart';

test('cocktail detail targets the actually routed new order component', () => {
  assert.match(page, /import drawerTYDetail from ["']@\/components\/money\/newDrawerTYDetail\.vue/);
  assert.match(cocktailPage, /v-if="!isOrder\(\)"/);
  assert.match(cocktailPage, /api_order\.reqGetYHListByord\(params\)/);
  assert.match(cocktailPage, /sessionStorage\.getItem\("client"\) == "order"/);
});

test('Flutter cocktail detail retains every original column and wire field in source order', () => {
  const dartCocktail = read(dartCocktailPath);
  const labels = [...cocktailPage.matchAll(/<div class="th">([^<{][^<]*)<\/div>/g)].map(
    match => match[1],
  );
  const fields = [
    ...cocktailPage.matchAll(/<div class="td(?: one-txt-cut)?">{{\s*item\.(\w+)\s*}}/g),
  ].map(match => match[1]);
  assert.deepEqual(labels, [
    '序号',
    '区域',
    '卡台名称',
    '下单/补交时间',
    '结账时间',
    '点单人',
    '点单人部门',
    '点单人岗位',
    '授权人',
    '授权人部门',
    '授权人岗位',
    '商品一级分类',
    '商品二级分类',
    '商品名称',
    '点单金额',
    '订台人',
    '订位部门',
    '订位人岗位',
    '关联功能台',
    '补交营业日',
    '支付信息描述',
  ]);
  assert.deepEqual(fields, [
    'rn',
    's',
    'o',
    'pt',
    'w',
    'wd',
    'ws',
    'ae',
    'ad',
    'as',
    'on',
    'tn',
    'n',
    'a',
    'se',
    'sd',
    'ss',
    'bs',
    'bb',
    'p',
  ]);
  assert.deepEqual(dartArray(dartCocktail, 'columnLabels'), labels);
  assert.deepEqual(dartArray(dartCocktail, 'wireFields'), fields);
  assert.match(dartCocktail, /scrollIndicator = '>>'/);
  assert.notDeepEqual(
    dartArray(dartCocktail.replace("'pt'", "'wrong_key'"), 'wireFields'),
    fields,
  );
});

const soldOutPage = read('src/components/order/newProductListGQ.vue');
const soldOutDart =
  'flutter_workspace/packages/card_table/lib/src/sold_out_products.dart';

test('sold-out products target the actually routed new order overlay', () => {
  assert.match(page, /import outSomething from ["']\.\/orderMeal\/newOrderMealList\.vue/);
  assert.match(page, /hasOutSomething/);
  assert.match(read('src/views/Order/orderMeal/newOrderMealList.vue'), /newProductListGQ\.vue/);
  assert.match(soldOutPage, /api_order\.reqGetGQOrderList\(\)/);
  assert.match(soldOutPage, /api_order\.reqDelGQOrder\(params\)/);
  assert.match(
    read('src/components/order/newDrawerMeal/singleProduct.vue'),
    /api_order\.reqSetGQOrder\(params\)/,
  );
});

test('Flutter sold-out products use the three source POSTs', () => {
  const dartSoldOut = read(soldOutDart);
  const getQuery = orderApi.match(
    /reqGetGQOrderList:[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/,
  );
  const setQuery = orderApi.match(
    /reqSetGQOrder:[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/,
  );
  const delQuery = orderApi.match(
    /reqDelGQOrder:[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/,
  );
  assert.equal(getQuery[1], '/sel/get_prd_sold_outs');
  assert.equal(setQuery[1], '/sel/set_prd_sold_out');
  assert.equal(delQuery[1], '/sel/del_prd_sold_out');
  assert.match(dartSoldOut, /postWithoutBody\(\s*'\/sel\/get_prd_sold_outs'/);
  assert.match(dartSoldOut, /post\(\s*'\/sel\/set_prd_sold_out'/);
  assert.match(dartSoldOut, /post\(\s*'\/sel\/del_prd_sold_out'/);
  assert.match(dartSoldOut, /'prd_id': id/);
  assert.match(dartSoldOut, /'cnt': count/);
  assert.doesNotMatch(dartSoldOut, /add_prd_sold_out/);
});

const vipPage = read('src/components/order/vipRecharge/drawerVipRecharge.vue');
const vipApi = read('src/api/vip/index.js');
const vipDart = read('flutter_workspace/packages/card_table/lib/src/vip_recharge.dart');

test('vip recharge targets the routed new order footer', () => {
  assert.match(page, /import drawerVipRecharge from ["']@\/components\/order\/vipRecharge\/drawerVipRecharge\.vue/);
  assert.match(page, /hasVipRechargeAuth/);
  assert.match(page, /sys_modules\.includes\(91\)/);
  assert.match(vipPage, /reqGetCustCardListForDept/);
  assert.match(vipPage, /reqGetVipCardDetailForMakeMoney/);
  assert.match(vipPage, /reqGetDepositRulesForDept/);
});

test('Flutter vip recharge uses the order search and deposit rule POSTs', () => {
  const search = vipApi.match(
    /reqGetCustCardListForDept:[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/,
  );
  const detail = vipApi.match(
    /reqGetVipCardDetailForMakeMoney:[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/,
  );
  const rules = vipApi.match(
    /reqGetDepositRulesForDept:[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/,
  );
  const order = vipApi.match(
    /reqNewCustDeptOrder:[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/,
  );
  const pay = vipApi.match(
    /reqNewCustDeptOrderPay:[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/,
  );
  const status = vipApi.match(
    /reqGetCustDeptOrderStatus:[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/,
  );
  const lastSales = vipApi.match(
    /reqGetCustCardLastSales:[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/,
  );
  assert.equal(search[1], '/sel/get_cust_card_list_for_dept');
  assert.equal(detail[1], '/mb/card/get_mb_card_f_deposit');
  assert.equal(rules[1], '/sel/get_deposit_rules_for_dept');
  assert.equal(order[1], '/wo/new_cust_dept_order');
  assert.equal(pay[1], '/wo/new_cust_dept_order_pay');
  assert.equal(status[1], '/wo/get_cust_dept_order_status');
  assert.equal(lastSales[1], '/wo/get_cust_card_last_sales');
  assert.match(vipDart, /post\(\s*'\/sel\/get_cust_card_list_for_dept'/);
  assert.match(vipDart, /post\(\s*'\/mb\/card\/get_mb_card_f_deposit'/);
  assert.match(vipDart, /post\(\s*'\/sel\/get_deposit_rules_for_dept'/);
  assert.match(vipDart, /post\(\s*'\/wo\/new_cust_dept_order'/);
  assert.match(vipDart, /post\(\s*'\/wo\/new_cust_dept_order_pay'/);
  assert.match(vipDart, /post\(\s*'\/wo\/get_cust_dept_order_status'/);
  assert.match(vipDart, /post\(\s*'\/wo\/get_cust_card_last_sales'/);
  assert.match(vipDart, /'card_id': _jsonId\(cardId\)/);
  assert.match(vipDart, /'order_id': orderId/);
});

test('Flutter cocktail detail uses the order keyword POST, not cashier export', () => {
  const dartCocktail = read(dartCocktailPath);
  const query = orderApi.match(
    /reqGetYHListByord:[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/,
  );
  assert(query);
  assert.equal(query[1], '/sel/rpt/get_hl_list_byord');
  assert.match(cocktailPage, /key: this\.keyword/);
  assert.match(dartCocktail, /post\(\s*'\/sel\/rpt\/get_hl_list_byord'/);
  assert.match(dartCocktail, /'key': keyword/);
  assert.doesNotMatch(dartCocktail, /\/sel\/rpt\/get_hl_list'/);
  assert.doesNotMatch(dartCocktail, /exp_hl_list|导出Excel|exportExcel/);
  assert.match(dartCocktail, /rn': '合计'/);
});

test('order home password dialogs target the routed card-page mixin', () => {
  const mixin = read('src/mixin/cardPage.js');
  const authApi = read('src/api/UtilAuth/auth/index.js');
  const orderApiSource = read('src/api/order/index.js');
  const dartPwd = read(
    'flutter_workspace/packages/card_table/lib/src/account_passwords.dart',
  );
  assert.match(page, /legendOptionHandle\('updatePwd'\)/);
  assert.match(page, /legendOptionHandle\('authPwd'\)/);
  assert.match(page, /updatePassword/);
  assert.match(page, /updateAuthPassword/);
  const chg = authApi.match(
    /requestauthchg_pw[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/,
  );
  const enabled = orderApiSource.match(
    /reqGetAuthStatus:[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/,
  );
  const authChg = orderApiSource.match(
    /reqUpdateAuthPwd:[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/,
  );
  assert.equal(chg[1], '/emp/chg_pwd');
  assert.equal(enabled[1], '/emp/get_auth_pwd_enabled');
  assert.equal(authChg[1], '/emp/chg_auth_pwd');
  assert.match(mixin, /old_password: md5\(form\.old_password\)/);
  assert.match(dartPwd, /post\(\s*'\/emp\/chg_pwd'/);
  assert.match(dartPwd, /postWithoutBody\(\s*'\/emp\/get_auth_pwd_enabled'/);
  assert.match(dartPwd, /post\(\s*'\/emp\/chg_auth_pwd'/);
});

test('order meal add-product targets the routed order page APIs', () => {
  const orderApiSource = read('src/api/order/index.js');
  const dartMeal = read(
    'flutter_workspace/packages/card_table/lib/src/order_meal.dart',
  );
  const add = orderApiSource.match(
    /reqAddProductToShopping:[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/,
  );
  const count = orderApiSource.match(
    /reqGetShoppingCount:[\s\S]*?axios\.post\(`\$\{base\.htgl\}([^`]+)`/,
  );
  assert.equal(add[1], '/wsc/add_prd');
  assert.equal(count[1], '/wsc/get_item_cnt');
  assert.match(page, /handleOrderClick/);
  assert.match(dartMeal, /post\(\s*'\/wsc\/add_prd'/);
  assert.match(dartMeal, /post\(\s*'\/wsc\/get_item_cnt'/);
  assert.match(dartMeal, /post\(\s*'\/wsc\/get_items'/);
  assert.match(dartMeal, /post\(\s*'\/wsc\/set_cnt'/);
  assert.match(dartMeal, /post\(\s*'\/wo\/set_csm_waiter'/);
  assert.match(dartMeal, /post\(\s*'\/wo\/get_cust_items_for_csm'/);
  assert.match(dartMeal, /post\(\s*'\/wo\/set_csm_cust'/);
  assert.match(dartMeal, /post\(\s*'\/wo\/get_set_csm_cust_rst'/);
  assert.match(dartMeal, /post\(\s*'\/wo\/list'/);
});

test('booking confirm writes keep Vue lock unlock cancel pin paths', () => {
  const dartBooking = read(
    'flutter_workspace/packages/card_table/lib/src/booking_card_api.dart',
  );
  const bookApi = read('src/api/Book/index.js');
  assert.match(bookApi, /\/bk\/lock/);
  assert.match(bookApi, /\/bk\/unlock/);
  assert.match(bookApi, /\/bk\/cancel_open/);
  assert.match(bookApi, /\/bk\/cancel`/);
  assert.match(bookApi, /\/bk\/top_seat_dsp/);
  assert.match(bookApi, /\/bk\/cancel_top_seat_dsp/);
  assert.match(bookApi, /\/bk\/disable_csm_must_ord/);
  assert.match(dartBooking, /'\/bk\/lock'/);
  assert.match(dartBooking, /'\/bk\/unlock'/);
  assert.match(dartBooking, /'\/bk\/cancel_open'/);
  assert.match(dartBooking, /'\/bk\/cancel'/);
  assert.match(dartBooking, /'\/bk\/top_seat_dsp'/);
  assert.match(dartBooking, /'\/bk\/cancel_top_seat_dsp'/);
  assert.match(dartBooking, /'\/bk\/disable_csm_must_ord'/);
  assert.match(bookApi, /\/bk\/chg_csm_mca/);
  assert.match(bookApi, /\/bk\/chg_sales/);
  assert.match(bookApi, /\/bk\/set_seat_mark/);
  assert.match(bookApi, /\/bk\/chg_open_seat_remark/);
  assert.match(bookApi, /\/bk\/conv_ol_seat_local/);
  assert.match(dartBooking, /'\/bk\/chg_csm_mca'/);
  assert.match(dartBooking, /'\/bk\/chg_sales'/);
  assert.match(dartBooking, /'\/bk\/set_seat_mark'/);
  assert.match(dartBooking, /'\/bk\/chg_open_seat_remark'/);
  assert.match(dartBooking, /'\/sel\/chg_csm_waiter'/);
  assert.match(dartBooking, /'\/sel\/seat_clean'/);
  assert.match(dartBooking, /'\/bk\/conv_ol_seat_local'/);
});

test('order card tiles keep Vue amount person mark remark and turnover fields', () => {
  const dartScreen = read(
    'flutter_workspace/packages/card_table/lib/src/card_table_screen.dart',
  );
  const dartDisplay = read(
    'flutter_workspace/packages/card_table/lib/src/order_card_display.dart',
  );
  const dartStore = read(
    'flutter_workspace/packages/card_table/lib/src/legacy_card_table_store.dart',
  );
  assert.match(page, /点:￥\{\{ item\.orderAmt \}\}/);
  assert.match(page, /惠:￥\{\{ item\.zengSongAmt \}\}/);
  assert.match(page, /item\.diXiaoJindu/);
  assert.match(page, /item\.mark/);
  assert.match(page, /item\.remark/);
  assert.match(page, /翻\{\{ item\.turnoverCnt \}\}/);
  assert.match(page, /getOrderPersonName/);
  assert.match(page, /getDepartmentName/);
  assert.match(dartScreen, /点:￥\$\{OrderCardDisplay\.yuan\(table\.orderAmount\)\}/);
  assert.match(dartScreen, /惠:￥\$\{OrderCardDisplay\.yuan\(table\.giftAmount\)\}/);
  assert.match(dartScreen, /table\.minConsumeProgress/);
  assert.match(dartScreen, /table\.mark/);
  assert.match(dartScreen, /table\.remark/);
  assert.match(dartScreen, /翻\$\{table\.turnoverCount\}/);
  assert.match(dartDisplay, /modules\.contains\(12\)/);
  assert.match(dartStore, /giftAmount:/);
  assert.match(dartStore, /assignedMinConsumeAmount:/);
  assert.match(dartStore, /data\[6\]/);
});
