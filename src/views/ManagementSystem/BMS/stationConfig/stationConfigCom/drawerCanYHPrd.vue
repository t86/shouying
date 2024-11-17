<template>
  <div>
    <!-- 优惠/优惠2 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="900px"
    >
      <div class="session p-5 erp-lib-detail fs14">
        <div class="discount-form">
          <el-form>

            <el-form-item label="当台必点商品下单后才可优惠：">
                <el-radio v-model="must_order_bef_yh" :label="2">否</el-radio>
                <el-radio v-model="must_order_bef_yh" :label="1">是</el-radio>
            </el-form-item>

            <el-form-item label="主营点单达当前台低消才可优惠：">
                <el-radio v-model="zyorder_over_seat_min_csm" :label="2">否</el-radio>
                <el-radio v-model="zyorder_over_seat_min_csm" :label="1">是</el-radio>
              <div class="note">
                选择“是”后，主营点单金额未达当台低消时不允许赠送商品
              </div>
            </el-form-item>

            <el-form-item label="优惠比例限制：">
              优惠金额不得超过当前前台的主营点单的
              <el-input type="number" v-model="zyorder_free_percent" placeholder="输入1-100" class="input-with-append">
                <template slot="append">%</template>
              </el-input>
              <div class="note">
                不配置则以限额限量为准，配置后优先以比例限制为准；填写0则默认为未配置
              </div>
            </el-form-item>
            <el-form-item label="优惠卡台列表：">
              <div class="card-layout">
                <el-button @click="showOrHideChooseCardHandle" type="primary">选择卡台</el-button>
                <div class="note">
                  配置的卡台有无订位人都可直接优惠
                </div>
                <div class="table table1">
                  <div class="thead">
                    <div class="tr" layout="row" layout-align="space-between center">
                      <div class="th" style="text-align: center;">区域名称</div>
                      <div class="th" style="text-align: center;">区域状态</div>
                      <div class="th" style="text-align: center;">卡台名称</div>
                      <div class="th" style="text-align: center;">卡台状态</div>
                    </div>
                  </div>
                  <div class="tbody merged">
                    <table class="merged-table">
                      <tbody>
                        <template  v-for="(group, areaName) in groupedData">
                          <tr >
                            <td :rowspan="group.length">{{ areaName }}</td>
                            <td :rowspan="group.length">
                              {{ group[0].areaStatus * 1 == 1 ? '有效' : '无效' }}
                            </td>
                            <td>{{ group[0].name }}</td>
                            <td>{{ group[0].status * 1 == 1 ? '有效' : '无效' }}</td>
                          </tr>
                          <tr v-for="item in group.slice(1)" :key="item.id">
                            <td>{{ item.name }}</td>
                            <td>{{ item.status * 1 == 1 ? '有效' : '无效' }}</td>
                          </tr>
                        </template >
                      </tbody>
                    </table>
                
                    <div class="no-data" v-if="tableData.length === 0">
                      <img :src="require('@/assets/img/wu.png')" alt />
                      <p>暂无数据</p>
                    </div>
                  </div>
                </div>
              </div>
             
            </el-form-item>
          </el-form>
        </div>

        <!-- 选择限额限量 -->
        <div class="tips">
          <span class="red-color">*</span>
          <span class="fs14">选择限额限量</span>
        </div>
        <div class="table-content m-t-3">
          <div class="table table1">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">
                  <el-checkbox
                    v-model="checkAll"
                    :indeterminate="isIndeterminate"
                    @change="changeCheckboxHandle('all')"
                  >全选</el-checkbox>
                </div>
                <div class="th">名称</div>
                <div class="th">日限量</div>
                <div class="th">日限额</div>
                <div class="th">月限量</div>
                <div class="th">月限额</div>
                <div class="th">商品组数</div>
                <div class="th">创建时间</div>
              </div>
            </div>
            <div class="tbody">
              <div
                class="tr"
                layout="row"
                layout-align="space-between center"
                v-for="(item, index) in tableData"
                :key="item.id"
              >
                <div class="td">
                  <div style="width: 60px;text-align:left">
                    <el-checkbox
                      v-model="item.checked"
                      @change="changeCheckboxHandle('item')"
                    >{{index + 1}}</el-checkbox>
                  </div>
                </div>
                <div class="td">{{item.n}}</div>
                <div class="td">{{item.dc}}</div>
                <div class="td">{{item.dm}}</div>
                <div class="td">{{item.mc}}</div>
                <div class="td">{{item.mm}}</div>
                <div class="td">{{item.gc}}</div>
                <div class="td">{{item.c}}</div>
              </div>
              <div class="no-data" v-if="tableData.length==0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
        </div>
        <!-- 可优惠商品列表 -->
        <div class="tips m-t-3">
          <span class="red-color">*</span>
          <span class="fs14">可优惠商品列表</span>
          <span class="red-color">(限额限量商品组中的商品即为该岗位可优惠的商品)</span>
        </div>
        <div class="table-content m-t-3">
          <div class="table table2">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">序号</div>
                <div class="th">商品名称</div>
                <div class="th">一级分类</div>
                <div class="th">二级分类</div>
                <div class="th">单价</div>
              </div>
            </div>
            <div class="tbody">
              <div
                class="tr"
                layout="row"
                layout-align="space-between center"
                v-for="(item, index) in tableDataPrd"
                :key="item.id"
              >
                <div class="td">{{index + 1}}</div>
                <div class="td">{{item.p}}</div>
                <div class="td">{{item.o}}</div>
                <div class="td">{{item.t}}</div>
                <div class="td">{{item.r}}</div>
              </div>
              <div class="no-data" v-if="tableDataPrd.length==0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>

      <fullPageTable
          titleText="选择卡台"
          ref="fullPageTableRef"
          @showOrHideFullPageHandle="showOrHideChooseCardHandle"
          @setChoosedCardInfo="setChoosedCardInfo"
          :selectedCardInfo="choosedCardInfo"
          v-if="showFullPage"
        />
    </el-drawer>
  </div>
</template>
 
<script>
import fullPageTable from "./components/fullPageTable"; // 转台

export default {
  data() {
    return {
      must_order_bef_yh: 2,
      zyorder_over_seat_min_csm : 2,
      zyorder_free_percent: 0,
      checkAll: false,
      tableData: [], 
      tableDataPrd: [], 
      showFullPage: false,
      choosedCardInfo: [] // 选择好的卡台信息
    };
  },
  methods: {
    // 显示或隐藏选择卡台组件
    showOrHideChooseCardHandle() {
      this.showFullPage = !this.showFullPage;
    },
    setChoosedCardInfo(info) {
      this.choosedCardInfo = [...info];
      this.showFullPage = false;
    },

    async getTableData() {
      const params = {
        id: this.checkedList[0].id * 1 //    []int64   待读取岗位Id列表
      }
      try {
        const res = this.type == 1
            ? await this.$api.BMS.station.reqGetGiveCateConfig(params)
            : await this.$api.BMS.station.reqGetGive2CateConfig(params)

        if (res.code == 1) {
          this.zyorder_over_seat_min_csm = res.data.zyorder_over_seat_min_csm
          this.zyorder_free_percent = res.data.zyorder_free_percent
          this.must_order_bef_yh = res.data.must_order_bef_yh
          this.tableData = (res.data.free_limits || []).map(item => ({
            ...item,
            checked: item.st == 1
          }));
          this.checkAll = this.tableData.every(item => item.checked)
          const areas = res.data.sales_addition_seats || []
          areas.forEach(area => {
            area.ss.forEach(item => {
              this.choosedCardInfo = [...this.choosedCardInfo, {...item, areaStatus: area.s, areaName: area.n, status: item.s, name: item.n }]
            });
          })
          this.getPrdTableData()
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据请求失败", error);
      }
    },

    async getPrdTableData() {
      const params = {
        free_limit_ids: this.tableData.filter(item => item.checked).map(item => item.id * 1)
      }
      if(params.free_limit_ids.length == 0) return this.tableDataPrd = []
      try {
        const res = await this.$api.BMS.station.reqGetChoosePrdList(params)
        if (res.code == 1) {
          this.tableDataPrd = res.data.records || []
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据请求失败", error);
      }
    },


    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData = this.tableData.map(item => ({
            ...item,
            checked: this.checkAll
          }));
          break;
        case "item":
          this.checkAll = this.tableData.every(item => item.checked);
          break;
      }
      this.getPrdTableData()
    },

    async onSubmit() {
      const params = {
        station_id: this.checkedList[0].id, // []int64   待操作角色Id列表
        free_limit_ids: this.tableData.filter(item => item.checked).map(item => item.id * 1), // []int64   选中的限额限量组列表
      };

      try {
        let res
        if (this.type === 1) {
          params.zyorder_over_seat_min_csm  = this.zyorder_over_seat_min_csm * 1
          params.zyorder_free_percent  = this.zyorder_free_percent * 1
          params.must_order_bef_yh = this.must_order_bef_yh * 1
          params.sales_addition_seats = this.choosedCardInfo.map(item => item.id * 1)
          res = await this.$api.BMS.station.reqSetGiveCateConfig(params)
        } else {
          res = await this.$api.BMS.station.reqSetGive2CateConfig(params)
        }

        if (res.code == 1) {
          this.$message.success('操作成功')
          this.onCancelDrawer()
          this.$emit('getTableData')
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("设置限额失败", error);
      }
    },
    
    onCancelDrawer() {
      this.show = false;
    }
  },
  mounted() {
  },
  props: {
    value: {
      default: false // 是否显示drawer
    },
    checkedList: {
      default: () => []
    },
    type: {
      default: 1
    }
  },
  computed: {
    title() {
      return this.type == 1 ? '优惠' : '优惠2'
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    },
    isIndeterminate() {
      return !this.checkAll && this.tableData.some(item => item.checked);
    },
    groupedData() {
      const groups = this.choosedCardInfo.reduce((acc, item) => {
        if (!acc[item.areaName]) {
          acc[item.areaName] = [];
        }
        acc[item.areaName].push(item);
        return acc;
      }, {});

      return groups;
    }
  },

  components:{
    fullPageTable
  },

  watch: {
    value: {
      handler(newVal) {

        if (newVal) {
          this.getTableData();
        } else {
          this.choosedCardInfo = []
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../style/common/elementDrawerWine.less";
@import "../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../style/erp/form.less";
@import "../../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
.table-content {
  .table {
    &.table1 {
      height: 30vh;
      overflow: auto;
      .th,.td {
        &:nth-child(1),
        &:nth-child(3),
        &:nth-child(7){
          width: 30%;
        }
        &:nth-child(2),
        &:nth-child(8){
          width: 70%;
        }
      }
    }
    &.table2 {
      height: 44vh;
      overflow: auto;
    }
  }
}
.card-layout {
  .table {
      height: 30vh;
      overflow: auto;
      .th,.td {
          width: 25% !important;
      }
  }
}
.discount-form {
  margin-bottom: 10px;
}

.el-form-item {
  margin-bottom: 20px;
}

.default-note {
  background-color: yellow;
  padding: 10px;
  margin-bottom: 20px;
  text-align: center;
}

.input-with-append {
  width: 150px;
}

.note {
  color: red;
  font-size: 14px;
}

.merged-table {
  width: 100%;
  border-collapse: collapse;
  table-layout: fixed; /* 使用固定布局确保列宽均匀 */
  tr{
    width: 100%;
  }
}

.merged-table td {
  border: 1px solid #ccc;
  text-align: center;
  height: 40px;
  width: 25%; /* 每列占 25%，确保 4 列平均分配 */
  box-sizing: border-box; /* 确保 padding 不会影响总宽度 */
  word-wrap: break-word; /* 允许长文本换行 */
  overflow: hidden; /* 防止内容溢出 */
}

</style>