<template>
  <div class="cut-prd-table">
    <div class="coll" layout="row" layout-align="start center">
      <div class="label">规则对象：</div>
      <div class="value">
        <el-select size="small" v-model="ruleValue" placeholder="请选择">
          <el-option label="全部" :value="0"></el-option>
          <el-option label="点单人" :value="1"></el-option>
          <el-option label="订位人" :value="2"></el-option>
        </el-select>
      </div>
      <el-input v-model="keyword" style="width:200px;margin:0 10px" size="small" placeholder="商品名称/首字母"></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button type="info" size="small" @click="resetHandle">重置</el-button>
    </div>
    <el-button class="m-t-3 m-b-3" type="primary" size="small" @click="showOrHideDrawerHandle">新增商品</el-button>
    <el-button class="m-t-3 m-b-3" type="primary" size="small" @click="deleteSeatHandle">批量删除</el-button>
    <p style="color:#999">配置抽成商品的抽成金额</p>
    <div class="table-content">
      <div class="table m-t-3">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">
              <el-checkbox
                v-model="checked"
                :indeterminate="isIndeterminate"
                @change="changeCheckboxHandle('all')"
              >全选</el-checkbox>
            </div>
            <div class="th">规则对象</div>
            <div class="th">商品名称</div>
            <div class="th">一级分类</div>
            <div class="th">二级分类</div>
            <div class="th">单价</div>
            <div class="th">数量统计规则</div>
            <div class="th">金额统计规则</div>
            <div class="th">固定金额</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            v-for="(item, index) in tableData"
            :key="index"
            layout="row"
            layout-align="space-between center"
          >
            <div class="td">
              <el-checkbox
                v-model="item.checked"
                @change="changeCheckboxHandle('item')"
              >{{ index + 1 }}</el-checkbox>
            </div>
            <div class="td">{{ item.pn }}</div>
            <div class="td">{{ item.n }}</div>
            <div class="td">{{ item.on }}</div>
            <div class="td">{{ item.tn }}</div>
            <div class="td">{{ item.p }}</div>
            <div class="td" layout="row" layout-align="start center">
              <el-radio
                v-model="item.radioPrice"
                @change="updatePrdConfigHandle(item)"
                label="1"
              >全部（全价+打折）</el-radio>
              <el-radio
                v-model="item.radioPrice"
                @change="updatePrdConfigHandle(item)"
                label="2"
              >仅全价</el-radio>
            </div>
            <div class="td" layout="row" layout-align="start center">
              <el-radio
                v-model="item.radioAmt"
                @change="updatePrdConfigHandle(item)"
                label="1"
              >按销售比例</el-radio>
              <el-radio
                v-model="item.radioAmt"
                @change="updatePrdConfigHandle(item)"
                label="2"
              >按固定金额</el-radio>
            </div>
            <div class="td" layout="row" layout-align="space-between center">
              <div v-if="item.radioAmt == 1">
                <el-input
                  style="width:120px"
                  v-model="item.resultPercent"
                  placeholder="请输入0-100的数字"
                  @focus="getInputFocus($event)"
                  @input="resultPercentInputHandle($event, item)"
                ></el-input>
                <span>%</span>
              </div>
              <div v-else>
                <el-input
                  style="width:120px"
                  v-model="item.resultAmt"
                  placeholder="请输入金额"
                  @input="resultAmtInputHandle($event, item)"
                ></el-input>
                <span>元</span>
              </div>
              <el-button
                :type="item.resultAmt == item.originAmt && item.radioAmt == 2 || item.resultPercent == item.originPercent && item.radioAmt == 1 ? 'info' : 'primary'"
                size="mini"
                :disabled="item.resultAmt == item.originAmt && item.radioAmt == 2 || item.resultPercent == item.originPercent && item.radioAmt == 1"
                @click.stop="updatePrdConfigHandle(item, item.resultAmt == item.originAmt && item.radioAmt == 2 || item.resultPercent == item.originPercent && item.radioAmt == 1)"
              >
                <i class="el-icon-check"></i>
              </el-button>
            </div>
          </div>
          <div class="no-data" v-if="tableData.length == 0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>
    <drawerAddPrdCom
      :showDrawer="showDrawer"
      :addedSeatList="tableData"
      @showOrHideDrawerHandle="showOrHideDrawerHandle"
      @getTableData="getTableData"
    />
  </div>
</template>
 
<script>
import drawerAddPrdCom from "./drawerAddPrdCom/drawerAddPrdCom.vue";
export default {
  data() {
    return {
      keyword: '',
      ruleValue: 0,
      // menuId: "",
      showDrawer: false,
      checked: false,
      tableData: [],
    };
  },
  methods: {
    init() {
      this.getTableData();
    },

    // 获取表格数据
    async getTableData(menuId='') {
      // if (!menuId) return;
      const params = {
        dept_id: 0, //menuId * 1, //   int64 部门Id
        type_id: this.ruleValue * 1, // int 0 全部 1 点单人 2 订位人  
        key: this.keyword, //  string  模糊查询关键字
      };
      try {
        const res = await this.$api.BMS.cutPrd.reqGetPrdConfig(params);
        if(res.code == 1) {
          const tableData = res.data.items || [];
          this.tableData = tableData.map(item => ({
            ...item,
            radioPrice: item.cnt_rule.toString(),
            radioAmt: item.amt_rule.toString(),
            resultAmt: item.fixed_amt,
            originAmt: item.fixed_amt,
            resultPercent: item.percent_amt,
            originPercent: item.percent_amt,
            checked: false
          }));
          this.checked = false;
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("获取表格数据失败", error);
      }
    },

    // 输入金额两位小数限定
    resultAmtInputHandle(e, itemInfo) {
      if (isNaN(e * 1)) {
        this.$message.warning("请输入数字");
      } else {
        const tempVal = e.split(".");
        if (tempVal.length < 2) {
          itemInfo.resultAmt = e * 1;
        } else if (tempVal.length >= 2) {
          // 输入的有小数
          tempVal[1] = tempVal[1].slice(0, 2);
          itemInfo.resultAmt = [tempVal[0], tempVal[1]].join(".");
        }
        if (itemInfo.resultAmt * 1 > itemInfo.p * 1) {
          this.$message.warning("固定金额不可超过单价");
          itemInfo.resultAmt = itemInfo.p;
        }
      }
    },

    // 输入百分比限定
    resultPercentInputHandle(e, itemInfo){
      if (isNaN(e * 1)) {
        this.$message.warning("请输入数字");
      } else {
        const tempVal = e.split(".");
        if (tempVal.length < 2) {
          itemInfo.resultPercent = e * 1;
        } else if (tempVal.length >= 2) {
          // 输入的有小数
          tempVal[1] = tempVal[1].slice(0, 2);
          itemInfo.resultPercent = [tempVal[0], tempVal[1]].join(".");
        }
        if (itemInfo.resultPercent * 1 > 100) {
          this.$message.warning("最大百分比为100");
          itemInfo.resultPercent = 100;
        }
      }
    },

    // el-input获取焦点时全选input中的文字
    getInputFocus(event) {
      event.currentTarget.select();
    },

    // 更改商品配置
    async updatePrdConfigHandle(itemInfo, flag = false) {
      const params = {
        type_id: itemInfo.t * 1, //    int  抽成对象类型 1 点单人 2 订位人
        dept_id: this.menuId * 1, //   int64 部门Id
        prd_id: itemInfo.id * 1, //     int64    商品Id
        cnt_rule: itemInfo.radioPrice * 1, //   int    数量规则 1 全部(全价+打折) 2 仅全价
        amt_rule: itemInfo.radioAmt * 1, //   int    金额规则 1 按售价比例 2 按固定金额
        fixed_amt: itemInfo.radioAmt * 1 == 1 ? "0" : (itemInfo.resultAmt * 1).toString(), //  string  固定金额(单位元,支持两位小数), 当AmtRule=1时 传0
        percent_amt: itemInfo.radioAmt == 1 ? itemInfo.resultPercent * 1 : 0 // int    百分比值,范围1-100 当AmtRule=2时,传0
      };
      try {
        const res = await this.$api.BMS.cutPrd.reqSavePrdConfig(params);
        if(res.code == 1) {
          this.$message.success("更新成功");
          this.getTableData(this.menuId);
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("更新最小金额失败", error);
      }
    },
    // 批量删除
    async deleteSeatHandle() {
      const params = {
        dept_id: 0, // this.menuId * 1, //   int64 部门Id
        type_ids: this.tableData
          .filter(item => item.checked)
          .map(item => item.t * 1), //   []int  抽成对象类型 1 点单人 2 订位人
        prd_ids: this.tableData
          .filter(item => item.checked)
          .map(item => item.id * 1) //   []int64  待删除商品列表
      };
      if (params.prd_ids.length == 0)
        return this.$message.warning("请选择需要删除的商品");
      try {
        const res = await this.$api.BMS.cutPrd.reqDelPrdConfig(params);
        if(res.code == 1) {
          this.$message.success("删除成功");
          this.getTableData(this.menuId);
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("批量删除商品失败", error);
      }
    },
    // 改变多选框的值
    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData.forEach(el => {
            el.checked = this.checked;
          });
          break;
        case "item":
          this.checked = this.tableData.every(item => item.checked);
          break;
      }
      this.$forceUpdate();
    },
    showOrHideDrawerHandle() {
      this.showDrawer = !this.showDrawer;
    },

    resetHandle(){
      this.keyword = ''
      this.ruleValue = 0
      this.getTableData()
    }
  },
  mounted() {
    this.init();
  },
  props: {
  },
  components: {
    drawerAddPrdCom
  },
  computed: {
    isIndeterminate() {
      if (this.tableData.every(item => item.checked)) {
        return false;
      } else {
        return this.tableData.some(item => item.checked);
      }
    },
  },
  watch: {
    $route(newVal) {
      // this.menuId = newVal.query.menuId;
      this.init();
      this.getTableData(newVal.query.menuId);
    }
  }
};
</script>

<style lang="less">
@import '../../../../../../style/erp/table.less';
</style>
<style scoped lang="less">
@import "./cutPrdTable.less";
</style>