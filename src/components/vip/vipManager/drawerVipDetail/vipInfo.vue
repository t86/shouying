<template>
  <div class="vip-info">
    <div class="form-grid">
      <div class="row">
        <div class="label">姓名:</div>
<!--          <el-input placeholder="请输入内容" v-model="info.name" size="mini" @change="nameChanged">-->
<!--            <el-button slot="append" icon="el-icon-search" size="mini"></el-button>-->
<!--          </el-input>-->
          <el-select
              v-model="info.name"
              filterable
              remote
              reserve-keyword
              placeholder="请输入关键词"
              :remote-method="nameQuery"
              @change="phoneChanged"
              size="mini"
              :loading="loading">
            <el-option
                v-for="item in options"
                :key="item.p"
                :label="item.n"
                :value="item.p">
            </el-option>
          </el-select>
      </div>
      <div class="row">
        <div class="label">性别:</div>
        <div class="value">{{info.sex}}</div>
      </div>
      <div class="row">
        <div class="label">出生日期:</div>
        <div class="value">{{info.birthday}}</div>
      </div>
      <div class="row">
        <div class="label">绑定手机：</div>
        <div>
          <el-input placeholder="请输入内容" v-model="info.bind_phone" size="mini">
            <el-button slot="append" icon="el-icon-search" size="mini" @click="inputPhoneChanged"></el-button>
          </el-input>
        </div>
      </div>
      <div class="row">
        <div class="label">联系手机：</div>
        <div class="value">{{info.contact_phone}}</div>
      </div>
      <div class="row">
        <div class="label">会员卡消费次数:</div>
        <div class="value">{{info.consume_cnt}}次</div>
      </div>
      <div class="row">
        <div class="label">会员卡消费金额:</div>
        <div class="value">{{info.consume_amt}}</div>
      </div>
      <div class="row">
        <div class="label">会员卡最后消费日期:</div>
        <div class="value">{{info.last_consume_day}}</div>
      </div>
      <div class="row">
        <div class="label">累计充值:</div>
        <div class="value">{{ (info.deposit_val_amt/100).toFixed(2) }}</div>
      </div>
      <div class="row">
        <div class="label">累计赠送:</div>
        <div class="value">{{ (info.deposit_free_amt/100).toFixed(2) }}</div>
      </div>
    </div>
<!--    <div class="row-another">-->
<!--      <div class="label">消费喜好:</div>-->
<!--      <div class="value">{{info.interest}}</div>-->
<!--    </div>-->
  </div>
</template>
 
<script>
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      loading: false,
      options:[]
    };
  },

  methods: {
    async nameQuery(value){
      console.log('----------', value)
      try {
        const params = {
          name: value
        };
        const res = await api_vip.reqMbNameList(params);
        if (res.code == 1) {
          this.options = res.data.records || [];
        } else {
          this.$message.warning(res.msg);
        }
      }
      catch (error) {
        console.log(error);
      }
    },
    async phoneChanged(value) {
      console.log('select phoneChanged:', value)
      this.$emit("phoneChanged", value);
    },
    async inputPhoneChanged(value) {
      console.log('input phoneChanged:', this.info.bind_phone)
      this.$emit("phoneChanged", this.info.bind_phone);
    },
  },


  props: {
    info: {
      default: {}
    }
  },
};
</script>

<style scoped lang="less">
.vip-info {
  border-bottom: 1px solid #b0b7c6;
  padding-bottom: 20px;
  font-size: 14px;
  .form-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    grid-auto-rows: 28px;

    .row {
      display: grid;
      grid-template-columns: 150px 1fr;
    }
  }

  .label {
    text-align: right;
  }
  .value {
    margin-left: 10px;
    word-break: break-all;
  }

  .row-another {
    display: grid;
    grid-template-columns: 140px 1fr;
  }
  .el-button--mini {
    background-color: #d1d5e0;
  }
  .el-input-group__append, .el-input-group__prepend  {
    background-color: #d1d5e0;
    border: none;
  }
}
</style>