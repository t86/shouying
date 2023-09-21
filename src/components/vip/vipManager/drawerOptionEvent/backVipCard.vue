<template>
  <!-- 退卡 -->
  <div class="step-four">
    <div class="form-grid">
      <div class="row">
        <div class="label">会员卡号：</div>
        <div class="value">{{vipInfo.card_no}}</div>
      </div>
      <div class="row">
        <div class="label">姓名：</div>
        <div class="value">{{vipInfo.name || '---'}}</div>
      </div>
      <div class="row">
        <div class="label">绑定手机：</div>
        <div class="value">{{vipInfo.bind_phone || '---'}}</div>
      </div>
      <div class="row">
        <div class="label">联系手机：</div>
        <div class="value">{{vipInfo.contact_phone || '---'}}</div>
      </div>
      <div class="row">
        <div class="label">储蓄余额：</div>
        <div class="value">{{vipInfo.val_bal}}</div>
      </div>
      <div class="row">
        <div class="label">赠送余额：</div>
        <div class="value">{{vipInfo.free_bal}}</div>
      </div>
      <div class="row">
        <div class="label">积分余额：</div>
        <div class="value">{{vipInfo.pt_bal}}</div>
      </div>
    </div>
    <div class="content">
      <div class="form-grid m-t-6" style="border:none">
        <div class="row">
          <div class="label m-t-2">
            <span style="color:#E0304F">*</span>
            <span>退卡理由：</span>
          </div>
          <div class="value">
            <el-select v-model="reason" size="small" style="width:284px" placeholder="请选择退卡理由">
              <el-option
                v-for="item in reasonOption"
                :key="item.name"
                :label="item.name"
                :value="item.name"
              ></el-option>
            </el-select>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
 
<script>
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      vipInfo: {},
      reason: ""
    };
  },
  methods: {
    async getVipInfo() {
      this.reason = ""
      const params = {
        id: this.currentItemInfo.id * 1 //   int64   会员卡Id
      };
      try {
        const res = await api_vip.reqVipCardGetVNodeCard(params);
        if (res.code == 1) {
          this.vipInfo = res.data || {};
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取会员信息失败", error);
      }
    }
  },
  props: {
    currentItemInfo: {
      default: {}
    }
  },
  computed: {
    reasonOption(){
      const result = this.$store.state.cardPageInfo.resResultDataObj.reasonList
      return result.filter(item => item.status == 1 &&item.type_id == 3)
    }
  },
  watch: {
    reason: {
      handler() {
        this.$emit('updateInfoHandle', {reason: this.reason})
      },
      immediate: true
    },
  }
};
</script>

<style scoped lang="less">
@import "../../../../style/vip/drawerManager/stepFour.less";
</style>