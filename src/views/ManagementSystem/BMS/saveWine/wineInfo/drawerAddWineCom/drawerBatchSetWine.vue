<template>
  <div>
    <el-dialog title="批量修改存酒分类" :visible.sync="showDrawer" :close-on-click-modal="false" :size="500">
      <div class="session">
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">存酒分类：</div>
          <div class="value">
            <el-select v-model="wine_cate_id" placeholder="请选择">
              <el-option v-for="item in tableData" :key="item.id" :label="item.n" :value="item.id">
              </el-option>
            </el-select>
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
      wine_cate_id: "",
      searchFormData: {
        valueArr: [0, 0],
        options: [],
      },
      tableData: []
    };
  },
  methods: {
    async getTableData() {
      try {
        const res = await this.$api.BMS.saveWine.reqGetWineCateList({});
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map(item => ({
            ...item,
          }));
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("存酒列表数据获取失败", error);
      }
    },
    restSearchData() {
      this.wine_cate_id = "";
    },

    async submitHandle() {
      const params = {
        wine_cate_id: this.wine_cate_id, //    []int64    待修改商品Id列表
        prd_ids: this.ids
      };
      try {
        const res = await this.$api.BMS.saveWine.reqBatchSetPrdWineCate(params);
        if (res.code == 1) {
          this.$message.success('存酒分类修改成功')
          this.closeDrawerHandle();
          this.$emit("getTableData");
        }
      } catch (error) {
        console.log('批量存酒分类修改失败')
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
    ids: {
      default: []
    },
  },
  created() {
    this.getTableData();
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.restSearchData();
      }
    }
  }
};
</script>
  
<style lang='less' scoped>
.coll {
  margin-top: 30px;
  font-size: 14px;

  .label {
    width: 120px;
    text-align: right;
  }

  .value {
    padding-left: 6px;
    box-sizing: border-box;
    width: calc(100% - 120px);
  }
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

/deep/.el-dialog__footer {
  text-align: center;
}
</style>