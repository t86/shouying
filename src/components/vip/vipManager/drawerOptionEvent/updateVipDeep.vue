<template>
  <!-- 更改会员等级 -->
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
      <!-- <div class="row">
        <div class="label">剩余积分：</div>
        <div class="value">1000</div>
      </div>-->
    </div>
    <div class="content">
      <div class="form-grid m-t-6" style="border:none">
        <div class="row">
          <div class="label m-t-2">
            <span style="color:#E0304F">*</span>
            <span>会员卡等级：</span>
          </div>
          <div class="value">
            <el-select v-model="vipDeepVal" size="small" style="width:284px" placeholder="请选择会员卡等级">
              <el-option
                v-for="item in vipDeepValOption"
                :key="item.id"
                :label="item.n"
                :value="item.id"
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
      vipDeepVal: "",
      vipDeepValOption: []
    };
  },
  methods: {
    async getVipInfo() {
      const params = {
        id: this.currentItemInfo.id * 1 //   int64   会员卡Id
      };
      try {
        const res = await api_vip.reqGetVipCardDeep(params);
        if (res.code == 1) {
          this.vipInfo = res.data.card_info || {};
          this.vipDeepVal = res.data.card_info.card_level_id;
          this.vipDeepValOption = res.data.card_levels || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取会员信息失败", error);
      }
    }
  },
  created() {
    this.getVipInfo();
  },
  props: {
    currentItemInfo: {
      default: {}
    }
  },
  watch: {
    vipDeepVal: {
      handler(newVal) {
        this.$emit('updateInfoHandle', {vipDeepVal: newVal})
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../style/vip/drawerManager/stepFour.less";
</style>