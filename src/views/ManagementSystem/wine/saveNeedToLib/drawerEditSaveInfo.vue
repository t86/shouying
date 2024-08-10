<template>
  <div>
    <!-- 修改存酒入库单 -->
    <el-drawer
      title="编辑"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="800px"
    >
      <div class="session edit-save-info p-5">

        <drawerCardOrder
          v-model="showCardOrderDrawer"
          :productInfo="currentSaveInfo"
          :isFreeEditCard="!isCardBillRelated"
          @onSubmit="onCardOrderSubmit"
        />
        <drawerChgCustomerInfo
        :showDrawer="showChgCustomerInfoDrawer"
        :item="currentSaveInfo"
        @showOrHideDrawerHandle="showOrHideChgCustomerInfoHandle"
        @onSubmit="onCustomerInfoSubmit"
        />
        <drawerChgOrderPerson
        :showDrawer="showChgOrderPersonDrawer"
        :item="currentSaveInfo"
        @showOrHideDrawerHandle="showOrHideChgOrderPersonHandle"
        @onSubmit="onSaveOrderPersonSubmit"
        />
        <drawerChgSaveTime
        :showDrawer="showChgSaveTimeDrawer"
        :item="currentSaveInfo"
        @showOrHideDrawerHandle="showOrHideChgSaveTimeHandle"
        @onSubmit="onSaveTimeSubmit"
        />
        <div class="top grid" layout="row" layout-align="start center">
            <div class="title">营业日</div>
            <div
            >{{ isCardBillRelated ? businessDate : '————' }}</div>
            <el-button v-if="isCardBillRelated" type="primary" @click="changeCardOrder"
            >更改卡台流水</el-button>
            <el-button type="primary" v-if="isCardBillRelated" @click="changeRelatedBill"
            >转为非关联卡台流水</el-button>
            <el-button type="primary" v-else @click="changeRelatedBill"
            >转为关联卡台流水</el-button>
            <div v-if="!isCardBillRelated"></div>

            <div class="title">卡台</div>
            <div>{{ seat.n }}</div>
            <el-button type="primary" v-if="!isCardBillRelated" @click="changeCardOrder">更改卡台</el-button>
            <div v-else></div>
            <div></div>

            <div class="title">订位人</div>
            <div>{{ employee.n }}</div>
            <el-button type="primary" v-if="!isCardBillRelated" @click="changeOrderPerson">更改订位人</el-button>
            <div v-else></div>
            <div></div>

            <div class="title">客人信息</div>
            <div class="name" v-if="isCustomer">{{ custName || ' ' }}</div>
            <div v-else>{{ (custName || '') + "  " + (custPhone || '') }}</div>
            <div class="phone" v-if="isCustomer">{{ custPhone || ' ' }}</div>
            <el-button type="primary" @click="changeCustomerInfo" v-else
            >更改客人信息</el-button>
            <div></div>

            <div class="title">存酒时间</div>
            <div>{{ saveTime }}</div>
            <el-button type="primary" @click="changeSaveTime">更改存酒时间</el-button>


        </div>
        <div class="red fs14 m-t-3 m-b-3">点击散瓶规格可更改</div>
        <!-- 表格 -->
        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">名称</div>
                <div class="th">规格</div>
                <div class="th">每瓶克数</div>
                <div class="th">数量</div>
                <div class="th">有效期</div>
                <div class="th" style="width: 220px">操作</div>
              </div>
            </div>
            <div class="tbody">
              <div
                class="tr"
                layout="row"
                layout-align="space-between center"
                v-for="item in tableData"
                :key="item.id"
              >
                <div class="td">{{ item.n }}</div>
                <div class="td">
                  <div >
                    <el-select
                      v-model="item.u"
                      size="mini"
                      style="width: 100px"
                      placeholder="请选择"
                    >
                      <el-option
                        v-for="item in options"
                        :key="item.value"
                        :label="item.label"
                        :value="item.label"
                      ></el-option>
                    </el-select>
                  </div>
                </div>
                <div class="td">
                  <div v-if="item.u == '整瓶'">-</div>
                  <div v-else>
                    <el-input
                      v-model="item.g"
                      size="mini"
                      style="width: 100px"
                    ></el-input>
                  </div>
                </div>
                <div class="td" layout="row" layout-align="center center">
                  <el-button
                    size="small"
                    style="
                      width: 26px;
                      padding: 0;
                      height: 26px;
                      border-radius: 50%;
                    "
                    icon="el-icon-minus"
                    :disabled="item.c <= 1"
                    @click="item.c = Math.max(1, item.c - 1)"
                  ></el-button>
                  <el-input
                    v-model="item.c"
                    size="mini"
                    style="width: 60px; margin: 0 10px"
                  ></el-input>
                  <el-button
                    size="mini"
                    :disabled="item.a != '-' && item.c >= item.ac"
                    style="
                      width: 26px;
                      padding: 0;
                      height: 26px;
                      border-radius: 50%;
                    "
                    icon="el-icon-plus"
                    @click="item.c++"
                  ></el-button>
                </div>
                <div class="td" layout="row" layout-align="center center">
<!--                  <el-button-->
<!--                    size="small"-->
<!--                    style="-->
<!--                      width: 26px;-->
<!--                      padding: 0;-->
<!--                      height: 26px;-->
<!--                      border-radius: 50%;-->
<!--                    "-->
<!--                    icon="el-icon-minus"-->
<!--                    :disabled="item.expireDays <= 1"-->
<!--                    @click="item.expireDays = Math.max(1, item.expireDays - 1)"-->
<!--                  ></el-button>-->
                  <el-input
                    v-model="item.expireDays"
                    size="mini"
                    disabled
                    style="width: 60px; margin: 0 10px"
                    :class="{ 'custom-color': item.isRed }"
                  ></el-input>
                  <el-button
                    size="mini"
                    style="
                      width: 26px;
                      padding: 0;
                      height: 26px;
                      border-radius: 50%;
                    "
                    icon="el-icon-edit"
                    @click="showSaveWineDays(item)"
                  ></el-button>
                </div>
                <div class="td" style="width: 220px">
                  <span
                    style="color: #2170ff; cursor: pointer"
                    @click="copyHandle(item)"
                    >复制</span
                  >
                  <span
                    style="color: #2170ff; cursor: pointer"
                    @click="deleteHandle(item)"
                    >删除</span
                  >
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center" v-if="isCustomer">
          <div class="label">备注姓名：</div>
          <div class="value">
            <el-input
              type="primary"
              size="small"
              style="width: 260px"
              v-model="remarkName"
              placeholder="请输入备注姓名"
            ></el-input>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center" v-if="isCustomer">
          <div class="label">备注手机号：</div>
          <div class="value">
            <el-input
              type="primary"
              size="small"
              style="width: 260px"
              v-model="remarkPhone"
              placeholder="请输入备注手机号"
            ></el-input>
          </div>
        </div>
      </div>
      <!-- 授权 -->
      <authCom
        ref="authRef"
        v-model="showAuthDrawer"
        :tableData="tableData"
        @emitHandle="submitSureHandle"
      />

      <el-dialog
        title="提示"
        :visible.sync="dialogVisible"
        append-to-body
        width="30%"
      >
        <p>确认入库吗？</p>
        <span slot="footer" class="dialog-footer">
          <el-button @click="dialogVisible = false">取 消</el-button>
          <el-button type="primary" @click="onSubmit">确 定</el-button>
        </span>
      </el-dialog>

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="showAuthHandle">{{
          needWaiterAuth ? "服务员授权" : "确认修改信息"
        }}</el-button>
      </div>

      <div>
        <Slider :visible="sliderVisible" style="width: 80%; text-align: center" v-if="sliderVisible"  :options="[1, 30, 60, 90, 150, 300, 500]" :current="selectedSaveWineItem.expireDays" @confirm="handleConfirm" @cancel="handleCancel" />
      </div>



    </el-drawer>
  </div>
</template>

<script>
import api_wine from "@/api/wine";
import authCom from "../commonCom/auth.vue";
import drawerCardOrder from './saveWineOrder/index.vue'
import drawerChgCustomerInfo from './drawerChgCustomerInfo.vue'
import drawerChgSaveTime from './drawerChgSaveTime.vue'
import drawerChgOrderPerson from "./drawerChgOrderPerson.vue";
import Slider from "@/components/slider2";


export default {
  data() {
    return {
      selectedSaveWineItem: {},
      sliderVisible: false,

      isCardBillRelated: true,
      showCardOrderDrawer: false,
      showChgCustomerInfoDrawer: false,
      showChgSaveTimeDrawer: false,
      showChgOrderPersonDrawer: false,
      dialogVisible: false,
      tableData: [],
      showAuthDrawer: false,
      saveTime: '',
      custPhone: '',
      custName: '',
      remarkName: "",
      remarkPhone: "",
      employee: {},
      cardOrder: 0,
      seat: {},
      businessDate: '',
      options: [
        { id: 1, label: "0.1" },
        { id: 2, label: "0.2" },
        { id: 3, label: "0.3" },
        { id: 4, label: "0.4" },
        { id: 5, label: "0.5" },
        { id: 6, label: "0.6" },
        { id: 7, label: "0.7" },
        { id: 8, label: "0.8" },
        { id: 9, label: "0.9" },
        { id: '整瓶', label: "整瓶" },
      ],
      authInfo: {},
    };
  },
  methods: {
    async handleConfirm(value) {
      console.log('confirm value:', value)
      this.sliderVisible = false
      this.selectedSaveWineItem.expireDays = value
      console.log('this.selectedSaveWineItem:', this.selectedSaveWineItem)
    },
    handleCancel() {
      this.sliderVisible = false
      console.log('取消操作');
    },

    showSaveWineDays(item){
      console.log('click item:', item)
      this.sliderVisible = false
      this.selectedSaveWineItem = item
      this.sliderVisible = true
    },
    changeRelatedBill(){
      this.isCardBillRelated = !this.isCardBillRelated;
    },
    changeCustomerInfo(){
      this.showChgCustomerInfoDrawer = true;
    },
    changeCardOrder(){
      this.showCardOrderDrawer = true;
    },
    changeSaveTime(){
      this.showChgSaveTimeDrawer = true;
    },
    changeOrderPerson(){
      this.showChgOrderPersonDrawer = true;
    },
    showOrHideChgCustomerInfoHandle(){
      this.showChgCustomerInfoDrawer = !this.showChgCustomerInfoDrawer;
    },
    showOrHideChgSaveTimeHandle(){
      this.showChgSaveTimeDrawer = !this.showChgSaveTimeDrawer;
    },
    showOrHideChgOrderPersonHandle(){
      this.showChgOrderPersonDrawer = !this.showChgOrderPersonDrawer
    },
    async onSubmit() {
      const { userName, passWord, type } = this.authInfo;
      const params = {
        bef_in_id: this.currentSaveInfo.o * 1, //  int64      //BefInId 待入库订单Id
        mode_type: this.isCardBillRelated ? 1: 2,        //ModeType 1 关联流水模式  2  非关联流水模式
        bef_in_dtl_ids: this.tableData.map((item) => item.id * 1), //  []int64   待入库子订单Id
        unit_types: this.tableData.map((item) =>
          item.u == "整瓶" ? "1" : item.u
        ), //  []string   对应子定单修改后的规格
        prd_cnts: this.tableData.map((item) => item.c * 1), //   []int   对应子订单修改后的商品数量
        expired_days: this.tableData.map((item) => item.expireDays * 1), //   []int   过期天数
        g_cnts: this.tableData.map((item) => item.g * 1), //     []int        //GCnts 对应子订单修改后的克数
        prd_ids:this.tableData.map((item) => item.p), //NewPrdIds 对应子订单修改后的商品Id, 预留(将来可能修改商品)
        csm_id: this.isCardBillRelated ? this.cardOrder : 0, // int64 待入库存酒对应的流水
        seat_id: this.isCardBillRelated ? 0 : this.seat.id,     //NewSeatId 卡台Id 关联流水=0, 否则=指定卡台
        sales_emp_id: this.isCardBillRelated ? 0 : this.employee.id * 1,      //NewSalesEmpId 订位人Id 关联流水=0, 否则=指定定位人,散客=0
        cust_name: this.remarkName || this.custName,     //NewCustName 可修改 客户中心存酒对应备注客人姓名, 客户存酒对应客户手机号
        cust_phone: this.remarkPhone || this.custPhone,     //NewCustPhone 可修改 客户中心存酒对应备注客人手机号, 客户存酒对应客户手机号
        store_time: this.saveTime   //NewStoreTime 存酒时间 注意这边使用格式 yyyy/mm/dd hh24:mi:ss 如果没有修改,则回传返回的存酒时间
      };
      try {
        const res = await api_wine.reqChgCjBefIn(params);
        if (res.code == 1) {
          this.$message.success("修改成功");
          this.showAuthDrawer = false;
          this.onCancelDrawer();
          this.$emit("getTableData");
          this.dialogVisible = false;
        } else {
          this.$message.warning(res.msg);
        }

      } catch (error) {
        console.log("修改存酒详情失败", error);
      }
    },

    copyHandle(itemInfo) {
      this.tableData = [...this.tableData, {...itemInfo }]
    },
    deleteHandle(itemInfo) {
      const index = this.tableData.findIndex((item) => item.id == itemInfo.id);
      if (index > -1) {
        this.tableData.splice(index, 1);
      }
    },

    showAuthHandle() {
      if (this.needWaiterAuth) {
        if (this.tableData.length <= 0)
          return this.$message.warning("当前暂无商品可授权");
        this.showAuthDrawer = true;
      } else {
        // 仓库人员编辑完存酒单，不需要服务员授权，直接提交
        this.authInfo = { userName: "", passWord: "", type: 1 };
        this.onSubmit();
        // this.dialogVisible = true;
      }
    },

    submitSureHandle({ userName, passWord, type }) {
      this.authInfo = { userName, passWord, type };
      this.dialogVisible = true;
    },

    onCancelDrawer() {
      this.show = false;
    },
    onCancelCardOrderDrawer(){
      this.showCardOrderDrawer = false
    },
    onCardOrderSubmit(data){
      console.log(data);
      if(this.isCardBillRelated) {
        this.cardOrder = data.orderInfo.id;
        this.seat = data.cardInfo;
        this.businessDate = data.date;
        this.showCardOrderDrawer = false;
        this.employee = {n: data.orderInfo.s}
      } else {
        this.seat = data.cardInfo;
        this.showCardOrderDrawer = false;
      }
    },
    onCustomerInfoSubmit(data){
      this.custPhone = data.phone
      this.custName = data.name
      this.showChgCustomerInfoDrawer = false;
    },
    onSaveOrderPersonSubmit(data){
      this.employee = data
      this.showChgOrderPersonDrawer = false;
    },
    onSaveTimeSubmit(data){
      this.saveTime = data.time
      this.showChgSaveTimeDrawer = false;
    },
  },
  mounted() {},
  props: {
    value: {
      default: false, // 是否显示drawer
    },
    currentSaveInfo: {
      default: () => ({}),
    },
    needWaiterAuth: {
      default: true,
    },
    isCustomer: {
      default: false,
    },
  },
  computed: {
    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      },
    },
  },
  components: {
    Slider,
    authCom,
    drawerCardOrder,
    drawerChgCustomerInfo,
    drawerChgSaveTime,
    drawerChgOrderPerson,
},
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.tableData = JSON.parse(
            JSON.stringify(this.currentSaveInfo.ss || [])
          );
          this.tableData = this.tableData.map((item) => {
            return {
              ...item,
              expireDays: item.ed || item.ce,
              isRed: item.ed && item.ed * 1 != item.ce * 1,
            }
          }
          );
          console.log(this.currentSaveInfo);
          this.saveTime = this.currentSaveInfo.t
          this.custName = this.currentSaveInfo.c || (this.currentSaveInfo.rn)
          this.custPhone = this.currentSaveInfo.p || (this.currentSaveInfo.rp)
          this.cardOrder = this.currentSaveInfo.m
          this.seat = { n: this.currentSaveInfo.s, id: this.currentSaveInfo.si }
          this.businessDate = this.currentSaveInfo.d

        } else {
        }
      },
      immediate: true,
    },
    tableData: {
      handler(newVal) {
        this.$emit("update:tableData", newVal);
      },
      deep: true,
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../../style/common/elementDrawerWine.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/elementFormBtnWine.less";
@import "../../../../style/wine/table.less";
</style>

<style lang="less" scoped>

/deep/ .custom-color .el-input__inner {
  color: red;
}

.grid {
  margin-top: 20px;
  display: grid;
  grid-template-columns:150px 200px 150px 1fr;
  grid-row-gap: 20px;
  justify-items: start;
  align-items:center

}

.coll {
  margin-top: 10px;
}

.edit-save-info {
  .top {
    .title {
      font-size: 20px;
      font-weight: 600;
      line-height: 35px;
    }
  }
  .red {
    color: #f56c6c;
  }

  .table {
    .tbody {
      overflow: auto;
    }
  }
}

/deep/.el-button--default {
  background-color: #fff;
}
</style>
