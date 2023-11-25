<template>
  <div>
    <!-- 可点商品 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      
      <div class="session p-5 erp-lib-detail fs14">
        <div class="coll p-b-3 border-bottom">
          <div class="value m-t-3 m-l-8">
            <el-button type="primary" size="small" @click.native="showAddPrdDrawer = true">新增商品</el-button>
            <el-button type="primary" size="small" @click.native="deleteHandle">批量删除</el-button>
          </div>
        </div>
        <div class="table-content m-t-3">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">
                  <el-checkbox
                    v-model="checkAll"
                    :indeterminate="indeterminate"
                    @change="changeCheckboxHandle('all')"
                  >全选</el-checkbox>
                </div>
                <div class="th">单品</div>
                <div class="th">分类</div>
                <div class="th">单价</div>
              </div>
            </div>
            <div class="tbody">
              <div
                class="tr"
                v-for="(item, index) in tableData"
                :key="item.id"
                layout="row"
                layout-align="space-between center"
              >
                <div class="td">
                  <el-checkbox
                    v-model="item.checked"
                    @change="changeCheckboxHandle('item')"
                  >{{index + 1}}</el-checkbox>
                </div>
                <div class="td">{{item.n}}</div>
                <div class="td">{{ item.on }} > {{item.tn}}</div>
                <div class="td">{{item.p}}</div>
              </div>
              <div class="no-data" v-if="tableData.length==0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 添加商品 -->
      <drawerAddPrd v-model="showAddPrdDrawer" @getChoosedPrdList="getChoosedPrdList" :stationId="currentInfo.id" prdType="3" :checkedPrdList="tableData" />

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import { cloneDeep } from "lodash-es";
export default {
  data() {
    return {
      checkAll: false,
      indeterminate: false,
      showAddPrdDrawer: false,
      tableData: [],
      dialogSaveVisible: false,
    };
  },
  methods: {
    getChoosedPrdList(prdList){
      this.tableData = [...this.tableData, ...prdList].filter((item, index, arr) => arr.findIndex(items => items.id == item.id) == index)
      this.checkAll = this.tableData.every(item => item.checked)
    },
    // 删除
    async deleteHandle() {
      const checkedIdList = this.tableData.filter(item => item.checked).map(item => item.id)

      const res = await this.$api.BMS.seat.requestBatchDelSpSeatPrd({
        seat_id: this.currentInfo.id,
        prd_ids: checkedIdList
      });
      if (res.code == 1) {
        this.$message.success("批量删除成功");
        const tableData = []
        this.tableData.forEach(el => {
          if(!checkedIdList.find(item => item == el.id)) tableData.push(el)
        })
        this.tableData = [...tableData]
        this.checkAll = false
      } else {
        this.$message.warning(res.msg);
      }
    },
    changeCheckboxHandle(type) {
      console.log('changeCheckboxHandle', type)
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
      this.indeterminate = !this.checkAll && this.tableData.some(item => item.checked)
      
    },
    // saveAndChange(){
    //   this.dialogSaveVisible = false
    //   this.onSubmit(false);
    // },
    async getDetail() {
      const params = {
        seat_id: this.currentInfo.id,
      };
      try {
        const res = await this.$api.BMS.seat.requestGetSpSeatPrdList(
          params
        );
        if (res.code == 1) {
          this.tableData = res.data.records || []

        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    // 点击可点商品全部checkbox
    checkAllHandle(val) {
      setTimeout(() => {
        this.checkAll = val;
        this.indeterminate = false;
      });
    },

    // async onSubmit(isClose = true) {
    //   const params = {
    //     prd_ids: this.tableData.map(item => item.id),  //PrdIds 待添加商品Id列表
    //     seat_id: this.currentInfo.id,      //SeatId 功能卡台Id
    //   };
    //   try {
    //     const res = await this.$api.BMS.seat.requestBatchAddSpSeatPrd(
    //     params
    //     );
    //     if (res.code == 1) {
    //       this.$message.success("操作成功");
    //       if(isClose) {
    //         this.onCancelDrawer();
    //       }
    //       this.$emit("getTableData");
    //     } else {
    //       this.$message.warning(res.msg);
    //     }
    //   } catch (error) {
    //     console.log("数据请求失败", error);
    //   }
    // },

    onCancelDrawer() {
      this.show = false;
      this.checkAll = false
      this.tableData = []
    },
  },
  mounted() {},
  props: {
    value: {
      default: false, // 是否显示drawer
    },
    currentInfo: {
      default: () => {},
    },
  },
  computed: {
    title() {
      return "可点商品";
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      },
    },
  },

  components: {
    drawerAddPrd: () => import('../../../prdGroupConfig/prdGroupCom/drawerAddPrd.vue')
  },

  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.getDetail();
        }
      },
      immediate: true,
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../style/erp/form.less";
@import "../../../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
.coll {
  .label {
    width: 120px;
  }
}
</style>
