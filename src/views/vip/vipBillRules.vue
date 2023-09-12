<template>
  <!-- 会员卡号生成规则 -->
  <div class="vip vip-bill-rules">
    <h3 class="title">会员卡结账规则</h3>
    <div class="warning">
      说明：未在表单中配置规则的商品, 如使用会员卡渠道,只能使用储值金额结账
    </div>

    <div class="search m-t-2 m-b-4">
      <div class="row">
        <span class="label">商品分类:</span>
        <el-select
          v-model="form.productVal"
          size="small"
          placeholder="请选择商品类型"
          style="width: 200px"
        >
          <el-option
            v-for="item in form.productOption"
            :key="item.id"
            :label="item.n"
            :value="item.id"
          >
          </el-option>
        </el-select>
      </div>
      <div class="row" layout="row" layout-align="start center">
        <el-input
          class="m-r-2"
          v-model="form.keyword"
          size="small"
          placeholder="商品名称/首字母"
          style="width: 200px"
        ></el-input>
        <button class="btn primary m-l-4" @click="getTableData">查询</button>
        <button class="btn info m-l-4" @click="resetHandle">重置</button>
      </div>
    </div>
  </div>
</template>

<script>
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      form: {
        productVal: "",
        productOption: [],
        keyword: "",
      },
    };
  },
  methods: {},
  mounted() {},
};
</script>

<style lang="less" scoped>
@import "../../style/common/elementDrawerVip.less";
@import "../../style/vip/vipBtn.less";
@import "../../style/vip/vip.less";
</style>

<style lang="less" scoped>
.vip-bill-rules {
  .warning {
    font-size: 28px;
    color: red;
    margin-bottom: 20px;
  }

  .search {
    display: grid;
    grid-template-columns: 300px 400px;
    grid-gap: 10px;

    .row {
      span {
        font-size: 13px;
      }
    }
  }
}
</style>
