<template>
  <div class="terminal-rules">
    <div style="padding-bottom: 50px">
      <div class="m-l-4 mt-8 fs14">
        <span>开启商品非会员价功能:</span>
        <el-switch v-model="opening"
                   active-text="是"
                   inactive-text="否"
        ></el-switch>
      </div>

      <div class="m-l-4 mt-4 fs14" v-if="this.opening">
        <span>非会员价在商品单价基础上上浮 </span>
        <el-input style="width:150px" v-model="radio" type="text" @input="inputHandle" />
        <span>%</span>
        <p class="red-color mt-2">例: 商品会员价100元, 上浮10%作为非会员价，则非会员价为100* (1+10%) =110元; 有小数则会向上取整，如19.01会取整20</p>
      </div>
      <el-button
          type="primary"
          style="margin: 30px 0 0 200px"
          @click.native="submitHandle">
        保存
      </el-button>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      opening: false,
      radio: 10,
    };
  },
  methods: {
    inputHandle() {
      if (isNaN(this.radio * 1)) {
        this.$message.warning("请输入数字");
        return true;
      }
    },

    async getConfig() {
      try {
        const res = await this.$api.BMS.Prd.get_member_price_cfg()
        if (res.code === 1) {
          if(res.data.percent === 0){
            this.opening = false
          } else {
            this.opening = true
            this.radio = res.data.percent;
          }
          console.log(res)
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("fail", error);
      }
    },

    async submitHandle() {
      if (this.inputHandle()) return;
      const params = {
        percent: this.opening? this.radio * 1: 0
      };

      try {
        const res = await this.$api.BMS.Prd.save_member_price_cfg(params);
        res.code === 1
            ? this.$message.success("保存成功")
            : this.$message.warning(res.msg);
      } catch (error) {
        console.log("保存失败", error);
      }
    }
  },
  mounted() {
    this.getConfig()
  },
  watch: {
  }
};
</script>

<style scoped lang="less">
</style>