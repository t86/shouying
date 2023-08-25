<template>
  <div>
    <!-- 当前组件所用到的地方为：1、erp首页商品对照  2、物料管理-商品对照 -->
    <!-- 绑定erp商品 -->
    <el-drawer
      title="绑定erp商品"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="80%"
    >
      <div class="session p-4">
        <!-- 头部筛选项 -->
        <div class="select-top" layout="row" layout-align="start center">
          <div class="item" layout="row" layout-align="start center">
            <div class="label">分类:</div>
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
            <el-button type="primary" size="mini" @click.stop="getTableData(2)">查询</el-button>
            <el-button type size="mini" @click.stop="restSearchData">重置</el-button>
          </div>
        </div>
        <!-- table -->
        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">行号</div>
                <div class="th">erp商品名称</div>
                <div class="th">erp商品分类树描述</div>
                <div class="th">单位</div>
                <div class="th">状态</div>
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
                    v-model="item.checked"
                    @change="changeCheckboxHandle(item)"
                  >{{ index + 1 }}</el-checkbox>
                </div>
                <div class="td">{{ item.n }}</div>
                <div class="td">{{ item.cp }}</div>
                <div class="td">{{ item.un }}</div>
                <div class="td">{{ item.s }}</div>
              </div>
              <div class="no-data" v-if="tableData.length==0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click.stop="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="submitHandle">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      show: false,
      // 筛选条件
      searchFormData: {
        valueArr: [0, 0],
        options: [],
        keyword: ""
      },
      tableData: []
    };
  },
  methods: {
    // 获取商品分类
    async getTableData(init = 1) {
      const params = {
        page_num: 1,
        page_size: 100000,
        is_init: init,
        erp_cate_id: this.searchFormData.valueArr[1],
        name: this.searchFormData.keyword || ""
      };
      try {
        const res = await this.$api.BMS.Prd.requestprderp_prds(params);
        if (res.code == 1) {
          if (init == 1) {
            const options = res.data.erp_cates || [];
            options.forEach(el => {
              el.value = el.id;
              el.label = el.n;
              el.children =
                el.subs && el.subs.length > 0
                  ? JSON.parse(JSON.stringify(el.subs))
                  : [];

              el.children.forEach(ele => {
                ele.value = ele.id;
                ele.label = ele.n;
              });
            });
            this.searchFormData.options = [...options];
          }
          this.tableData = (res.data.erp_prds || []).map(item => ({
            ...item,
            checked: false
          }));
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("分类options获取失败", error);
      }
    },

    // 改变多选框的值
    changeCheckboxHandle(itemInfo) {
      this.tableData = this.tableData.map(item => ({
        ...item,
        checked: item.id == itemInfo.id
      }));
    },

    // 重置
    restSearchData() {
      this.searchFormData.valueArr = [0, 0];
      this.searchFormData.keyword = "";
      this.getTableData();
    },

    submitHandle() {
      const checkedList = this.tableData.filter(item => item.checked);
      if (checkedList.length <= 0)
        return this.$message.warning("绑定商品不能为空");
      this.onCancelDrawer();
      this.$emit("getBindList", {
        inventory: checkedList,
        currentItem: this.currentItem
      });
    },
    // 关闭drawer
    onCancelDrawer() {
      this.$emit("showOrHideDrawer");
    }
  },
  props: {
    showDrawer: {
      default: false
    },
    currentItem: {
      default: {}
    }
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.searchFormData.keyword = this.currentItem.n || "";
        this.getTableData(1);
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../style/common/elementDrawerWine.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/elementFormBtnWine.less";
@import "../../../../style/erp/table.less";
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
}
</style>

<style>
.el-icon-arrow-right:before {
  color: #606266;
}
</style>