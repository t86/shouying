export const transformCardDataHandle = (arr = [], index = 0) => {
  const resultArr = []
  switch (Number(index)) {
    case 0: // 区域
      arr.forEach(el => {
        resultArr.push({
          id: el[0],  // 区域Id
          name: el[1],  // 区域名称
          status: el[2],  // 区域状态:1有效 2无效 3删除
          dsp: el[3],      // 区域显示顺序
          mustOrderPrdId: el[4]    // 必点商品id
        })
      })
      break
    case 1:  // 卡台
      arr.forEach(el => {
        resultArr.push({
          id: el[0],  //卡台Id
          name: el[1],  // 卡台名称
          status: el[2],  // 卡台状态:1有效 2无效 3删除
          regionId: el[3],  // 所属区域Id
          seatType: el[4],  // 开台类型:1散台 2吧台 3卡座 4包厢
          bizType: el[5],   // 业务类型:1 普通卡台 2 虚拟卡台  3:关联功能台(鸡尾酒) 4:功能台
          capacity: el[6],  // 可坐人数
          dsp: el[7],  // 卡台排序
        })
      })
      break
    case 2:  // 商品一级分类  
      arr.forEach(el => {
        resultArr.push({
          id: el[0],  // 商品一级分类Id
          name: el[1],  // 分类名称
          status: el[2],  // 卡台状态:1有效 2无效 3删除
          dsp: el[3],  // 分类显示顺序
        })
      })
      break
    case 3:  // 商品二级分类  
      arr.forEach(el => {
        resultArr.push({
          id: el[0],  // 商品二级分类Id
          name: el[1],  // 分类名称
          status: el[2],  // 分类状态:1有效 2无效 3 删除
          dsp: el[3],  // 分类显示顺序
          oneCateId: el[4],  // 二级分类所属一级分类Id
          enable_time_limit: el[5],// 开启时间段限制 1 开启 2 未开启,
          begin_time: el[6], // 时间段1开始时间格式hh24:mi,
          end_time: el[7],// 时间段1结束时间,
          begin_time2: el[8],// 时间段2开始时间,
          end_time2: el[9],// 时间段2结束时间
        })
      })
      break
    case 4:  // 商品/套餐   
      arr.forEach(el => {
        resultArr.push({
          id: el[0],  // 商品/套餐Id
          name: el[1],  // 名称
          status: el[2],  // 状态:1有效 2无效 3 删除
          dsp: el[3],  // 显示顺序
          namePy: el[4],  // 拼音首字母(用于模糊筛选)
          nameEng: el[5],  // 英文名
          oneCateId: el[6],  // 所属一级分类Id
          twoCateId: el[7],  // 所属二级分类Id
          price: el[8],  // 单价
          prdType: el[9],  // 商品类型:1存货(关联erp) 7普通(不关联erp) 2套餐 3 时价特饮(关联erp) 4 时价小费 5 时价赔偿 6 联营,13 定价特饮 14 定价小费  15定价赔偿
          bizType: el[10],  // 营业类型 1 主营 2 非主营 3 非主营(分成),
          matId: el[11],  // 关联物料Id 如果=0代表没有关联
          useType: el[12],  // 使用限制 1 无限制 2 仅优惠
          picName: el[13],  // 商品图片
        })
      })
      break
    case 5:  // 员工 
      arr.forEach(el => {
        resultArr.push({
          id: el[0],  // 员工Id
          name: el[1],  // 名称
          status: el[2],  // 状态:1有效 2无效 3 删除
          deptId: el[3],  // 所属部门Id
          stationId: el[4],  // 对应岗位Id
          sex: el[5],  // 性别:1男 2女
          phoneNum: el[6],  // 联系电话
          namePy: el[7],  // 拼音首字母(用于模糊筛选)
          code: el[8],  // 员工工号
          upper_emp_id: el[9],  // 直属上级员工Id
          clone_emp_id: el[10],  // 替身Id
          real_name: el[11], // 真实姓名
        })
      })
      break
    case 6:  // 部门   
      arr.forEach(el => {
        resultArr.push({
          id: el[0],  // 部门Id
          name: el[1],  // 名称
          status: el[2],  // 状态:1有效 2无效 3 删除
          parentId: el[3],  // 所属上级部门Id
        })
      })
      break
    case 7:  // 岗位 
      arr.forEach(el => {
        resultArr.push({
          id: el[0],  // 岗位Id
          name: el[1],  // 名称
          status: el[2],  // 状态:1有效 2无效 3 删除
        })
      })
      break
    case 8:  // 商品估清   
      arr.forEach(el => {
        resultArr.push({
          id: el[0],  // 商品id
          cnt: el[1],  // 商品数量
          status: el[2],  // 状态:1有效 2无效 3 删除
        })
      })
      break
    case 9:  // 套餐明细项  
      arr.forEach(el => {
        resultArr.push({
          prdId: el[0],  // 套餐明细配置项对应的套餐商品Id
          status: el[1],  // 配置状态:1有效 3 删除
          grpId: el[2],  // 套餐配置组Id(=1的时候,代表的是不可替换项可以忽略该组可选项这个数据, 其他代表可替换项)
          seqId: el[3],  // 套餐配置组内顺序Id
          dtlPrdId: el[4],  // 明细单品Id
          prdCnt: el[5],  // 明细单品数量
          grpSelCnt: el[6],  // 该组可选项数
        })
      })
      break
    case 10:  // 库存预警
      arr.forEach(el => {
        resultArr.push({
          prdId: el[0],  // 库存预警预警商品Id
          status: el[1],  // 预警状态:1有效 3 删除
          cnt: el[2],  // 剩余库存数 该数据后续可能会有调整,暂时可以先不管
        })
      })
      break
    case 11:  //  岗位不限可点商品权限 
      arr.forEach(el => {
        resultArr.push({
          stationId: el[0],  // 岗位不限可点商品权限岗位Id
          status: el[1],  // 配置状态: 1有效 3 删除
        })
      })
      break
    case 12:  //  岗位可点二级分类商品权限  
      arr.forEach(el => {
        resultArr.push({
          stationId: el[0],  // 岗位可点二级分类商品权限岗位Id
          status: el[1],  // 配置状态: 1有效 3 删除
          authType: el[2],  // 授权类型:1服务员可点商品 2经营赠送 3 内招 5 外招 6 自用 8 特饮关联
          twoCateId: el[3],  // 商品二级分类Id
        })
      })
      break
    case 13:  // 角色  
      arr.forEach(el => {
        resultArr.push({
          station_id: el[0],  // 岗位系统权限关系岗位Id
          sys_role_id: el[1],  // 系统角色 1 咨客 2服务员 3营销 4特饮 5收银员 6系统管理员 7会员中心 8ERP管理员 9仓库管理员 10 存酒管理员 11 督查
          status: el[2],  // 状态 1有效
        })
      })
      break
    case 14:  // 业务数据(当前卡台列表)   
      arr.forEach(el => {
        resultArr.push({
          seatId: el[0],  // 卡台id
          wkBookId: el[1], // 预订记录
          wkBookTime: el[2], // 预定时间
          wkCsmId: el[3], // 流水记录id
          expArriveTime: el[4],  // 期望达到时间
          openTime: el[5],  // 开台时间
          // openType: el[6],  // 开台类型  0 未开台 1 消费 2 内招 3 外招 4 气氛 5 全转 6 半转
          orderAmt: el[6],  // 点单金额(不包含优惠金额,优惠2金额)
          backAmt: el[7],  // 退款金额
          payedAmt: el[8],  // 已付款金额
          grpMinCsmAmt: el[9],  // 卡台自带抵消金额(根据实际情况设置的默认值)
          assignMinCsmAmt: el[10], // 操作员设置抵消金额(根据grpMinCsmAmt上下调动的金额)
          // intFreeAmt: el[11],  // 内招金额
          // extFreeAmt: el[12],  // 外招金额
          // bizFreeAmt: el[13],  // 业务招待金额
          yhAmt: el[11],  // 优惠金额
          yh2Amt: el[12], // 优惠2金额
          turnoverCnt: el[13],  // 翻台数
          salesEmpId: el[14],  // 订位人Id
          secondSalesEmpId: el[15],  // 联合订位人Id
          customerName: el[16],  // 客户姓名
          customerPhone: el[17],  // 客户电话
          customerCnt: el[18], // 到店人数
          bizStatus: el[19],  // 业务状态 1 空台 2 锁定 3 预订 4 开台 5 点单未结账 6 部分结账 7 已结账 8 线上小程序预定 22 无效 33 删除
          waiter_emp_ids: el[20], // 下单服务员列表 列表以;;分隔 对应empId的列表 例如 ;123;112; 对应empId=123和empId=112两个服务员都在这个卡台下过单
          waiter_emp_ids_arr: el[20].split(';'),  // 当前卡台对应的点单服务员empId（展示在首页我的卡台）
          pay_notify: el[21],  // 支付超时提醒 1 需要提醒 2 不需要提醒
          platform_id: el[22],  // 渠道来源 0 代表本地系统 1 代表微信小程序 (以后有抖音,大众点评等再扩展)
          customer_name_py: el[23],  // 客户名称拼音首字母
          remark: el[24],  // 备注
          mark: el[25],  // 卡台标记
          settle_mode: el[26],  // 买单标记 1 先买单 2 后买单
          payed_val_amt: el[27], // 已付款有价金额
          payed_zy_val_amt: el[28], // 已付款主营有价金额   payed_zy_val_amt 已付款主营有价金额  与 payed_val_amt 可算出已付款非主营有价金额
          payed_free_amt: el[29], // 已付款无价金额
          payed_zy_free_amt: el[30], // 已付款主营无价金额    payed_zy_free_amt 已付款主营无价金额 与 payed_free_amt 可算出已付款非主营无价金额
          order_zy_amt: el[31], // 主营下单金额(不包含优惠,优惠2)
          isOwnBookedCard: false, // 是否是自己或自己下属预定的卡台   此字段用于点单系统营销确认卡台是否为自己或自己下属一定的卡台判断
          chgSeatInfo: el[32],  //  转台信息
          seat_biz_type: el[33], // 卡台类型字段(1 实体台 2 虚拟台 3 关联功能台 4 功能台)
          waiter_emp_id: el[34], // 当台点单服务员
          csm_cust_phone: el[35], // 流水台指定的客人手机号
          csm_cust_name: el[36], // 流水台对应的客人姓名(可能为空)
        })
      })
      break
    case 15:  // 岗位(服务员)可点区域
      arr.forEach(el => {
        resultArr.push({
          station_id: el[0],  // 岗位Id,  
          status: el[1],  // 配置状态: 1有效 3 删除
          region_id: el[2]  // 区域Id
        })
      })
      break
    case 16:  //  区域可点商品 
      arr.forEach(el => {
        resultArr.push({
          region_id: el[0],  // 区域Id
          status: el[1],  //  配置状态: 1有效 3 删除
          prd_id: el[2],  // 商品Id
          mklib_id: el[3]  // 出品库id
        })
      })
      break
    case 17:  //  支付渠道 
      arr.forEach(el => {
        resultArr.push({
          id: el[0],  // 渠道id
          name: el[1],  //  渠道名称
          pay_type: el[2],  // 支付类型:1 联动渠道 2 不联动渠道(只落单)
          auth_type: el[3],  // 授权类型: 1 需要授权 2 不需要授权
          value_type: el[4],  // 价值类型: 1 全有价 2 全免费 3 混合
          status: el[5],  // 状态: 1有效 3 删除
          dsp: el[6],  // 显示顺序
        })
      })
      break
    case 18:  //  营业信息 
      arr.forEach(el => {
        resultArr.push({
          status: '1',  // 1：有效
          wkday_id: el[0],  // 营业日Id: 如果=0 表示营业日未开启 <>0 表示当前营业日id(需与本地存储的营业日id进行比较,如果不一致,需重新拉取 类型14的业务数据
          pic_prefix_url: el[1], // 图片url访问前缀
          org_name: el[2], // 门店名称
        })
      })
      break
    case 19:  //  要求类型 
      arr.forEach(el => {
        resultArr.push({
          id: el[0],  // 要求类型Id
          name: el[1],  // 名称
          status: el[2],  // 状态:1有效 2无效 3 删除
          dsp: el[3],  // 要求类型排序值
          mode_type: el[4],  // 模式:1单选 2多选 
        })
      })
      break
    case 20:  //  要求项
      arr.forEach(el => {
        resultArr.push({
          id: el[0],  // 要求项Id
          name: el[1],  // 名称
          status: el[2],  // 状态:1有效 2无效 3 删除
          typeId: el[3],  // 要求类型Id
          dsp: el[4],  // 要求明细项排序值
        })
      })
      break
    case 21:  //  二级分类要求类型配置
      arr.forEach(el => {
        resultArr.push({
          two_cate_id: el[0],  // 二级分类Id
          rqm_type_id: el[1],  // 要求类型Id
          status: el[2],  // 状态:1有效 2无效 3 删除
        })
      })
      break
    case 22:  //  待退款订单数量小红点（收银系统卡台首页展示）
      arr.forEach(el => {
        resultArr.push({
          status: 1,  // 状态:1有效 2无效 3 删除
          cnt: el[0],  // 小红点数量
        })
      })
      break
    case 23:  //  全量刷新业务数据标记(版本值) refresh_seq 该值与本地保存的值不一致的时候,做业务数据的全量刷新,并保存最新的该值到本地
      arr.forEach(el => {
        resultArr.push({
          status: 1,  // 状态:1有效 2无效 3 删除
          value: el[0],  // 当前版本值
        })
      })
      break
    case 24:  //  咨客可操作日期列表
      arr.forEach(el => {
        resultArr.push({
          status: 1,  // 状态:1有效 2无效 3 删除
          name: el[0],  // 日期显示值
          id: el[1],  // 日期实际值
        })
      })
      break
    case 25:  //  未来(当日以后的)预留业务数据
      arr.forEach(el => {
        resultArr.push({
          book_day_value: el[0], // 与咨客可操作日期日期关键字对应
          seat_id: el[1],  // 卡台id
          book_id: el[2],  // 预定id
          book_time: el[3],  // 预定时间
          exp_arrive_time: el[4],  //  期望到达时间
          sales_emp_id: el[5],  // 订位人Id
          customer_name: el[6],  // 客户名称
          customer_phone: el[7],  // 客户电话
          customer_cnt: el[8],  // 客户数量
          status: el[9],  // 状态:1有效 2无效 3 删除
          platform_id: el[10],  // 渠道来源 0 代表本地系统 1 代表微信小程序 (以后有抖音,大众点评等再扩展)
          second_sales_emp_id: el[11],  // 联合订位人Id
          remark : el[12],  // 联合订位人Id
          customer_name_py : el[13],  // 客户名称拼音
        })
      })
      break
    case 26:  // 线上卡台标记
      arr.forEach(el => {
        resultArr.push({
          status: 1, // 状态
          seat_id: el[0],  // 卡台id
          cardStatus: el[1],  // 1 线上 2或3 线下
        })
      })
      break
    case 27:  // 角色关联花篮,小费商品权限
      arr.forEach(el => {
        resultArr.push({
          station_id: el[0], //  角色Id
          status: el[1], // 1有效 2无效 3删除
          prd_id: el[2], // 关联商品Id
        })
      })
      break
    case 28:  // 当前营业日已转线下卡台
      arr.forEach(el => {
        resultArr.push({
          seat_id : el[0], //  卡台Id
          status: el[1], // 1有效 2无效 3删除
        })
      })
      break
    case 29:  // 咨客台置顶的卡台
      arr.forEach(el => {
        resultArr.push({
          seat_id : el[0], //  卡台Id
          seq_id: el[1], // 顺序值越大越排在前面
          status: el[2], // 1有效  3删除
        })
      })
      break
    case 30:  // 出品库列表
      arr.forEach(el => {
        resultArr.push({
          id : el[0], //  出品库id
          name : el[1], //  出品库名称
          status: el[2], // 1有效  3删除
        })
      })
      break
    case 31:  // 卡台标签定义
      arr.forEach(el => {
        resultArr.push({
          id : el[0], //  出品库id
          name : el[1], // 名称
          status: el[2], // 1有效 2无效  3删除
        })
      })
      break
    case 32:  // 理由定义
      arr.forEach(el => {
        resultArr.push({
          id : el[0], //  理由id
          name : el[1], //  理由
          status: el[2], // 1有效 2无效  3删除
          type_id: el[3]  // 1优惠理由 2退单理由
        })
      })
      break
    case 33:  // 挂账账户
      arr.forEach(el => {
        resultArr.push({
          id : el[0], //  挂账id
          name : el[1], //  账户名称
          status: el[2], // 1有效 2无效  3删除
        })
      })
      break
    case 34:  // 支付渠道过滤
      arr.forEach(el => {
        resultArr.push({
          id : el[0], //  渠道id
          status: el[1], // 1有效 2无效  3删除
        })
      })
      break
    case 35:  // 预定系统卡台是否显示金额
      arr.forEach(el => {
        resultArr.push({
          id : el[0], //  1 自动关闭营业日  2 代表下单付款超时提醒配置  3 限制咨客系统卡台列表和报表总不显示金额  5 限制咨客系统清台
          param1 : el[1], 
          param2 : el[2],  
          param3 : el[3],  
          param4 : el[4],  
          param5 : el[5],  
          paramv1: el[6], // v1
          paramv2: el[7], // v2
          paramv3: el[8], // v3
          paramv4: el[9], // v4
          paramv5: el[10], // v5
        })
      })
  //     35号源数据
  //    id ,param1, param2, param3, param4, param5
  //    id:1 代表自动关闭营业日 param1: 1开启/2关闭  param2:小时  param3:分钟
  //    id:2 代表下单付款超时提醒配置   param1:线上下单超时分钟数  param2:下线下单超时分钟数
  //    id:3 限制咨客系统卡台列表和报表总不显示金额  param1:1禁止/2不禁止   这个就是原来35的数据
  //    id:5 限制咨客系统清台  param1:1禁止/不禁止
      break
    case 36:  // 角色限额限量配置
      arr.forEach(el => {
        resultArr.push({
          station_id: el[0], // 角色id
          auth_type: el[1], // 授权类型 2 优惠 3 优惠2
          free_limit_id: el[2], // 限额配置Id,
          status: el[3]  // 状态 1 有效 2 无效 3 删除
        })
      })
      break
    case 37:  // 限额限量实际明细商品(最终效果)
      arr.forEach(el => {  
        resultArr.push({
          free_limit_id: el[0], // 限额配置Id
          prd_id: el[1], // 商品Id
          status: el[2]  // 状态 1 有效 2 无效 3 删除
        })
      })
      break
    case 38:  // 商户号收款金额汇总
      arr.forEach(el => {  
        resultArr.push({
          id: el[0], // 固定=1
          amt: el[1], // 总金额
          g_amt: el[2], // 对公金额
          status: 1  // 状态 1 有效 2 无效 3 删除
        })
      })
      break
    case 39:  // 卡台状态数量统计
      arr.forEach(el => {  
        resultArr.push({
          id: el[0], // 固定=1  //1 空台 2 锁定 8 当日预留 5 点单(未结) 6 半结 7 已结 10 开台(总数,累计) 20 抵达数,cnt 数量 30 卡台累计开台数 31 卡台累计抵达数
          region_id: el[1], //  区域id(当id=30,31时代表卡台Id)
          cnt: el[2], // 数量 (当id=30表示累计开台数,31时代表卡台累计抵达数)
          status: 1  // 状态 1 有效 2 无效 3 删除
        })
      })
      break
    case 40:  // 设备可操作区域或卡台  // license_id 设备Id, type_id 类型 1 区域 2 卡台, status 1 有效(其他无效), region_o_seat_id 根据type_id对应卡台或区域
      arr.forEach(el => {  
        resultArr.push({
          license_id: el[0], // 设备Id
          type_id: el[1], // 类型 1 区域 2 卡台
          status: el[2], // 1 有效(其他无效)
          region_o_seat_id: el[3]  // 根据type_id对应卡台或区域
        })
      })
      break
    case 41:  // 角色明细
      arr.forEach(el => {  
        resultArr.push({
          station_id: el[0], // 岗位id
          sys_module_id: el[1], // 模块id
          status: el[2], // 状态 1 有效
        })
      })
      break
    case 42:  // 可点商品配置
      arr.forEach(el => {  
        resultArr.push({
          station_id: el[0], // 岗位id
          prd_id: el[1], // 商品id
          status: el[2], // 状态 1 有效
        })
      })
      break
    case 43:  // 前端版本号
      arr.forEach(el => {  
        resultArr.push({
          ver: el[0], // 前端版本号
        })
      })
      break
    case 44:  // 功能台配置可点商品
      arr.forEach(el => {  
        resultArr.push({
          seat_id: el[0], // 卡台id,
          prd_id: el[1], // 可点商品Id
          status: el[2], // 状态 1 有效 3 删除
        })
      })
      break
    case 45:  // 店长配置
      arr.forEach(el => {  
        resultArr.push({
          emp_id: el[0], // 员工id,
          status: el[1], // 状态 1 有效 3 删除
        })
      })
      break
    case 46:  //  排队配置
      arr.forEach(el => {  
        resultArr.push({
          status : el[0], // 小程序排队功能开关  1 开启 2 未开启
          sound_on: el[1], //  语音播报开关 1 开启 2 未开启
          sound_cnt: el[2], //  语音播报次数
          sound_text: el[3], //  语音播报文案, 使用 {排队类型编号} 对应排队号码变量
          number_type: el[4], // 号码样式,1 A1 2 A01 3 A001
        })
      })
      break
    case 47: // 排队类型(主键id)
      arr.forEach(el => {  
        resultArr.push({
          id : el[0], // 主键
          status : el[1], // 状态 1 有效 3 删除
          name: el[2], //  类型名称
          num_prefix: el[3], //  类型编码
          min_cnt: el[4], //  起始人数
          max_cnt : el[5], //  截止人数
          min_csm_amt: el[6], // 抵消金额(单位元)
        })
      })
      break
    case 48: // 排队记录(主键queue_type_id,queue_no)
      arr.forEach(el => {  
        resultArr.push({
          wkday_id : el[0], // 营业日id
          phone_num: el[1], // 客人手机号
          name: el[2], // 客人姓名
          queue_type_id: el[3], // 排队类型id
          queue_no: el[4], // 排队号
          status: el[5], // 状态1 排队中 2 已过号 5 已叫号 3 已取消
          obtain_time: el[6], // 取号时间 取号时间(格式:yyyymmddhh24miss)
          update_time: el[7], // 更新时间(格式:yyyymmddhh24miss) 对应 到店时间 取消时间 过号时间 叫号时间
        })
      })
      break
    case 49: // 当前取号(可用于大屏,可用于咨客操作面板界面)(主键:queue_type_id)
      arr.forEach(el => {  
        resultArr.push({
          wkday_id : el[0], // 营业日id
          queue_type_id: el[1], //  排队类型id
          last_gen_num: el[2], //  当前取到几号了
          curr_no: el[3], //  当前轮到哪个号了=0代表没有了
          curr_no_status: el[4], //  当前叫号状态 1 排队中(可以叫号,过号,入场), 2,5 已过号,已入场(只能叫号)
          wait_cnt: el[5], //  等待桌数
          wait_no: el[6], //  等待叫号
        })
      })
      break
    case 50: // 岗位附加可赠送卡台列表(主键station_id+seat_id)
      arr.forEach(el => {  
        resultArr.push({
          station_id : el[0], // 岗位id
          seat_id: el[1], //  附加可赠送卡台id
          status: el[2], //  状态1有效 3删除
        })
      })
      break
  }
  return resultArr
}
