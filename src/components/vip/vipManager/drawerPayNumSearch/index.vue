<template>
  <div>
    <!-- 付款码搜索 -->
    <el-drawer
      title="付款序列号制卡"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="700px"
    >
      <div class="session p-5">
        <div class="search">
          <el-input
            size="small"
            v-model="keyword"
            placeholder="请输入六位付款序列号"
            style="width: 284px"
            @input="getTableData"
          ></el-input>
          <button class="btn primary" @click="getTableData">搜索</button>
        </div>
      </div>
      <div class="search-vip-list">
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="space-between center">
              <div class="th">会员卡号</div>
              <div class="th">绑定手机</div>
              <div class="th">姓名</div>
              <div class="th">卡类型</div>
              <div class="th">卡等级</div>
              <div class="th">操作</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              v-for="item in tableData"
              :key="item.id"
              layout="row"
              layout-align="space-between center"
            >
              <div class="td" layout="row" layout-align="start center">
                <span>{{ item.c }}</span>
                <img
                  v-if="item.r == 1"
                  :src="require('@/assets/vip-imgs/vip-manager-icon.png')"
                />
              </div>
              <div class="td">{{ item.p }}</div>
              <div class="td">{{ item.n }}</div>
              <div class="td">{{ item.ct }}</div>
              <div class="td">{{ item.cl }}</div>
              <div class="td">
                <span
                  :class="{ disabled: item.r == 1 }"
                  @click="emitData(item, 2)"
                  >制卡</span
                >
              </div>
            </div>
            <div class="no-data" v-if="tableData.length == 0">
              <img :src="require('@/assets/vip-imgs/empty.png')" alt />
              <p>暂无数据</p>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer()">取消</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_money from "@/api/money";
import tips from "@/components/vip/vipManager/drawerOptionEvent/tipsArr";
export default {
  data() {
    return {
      show: false,
      keyword: "",
      phoneNum: "",
      authCodeStr: "",
      tableData: [],
    };
  },
  methods: {
    async getTableData(e) {
      const result = await this.validateValidateInfo(e);
      if (result) {
        const params = {
          sms_auth_code: result, // string   手机验证码验证授权串
          phone_num: this.phoneNum, //  string   手机号
        };

        try {
          const res = await api_money.reqGetVipCardFormPhoneNum(params);
          if (res.code == 1) {
            this.tableData = (res.data.records || []).map((item) => ({
              ...item,
              p: this.phoneNum,
            }));
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("通过手机号查询会员卡失败", error);
        }
      }
    },
    async validateValidateInfo(e) {
      const params = {
        srv_code: this.keyword, //    string   付款码
      };
      if (params.srv_code.length != 6 && typeof e == "object") {
        this.$message.warning("请输入正确的六位服务码序列号");
        return false;
      } else if (params.srv_code.length != 6) {
        return;
      }
      try {
        const res = await api_money.reqGetVipCardFormValidate(params);
        if (res.code == 1) {
          this.phoneNum = res.data.p;
          this.authCodeStr = res.data.c;
          return res.data.c;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("验证手机验证码失败", error);
      }
    },
    emitData(itemInfo, index) {
      if (itemInfo.r == 1) return;
      const optionInfo = tips.find((item) => item.id == index);
      this.onCancelDrawer();
      this.$emit("updateCurrentVipInfo", {
        info: itemInfo,
        optionInfo,
      });
    },
    onCancelDrawer() {
      this.$emit("showOrHideDrawer");
    },

    reset() {
      this.keyword = "";
      this.phoneNum = "";
      this.authCodeStr = "";
      this.tableData = [];
    },
  },
  mounted() {},
  props: {
    showDrawer: {
      default: false, // 是否显示drawer
    },
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) this.reset();
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../../style/vip/vip.less";
@import "../../../../style/common/elementDrawerVip.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/vip/vipBtn.less";
@import "../../../../style/common/elementFormBtnVip.less";
@import "../../../../style/common/scrollBarVip.less";
</style>

<style lang="less" scoped>
.search-vip-list {
  padding: 0 20px;
  .table {
    .th:nth-child(1),
    .td:nth-child(1) {
      width: 120px;
      img {
        width: 18px;
        margin-left: 2px;
      }
    }
    .th:nth-child(2),
    .td:nth-child(2) {
      width: 120px;
    }
    .th:nth-child(3),
    .td:nth-child(3) {
      width: 100px;
    }
    .th:nth-child(4),
    .td:nth-child(4) {
      width: 180px;
    }
    .th:nth-child(5),
    .td:nth-child(5) {
      width: 120px;
    }
    .th:nth-child(6),
    .td:nth-child(6) {
      width: 60px;
      span {
        color: #2362d5;
        cursor: pointer;
        &.disabled {
          color: #888;
          cursor: no-drop;
        }
      }
    }
  }
}
</style>
