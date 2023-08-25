<template>
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      :size="status == 1 ? '50%' : '80%'"
    >
      <div class="session p-3 fs14">
        <div v-if="status == 1" style="margin-top: 30px;">
          <span class="red-color p-l-6">*</span>
          <span>选择规则对象：</span>
          <el-radio v-model="radioVal" :label="1">点单人</el-radio>
          <el-radio v-model="radioVal" :label="2">订位人</el-radio>
          <p class="red-color fs12"></p>
        </div>
        <div v-else>
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
              <el-button type="primary" size="small" @click.stop="getTableData(1)">查询</el-button>
              <el-button type="primary" size="small" @click.stop="restSearchData">重置</el-button>
            </div>
          </div>
          <!-- table -->
          <div class="table-content" v-infinite-scroll="loadNextPageHandle" infinite-scroll-distance='1'>
            <div class="table">
              <div class="thead">
                <div class="tr" layout="row" layout-align="space-between center">
                  <div class="th">
                    <el-checkbox
                      v-model="checked"
                      :indeterminate="isIndeterminate"
                      @change="changeCheckboxHandle('all')"
                    >全选</el-checkbox>
                  </div>
                  <div class="th">商品名称</div>
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
                      v-model="item.checked"
                      @change="changeCheckboxHandle('item')"
                    >{{ index + 1 }}</el-checkbox>
                  </div>
                  <div class="td">{{ item.n }}</div>
                  <div class="td">{{ item.on }} > {{ item.tn }}</div>
                  <div class="td">{{item.price}}</div>
                </div>
                <div class="no-data" v-if="tableData.length == 0">
                  <img src="@/assets/img/wu.png" alt />
                  <p>暂无数据</p>
                </div>
                <div class="tips p-t-2 fs14" style="text-align:center" v-if="tableData.length > 0">{{isLoaded ? '没有更多了' : '加载中...' }}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button size="small" type="info" @click.stop="closeDrawerHandle">关闭</el-button>
        <el-button type="primary" size="small" @click="submitHandle">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      // menuId: "",
      status: 1, // 1 选择点单人/订位人  2 添加商品
      radioVal: 1, // 1 点单人  2订位人
      show: false,
      // 筛选条件
      searchFormData: {
        valueArr: [0, 0],
        options: [],
        keyword: ""
      },
      tableData: [],
      checked: false,
      isLoaded: false,

      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0
      },
    };
  },
  methods: {
    // 获取表格数据
    async getTableData(init = 2) {
      if(init == 1) {
        this.pageInfo.page = 1
        this.isLoaded = false
      }
      if(this.isLoaded) return
      const params = {
        name: this.searchFormData.keyword || '', //  string   搜索关键字
        page_num: this.pageInfo.page * 1 , //   int        //PageNum 第几页
        page_size: this.pageInfo.pageSize, //  int        //PageSize 每页多少行
        init: init, //       int        //Init  初始化标记 1 初始化, 会返回一级分类的结构    2 非初始化, 不返回一级分类结构
        one_cate_id: this.searchFormData.valueArr[0] * 1, // int64    商品一级分类Id =0代表不限制
        two_cate_id: this.searchFormData.valueArr[1] * 1, // int64   商品二级分类Id =0代表不限制
      };

      try {
        const res = await this.$api.BMS.cutPrd.reqGetPrdCatePrdList(params);
        if(res.code == 1) {
          if (init == 1) {
            const options = res.data.cates || [];
            options.forEach(el => {
              el.value = el.id
              el.label = el.n
              el.children =
                el.ss && el.ss.length > 0
                  ? JSON.parse(JSON.stringify(el.ss))
                  : []

              el.children.forEach(ele => {
                ele.value = ele.id
                ele.label = ele.n
              });
            });

            this.searchFormData.options = [...options]
          }
          const tableData = (res.data.prds || []).map(item => ({
            ...item,
            checked: false
          }));

          this.tableData = init == 1 ? [...tableData] : [...this.tableData, ...tableData]

          this.checked = this.tableData.every(item => item.checked)

          this.isLoaded = this.tableData.length < this.pageInfo.pageSize * this.pageInfo.page
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("获取商品列表失败", error);
      }
    },
    // 改变多选框的值
    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData.forEach(el => {
            if (!el.disabled) el.checked = this.checked;
          });
          break;
        case "item":
          this.checked = this.tableData
            .filter(item => !item.disabled)
            .every(item => item.checked);
          break;
      }
      this.$forceUpdate();
    },

    // 重置
    restSearchData() {
      this.searchFormData.valueArr = [0, 0];
      this.searchFormData.keyword = "";
      this.getTableData(1);
    },

    async submitHandle() {
      if(this.status == 1) {
        this.getTableData(1);
        this.isLoaded = false
        return this.status = 2
      }
      const params = {
        dept_id: 0, // this.menuId * 1, //   int64 部门Id
        type_id: this.radioVal * 1, //   int  抽成对象类型 1 点单人 2 订位人
        prd_ids: this.tableData
          .filter(item => item.checked)
          .map(item => item.id * 1) //   []int64   待添加商品列表
      };

      if (params.prd_ids.length <= 0)
        return this.$message.warning("请选择需要添加的商品");

      try {
        const res = await this.$api.BMS.cutPrd.reqAddPrdConfig(params);
        if(res.code == 1) {
          this.closeDrawerHandle();
          this.$emit("getTableData", this.menuId);
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("添加商品失败", error);
      }
    },
    // 加载下一页
    loadNextPageHandle(){
      this.pageInfo.page = this.pageInfo.page + 1
      this.getTableData()
    },
    // 关闭drawer
    closeDrawerHandle() {
      this.$emit("showOrHideDrawerHandle");
    }
  },
  props: {
    showDrawer: {
      default: false
    }
  },
  computed: {
    title() {
      return "添加商品" 
    },

    isIndeterminate() {
      if (
        this.tableData
          .filter(item => !item.disabled)
          .every(item => item.checked)
      ) {
        return false;
      } else {
        return this.tableData.some(item => item.checked);
      }
    }
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.status = 1
        // this.orgId = this.$route.query.orgId;
        // this.menuId = this.$route.query.menuId;
      }
    }
  }
};
</script>

<style scoped lang="less">
@import '../../../../../../../style/common/elementDrawerWine.less';
@import '../../../../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../../../../style/common/elementFormBtnWine.less';
@import '../../../../../../../style/erp/form.less';
@import '../../../../../../../style/erp/table.less';
</style>
<style scoped lang="less">
@import "./drawerAddPrdCom.less";
</style>

<style>
.el-icon-arrow-right:before {
  color: #606266;
}
</style>