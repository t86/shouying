<template>
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="720px"
      append-to-body
    >
  
      <div v-if="step == 1" class="session p-3 fs14">
        <span class="red">*</span>
        <span>选择卡等级：</span>
        <el-select
          v-model="levelVal"
          size="small"
          placeholder="请选择会员卡等级"
          style="width: 200px"
        >
          <el-option
            v-for="item in levelOption"
            :key="item.id"
            :label="item.n"
            :value="item.id"
          ></el-option>
        </el-select>


        <p class="m-2">选择扣款规则</p>

        <div>
          <el-radio class="m-t-3 m-l-3" v-model="ruleValue" label="1"
            >按比例扣款</el-radio
          >
        </div>
        <div>
          <el-radio class="m-t-3 m-l-3" v-model="ruleValue" label="2"
            >优先用赠送金额</el-radio
          >
        </div>
        <div>
          <el-radio class="m-t-3 m-l-3" v-model="ruleValue" label="3"
            >只能用储值金额</el-radio
          >
        </div>
        <div>
          <el-radio class="m-t-3 m-l-3" v-model="ruleValue" label="4"
            >只能用赠送金额</el-radio
          >
        </div>
      </div>

      <div v-if="step == 2" class="session p-3 fs14">
        <!-- 头部筛选项 -->
        <div class="select-top" layout="row" layout-align="start center">
          <div class="item" layout="row" layout-align="start center">
            <div class="label">分类:</div>
            <el-cascader
              v-model="searchFormData.valueArr"
              :options="searchFormData.options"
              clearable
            ></el-cascader>
          </div>
          <div class="item" layout="row" layout-align="start center">
            <el-input
              v-model="searchFormData.keyword"
              style="width: 200px"
              placeholder="请输入商品名称或拼音字母"
            ></el-input>
          </div>
          <div class="item" layout="row" layout-align="start center">
            <el-button type="primary" size="small" @click.stop="getTableData(2)"
              >查询</el-button
            >
            <el-button type="primary" size="small" @click.stop="restSearchData"
              >重置</el-button
            >
          </div>
        </div>
        <!-- table -->
        <!-- v-infinite-scroll="loadNextPageHandle"
                  infinite-scroll-distance="1" -->
        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">
                  <el-checkbox
                    v-model="checked"
                    :indeterminate="isIndeterminate"
                    @change="changeCheckboxHandle('all')"
                    >全选</el-checkbox
                  >
                </div>
                <div class="th">商品名称</div>
                <div class="th">分类</div>
                <div class="th">商品类型</div>
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
                    :checked="item.checked"
                    @change="changeCheckboxHandle('item')"
                    >{{ index + 1 }}</el-checkbox
                  >
                </div>
                <div class="td">{{ item.n }}</div>
                <div class="td">{{ item.on }} > {{ item.tn }}</div>
                <div class="td">{{ item.t }}</div>
              </div>
              <div class="no-data" v-if="tableData.length == 0">
                <img src="@/assets/img/wu.png" alt />
                <p>暂无数据</p>
              </div>
              <!-- <div
                class="tips p-t-2 fs14"
                style="text-align: center"
                v-if="tableData.length > 0"
              >
                {{ isLoaded ? "没有更多了" : "加载中..." }}
              </div> -->
            </div>
          </div>
        </div>
      </div>

      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button size="small" type="info" @click.stop="closeDrawerHandle"
          >关闭</el-button
        >
        <el-button type="primary" size="small" @click="submitHandle">{{
          step == 1 ? "下一步" : "确定"
        }}</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_vip from "@/api/vip";

export default {
  props: {
    item: {},
    showDrawer: {
      default: false,
    },

    addedSeatList: {
      default: () => [],
    },
    levelOption: {
      default: () => [],
    },
  },
  data() {
    return {
      step: 1,
      show: false,
      ruleValue: "",
      // 筛选条件
      searchFormData: {
        valueArr: [0, 0],
        options: [],
        keyword: "",
      },
      tableData: [],
      checked: false,
      isLoaded: false,

      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0,
      },
      levelVal: 0,
    };
  },
  methods: {
    // 获取表格数据
    async getTableData(init = 2) {
      // if (init == 1) {
      //   // this.pageInfo.page = 1;
      //   this.isLoaded = false;
      // }
      // if (this.isLoaded) return;
      const params = {
        name: this.searchFormData.keyword || "", //  string   搜索关键字
        // page_num: this.pageInfo.page * 1, //   int        //PageNum 第几页
        // page_size: this.pageInfo.pageSize, //  int        //PageSize 每页多少行
        init: init, //       int        //Init  初始化标记 1 初始化, 会返回一级分类的结构    2 非初始化, 不返回一级分类结构
        one_cate_id: this.searchFormData.valueArr[0] * 1, // int64    商品一级分类Id =0代表不限制
        two_cate_id: this.searchFormData.valueArr[1] * 1, // int64   商品二级分类Id =0代表不限制
      };

      try {
        const res = await api_vip.reqGetVipBillRuleProductsList(params);
        if (res.code == 1) {
          if (init == 1) {
            const options = res.data.cates || [];
            options.forEach((el) => {
              el.value = el.id;
              el.label = el.n;
              el.children =
                el.ss && el.ss.length > 0
                  ? JSON.parse(JSON.stringify(el.ss))
                  : [];

              el.children.forEach((ele) => {
                ele.value = ele.id;
                ele.label = ele.n;
              });
            });

            this.searchFormData.options = [...options];
          }
          this.tableData = (res.data.prds || []).map((item) => {
            item.on = this.searchFormData.options.find(
              (i) => i.value == item.oi
            ).n;
            item.tn = this.searchFormData.options
              .find((i) => i.value == item.oi)
              .children.find((i) => i.value == item.ti).n;
            return {
              ...item,
              disabled: this.addedSeatListId.includes(item.id * 1),
              checked: this.addedSeatListId.includes(item.id * 1),
            };
          });

          // this.tableData =
          //   init == 1 ? [...tableData] : [...this.tableData, ...tableData];

          this.checked = this.tableData.every((item) => item.checked);

          // this.isLoaded =
          //   this.tableData.length < this.pageInfo.pageSize * this.pageInfo.page;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取商品列表失败", error);
      }
    },
    // 改变多选框的值
    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData.forEach((el) => {
            if (!el.disabled) el.checked = this.checked;
          });
          break;
        case "item":
          this.checked = this.tableData
            .filter((item) => !item.disabled)
            .every((item) => item.checked);
          break;
      }
      this.$forceUpdate();
    },

    reset() {
      this.searchFormData.valueArr = [0, 0];
      this.searchFormData.keyword = "";
      this.step = 1;
    },

    // 重置
    restSearchData() {
      this.reset();
      this.getTableData(1);
    },

    async submitHandle() {
      if (this.step == 1) {
        if (!this.ruleValue) {
          return this.$message.warning("请选择需要添加的商品");
        }
        this.step = 2;
        return;
      }
      const params = {
        prd_ids: this.tableData
          .filter((item) => item.checked && !item.disabled)
          .map((item) => item.id * 1), //   []int64   待添加商品列表
        type_id: this.ruleValue * 1,
        card_level_id: this.levelVal,
        card_type_id: this.item.id,
      };

      if (params.prd_ids.length <= 0)
        return this.$message.warning("请选择需要添加的商品");

      try {
        const res = await api_vip.reqAddVipBillRule(params);
        if (res.code == 1) {
          this.closeDrawerHandle();
          this.$emit("getTableData", this.menuId);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("添加商品失败", error);
      }
    },
    // 加载下一页
    loadNextPageHandle() {
      this.pageInfo.page = this.pageInfo.page + 1;
      this.getTableData();
    },
    // 关闭drawer
    closeDrawerHandle() {
      this.reset();
      this.$emit("showOrHideDrawerHandle");
    },
  },
  computed: {
    title() {
      return this.step == 1 ? "选择扣款规则" : "选择商品";
    },

    addedSeatListId() {
      return this.addedSeatList.map((item) => item.id * 1);
    },

    isIndeterminate() {
      if (
        this.tableData
          .filter((item) => !item.disabled)
          .every((item) => item.checked)
      ) {
        return false;
      } else {
        return this.tableData.some((item) => item.checked);
      }
    },
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.getTableData(1);
      }
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawerWine.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtnWine.less";
@import "../../../style/erp/form.less";
@import "../../../style/erp/table.less";
</style>
<style scoped lang="less">
@import "./drawerAddRuleCom.less";
</style>

<style>
.el-icon-arrow-right:before {
  color: #606266;
}
.red {
   color: red;
}
</style>
