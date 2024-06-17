<template>
  <div>
    <!-- 新增或修改erp一级分类 -->
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
            <span>一级分类名称：</span>
          </div>
          <div class="value">
            <el-input
              v-model="oneCateName"
              size="small"
              @input="validator()"
              placeholder="请输入一级分类名称"
            ></el-input>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>首选出品库：</span>
          </div>
          <div class="value">
            <el-select v-model="outLibVal" size="small" placeholder="请选择出品库" class="controlling">
              <el-option 
                v-for="item in outLibOption" 
                :key="item.id" 
                :label="item.n"
                :value="item.id">
              </el-option>
            </el-select>
          </div>
        </div>
<!--        <div class="coll" layout="row" layout-align="start center">-->
<!--          <div class="label">-->
<!--            <span class="red">*</span>-->
<!--            <span>微信小程序可见：</span>-->
<!--          </div>-->
<!--          <div class="value">-->
<!--            <el-radio v-model="isShowRadio" :label="1">可见</el-radio>-->
<!--            <el-radio v-model="isShowRadio" :label="2">不可见</el-radio>-->
<!--          </div>-->
<!--        </div>-->
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
      oneCateName: "",
      outLibVal: '',
      outLibOption: [],
      // isShowRadio: 1
    };
  },
  methods: {
    // 获取修改前数据
    async getDetail(){
      const params = {
        id: this.currentInfo.id * 1
      }
      try {
        const res = await this.$api.BMS.ocate.requestocateget(params)
        if(res.code == 1) {
          this.outLibOption = res.data.mklibs || []
          this.oneCateName = res.data.prd_one_cate.name
          this.outLibVal = res.data.prd_one_cate.first_mklib_id * 1
          // this.isShowRadio = res.data.prd_one_cate.show_in_mp * 1
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    validator(){
      if (this.oneCateName == '') {
        this.$message.warning('请输入分类名称')
      } else if (this.$overall.character(this.oneCateName) > 10) {
        this.$message.warning('输入文字长度超过5')
      }
    },

    async getOutLibOption() {
      const params = {
        id: 0
      }
      try {
        const res = await this.$api.BMS.ocate.requestocateget(params)
        if(res.code == 1) {
          this.outLibOption = res.data.mklibs || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    async onSubmit() {
      if (this.oneCateName.length <= 0)
        return this.$message.warning("请输入一级分类名称");
      if (!this.outLibVal)
        return this.$message.warning("请选择首选出品库");
      const params = {
        name: this.oneCateName || '',
        first_mklib_id: this.outLibVal * 1,
        // show_in_mp: this.isShowRadio * 1,
        ...this.type == 2 && {id : this.currentInfo.id}
      };
      try {
        const api = this.type == 1 ? 'requestocatenew' : 'requestocatesave'
        const res = await this.$api.BMS.ocate[api](params)
        if(res.code == 1) {
          this.onCancelDrawer()
          this.$emit('getTableData', true)
          this.$emit('getMenuList')
          this.$message.success('操作成功')
        } else if (res.code == 6) {
          this.onCancelDrawer()
          this.$emit('getTableData', true)
          this.$emit('getMenuList')
          this.$message.warning("创建成功，状态无效，" + res.msg)
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('新增失败', error);
      }
    },
    onCancelDrawer() {
      this.show = false;
    },

    resetHandle() {
      this.oneCateName = ''
      this.outLibVal = ''
      // this.isShowRadio = 1
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
      return this.type == 1 ? "新增一级分类" : "编辑一级分类";
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
            this.resetHandle()
            this.getOutLibOption()
          } else {
            this.getDetail()
          }
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../style/erp/form.less";
</style>

<style lang="less" scoped>
.coll {
  margin-bottom: 20px;
  .label {
    width: 150px;
  }
}
</style>