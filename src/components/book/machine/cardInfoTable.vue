<template>
  <div class="card-info-table">
    <!-- 翻台订位人 -->
    <div class="turn-over" v-if="formStatus==4">
      <div class="table" v-if="subStatus==1">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">序号</div>
            <div class="th">卡台</div>
            <div class="th">预定时间</div>
            <div class="th">开台时间</div>
            <div class="th">订位人</div>
            <div class="th">订位人联系方式</div>
            <div class="th">联合订位人</div>
            <div class="th">联合订位人联系方式</div>
            <div class="th">操作</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            layout="row"
            layout-align="space-between center"
            v-for="(item, index) in tableData"
            :key="index"
          >
            <div class="td">{{index + 1}}</div>
            <div class="td">{{item.cardName}}</div>
            <div class="td">{{item.bt}}</div>
            <div class="td">{{item.ot}}</div>
            <div class="td">{{item.saleName}}</div>
            <div class="td">{{item.salePhone}}</div>
            <div class="td">{{item.secondSaleName}}</div>
            <div class="td">{{item.secondSalePhone}}</div>
            <div class="td">
              <span
                style="color: #09f;cursor:pointer;"
                @click="changeSubStatusHandle(2, item)"
              >修改订位人</span>
            </div>
          </div>
        </div>
        <div v-if="tableData.length == 0" class="no-data">暂无数据</div>
      </div>
      <!-- 修改翻台订位人 -->
      <el-form
        @submit.native.prevent
        v-if="subStatus==2"
        label-position="right"
        label-width="150px"
        :model="formData"
        ref="drawerRef"
      >
        <el-form-item label="台号">
          <div class="white">{{formData.cardName}}</div>
        </el-form-item>
        <el-form-item label="预定时间">
          <div class="white">{{formData.reservedTime}}</div>
        </el-form-item>
        <el-form-item label="开台时间">
          <div class="white">{{formData.openTime}}</div>
        </el-form-item>
        <el-form-item label="订位人" class="required required3">
          <input-select
            style="width:80%"
            :value="formData.saleName"
            placeholder="请输入姓名或工号"
            :optionsList="formData.saleOption"
            @selectInputHandle="inputSealName"
            @selectOptionItem="changeSealName"
            @selectBlurHandle="selectBlurHandle"
          ></input-select>
        </el-form-item>
        <el-form-item label="订位人电话">
          <el-input v-model="formData.salePhone" disabled style="width:80%;"></el-input>
        </el-form-item>
        <el-form-item label="联合订位人">
          <input-select
            style="width:80%"
            :value="formData.secondSaleName"
            placeholder="请输入姓名或工号"
            :optionsList="formData.secondSaleOption"
            @selectInputHandle="inputSecondSealName"
            @selectOptionItem="changeSecondSealName"
            @selectBlurHandle="selectBlurHandle"
          ></input-select>
        </el-form-item>
        <el-form-item label="联合订位人电话">
          <el-input v-model="formData.secondSalePhone" disabled style="width:80%;"></el-input>
        </el-form-item>
        <el-form-item label="修改理由" class="required required4">
          <el-input
            type="textarea"
            :rows="2"
            placeholder="请输入修改理由"
            v-model="formData.reason"
            style="width:80%"
          ></el-input>
        </el-form-item>
      </el-form>
    </div>

    <!-- 查看卡台消费记录 -->
    <!-- <div class="consume-list" v-if="formStatus==3">
      <h1>卡座区  K01</h1>
      <div class="top-tab">
        <ul
          :class="{'overflow':!turnOverInfo.turnOverTabShow}"
          ref="turnOverTabRef"
          layout="row"
          layout-align="start start"
        >
          <li
            :class="{'active': turnOverInfo.activeTurnOverCount==item.id}"
            v-for="(item,index) in turnOverInfo.turnOverTabList"
            :key="index"
            @click.stop="changeTab('turnOverCount',item.id)"
          >{{item.name}}</li>
        </ul>
      </div>
    </div> -->

    <div class="form-btn" layout="row" layout-align="center center">
      <el-button type="info" @click="onCancelDrawer">取消</el-button>
      <el-button type="primary" v-if="formStatus==4 && subStatus == 2" @click="onSubmit">确认</el-button>
    </div>
  </div>
</template>
 
<script>
import api_card from "@/api/Book";
import common_book from "@/utils/common/book";
import inputSelect from "@/components/book/inputSelect";
export default {
  data() {
    return {
      tableData: [],
      subStatus: 1, // 内部切换
      formData: {
        id: "", // 操作流水记录id
        cardName: "",
        reservedTime: "",
        openTime: "",
        saleName: "",
        salePhone: "",
        saleId: "",
        saleOptions: [],
        secondSaleName: "",
        secondSalePhone: "",
        secondSaleId: "",
        secondSaleOption: [],
        reason: ""
      },
      // 查看卡台消费记录中的翻台tab
      turnOverInfo: {
        turnOverTabList: [1,2,3],
        activeTurnOverCount: 1,
        turnOverTabShow: false
      },
    };
  },
  methods: {
    async getTurnOverList() {
      const params = {
        id: this.cardInfo.id * 1 //   int64   待操作卡台Id
      };
      try {
        const res = await api_card.reqGetTurnOverList(params);
        if (res.code == 1) {
          res.data = res.data || [];
          res.data.forEach(el => {
            const saleInfo = common_book.getOrderPersonInfo(el.si);
            const secondSaleInfo = common_book.getOrderPersonInfo(el.ssi);
            el.cardName = this.cardInfo.name;
            el.saleName = saleInfo ? saleInfo.name : "";
            el.salePhone = saleInfo ? saleInfo.phoneNum : "";
            el.secondSaleName = secondSaleInfo ? secondSaleInfo.name : "";
            el.secondSalePhone = secondSaleInfo ? secondSaleInfo.phoneNum : "";
          });

          this.tableData = [...res.data];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取翻台订位人历史列表失败", error);
      }
    },

    changeSubStatusHandle(status = 1, itemInfo) {
      this.subStatus = status;
      if (this.formStatus == 4 && status == 2 && itemInfo)
        // 修改翻台订位人
        this.formData = {
          id: itemInfo.id,
          cardName: itemInfo.cardName,
          reservedTime: itemInfo.bt,
          openTime: itemInfo.ot,
          saleName: itemInfo.saleName,
          salePhone: itemInfo.salePhone,
          saleId: itemInfo.si,
          saleOptions: [],
          secondSaleName: itemInfo.secondSaleName,
          secondSalePhone: itemInfo.secondSalePhone,
          secondSaleId: itemInfo.ssi,
          secondSaleOption: [],
          reason: ""
        };
    },

    /*
     *订位人
     */
    // 获取模糊查询订位人的相关信息
    inputSealName(query) {
      this.formData.saleName = query;
      this.formData.salePhone = "";
      this.formData.saleId = "";
      const sealInfoArr = this.$store.state.cardPageInfo.resResultDataObj
        .orderPersonInfo;
      const results = query
        ? sealInfoArr.filter(
            el =>
              el.code.toString().startsWith(query) ||
              el.name.toString().startsWith(query) ||
              el.namePy.toString().startsWith(query.toLowerCase())
          )
        : sealInfoArr;
      this.formData.saleOption = results;
    },
    // 选择订位人的信息
    changeSealName(info) {
      this.formData.saleName = info.name;
      this.formData.salePhone = info.phoneNum;
      this.formData.saleId = info.id;
      this.formData.saleOption = [];
    },
    // 获取模糊查询联合订位人的相关信息
    inputSecondSealName(query) {
      this.formData.secondSaleName = query;
      this.formData.secondSalePhone = "";
      this.formData.secondSaleId = "";
      const sealInfoArr = this.$store.state.cardPageInfo.resResultDataObj
        .orderPersonInfo;
      const results = query
        ? sealInfoArr.filter(
            el =>
              el.code.toString().startsWith(query) ||
              el.name.toString().startsWith(query) ||
              el.namePy.toString().startsWith(query.toLowerCase())
          )
        : sealInfoArr;
      this.formData.secondSaleOption = results;
    },
    // 选择联合订位人的信息
    changeSecondSealName(info) {
      this.formData.secondSaleName = info.name;
      this.formData.secondSalePhone = info.phoneNum;
      this.formData.secondSaleId = info.id;
      this.formData.secondSaleOption = [];
    },

    selectBlurHandle() {
      this.formData.saleOption = [];
      this.formData.secondSaleOption = [];
    },

    async onSubmit() {
      const params = {
        id: this.cardInfo.id * 1, //  int64  待操作卡台Id
        csm_id: this.formData.id * 1, //     int64   待操作流水记录Id
        sales_emp_id: this.formData.saleId * 1, // int64      //SalesEmpId 订位人Id
        second_sales_emp_id: this.formData.secondSaleId * 1, // int64      //SecondSalesEmpId 联合订位人Id
        reason: this.formData.reason //     string     //Reason 理由
      };

      if(!params.sales_emp_id) return this.$message.warning('请选择订位人！')
      if(!params.reason) return this.$message.warning('请输入修改理由！')

      try {
        const res = await api_card.reqUpdateTurnOverDetail(params);
        if (res.code == 1) {
          this.$message.success("修改成功！");
          this.$emit("closeDrawerHandle");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("修改翻台订位人失败", error);
      }
    },

    onCancelDrawer() {
      if (this.subStatus == 2) return (this.subStatus = 1);
      this.$emit("closeDrawerHandle");
    }
  },
  created() {
    this.getTurnOverList();
  },
  props: {
    show: {
      required: true,
      default: false
    },
    formStatus: {
      required: true,
      default: 3 // 所选选项的表单状态
      //  3：查看卡台消费 4：修改翻台订位人
    },
    cardInfo: {
      default: {}
    }
  },
  components: {
    inputSelect
  },
  watch: {
    show(newVal) {
      if (newVal) {
        if (this.formStatus == 4) {
          this.getTurnOverList();
          this.subStatus = 1;
        }
      }
    }
  }
};
</script>

<style lang="less" scoped>
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementFormBtn.less";
</style>

<style scoped lang="less">
.card-info-table {
  padding: 0 20px;
  .table {
    width: 100%;
    min-height: 100px;
    overflow: auto;
    font-size: 14px;
    color: #fff;
    .thead {
      position: sticky;
      top: 0;
      z-index: 1;
      .tr {
        background: rgb(30, 33, 39);
        .th:nth-child(9) {
          background-color: rgb(30, 33, 39);
        }
      }
    }

    .tbody {
      max-height: calc(100vh - 240px);
      .tr:nth-child(2n + 1) {
        background-color: #08080a;
        .td:nth-child(9) {
          background-color: #08080a;
        }
      }
      .tr:nth-child(2n) {
        background-color: rgb(19, 21, 26);
        .td:nth-child(9) {
          background-color: rgb(19, 21, 26);
        }
      }
    }

    .tr {
      width: 100%;
      box-sizing: border-box;
      min-width: 1000px;
      line-height: 30px;
      border-bottom: 1px solid rgba(216, 229, 255, 0.1);
      padding: 6px 0px 6px 10px;
      position: relative;
      .th,
      .td {
        padding: 0 5px;
      }
      .th:nth-child(1),
      .td:nth-child(1) {
        width: 50px;
      }
      .th:nth-child(2),
      .td:nth-child(2) {
        width: 50px;
      }
      .th:nth-child(3),
      .td:nth-child(3) {
        width: 140px;
      }
      .th:nth-child(4),
      .td:nth-child(4) {
        width: 140px;
      }
      .th:nth-child(5),
      .td:nth-child(5) {
        width: 100px;
      }
      .th:nth-child(6),
      .td:nth-child(6) {
        width: 120px;
      }
      .th:nth-child(7),
      .td:nth-child(7) {
        width: 100px;
      }
      .th:nth-child(8),
      .td:nth-child(8) {
        width: 140px;
      }
      .th:nth-child(9),
      .td:nth-child(9) {
        width: 80px;
        position: sticky;
        right: 0;
      }
    }
  }

  .no-data {
    font-size: 20px;
    line-height: 80px;
    text-align: center;
    color: #666;
  }
}
</style>

<style scoped lang="less">
  // 查看卡台消费记录
  .top-tab {
    position: relative;
    height: 60px;

    >ul {
      position: absolute;
      z-index: 10;
      padding: 0 8px;
      width: 100%;
      background: rgba(8, 8, 10, .9);
      box-sizing: border-box;
      overflow: hidden;
      flex-wrap: wrap;

      &.overflow {
        height: 60px;
      }

      li {
        position: relative;
        width: 152px;
        height: 36px;
        margin: 12px 7px;
        font-size: 18px;
        font-weight: 500;
        white-space: nowrap;
        text-align: center;
        line-height: 36px;
        background: #0D172D;
        box-shadow: inset 0px 1px 1px 0px #2775BA;
        border-radius: 18px;
        cursor: pointer;

        &:after {
          display: none;
          content: '';
          width: 0px;
          height: 0px;
          border: 10px solid transparent;
          border-top-color: #A9D1FA;
          position: absolute;
          left: 50%;
          bottom: 0px;
          transform: translate(-50%, 18px);
        }

        &.active {
          color: #08080A;
          background: #F8FEFF;
          // background: linear-gradient(180deg, #F8FEFF 0%, #A9D1FA 100%);

          &:after {
            display: block;
          }
        }
      }
    }
  }
</style>