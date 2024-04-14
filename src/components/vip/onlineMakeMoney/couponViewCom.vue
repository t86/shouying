<template>
  <div class="coupon vip">
    <div
      layout="row"
      layout-align="start center"
    >
      <div class="item" layout="row" layout-align="start center">
        <div class="label">类型:</div>
        <el-select v-model="searchFormData.typeValue" placeholder="请选择">
          <el-option
            v-for="item in typeOptions"
            :key="item.value"
            :label="item.label"
            :value="item.value"
          ></el-option>
        </el-select>
      </div>
      <div class="item m-l-2 m-r-1" layout="row" layout-align="start center">
        <el-input
          v-model="searchFormData.keyword"
          style="width: 200px"
          placeholder="请输入卡券名称或大礼包名称"
        ></el-input>
      </div>
      <div class="item" layout="row" layout-align="start center">
        <button class="btn primary" @click="getTableData">搜索</button>
        <button class="btn info" @click="restSearchData">重置</button>
      </div>
    </div>

    <div class="table m-t-5">
      <div class="thead">
        <div class="tr" layout="row" layout-align="start center">
          <div class="th">序号</div>
          <div class="th">名称</div>
          <div class="th">类型</div>
        </div>
      </div>
      <div class="tbody">
        <div v-for="(item, index) in tableData" :key="index">
          <div class="tr" layout="row" layout-align="start center">
            <div class="td" layout="row">
              <el-radio
                v-model="radioValue"
                :label="index"
                style="
                  width: 40px !important;
                  margin-top: 5px;
                  margin-right: 10px;
                "
                >{{ index + 1 }}</el-radio
              >
            </div>
            <div class="td">{{ item.n }}</div>
            <div class="td">{{ item.t }}</div>
          </div>

        </div>
        <div class="no-data" v-if="tableData.length == 0">
          <img src="@/assets/img/no-data.png" alt />
          <p>暂无数据</p>
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
      typeOptions: [{
        value: 0,
        label: "全部",
      }, {
        value: 1,
        label: "兑换券",
      }, {
        value: 2,
        label: "大礼包",
      }],
      searchFormData: {
        typeValue: 0,
        keyword: "",
      },
      tableData: [],
      radioValue: "",
    };
  },
  props: {
    id: {
      type: String,
      default: "",
    },
  },
  mounted() {
    this.radioValue = this.id;
    this.getTableData();
  },
  methods: {
    async getTableData() {
      try {
        const res = await api_vip.reqGetKqItems({
          type_id: this.searchFormData.typeValue,
          key: this.searchFormData.keyword,
        });
        console.log("coupon res", res);
        this.tableData = (res.data.records || []).map((item) => {
          return {
            ...item,
          };
        });
      } catch (e) {
        this.$message.warning("获取卡券/礼包数据失败" + e);
      }
      return;
    },
    restSearchData() {
      this.searchFormData = {
        typeValue: 0,
        keyword: "",
      };
      this.getTableData();
    },
  },
  watch: {
    radioValue(newValue) {
      console.log("radioValue", newValue);
      if(newValue && this.tableData.length > 0) {
        this.$emit("value-changed", this.tableData[newValue]);
      }
    },
    id(newValue) {
      console.log("id", newValue);
      this.radioValue = newValue;
    },
  },
};
</script>
<style lang="less" scoped>
@import "../../../style/vip/vip.less";
@import "../../../style/vip/vipBtn.less";
</style>
<style lang="less"  scoped>
.coupon {
  padding: 20px;
  .table {
    max-height: calc(100vh - 250px);
    overflow-y: auto;
    .tr {
      .th,
      .td {
        width: 30%;
      }
      .th:nth-child(1),
      .td:nth-child(1),
      .th:nth-last-child(1),
      .td:nth-last-child(1) {
        width: 20%;
        span{
          color: #2362D5;
          cursor: pointer;
        }
      }
    }
  }
}
</style>
