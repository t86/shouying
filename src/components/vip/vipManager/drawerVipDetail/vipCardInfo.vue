<template>
  <div class="vip-card-info">
    <div class="form-grid" :class="{'m-t-3': index > 0}" v-for="(item,index) in info" :key="index">
      <div class="row">
        <div class="label">会员卡号:</div>
        <div class="value">{{item.c}}</div>
      </div>
      <div class="row">
        <div class="label">会员卡等级:</div>
        <div class="value">{{item.cl}}</div>
      </div>
      <div class="row">
        <div class="label">卡类型:</div>
        <div class="value">{{item.ct}}</div>
      </div>
      <div class="row">
        <div class="label">会员卡标签:</div>
        <div class="value">{{item.m}}</div>
      </div>
      <div class="row">
        <div class="label">绑定手机:</div>
        <div class="value">{{item.cp}}</div>
      </div>
      <div class="row">
        <div class="label">会员卡总余额:</div>
        <div class="value">{{item.b}}</div>
      </div>
      <div class="row">
        <div class="label">充值余额:</div>
        <div class="value">{{item.vb}}</div>
      </div>
      <div class="row">
        <div class="label">赠送余额:</div>
        <div class="value">{{item.fb}}</div>
      </div>
      <div class="row">
        <div class="label">积分余额:</div>
        <div class="value">{{ item.p }}</div>
      </div>
    </div>
    <div class="row">
      <div class="label">累计充值:</div>
      <div class="value">{{item.dv}}</div>
    </div>
    <div class="row">
      <div class="label">累计赠送:</div>
      <div class="value">{{ item.df }}</div>
    </div>
  </div>
</template>
 
<script>
  export default {
    data() {
      return {
 
      }
    },
    methods: {
    },
    created() {
 
    },
    mounted() {
 
    },
    props: {
      info: {
        default: []
      }
    },
    components: {
 
    },
    filters: {
 
    }
  }
 
</script>

<style scoped lang="less">
.vip-card-info {
  .form-grid {
    padding: 10px 0;
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    grid-auto-rows: 28px;
    font-size: 14px;
    border-bottom: 1px solid #b0b7c6;

    .row {
      display: grid;
      grid-template-columns: 120px 1fr;
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
    grid-template-columns: 120px 1fr;
  }
}
</style>