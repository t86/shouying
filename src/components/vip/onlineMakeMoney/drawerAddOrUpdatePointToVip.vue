<template>
  <div>
    <!-- 新增、修改线上充值 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      append-to-body
      direction="rtl"
      size="720px"
    >
      <div class="session add-or-update-make-money-to-vip">
        <div class="form" >
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span class="red">*</span>
              <span>卡等级</span>
            </div>
            <div class="value">
              <el-select
              v-model="cardLevelVal"
              size="small"
              placeholder="请选择会员卡等级"
              style="width: 200px"
            >
              <el-option
                v-for="item in cardLevelList"
                :key="item.id"
                :label="item.n"
                :value="item.id"
              >
              </el-option>
            </el-select>
            </div>
          </div>
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>赠送积分规则</span>
            </div>
            <div class="value">
              <el-radio-group v-model="type_id" v-if="$store.getters.vipAuth">
                <el-radio :label="1">不赠送积分</el-radio>
                <!-- <el-radio :label="2">充值赠送积分</el-radio> -->
                <el-radio :label="3">消费赠送积分</el-radio>
              </el-radio-group>
            </div>
          </div>
          <div v-if="type_id == '3'" class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>消费</span>

            </div>
            <div class="value">
              <el-input v-model="makeMoney" size="small" style="width:284px" placeholder="输入整数"></el-input>
              <span>元储值金额送1积分</span>
            </div>
          </div>
          <div v-if="type_id == '3'" class="row" layout="row" layout-align="start center">
            <div class="label">
              <span class="red"></span>
            </div>
            <div class="value">
              <span class="red" style="font-size: 14px;">说明：不足的部分不会赠送，例如设置消费10元储值金额赠送1积分，消费999元储值金额则赠送99积分</span>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_vip from "@/api/vip";
import couponViewCom from "@/components/vip/onlineMakeMoney/couponViewCom.vue";
export default {
  data() {
    return {
      show: false,
      makeMoney: "", // 消费金额
      zsPoint: "",
      remark: "",
      cardLevelList: [], // 会员卡等级列表
      cardLevelVal: "0", // 会员卡等级
      type_id: 1, // 赠送积分规则
    };
  },
  methods: {
    async getCardLevelList() {
      try {
        const params = {
          card_type_id: this.cardTypeId, 
          id: this.editInfo.id,
        }

        const res = await api_vip.reqGetPtRule(params);

        console.log('res', res, this.cardTypeId)
        if (res.code == 1) {
          this.cardLevelList = res.data.card_level_dfns;
          this.cardLevelList = [{id: '0', n: '全等级'}, ...this.cardLevelList]
          this.cardLevelVal = res.data.rule_info && res.data.rule_info.card_level_id || '0'
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取会员卡类型列表失败", error);
      }
    },
    // 提交
    async onSubmit() {
      if((this.makeMoney == '' && this.type_id == '3') || !this.cardLevelVal ) return this.$message.warning('充值金额, 会员卡等级必须填写')
      const params = {
        base_amt: this.makeMoney * 100, // int   充值金额
        card_level_id: this.cardLevelVal * 1, // int    会员卡等级
        card_type_id: this.cardTypeId * 1, //  int    会员卡类型
      };
      if(this.editInfo.id) {
        params.id = this.editInfo.id
      }
      try {
        const res = this.editInfo.id ? await api_vip.reqSavePtRule(params) : await api_vip.reqNewPtRule(params)
        if (res.code == 1) {
          this.$message.success(`${this.editInfo.id ? '编辑': '新建'}成功`)
          this.onCancelDrawer()
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log(`${this.editInfo.d ? '编辑': '新建'}积分规则失败`, error)
      }
    },
    onCancelDrawer() {
      this.$emit("showOrHideHandle");
    },
    resetData() {
      this.makeMoney = "";
    },
  },
  mounted() {},
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    editInfo: {
      default: {}
    },
    cardTypeId: {
      default: 0
    }
  },
  computed: {
    title() {
      return this.editInfo.d ? "编辑" : "新增";
    }
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
        if (newVal) {
          this.getCardLevelList();
          if (this.editInfo.d) {
            // 编辑
            this.makeMoney = this.editInfo.d
          } else {
            this.resetData();
          }
        } else {
          this.$emit("getTableData");
        }
      },
      immediate: true
    }
  },
  components: {
    couponViewCom
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawerVip.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/vip/vipBtn.less";
@import "../../../style/common/elementFormBtnVip.less";
@import "../../../style/common/scrollBarVip.less";
@import "../../../style/vip/vipBtn.less";
</style>
<style lang="less" scoped>
.add-or-update-make-money-to-vip {
  .form {
    padding-bottom: 30px;
    .row {
      margin: 20px 0;

      .label {
        width: 150px;
        text-align: right;
        font-size: 14px;
        margin-right: 10px;

        span.red {
          color: #f51f4b;
        }
      }

      .value {
        .tips {
          margin-top: 10px;
          font-size: 13px;
          color: #72727b;
        }
      }
    }
  }
}
</style>