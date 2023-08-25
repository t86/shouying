<template>
  <div>
    <!-- 添加或修改出品库 -->
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
            <span class="fs14">出品库名称：</span>
          </div>
          <div class="value">
            <el-input v-model="name" placeholder="请输入出品库名称" @input="validator" />
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red-color">*</span>
            <span class="fs14">存货仓库：</span>
          </div>
          <div class="value">
            <el-select v-model="storeLibVal" placeholder="请选择存货仓库" size="small" clearable>
              <el-option v-for="item in storeLibOption" :key="item.id" :label="item.n" :value="item.id"></el-option>
            </el-select>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red-color">*</span>
            <span class="fs14">出品打印机：</span>
          </div>
          <div class="value">
            <el-select v-model="outLibVal" placeholder="请选择打印机" size="small" clearable>
              <el-option v-for="item in outLibOption" :key="item.id" :label="item.n" :value="item.id"></el-option>
            </el-select>
          </div>
        </div>
        <p class="red-color fs12 m-t-2" style="margin-left:160px">用于打印出品单</p>

        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="fs14">出品打印份数：</span>
          </div>
          <div class="value">
            <el-input-number v-model="printCount" :max="3" :min="0" :disabled="!outLibVal" />
          </div>
        </div>

        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="fs14">单品是否分页打印：</span>
          </div>
          <div class="value">
            <el-radio v-model="isNextPageVal" :label="1">是</el-radio>
            <el-radio v-model="isNextPageVal" :label="2">否</el-radio>
            <span class="primary-link fs14 cursor" @click="showPreviewDrawer = true">查看预览</span>
          </div>
        </div>

        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="fs14">传菜打印机：</span>
          </div>
          <div class="value">
            <el-select v-model="connectLibVal" placeholder="请选择打印机" size="small" clearable >
              <el-option v-for="item in connectLibOption" :key="item.id" :label="item.n" :value="item.id"></el-option>
            </el-select>
          </div>
        </div>
        <p class="red-color fs12 m-t-2" style="margin-left:160px">用于打印传菜单，方便传菜人员核单</p>

        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="fs14">传菜打印份数：</span>
          </div>
          <div class="value">
            <el-input-number v-model="connectPrintCount"  :max="3" :min="0" :disabled="!connectLibVal" />
          </div>
        </div>
        <p class="red-color fs12 m-t-2" style="margin-left:160px">如没有选择选择打印机则不能改份数，打印份数要在[1,3]范围内</p>
      </div>
      <drawerPreview v-model="showPreviewDrawer" />
      
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
      storeLibVal: '',  // 存货仓库名称
      storeLibOption: [],  
      outLibVal: '',  // 出品打印机名称
      outLibOption: [],
      printCount: 1,
      isNextPageVal: 1,
      connectLibVal: '',  // 传菜打印机名称
      connectLibOption: [],
      connectPrintCount: 1,
      
      showPreviewDrawer: false,  // 查看预览
    };
  },
  methods: {
    // form表单检测
    validator() {
      if (this.name == "") {
        this.$message.warning("请输入出品库名称");
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
        const res = await this.$api.BMS.mklib.requestmklibget(params)
        if(res.code == 1) {
          this.name = res.data.mklib.name || ''
          this.storeLibVal = (res.data.mklib.store_id * 1) || ''
          this.storeLibOption = res.data.stores || []
          this.outLibVal = (res.data.mklib.cp_prt_id * 1) || ''
          this.outLibOption = res.data.prts || []
          this.printCount = res.data.mklib.cp_prt_cnt * 1
          this.isNextPageVal = res.data.mklib.cp_prt_split * 1
          this.connectLibVal = (res.data.mklib.cc_prt_id * 1) || ''
          this.connectLibOption = res.data.prts || []
          this.connectPrintCount = res.data.mklib.cc_prt_cnt * 1
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取修改前数据失败', error);
      }
    },

    async getOptionsHandle(){
      const params = {
        id: 0
      }
      try {
        const res = await this.$api.BMS.mklib.requestmklibget(params)
        console.log(res);
        if(res.code == 1) {
          this.storeLibOption = res.data.stores || []
          this.outLibOption = res.data.prts || []
          this.connectLibOption = res.data.prts || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取options请求失败', error);
      }
    },

    resetHandle(){
      this.name = ""
      this.storeLibVal = ''
      this.storeLibOption = []
      this.outLibVal = ''
      this.outLibOption = []
      this.printCount = 1
      this.isNextPageVal = 1
      this.showPreviewDrawer = false 
      this.connectLibVal = ''
      this.connectLibOption = []
      this.connectPrintCount = 1
    },

    async onSubmit() {
      const params = {
        name: this.name, //  string   出品库名称
        cp_prt_id: this.outLibVal * 1, //  int64   出品打印机Id
        cp_prt_cnt: this.printCount * 1, // int     出品打印次数
        cp_prt_split: this.isNextPageVal * 1, // int    单品是否分页打印  1 是  2 否
        cc_prt_id: this.connectLibVal * 1, //  int64    传菜打印机Id
        cc_prt_cnt: this.connectPrintCount * 1, // int      传菜打印次数
        store_id: this.storeLibVal * 1, //   int64    存货仓库Id
        ...this.type == 2 && {id: this.currentInfo.id * 1}  // int64  出品库id
      };
      if(!params.name) return this.$message.warning('请输入出品库名称')
      if(!params.store_id) return this.$message.warning('请选择存货仓库')
      if(!params.cp_prt_id) return this.$message.warning('请选择出品打印机')
      try {
        const api = this.type == 1 ? "requestmklibnew" : "requestmklibsave";
        const res = await this.$api.BMS.mklib[api](params);
        if (res.code == 1) {
          this.onCancelDrawer();
          this.$message.success('操作成功')
          this.$emit("getTableData");
        } else if (res.code == 6) {
          this.onCancelDrawer();
          this.$emit("getTableData");
          this.$message.warning("创建成功，状态无效，" + res.msg)
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
      return this.type == 1 ? "新增出品库" : "编辑出品库";
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
  components: {
    drawerPreview: () => import('./drawerPreview.vue')
  },
  watch: {
    value: {
      async handler(newVal) {
        if (newVal) {
          if(this.type == 2) {
            await this.getData()
          } else {
            this.resetHandle()
            this.getOptionsHandle()
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
  margin-top: 20px;
  .label {
    width: 150px;
    text-align: right;
  }
}

/deep/.el-input-number__decrease{
  height: 32px;
  transform: translateY(2px);
  .el-icon-minus{
    transform: translateY(-2px);
  }
}

/deep/.el-input-number__increase{
  height: 32px;
  transform: translate(30px, 2px);
  .el-icon-plus{
    transform: translateY(-2px);
  }
}
</style>