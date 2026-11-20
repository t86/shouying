import 'package:foundation/foundation.dart';

abstract interface class BmsReportConfigurationLoader {
  Object? get configurationContext;
  Future<Result<Map<String, Object?>>> requestReportConfiguration(
    BmsReportConfigurationRequest request,
  );
}

enum BmsReportConfigurationOperation {
  deptTree('get_dept_tree', true, ''),
  departmentTabs('get_hl_tabs', true, ''),
  addDepartmentTabs('batch_add_hl_tabs', false, 'dept_ids'),
  deleteDepartmentTab('del_hl_tab', false, 'dept_id'),
  waiterProducts('get_waiter_sales_prds', true, ''),
  waiterProductItems(
    'get_waiter_sales_prd_items',
    true,
    'name,page_num,page_size,init,one_cate_id,two_cate_id',
  ),
  addWaiterProducts('add_waiter_sales_prds', false, 'prd_ids'),
  deleteWaiterProduct('del_waiter_sales_prd', false, 'prd_id'),
  statistics('get_rpt_jk_cate_list', true, ''),
  createStatistic('new_rpt_jk_cate', false, 'name,type_id,biz_type'),
  renameStatistic('save_rpt_jk_cate_name', false, 'id,name'),
  saveStatisticBusinessType('save_rpt_jk_cate_biztype', false, 'id,biz_type'),
  deleteStatistics('batch_del_rpt_jk_cate', false, 'ids'),
  moveStatistic('move_rpt_jk_cate_dsp', false, 'id,dest_id,down_up'),
  statisticCategoryItems('get_rpt_jk_cate_cate_items', true, ''),
  saveStatisticCategories('save_rpt_jk_cate_cates', false, 'id,cate_ids'),
  statisticProducts(
    'get_rpt_jk_cate_prd_list',
    true,
    'id,init,one_cate_id,two_cate_id,name',
  ),
  statisticProductItems(
    'get_rpt_jk_cate_prd_items',
    true,
    'init,one_cate_id,two_cate_id,name',
  ),
  addStatisticProducts('batch_add_rpt_jk_cate_pitems', false, 'id,prd_ids'),
  deleteStatisticProducts('batch_del_rpt_jk_cate_pitems', false, 'id,prd_ids'),
  channels('get_rpt_jk_cnl_list', true, ''),
  channelItems('get_rpt_jk_cnl_dtl', true, ''),
  saveChannel('new_or_save_rpt_jk_cnl', false, 'id,name,pay_cnl_ids'),
  deleteChannels('batch_del_rpt_jk_cnl', false, 'ids'),
  moveChannel('move_rpt_jk_cnl_dsp', false, 'id,dest_id,down_up'),
  highMarginProducts('get_srv_ord_high_prd_cfg', true, 'key'),
  highMarginProductItems(
    'get_srv_ord_high_prd_items',
    true,
    'name,page_num,page_size,init,one_cate_id,two_cate_id',
  ),
  addHighMarginProducts('add_srv_ord_high_prd_cfg', false, 'ids'),
  deleteHighMarginProducts('del_srv_ord_high_prd_cfg', false, 'ids');

  const BmsReportConfigurationOperation(
    this.endpoint,
    this.reads,
    this._fields,
  );
  final String endpoint;
  final bool reads;
  final String _fields;
  bool get hasBody => _fields.isNotEmpty;
}

/// Closed endpoint and field vocabulary. No arbitrary backend route or extra
/// credential fields can be supplied through the configuration UI.
final class BmsReportConfigurationRequest {
  const BmsReportConfigurationRequest(
    this.operation, {
    this.parameters = const {},
  });
  final BmsReportConfigurationOperation operation;
  final Map<String, Object?> parameters;
  Map<String, Object?> get body {
    final keys = operation.hasBody
        ? operation._fields.split(',').toSet()
        : <String>{};
    if (parameters.length != keys.length ||
        !parameters.keys.every(keys.contains)) {
      throw const FormatException('报表配置参数不完整或包含未知字段');
    }
    final output = <String, Object?>{};
    bool integer(Object? value, {bool zero = false}) =>
        value is int && value >= (zero ? 0 : 1) && value <= 9007199254740991;
    for (final key in keys) {
      final value = parameters[key];
      if (key == 'name' || key == 'key') {
        if (value is! String ||
            value.length > 200 ||
            (!operation.reads && value.trim().isEmpty)) {
          throw const FormatException('请输入有效名称或关键字');
        }
        output[key] = value;
      } else if (key.endsWith('_ids') || key == 'ids') {
        if (value is! List ||
            value.isEmpty ||
            value.any((id) => !integer(id)) ||
            value.toSet().length != value.length) {
          throw const FormatException('请选择有效且不重复的记录');
        }
        output[key] = List<int>.unmodifiable(value.cast<int>());
      } else {
        final zero =
            key == 'one_cate_id' ||
            key == 'two_cate_id' ||
            (key == 'id' &&
                operation == BmsReportConfigurationOperation.saveChannel);
        if (!integer(value, zero: zero) ||
            (['init', 'type_id', 'down_up'].contains(key) &&
                ![1, 2].contains(value)) ||
            (key == 'biz_type' && ![1, 2, 3].contains(value))) {
          throw const FormatException('编号、分页或类型无效');
        }
        output[key] = value;
      }
    }
    if (parameters.containsKey('dest_id') &&
        parameters['id'] == parameters['dest_id']) {
      throw const FormatException('移动目标不能是自身');
    }
    return Map.unmodifiable(output);
  }
}
