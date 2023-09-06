<template>
  <div>
    <!-- 新增调拨出库/类似创建调拨出库 -->
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
                <span>出库仓库：</span>
              </div>
              <div class="value">
                <el-select
                v-model="form.outLibVal"
                placeholder="请选择仓库"
                size="small"
                @change="changeOutLibValHandle"
              >
                <el-option
                  v-for="(item,i) in form.outLibValOption"
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
                <span>入库仓库：</span>
              </div>
              <div class="value">
                <el-select
                v-model="form.inLibVal"
                placeholder="请选择类型"
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

        <div class="tips red-color m-t-6 fs14">
          提示："可出库数量"仅作为参考数量，具体出库数量以实际出库数量为准
        </div>
        <!-- 表格 -->
        <div class="btn-area m-t-4 p-t-1 p-b-1" style="background:#eee">
          <icon-button
            @click.native="addTableRow"
            text="添加物料"
            img="btn_add.png"
            colors="#f5f5f5"
          ></icon-button>
        </div>
        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">序号</div>
                <div class="th"></div>
                <div class="th">物料名称</div>
                <div class="th">一级分类</div>
                <div class="th">二级分类</div>
                <div class="th">单位</div>
                <div class="th">可出库数量</div>
                <div class="th">出库数量</div>
                <div class="th">出库成本小计</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="(item, i) in tableData" :key="item.id">
                <div class="td">{{i + 1}}</div>
                <div class="td">
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
                <div class="td">{{item.maxCount >= 0 ? item.maxCount : '---'}}</div>
                <div class="td">
                  <el-input
                    v-model="item.count"
                    type="number"
                    min="1"
                    @input="inputHandle(item)"
                    placeholder="请输入数量"
                    size="mini"
                  />
                </div>
                <div class="td">{{isNaN(((item.a/item.maxCount)*(item.count || 0)).toFixed(2)) ? '0.00' : ((item.a/item.maxCount)*(item.count || 0)).toFixed(2)}}</div>
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
        outLibVal: '', // 出库仓库
        outLibValOption: [], // 出库仓库option
        inLibVal: '', // 入库仓库
        inLibValOption: [], // 入库仓库option
        remark: '', // 备注
      },

      tableData: [],
      mateOptions: [], // 模糊查询列表
      loading: false, // 是否正在从远程获取数据

      matAllLibInfoList: []  // 从首页进入创建出库单，出库明细商品中的总数量和总金额列表元数据
    };
  },
  methods: {
    // 获取基础信息
    async getAllData(){
      try {
        const res = await this.$api.ERP.soutd.requestsoutdstore_items()
        if(res.code == 1) {
          this.form.outLibValOption = res.data.out_stores || []
          this.form.inLibValOption = res.data.in_stores || []
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
        const res = await this.$api.ERP.soutd.requestsoutdget_f_copy(params)
        if(res.code == 1) {
          this.form.outLibVal = res.data.out_store_id || '' // 出库仓库
          this.form.outLibValOption = res.data.out_stores || [] // 出库仓库option
          this.form.inLibVal = res.data.in_store_id || '' // 入库仓库
          this.form.inLibValOption = res.data.in_stores || '' // 入库仓库
          this.form.remark = res.data.remark || '' // 备注
          this.tableData = []
          for(const key in (res.data.dtls || [])) {
            this.tableData.push({
              isEffective: true,  // 是否为类似创建
              id: res.data.dtls[key].id, // id
              name: res.data.dtls[key].n, // 名字
              oneCate: res.data.dtls[key].moc, // 一级分类
              twoCate: res.data.dtls[key].mtc, // 二级分类
              unit: res.data.dtls[key].un, // 单位名字
              maxCount: res.data.dtls[key].ic || 0, // 库存
              count: res.data.dtls[key].c, // 数量
              a: res.data.dtls[key].ia || 0
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
          store_id: this.form.outLibVal * 1,
          name: query,
          page_num: 1,
          page_size: 9999999
        }
        try {
          const res = await this.$api.ERP.soutd.requestsoutdmat_items(params)
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
          el.id = info.id
          el.name = info.n
          el.oneCate = info.moc;
          el.twoCate = info.mtc;
          el.unit = info.un;
          el.maxCount = info.c
          el.a = info.a
        }
      });
      this.tableData = [...tableData];
      this.mateOptions = []
    },

    addTableRow(){
      if(!this.form.outLibVal) return this.$message.warning('请先选择出库仓库')
      if(!this.form.inLibVal) return this.$message.warning('请先选择入库仓库')
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
        maxCount: 0, // 库存数量
        count: 1 // 数量
      }));
    },

    inputHandle(itemInfo){
      if(isNaN(itemInfo.count * 1)) {
        itemInfo.count = 0
        return this.$message.warning('请输入数字')
      }
      if(itemInfo.maxCount > 0 && itemInfo.count > itemInfo.maxCount) {
        itemInfo.count = itemInfo.maxCount
        return this.$message.warning('最大数量不可超过库存数量')
      }
      if(itemInfo.count < 0) {
        itemInfo.count = 0
      }
    },

    resetHandle(){
      this.form.inLibVal = this.paramsPrdList.id && this.isFirstLoadAdd ? this.paramsPrdList.id : ''
      this.form.outLibVal = ''
      this.form.remark = ''
      this.tableData = this.paramsPrdList.id && this.isFirstLoadAdd ? (this.paramsPrdList.ms || []).map(item => ({
        id: item.id, // id
        name: item.mn, // 名字
        oneCate: item.on, // 一级分类
        twoCate: item.tn, // 二级分类
        unit: item.un, // 单位名字
        maxCount: item.c, // 库存数量
        count: Math.abs(item.c), // 数量
        isParamsPrd: true // 是否为首页跳转过来新建出库单
      })) : []

      // 此处用于从首页进入后创建出库单（获取商品明细中的可出库总数量和总金额）
      if(this.isFirstLoadAdd && this.tableData.length > 0) {
        this.getLibInfo()
      }
    },

    async getLibInfo(){
      const params = {
        mat_ids: this.tableData.filter(item => item.isParamsPrd).map(item => item.id * 1) //    []int64  物料列表
      }
      try {
        const res = await this.$api.ERP.soutd.reqGetMatLibCount(params)
        if(res.code == 1) {
          this.matAllLibInfoList = res.data.records || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取商品可出库总数量和总金额失败', error);
      }
    },

    // 改变出库仓库，更新从首页带过来物料的库存总数量
    changeOutLibValHandle(){
      if(this.isFirstLoadAdd) {
        this.tableData = this.tableData.map(item => {
          const matInfo = this.matAllLibInfoList.find(items => items.s == this.form.outLibVal && items.m == item.id) || {}
          return {
            ...item,
            maxCount: matInfo.c || 0, 
            a: matInfo.a || 0 
          }
        })
      }
    },

    async onSubmit (){
      if(
        !this.form.outLibVal ||
        !this.form.inLibVal
      ) return this.$message.warning('必选框不能为空')
      // 新增
      const params = {
        out_store_id: this.form.outLibVal * 1, // int64 出库仓库id
        in_store_id: this.form.inLibVal * 1, // int 入库仓库id
        remark: this.form.remark, //  string   备注
        mat_ids: this.tableData.filter(item => item.name !=='').map(item => item.isEffective && isNaN(item.name * 1) ? item.id * 1 : item.id * 1), // []int64    物料商品Id列表
        cnts: this.tableData.filter(item => item.name !=='').map(item => item.count * 1), //       []int       物料商品对应单位的数量列表
      }
      try {
        const res = await this.$api.ERP.soutd.requestsoutdnew(params)
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
      this.isFirstLoadAdd = false
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
    },
    
    paramsPrdList: {
      default: () => {} // 从首页传进来的商品列表信息
    },

    isFirstLoad:{ // 首页传进来的商品列表是否为第一次加载（为了区分有传进来的参数时，手动点击重建调拨出库单）
      default: false
    }
  },
  computed: {
    title(){
      return this.type == 1 ? '新增调拨出库' : '类似创建调拨出库'
    },
    show: {
      get(){
        return this.value
      },

      set(val) {
        this.$emit('input', val)
      }
    },
    isFirstLoadAdd: {
      get(){
        return this.isFirstLoad
      },

      set(val) {
        this.$emit('update:isFirstLoad', val)
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