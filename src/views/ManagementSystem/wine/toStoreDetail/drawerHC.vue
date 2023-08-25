<template>
  <div>
    <!-- 红冲 -->
    <el-drawer
      title="红冲"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="850px"
    >
      <div class="session p-5 hc">
        <div class="top" layout="row" layout-align="start center">
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">出库单号：</div>
            <div class="value">{{orderId}}</div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">出库时间：</div>
            <div class="value">{{outTime}}</div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">操作人：</div>
            <div class="value">{{outEmp}}</div>
          </div>
        </div>
        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">商品名称</div>
                <div class="th">规格</div>
                <div class="th">入库仓库</div>
                <div class="th">红冲前数量</div>
                <div class="th">红冲数量</div>
                <div class="th">红冲后数量</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="item in tableData" :key="item.id">
                <div class="td">{{item.p}}</div>
                <div class="td">{{item.u}}</div>
                <div class="td">{{item.s}}</div>
                <div class="td">{{item.c}}</div>
                <div class="td">
                  <el-input v-model="item.count" style="width:80%" @input="inputHandle(item)" size="mini" placeholder="请输入数量"></el-input>
                </div>
                <div class="td">{{item.resultCount}}</div>
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
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_wine from '@/api/wine'
export default {
  data() {
    return {
      orderId: '',
      outTime: '',
      outEmp: '',
      tableData: []
    };
  },
  methods: {
    async getTableData(){
      const params = {
        id: this.currentInfo.id * 1  //  int64   充公出库单订单Id
      }
      try {
        const res = await api_wine.reqGetToStoreOfHc(params)
        if(res.code == 1) {
          this.tableData = (res.data.records || []).map(item => ({
            ...item,
            count: '',  // 红冲数量
            resultCount: item.c   // 剩余红冲数量
          }))

          this.orderId = res.data.id
          this.outTime = res.data.out_time || ''
          this.outEmp = res.data.oper_emp_name || ''
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('红冲详情列表获取失败', error)
      }
    },

    inputHandle(itemInfo){
      if(isNaN(itemInfo.count * 1)) {
        itemInfo.resultCount = itemInfo.c
      } else {
        if(itemInfo.count > itemInfo.c) {
          itemInfo.count = itemInfo.c
        }
        if(itemInfo.count * 1 <= 0) {
          itemInfo.count = ''
        }
        itemInfo.resultCount = itemInfo.c - itemInfo.count * 1
      }
    },


    async onSubmit (){
      const params = {
        order_dtl_ids: this.tableData.filter(item => item.count * 1 > 0).map(item => item.id * 1), // []int64  待充公出库子订单Id列表
        hc_prd_cnts: this.tableData.filter(item => item.count * 1 > 0).map(item => item.count * 1), // []int   对应上面子订单列表,红冲商品数量
      }
      try {
        const res = await api_wine.reqToStoreToHc(params)
        if(res.code == 1) {
          this.$message.success('操作成功')
          this.onCancelDrawer();
          this.$emit("getTableData");
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('红冲操作失败', error)
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
         this.getTableData()
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import '../../../../style/common/elementDrawerWine.less';
@import '../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../style/common/elementFormBtnWine.less';
@import "../../../../style/wine/table.less";
</style>

<style lang="less" scoped>
.hc {
  .top {
    margin-bottom: 20px;
    .coll {
      margin-right: 30px;
    }
  }

  .table {
    .tbody {
      overflow: auto;
      height: calc(100vh - 250px);
    }
  }
}
</style>