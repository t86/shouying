<template>
  <div class="org">
    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">门店名称：</div>
      <div class="value">{{detailInfo.org_name}}</div>
    </div>

    <div style="display: block; text-align: center">
      <el-button size="big" class="button" type="primary" @click.stop="restore">恢复营业日</el-button>
      <p style="color: red" class="warning">连续点击七次可操作该功能</p>
    </div>

    <el-dialog title="恢复营业日" :visible.sync="dialogVisible" :show-close="false" :close-on-click-modal="false">
      <span style="font-size: 18px">是否确定恢复营业日</span>
      <span slot="footer" class="dialog-footer">
        <el-button @click="dialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="doRestore">确 定</el-button>
      </span>
    </el-dialog>
  </div>

</template>
<script>
export default {
  data() {
    return {
      clickCount: 0,
      dialogVisible: false,
      detailInfo:{}
    }
  },
  methods: {
    async doRestore() {
      try {
        const res = await this.$api.BMS.Org.reqRestore();
        if (res.code === 1) {
          this.detailInfo = res.data;
          this.$message.success("恢复营业日成功");
          this.dialogVisible = false
        } else {
          this.$message.warning(res.msg);
          this.dialogVisible = false
        }
      } catch (error) {
        this.dialogVisible = false
        console.log("restore fail", error);
      } finally {
        this.dialogVisible = false
      }
    },
    async getPageData() {
      try {
        const res = await this.$api.BMS.Org.reqGetDetailInfo();
        if (res.code === 1) {
          this.detailInfo = res.data;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("门店信息获取失败", error);
      }
    },
    async restore() {
      if (this.clickCount > 6 ) {
        console.log('ok')
        this.clickCount = 0
        this.dialogVisible = true
      } else {
        console.log(this.clickCount)
        this.clickCount ++
      }
    }
  },
  mounted() {
    this.getPageData()
  }
};
</script>
<style scoped lang="less">
.org {
  padding: 20px 30px;
  max-height: calc(100vh - 100px);
  overflow: auto;
  box-sizing: border-box;
  .select {
    width: 196px;
  }

  .address {
    width: 136px;
  }

  .input {
    width: 424px;
    color: #40404e;
  }

  .textarea,
  textarea {
    margin-top: 6px;
    width: 426px;
    background-color: #1a1a20 !important;
    color: #40404e !important;
  }

  .button {
    //margin-left: 400px;
    margin-top: 40px;
    text-align: center;
  }
  .warning {
    text-align: center;
    color: red;
    margin-top: 20px;
  }
}
</style>
