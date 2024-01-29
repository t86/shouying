<template>
  <div>
    <!-- 充公出库 -->
    <el-drawer
      :title="batchLib? '批量充公出库' : '充公出库'"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5">
        <div v-if="batchLib" layout="row" layout-align="start center" class="m-b-4">
          <div>批量入库仓库选择：</div>
          <el-select v-model="selBatchLib" size="mini" style="width:100px" placeholder="请选择">
            <el-option
              v-for="item in storeList"
              :key="item.id"
              :label="item.n"
              :value="item.id"
            ></el-option>
          </el-select>
        </div>

        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">商品名称</div>
                <div class="th">规格</div>
                <div class="th" v-if="!batchLib">入库仓库</div>
                <div class="th">出库数量</div>
              </div>
            </div>
            <div class="tbody">
              <div
                class="tr"
                layout="row"
                layout-align="space-between center"
                v-for="(item, index) in tableData"
                :key="index"
              >
                <div class="td">{{item.n}}</div>
                <div class="td">{{item.u}}</div>
                <div class="td" v-if="!batchLib">
                  <el-select v-model="item.libVal" size="mini" style="width:100px" placeholder="请选择">
                    <el-option
                      v-for="item in storeList"
                      :key="item.id"
                      :label="item.n"
                      :value="item.id"
                    ></el-option>
                  </el-select>
                </div>
                <div class="td" layout="row" layout-align="center center">
                  <el-button
                    type
                    size="small"
                    style="width:26px;padding:0;height:26px;border-radius:50%"
                    icon="el-icon-minus"
                    :disabled="item.c<=1"
                    @click="changeCountHandle(item, Math.max(1, item.c - 1))"
                  ></el-button>
                  <el-input v-model="item.c" @input="changeCountHandle(item, item.c)" size="mini" style="width:60px;margin:0 10px"></el-input>
                  <el-button
                    type
                    size="mini"
                    :disabled="item.c >= item.maxCount"
                    style="width:26px;padding:0;height:26px;border-radius:50%"
                    icon="el-icon-plus"
                    @click="changeCountHandle(item, item.c + 1)"
                  ></el-button>
                </div>
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
      tableData: [],
      selBatchLib: '',
    };
  },
  methods: {
    changeCountHandle(itemInfo, count){
      let resultCount = Math.max(1, count)
      resultCount = Math.min(itemInfo.maxCount, resultCount)
      itemInfo.c = resultCount
    },
    async onSubmit (){
      const hasNotChooseStore = this.tableData.some(item => item.libVal === '')
      if(hasNotChooseStore && !this.batchLib) return this.$message.warning('请选择入库仓库')
      if(this.batchLib && !this.selBatchLib) return this.$message.warning('请选择入库仓库')
      const params = {
        prd_ids: this.tableData.map(item => item.id * 1), //    []int64   商品列表
        unit_types: this.tableData.map(item => item.u == '整瓶' ? '1' : item.u), // []string  对应商品列表的规格
        prd_cnts: this.tableData.map(item => item.c * 1), //   []int    对应商品列表的商品数量
        store_ids: this.batchLib ? this.tableData.map(item => this.selBatchLib * 1) : this.tableData.map(item => item.libVal * 1), //  []int64   对应商品列表的仓库
      }
      try {
        const res = await api_wine.reqToStorePrdListToLib(params)
        if(res.code == 1) {
          this.$message.success("入库成功");
          this.onCancelDrawer();
          this.$emit("getTableData");
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('充公出库失败', error)
      }
    },
    onCancelDrawer(){
      this.show = false
    },

  },
  mounted() {},
  props: {
    title: {
      default: '充公出库',
    },
    value: {
      default: false // 是否显示drawer
    },
    currentInfoList: {
      default: () => ([])
    },
    storeList:{
      default: () => ([])
    },
    batchLib: {
      default: false,
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
          this.tableData = this.currentInfoList.map(item => ({
            ...item,
            maxCount: item.c,
            libVal: ''
          }))
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
.session {
  overflow: hidden;
}
.table {
  .tbody {
    max-height: calc(100vh - 230px);
    scroll-behavior: auto;
    overflow: scroll;
  }
}
</style>