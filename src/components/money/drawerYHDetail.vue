<template>
  <div class="YH-detail">
    <!-- 优惠明细表 -->
    <el-drawer
      title="优惠明细表"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div>
        <div class="top" layout="row" layout-align="space-between center">
          <div class="top-left" layout="row" layout-align="start center">
            <span>优惠类型：</span>
            <mySelect
              style="width:150px"
              :value="selectInfo.selectVal"
              :optionsList="selectInfo.selectOption"
              @selectOptionItem="setSelectValHandle"
              @selectBlurHandle="selectBlurHandle"
              @getOption="getOptionHandle"
            />
            <input v-model="keyword" placeholder="订台人/优惠人/商品名称" />
            <el-button
              class="m-l-2"
              type="primary"
              style="width:70px;height:30px;line-height:30px;padding:0"
              @click="getTableData"
            >查询</el-button>
            <el-button
              type="info"
              style="width:70px;height:30px;line-height:30px;padding:0"
              @click="resetHandle"
            >重置</el-button>
          </div>
          <el-button
            type="primary"
            @click="exportExcel"
            style="width:90px;height:30px;line-height:30px;padding:0"
          >导出Excel</el-button>
        </div>

        <div class="table">
          <table class="custom-table">
            <thead>
              <tr>
                <th>序号</th>
                <th>优惠部门</th>
                <th>优惠人</th>
                <th>优惠总额</th>
                <th>区域</th>
                <th>卡台名称</th>
                <th>优惠时间</th>
                <th>优惠类型</th>
                <th>优惠理由</th>
                <th>商品一级分类</th>
                <th>商品二级分类</th>
                <th>商品名称</th>
                <th>商品单价</th>
                <th>优惠数量</th>
                <th>优惠金额小计</th>
                <th>订台人</th>
                <th>订台部门</th>
                <th>优惠2关联功能台</th>
                <th>优惠2关联功能台区域</th>
                <th>优惠2订位人</th>
                <th>优惠2订位人部门</th>
              </tr>
            </thead>
            <tbody>
              <template v-if="flatTableData.length > 0">
                <tr v-for="(item, index) in flatTableData" :key="index">
                  <td>{{item.rowNum}}</td>
                  <!-- 优惠部门、优惠人、优惠总额需要合并单元格 -->
                  <td v-if="item.isFirstInGroup" :rowspan="item.groupRowspan">{{item.ad}}</td>
                  <td v-if="item.isFirstInGroup" :rowspan="item.groupRowspan">{{item.ae}}</td>
                  <td v-if="item.isFirstInGroup" :rowspan="item.groupRowspan">{{item.a}}</td>
                  <!-- 以下是明细字段，每行都显示 -->
                  <td>{{item.rn}}</td>
                  <td>{{item.s}}</td>
                  <td>{{item.o}}</td>
                  <td>{{item.t}}</td>
                  <td>{{item.r}}</td>
                  <td>{{item.on}}</td>
                  <td>{{item.tn}}</td>
                  <td>{{item.n}}</td>
                  <td>{{item.p}}</td>
                  <td>{{item.c}}</td>
                  <td>{{item.dtlAmt}}</td>
                  <td>{{item.se}}</td>
                  <td>{{item.sd}}</td>
                  <td>{{item.es}}</td>
                  <td>{{item.er}}</td>
                  <td>{{item.ee}}</td>
                  <td>{{item.ed}}</td>
                </tr>
              </template>
              <tr v-else>
                <td colspan="21" style="text-align:center;padding:20px">暂无数据</td>
              </tr>
            </tbody>
          </table>
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
import mySelect from "@/components/book/select";
export default {
  data() {
    return {
      show: false,
      selectInfo: {
        selectVal: "全部",
        selectOption: [],
        originSelectOption: [
          {
            id: 0,
            name: "全部"
          },
          {
            id: 1,
            name: "优惠"
          },
          {
            id: 2,
            name: "优惠2"
          }
        ]
      },
      keyword: "",
      tableData: [],
      flatTableData: [], // 展平后的表格数据
    };
  },
  methods: {
    // 获取数据
    async getTableData() {
      const params = {
        yh_type: this.selectInfo.originSelectOption.find(item => item.name == this.selectInfo.selectVal).id * 1, //    int      0 全部 1 优惠 2 优惠2
        key: this.keyword, //        string    模糊查询关键字(订台人/优惠人/商品名称)
      }
      try {
        const res = await api_money.reqGetYHList(params);
        if (res.code == 1) {
          this.tableData = res.data.records || []
          this.processFlatTableData();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据获取失败", error);
      }
    },

    // 处理数据：将嵌套结构展平，并标记合并单元格信息
    processFlatTableData() {
      const flatData = [];
      let rowNum = 1; // 序号计数器

      this.tableData.forEach((record) => {
        // record 包含: ad(优惠部门), ae(优惠人), a(优惠金额), dtls(明细数组)
        const dtls = record.dtls || [];
        const groupRowspan = dtls.length; // 该组需要合并的行数

        dtls.forEach((dtl, dtlIndex) => {
          flatData.push({
            // 序号
            rowNum: rowNum++,
            // 合并单元格标识
            isFirstInGroup: dtlIndex === 0, // 是否是分组的第一行
            groupRowspan: groupRowspan, // 合并的行数
            // 优惠部门、优惠人、优惠金额（来自父级record）
            ad: record.ad || '',
            ae: record.ae || '',
            a: record.a || '',
            // 明细字段（来自dtl）
            rn: dtl.rn || '', // 区域名称
            s: dtl.s || '',   // 卡台名称
            o: dtl.o || '',   // 优惠操作时间
            t: dtl.t || '',   // 优惠类型
            r: dtl.r || '',   // 优惠理由
            on: dtl.on || '', // 商品一级分类
            tn: dtl.tn || '', // 商品二级分类
            n: dtl.n || '',   // 商品名称
            p: dtl.p || '',   // 商品单价
            c: dtl.c || '',   // 优惠数量
            dtlAmt: dtl.a || '', // 优惠金额小计（明细中的a字段）
            se: dtl.se || '', // 订位人
            sd: dtl.sd || '', // 订位部门
            es: dtl.es || '', // 优惠2关联功能台
            er: dtl.er || '', // 优惠2关联功能台区域
            ee: dtl.ee || '', // 优惠2订位人
            ed: dtl.ed || '', // 优惠2订位人部门
          });
        });
      });

      this.flatTableData = flatData;
    },

    
    resetHandle() {
      this.keyword = "";
      this.selectInfo.selectVal = "全部";
      this.getTableData();
    },

    // 导出excel
    async exportExcel() {
      const params = {
        yh_type: this.selectInfo.originSelectOption.find(item => item.name == this.selectInfo.selectVal).id * 1, //    int      0 全部 1 优惠 2 优惠2
        key: this.keyword, //        string    模糊查询关键字(订台人/优惠人/商品名称)
      }

      try {
        const res = await api_money.reqExportYHListReport(params);
        if (!res.msg) {
          const url = window.URL.createObjectURL(
            new Blob([res], {
              type:
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            })
          );
          const a = document.createElement("a"); //添加a标签
          document.body.appendChild(a);
          a.href = url;
          a.setAttribute("download", decodeURIComponent(res.fileName)); // 下载文件的名称及文件类型后缀
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
      this.$emit("showOrHideYHDetailDrawer");
    },


    
    /*
    筛选下拉框相关 start
    */
    setSelectValHandle(info) {
      this.selectInfo.selectVal = info.name;
    },
    selectBlurHandle() {
      this.selectInfo.selectOption = [];
    },
    getOptionHandle() {
      this.selectInfo.selectOption = JSON.parse(
        JSON.stringify(this.selectInfo.originSelectOption)
      );
    }
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    }
  },
  components: {
    mySelect
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      newVal ? this.resetHandle() : "";
    }
  }
};
</script>

<style scoped lang="less">
@import "../../style/money/drawerYHDetail.less";
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>