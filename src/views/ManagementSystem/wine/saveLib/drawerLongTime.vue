<template>
  <div>
    <!-- 延期 -->
    <el-drawer
      title="延期"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="500px"
    >
      <div class="session p-5 fs14">
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">延期时长:</div>
          <div class="value m-l-4">
            <el-input v-model="dayVal" style="width:200px" class="m-r-2" size="small"></el-input>天
          </div>
        </div>
        <div class="red tips">例如：剩余有效期为10天，延期5天后，变为15天</div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_wine from "@/api/wine";
export default {
  data() {
    return {
      dayVal: ""
    };
  },
  methods: {
    async onSubmit() {
      const params = {
        invt_ids: this.ids, //    []int64    库存Id列表
        delay_day: this.dayVal * 1   //  int   延期天数
      };

      try {
        const res = await api_wine.reqAddLongTime(params);
        if(res.code == 1) {
          this.$message.success('延期成功')
          this.$emit('getTableData')
          this.onCancelDrawer()
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("延期失败", error);
      }
    },
    onCancelDrawer() {
      this.show = false;
    }
  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    ids: {
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
    }
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.dayVal = "";
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../style/common/elementDrawerWine.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/elementFormBtnWine.less";
</style>

<style lang="less" scoped>
.red{
  color: red;
  margin: 10px 0 0 60px;
}
</style>