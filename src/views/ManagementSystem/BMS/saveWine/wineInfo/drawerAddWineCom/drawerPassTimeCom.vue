<template>
  <div>
    <el-dialog
      title="批量设置过期时间"
      :visible.sync="showDrawer"
      :close-on-click-modal="false"
      :size="500"
    >
      <div class="session">
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">整瓶有效期：</div>
          <div class="value">
            <el-input
              v-model="day1Val"
              class="m-r-2"
              size="small"
              style="width: 180px"
              placeholder="请输入有效期天数"
            ></el-input>天
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">散瓶有效期：</div>
          <div class="value">
            <el-input
              v-model="day2Val"
              class="m-r-2"
              size="small"
              style="width: 180px"
              placeholder="请输入有效期天数"
            ></el-input>天
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
      day1Val: "",
      day2Val: ""
    };
  },
  methods: {
    restSearchData() {
      this.day1Val = "";
      this.day2Val = "";
    },

    async submitHandle() {
      const params = {
        prd_ids: this.ids, //    []int64    待修改商品Id列表
        full_expired_day: this.day1Val * 1,   // int  整瓶过期天数
        loose_expired_day: this.day2Val * 1   // int  散瓶过期天数
      };

      try {
        const res = await this.$api.BMS.saveWine.reqSetPassTime(params);
        if(res.code == 1){
          this.$message.success('设置成功')
          this.closeDrawerHandle();
          this.$emit("getTableData");
        }
      } catch (error) {
        console.log('批量设置过期时间失败')
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
    status: {
      default: 1 // 添加商品   2：编辑商品
    }
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