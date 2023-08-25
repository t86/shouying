<template>
  <div>
    <!-- 库存明细 -->
    <el-drawer
      title="库存明细"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="90%"
    >
      <div class="session p-5">
        <div class="top m-b-2 fs18" layout="row" layout-align="start center">
          <div class="title m-r-8">当前所选流水：{{currentInfo.n}}</div>
          <div class="title">当前所选规格：{{currentInfo.g == 1 ? '整瓶' : currentInfo.g + '瓶'}}</div>
        </div>
        <div class="red fs14 m-b-3">红色为过期待处理</div>
        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th" style="width:70%">入库时间</div>
                <div class="th">客人姓名</div>
                <div class="th">手机号</div>
                <div class="th">库存数量</div>
                <div class="th" style="width:70%">存酒流水号</div>
                <div class="th">卡台</div>
                <div class="th">订位人</div>
                <div class="th">服务员</div>
                <div class="th" style="width:70%">存酒时间</div>
                <div class="th" style="width:70%">过期时间</div>
                <div class="th">备注手机号</div>
                <div class="th">备注姓名</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" :class="{red: item.isPass}" layout="row" layout-align="space-between center" v-for="item in tableData" :key="item.id">
                <div class="td" style="width:70%">{{item.t}}</div>
                <div class="td">{{item.cn}}</div>
                <div class="td">{{item.p}}</div>
                <div class="td">{{item.c}}</div>
                <div class="td" style="width:70%;user-select:text">{{item.i}}</div>
                <div class="td">{{item.s}}</div>
                <div class="td">{{item.se}}</div>
                <div class="td">{{item.w}}</div>
                <div class="td" style="width:70%">{{item.bt}}</div>
                <div class="td" style="width:70%">{{item.e}}</div>
                <div class="td">{{item.rp}}</div>
                <div class="td">{{item.rn}}</div>
              </div>
              <div class="no-data" v-if="tableData.length==0">
                <img src="@/assets/img/wu.png" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_wine from '@/api/wine'
export default {
  data() {
    return {
      tableData: []
    };
  },
  methods: {
    async getTableData(){
      const params = {
        prd_id: this.currentInfo.id * 1, //   int64   商品Id
        unit_type: this.currentInfo.g, //  string   规格,整瓶1,散瓶0.x
      }
      try {
        const res = await api_wine.reqGetSaveLibGridDetail(params)
        if(res.code == 1) {
          this.tableData = (res.data.records || []).map(item => ({
            ...item,
            isPass: +new Date(item.e) - +new Date() <= 0
          }))
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取存酒库库存数据失败', error)
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
  .red {
    color: red;
  }

  .table{
    .tbody{
      max-height: calc(100vh - 260px);
    }
  }
</style>