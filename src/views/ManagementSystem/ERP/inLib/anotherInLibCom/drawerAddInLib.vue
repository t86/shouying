<template>
  <div>
    <!-- 新增入库/类似创建 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div class="session p-5">
        <!-- 头部表单 -->
        <div class="form">
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="center center">
              <div class="label">
                <span class="red-color">*</span>
                <span>入库仓库：</span>
              </div>
              <div class="value">
                <el-select
                v-model="form.inLibVal"
                placeholder="请选择仓库"
                size="small"
              >
                <el-option
                  v-for="(item,i) in form.inLibValOption"
                  :key="i"
                  :label="item.n"
                  :value="item.id"
                ></el-option>
              </el-select>
              </div>
            </div>
            <div class="item fs14" layout="row" layout-align="center center">
              <div class="label">
                <span class="red-color">*</span>
                <span>入库类型：</span>
              </div>
              <div class="value">
                <el-select
                @change="form.inLibTypeVal == 7 ? form.gysVal = '' : ''"
                v-model="form.inLibTypeVal"
                placeholder="请选择类型"
                size="small"
              >
                <el-option label="采购入库" :value="1"></el-option>
                <el-option label="其他入库" :value="7"></el-option>
                <el-option label="盘盈入库" :value="51"></el-option>
              </el-select>
              </div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="center center">
              <div class="label">
                <span class="red-color">*</span>
                <span>发票类型：</span>
              </div>
              <div class="value">
                <el-select
                v-model="form.fpVal"
                placeholder="请选择发票类型"
                size="small"
              >
                <el-option
                  label="普票"
                  :value="1"
                ></el-option>
                <el-option
                  label="专票"
                  :value="2"
                ></el-option>
              </el-select>
              </div>
            </div>
            <div class="item fs14" layout="row" layout-align="center center">
              <div class="label">
                <span class="red-color" v-if="form.inLibTypeVal != 7">*</span>
                <span>供应商：</span>
              </div>
              <div class="value">
                <el-select
                :disabled="form.inLibTypeVal == 7"
                v-model="form.gysVal"
                placeholder="请选择供应商"
                size="small"
              >
                <el-option
                  v-for="(item,i) in form.gysValOption"
                  :key="i"
                  :label="item.n"
                  :value="item.id"
                ></el-option>
              </el-select>
              </div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="center center">
              <div class="label">
                <span>备注：</span>
              </div>
              <div class="value">
                <el-input
                  type="textarea"
                  v-model="form.remark"
                  :rows="3"
                  placeholder="请输入备注"
                />
              </div>
            </div>
            <div class="item fs14" layout="row" layout-align="center center">
            </div>
          </div>
        </div>

        <!-- 表格 -->
        <div class="table-content m-t-4">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">序号</div>
                <div class="th"></div>
                <div class="th">物料名称</div>
                <div class="th">一级分类</div>
                <div class="th">二级分类</div>
                <div class="th">单位</div>
                <div class="th">入库数量</div>
                <div class="th">入库单价</div>
                <div class="th">入库小计</div>
                <div class="th" v-if="form.fpVal == 2">入库小计(裸价)</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="(item, i) in tableData" :key="item.id">
                <div class="td">{{i + 1}}</div>
                <div class="td" layout="row" layout-align="start center">
                  <icon-button
                    style="width:20px;height:20px"
                    @click.native="addTableRow"
                    text="新增"
                    img="btn_add.png"
                    colors="#f5f5f5"
                  ></icon-button>
                  <icon-button
                    style="width:20px;height:20px"
                    @click.native="delTableRow(item)"
                    text="删除"
                    img="btn_delete.png"
                    colors="#6B2830"
                  ></icon-button>
                </div>
                <div class="td">
                  <el-select
                    v-model="item.name"
                    filterable
                    remote
                    reserve-keyword
                    placeholder="请输入物料拼音首字母或名称的关键字"
                    :remote-method="remoteMethod"
                    :loading="loading"
                    @change="changeNameHandle(item)"
                  >
                    <el-option
                      v-for="items in mateOptions"
                      :key="items.id"
                      :label="items.n"
                      :value="items.id"
                    ></el-option>
                  </el-select>
                </div>
                <div class="td">{{item.oneCate}}</div>
                <div class="td">{{item.twoCate}}</div>
                <div class="td">{{item.unit}}</div>
                <div class="td">
                  <el-input
                    v-model="item.count"
                    type="number"
                    min="1"
                    placeholder="请输入入库数量"
                    size="mini"
                  />
                </div>
                <div class="td">{{form.fpVal==2?(item.amt / 1.13 / item.count).toFixed(4):(item.amt / item.count).toFixed(4)}}</div>
                <div class="td" v-if="form.fpVal==2">{{(item.amt/1.13).toFixed(4)}}</div>
                <div class="td">
                  <el-input
                    v-model="item.amt"
                    type="number"
                    :placeholder="form.fpVal == 2 ?'请输入入库小计(裸价)':'请输入入库小计'"
                    size="mini"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
export default {
  data() {
    return {
      form: {
        inLibVal: '', // 入库仓库
        inLibValOption: [], // 入库仓库option
        inLibTypeVal: '', // 入库类型
        fpVal: '', // 发票类型
        gysVal: '', // 供应商
        gysValOption: [], // 供应商option
        remark: '', // 备注
      },

      tableData: [],
      mateOptions: [], // 模糊查询列表
      loading: false, // 是否正在从远程获取数据
    };
  },
  methods: {
    // 获取基础信息
    async getAllData(){
      try {
        const res = await this.$api.ERP.sin.requestsinnew_sin_items()
        if(res.code == 1) {
          this.form.inLibValOption = res.data.stores || []
          this.form.gysValOption = res.data.suppliers || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('初始化数据获取失败', error);
      }
    },
    // 获取类似创建基础信息
    async getEffectiveData(){
      const params = {
        id: this.currentInfo.id * 1  // int64  入库单Id
      }
      try {
        const res = await this.$api.ERP.sin.requestsinget_f_copy(params)
        if(res.code == 1) {
          this.form.inLibVal = res.data.store_id || '' // 入库仓库
          this.form.inLibValOption = res.data.stores || [] // 入库仓库option
          this.form.inLibTypeVal = res.data.record_type || '' // 入库类型
          this.form.fpVal = res.data.fapiao_type || '' // 发票类型
          this.form.gysVal = res.data.supplier_id || '' // 供应商
          this.form.remark = res.data.remark || '' // 备注
          this.form.gysValOption = res.data.suppliers || []  // 供应商option
          this.tableData = !res.data.dtls ? this.tableRowInit(5) : []
          for(const key in (res.data.dtls || [])) {
            this.tableData.push({
              isEffective: true,  // 是否为类似创建
              id: res.data.dtls[key].id, // id
              name: res.data.dtls[key].n, // 名字
              oneCate: res.data.dtls[key].moc, // 一级分类
              twoCate: res.data.dtls[key].mtc, // 二级分类
              unit: res.data.dtls[key].un, // 单位名字
              count: res.data.dtls[key].c, // 数量
              amt: res.data.dtls[key].p //计算好的入库金额
            })
          }
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('类似创建基础信息获取失败', error);
      }
    },
    // 根据输入的内容模糊查找
    async remoteMethod(query) {
      if (query !== "") {
        this.loading = true;
        const params = {
          name: query,
          page_num: 1,
          page_size: 9999999
        }
        try {
          const res = await this.$api.ERP.sin.requestsinmat_items(params)
          if(res.code == 1) {
            this.mateOptions = res.data || [];
            this.loading = false;
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('查找失败', error);
        }
      } else {
        this.mateOptions = [];
      }
    },    
    // 选择物料名称
    changeNameHandle(itemInfo) {
      const tableData = [...this.tableData];
      const info = this.mateOptions.find(item => item.id == itemInfo.name);
      tableData.forEach(el => {
        if (el.id == itemInfo.id) {
          el.oneCate = info.moc;
          el.twoCate = info.mtc;
          el.unit = info.un;
        }
      });
      this.tableData = [...tableData];
      this.mateOptions = []
    },
    addTableRow(){
      this.tableData = [...this.tableData, ...this.tableRowInit(1)]
    },
    delTableRow(itemInfo){
      const index = this.tableData.findIndex(item => item.id == itemInfo.id)
      this.tableData.splice(index, 1)
    },
    tableRowInit(num){
      return new Array(num).fill(1).map((item, index) => ({
        id: this.tableData.length + 1 + index, // id
        name: "", // 名字
        oneCate: "", // 一级分类
        twoCate: "", // 二级分类
        unit: "", // 单位名字
        count: 1, // 数量
        amt: 0 // 入库小计
      }));
    },
    resetHandle(){
      this.form.inLibVal = ''
      this.form.inLibTypeVal = ''
      this.form.fpVal = ''
      this.form.gysVal = ''
      this.form.remark = ''
    },
    async onSubmit (){
      if(
        !this.form.inLibVal ||
        !this.form.inLibTypeVal ||
        !this.form.fpVal ||
        (!this.form.gysVal && this.form.inLibTypeVal != 7)
      ) return this.$message.warning('必选框不能为空')
      // 新增
      const params = {
        store_id: this.form.inLibVal * 1, // int64 入库仓库id
        record_type: this.form.inLibTypeVal * 1, // int 入库类型 1 采购入库 7 其他入库
        supplier_id: this.form.inLibTypeVal == 7 ? "" : this.form.gysVal * 1, // int64   供应商Id
        fapiao_type: this.form.fpVal * 1, // int     发票类型 普票(传1),专票(传2)
        remark: this.form.remark, //  string   备注
        mat_ids: this.tableData.filter(item => item.name !=='').map(item => item.isEffective && isNaN(item.name * 1) ? item.id * 1 : item.name * 1), //    []int64    物料商品Id列表
        cnts: this.tableData.filter(item => item.name !=='').map(item => item.count * 1), //       []int       物料商品对应单位的数量列表
        amts: this.form.fpVal == 2 ? this.tableData.filter(item => item.name !=='').map(item => (item.amt / 1.13).toFixed(2)) : this.tableData.filter(item => item.name !=='').map(item => (item.amt * 1).toFixed(2)), //  []string   物料商品对应采购总金额 使用字符串表示, 最大支持2位小数
        src_amts: this.tableData.filter(item => item.name !=='').map(item => (item.amt * 1).toFixed(2))//  []string   裸价金额,如果普票,实际金额=src_amt,专票的话,实际金额=src_amt/1.13
      }
      try {
        const res = await this.$api.ERP.sin.requestsinnew(params)
        if (res.code == 1) {
          this.$message.success('创建成功')
          this.onCancelDrawer()
          this.$emit('getTableData')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('创建失败', error);
      }
    },
    onCancelDrawer(){
      this.show = false
    },

  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    type: {
      default: 1
    },
    currentInfo:{
      default: () => ({})
    }
  },
  computed: {
    title(){
      return this.type == 1 ? '新增入库' : '类似创建其他入库'
    },
    show: {
      get(){
        return this.value
      },

      set(val) {
        this.$emit('input', val)
      }
    }
  },
  components: {
    IconButton
  },
  watch: {
    value: {
      handler(newVal) {
        if(newVal) {
          if(this.type == 1) {
            // 新建
            this.resetHandle()
            this.getAllData()
          } else {
            // 类似创建
            this.getEffectiveData()
          }
          this.tableData = this.tableRowInit(5);
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import '../../../../../style/common/elementDrawerWine.less';
@import '../../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../../style/common/elementFormBtnWine.less';
@import '../../../../../style/erp/form.less';
@import '../../../../../style/erp/table.less';
</style>

<style lang="less" scoped>
.coll {
  .item {
    width: 50%;
    .label {
      width: 100px;
      text-align: right;
    }
  }
}

.table-content {
  width: 100%;
  overflow: auto;
  .table {
    min-width: 1300px;
    max-height: calc(100vh - 400px);
    overflow: auto;
    .tr {
      padding-right: 10px;
    }
    
    .th,.td {
      &:nth-child(1) {
        width: 30%;
      }
      
      &:nth-child(2) {
        width: 40%;
      }
    }
  }
}
</style>