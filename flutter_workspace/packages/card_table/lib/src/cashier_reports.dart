import 'package:foundation/foundation.dart';
import 'package:card_table/src/cashier_quota.dart';
import 'package:protocol/protocol.dart';

import 'package:card_table/src/minimum_consumption_report.dart';

import 'package:card_table/src/cocktail_detail_report.dart';

final class CashierReportRow {
  const CashierReportRow({
    required this.id,
    required this.cells,
    this.details = const [],
  });
  final String id;
  final Map<String, String> cells;
  final List<CashierReportRow> details;
  String operator [](String key) => cells[key] ?? '';
}

final class CashierReportQuery {
  const CashierReportQuery({
    required this.title,
    this.keyword = '',
    this.page = 1,
    this.pageSize = 20,
    this.regionId = 0,
    this.groupType = 1,
    this.deptId = 0,
    this.salesEmpId = 0,
    this.discountType = 0,
    this.startDay = '',
    this.endDay = '',
    this.quotaAuthorization,
    this.quotaLimitId,
    this.canDispatch,
    this.productType,
    this.businessType,
    this.paymentType,
    this.customerType,
    this.customerId,
    this.initialize = false,
    this.wkdayId,
    this.setAll = true,
    this.setCategoryIds = const [],
    this.setProductIds = const [],
    this.setStatus = 0,
  });
  final String title, keyword;
  final int? productType, businessType, paymentType, customerType;
  final String? customerId;
  final bool initialize, setAll;
  final int? wkdayId;
  final List<int> setCategoryIds, setProductIds;
  final int setStatus;
  final CashierQuotaAuthorization? quotaAuthorization;
  final int? quotaLimitId;
  final bool Function()? canDispatch;
  final String startDay, endDay;
  final int page,
      pageSize,
      regionId,
      groupType,
      deptId,
      salesEmpId,
      discountType;
}

final class CashierReportPage {
  const CashierReportPage({
    this.rows = const [],
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.quota,
    this.productTypes = const {},
    this.businessTypes = const {},
    this.paymentRows = const [],
    this.channelColumns = const {},
    this.grandTotal,
    this.historyDays = const {},
    this.setCategories = const [],
  });
  final List<CashierReportRow> rows;
  final Map<int, String> productTypes, businessTypes;
  final List<CashierReportRow> paymentRows;
  final Map<String, String> channelColumns;
  final String? grandTotal;
  final Map<int, String> historyDays;
  final List<CashierSetReportCategory> setCategories;
  final CashierQuotaResult? quota;
  final int total, page, pageSize;
}

final class CashierSetReportCategory {
  const CashierSetReportCategory({
    required this.id,
    required this.name,
    this.products = const {},
  });
  final int id;
  final String name;
  final Map<int, String> products;
}

final class CashierReportOptions {
  const CashierReportOptions({
    this.regions = const {},
    this.departments = const {},
    this.salesEmployees = const {},
    this.salesSearchTerms = const {},
  });
  final Map<int, String> regions, departments, salesEmployees, salesSearchTerms;
}

final class CashierPaymentCustomer {
  const CashierPaymentCustomer({
    required this.name,
    required this.phone,
    required this.balance,
    required this.points,
  });
  final String name, phone, balance, points;
}

final class CashierReportMeta {
  const CashierReportMeta({
    required this.title,
    this.columns = const [],
    this.fields = const [],
    this.apiPath = '',
    this.requiresDateRange = false,
    this.supportsKeyword = false,
    this.scopeNote = '',
    this.usesQuery = false,
    this.exportPath = '',
  });
  final String title;
  final List<String> columns;
  final List<String> fields;
  final String apiPath;
  final bool requiresDateRange;
  final bool supportsKeyword;
  final String scopeNote;
  final bool usesQuery;
  final String exportPath;
  bool get supported => apiPath.isNotEmpty;
}

/// Menu inventory is not an assertion that every report has been ported.
/// Contracts below come from moneyCard.vue's actual imported drawers.
abstract final class CashierReportCatalog {
  static const historyDetailColumns = [
    '点单时间',
    '结账时间',
    '点单部门',
    '点单人',
    '点单人岗位',
    '关联台',
    '自助',
    '商品一级分类',
    '商品二级分类',
    '商品名称',
    '商品类型',
    '业务类型',
    '点单数量',
    '点单金额',
    '实收金额',
    '支付信息',
  ];
  static const historyDetailFields = [
    'o',
    'pm',
    'd',
    'w',
    'ws',
    'ri',
    'co',
    'on',
    'tn',
    'p',
    'pt',
    'bt',
    'c',
    'oa',
    'pa',
    'pi',
  ];
  static const _depositColumns = [
    '序号',
    '卡台名称',
    '客人姓名',
    '联系方式',
    '类型名称',
    '预订日期',
    '操作时间',
    '操作金额',
    '操作前余额',
    '操作后余额',
  ];
  static const _depositFields = [
    '',
    's',
    'n',
    'p',
    't',
    'b',
    'o',
    'a',
    'bb',
    'ab',
  ];
  static const depositDetail = CashierReportMeta(
    title: '预订金流水详情',
    usesQuery: true,
    apiPath: '/sel/rpt/get_one_cust_prepay_log',
    exportPath: '/sel/rpt/exp_one_cust_prepay_log',
    columns: _depositColumns,
    fields: _depositFields,
  );
  static final Map<String, CashierReportMeta> reports = Map.unmodifiable({
    for (final title in const <String>[
      '班结表',
      '售出日报表',
      '商品出库表',
      '查询优惠额度',
      '线上支付汇总',
      '支付记录',
      '区域实时营收',
      '业绩日报表',
      '转台记录',
      '线上预订记录',
      '优惠明细表',
      '当日卡券核销记录表',
      '商品卡台销售表',
      '鸡尾酒明细表',
      '鸡尾酒汇总表',
      '挂账账户',
      '翻台记录',
      '点单记录',
      '历史点单记录',
      '非鸡尾酒类补交报表',
      '修改订位人记录',
      '估清商品',
      '盘盈盘亏',
      '商户号管理',
      '低消进度统计表',
      '现抽明细表',
      '现抽汇总表',
      '非主营分类渠道',
      '分类渠道汇总表',
      '部门销售明细表',
      '部门销售汇总表',
      '套餐统计表',
      '挂账还款记录表',
      '预订金流水表',
      '预订金余额表',
      '结束营业日',
      '自动结束营业日',
    ])
      title: CashierReportMeta(title: title),
    '支付记录': const CashierReportMeta(
      title: '支付记录',
      apiPath: '/sel/get_pay_list',
      usesQuery: true,
      supportsKeyword: true,
      columns: ['序号', '卡台', '付款时间', '结账人', '付款金额', '支付方式', '订单绑定会员', '积分赠送中'],
      fields: ['', 'n', 'p', 'pe', 'pa', 'pi', 'c', 'pt'],
    ),
    '线上支付汇总': const CashierReportMeta(
      title: '线上支付汇总',
      apiPath: '/sel/get_ol_pay_bill',
      usesQuery: true,
      columns: ['门店', '营业日期', '支付渠道', '成功笔数', '成功金额', '退单笔数', '退单金额'],
      fields: ['org_name', 'biz_day', 'n', 'pc', 'pa', 'bc', 'ba'],
    ),
    '区域实时营收': const CashierReportMeta(
      title: '区域实时营收',
      apiPath: '/sel/rpt/get_region_real_amts',
      usesQuery: true,
      exportPath: '/sel/rpt/exp_region_real_amts',
      columns: [
        '区域',
        '开台数量',
        '主营已付',
        '主营未付',
        '主营合计',
        '非主营已付',
        '非主营未付',
        '非主营合计',
      ],
      fields: ['r', 'c', 'zp', 'zup', 't', 'fzp', 'fzup', 'ft'],
    ),
    '业绩日报表': const CashierReportMeta(
      title: '业绩日报表',
      apiPath: '/sel/rpt/get_yj_rpt',
      usesQuery: true,
      exportPath: '/sel/rpt/exp_yj_rpt',
      columns: [
        '序号',
        '订位部门/分组',
        '区域',
        '卡台',
        '订位人',
        '开台时间',
        '订台数',
        '折前(含未结金额)',
        '折后(含未结金额)',
        '可计业绩',
        '未结金额',
        '优惠金额',
        '转台记录',
        '咨客备注',
      ],
      fields: [
        '',
        'n',
        'r',
        's',
        'e',
        'o',
        'oc',
        'z',
        'v',
        'y',
        'u',
        'h',
        'c',
        'br',
      ],
    ),
    '优惠明细表': const CashierReportMeta(
      title: '优惠明细表',
      apiPath: '/sel/rpt/get_yh_list',
      usesQuery: true,
      supportsKeyword: true,
      exportPath: '/sel/rpt/exp_yh_list',
      columns: [
        '序号',
        '优惠部门',
        '优惠人',
        '优惠总额',
        '区域',
        '卡台名称',
        '优惠时间',
        '优惠类型',
        '优惠理由',
        '商品一级分类',
        '商品二级分类',
        '商品名称',
        '商品单价',
        '优惠数量',
        '优惠金额小计',
        '订台人',
        '订台部门',
        '优惠2关联功能台',
        '优惠2关联功能台区域',
        '优惠2订位人',
        '优惠2订位人部门',
      ],
      fields: [
        '',
        'ad',
        'ae',
        'group_amount',
        'rn',
        's',
        'o',
        't',
        'r',
        'on',
        'tn',
        'n',
        'p',
        'c',
        'a',
        'se',
        'sd',
        'es',
        'er',
        'ee',
        'ed',
      ],
    ),
    '班结表': const CashierReportMeta(
      title: '班结表',
      columns: ['项目', '数值'],
      apiPath: '/wkd/get_bj',
      scopeNote: '当前营业日 · 全部区域、全部收银员（暂不支持自定义筛选）',
    ),
    '售出日报表': const CashierReportMeta(
      title: '售出日报表',
      columns: ['商品名称', '售出数量'],
      fields: ['n', 'c'],
      apiPath: '/sel/rpt/get_sold_out_rpt',
      scopeNote: '当前营业日 · 全部分类、出品库、订单和售出方式（暂不支持自定义筛选）',
    ),
    '鸡尾酒明细表': const CashierReportMeta(
      title: '鸡尾酒明细表',
      apiPath: '/sel/rpt/get_hl_list',
      supportsKeyword: true,
      columns: [
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
        '备注',
      ],
      fields: [
        '',
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
        'm',
      ],
    ),
    '鸡尾酒汇总表': const CashierReportMeta(
      title: '鸡尾酒汇总表',
      apiPath: '/sel/rpt/get_hl_rpt_sum_list',
      supportsKeyword: true,
      columns: [
        '序号',
        '点单人部门',
        '点单人',
        '点单人岗位',
        '授权人部门',
        '授权人',
        '授权人岗位',
        '商品名称',
        '点单金额',
      ],
      fields: ['', 'wd', 'w', 'ws', 'ad', 'ae', 'as', 'n', 'a'],
    ),
    '转台记录': const CashierReportMeta(
      title: '转台记录',
      usesQuery: true,
      apiPath: '/bk/get_chg_seat_log',
      columns: ['序号', '开台时间', '转台记录'],
      fields: ['', 'o', 'i'],
    ),
    '线上预订记录': const CashierReportMeta(
      title: '线上预订记录',
      usesQuery: true,
      apiPath: '/sel/rpt/get_ol_book_list',
      exportPath: '/sel/rpt/exp_ol_book_list',
      columns: [
        '序号',
        '卡台名称',
        '区域',
        '客人姓名',
        '手机号',
        '预订时间',
        '开台时间',
        '预付金',
        '预付金(已使用)',
        '预付金(剩余)',
        '预付金(退还)',
        '状态',
        '备注',
      ],
      fields: [
        '',
        's',
        'rn',
        'c',
        'p',
        'o',
        'ot',
        'pa',
        'ua',
        'b',
        'ba',
        'st',
        'r',
      ],
    ),
    '商品卡台销售表': const CashierReportMeta(
      title: '商品卡台销售表',
      usesQuery: true,
      supportsKeyword: true,
      apiPath: '/sel/rpt/get_prd_set_sold_cnt',
      exportPath: '/sel/rpt/exp_prd_set_sold_cnt',
      columns: [
        '序号',
        '商品名称',
        '一级分类',
        '二级分类',
        '卡台',
        '开台时间',
        '订位人',
        '单品销售数',
        '套餐内销售数',
        '合计数',
      ],
      fields: ['', 'p', 'o', 't', 'sn', 'ot', 's', 'dc', 'sc', 'tc'],
    ),
    '商品出库表': const CashierReportMeta(
      title: '商品出库表',
      usesQuery: true,
      supportsKeyword: true,
      requiresDateRange: true,
      apiPath: '/sel/rpt/get_rpt_prd_out_list',
      exportPath: '/sel/rpt/exp_rpt_prd_out_list',
      columns: ['序号', '一级分类', '二级分类', '商品名称', '单品出库数量', '套餐内出库数量', '总出库量'],
      fields: ['', 'on', 'tn', 'n', 'dc', 'sc', 'c'],
    ),
    '历史点单记录': const CashierReportMeta(
      title: '历史点单记录',
      usesQuery: true,
      supportsKeyword: true,
      apiPath: '/sel/rpt/get_csm_his',
      exportPath: '/sel/rpt/exp_csm_his',
      columns: [
        '营业日',
        '区域',
        '卡台流水',
        '订位人',
        '订位部门',
        '订位人岗位',
        '总订单金额',
        '总实收金额',
        '支付信息',
      ],
      fields: ['b', 'r', 's', 'se', 'sd', 'ss', 'o', 'p', 'pi'],
    ),
    '套餐统计表': const CashierReportMeta(
      title: '套餐统计表',
      usesQuery: true,
      apiPath: '/sel/rpt/get_set_cnt_rpt',
      columns: ['套餐', '商品名称', '售出数量'],
      fields: ['nn', 'n', 'c'],
    ),
    '现抽明细表': const CashierReportMeta(
      title: '现抽明细表',
      usesQuery: true,
      supportsKeyword: true,
      apiPath: '/sel/rpt/get_xian_chou_list',
      exportPath: '/sel/rpt/exp_xian_chou_list',
      columns: [
        '序号',
        '卡台名称',
        '抽成对象',
        '抽成人',
        '抽成部门',
        '商品名称',
        '点单数量',
        '点单金额',
        '下单时间',
        '抽成金额',
        '支付信息描述',
      ],
      fields: ['', 's', 'tn', 'o', 'd', 'p', 'c', 'a', 't', 'ca', 'pi'],
    ),
    '现抽汇总表': const CashierReportMeta(
      title: '现抽汇总表',
      usesQuery: true,
      supportsKeyword: true,
      apiPath: '/sel/rpt/get_xian_chou_sum_list',
      exportPath: '/sel/rpt/exp_xian_chou_sum_list',
      // Keep drawerXCAllInfo's actual o/tn mapping, not the detail drawer's.
      columns: ['序号', '抽成对象', '抽成人', '抽成部门', '商品名称', '点单总数量', '点单总金额', '抽成总金额'],
      fields: ['', 'o', 'tn', 'd', 'p', 'c', 'a', 'ca'],
    ),
    '非主营分类渠道': const CashierReportMeta(
      title: '非主营分类渠道',
      usesQuery: true,
      apiPath: '/sel/rpt/get_not_zy_cate_cnls',
      exportPath: '/sel/rpt/exp_not_zy_cate_cnls',
      columns: ['序号', '一级分类', '二级分类', '支付渠道', '支付金额'],
      fields: ['', 'on', 'tn', 'cn', 'a'],
    ),
    '分类渠道汇总表': const CashierReportMeta(
      title: '分类渠道汇总表',
      usesQuery: true,
      apiPath: '/sel/rpt/get_jk_list',
      exportPath: '/sel/rpt/exp_jk_list',
      columns: ['序号', '类别', '合计'],
      fields: ['', 'c', 'a'],
    ),
    '部门销售明细表': const CashierReportMeta(
      title: '部门销售明细表',
      usesQuery: true,
      apiPath: '/sel/rpt/get_waiter_sales_prd_amt_list',
      exportPath: '/sel/rpt/exp_waiter_sales_prd_amt_list',
      columns: [
        '序号',
        '订位部门',
        '订位人',
        '商品名称',
        '一级分类',
        '二级分类',
        '销售数量',
        '销售金额(实收金额)',
      ],
      fields: ['', 'd', 'o', 'p', 'on', 'tn', 'c', 'a'],
    ),
    '部门销售汇总表': const CashierReportMeta(
      title: '部门销售汇总表',
      usesQuery: true,
      apiPath: '/sel/rpt/get_waiter_sales_prd_amt_sums',
      exportPath: '/sel/rpt/exp_waiter_sales_prd_amt_sums',
      columns: ['序号', '订位部门', '商品名称', '一级分类', '二级分类', '销售数量', '销售金额(实收金额)'],
      fields: ['', 'd', 'p', 'on', 'tn', 'c', 'a'],
    ),
    '挂账还款记录表': const CashierReportMeta(
      title: '挂账还款记录表',
      usesQuery: true,
      apiPath: '/sel/rpt/get_cnl_account_rtn_list',
      exportPath: '/sel/rpt/exp_cnl_account_rtn_list',
      columns: ['序号', '操作时间', '挂账账号', '操作人', '还款渠道', '还款金额'],
      fields: ['', 'o', 'a', 'e', 'r', 'm'],
    ),
    '预订金流水表': const CashierReportMeta(
      title: '预订金流水表',
      usesQuery: true,
      supportsKeyword: true,
      requiresDateRange: true,
      apiPath: '/sel/rpt/get_cust_prepay_log',
      // reqExpCustPrePayLog uses this same path with a binary response.
      exportPath: '/sel/rpt/get_cust_prepay_log',
      columns: _depositColumns,
      fields: _depositFields,
    ),
    '预订金余额表': const CashierReportMeta(
      title: '预订金余额表',
      usesQuery: true,
      supportsKeyword: true,
      apiPath: '/sel/rpt/get_cust_prepay_bal',
      exportPath: '/sel/rpt/exp_cust_prepay_bal',
      columns: ['序号', '客人姓名', '联系方式', '可用金额', '锁定金额', '消费金额', '退款金额'],
      fields: ['', 'n', 'p', 'ub', 'la', 'ca', 'ba'],
    ),
    '翻台记录': const CashierReportMeta(
      title: '翻台记录',
      usesQuery: true,
      apiPath: '/sel/rpt/get_turnover_csm_list',
      // Source money/index.js intentionally spells the export segment "cms".
      exportPath: '/sel/rpt/exp_turnover_cms_list',
      columns: [
        '序号',
        '卡台名称',
        '区域',
        '预定时间',
        '开台时间',
        '订位人',
        '消费金额',
        '低消进度',
        '翻台时间',
      ],
      fields: ['', 's', 'r', 'b', 'o', 'se', 'pv', 'm', 't'],
    ),
    '点单记录': const CashierReportMeta(
      title: '点单记录',
      usesQuery: true,
      supportsKeyword: true,
      apiPath: '/sel/rpt/get_order_prd_list',
      exportPath: '/sel/rpt/exp_order_prd_list',
      columns: [
        '区域',
        '卡台',
        '关联卡台',
        '点单时间',
        '结账时间',
        '点单部门',
        '点单人岗位',
        '点单人',
        '自助',
        '商品一级分类',
        '商品二级分类',
        '商品名称',
        '商品类型',
        '营业类型',
        '点单数量',
        '点单金额',
        '实收金额',
        '订台人',
        '订位部门',
        '订位人岗位',
        '支付信息',
      ],
      fields: [
        'r',
        's',
        'ri',
        'o',
        'pm',
        'od',
        'ws',
        'oe',
        'ic',
        'po',
        'pt',
        'p',
        'pd',
        'bt',
        'c',
        'a',
        'v',
        'se',
        'sd',
        'ss',
        'pi',
      ],
    ),
    '非鸡尾酒类补交报表': const CashierReportMeta(
      title: '非鸡尾酒类补交报表',
      usesQuery: true,
      supportsKeyword: true,
      apiPath: '/sel/rpt/get_relate_prd_list',
      exportPath: '/sel/rpt/exp_relate_prd_list',
      columns: [
        '区域',
        '卡台',
        '点单时间',
        '点单部门',
        '点单人',
        '商品一级分类',
        '商品二级分类',
        '商品名称',
        '点单金额',
        '订台人',
        '订位部门',
        '关联功能台',
        '补交营业日',
        '支付信息描述',
      ],
      fields: [
        'rn',
        's',
        'o',
        'wd',
        'we',
        'on',
        'tn',
        'n',
        'a',
        'se',
        'sd',
        'bs',
        'bb',
        'p',
      ],
    ),
    '修改订位人记录': const CashierReportMeta(
      title: '修改订位人记录',
      usesQuery: true,
      apiPath: '/sel/rpt/get_csm_sales_chg_list',
      exportPath: '/sel/rpt/exp_csm_sales_chg_list',
      columns: [
        '序号',
        '开台时间',
        '卡台名称',
        '区域',
        '原订位人',
        '修改后订位人',
        '消费金额',
        '操作人',
        '操作时间',
        '修改理由',
      ],
      fields: ['', 'o', 's', 'r', 'fs', 'ts', 'oa', 'oe', 'ot', 'cr'],
    ),
    '低消进度统计表': const CashierReportMeta(
      title: '低消进度统计表',
      apiPath: '/wo/get_seat_zy_csm_list',
      columns: MinimumConsumptionReportRow.columnLabels,
    ),
  });
}

final class ProtocolCashierReportsApi {
  const ProtocolCashierReportsApi({required this.client});
  final ProtocolClient client;

  Map<String, Object?> _queryBody(CashierReportQuery query) {
    if (query.initialize) throw const FormatException();
    if (query.title == '历史点单记录') {
      if (query.wkdayId == null ||
          query.wkdayId! <= 0 ||
          query.wkdayId! > 9007199254740991) {
        throw const FormatException();
      }
      return {'wkday_id': query.wkdayId, 'key': query.keyword};
    }
    if (query.title == '套餐统计表') {
      if (![0, 1, 5].contains(query.setStatus) ||
          [
            ...query.setCategoryIds,
            ...query.setProductIds,
          ].any((id) => id <= 0 || id > 9007199254740991) ||
          (query.setAll &&
              (query.setCategoryIds.isNotEmpty ||
                  query.setProductIds.isNotEmpty))) {
        throw const FormatException();
      }
      return {
        'all': query.setAll ? 1 : 2,
        'two_cate_ids': query.setCategoryIds,
        'prd_ids': query.setProductIds,
        'status': query.setStatus,
      };
    }
    if (query.customerId != null) {
      final id = int.tryParse(query.customerId!);
      if (query.title != '预订金余额表' || id == null || id <= 0) {
        throw const FormatException();
      }
      return {'cust_id': id};
    }
    if ((query.paymentType != null && ![0, 1, 2].contains(query.paymentType)) ||
        (query.customerType != null &&
            ![0, 1, 2].contains(query.customerType))) {
      throw const FormatException();
    }
    if (query.title == '商品出库表' || query.title == '预订金流水表') {
      DateTime day(String text) {
        final value = DateTime.tryParse(text);
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) ||
            value == null ||
            '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}' !=
                text) {
          throw const FormatException();
        }
        return value;
      }

      if (day(query.startDay).isAfter(day(query.endDay))) {
        throw const FormatException();
      }
    }
    if (query.page < 1 ||
        query.pageSize < 1 ||
        query.pageSize > 200 ||
        query.regionId < 0 ||
        query.deptId < 0 ||
        query.salesEmpId < 0 ||
        query.groupType < 1 ||
        query.groupType > 5 ||
        query.discountType < 0 ||
        query.discountType > 2) {
      throw const FormatException();
    }
    return switch (query.title) {
      '支付记录' => {
        'key': query.keyword,
        'page_num': query.page,
        'page_size': query.pageSize,
      },
      '线上支付汇总' || '转台记录' || '线上预订记录' => {},
      '翻台记录' || '修改订位人记录' => {},
      '挂账还款记录表' => {},
      '现抽明细表' || '现抽汇总表' => {'key': query.keyword},
      '非主营分类渠道' || '分类渠道汇总表' || '部门销售明细表' || '部门销售汇总表' => {},
      '预订金流水表' => {
        'page_num': query.page,
        'page_size': query.pageSize,
        'begin_day': query.startDay,
        'end_day': query.endDay,
        'key': query.keyword,
      },
      '预订金余额表' => {
        'page_num': query.page,
        'page_size': query.pageSize,
        'key': query.keyword,
      },
      // Vue resetHandle clears form: undefined fields disappear from JSON,
      // while undefined * 1 becomes is_cust:null. Do not select a made-up type.
      '点单记录' => {
        if (query.keyword.isNotEmpty) 'key': query.keyword,
        if (query.productType != null) 'prd_type': query.productType,
        if (query.businessType != null) 'biz_type': query.businessType,
        if (query.paymentType != null) 'pay_type': query.paymentType,
        'is_cust': query.customerType,
      },
      '非鸡尾酒类补交报表' => {'key': query.keyword},
      '商品卡台销售表' => {'key': query.keyword},
      '商品出库表' => {
        'key': query.keyword,
        'start_day': query.startDay,
        'end_day': query.endDay,
      },
      '区域实时营收' => {'id': query.regionId},
      '业绩日报表' => {
        'type_id': query.groupType,
        'dept_id': query.deptId,
        'sales_emp_id': query.salesEmpId,
      },
      '优惠明细表' => {'yh_type': query.discountType, 'key': query.keyword},
      _ => throw const FormatException(),
    };
  }

  Future<Result<CashierReportPage>> loadReportPage(
    ClientKind kind, {
    required CashierReportQuery query,
  }) async {
    if (query.title == '查询优惠额度') return _loadQuota(kind, query);
    final meta = query.title == '预订金余额表' && query.customerId != null
        ? CashierReportCatalog.depositDetail
        : CashierReportCatalog.reports[query.title];
    if (kind != ClientKind.cashier || meta?.usesQuery != true) {
      return const FailureResult(unavailable);
    }
    try {
      if (query.initialize) return await _initializeReport(kind, query.title);
      final body = _queryBody(query);
      final response =
          const [
            '线上支付汇总',
            '转台记录',
            '线上预订记录',
            '翻台记录',
            '挂账还款记录表',
            '非主营分类渠道',
            '分类渠道汇总表',
            '部门销售明细表',
            '部门销售汇总表',
          ].contains(query.title)
          ? await client.postWithoutBody(meta!.apiPath, client: kind)
          : await client.post(meta!.apiPath, client: kind, body: body);
      final parsed = _data(response);
      if (parsed.failureOrNull case final failure?) {
        return FailureResult(failure);
      }
      final data = parsed.valueOrNull!;
      if (query.title == '历史点单记录') return Success(_historyPage(data, meta));
      if (query.title == '套餐统计表') return Success(_setCountPage(data));
      if (query.title == '分类渠道汇总表') return Success(_categoryChannelPage(data));
      final values = query.title == '线上支付汇总'
          ? data['pays'] ?? []
          : query.title == '非鸡尾酒类补交报表'
          ? data['orders'] ?? []
          : data['records'] ?? [];
      if (values is! List || values.length > 10000) {
        return const FailureResult(shapeFailure);
      }
      final rows = <CashierReportRow>[];
      void add(Map record, {String? id}) {
        final cells = <String, String>{};
        for (var i = 0; i < meta.columns.length; i++) {
          final key = meta.fields[i];
          final cents =
              query.title == '挂账还款记录表' && key == 'm' ||
              query.title == '预订金流水表' && ['a', 'bb', 'ab'].contains(key) ||
              query.title == '预订金余额表' &&
                  ['ub', 'la', 'ca', 'ba', 'a', 'bb', 'ab'].contains(key) ||
              query.title == '区域实时营收' &&
                  ['zp', 'zup', 't', 'fzp', 'fzup', 'ft'].contains(key) ||
              query.title == '业绩日报表' && ['z', 'v', 'y', 'u', 'h'].contains(key);
          cells[meta.columns[i]] = cents
              ? _money(record[key], cents: true)
              : _cell(record[key]);
        }
        if (query.title == '支付记录') {
          cells['付款金额'] = _money(record['pa']);
          if (['', '-', '--'].contains(cells['结账人']?.trim())) {
            cells['结账人'] = cells['支付方式']!.contains('自助') ? '自助收银' : '--';
          }
        }
        rows.add(
          CashierReportRow(
            id: id ?? '${rows.length + 1}',
            cells: Map.unmodifiable(cells),
          ),
        );
      }

      for (final value in values) {
        if (value is! Map) return const FailureResult(shapeFailure);
        if (query.title == '支付记录' && int.tryParse('${value['id']}') == null) {
          return const FailureResult(shapeFailure);
        }
        if (query.title == '预订金余额表' &&
            query.customerId == null &&
            (int.tryParse('${value['id']}') ?? 0) <= 0) {
          return const FailureResult(shapeFailure);
        }
        if (query.title == '优惠明细表') {
          final details = value['dtls'] ?? [];
          if (details is! List) return const FailureResult(shapeFailure);
          for (final (index, detail) in details.indexed) {
            if (detail is! Map || rows.length >= 10000) {
              return const FailureResult(shapeFailure);
            }
            add({
              ...detail,
              'ad': value['ad'],
              'ae': value['ae'],
              'group_amount': index == 0 ? value['a'] : '',
            });
          }
        } else if (query.title == '线上支付汇总') {
          add({
            ...value,
            'org_name': data['org_name'],
            'biz_day': data['biz_day'],
          });
        } else {
          add(value, id: value['id']?.toString());
        }
      }
      if (query.title == '线上支付汇总' && rows.isEmpty) {
        add({'org_name': data['org_name'], 'biz_day': data['biz_day']});
      }
      final depositPaged =
          ['预订金流水表', '预订金余额表'].contains(query.title) &&
          query.customerId == null;
      final depositTotal = depositPaged
          ? int.tryParse('${data['row_cnt']}')
          : null;
      if (depositPaged && (depositTotal == null || depositTotal < 0)) {
        return const FailureResult(shapeFailure);
      }
      final total = depositPaged
          ? depositTotal!
          : query.title == '支付记录'
          ? int.tryParse('${data['row_cnt']}') ?? rows.length
          : rows.length;
      return Success(
        CashierReportPage(
          rows: List.unmodifiable(rows),
          productTypes: query.title == '点单记录'
              ? _reportTypes(data['prd_type'])
              : const {},
          businessTypes: query.title == '点单记录'
              ? _reportTypes(data['biz_types'])
              : const {},
          paymentRows: query.title == '非鸡尾酒类补交报表'
              ? _relatedPayments(data['pays'])
              : const [],
          total: total,
          page: depositPaged
              ? query.page
              : query.title == '支付记录'
              ? int.tryParse('${data['page_num']}') ?? query.page
              : 1,
          pageSize: depositPaged
              ? query.pageSize
              : int.tryParse('${data['page_size']}') ?? query.pageSize,
        ),
      );
    } on Object {
      return const FailureResult(shapeFailure);
    }
  }

  Future<Result<CashierReportPage>> _initializeReport(
    ClientKind kind,
    String title,
  ) async {
    final path = switch (title) {
      '历史点单记录' => '/sel/rpt/get_csm_his_wkday_items',
      '套餐统计表' => '/sel/rpt/get_set_cnt_items',
      _ => '',
    };
    if (path.isEmpty) return const FailureResult(unavailable);
    final result = _data(await client.postWithoutBody(path, client: kind));
    if (result.failureOrNull case final failure?) return FailureResult(failure);
    final data = result.valueOrNull!;
    if (title == '历史点单记录') {
      final days = _reportTypes(data['records']);
      if (days.keys.any((id) => id <= 0)) throw const FormatException();
      return Success(CashierReportPage(historyDays: days));
    }
    final categories = <CashierSetReportCategory>[];
    for (final row in _reportRows(data['two_cates'])) {
      final id = int.tryParse('${row['id']}');
      if (id == null || id <= 0 || categories.any((cat) => cat.id == id)) {
        throw const FormatException();
      }
      final products = _reportTypes(row['ss']);
      if (products.keys.any((id) => id <= 0)) throw const FormatException();
      categories.add(
        CashierSetReportCategory(
          id: id,
          name: _cell(row['n']),
          products: products,
        ),
      );
    }
    return Success(
      CashierReportPage(setCategories: List.unmodifiable(categories)),
    );
  }

  static List<Map> _reportRows(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List || raw.length > 10000) throw const FormatException();
    return [
      for (final row in raw)
        if (row is Map) row else throw const FormatException(),
    ];
  }

  static CashierReportPage _historyPage(Map data, CashierReportMeta meta) {
    final rows = <CashierReportRow>[];
    var detailCount = 0;
    for (final row in _reportRows(data['records'])) {
      final details = <CashierReportRow>[];
      for (final order in _reportRows(row['os'])) {
        if (++detailCount > 10000) throw const FormatException();
        details.add(
          CashierReportRow(
            id: '${details.length}',
            cells: Map.unmodifiable({
              for (
                var i = 0;
                i < CashierReportCatalog.historyDetailFields.length;
                i++
              )
                CashierReportCatalog.historyDetailColumns[i]:
                    [
                      'oa',
                      'pa',
                    ].contains(CashierReportCatalog.historyDetailFields[i])
                    ? _money(
                        order[CashierReportCatalog.historyDetailFields[i]],
                        cents: true,
                      )
                    : _cell(order[CashierReportCatalog.historyDetailFields[i]]),
            }),
          ),
        );
      }
      rows.add(
        CashierReportRow(
          id: '${rows.length}',
          details: List.unmodifiable(details),
          cells: Map.unmodifiable({
            for (var i = 0; i < meta.fields.length; i++)
              meta.columns[i]: ['o', 'p'].contains(meta.fields[i])
                  ? _money(row[meta.fields[i]], cents: true)
                  : _cell(row[meta.fields[i]]),
          }),
        ),
      );
    }
    return CashierReportPage(rows: List.unmodifiable(rows), total: rows.length);
  }

  static CashierReportPage _setCountPage(Map data) {
    final rows = <CashierReportRow>[];
    for (final set in _reportRows(data['prd_sets'])) {
      rows.add(
        CashierReportRow(
          id: '${rows.length}',
          cells: {'套餐': _cell(set['n']), '商品名称': '', '售出数量': _cell(set['c'])},
        ),
      );
      for (final product in _reportRows(set['ss'])) {
        if (rows.length >= 10000) throw const FormatException();
        rows.add(
          CashierReportRow(
            id: '${rows.length}',
            cells: {
              '套餐': '',
              '商品名称': _cell(product['n']),
              '售出数量': _cell(product['c']),
            },
          ),
        );
      }
    }
    return CashierReportPage(rows: List.unmodifiable(rows), total: rows.length);
  }

  Future<Result<void>> printReportQuery(
    ClientKind kind, {
    required CashierReportQuery query,
    bool Function()? canDispatch,
  }) async {
    if (kind != ClientKind.cashier ||
        query.title != '套餐统计表' ||
        query.initialize) {
      return const FailureResult(unavailable);
    }
    try {
      return _ack(
        await client.post(
          '/sel/rpt/prt_set_cnt_rpt',
          client: kind,
          body: _queryBody(query),
          canDispatch: () =>
              (canDispatch?.call() ?? true) &&
              (query.canDispatch?.call() ?? true),
        ),
      );
    } on Object {
      return const FailureResult(shapeFailure);
    }
  }

  static String _money(Object? value, {bool cents = false}) {
    if (value == null || value == '') return cents ? '0.00' : '--';
    final number = num.tryParse('$value');
    if (number == null || !number.isFinite) throw const FormatException();
    return (number / (cents ? 100 : 1)).toStringAsFixed(2);
  }

  static CashierReportPage _categoryChannelPage(Map data) {
    final records = data['records'] ?? const [];
    final channels = data['cnls'] ?? const [];
    if (records is! List ||
        channels is! List ||
        records.length > 10000 ||
        channels.length > 10000) {
      throw const FormatException();
    }
    final labels = <String, String>{};
    for (final channel in channels) {
      if (channel is! Map) throw const FormatException();
      final id = _cell(channel['id']);
      if (id.isEmpty || labels.containsKey('channel:$id')) {
        throw const FormatException();
      }
      labels['channel:$id'] = _cell(channel['n']);
    }
    final groups = <String, Map<String, String>>{};
    final totals = <String, double>{};
    for (final record in records) {
      if (record is! Map) throw const FormatException();
      final category = _cell(record['c']);
      final raw = record['a'];
      final amount = raw == null || raw == '' ? 0.0 : double.tryParse('$raw');
      if (amount == null || !amount.isFinite) throw const FormatException();
      final row = groups.putIfAbsent(category, () => {'类别': category});
      // Match Vue: a duplicate category/channel cell keeps the last amount,
      // while category and grand totals include every returned record.
      row['channel:${_cell(record['l'])}'] =
          raw == null || raw == '' || raw == 0 ? '0.00' : _cell(raw);
      totals[category] = (totals[category] ?? 0) + amount;
    }
    // Vue sums each category first, then those totals in first-seen order.
    final grandTotal = totals.values.fold<double>(
      0,
      (sum, amount) => sum + amount,
    );
    if (!grandTotal.isFinite || totals.values.any((value) => !value.isFinite)) {
      throw const FormatException();
    }
    return CashierReportPage(
      channelColumns: Map.unmodifiable(labels),
      grandTotal: grandTotal.toStringAsFixed(2),
      total: groups.length,
      rows: List.unmodifiable([
        for (final (index, entry) in groups.entries.indexed)
          CashierReportRow(
            id: '${index + 1}',
            cells: Map.unmodifiable({
              ...entry.value,
              '合计': totals[entry.key]!.toStringAsFixed(2),
            }),
          ),
      ]),
    );
  }

  static Map<int, String> _reportTypes(Object? values) {
    if (values == null) return const {};
    if (values is! List || values.length > 10000) throw const FormatException();
    final result = <int, String>{};
    for (final row in values) {
      if (row is! Map) throw const FormatException();
      final id = int.tryParse('${row['id']}');
      if (id == null || result.containsKey(id)) {
        throw const FormatException();
      }
      result[id] = _cell(row['n']);
    }
    return Map.unmodifiable(result);
  }

  static List<CashierReportRow> _relatedPayments(Object? values) {
    if (values == null) return const [];
    if (values is! List || values.length > 10000) throw const FormatException();
    return List.unmodifiable([
      for (final (index, row) in values.indexed)
        if (row is Map)
          CashierReportRow(
            id: 'payment-$index',
            cells: Map.unmodifiable({
              '渠道': _cell(row['n']),
              '笔数': _cell(row['c']),
              '金额': _cell(row['a']),
            }),
          )
        else
          throw const FormatException(),
    ]);
  }

  Future<Result<ProtocolBinaryFile>> exportReport(
    ClientKind kind, {
    required CashierReportQuery query,
  }) async {
    if (query.quotaAuthorization != null || query.quotaLimitId != null) {
      return const FailureResult(unavailable);
    }
    final path = query.title == '预订金余额表' && query.customerId != null
        ? CashierReportCatalog.depositDetail.exportPath
        : CashierReportCatalog.reports[query.title]?.exportPath ?? '';
    if (kind != ClientKind.cashier || path.isEmpty) {
      return const FailureResult(unavailable);
    }
    try {
      return await client.postBinary(
        path,
        client: kind,
        body:
            [
              '线上预订记录',
              '翻台记录',
              '挂账还款记录表',
              '非主营分类渠道',
              '分类渠道汇总表',
              '部门销售明细表',
              '部门销售汇总表',
            ].contains(query.title)
            ? null
            : _queryBody(query),
        fallbackFileName: '${query.title}.xlsx',
      );
    } on Object {
      return const FailureResult(shapeFailure);
    }
  }

  Future<Result<CashierReportPage>> _loadQuota(
    ClientKind kind,
    CashierReportQuery query,
  ) async {
    if (kind != ClientKind.cashier) return const FailureResult(unavailable);
    final auth = query.quotaAuthorization;
    final id = query.quotaLimitId;
    if ((id == null && auth?.valid != true) ||
        (id != null && (id <= 0 || auth != null))) {
      return const FailureResult(unavailable);
    }
    try {
      final response = await client.post(
        id == null
            ? '/sel/get_auth_emp_free_limit'
            : '/station/get_fl_act_prds',
        client: kind,
        canDispatch: query.canDispatch,
        body: id == null
            ? auth!.toWire()
            : {
                'free_limit_ids': [id],
              },
      );
      final parsed = _data(response);
      if (parsed.failureOrNull case final failure?) {
        return FailureResult(failure);
      }
      final data = parsed.valueOrNull!;
      final records = data['records'] ?? [];
      if (records is! List || records.length > 10000) {
        return const FailureResult(shapeFailure);
      }
      final rows = <CashierReportRow>[];
      for (final raw in records) {
        if (raw is! Map) return const FailureResult(shapeFailure);
        final fields = id == null
            ? const [
                'n',
                't',
                'udc',
                'ldc',
                'uda',
                'lda',
                'umc',
                'lmc',
                'uma',
                'lma',
              ]
            : const ['p'];
        final cells = <String, String>{};
        for (final field in fields) {
          final value = raw[field];
          if (value != null && value is! String && value is! num) {
            return const FailureResult(shapeFailure);
          }
          cells[field] = value?.toString() ?? '';
        }
        rows.add(CashierReportRow(id: '${raw['id'] ?? ''}', cells: cells));
      }
      return Success(
        CashierReportPage(
          rows: rows,
          total: rows.length,
          quota: id == null
              ? CashierQuotaResult(
                  name: '${data['name'] ?? ''}',
                  code: '${data['code'] ?? ''}',
                )
              : null,
        ),
      );
    } on Object {
      return const FailureResult(shapeFailure);
    }
  }

  Future<Result<void>> printReport(
    ClientKind kind, {
    required String title,
  }) async {
    if (kind != ClientKind.cashier || title != '线上支付汇总') {
      return const FailureResult(unavailable);
    }
    return _ack(
      await client.postWithoutBody('/sel/prt_ol_pay_bill', client: kind),
    );
  }

  Result<void> _ack(Result<Map<String, Object?>> result) {
    if (result.failureOrNull case final failure?) return FailureResult(failure);
    return result.valueOrNull?['code'] == 1 ||
            result.valueOrNull?['code'] == '1'
        ? const Success(null)
        : const FailureResult(
            AppFailure(
              kind: FailureKind.business,
              code: 'report.rejected',
              safeMessage: '服务端拒绝操作，请重试',
            ),
          );
  }

  Future<Result<Map<int, String>>> loadDepartments(ClientKind kind) async {
    if (kind != ClientKind.cashier) return const FailureResult(unavailable);
    final result = await client.postWithoutBody('/dept/tree', client: kind);
    if (_ack(result).failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    try {
      final options = <int, String>{};
      void visit(Object? value, String prefix) {
        if (value is! List) throw const FormatException();
        for (final row in value) {
          if (row is! Map) throw const FormatException();
          final id = int.parse('${row['id']}');
          options[id] = '$prefix${_cell(row['n'])}';
          if (row['subs'] != null) visit(row['subs'], '${options[id]} / ');
        }
      }

      visit(result.valueOrNull!['data'], '');
      return Success(Map.unmodifiable(options));
    } on Object {
      return const FailureResult(shapeFailure);
    }
  }

  Future<Result<CashierPaymentCustomer?>> findPaymentCustomer(
    ClientKind kind, {
    required String phone,
  }) async {
    if (kind != ClientKind.cashier || !RegExp(r'^\d{11}$').hasMatch(phone)) {
      return const FailureResult(shapeFailure);
    }
    final result = await client.post(
      '/sel/get_cust_info_by_phonenum',
      client: kind,
      body: {'phone_num': phone},
    );
    if (_ack(result).failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final data = result.valueOrNull!['data'];
    if (data == null) return const Success(null);
    if (data is! Map) return const FailureResult(shapeFailure);
    try {
      return Success(
        CashierPaymentCustomer(
          name: _cell(data['name']),
          phone: _cell(data['phone']),
          balance: _cell(data['bal']),
          points: _cell(data['pt']),
        ),
      );
    } on Object {
      return const FailureResult(shapeFailure);
    }
  }

  Future<Result<void>> changePaymentCustomer(
    ClientKind kind, {
    required String paymentId,
    required String phone,
  }) async {
    final id = int.tryParse(paymentId);
    if (kind != ClientKind.cashier ||
        id == null ||
        (phone.isNotEmpty && !RegExp(r'^\d{11}$').hasMatch(phone))) {
      return const FailureResult(shapeFailure);
    }
    return _ack(
      await client.post(
        '/sel/chg_pay_cust',
        client: kind,
        body: {'id': id, 'phone': phone},
      ),
    );
  }

  Future<Result<List<CashierReportRow>>> loadReportData(
    ClientKind client, {
    required String reportTitle,
    String startDate = '',
    String endDate = '',
    String keyword = '',
  }) async {
    final meta = CashierReportCatalog.reports[reportTitle];
    if (meta == null || !meta.supported) {
      return const FailureResult(unavailable);
    }
    if (meta.usesQuery) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'report.query_required',
          safeMessage: '此报表需要完整筛选查询入口',
        ),
      );
    }
    // These source drawers query the current business day, never calendar dates.
    if (client != ClientKind.cashier) return const FailureResult(unavailable);
    try {
      if (reportTitle == '低消进度统计表') {
        final result = await ProtocolMinimumConsumptionReportApi(
          client: this.client,
        ).load(client);
        if (result.failureOrNull case final failure?) {
          return FailureResult(failure);
        }
        return Success([
          for (final (index, row) in result.valueOrNull!.indexed)
            CashierReportRow(
              id: '${index + 1}',
              cells: Map.unmodifiable({
                for (var i = 0; i < row.cells.length; i++)
                  meta.columns[i + 1]: row.cells[i],
              }),
            ),
        ]);
      }
      final body = <String, Object?>{};
      if (reportTitle == '班结表') {
        body.addAll({
          'region_ids': [-1],
          'cashier_ids': [-1],
        });
      } else if (reportTitle == '售出日报表') {
        final options = await this.client.postWithoutBody(
          '/sel/rpt/get_sold_out_rpt_items',
          client: client,
        );
        final data = _data(options);
        if (data.failureOrNull case final failure?) {
          return FailureResult(failure);
        }
        final libs = data.valueOrNull!['prt_mk_libs'];
        if (libs is! List ||
            libs.isEmpty ||
            libs.first is! Map ||
            libs.first['id'] is! int) {
          return const FailureResult(
            AppFailure(
              kind: FailureKind.protocol,
              code: 'report.sold_options_missing',
              safeMessage: '售出日报表缺少打印出品库参数，无法查询',
            ),
          );
        }
        body.addAll({
          'is_all_cate': 1,
          'is_all_mklib': 1,
          'two_cate_ids': <int>[],
          'mklib_ids': <int>[],
          'status': 0,
          'prt_mklib_id': libs.first['id'],
          'sold_type': 0,
        });
      } else {
        body['key'] = keyword;
      }
      final response = await this.client.post(
        meta.apiPath,
        body: body,
        client: client,
      );
      final parsed = _data(response);
      if (parsed.failureOrNull case final failure?) {
        return FailureResult(failure);
      }
      final data = parsed.valueOrNull!;
      if (reportTitle == '班结表') return Success(_shiftRows(data));
      final records = data['records'] ?? const [];
      if (records is! List || records.length > 10000) {
        return const FailureResult(shapeFailure);
      }
      final rows = <CashierReportRow>[];
      for (final record in records) {
        if (record is! Map) return const FailureResult(shapeFailure);
        rows.add(
          CashierReportRow(
            id: '${rows.length + 1}',
            cells: Map.unmodifiable({
              for (var i = 0; i < meta.columns.length; i++)
                meta.columns[i]:
                    (reportTitle == '鸡尾酒明细表' || reportTitle == '鸡尾酒汇总表') &&
                        meta.fields[i] == 'a'
                    ? CocktailReportAmounts.fromWire(record).display
                    : _cell(record[meta.fields[i]]),
            }),
          ),
        );
      }
      if (reportTitle == '售出日报表') {
        num total = 0;
        for (final record in records) {
          final count = record['c'];
          if (count is! num || !count.isFinite) {
            return const FailureResult(shapeFailure);
          }
          total += count;
        }
        rows.add(
          CashierReportRow(
            id: 'total',
            cells: {'商品名称': '合计', '售出数量': _cell(total)},
          ),
        );
      }
      return Success(List.unmodifiable(rows));
    } catch (_) {
      return const FailureResult(shapeFailure);
    }
  }

  Result<Map<String, Object?>> _data(Result<Map<String, Object?>> response) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final env = response.valueOrNull!;
    if (env['code'] != 1 && env['code'] != '1') {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'report.rejected',
          safeMessage: '服务端拒绝查询报表，请重试',
        ),
      );
    }
    final data = env['data'];
    return data is Map<String, Object?>
        ? Success(data)
        : const FailureResult(shapeFailure);
  }

  List<CashierReportRow> _shiftRows(Map<String, Object?> data) {
    const fields = {
      '门店': 'org_name',
      '营业日期': 'biz_day',
      '收银员': 'cashier_names',
      '单数': 'total_items',
      '退单笔数': 'back_items',
      '退单金额': 'back_amt',
      '优惠笔数': 'yh_items',
      '优惠金额': 'yh_amt',
      '优惠2笔数': 'yh2_items',
      '优惠2金额': 'yh2_amt',
      '会员卡线上充值金额': 'mb_ol_dep_amt',
      '会员卡线下充值金额': 'mb_of_dep_amt',
      '挂账还款合计': 'act_rtn_amt',
      '账单合计': 'total_amt',
      '应收合计': 'order_amt',
      '折扣合计': 'free_amt',
      '非主营未付合计': 'not_zy_topay_amt',
      '主营未付合计': 'zy_topay_amt',
      '实收合计': 'value_amt',
      '非主营实收合计': 'not_zy_amt',
      '主营实收合计': 'zy_value_amt',
    };
    final rows = <CashierReportRow>[
      for (final field in fields.entries)
        CashierReportRow(
          id: field.value,
          cells: {'项目': field.key, '数值': _cell(data[field.value])},
        ),
    ];
    for (final section in {'pays': 'p', 'orders': 'c'}.entries) {
      final items = data[section.key] ?? const [];
      if (items is! List || items.length > 10000) throw const FormatException();
      for (final item in items) {
        if (item is! Map) throw const FormatException();
        rows.add(
          CashierReportRow(
            id: '${section.key}-${rows.length}',
            cells: {
              '项目':
                  '${section.key == 'pays' ? '支付渠道' : '收入'} · ${_cell(item[section.value])}',
              '数值': _cell(item['a']),
            },
          ),
        );
      }
    }
    return List.unmodifiable(rows);
  }

  static String _cell(Object? value) => switch (value) {
    null => '',
    String() when value.length <= 2048 => value,
    num() when value.isFinite => value.toString(),
    _ => throw const FormatException(),
  };
  static const unavailable = AppFailure(
    kind: FailureKind.business,
    code: 'report.unavailable',
    safeMessage: '此报表尚未完成迁移，暂不可用',
  );
  static const shapeFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'report.invalid_data',
    safeMessage: '报表返回数据无法识别，请重试',
  );
}
