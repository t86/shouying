<template>
  <div>
    <!-- 添加商品 -->
    <el-drawer
      title="添加商品"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      append-to-body
      size="720px"
    >
      <div class="session p-4">
        <!-- 头部筛选项 -->
        <div class="select-top fs14" layout="row" layout-align="start center">
          <div class="item" layout="row" layout-align="start center">
            <div class="label">分类：</div>
            <el-cascader
              v-model="searchFormData.valueArr"
              size="mini"
              :options="searchFormData.options"
              clearable
            ></el-cascader>
          </div>
          <div class="item" layout="row" layout-align="start center">
            <el-input
              v-model="searchFormData.keyword"
              size="mini"
              style="width: 200px"
              placeholder="请输入商品名称或拼音字母"
            ></el-input>
          </div>
          <div class="item" layout="row" layout-align="start center">
            <el-button type="primary" style="background-color: #2170ff" size="mini" @click.stop="getTableData(1)">查询</el-button>
            <el-button type size="mini" @click.stop="restSearchData">重置</el-button>
          </div>
        </div>
        <!-- table -->
        <div class="table-content">
          <div class="table" v-infinite-scroll="getTableData">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">
                  <el-checkbox
                    v-model="checkAll"
                    :indeterminate="isIndeterminate"
                    @change="changeCheckbox('all')"
                  >全选</el-checkbox></div>
                <div class="th">名称</div>
                <div class="th">分类</div>
                <div class="th">单价</div>
              </div>
            </div>
            <div class="tbody">
              <div
                class="tr"
                v-for="(item, index) in tableData"
                :key="index"
                layout="row"
                layout-align="space-between center"
              >
                <div class="td">
                  <el-checkbox
                    :disabled="item.disabled"
                    v-model="item.checked"
                    @change="changeCheckbox('item')"
                  >{{ index + 1 }}</el-checkbox>
                </div>
                <div class="td">{{ item.n }}</div>
                <div class="td">{{ item.on }} > {{item.tn}}</div>
                <!-- <div class="td">{{ (item.price/100.0).toFixed(2) }}</div> -->
                <div class="td">{{ item.price }}</div>
              </div>
              <div class="no-data" v-if="tableData.length==0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
            <p class="m-t-3 fs12" style="text-align:center">{{loadText}}</p>
          </div>
        </div>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click.stop="onCancelDrawer">关闭</el-button>
        <el-button type="primary" style="background-color: #2170ff" @click="submitHandle">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      // 筛选条件
      searchFormData: {
        valueArr: [0, 0],
        options: [],
        keyword: ""
      },
      checkAll: false,
      tableData: [],
      loadText: '',
      pageSize: 50,
      page: 1,
    };
  },
  methods: {
    // 获取商品分类
    async getTableData(init = 2) {
      if (this.loadText === '没有更多了' && init !== 1) {
        return;
      }
      
      this.page = init == 1 ? 1 : this.page + 1
      const params = {
        page_num: this.page,
        page_size: this.pageSize,
        init: init,
        is_init: init,
        name: this.searchFormData.keyword || "",
        one_cate_id: this.searchFormData.valueArr[0],
        two_cate_id: this.searchFormData.valueArr[1],
      };
      try {
        let res = null
        if(this.prdType == "1") {
          res = await this.$api.BMS.pgrp.requestpgrpprd_items(params);
        }else if(this.prdType == '2') {
          res = await this.$api.BMS.station.reqGetOrdExclPrdItems(params);
        }else {
          res = await this.$api.BMS.seat.requestGetSpSeatPrdItems(params);
        }
        if (res.code == 1) {
          if (init == 1) {
            const options = res.data.cates || [];
            options.forEach(el => {
              el.value = el.id;
              el.label = el.n;
              el.children =
                el.ss && el.ss.length > 0
                  ? JSON.parse(JSON.stringify(el.ss))
                  : [];

              el.children.forEach(ele => {
                ele.value = ele.id;
                ele.label = ele.n;
              });
            });
            this.searchFormData.options = [...options];
          }
          const tableData = ((this.prdType == 3 ? res.data.items : res.data.prds) || []).map(item => {
            const isExist = this.checkedPrdList.some(i => i.id === item.id);
            const isInSelectedCate = this.selectList.includes(item.ti);
            return {
              ...item,
              checked: isExist || isInSelectedCate,
              disabled: isExist || isInSelectedCate,
              price: item.p
            }
          })
          this.loadText = tableData.length == this.pageSize ? '加载中...' : '没有更多了'
          this.tableData = init == 1 ? [...tableData] : [...this.tableData, ...tableData]
          this.checkAll = this.tableData.every(item => item.checked)
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("分类options获取失败", error);
      }
    },

    changeCheckbox(type){
      switch(type) {
        case 'all':
          this.tableData = this.tableData.map(item => ({
            ...item,
            checked: item.disabled ? item.checked : this.checkAll
          }))
          break
        case 'item':
          const enabledItems = this.tableData.filter(item => !item.disabled);
          this.checkAll = enabledItems.length > 0 && enabledItems.every(item => item.checked);
          break
      }
    },

    // 重置
    restSearchData() {
      this.searchFormData.valueArr = [0, 0];
      this.searchFormData.keyword = "";
      this.getTableData();
    },

    async submitHandle() {
      const checkedList = this.tableData.filter(item => item.checked);
      if (checkedList.length <= 0) {
        return this.$message.warning("请选择需要添加的商品");
      }

      if(this.prdType * 1 == 1) {
        this.onCancelDrawer();
        this.$emit("getChoosedPrdList", checkedList);
        return;
      }

      const params = {
        station_id: this.stationId,
        seat_id: this.stationId,      //SeatId 功能卡台Id
        prd_ids: this.tableData.filter(item => item.checked).map(item => item.id)
      };
      try {
        if (params.prd_ids.length > 0) {
          let res = null
          if (this.prdType * 1 == 3) {
            res = await this.$api.BMS.seat.requestBatchAddSpSeatPrd(params);
          } else {
            res = await this.$api.BMS.station.reqAddOrdExclPrd(params)
          }
          if (res.code == 1) {
            this.$message.success("操作成功");
            this.onCancelDrawer();
            this.$emit("getTableData");
          } else {
            this.$message.warning(res.msg);
          }
        } else {
          this.$message.success("操作成功");
          this.onCancelDrawer();
          this.$emit("getTableData");
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
      this.onCancelDrawer();
      this.$emit("getChoosedPrdList", checkedList);
    },
    // 关闭drawer
    onCancelDrawer() {
      this.show = false
    }
  },
  props: {
    value: {
      default: false // 是否显示drawer
    },
    prdType: {
      default: "1" // 1.商品组配置， 2：不可点商品配置 3.功能台配置可点商品
    },
    checkedPrdList: {
      type: Array,
      default: () => []
    },
    stationId: {
      default: 0
    },
    selectList: {
      type: Array,
      default: () => []
    }
  },
  computed: {
    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    },

    isIndeterminate(){
      return !this.checkAll && this.tableData.some(item => item.checked)
    }
  },
  watch: {
    value(newVal) {
      this.show = newVal;
      if (newVal) {
        this.getTableData(1);
      } else {
        this.tableData = []
        this.searchFormData.keyword = ''
        this.searchFormData.valueArr = [0, 0]
      }
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
<style scoped lang="less">
.select-top {
  flex-wrap: wrap;

  .item {
    margin: 4px 20px 4px 0;
  }
}

.table {
  max-height: calc(100vh - 200px);
  overflow-y: auto;
  .th,.td {
    &:nth-child(1),
    &:nth-child(4){
      width: 30%;
    }
  }
}
</style>

<style>
.el-icon-arrow-right:before {
  color: #606266;
}
</style>
