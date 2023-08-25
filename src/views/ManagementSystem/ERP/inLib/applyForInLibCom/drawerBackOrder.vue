<template>
  <div>
    <!-- 驳回 -->
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
              <span>物料名字：</span>
            </div>
            <div class="value">{{currentInfo.n}}</div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span>一级分类：</span>
            </div>
            <div class="value">{{currentInfo.moc}}</div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span>二级分类：</span>
            </div>
            <div class="value">{{currentInfo.mtc}}</div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span>出库单位：</span>
            </div>
            <div class="value">{{currentInfo.un}}</div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span>出库数量：</span>
            </div>
            <div class="value">{{currentInfo.c}}</div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span>异议锁定数量：</span>
            </div>
            <div class="value">{{currentInfo.lyc}}</div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>异议数量：</span>
            </div>
            <div class="value">
              <el-input v-model="applyForCount" placeholder="请输出异议数量" size="mini"/>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>备注：</span>
            </div>
            <div class="value">
              <el-input 
                type="textarea" 
                v-model="applyForRemark" 
                :rows="3"
                placeholder="请输入备注" />
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
      if(this.applyForCount > this.currentInfo.lyc) return this.$message.warning('异议数量不可超过异议锁定数量')
      if(this.applyForRemark.length <= 0) return this.$message.warning('请填写异议原因')
      const params = {
        id: this.currentInfo.id * 1,
        cnt: this.applyForCount * 1,
        remark: this.applyForRemark || ''
      }
      try {
        const res = await this.$api.ERP.soutdd_yy.requestd_yyin_back(params)
        if (res.code == 1) {
          this.$message.success('操作成功')
          this.onCancelDrawer()
          this.$emit('emitHandle')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('驳回失败', error);
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
      return '驳回'
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
  border-radius: 10px;
  .coll {
    box-sizing: border-box;
    margin-top: 20px;
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