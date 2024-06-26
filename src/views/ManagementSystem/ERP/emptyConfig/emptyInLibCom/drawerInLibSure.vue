<template>
  <div>
    <!-- 确认入库订单选择 -->
    <el-drawer
      title="确认入库"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="1100px"
    >
      <div class="session p-5 in-lib-sure">
        <div class="top" layout="row" layout-align="start center">
          <span>入库单生成时间：</span>
          <span class="m-r-6">{{currentInfo.c}}</span>
          <span>订单号：</span>
          <span>{{currentInfo.id}}</span>
        </div>

        <!-- 筛选 -->
        <div class="search m-t-3 m-b-3" layout="row" layout-align="start center">
          <span>服务员：</span>
          <el-input size="small" v-model="empKeyword" style="width:200px" placeholder="请输入姓名或工号"></el-input>
          <el-input size="small" v-model="prdKeyword" style="width:200px;margin: 0 10px" placeholder="请输入商品名称"></el-input>
          <el-button type="primary" size="small" @click="getTableData">查询</el-button>
          <el-button type="primary" size="small" @click="resetHandle">重置</el-button>
        </div>

        <!-- 表格 -->
        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">服务员</div>
                <div class="th">空瓶名称</div>
                <div class="th">应入库数量</div>
                <div class="th">实际出库数量</div>
                <div class="th w60">
                  <span>备注</span>
                  <span class="red">(当时及入库数量与应入库数量不相等时，尽量输入备注)</span>
                </div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="item in tableData" :key="item.id">
                <div class="td">{{item.w}}</div>
                <div class="td">{{item.m}}</div>
                <div class="td">{{item.c}}</div>
                <div class="td">
                  <el-input size="small" style="width:100px" v-model="item.count" :maxLength="30" placeholder="请输入实际出库数量" @input="inputCountHandle(item)"></el-input>
                </div>
                <div class="td w60">
                  <el-input size="small" style="width:200px" v-model="item.remark" :maxLength="30" placeholder="请输入备注，不超过30字"></el-input>
                </div>
              </div>
              <div class="no-data" v-if="tableData.length==0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确认入库</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      empKeyword: '',
      prdKeyword: '',
      tableData: []
    };
  },
  methods: {
    async getTableData(){
      const params = {
        id: this.currentInfo.id * 1 // int64  待入库订单Id
      }
      try {
        const res = await this.$api.ERP.emptyLib.getNeedInLibOrderDetail(params);
        if (res.code == 1) {
          this.tableData = (res.data.records || []).filter(item => (item.w.includes(this.empKeyword) || item.wc.includes(this.empKeyword)) && item.m.includes(this.prdKeyword)).map(item => ({
            ...item,
            count: item.c,  // 实际入库数量
            remark: ''
          }));
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('获取订单详情失败', error);
      }
    },

    inputCountHandle(itemInfo){
      if(isNaN(itemInfo.count * 1)) {
        this.$message.warning('请输入数字')
        itemInfo.count = itemInfo.c
      }
      if(itemInfo.count > itemInfo.c) {
        itemInfo.count = itemInfo.c
      }

      if(itemInfo.count < 0) {
        itemInfo.count = 0
      }
    },

    // 确认入库
    async onSubmit (){
      const params = {
        ids: this.tableData.map(item => item.id * 1), //   []int64   待入库订单列表
        cnt: this.tableData.map(item => item.count * 1), //    []int   实际入库数量,可以是0
        remarks: this.tableData.map(item => item.remark), //    []string   备注
      }
      try {
        const res = await this.$api.ERP.emptyLib.submitEmptyInLib(params);
        if (res.code == 1) {
          this.$message.success('入库成功')
          this.onCancelDrawer()
          this.$emit('getTableData')
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('确认入库失败', error);
      }
    },

    resetHandle(){
      this.empKeyword = ''
      this.prdKeyword = ''
      this.getTableData()
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
    currentInfo: {
      default: () => ({})
    }
  },
  computed: {
    show: {
      get(){
        return this.value
      },

      set(val) {
        this.$emit('input', val)
      }
    }
  },
  watch: {
    value: {
      handler(newVal) {
        if(newVal) {
          this.resetHandle()
        } else {
          
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import '../../../../../style/common/elementDrawerWine.less';
@import '../../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../../style/common/elementFormBtnWine.less';
@import '../../../../../style/erp/table.less';
</style>

<style lang="less" scoped>
.in-lib-sure {
  .table {
    .w60 {
      width: 60%;
    }
    .tbody {
      height: calc(100vh - 280px);
      overflow: auto;
    }
  }

  .red {
    color: #F56C6C;
  }
}
</style>