<template>
  <div>
    <!-- 新增或修改区域 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 fs14">
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>岗位名称：</span>
          </div>
          <div class="value">
            <el-input
              v-model="stationName"
              size="mini"
              placeholder="请输入岗位名称"
              @input="validator"
            ></el-input>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      stationName: "",
    };
  },
  methods: {
    validator() {
      if (this.stationName == "") {
        this.$message.warning("请输入岗位名称")
        return false
      } else if (this.$overall.character(this.stationName) > 20) {
        this.$message.warning("输入文字长度超过10")
        return false
      }
      return true
    },

    async onSubmit() {
      if(!this.validator()) return
      const params = {
        ...this.type == 1 && {name: this.stationName || ''},
        ...this.type == 2 && {n: this.stationName || ''},
        ...this.type == 2 && {id : this.currentInfo.id},
      };
      try {
        const api = this.type == 1 ? 'requestStationNew' : 'requestStationSave'
        const res = await this.$api.BMS.station[api](params)
        if(res.code == 1) {
          this.onCancelDrawer()
          this.$emit('getTableData')
          this.$message.success('操作成功')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('新增失败', error);
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
    type: {
      default: 1
    },
    currentInfo: {
      default: () => ({})
    }
  },
  computed: {
    title() {
      return this.type == 1 ? "新增岗位" : "编辑岗位";
    },

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
          if (this.type == 1) {
            this.stationName = "";
          } else {
            this.stationName = this.currentInfo.n || ''
          }
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../style/common/elementDrawerWine.less";
@import "../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../style/erp/form.less";
</style>