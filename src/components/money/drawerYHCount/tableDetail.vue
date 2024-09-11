<template>
  <div class="YH-detail" @click="hidePrdList">
    <div class="top" layout="row" layout-align="start center">
      <span>姓名：{{resultInfo.name}}</span>
      <span class="m-l-10">工号：{{resultInfo.code}}</span>
    </div>

    <div class="table m-t-4">
      <div class="thead">
        <div class="tr" layout="row" layout-align="start center">
          <div class="th">限额限量名称</div>
          <div class="th">类型</div>
          <div class="th">
            <div class="th-top">日限数量</div>
            <div class="th-bottom" layout="row" layout-align="start center">
              <div class="th-th">已用</div>
              <div class="th-th">剩余</div>
            </div>
          </div>
          <div class="th">
            <div class="th-top">日限金额</div>
            <div class="th-bottom" layout="row" layout-align="start center">
              <div class="th-th">已用</div>
              <div class="th-th">剩余</div>
            </div>
          </div>
          <div class="th">
            <div class="th-top">月用数量</div>
            <div class="th-bottom" layout="row" layout-align="start center">
              <div class="th-th">已用</div>
              <div class="th-th">剩余</div>
            </div>
          </div>
          <div class="th">
            <div class="th-top">月限金额</div>
            <div class="th-bottom" layout="row" layout-align="start center">
              <div class="th-th">已用</div>
              <div class="th-th">剩余</div>
            </div>
          </div>
        </div>
      </div>
      <div class="tbody">
        <div
          class="tr"
          layout="row"
          layout-align="start center"
          v-for="(item, index) in tableData"
          :key="index"
        >
          <div class="td" @click.stop="">
            <span style="color:#2170ff;cursor:pointer" @click="getPrdList(item, index)">{{item.n}}</span>
            <img v-if="item.showPrdList" class="sj" :src="require('@/assets/card-imgs/cardOptions/sanjiao.png')" alt />
            <ul v-if="item.showPrdList" class="prd-list" :style="{top: (-1 * Math.min((60 + index * 40), 130)) + 'px'}">
              <li class="thead">
                <div class="tr" layout="row" layout-align="start center">
                  <div class="th">序号</div>
                  <div class="th">商品名称</div>
                </div>
              </li>
              <li class="tbody">
                <div class="tr" layout="row" layout-align="start center" v-for="(items, indexs) in item.prdList" :key="indexs">
                  <div class="td">{{indexs + 1}}</div>
                  <div class="td">{{items.p}}</div>
                </div>
                <div class="no-data m-t-6" v-if="item.prdList.length == 0">暂无数据</div>
              </li>
            </ul>
          </div>
          <div class="td">{{item.t}}</div>
          <div class="td" style="width:10%">{{item.udc}}</div>
          <div class="td" style="width:10%">{{item.ldc}}</div>
          <div class="td" style="width:10%">{{item.uda}}</div>
          <div class="td" style="width:10%">{{item.lda}}</div>
          <div class="td" style="width:10%">{{item.umc}}</div>
          <div class="td" style="width:10%">{{item.lmc}}</div>
          <div class="td" style="width:10%">{{item.uma}}</div>
          <div class="td" style="width:10%">{{item.lma}}</div>
        </div>
        <p v-if="tableData.length == 0" class="m-t-10 fs14" style="text-align:center">暂无数据</p>
      </div>
    </div>
  </div>
</template>
 
<script>
import api_money from "@/api/money";
export default {
  data() {
    return {
      show: false,
      tableData: []
    };
  },
  methods: {
    async getPrdList(itemInfo, index){
      const params = {
        free_limit_ids: [itemInfo.id * 1] // []int64   限额限量配置列表
      }

      try {
        const res = await this.$api.BMS.station.reqGetChoosePrdList(params)
        if(res.code == 1) {
          this.tableData = this.tableData.map((item, i) => ({
            ...item,
            showPrdList: index == i,
            prdList: index == i ? [...(res.data.records || [])] : []
          }))
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('限额限量商品明细获取失败', error)
      }
    },

    hidePrdList(){
      this.tableData = this.tableData.map(item => ({
        ...item,
        showPrdList: false,
        prdList: []
      }))
    },

    onCancelDrawer() {
      this.$emit("showOrHideYHDetailDrawer");
    },
  },
  props: {
    resultInfo: {
      default: {} 
    }
  },
  watch: {
    resultInfo: {
      handler(newVal) {
        this.tableData = (newVal.records || []).map(item => ({
          ...item,
          showPrdList: false,
          prdList: []
        }))
      },
      immediate: true,
      deep: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/scrollBar.less";
</style>

<style lang="less" scoped>
.YH-detail{
  color: rgba(255, 255, 255, 0.8);
  padding: 20px;
  .table{
    height: calc(100vh - 230px);
    overflow: auto;
    font-size: 14px;
    width: 100%;
    position: relative;
    .thead{
      position: sticky;
      top: 0;
      z-index: 1;
      background: #182037;
      // background: linear-gradient(180deg, #182037 0%, #11182D 100%);
    }
    .tr{
      text-align: center;
      padding: 4px 0;
      .th-top,.th-bottom{
        padding: 4px 0;
      }
      .th,.td{
        width: 20%;
      }
      .th-th{
        width: 50%;
      }
    }

    .tbody .tr{
      padding: 10px 0;
      &:nth-child(2n){
        background-color: rgba(255, 255, 255, 0.04);
      }

      .td {
        position: relative;
        .sj{
          width: 20px;
          position: absolute;
          left: 101%;
          top: 50%;
          transform: translate(-10px, -50%);
          z-index: 2;
        }
        .prd-list {
          position: absolute;
          width: 200px;
          min-height: 100px;
          max-height: 300px;
          overflow-y: auto;
          left: calc(100% + 10px);
          padding: 0 4px;
          background: #2A3959;
          // background: linear-gradient(180deg, #2A3959 0%, #2A3959 100%);
          box-shadow: 0px 0px 10px 0px rgb(26 137 255 / 80%);
          border: 1px solid #32B9FF;
          border-radius: 8px;
          z-index: 1;
          .thead {
            background:#182037;
            // background: linear-gradient(180deg, #182037 0%, #11182D 100%);
            z-index: 10;
          }
          .tr {
            .th:nth-child(1), .td:nth-child(1){
              width: 50px;
            }
            .th:nth-child(2), .td:nth-child(2){
              width: 150px;
            }
          }
        }
      }
    }

  }
}
</style>