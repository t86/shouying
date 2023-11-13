<template>
  <!-- 调拨入库 -->
  <div class="empty-lib-order">
    <div class="top">
      <div layout="row" layout-align="start center">
        <span class="label fs14">入库日期：</span>
        <ul class="time-select fs14 m-r-1" layout="row" layout-align="start center">
          <li layout="row" layout-align="start center" @click="setDateVal(1)">
            <img
              :src="activeTime == 1 ? require('@/assets/img/date_label_selete.png') : require('@/assets/img/date_label_grey.png')"
              alt />
            <span :class="{ active: activeTime == 1 }">近7天</span>
          </li>
          <li layout="row" layout-align="start center" @click="setDateVal(2)">
            <img
              :src="activeTime == 2 ? require('@/assets/img/date_label_selete.png') : require('@/assets/img/date_label_grey.png')"
              alt />
            <span :class="{ active: activeTime == 2 }">近30天</span>
          </li>
          <li layout="row" layout-align="start center" @click="setDateVal(3)">
            <img
              :src="activeTime == 3 ? require('@/assets/img/date_label_selete.png') : require('@/assets/img/date_label_grey.png')"
              alt />
            <span :class="{ active: activeTime == 3 }">近90天</span>
          </li>
        </ul>
        <div class="value m-r-2">
          <el-date-picker style="width:140px" v-model="begin_day" type="date" :clearable="false" size="small"
            value-format="yyyy-MM-dd" placeholder="开始日期"></el-date-picker>
          <span>至</span>
          <el-date-picker style="width:140px" v-model="end_day" type="date" :clearable="false" size="small"
            value-format="yyyy-MM-dd" placeholder="结束日期"></el-date-picker>
        </div>
        <span class="label fs14 m-l-2">入库仓库：</span>
        <el-select v-model="inLibVal" size="small" style="width:120px">
          <el-option label="全部" :value='0'></el-option>
          <el-option v-for="(item, i) in inLibOption" :key="i" :label="item.n" :value="item.id"></el-option>
        </el-select>
        <span class="label fs14 m-l-2">订单类型：</span>
        <el-select v-model="orderVal" size="small" style="width:120px">
          <el-option label="全部" :value="0"></el-option>
          <el-option label="销售出库" :value="11"></el-option>
          <el-option label="调拨出库" :value="3"></el-option>
          <el-option label="其他出库" :value="17"></el-option>
          <el-option label="报损出库" :value="62"></el-option>
        </el-select>
      </div>
      <div class="m-t-2" layout="row" layout-align="start center">
        <span class="label fs14 m-l-2">一级分类：</span>
        <el-select v-model="oneCateVal" size="small" style="width:120px">
          <el-option label="全部" :value='0'></el-option>
          <el-option v-for="(item, i) in oneCateOption" :key="i" :label="item.n" :value="item.id"></el-option>
        </el-select>
        <span class="label fs14 m-l-2">二级分类：</span>
        <el-select v-model="twoCateVal" size="small" style="width:120px">
          <el-option label="全部" :value='0'></el-option>
          <el-option v-for="(item, i) in twoCateOption" :key="i" :label="item.n" :value="item.id"></el-option>
        </el-select>

        <span class="label fs14 m-l-3">备注：</span>
        <el-input v-model="remark" size="small" style="width:200px" placeholder="物料名称或简写"></el-input>

        <el-button class="m-l-4" type="primary" size="small" @click="getTableData">查询</el-button>
        <el-button size="small" @click="resetHandle">重置</el-button>
        <el-button type="primary" size="small" @click="exportExcelHandle">导出Excel</el-button>
      </div>
    </div>

    <div class="table-content m-t-3">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">序号</div>
            <div class="th">订单类型</div>
            <div class="th">出库仓库</div>
            <div class="th">物料名称</div>
            <div class="th">一级分类</div>
            <div class="th">二级分类</div>
            <div class="th">出库单位</div>
            <div class="th">出库数量</div>
            <div class="th">出库成本小计</div>
            <div class="th">出库小计</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" layout="row" layout-align="space-between center" v-for="(item, index) in tableData"
            :key="item.id">
            <div class="td">{{ index + 1 }}</div>
            <div class="td">{{ item.rt }}</div>
            <div class="td">{{ item.osn }}</div>
            <div class="td">{{ item.n }}</div>
            <div class="td">{{ item.moc }}</div>
            <div class="td">{{ item.mtc }}</div>
            <div class="td">{{ item.un }}</div>
            <div class="td">{{ item.oc }}</div>
            <div class="td">{{ item.oa }}</div>
            <div class="td">{{ item.sa }}</div>
          </div>
          <div class="no-data" v-if="tableData.length == 0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      activeTime: 1, // 1：近7天  2：近30天  3：近3个月
      begin_day: "",
      end_day: "",
      inLibVal: 0,  // 入库仓库
      inLibOption: [], // 出库仓库option
      orderVal: 0,
      orderOption: [],
      oneCateVal: 0,
      oneCateOption: [],
      twoCateVal: 0,
      twoCateOption: [],
      remark: '',
      checkAll: false,
      tableData: []
    };
  },
  methods: {
    async getOptions() {
      try {
        const res = await this.$api.ERP.rpt_erp.requestrpt_erpparam_items()
        if (res.code == 1) {
          this.inLibOption = res.data.stores || []
          this.oneCateOption = res.data.cates || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取options数据失败', error);
      }
    },
    async getTableData() {
      const params = {
        begin_day: this.begin_day, //  string  入库开始日期 格式  yyyy-mm-dd
        end_day: this.end_day, //    string  入库结束日期 格式 yyyy-mm-dd
        out_store_id: this.inLibVal * 1, //   int64   入库仓库 ,0 表示不限制
        record_type: this.orderVal * 1, // int  订单类型 0 代表不限制  1 采购入库  7  其他入库  3 调拨入库
        mat_one_cate_id: this.oneCateVal * 1, // int64  物料一级分类id , 0 代表不限制
        mat_two_cate_id: this.twoCateVal * 1, // int64  物料二级分类id, 0 代表不限制
        name: this.remark || '', //       string   模糊查询关键字, 物料名称或简称 , 空, 表示不限制
      };

      try {
        const res = await this.$api.ERP.rpt_erp.requestrpt_erpout_sum(params);
        if (res.code == 1) {
          this.tableData = res.data || []
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据获取失败", error);
      }
    },

    async exportExcelHandle() {
      const params = {
        begin_day: this.begin_day, //  string  入库开始日期 格式  yyyy-mm-dd
        end_day: this.end_day, //    string  入库结束日期 格式 yyyy-mm-dd
        out_store_id: this.inLibVal * 1, //   int64   入库仓库 ,0 表示不限制
        record_type: this.orderVal * 1, // int  订单类型 0 代表不限制  1 采购入库  7  其他入库  3 调拨入库
        mat_one_cate_id: this.oneCateVal * 1, // int64  物料一级分类id , 0 代表不限制
        mat_two_cate_id: this.twoCateVal * 1, // int64  物料二级分类id, 0 代表不限制
        name: this.remark || '', //       string   模糊查询关键字, 物料名称或简称 , 空, 表示不限制
      };
      try {
        const res = await this.$api.ERP.rpt_erp.reqExportOutLibAllRpt(params)
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

    getDate(dateNum = +new Date()) {
      const date = new Date(dateNum);
      const year = date.getFullYear();
      const month = (date.getMonth() + 1).toString().padStart(2, 0);
      const day = date
        .getDate()
        .toString()
        .padStart(2, 0);
      return year + "-" + month + "-" + day;
    },

    setDateVal(activeTime) {
      this.activeTime = activeTime;
      const dayInfo = {
        "1": 7,
        "2": 30,
        "3": 90
      };
      const oneDay = +new Date("2023/05/24") - +new Date("2023/05/23");
      const begin = this.getDate(+new Date() - oneDay * dayInfo[activeTime]);
      const end = this.getDate();
      this.begin_day = begin;
      this.end_day = end;
      this.getTableData();
    },

    resetHandle() {
      this.inLibVal = 0
      this.orderVal = 0
      this.oneCateVal = 0
      this.twoCateVal = 0
      this.remark = ''
      this.getOptions()
      this.setDateVal(1);
    }
  },
  created() {
    this.resetHandle();
  },
  watch: {
    oneCateVal(newVal) {
      const oneCateInfo = this.oneCateOption.find(item => item.id == newVal)
      if (find) {
        this.twoCateOption = oneCateInfo.ss || []
      } else {
        this.twoCateOption = []
      }
      this.twoCateVal = 0
    }
  }
};
</script>

<style lang="less" scoped>
@import "../../../../style/erp/table.less";
</style>
<style scoped lang="less">
.empty-lib-order {
  padding: 20px;

  .top {
    .order-status {
      li {
        padding: 6px 12px;
        border-radius: 6px;
        margin-right: 6px;
        border: 1px solid transparent;

        &.active {
          border: 1px solid #2170ff;
        }
      }
    }

    .time-select {
      li {
        cursor: pointer;
        margin-right: 16px;

        img {
          width: 12px;
          margin-right: 6px;
        }

        span {
          &.active {
            color: #2170ff;
          }
        }
      }
    }
  }

  .table-content {
    width: 100%;
    height: calc(100vh - 220px);
    overflow: auto;

    .table {

      .th,
      .td {
        &:nth-child(1) {
          width: 30%;
        }
      }
    }
  }
}
</style>

<style>
/* 日期选择器 */
.el-date-picker__header-label {
  color: #1a1a21;
}

.el-date-table th,
.el-picker-panel__content {
  color: #1a1a21;
}

.el-range-editor--small .el-range-input {
  background-color: transparent;
}
</style>