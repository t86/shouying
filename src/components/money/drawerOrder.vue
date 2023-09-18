<template>
  <div>
    <!-- 点单记录 -->
    <el-drawer
      title="点单记录"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div class="order-detail">
        <div class="top" layout="row" layout-align="space-between center">
          <div class="row">
            <span class="label">商品类型:</span>
            <el-select
              v-model="form.prodType"
              size="small"
              placeholder="请选择商品类型"
              style="width: 200px"
            >
              <el-option
                v-for="item in form.prodOptions"
                :key="item.id"
                :label="item.n"
                :value="item.id"
              >
              </el-option>
            </el-select>
          </div>

          <div class="row">
            <span class="label">营业类型:</span>
            <el-select
              v-model="form.businessType"
              size="small"
              placeholder="请选择营业类型"
              style="width: 200px"
            >
              <el-option
                v-for="item in form.businessOptions"
                :key="item.id"
                :label="item.n"
                :value="item.id"
              >
              </el-option>
            </el-select>
          </div>

          <div class="top-left" layout="row" layout-align="start center">
            <input
              v-model="form.keyword"
              placeholder="订台人/点单人/商品名称"
            />
            <el-button
              class="m-l-2"
              type="primary"
              style="width: 70px; height: 30px; line-height: 30px; padding: 0"
              @click="getTableData"
              >查询</el-button
            >
            <el-button
              type="info"
              style="width: 70px; height: 30px; line-height: 30px; padding: 0"
              @click="resetHandle"
              >重置</el-button
            >
          </div>
          <el-button
            type="primary"
            @click="exportExcel"
            style="width: 90px; height: 30px; line-height: 30px; padding: 0"
            >导出Excel</el-button
          >
        </div>

        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">区域</div>
              <div class="th">卡台</div>
              <div class="th">点单时间</div>
              <div class="th">点单部门</div>
              <div class="th">点单人</div>
              <div class="th">商品一级分类</div>
              <div class="th">商品二级分类</div>
              <div class="th">商品名称</div>
              <div class="th">点单数量</div>
              <div class="th">点单金额</div>
              <div class="th">实收金额</div>
              <div class="th">订台人</div>
              <div class="th">订位部门</div>
              <div class="th">支付信息</div>
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
              <div class="td">{{ item.r }}</div>
              <div class="td">{{ item.s }}</div>
              <div class="td">{{ item.o }}</div>
              <div class="td">{{ item.od }}</div>
              <div class="td">{{ item.oe }}</div>
              <div class="td">{{ item.po }}</div>
              <div class="td">{{ item.pt }}</div>
              <div class="td">{{ item.p }}</div>
              <div class="td">{{ item.c }}</div>
              <div class="td">{{ item.a }}</div>
              <div class="td">{{ item.v }}</div>
              <div class="td">{{ item.se }}</div>
              <div class="td">{{ item.sd }}</div>
              <div class="td">{{ item.pi }}</div>
            </div>
            <p
              v-if="tableData.length == 0"
              class="m-t-10 fs14"
              style="text-align: center"
            >
              暂无数据
            </p>
          </div>
        </div>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_money from "@/api/money";
export default {
  data() {
    return {
      show: false,
      form: {
        keyword: "",
        prodType: "",
        businessType: "",
        prodOptions: [],
        businessOptions: [],
      },
      tableData: [],
    };
  },
  methods: {
    // 获取数据
    async getTableData() {
      const params = {
        key: this.form.keyword, //  string  查询关键字
      };
      try {
        const res = await api_money.reqGetOrderDetailList(params);
        if (res.code == 1) {
          this.tableData = res.data.records || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取表格数据失败", error);
      }
    },

    // 导出excel
    async exportExcel() {
      const params = {
        key: this.form.keyword, //  string  查询关键字
      };

      try {
        const res = await api_money.reqExportOrderDetailReport(params);
        if (!res.msg) {
          const url = window.URL.createObjectURL(
            new Blob([res], {
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            })
          );
          const a = document.createElement("a"); //添加a标签
          document.body.appendChild(a);
          a.href = url;
          a.setAttribute("download", res.fileName); // 下载文件的名称及文件类型后缀
          a.click(); //点击标签
          document.body.removeChild(a); // 下载完成移除元素
          window.URL.revokeObjectURL(url); // 释放掉blob对象
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("导出excel失败", error);
      }
    },

    onCancelDrawer() {
      this.$emit("showOrHideOrderDetailDrawer");
    },

    resetHandle() {
      this.form = {};
      this.getTableData();
    },
  },
  props: {
    showDrawer: {
      default: false, // 是否显示drawer
    },
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      newVal ? this.resetHandle() : "";
    },
  },
};
</script>

<style scoped lang="less">
@import "../../style/money/drawerOrder.less";
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>
