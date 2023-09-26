<template>
    <!-- 扣除积分 -->
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
          <div class="label">绑定手机号：</div>
          <div class="value">{{vipInfo.bind_phone || '---'}}</div>
        </div>
        <div class="row">
          <div class="label">联系手机：</div>
          <div class="value">{{vipInfo.contact_phone || '---'}}</div>
        </div>
        <div class="row">
          <div class="label">储值余额：</div>
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
        <div class="flex-col" style="border:none">
          <div class="flex-row">
            <div class="label m-t-2">
              <span style="color:#E0304F">*</span>
              <span>充值积分</span>
            </div>
            <div class="value" style="margin-left: 16px;">
                <el-input
                v-model="point"
                size="small"
                style="width: 284px"
                placeholder="请输入整数"
              ></el-input>
            </div>
          </div>
          <div class="flex-row">
            <div class="label m-t-2">
              <span style="margin-left: 12px;">备注</span>
            </div>
            <div class="value" style="margin-left: 16px;">
              <el-input
                type="textarea"
                :rows="2"
                placeholder="填写充值积分的原因，不超过30个字"
                v-model="remark"
                style="width: 284px"
              >
               </el-input>
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
        point: "",
        remark: "",
      };
    },
    methods: {
      async getVipInfo() {
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
    created() {
      this.getVipInfo();
    },
    props: {
      currentItemInfo: {
        default: {}
      }
    },
    watch: {
      point: {
        handler(newVal) {
          this.$emit('updateInfoHandle', {point: newVal,remark:this.remark})
        },
        immediate: true
      },
      remark:{
        handler(newVal) {
          this.$emit('updateInfoHandle', {point: this.point,remark: newVal})
        },
        immediate: true
      }
    }
  };
  </script>
  
  <style scoped lang="less">
  @import "../../../../style/vip/drawerManager/stepFour.less";
  .flex-col{
    display: flex !important;
    flex-direction: column;
    justify-content: center;
  }
  .flex-row{
    margin-top: 24px;
    display: flex;
    flex-direction: row;
    justify-content: flex-start;
    .label{
      min-width: 100px;
    }
  }
  </style>