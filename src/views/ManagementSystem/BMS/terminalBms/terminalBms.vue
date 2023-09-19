<template>
  <div class="terminal">
    <div class="coll" layout="row" layout-align="start center">
      <div class="label">终端类型：</div>
      <div class="value" style="margin: 0 10px">
        <el-select size="small" v-model="deviceType" placeholder="请选择">
          <el-option v-for="(item, index) in typeList" :key="index" :label="item.n" :value="item.id"></el-option>
        </el-select>
      </div>
      <div class="label">状态</div>
      <div class="value" style="margin: 0 10px">
        <el-select size="small" v-model="status" placeholder="请选择">
          <el-option label="全部" :value="0"></el-option>
          <el-option label="有效" :value="1"></el-option>
          <el-option label="无效" :value="2"></el-option>
        </el-select>
      </div>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button type="info" size="small" @click="resetHandle">重置</el-button>
    </div>
    <div class="bar">
      <icon-button @click.native="clearBindHandle" text="批量清除绑定" img="btn_delete.png" colors="#6B2830"></icon-button>
    </div>
    <!-- 表格 -->
    <div class="table-content">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">
              <el-checkbox v-model="checkedAll" :indeterminate="indeterminate"
                @change="changeCheckboxHandle('all')">序号</el-checkbox>
            </div>
            <div class="th">终端名称</div>
            <div class="th">终端类型</div>
            <div class="th">终端授权码</div>
            <div class="th">打印机名称</div>
            <div class="th">状态</div>
            <div class="th">使用状态</div>
            <div class="th">操作</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" :class="{ selected: item.checked, gray: item.s == '无效' }" layout="row"
            layout-align="space-between center" v-for="(item, index) in tableData" :key="item.id">
            <div class="td">
              <el-checkbox v-model="item.checked" @change="changeCheckboxHandle('item')">{{ index + 1 }}</el-checkbox>
            </div>
            <div class="td">{{ item.n }}</div>
            <div class="td">{{ item.t }}</div>
            <div class="td">{{ item.c }}</div>
            <div class="td">{{ item.pn || "---" }}</div>
            <div class="td">{{ item.s }}</div>
            <div class="td">{{ item.u == 1 ? "已使用" : "未使用" }}</div>
            <div class="td" layout="row" layout-align="start center">
              <span style="width: 80px" v-if="item.ti == 1">---</span>
              <el-link style="width: 80px" v-else type="primary" :underline="false"
                @click="showOrHidePrintConfig($event, item)">配置打印机</el-link>
              <el-link style="width: 80px" type="primary" :underline="false"
                @click="showOrHideQRHandle($event, item)">授权快捷码</el-link>
              <el-link style="width: 100px" type="primary" :underline="false"
                @click="configAreaOrSeatHandle($event, item)">配置区域/卡台</el-link>
            </div>
          </div>
          <div class="no-data m-b-10" v-if="tableData.length == 0">
            <img class="p-t-10 m-t-10 m-b-4" src="../../../../assets/img/wu.png" alt />
            <div>暂无数据</div>
          </div>
        </div>
      </div>
    </div>

    <!-- 配置打印机 -->
    <div class="dialogPrinter" v-show="showDrawer">
      <el-dialog :title="title" :visible.sync="showDrawer" @close="showDrawer = false" :close-on-click-modal="false">
        <el-form label-position="left">
          <div class="compatibil">
            <div class="compatibility" layout="row" layout-align="start center" v-if="currentInfo.t != '存酒仓库'">
              <div class="mandatory m-r-3">
                <span style="color: #ce4153">*</span>打印机
              </div>
              <el-select v-model="printVal" class="controlling">
                <el-option label="请选择打印机" value="0"></el-option>
                <el-option v-for="item in printOption" :key="item.id" :label="item.n" :value="item.id + ''"></el-option>
              </el-select>
            </div>
            <div v-else>
              <div class="compatibility" layout="row" layout-align="start center">
                <div class="mandatory m-r-3">
                  存酒小票打印机
                </div>
                <el-select v-model="saveWinePrintVal" class="controlling">
                  <el-option label="请选择打印机" value="0"></el-option>
                  <el-option v-for="item in saveWinePrintOption" :key="item.id" :label="item.n" :value="item.id + ''"></el-option>
                </el-select>
              </div>
              <div class="compatibility" layout="row" layout-align="start center" style="margin-top: 16px;">
                <div class="mandatory m-r-3">
                  取酒小票打印机
                </div>
                <el-select v-model="printVal" class="controlling">
                  <el-option label="请选择打印机" value="0"></el-option>
                  <el-option v-for="item in printOption" :key="item.id" :label="item.n" :value="item.id + ''"></el-option>
                </el-select>
              </div>
            </div>
            <div style="color: #ce4153; line-height: 24px" v-if="currentInfo.t == '点单机' || currentInfo.t == '点单机和收银台'
              ">
              用于下单打印消费单
            </div>
            <div style="color: #ce4153; line-height: 24px" v-if="currentInfo.t == '收银台' || currentInfo.t == '点单机和收银台'
              ">
              用于收银台打印消费单、结算单、退单小票、班结表、售出日报表等
            </div>
            <div style="color: #ce4153; line-height: 24px" v-if="currentInfo.t == '咨客台'">
              说明：用于清台打印结算单
            </div>
            <div style="color: #ce4153; line-height: 24px" v-if="currentInfo.t == '存酒仓库'">
              说明：都不配置增存取酒不打印小票
            </div>
          </div>
        </el-form>
        <span slot="footer" style="display: block; text-align: center">
          <el-button @click="showOrHidePrintConfig">取消</el-button>
          <el-button type="primary" @click="submitHandle">确认</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 授权快捷码 -->
    <div class="dialogPrinter" v-show="showTerminalCodeDrawer">
      <el-dialog title="授权快捷码" :visible.sync="showTerminalCodeDrawer" @close="showTerminalCodeDrawer = false"
        :close-on-click-modal="false">
        <div style="
            height: calc(100vh - 200px);
            padding: 60px 30px;
            box-sizing: border-box;
          " layout="column" layout-align="start start">
          <div layout="row" layout-align="center center">
            <p>快捷码：</p>
            <p class="m-l-3 m-r-3">{{ textValue }}</p>
            <el-link style="width: 70px" type="primary" :underline="false" v-clipboard:copy="textValue"
              v-clipboard:success="copySuccessHandle">复制快捷码</el-link>
          </div>
          <p style="color: red; margin-top: 30px">
            提示：当前快捷码有效期为1小时
          </p>
        </div>
        <span slot="footer" class="dialog-footer" style="display: block; text-align: center">
          <el-button @click="showTerminalCodeDrawer = false">关闭</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 配置区域/卡台 -->
    <drawerChooseAreaOrSeat v-model="showChooseAreaOrSeatDrawer" :currentInfo="currentInfo"
      @getTableData="getTableData" />
  </div>
</template>

<script>
import IconButton from "@/components/IconButton.vue";
export default {
  data() {
    return {
      tableData: [{ id: 0, n: "全部" }],
      typeList: [],
      deviceType: 0,
      status: 0,
      checkedAll: false,
      showDrawer: false,
      printVal: "0",
      printOption: [], // 普通打印机
      saveWinePrintVal: "0", // 存酒打印机
      saveWinePrintOption:[], // 存酒打印机
      currentInfo: {}, // 当前操作的终端单条数据

      showTerminalCodeDrawer: false,
      textValue: "test", // 快捷码

      showChooseAreaOrSeatDrawer: false,
    };
  },
  methods: {
    resetHandle() {
      this.deviceType = 0;
      this.status = 0;
      this.getTableData();
    },
    async getTableData() {
      try {
        const params = {
          license_type: this.deviceType, //设备类型 0 代表全部
          status: this.status, // 状态 1 有效 2 无效 0 全部
        };
        const res = await this.$api.BMS.terminal.reqGetTerminalList(params);
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map((item) => ({
            ...item,
            checked: false,
          }));
          this.typeList = [{ id: 0, n: "全部" }, ...res.data.license_types] || [
            { id: 0, n: "全部" },
          ];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("日志列表获取失败", error);
      }
    },
    async getSelectOption() {
      try {
        const res = await this.$api.BMS.terminal.reqGetTerminalPrintList();
        res.code == 1
          ? (this.printOption = res.data.records || [])
          : this.$message.warning(res.msg);

        const res1 = await this.$api.BMS.terminal.reqGetTerminalSaveWinePrintList();
        res1.code == 1
          ? (this.saveWinePrintOption = res1.data.records || [])
          : this.$message.warning(res1.msg);
      } catch (error) {
        console.log("获取终端打印机列表失败", error);
      }
    },

    showOrHidePrintConfig(e, itemInfo) {
      this.showDrawer = !this.showDrawer;
      if (itemInfo) {
        this.printVal = itemInfo.pi.toString();
        this.saveWinePrintVal = itemInfo.spi.toString() || '0';
        this.currentInfo = { ...itemInfo };
        this.getSelectOption();
      }
    },

    async submitHandle() {
      const params = {
        id: this.currentInfo.id * 1, //   int64    终端Id
        prt_id: this.printVal * 1, //  int64   打印机Id, =0表示删除
        wine_store_prt_id: this.saveWinePrintVal * 1, //  int64   存酒打印机Id, =0表示删除
      };
      try {
        const res = await this.$api.BMS.terminal.reqSaveTerminalConfig(params);
        if (res.code == 1) {
          this.$message.success("保存成功");
          this.showOrHidePrintConfig();
          this.getTableData();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("保存打印机配置失败", error);
      }
    },

    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData = this.tableData.map((item) => ({
            ...item,
            checked: this.checkedAll,
          }));
          break;
        case "item":
          this.checkedAll = this.tableData.every((item) => item.checked);
          break;
      }
    },

    async clearBindHandle() {
      const ids = this.tableData
        .filter((item) => item.checked)
        .map((item) => item.id * 1);
      if (ids.length == 0)
        return this.$message.warning("请选择需要清除绑定的终端");
      const params = {
        ids, //   []int64  授权码Id列表
      };
      try {
        const res = await this.$api.BMS.terminal.reqClearTerminal(params);
        if (res.code == 1) {
          this.$message.success("操作成功");
          this.getTableData();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("批量清除绑定失败", error);
      }
    },

    /*
      授权码相关
    */

    // 复制授权码
    copySuccessHandle() {
      this.$message.success("复制成功");
    },

    async getTextVal(authCode) {
      const params = {
        auth_code: authCode, //  string   注册码
      };
      try {
        const res = await this.$api.BMS.terminal.reqGetTerminalCode(params);
        if (res.code == 1) {
          this.textValue = res.data.code || "";
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("快捷码回去失败", error);
      }
    },

    // 打开快捷码
    showOrHideQRHandle(e, itemInfo) {
      this.showTerminalCodeDrawer = !this.showTerminalCodeDrawer;
      this.getTextVal(itemInfo.c);
    },

    // 打开配置区域/卡台
    configAreaOrSeatHandle(e, itemInfo) {
      this.currentInfo = { ...itemInfo };
      this.showChooseAreaOrSeatDrawer = true;
    },
  },
  mounted() {
    this.getTableData();
  },
  computed: {
    title() {
      return "配置" + this.currentInfo.t + "打印机";
    },
    indeterminate() {
      return !this.checkedAll && this.tableData.some((item) => item.checked);
    },
  },

  components: {
    IconButton,
    drawerChooseAreaOrSeat: () => import("./drawerChooseAreaOrSeat.vue"),
  },
};
</script>

<style lang="less">
@import "../../../../style/erp/table.less";
</style>
<style scoped lang="less">
.terminal {
  padding: 10px 20px;
  font-size: 14px;

  .bar {
    width: 100%;
    height: 54px;
    // background-color: #eee;
    display: flex;
    align-items: center;
  }

  .table {
    width: 100%;
    max-height: calc(100vh - 220px);
    overflow: auto;

    .tr {
      min-width: 1200px;
      line-height: 36px;
      padding: 0 10px;
      box-sizing: border-box;
    }

    .thead {
      position: sticky;
      top: 0;
      background-color: #f5f5f5;
      z-index: 999;

      .tr {
        background-color: #f5f5f5;
      }

      .th {
        font-weight: 600;
      }
    }

    .tbody {
      .tr:nth-child(2n + 1) {
        background-color: #f9f9f9;
      }

      .tr:nth-child(2n) {
        background-color: #f5f5f5;
      }

      .no-data {
        img {
          width: 60px;
        }

        text-align: center;
      }
    }

    .td,
    .th {
      line-height: 20px;
    }

    .th:nth-child(1),
    .td:nth-child(1) {
      width: 6%;
    }

    .th:nth-child(2),
    .td:nth-child(2) {
      width: 15%;
    }

    .th:nth-child(3),
    .td:nth-child(3) {
      width: 10%;
    }

    .th:nth-child(4),
    .td:nth-child(4) {
      width: 20%;
    }

    .th:nth-child(5),
    .td:nth-child(5) {
      width: 10%;
    }

    .th:nth-child(6),
    .td:nth-child(6) {
      width: 8%;
    }

    .th:nth-child(7),
    .td:nth-child(7) {
      width: 8%;
    }

    .th:nth-child(8),
    .td:nth-child(8) {
      width: 21%;
    }
  }
}

/deep/.el-checkbox__label {
  font-weight: 600;
}
</style>

<style>
.terminal .dialogPrinter .el-dialog {
  width: 720px;
  float: right;
  margin-top: 0 !important;
  margin-bottom: 0;
}

.terminal .dialogFormVisible .el-dialog {
  width: 50vw !important;
  min-width: 420px !important;
  max-width: 440px !important;
}

.terminal .el-dialog__body {
  height: calc(100vh - 160px);
}
</style>
