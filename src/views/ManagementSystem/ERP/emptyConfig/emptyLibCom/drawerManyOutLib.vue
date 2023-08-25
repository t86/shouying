<template>
  <div>
    <!-- 批量出库 -->
    <el-drawer
      title="批量出库"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="800px"
    >
      <div class="session p-5 hc">
        <!-- 表格 -->
        <div class="table-content m-t-3">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">空瓶名称</div>
                <div class="th">库存数量</div>
                <div class="th">出库数量</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="item in tableData" :key="item.id">
                <div class="td">{{item.n}}</div>
                <div class="td">{{item.c}}</div>
                <div class="td">
                  <el-input-number v-model="item.count" size="mini" @change="inputCountHandle(item)" :min="1" :max="item.c" label="请输入出库数量"></el-input-number>
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
        <el-button type="primary" @click="onSubmit">确认出库</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      tableData: []
    };
  },
  methods: {
    inputCountHandle(itemInfo){
      if(!itemInfo.count) {
        return this.$message.warning('请输入出库数量')
      }
      if(isNaN(itemInfo.count * 1)) {
        this.$message.warning('请输入数字')
        itemInfo.count = itemInfo.c
      }
      if(itemInfo.count > itemInfo.c) {
        this.$message.warning('数量不可超过库存数量' + itemInfo.c)
        itemInfo.count = itemInfo.c
      }

      if(itemInfo.count < 1) {
        itemInfo.count = 1
      }
    },

    // 确认出库
    async onSubmit (){
      const isNaNOrder = this.tableData.every(item => !isNaN(item.count * 1) &&  item.count > 0)
      if(!isNaNOrder) return this.$message.warning('请填写出库数量')
      const params = {
        ids: this.tableData.filter(item => item.count * 1 > 0).map(item => item.id * 1), //   []int64   入库订单列表
        cnt: this.tableData.filter(item => item.count * 1 > 0).map(item => item.count * 1), //    []int   红冲数量,>0
      }
      try {
        const res = await this.$api.ERP.emptyLib.emptyLibOut(params);
        if (res.code == 1) {
          this.$message.success('出库成功')
          this.onCancelDrawer()
          this.$emit('getTableData')
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('出库失败', error);
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
    currentList: {
      default: () => ([])
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
          this.tableData = this.currentList.map(item => ({
            ...item,
            count: item.c
            }))
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
.hc {
  .table {
    .tbody {
      height: calc(100vh - 210px);
      overflow: auto;
    }
  }
}
</style>