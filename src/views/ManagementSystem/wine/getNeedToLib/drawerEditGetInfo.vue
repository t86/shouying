<template>
  <div>
    <!-- 修改取酒出库单 -->
    <el-drawer
      title="编辑"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="900px"
    >
      <div class="session edit-save-info p-5">
        <div class="top" layout="row" layout-align="start center">
          <div class="title">存酒详情</div>
          <div class="name">{{currentWineInfo.c}}</div>
          <div class="phone">{{currentWineInfo.p}}</div>
        </div>

        <!-- 剩余取酒详情 -->
        <div class="get-list" layout="row" layout-align="space-between start">
          <div class="left">
            <div class="title fs16 m-t-3 m-b-3">剩余取酒详情</div>
            <div class="table-content">
              <div class="table">
                <div class="thead">
                  <div class="tr" layout="row" layout-align="space-between center">
                    <div class="th">名称</div>
                    <div class="th">规格</div>
                    <div class="th">每瓶克数</div>
                    <div class="th">剩余可取数量</div>
                  </div>
                </div>
                <div class="tbody">
                  <div
                    class="tr"
                    layout="row"
                    layout-align="space-between center"
                    v-for="item in WineList"
                    :key="item.id"
                  >
                    <div class="td one-txt-cut">{{item.n}}</div>
                    <div class="td">{{item.u}}</div>
                    <div class="td">{{item.g || '-'}}</div>
                    <div class="td" layout="row" layout-align="space-between center">
                      <div class="count">{{item.c}}</div>
                      <div
                        class="get-icon"
                        :class="{opacity: !item.canGet}"
                        @click="addWineToShoppingCart(item)"
                      >取</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="right">
            <div class="title fs16 m-t-3 m-b-3">取酒详情</div>
            <div class="table-content">
              <div class="table">
                <div class="thead">
                  <div class="tr" layout="row" layout-align="space-between center">
                    <div class="th">名称</div>
                    <div class="th">规格</div>
                    <div class="th">每瓶克数</div>
                    <div class="th">数量</div>
                    <div class="th">操作</div>
                  </div>
                </div>
                <div class="tbody">
                  <div
                    class="tr"
                    layout="row"
                    layout-align="space-between center"
                    v-for="item in shoppingCartWineList"
                    :key="item.id"
                  >
                    <div class="td one-txt-cut">{{item.n}}</div>
                    <div class="td">{{item.u}}</div>
                    <div class="td">{{item.g || '-'}}</div>
                    <div class="td" layout="row" layout-align="start center">
                      <el-button
                        type
                        size="small"
                        :disabled="item.c <= 1"
                        style="width:26px;padding:0;height:26px;border-radius:50%"
                        icon="el-icon-minus"
                        @click="changeShoppingCartCount(item, Math.max((item.c * 1 - 1), 1))"
                      ></el-button>
                      <input
                        type="number"
                        :min="1"
                        v-model="item.c"
                        @input="changeShoppingCartCount(item, Math.max(item.c, 1))"
                      />
                      <el-button
                        type
                        size="mini"
                        :disabled="item.c >= item.maxCount"
                        style="width:26px;padding:0;height:26px;border-radius:50%"
                        icon="el-icon-plus"
                        @click="changeShoppingCartCount(item, (item.c * 1 + 1))"
                      ></el-button>
                    </div>
                    <div class="td" layout="row" layout-align="center center">
                      <span
                        style="color:#2979ff;cursor:pointer"
                        @click="changeShoppingCartCount(item, 0)"
                      >删除</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- 授权 -->
      <authCom
        ref="authRef"
        v-model="showAuthDrawer"
        :tableData="shoppingCartWineList"
        @emitHandle="submitSureHandle"
      />

      <el-dialog
        title="提示"
        :visible.sync="dialogVisible"
        append-to-body
        width="30%">
        <p>确认出库吗？</p>
        <span slot="footer" class="dialog-footer">
          <el-button @click="dialogVisible = false">取 消</el-button>
          <el-button type="primary" @click="onSubmit">确 定</el-button>
        </span>
      </el-dialog>

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmitHandle">{{needWaiterAuth ? '服务员授权' : '确定出库'}}</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_wine from "@/api/wine";
import authCom from "../commonCom/auth.vue";
import api_saveWine from "@/api/saveWine";
export default {
  data() {
    return {
      dialogVisible: false,
      showAuthDrawer: false,
      WineList: [], // 当前流水可取酒水
      shoppingCartWineList: [], // 存酒购物车酒水
      authInfo: {}
    };
  },
  methods: {
    async init() {
      await this.getOrderCanGetWine();

      const shoppingCartWineList = this.currentWineInfo.ss
        ? JSON.parse(JSON.stringify(this.currentWineInfo.ss))
        : [];

      this.shoppingCartWineList = [];
      /*
        tips:此处需要注意，shoppingCartList中的数据为WineList中数据去除掉的，即shoppingCartList + WineList = 取酒前仓库酒水总和

        wineList中有个字段为 i ：表示当前仓库订单id 与 shoppingCardList修改前数据中的 id 匹配 ，但是shoppingCartList 中从 wineList 中添加过来的酒水信息也有 i 字段，表示日期，所以在
                          最终仓库人员操作完以后  shoppingCardList中的数据字段 i  只能通过 乘以1  是否为 NaN 判断为原购物车酒水还是新添加的酒水

        当删除掉购物车中的酒水，要添加到仓库列表中，因为此时未与后端进行交互，需要手动处理
      */
      shoppingCartWineList.forEach(el => {
        const wineInfo = this.WineList.find(item => item.id == el.i);
        if (wineInfo) {
          // 取酒未取完，仓库还有剩余
          el.maxCount = el.c * 1 + wineInfo.c * 1;
        } else {
          // 全部取完了
          el.maxCount = el.c;
        }
        this.shoppingCartWineList.push(el);
      });

      // 将购物车数据添加到wineList(此处wineList中存在的酒水不用做数量累加，因为wineList中的数量为当前可添加的和数量)
      this.shoppingCartWineList.forEach(el => {
        const wineInfo = this.WineList.find(item => item.id == el.i);
        if(!wineInfo){
          this.WineList.push({
            c: 0,
            canGet: false,
            e: "2023/05/25 00:00 - shoppingCart wine",
            g: el.g,
            i: "2023/05/18 11:32 - shoppingCart wine",
            id: el.i,
            n: el.n,
            p: el.p,
            r: el.r,
            u: el.u
          })
        }
        
      })
    },
    // 获取订单流水可存酒水
    async getOrderCanGetWine() {
      const params = {
        phone_num: this.currentWineInfo.p.toString(), // string   客户手机号,用以返还客户姓名
        key: "" //   string     过滤关键字
      };

      try {
        const res = await api_saveWine.reqGetCanGetFromLib(params);
        if (res.code == 1) {
          this.customName = res.data.cust_name || "";
          this.WineList = (res.data.records || []).map(item => ({
            ...item,
            canGet: true
          }));
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取可取酒水列表失败", error);
      }
    },

    // 选择流水中酒水信息
    addWineToShoppingCart(itemInfo) {
      if (!itemInfo.canGet)
        return this.$message.warning("当前酒水可取数量已达到最大值");
      const hasItem = this.shoppingCartWineList.find(
        item => item.id == itemInfo.id || item.i == itemInfo.id
      );
      if (hasItem) {
        this.shoppingCartWineList = this.shoppingCartWineList.map(item => {
          if (!isNaN(itemInfo.i * 1)) {
            // 服务员取酒时购物车加入的酒水
            return {
              ...item,
              c: item.i == itemInfo.id ? item.maxCount : item.c
            }
          } else {
            // 仓库人员加入的酒水
            return {
              ...item,
              c: item.id == itemInfo.id ? itemInfo.c : item.c
            }
          }
        });
      } else {
        this.shoppingCartWineList = [
          ...this.shoppingCartWineList,
          { ...itemInfo, maxCount: itemInfo.c }
        ];
      }
      this.WineList = this.WineList.map(item => ({
        ...item,
        c: item.id == itemInfo.id ? 0 : item.c,
        canGet: item.id == itemInfo.id ? false : item.canGet
      }));
    },

    // 修改购物车数量/删除
    changeShoppingCartCount(itemInfo, count) {
      // 计算差值增量
      const dis = count - itemInfo.c
      if (itemInfo.maxCount <= count) {
        itemInfo.c = itemInfo.maxCount;
      } else if (count <= 0) {
        // 删除
        const index = this.shoppingCartWineList.findIndex(
          item => item.id == itemInfo.id
        );
        if (index > -1) {
          this.shoppingCartWineList.splice(index, 1);
        }
        
        // 此处需要将删除掉的酒水添加或合并到wineList中
        const deleteCount = itemInfo.c
        // 判断当前被删除掉的酒水是否为服务员原来购物车中的酒水
        const isOriginWine = !isNaN(itemInfo.i * 1)

        this.WineList.forEach(el => {
          if(isOriginWine) {
            // 服务员原本点的酒水
            if(itemInfo.i == el.id) {
              el.c = el.c * 1 + deleteCount
              el.canGet = true
            }
          } else {
            // 仓库人员点的酒水
            if(itemInfo.id == el.id) {
              el.c = el.c * 1 + deleteCount
              el.canGet = true
            }
          }
        })

        itemInfo.c = count;

      } else {
        itemInfo.c = count;
      }

      // 如果为增加或减少数量需要对wineList中的数量进行修改（删除中逻辑已经在上边写过）
      if(count != 0) {
        this.WineList = this.WineList.map(item => {
          if (!isNaN(itemInfo.i * 1)) {
            // 服务员取酒购物车原有酒水
            const resultWineCount = item.id == itemInfo.i ? item.c - dis : item.c
            return {
              ...item,
              c: resultWineCount,
              canGet: item.id == itemInfo.i ? itemInfo.c < itemInfo.maxCount : item.canGet
            }
          } else {
            // 仓库人员新加入的酒水
            const resultWineCount = item.id == itemInfo.id ? item.c - dis : item.c
            return {
              ...item,
              c: resultWineCount,
              canGet: item.id == itemInfo.id ? resultWineCount > 0 : item.canGet
            };
          }
        });
      }
      
    },

    async getWineHandle() {
      const params = {
        seat_id: this.$store.state.orderInfo.saveWineCardInfo.id * 1, // int64    卡台Id
        invt_ids: this.shoppingCartWineList.map(item => item.id * 1), //   []int64   存酒库存Id列表
        prd_cnts: this.shoppingCartWineList.map(item => item.c * 1), //  []int  对应存酒库存Id的取酒商品数量
        phone_num_auth_code: this.phoneValidateStr, // string  认证手机授权码
        phone_num: this.phoneNum //  string  取酒客户手机号
      };
      try {
        const res = await api_saveWine.reqGetWineToNextLib(params);
        if (res.code == 1) {
          this.$message.success("取酒成功");
          this.$emit("onCancelDrawer", true);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("新增取酒订单失败", error);
      }
    },

    onSubmitHandle(){
      if(this.needWaiterAuth){
        this.showAuthDrawer = true
      } else {
        this.authInfo = { userName: '', passWord: '', type: 1 }
        this.dialogVisible = true
      }
    },

    submitSureHandle({ userName, passWord, type }){
      this.authInfo = { userName, passWord, type }
      this.dialogVisible = true
    },

    
    async onSubmit() {
      const { userName, passWord, type } = this.authInfo
      // 原购物车酒水
      const originShoppingCardList = this.shoppingCartWineList.filter(item => !isNaN(item.i * 1))
      // 新添加的购物车酒水
      const newShippingCardList = this.shoppingCartWineList.filter(item => isNaN(item.i * 1))
      const params = {
        auth_emp_code: userName, // string   授权人工号
        auth_emp_passwd: passWord, //  string   授权人密码
        pass_type: type, //  int   1 验证 员工号/密码  2 验证卡号/卡数据 为兼容之前的账号密码认证, 当=2的时候验证卡号和卡密, 共用emp_code,password
        bef_out_id: this.currentWineInfo.o * 1, // int64   待出库订单Id
        invt_ids: [...originShoppingCardList.map(item => item.i * 1), ...newShippingCardList.map(item => item.id)], //   []int64  库存Id列表
        prd_cnts: this.shoppingCartWineList.map(item => item.c * 1)  //   []int   对应上面库存出库商品数量
      };

      try {
        const res = await api_wine.reqAuthFromGetInLib(params);
        if (res.code == 1) {
          this.$message.success("出库成功");
          this.showAuthDrawer = false;
          this.onCancelDrawer();
          this.$emit("getTableData");
        } else {
          if(type == 2) window.loopReadCard()
          this.$message.warning(res.msg);
        }
        this.dialogVisible = false;
      } catch (error) {
        if(type == 2) window.loopReadCard()
        console.log("授权修改出库详情失败", error);
      }
    },

    onCancelDrawer() {
      this.show = false;
    }
  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    currentWineInfo: {
      default: () => ({})
    },
    needWaiterAuth:{
      default: true
    }
  },
  computed: {
    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    }
  },
  components: {
    authCom
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.init();
        } else {
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../style/common/elementDrawerWine.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/elementFormBtnWine.less";
@import "../../../../style/wine/table.less";
</style>

<style lang="less" scoped>
.edit-save-info {
  .top {
    .title {
      font-size: 20px;
      font-weight: 600;
    }
    .name {
      margin: 0 20px;
    }
  }
  // 列表
  .get-list {
    height: calc(100vh - 186px);
    // 左侧
    .left {
      width: 50%;
      height: 100%;
      overflow: auto;
      padding-right: 10px;
      box-sizing: border-box;
      border-right: 1px solid #eee;
      .table {
        .tbody {
          height: calc(100vh - 270px);
          overflow: auto;
          .get-icon {
            width: 36px;
            height: 28px;
            line-height: 28px;
            text-align: center;
            font-size: 18px;
            color: #fff;
            background: linear-gradient(180deg, #4b89ff 0%, #455eff 100%);
            border-radius: 6px;
            cursor: pointer;
            &.opacity {
              opacity: 0.2;
            }
          }
        }
      }
    }
    // 右侧
    .right {
      width: 50%;
      height: 100%;
      overflow: auto;
      padding-left: 10px;
      box-sizing: border-box;
      .table {
        .tbody {
          height: calc(100vh - 270px);
          overflow: auto;
        }
        .th,
        .td {
          width: 20%;
          &:nth-child(4) {
            width: 30%;
            img {
              width: 20px;
              cursor: pointer;
            }
            input {
              width: 50px;
              height: 26px;
              border-radius: 13px;
              margin: 0 6px;
              font-size: 14px;
              text-align: center;
              box-sizing: border-box;
            }
          }
          &:nth-child(5) {
            img {
              width: 20px;
              cursor: pointer;
            }
          }
        }
      }
    }
  }
}

/deep/.el-button--default {
  background-color: #fff;
}
</style>