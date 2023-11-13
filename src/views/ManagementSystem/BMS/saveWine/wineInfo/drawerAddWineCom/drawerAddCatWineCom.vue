<template>
  <div>
    <el-dialog :title="title" :visible.sync="showDrawer" :close-on-click-modal="false" :size="500">
      <div class="session">
        <!-- 头部筛选项 -->
        <div class="select-top" layout="Column" layout-align="start center">
          <div class="item" layout="row" layout-align="start center">
            <div class="label">存酒分类名称：</div>
            <el-input
              v-model="searchFormData.keyword"
              style="width: 250px"
              size="small"
              placeholder="请输入存酒分类名称(1-10个字)"
            ></el-input>
          </div>
          <div class="item" layout="row" layout-align="start center">
            <div class="label">整瓶有效期：</div>
            <el-input
              v-model="searchFormData.keyword"
              style="width: 250px"
              size="small"
              placeholder="请输入数字"
            ></el-input>
          </div>
          <div class="item" layout="row" layout-align="start center">
            <div class="label">散瓶有效期：</div>
            <el-input
              v-model="searchFormData.keyword"
              style="width: 250px"
              size="small"
              placeholder="请输入数字"
            ></el-input>
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
          .map(item => item.id * 1) //   []int64   待添加商品列表
      };

      if (params.prd_ids.length <= 0)
        return this.$message.warning("请选择需要添加的商品");

      try {
        const res =  await this.$api.BMS.saveWine.reqAddWine(params);
        if(res.code == 1) {
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
      default: 1 // 新增存酒分类   编辑存酒分类
    }
  },
  computed: {
    title() {
      return this.status == 1 ? "新增存酒分类" : "编辑存酒分类";
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
.label {
  width: 120px;
}
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

/deep/.el-dialog__footer{
  text-align: center;
}
</style>