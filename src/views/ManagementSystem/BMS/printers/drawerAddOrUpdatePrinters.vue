<template>
  <div>
    <!-- 添加或修改卡台抵消组 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 erp-lib-detail fs14">
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red-color">*</span>
            <span class="fs14">打印机名称：</span>
          </div>
          <div class="value">
            <el-input v-model="name" placeholder="请输入低消组名称" @input="validator" />
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red-color">*</span>
            <span class="fs14">IP地址：</span>
          </div>
          <div class="value">
            <el-input v-model="ip" placeholder="请输入打印机ID地址" />
          </div>
        </div>
        <p class="red-color fs12 m-t-3 m-l-10 p-l-10">IP地址格式为：a.b.c.d;其中a,b,c,d均为0-254的数字</p>
        
      </div>
      
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      name: "",
      ip: ''
    };
  },
  methods: {
    // form表单检测
    validator() {
      if (this.name == "") {
        this.$message.warning("请输入打印机名称");
      } else if (this.$overall.character(this.name) > 20) {
        this.$message.warning("输入文字长度超过10");
      }
    },

    // 获取修改前的数据
    async getData(){
      const params = {
        id: this.currentInfo.id
      }
      try {
        const res = await this.$api.BMS.printer.requestprinterget(params)
        if(res.code == 1) {
          this.name = res.data.name
          this.ip = res.data.ip_addr
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取修改前数据失败', error);
      }
    },

    async onSubmit() {
      const params = {
        name: this.name,
        ip_addr: this.ip,
        ...this.type == 2 && {id: this.currentInfo.id * 1}
      };
      try {
        const api = this.type == 1 ? "requestprinternew" : "requestprintersave";
        const res = await this.$api.BMS.printer[api](params);
        if (res.code == 1) {
          this.onCancelDrawer();
          this.$message.success('操作成功')
          this.$emit("getTableData");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("提交失败", error);
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
      default: 1 // 1 新增  2 编辑
    },
    currentInfo: {
      default: () => ({})
    }
  },
  computed: {
    title() {
      return this.type == 1 ? "新增打印机" : "编辑打印机";
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
      async handler(newVal) {
        if (newVal) {
          if(this.type == 2) {
            await this.getData()
          } else {
            this.name = ''
            this.ip = ''
          }
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
@import "../../../../style/erp/form.less";
@import "../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
@color: #666;
.coll {
  .label {
    width: 130px;
    text-align: right;
  }
}
</style>