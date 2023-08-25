<template>
  <div>
    <!-- 部分入库 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      append-to-body
      size="500px"
    >
      <div class="session p-5">
        <!-- 头部信息 -->
        <div class="form fs14">
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span>原入库数量：</span>
            </div>
            <div class="value">{{currentInfo.c}}</div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>异议数量：</span>
            </div>
            <div class="value">
              <el-input v-model="applyForCount" placeholder="请输出异议数量" size="mini" />
            </div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>异议原因：</span>
            </div>
            <div class="value">
              <el-input
                type="textarea"
                v-model="applyForRemark"
                :rows="3"
                placeholder="请输入异议原因(不超过140字)"
                size="mini"
                :maxLength="140"
              />
            </div>
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
      applyForCount: '',
      applyForRemark: ''
    };
  },
  methods: {
    // 确认
    async onSubmit (){
      if(this.applyForCount <= 0) return this.$message.warning('请填写异议数量')
      if(this.applyForRemark.length <= 0) return this.$message.warning('请填写异议原因')
      const params = {
        id: this.currentInfo.id * 1,
        yy_cnt: this.applyForCount * 1,
        remark: this.applyForRemark || ''
      }
      try {
        const res = await this.$api.ERP.sind.requestsindsh(params)
        if (res.code == 1) {
          this.$message.success('操作成功')
          this.onCancelDrawer()
          this.$emit('getAllData')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('异议订单申请失败', error);
      }
    },
    onCancelDrawer(){
      this.show = false
    },

  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    currentInfo:{
      default: () => ({})
    }
  },
  computed: {
    title(){
      return '申请售后'
    },
    show: {
      get(){
        return this.value
      },

      set(val) {
        this.$emit('input', val)
      }
    }
  },
};
</script>

<style scoped lang="less">
@import '../../../../../style/common/elementDrawerWine.less';
@import '../../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../../style/common/elementFormBtnWine.less';
@import '../../../../../style/erp/form.less';
</style>

<style lang="less" scoped>
.form{
  padding: 20px;
  border-radius: 10px;
  .coll {
    box-sizing: border-box;
    .item {
      width: 50%;
      .label {
        width: 120px;
        text-align: right;
      }
    }
  }
}
</style>