<template>
  <div>
    <el-dialog :title="title" :visible.sync="showDrawer" :close-on-click-modal="false" :size="500">
      <div class="session">
        <!-- 头部筛选项 -->
        <div class="select-top" layout="row" layout-align="start center">
          <div class="item" layout="row" layout-align="start center">
            <div class="label">分类:</div>
            <el-cascader v-model="searchFormData.valueArr" :options="searchFormData.options" size="small"
              clearable></el-cascader>
          </div>
          <div class="item" layout="row" layout-align="start center">
            <el-input v-model="searchFormData.keyword" style="width: 200px" size="small"
              placeholder="请输入商品名称或拼音字母"></el-input>
          </div>
          <div class="item" layout="row" layout-align="start center">
            <el-button type="primary" @click.stop="getTableData">查询</el-button>
            <el-button @click.stop="restSearchData">重置</el-button>
          </div>
        </div>
        <!-- table -->
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="space-between center">
              <div class="th">
                <el-checkbox v-model="checked" :indeterminate="isIndeterminate"
                  @change="changeCheckboxHandle('all')">全选</el-checkbox>
              </div>
              <div class="th">商品名称</div>
              <div class="th">一级分类</div>
              <div class="th">二级分类</div>
            </div>
          </div>
          <div class="tbody">
            <div class="tr" v-for="(item, index) in tableData" :key="index" layout="row"
              layout-align="space-between center">
              <div class="td">
                <el-checkbox v-model="item.checked" @change="changeCheckboxHandle('item')">{{ index + 1 }}</el-checkbox>
              </div>
              <div class="td">{{ item.n }}</div>
              <div class="td">{{ item.on }}</div>
              <div class="td">{{ item.tn }}</div>
            </div>
            <div class="no-data m-t-10" v-if="tableData.length == 0" style="text-align:center">
              <img src="@/assets/img/wu.png" style="width:60px" alt />
              <p class="m-t-2">暂无数据</p>
            </div>
          </div>
        </div>
      </div>
      <!-- 提交按钮 -->
      <span slot="footer" class="dialog-footer">
        <el-button @click.stop="closeDrawerHandle">取消</el-button>
        <el-button type="primary" @click="submitHandle">确定</el-button>
      </span>
    </el-dialog>
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
      tableData: [],
      checked: false
    };
  },
  methods: {
    // 获取表格数据
    async getTableData(init = 2) {
      const params = {
        name: this.searchFormData.keyword, //  string   搜索关键字
        page_num: 1, // int
        page_size: 100000, //  int
        is_init: init == 1 ? 1 : 2, //    int
        one_cate_id: this.searchFormData.valueArr[0] * 1, // int64
        two_cate_id: this.searchFormData.valueArr[1] * 1 // int64
      };

      try {
        const res = await this.$api.BMS.saveWine.reqGetAllWineLine(params);
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
          this.tableData = (res.data.items || []).map(item => ({
            ...item,
            checked: false
          }));
          this.checked = false;
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
      const params = {
        prd_ids: this.tableData
          .filter(item => item.checked)
          .map(item => item.id * 1), //   []int64   待添加商品列表
        wine_cate_id: this.$route.query.menuId * 1 || 0,
      };

      if (params.prd_ids.length <= 0)
        return this.$message.warning("请选择需要添加的商品");

      try {
        const res = await this.$api.BMS.saveWine.reqAddWine(params);
        if (res.code == 1) {
          this.$message.success('添加成功')
          this.closeDrawerHandle();
          this.$emit("getTableData");
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("添加商品失败", error);
      }
    },
    // 关闭drawer
    closeDrawerHandle() {
      this.$emit("showDrawerHandle");
    }
  },
  props: {
    showDrawer: {
      default: false
    },
    status: {
      default: 1 // 添加商品   2：编辑商品
    }
  },
  computed: {
    title() {
      return this.status == 1 ? "添加商品" : "编辑商品";
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
        this.restSearchData()
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "./drawerAddWineCom.less";
</style>

<style lang='less' scoped>
.el-icon-arrow-right:before {
  color: #606266;
}

/deep/.el-dialog {
  float: right;
  margin: 0 !important;
  height: 100vh;
  width: 700px;
}

/deep/.el-dialog__body {
  height: calc(100vh - 130px);
  padding: 0 20px;
  box-sizing: border-box;
  overflow: auto;
}

/deep/.el-dialog__footer {
  text-align: center;
}
</style>