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
        <div class="form" v-if="!showBind">
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
              <span class="red">*</span>
              <span>充值金额</span>
            </div>
            <div class="value">
              <el-input v-model="makeMoney" size="small" style="width:284px" placeholder="请输入充值金额"></el-input>
            </div>
          </div>
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>赠送金额</span>
            </div>
            <div class="value">
              <el-input v-model="zsMoney" size="small" style="width:284px" placeholder="请输入赠送金额"></el-input>
            </div>
          </div>
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>赠送卡券或礼包</span>
            </div>
            <div class="value">
              <div layout="row" layout-align="start center" >
                <el-button type="text" @click="onBind" v-if="couponId == ''">添加</el-button>
                <span style="padding-right: 5px" v-if="couponId">{{couponName}}</span>
                <el-button type="text" @click="onBind" v-if="couponId">更改</el-button>
                <el-button type="text" @click="deleteCouponHandle" v-if="couponId">删除</el-button>
              </div>

            </div>
          </div>
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>赠送积分</span>
            </div>
            <div class="value">
              <el-input v-model="zsPoint" size="small" style="width:284px" placeholder="请输入积分"></el-input>
            </div>
          </div>
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>充值规则</span>
            </div>
            <div class="value">
              <el-input v-model="remark" size="small" style="width:284px" placeholder="不超过30个字，用于充值时提示客人"></el-input>
            </div>
          </div>
        </div>
        <div v-else>
          <couponViewCom
            @value-changed="onValueChanged"
            :id="couponId + ''"
          />
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
      makeMoney: "",
      zsMoney: "",
      zsPoint: "",
      remark: "",
      cardLevelList: [], // 会员卡等级列表
      cardLevelVal: "", // 会员卡等级
      showBind: false, // 显示添加卡券/大礼包
      couponName: "", // 卡券/大礼包名称
      couponId: "", // 卡券/大礼包id
      tmpId: "", // 临时id
      tmpName: "", // 临时name
    };
  },
  methods: {
    async getCardLevelList() {
      try {
        const res = await api_vip.reqGetLevelList({
          id: this.selectItem.id * 1
        })
        if (res.code == 1) {
          this.cardLevelList = [{id: 0, n: '全等级'}, ...res.data.card_levels];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取会员卡类型列表失败", error);
      }
    },
    async getKqDetail() {
      try {
        const res = await api_vip.reqGetKqDetail({
          id: this.editInfo.id,
          card_type_id:this.editInfo.card_type_id
        })
        if (res.code == 1) {
          this.couponId = res.data.rule_info.free_kq_id
          // this.cardLevelList = [{id: 0, n: '全等级'}, ...res.data.card_levels];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取会员detail失败", error);
      }
    },
    // 绑定
    onBind() {
      this.showBind = true
    },
    deleteCouponHandle(){
      this.couponName = ""
      this.couponId = ""
    },
    onValueChanged(item){
      this.tmpId = item.id
      this.tmpName = item.n
      console.log("onValueChanged", item);
    },
    // 提交
    async onSubmit() {
      if(this.showBind) {
        this.couponId = this.tmpId
        this.couponName = this.tmpName
        this.showBind = false
      } else {
        console.log('cardLevelVal', this.cardLevelVal)
        if(this.zsPoint != '' && this.zsPoint * 1 != this.zsPoint) return this.$message.warning('赠送积分必须为正整数')
        if(this.remark.length > 30) return this.$message.warning('充值规则不可超过30个字')
        if(this.cardLevelVal * 1 != this.cardLevelVal) return this.$message.warning('会员卡等级必须填写')
        const params = {
          deposit_amt: this.makeMoney * 100, // int   充值金额
          free_amt: this.zsMoney * 100, //   int    赠送金额
          card_level_id: this.cardLevelVal * 1, // int    会员卡等级
          card_type_id: this.selectItem.id * 1, //  int    会员卡类型
          free_pt_amt: this.zsPoint * 1, // int    赠送积分
          free_kq_id: this.couponId ? this.couponId * 1 : 0, // int    赠送卡券id
          remark: this.remark, // string    充值提示    
        };
        if(this.editInfo.d) {
          params.id = this.editInfo.id
        }
        if(params.deposit_amt == 0) return this.$message.warning('充值金额不可为0')
        if(params.deposit_amt.toFixed(0) * 1 != params.deposit_amt) return this.$message.warning('充值金额必须为正整数')
        console.log(this.editInfo.d ? '编辑': '新建', params)
        try {
          const res = this.editInfo.d ? await api_vip.reqUpdateVipCardMakeMoneyRule(params) : await api_vip.reqAddVipCardMakeMoneyRule(params)
          if (res.code == 1) {
            this.$message.success(`${this.editInfo.d ? '编辑': '新建'}成功`)
            this.onCancelDrawer()
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log(`${this.editInfo.d ? '编辑': '新建'}充值规则失败`, error)
        }
      }
    },
    onCancelDrawer() {
      if(this.showBind) {
        this.showBind = false
      } else {
        this.$emit("showOrHideHandle");
      }
    },
    resetData() {
      this.makeMoney = "";
      this.zsMoney = "";
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
    selectItem: {
      default: {}
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
            this.getKqDetail()
            // 编辑
            this.makeMoney = this.editInfo.d / 100
            this.zsMoney = this.editInfo.f / 100
            // this.couponId = this.editInfo.id
            this,this.couponName = this.editInfo.fk
            this.cardLevelVal = (this.cardLevelList.find(item => item.n == this.editInfo.n) || {id:0})['id']
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