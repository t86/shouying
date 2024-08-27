<template>
  <div class="vip-fav">
    <div class="table">
      <div class="thead">
<!--        id         int64      //PrdId 商品Id-->
<!--        n          string     //PrdName 商品名称-->
<!--        oc         string     //OneCateName 商品一级分类名称-->
<!--        tc         string     //TwoCateName 商品二级分类名称-->
<!--        c          int        //OrderCnt 点单次数-->
        <div class="tr" layout="row" layout-align="space-between center">
          <div class="th">序号</div>
          <div class="th">商品</div>
          <div class="th">一级分类</div>
          <div class="th">二级分类</div>
          <div class="th">点击次数</div>
        </div>
      </div>
      <div class="tbody">
        <div
          class="tr"
          layout="row"
          layout-align="space-between center"
          v-for="(item, index) in tableData"
          :key="item.id"
        >
          <div class="td">{{index + 1}}</div>
          <div class="td">{{item.n}}</div>
          <div class="td">{{item.oc}}</div>
          <div class="td">{{item.tc}}</div>
          <div class="td">{{item.c}}</div>
        </div>
      </div>
    </div>
  </div>
</template>
 
<script>
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      tableData: [],
    };
  },
  methods: {
    async getTableData(reset) {
      const params = {
        ...(this.info.bp && { bind_phone: this.info.bp }), // string  绑定手机号(用于查询有绑定手机的会员信息,里面可能包含多张卡)
        ...(!this.info.bp && { id: this.info.id * 1 }) //  int64   会员卡Id(用于查询没有绑定手机的会员卡信息,单卡) 与bind_phone互斥
      };

      try {
        const res = await api_vip.get_mb_csm_top_prds(params);
        if (res.code == 1) {
          this.tableData = res.data.records || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("交易明细获取失败", error);
      }
    },

    changePageHandle(page) {
      this.pageInfo.page = page;
      this.getTableData();
    }
  },
  props: {
    info: {
      default: {}
    }
  }
};
</script>

<style lang="less" scoped>
@import "../../../../style/vip/vip.less";
</style>
<style scoped lang="less">
.vip-fav {
  font-size: 14px;
  .table {
    height: calc(100vh - 280px);
    overflow-y: auto;
    .th:nth-child(1),
    .td:nth-child(1) {
      width: 50px;
    }
    .th:nth-child(2),
    .td:nth-child(2) {
      width: 50%
    }
    .th:nth-child(3),
    .td:nth-child(3) {
      width: 80px;
    }
    .th:nth-child(4),
    .td:nth-child(4) {
      width: 80px;
    }
    .th:nth-child(5),
    .td:nth-child(5) {
      width: 80px;
      // span {
      //   color: #2362d5;
      //   cursor: pointer;
      // }
    }
  }

  .pagination{
    margin-top: 20px;
    float: right;
  }
}
</style>