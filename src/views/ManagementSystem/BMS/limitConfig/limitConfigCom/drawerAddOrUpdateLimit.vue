<template>
  <div>
    <!-- 新增或编辑限额限量 -->
   <el-drawer
     :title='title'
     :visible.sync='show'
     :before-close='onCancelDrawer'
     direction='rtl'
     size='720px'
   >
    <div class='session p-5 fs14'>
      <div class="coll" layout="row" layout-align="start center">
        <div class="label">
          <span class="red-color">*</span>
          <span class="fs14">名称：</span>
        </div>
        <div class="value">
          <el-input v-model="name" style="width:400px" placeholder="请输入名称" size="small"></el-input>
        </div>
      </div>

      <div class="coll" layout="row" layout-align="start center">
        <div class="label">
          <span class="fs14">日限数量：</span>
        </div>
        <div class="value" layout="row" layout-align="start center">
          <el-radio v-model="dayLimitCountVal" :label="1">不限</el-radio>
          <el-radio v-model="dayLimitCountVal" :label="2">限制</el-radio>
          <el-input v-model="dayLimitCount" style="width:100px" :disabled="dayLimitCountVal == 1"/>
          <span class="m-l-2">个</span>
        </div>
      </div>

      <div class="coll" layout="row" layout-align="start center">
        <div class="label">
          <span class="fs14">日限金额：</span>
        </div>
        <div class="value" layout="row" layout-align="start center">
          <el-radio v-model="dayLimitAmtVal" :label="1">不限</el-radio>
          <el-radio v-model="dayLimitAmtVal" :label="2">限制</el-radio>
          <el-input v-model="dayLimitAmt" style="width:100px" :disabled="dayLimitAmtVal == 1"/>
          <span class="m-l-2">元</span>
        </div>
      </div>

      <div class="coll" layout="row" layout-align="start center">
        <div class="label">
          <span class="fs14">月限数量：</span>
        </div>
        <div class="value" layout="row" layout-align="start center">
          <el-radio v-model="monthLimitCountVal" :label="1">不限</el-radio>
          <el-radio v-model="monthLimitCountVal" :label="2">限制</el-radio>
          <el-input v-model="monthLimitCount" style="width:100px" :disabled="monthLimitCountVal == 1"/>
          <span class="m-l-2">个</span>
        </div>
      </div>

      <div class="coll border-bottom p-b-3" layout="row" layout-align="start center">
        <div class="label">
          <span class="fs14">月限金额：</span>
        </div>
        <div class="value" layout="row" layout-align="start center">
          <el-radio v-model="monthLimitAmtVal" :label="1">不限</el-radio>
          <el-radio v-model="monthLimitAmtVal" :label="2">限制</el-radio>
          <el-input v-model="monthLimitAmt" style="width:100px" :disabled="monthLimitAmtVal == 1"/>
          <span class="m-l-2">元</span>
        </div>
      </div>

      <div class="coll p-l-10">
        <div class="label" style="width: 100%;text-align:left">
          <span class="red-color">*</span>
          <span class="fs14">商品组(至少选择一个商品组)</span>
        </div>
        <div class="value m-l-10 m-t-3">
          <el-tree
            node-key="id"
            :data="treeData"
            show-checkbox
            :props="defaultProps"
            @check="clickTreeCheckBox"
            :default-checked-keys="selectList"
          ></el-tree>
        </div>
      </div>
    </div>
    <div class='form-btn' layout='row' layout-align='center center'>
      <el-button type='info' @click='onCancelDrawer'>关闭</el-button>
      <el-button type='primary' @click='onSubmit'>确定</el-button>
    </div>
    </el-drawer>
  </div>
</template>
 
<script>
  export default {
    data() {
      return {
        // 修改前数据是否加载完成
        isLoaded: false,

        name: '',
        dayLimitCountVal: 1,
        dayLimitCount: '',
        dayLimitAmtVal: 1,
        dayLimitAmt: '',
        monthLimitCountVal: 1,
        monthLimitCount: '',
        monthLimitAmtVal: 1,
        monthLimitAmt: '',
        
        treeData: [], //选择二级列表全部内容
        selectList: [], // 默认选中节点
        checkedTwoCate: [], // 选中的二级分类
        defaultProps: {
          children: 'ts',
          label: 'n'
        },
      }
    },
    methods: {
      async getDetail(){
        const params = {
          id: this.currentInfo.id * 1
        }
        try {
          const res = await this.$api.BMS.freelmt.requestfreelmtget(params)
          if(res.code == 1) {
            this.treeData = [{
              n: '以下全部',
              ts: res.data.prd_grps || []
            }]
            for (const iterator of res.data.prd_grps) {
              if (iterator.s == 1) {
                this.selectList.push(iterator.id)
                this.checkedTwoCate.push(iterator.id)
              }
            }

            this.name = res.data.name
            this.dayLimitCountVal = res.data.day_cnt_limit == -1 ? 1 : 2
            this.dayLimitCount = res.data.day_cnt_limit == -1 ? '' : res.data.day_cnt_limit
            this.dayLimitAmtVal = res.data.day_amt_limit == -1 ? 1 : 2
            this.dayLimitAmt = res.data.day_amt_limit == -1 ? '' : res.data.day_amt_limit
            this.monthLimitCountVal = res.data.month_cnt_limit == -1 ? 1 : 2
            this.monthLimitCount = res.data.month_cnt_limit == -1 ? '' : res.data.month_cnt_limit
            this.monthLimitAmtVal = res.data.month_amt_limit == -1 ? 1 : 2
            this.monthLimitAmt = res.data.month_amt_limit == -1 ? '' : res.data.month_amt_limit

          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('数据请求失败', error);
        }
      },
      resetHandle() {
        this.name = ''
        this.dayLimitCountVal = 1
        this.dayLimitCount = ''
        this.dayLimitAmtVal = 1
        this.dayLimitAmt = ''
        this.monthLimitCountVal = 1
        this.monthLimitCount = ''
        this.monthLimitAmtVal = 1
        this.monthLimitAmt = ''
        this.treeData = []
        this.selectList = []
        this.checkedTwoCate = []
      },

      async getTreeData(){
        const params = {
          id: 0
        }
        try {
          const res = await this.$api.BMS.freelmt.requestfreelmtget(params)
          if(res.code == 1) {
            this.treeData = [{
              n: '以下全部',
              ts: res.data.prd_grps || [],
            }]
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('数据请求失败', error);
        }
      },

      // 选中的二级分类
      clickTreeCheckBox(nodeObj, SelectedObj) {
        const checkedTwoCate = [];
        for (const item of SelectedObj.checkedKeys) {
          if (item != undefined) {
            checkedTwoCate.push(item);
          }
        }
        this.checkedTwoCate = [...checkedTwoCate];
      },

      async onSubmit(){
        if(this.name == '') return this.$message.warning('请填写名称')
        const params = {
          name: this.name || '', //  string   低消组名称
          day_cnt_limit: this.dayLimitCountVal == 1 ? -1 : this.dayLimitCount * 1, // int   日限量, -1 代表无限制
          day_amt_limit: this.dayLimitAmtVal == 1 ? -1 : this.dayLimitAmt * 1, // int   日限额, -1 代表无限制
          month_cnt_limit: this.monthLimitCountVal == 1 ? -1 : this.monthLimitCount * 1, // int   月限量, -1 代表无限制
          month_amt_limit: this.monthLimitAmtVal == 1 ? -1 : this.monthLimitAmt * 1, // int   月限额, -1 代表无限制
          prd_grps: this.checkedTwoCate, //   []int64   选中的低消组id列表
          ...this.type == 2 && {id: this.currentInfo.id},
        }
        try {
          const api = this.type == 1 ? 'requestfreelmtnew' : 'requestfreelmtsave'
          const res = await this.$api.BMS.freelmt[api](params)
          if(res.code == 1) {
            this.$message.success(this.type == 1 ? '创建成功' : '编辑成功')
            this.onCancelDrawer()
            this.$emit('getTableData')
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('数据请求失败', error);
        }
      },
      onCancelDrawer() {
        this.show = false
      }
    },
    created() {
 
    },
    mounted() {
 
    },
    props: {
      value: {
        default: false
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
        return this.type == 1 ? '新增限额限量' : '编辑限额限量'
      },
      show: {
        get() {
          return this.value
        },
        set(val) {
          this.$emit('input', val)
        }
      }
    },
    watch: {
      value: {
        async handler(newVal) {
          if (newVal) {
            this.isLoaded = false
            this.resetHandle()
            if(this.type == 1) {
              await this.getTreeData()
            } else {
              await this.getDetail()
            }
            this.$nextTick(() => {
              this.isLoaded = true
            })
          }
        },
        immediate: true
     },
     
    dayLimitCountVal(){
      if(this.isLoaded) this.dayLimitCount = ''
    },
    dayLimitAmtVal(){
      if(this.isLoaded) this.dayLimitAmt = ''
    },
    monthLimitCountVal(){
      if(this.isLoaded) this.monthLimitCount = ''
    },
    monthLimitAmtVal(){
      if(this.isLoaded) this.monthLimitAmt = ''
    },
   }
 }
 
</script>

<style scoped lang='less'>
@import '../../../../../style/common/elementDrawerWine.less';
@import '../../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../../style/common/elementFormBtnWine.less';
@import '../../../../../style/erp/form.less';
@import '../../../../../style/erp/table.less';
</style>
<style scoped lang='less'>
/deep/.coll .el-input__inner, .coll .el-textarea__inner {
  width: 100%!important;
}

.coll {
  &.border-bottom {
    border-bottom: 1px dashed #666;
  }
}
</style>