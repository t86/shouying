<template>
  <!-- 会员卡号生成规则 -->
  <div class="vip vip-num-rules">
    <h3 class="title">会员卡号生成规则</h3>
    <div class="content">
      <div class="form">
        <div class="row" layout="row" layout-align="start center">
          <div class="label">卡号编码长度：</div>
          <div class="value" layout="row" layout-align="start center">
            <img
              :src="require('@/assets/vip-imgs/sub-btn.png')"
              @click="ruleLength=Math.max(1, ruleLength-1)"
            />
            <input class="rule-input" v-model="ruleLength" placeholder="请输入卡号编码长度" min="1" />
            <img :src="require('@/assets/vip-imgs/add-btn.png')" @click="ruleLength++" />
          </div>
        </div>
        <div class="row" layout="row" layout-align="start center">
          <div class="label">卡号前缀：</div>
          <div class="value">
            <el-input
              v-model="beginStr"
              size="small"
              placeholder="长度不超过4位"
              :maxlength="4"
              style="width:284px"
            ></el-input>
          </div>
        </div>
        <div class="row m-t-3" layout="row" layout-align="start start">
          <div class="label">卡号预览：</div>
          <div class="value">
            <div class="item" v-for="item in prevList" :key="item">{{item}}</div>
          </div>
        </div>
        <div class="row m-t-10" layout="row" layout-align="start start">
          <div class="label"></div>
          <div class="value">
            <button class="btn primary normal" @click="onSubmit">保存</button>
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
      ruleLength: '5',
      beginStr: ""
    };
  },
  methods: {
    async getRules() {
      try {
        const res = await api_vip.reqGetVipCardNoRule();
        if (res.code == 1) {
          this.ruleLength = res.data.num_length || '5';
          this.beginStr = res.data.prefix || '';
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取会员卡号规则失败", error);
      }
    },
    async onSubmit() {
      if(isNaN(this.ruleLength * 1) || this.ruleLength * 1 <= 0) return this.$message.warning('卡号编码长度必须为大于0的数字')
      const params = {
        num_length: this.ruleLength * 1, // int   编码长度
        prefix: this.beginStr //     string   卡前缀
      };
      try {
        const res = await api_vip.reqSetVipCardNoRule(params);
        if (res.code == 1) {
          this.$message.success('保存成功')
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("设置会员卡号规则失败", error);
      }
    }
  },
  mounted() {
    this.getRules();
  },
  computed: {
    prevList() {
      let result = [];
      const count = this.ruleLength - 1;
      if (!isNaN(count) && count >= 0) {
        const beginNum = this.beginStr + "0".repeat(count);
        const endNum = this.beginStr + "9".repeat(count);
        result = [
          beginNum +
            "0、" +
            beginNum +
            "1、" +
            beginNum +
            "2、" +
            beginNum +
            "3、" +
            beginNum +
            "5",
          "......",
          endNum +
            "3、" +
            endNum +
            "5、" +
            endNum +
            "6、" +
            endNum +
            "8、" +
            endNum +
            "9"
        ];
      }

      return result;
    }
  }
};
</script>

<style lang="less" scoped>
@import "../../style/common/elementDrawerVip.less";
@import "../../style/vip/vipBtn.less";
@import "../../style/vip/vip.less";
</style>

<style lang="less" scoped>
.vip-num-rules {
  .content {
    padding-left: 20px;
    padding-top: 20px;
    .form {
      .row {
        height: 50px;
        font-size: 14px;
        .label {
          width: 120px;
          text-align: right;
        }
        .value {
          padding-left: 6px;
          img {
            width: 28px;
            cursor: pointer;
          }
          input.rule-input {
            width: 56px;
            height: 28px;
            background: #b3bbcd;
            border-radius: 24px;
            border: 1px solid #aeafc1;
            margin: 0 6px;
            padding: 0 6px;
            box-sizing: border-box;
            text-align: center;
            font-size: 16px;
          }

          .item {
            height: 20px;
          }
        }
      }
    }
  }
}
</style>